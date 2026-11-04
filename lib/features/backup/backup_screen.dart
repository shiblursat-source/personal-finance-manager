import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import 'services/backup_service.dart';
import 'services/excel_export_service.dart';
import 'services/google_auth_service.dart';

final googleAuthProvider = Provider<GoogleAuthService>((_) => GoogleAuthService());
final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(appDatabaseProvider), ref.watch(googleAuthProvider)));

class BackupScreen extends ConsumerStatefulWidget { const BackupScreen({super.key}); @override ConsumerState<BackupScreen> createState() => _S(); }
class _S extends ConsumerState<BackupScreen> {
  String _status = 'Local database is the source of truth. Backup is optional and manual.'; bool _busy = false; String? _email;
  @override void initState() { super.initState(); ref.read(googleAuthProvider).signInSilently().then((u) { if (mounted) setState(() => _email = u?.email); }); }
  Future<void> _run(String label, Future<void> Function() fn) async { setState(() { _busy = true; _status = '$label…'; }); try { await fn(); setState(() => _status = '$label done ✓'); } catch (e) { setState(() => _status = '$label failed: $e'); } finally { if (mounted) setState(() => _busy = false); } }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Backup, Export & Settings')), body: ListView(padding: const EdgeInsets.all(16), children: [
    Text('Google Account', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(_email == null ? 'Not signed in' : 'Signed in as $_email'),
    const SizedBox(height: 8),
    Wrap(spacing: 8, children: [
      FilledButton.icon(onPressed: _busy ? null : () => _run('Sign-in', () async { final u = await ref.read(googleAuthProvider).signIn(); setState(() => _email = u?.email); }), icon: const Icon(Icons.login), label: const Text('Sign in with Google')),
      OutlinedButton(onPressed: _busy ? null : () async { await ref.read(googleAuthProvider).signOut(); setState(() => _email = null); }, child: const Text('Sign out')),
    ]),
    const Divider(height: 32),
    Text('Google Drive Backup (appDataFolder)', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    FilledButton.icon(onPressed: _busy ? null : () => _run('Backup to Drive', () => ref.read(backupServiceProvider).backupNow()), icon: const Icon(Icons.cloud_upload), label: const Text('Backup Now')),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: _busy ? null : () => _run('Restore from Drive', () async { final n = await ref.read(backupServiceProvider).restoreLatest(); setState(() => _status = 'Restore done ✓ — $n ledger entries imported'); }), icon: const Icon(Icons.cloud_download), label: const Text('Restore Backup')),
    const Divider(height: 32),
    Text('Excel / Gmail Export', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    FilledButton.tonalIcon(onPressed: _busy ? null : () => _run('Excel export', () => ExcelExportService(ref.read(appDatabaseProvider)).exportAndShareViaGmail()), icon: const Icon(Icons.table_chart_outlined), label: const Text('Export to Excel / Send via Gmail')),
    const Divider(height: 32),
    if (_busy) const LinearProgressIndicator(),
    const SizedBox(height: 8), Text(_status),
    const SizedBox(height: 16),
    const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Offline-first: everything works 100% offline. Backups are AES-256 encrypted JSON stored only in your own Google Drive appDataFolder (hidden from normal Drive view). The encryption key lives in Android secure storage on this device — keep a copy if you plan to restore on a new phone (see README).'))),
  ]));
}
