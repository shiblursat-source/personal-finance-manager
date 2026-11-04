import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/database.dart';

/// Builds a multi-sheet .xlsx mirroring the original Excel ledger and shares
/// it — the share sheet lets the user send it straight via Gmail.
class ExcelExportService {
  ExcelExportService(this.db);
  final AppDatabase db;

  Future<File> buildExcel() async {
    final excel = Excel.createExcel();
    void sheet(String name, List<List<Object?>> rows) {
      final s = excel[name];
      for (final r in rows) { s.appendRow(r.map((v) => v == null ? null : TextCellValue(v.toString())).toList()); }
    }
    final ledger = await db.select(db.ledgerEntries).get();
    final loans = await db.select(db.loans).get();
    double inc = 0, exp = 0; for (final e in ledger) { if (e.type == 'income') { inc += e.actualAmount; } else { exp += e.actualAmount; } }
    sheet('Dashboard', [['Metric', 'Amount (BDT)'], ['Total Income', inc], ['Total Expenses', exp], ['Net Savings', inc - exp], ['Active Loan Outstanding', loans.where((l) => l.isActive).fold<double>(0, (s, l) => s + l.balanceAmount)]]);
    sheet('Ledger', [['Year', 'Month', 'Type', 'Category', 'Title', 'Projected', 'Actual', 'Variance'], ...ledger.map((e) => [e.year, e.month, e.type, e.category, e.title, e.projectedAmount, e.actualAmount, e.projectedAmount - e.actualAmount])]);
    sheet('Loans', [['Name', 'Type', 'Total', 'Monthly P.A', 'Balance B.A', 'Sonchoy', 'Start', 'End', 'Active'], ...loans.map((l) => [l.name, l.type, l.totalAmount, l.monthlyPayment, l.balanceAmount, l.monthlySavings, l.startDate.toIso8601String(), l.endDate.toIso8601String(), l.isActive])]);
    final salary = await db.select(db.salaryStructures).get(); final pf = await db.select(db.pfEntries).get();
    sheet('Salary_PF', [['Year', 'Month', 'Basic', 'House Rent', 'Medical', 'Transport', 'Gross'], ...salary.map((s) => [s.year, s.month, s.basicSalary, s.houseRentAllowance, s.medicalAllowance, s.transportAllowance, s.basicSalary + s.houseRentAllowance + s.medicalAllowance + s.transportAllowance]), ['--- PF ---', '', '', '', '', '', ''], ['Year', 'Month', 'Deduction', 'Employer', 'Cumulative Balance', '', ''], ...pf.map((p) => [p.year, p.month, p.monthlyDeduction, p.employerContribution, p.cumulativeBalance, '', ''])]);
    final budgets = await db.select(db.occasionBudgets).get(); final items = await db.select(db.occasionItems).get();
    List<List<Object?>> occRows(String type) => [['Budget', 'Person/Category', 'Budgeted', 'Actual', 'Variance'], ...budgets.where((b) => b.type == type).expand((b) => items.where((i) => i.budgetId == b.id).map((i) => [b.title, i.personOrCategory, i.budgetedAmount, i.actualAmount, i.budgetedAmount - i.actualAmount]))];
    sheet('Eid', occRows('eid'));
    sheet('Tour', occRows('tour'));
    final bazar = await db.select(db.bazarShopItems).get(); final home = await db.select(db.homeConstructionItems).get(); final goals = await db.select(db.futureGoals).get();
    sheet('Projects', [['Section', 'Item', 'Qty', 'Unit Price', 'Target/Estimated', 'Actual/Paid'], ...bazar.map((b) => ['Bazar Shop', b.itemName, b.quantity, b.unitPrice, b.quantity * b.unitPrice, b.actualCost]), ...home.map((h) => ['Home Construction', h.itemName, h.quantity, h.unitPrice, h.quantity * h.unitPrice, h.paidAmount]), ...goals.map((g) => ['Future Goal', g.title, '', '', g.targetAmount, g.savedAmount])]);
    excel.delete('Sheet1');
    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel generation failed');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/finance_report_${DateTime.now().toIso8601String().split('T').first}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> exportAndShareViaGmail() async {
    final file = await buildExcel();
    await Share.shareXFiles([XFile(file.path)], subject: 'Personal Finance Report — Shiblur Rahman', text: 'Attached is my updated finance report (.xlsx). Choose Gmail in the share sheet to email it to yourself.');
  }
}
