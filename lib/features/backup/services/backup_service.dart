import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../core/constants/app_constants.dart';
import '../../../data/database.dart';
import 'google_auth_service.dart';

/// Full-DB export -> AES-256-CBC encrypted JSON -> Google Drive appDataFolder.
/// Local Drift DB is always the source of truth; backup is manual/opt-in.
class BackupService {
  BackupService(this.db, this.auth);
  final AppDatabase db; final GoogleAuthService auth;
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'pfm_backup_aes_key_v1';

  Future<enc.Key> _key() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return enc.Key.fromBase64(existing);
    final k = enc.Key.fromSecureRandom(32);
    await _storage.write(key: _keyName, value: k.base64);
    return k;
  }

  Future<String> exportEncryptedJson() async {
    final payload = await exportPlainMap();
    final iv = enc.IV.fromSecureRandom(16);
    final cipher = enc.Encrypter(enc.AES(await _key())).encrypt(jsonEncode(payload), iv: iv);
    return jsonEncode({'version': 1, 'iv': iv.base64, 'ciphertext': cipher.base64});
  }

  Future<Map<String, dynamic>> exportPlainMap() async => {
        'exportedAt': DateTime.now().toIso8601String(),
        'ledger': [for (final e in await db.select(db.ledgerEntries).get()) {'year': e.year, 'month': e.month, 'type': e.type, 'category': e.category, 'title': e.title, 'projected': e.projectedAmount, 'actual': e.actualAmount, 'note': e.note}],
        'loans': [for (final l in await db.select(db.loans).get()) {'name': l.name, 'type': l.type, 'total': l.totalAmount, 'pa': l.monthlyPayment, 'balance': l.balanceAmount, 'sonchoy': l.monthlySavings, 'start': l.startDate.toIso8601String(), 'end': l.endDate.toIso8601String(), 'active': l.isActive}],
        'loanPayments': [for (final p in await db.select(db.loanPayments).get()) {'loanId': p.loanId, 'year': p.year, 'month': p.month, 'amount': p.amount, 'paidAt': p.paidAt.toIso8601String()}],
        'salary': [for (final s in await db.select(db.salaryStructures).get()) {'year': s.year, 'month': s.month, 'basic': s.basicSalary, 'hra': s.houseRentAllowance, 'medical': s.medicalAllowance, 'transport': s.transportAllowance}],
        'pf': [for (final p in await db.select(db.pfEntries).get()) {'year': p.year, 'month': p.month, 'deduction': p.monthlyDeduction, 'employer': p.employerContribution, 'balance': p.cumulativeBalance}],
        'occasions': [for (final o in await db.select(db.occasionBudgets).get()) {'type': o.type, 'title': o.title, 'year': o.year, 'income': o.incomeBudget}],
        'occasionItems': [for (final i in await db.select(db.occasionItems).get()) {'budgetTitleIndex': i.budgetId, 'person': i.personOrCategory, 'budgeted': i.budgetedAmount, 'actual': i.actualAmount}],
        'bazar': [for (final b in await db.select(db.bazarShopItems).get()) {'year': b.year, 'month': b.month, 'item': b.itemName, 'qty': b.quantity, 'unit': b.unit, 'unitPrice': b.unitPrice, 'actual': b.actualCost, 'checked': b.isChecked}],
        'home': [for (final h in await db.select(db.homeConstructionItems).get()) {'item': h.itemName, 'unit': h.unit, 'qty': h.quantity, 'unitPrice': h.unitPrice, 'paid': h.paidAmount}],
        'goals': [for (final g in await db.select(db.futureGoals).get()) {'title': g.title, 'target': g.targetAmount, 'saved': g.savedAmount, 'deadline': g.deadline?.toIso8601String()}],
      };

  Future<String> decryptBackup(String encryptedJson) async {
    final map = jsonDecode(encryptedJson) as Map<String, dynamic>;
    final iv = enc.IV.fromBase64(map['iv'] as String);
    return enc.Encrypter(enc.AES(await _key())).decrypt64(map['ciphertext'] as String, iv: iv);
  }

  /// Uploads (creates or replaces) the single backup file in appDataFolder.
  Future<void> backupNow() async {
    final client = await auth.authenticatedClient();
    if (client == null) throw Exception('Not signed in to Google. Tap "Sign in with Google" first.');
    final api = drive.DriveApi(client);
    final content = await exportEncryptedJson();
    final bytes = utf8.encode(content);
    final existing = await api.files.list(spaces: 'appDataFolder', q: "name = '${AppConstants.backupFileName}'");
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');
    if (existing.files != null && existing.files!.isNotEmpty) {
      await api.files.update(drive.File(), existing.files!.first.id!, uploadMedia: media);
    } else {
      await api.files.create(drive.File(name: AppConstants.backupFileName, parents: ['appDataFolder']), uploadMedia: media);
    }
    client.close();
  }

  /// Downloads the latest backup, decrypts it and imports ledger + loans
  /// (other tables are included in the file for Excel/manual use; extending
  /// import to them follows the exact same pattern).
  Future<int> restoreLatest() async {
    final client = await auth.authenticatedClient();
    if (client == null) throw Exception('Not signed in to Google.');
    final api = drive.DriveApi(client);
    final list = await api.files.list(spaces: 'appDataFolder', q: "name = '${AppConstants.backupFileName}'", orderBy: 'modifiedTime desc');
    if (list.files == null || list.files!.isEmpty) { client.close(); throw Exception('No backup found in Drive appDataFolder.'); }
    final media = await api.files.get(list.files!.first.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
    client.close();
    final plain = await decryptBackup(utf8.decode(bytes));
    final map = jsonDecode(plain) as Map<String, dynamic>;
    int count = 0;
    await db.transaction(() async {
      await db.delete(db.ledgerEntries).go();
      for (final e in (map['ledger'] as List? ?? [])) {
        final m = e as Map<String, dynamic>;
        await db.into(db.ledgerEntries).insert(LedgerEntriesCompanion.insert(year: m['year'] as int, month: m['month'] as int, type: m['type'] as String, category: m['category'] as String, title: Value((m['title'] as String?) ?? ''), projectedAmount: Value((m['projected'] as num).toDouble()), actualAmount: Value((m['actual'] as num).toDouble())));
        count++;
      }
      await db.delete(db.loans).go();
      for (final e in (map['loans'] as List? ?? [])) {
        final m = e as Map<String, dynamic>;
        await db.into(db.loans).insert(LoansCompanion.insert(name: m['name'] as String, type: m['type'] as String, totalAmount: (m['total'] as num).toDouble(), monthlyPayment: (m['pa'] as num).toDouble(), balanceAmount: (m['balance'] as num).toDouble(), monthlySavings: Value((m['sonchoy'] as num?)?.toDouble() ?? 0), startDate: DateTime.parse(m['start'] as String), endDate: DateTime.parse(m['end'] as String)));
      }
    });
    return count;
  }
}
