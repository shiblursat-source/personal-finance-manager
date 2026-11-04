# Personal Finance & Expense Manager — Shiblur Rahman

A complete, offline-first Flutter Android app for personal finance, rebuilt from
Shiblur Rahman's 32-sheet Excel ledger. Local Drift/SQLite database is the
**source of truth (works 100% offline)**; Google Drive backup and Excel/Gmail
export are optional, manual actions.

> **Verification note (honest):** This codebase was authored in an environment
> **without Flutter/Dart installed** (`flutter`/`dart` not found on PATH), so
> `flutter analyze` / `build_runner` could **not** be run there. The code was
> carefully self-reviewed for import/syntax consistency and uses conservative,
> mutually compatible dependency versions for Flutter 3.24. On your machine,
> run the codegen + analyze steps below first — Drift's generated
> `database.g.dart` is intentionally not committed; it is produced by
> build_runner (step 3).

## Features

- **Dashboard** — Monthly Income / Expenses / Net Savings / Active Loan
  Outstanding cards, bar + pie charts of category spend, Quick Actions
  (Add Income, Add Expense, Record EMI, Backup to Drive), FAB.
- **Monthly Ledger & Budgeting (2020–2027)** — Year/month selector tabs,
  Projected Budget ⇄ Actual Cost toggle, Variance = Projected − Actual.
  Income: Earn 1, Earn 2, Overtime (EOT), Earned Leave (EL), Festival Bonus,
  Refunds. Expenses: Bari Vara, Barite Send, Dukan Bill, Utility
  (Current / Internet / Dish), Bazar, and more.
- **Loan & Credit Card EMI Tracker** — Mehedi loan, BRAC Bank Credit Card,
  LankaBangla Credit Card, City Bank Card (seeded). Total, Monthly Payment
  (P.A), Balance (B.A), Monthly Savings (Sonchoy), start/end dates, computed
  remaining months, **Mark as Paid** (deducts P.A from B.A in a transaction).
- **Salary & PF** — Basic / House Rent / Medical / Transport → Gross calculator;
  PF monthly deduction, employer contribution, cumulative balance, PF loan
  repayment schedule.
- **Occasions** — Eid budget per person (Abba, Maa, Bou, Omor, Ramim, …,
  Eid Bazar, Transport) with variance vs bonus income; Tour planner
  (Cox's Bazar: Bus Rent, Hotel, Food, Sightseeing, Misc).
- **Projects** — Bazar Shop checklist (Rice, Oil, Lentils, Eggs, Spices — qty ×
  unit price, target vs actual); Home Construction estimator (Bricks, Sand,
  Rod, Cement, Daily Labor, Water Tank — total budget, paid, remaining
  capital target); Future Goals (Land Purchase, House Building, Bank FD).
- **Cloud Backup** — Google Sign-In (OAuth 2.0), AES-256 encrypted JSON backup
  to Google Drive **appDataFolder**, one-tap Restore on a new device with the
  same Gmail ID.
- **Export** — Multi-sheet `.xlsx` (Dashboard, Ledger, Loans, Salary_PF, Eid,
  Tour, Projects) shared via the Android share sheet → choose **Gmail** to
  email it to yourself.
- **Currency** — Bangladeshi Taka ৳ with South-Asian digit grouping
  (`en_IN` grouping, matching Bangladeshi convention) via `intl`.
- First run is seeded with realistic demo data (edit/delete freely).

## Setup Instructions

### 1. Prerequisites
- Flutter **3.24+** (Dart 3.5+): https://docs.flutter.dev/get-started/install
- Android Studio / Android SDK, a device or emulator
- `flutter doctor` should be green for Android

### 2. Install dependencies
```bash
cd personal-finance-manager
flutter pub get
```

### 3. Generate Drift database code (REQUIRED before first run)
```bash
dart run build_runner build --delete-conflicting-outputs
# re-run after any change to lib/data/database.dart; for watch mode:
# dart run build_runner watch --delete-conflicting-outputs
```

### 4. Run / Build
```bash
flutter analyze
flutter test
flutter run
flutter build apk --debug
flutter build apk --release   # signs with debug config by default in this
                              # template — add your own keystore in
                              # android/app/build.gradle for Play Store use
```

## Google Cloud Setup (Drive Backup / Gmail sign-in)

1. Go to https://console.cloud.google.com → create/select a project.
2. **APIs & Services → Library** → enable **Google Drive API**.
3. **APIs & Services → OAuth consent screen** → External, app name
   "Personal Finance Manager", add your Gmail as a test user (while in
   Testing mode) and the scope `.../auth/drive.appdata` + `email`.
4. **Credentials → Create credentials → OAuth client ID → Android**:
   - Package name: **`com.shiblur.finance`** (the `applicationId` in
     `android/app/build.gradle`; Dart package is `personal_finance_manager`)
   - SHA-1 certificate fingerprint from your debug key:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     # or simply: cd android && ./gradlew signingReport
     ```
   - Repeat with your **release** keystore SHA-1 before publishing.
5. No `google-services.json` is needed for `google_sign_in` + Drive REST on
   Android (that file is only for Firebase). If you later add Firebase,
   drop it into `android/app/` and add the google-services plugin.
6. In the app: Dashboard → cloud icon → **Sign in with Google** → **Backup Now**.

### Backup / Restore — how it works
- **Backup Now:** serialises every table → AES-256-CBC encrypted JSON
  (`pfm_backup.json.enc`) → uploaded to Drive **appDataFolder** (hidden,
  app-private; no other app / Drive UI listing can see it).
- The AES key is generated once and kept in **Android secure storage**
  (`flutter_secure_storage`). ⚠️ If you restore on a *new* phone, the new
  device generates a different key and cannot decrypt the old backup.
  Practical options: restore while the old phone is available, or export the
  Excel report as a portable copy. (A passphrase-derived key is the planned
  v1.1 improvement — see `backup_service.dart`.)
- **Restore Backup:** downloads the latest backup, decrypts, and re-imports
  ledger + loans in one transaction (other tables are present in the file).
- **Export to Excel / Send to Gmail:** generates the .xlsx into temp storage
  and opens the share sheet — pick Gmail to send it to your own address.

## Project Structure

```
lib/
  main.dart                      # ProviderScope + one-time seed
  app.dart                       # MaterialApp.router (Material 3)
  core/
    constants/app_constants.dart # years 2020-2027, categories, seed names
    theme/app_theme.dart
    utils/currency_formatter.dart    # ৳ BDT formatting/parsing/compact
    utils/finance_calculations.dart  # variance, remaining months, gross…
    router/app_router.dart           # GoRouter + bottom NavigationBar shell
    widgets/                         # SummaryCard, EmptyState
  data/
    database.dart                # Drift tables (ALL modules) + markLoanPaid()
    providers.dart               # DB + period + stream providers (Riverpod)
    seed_data_service.dart       # first-run demo data (guarded, runs once)
  features/
    dashboard/   dashboard_screen.dart, dashboard_providers.dart
    ledger/      ledger_screen.dart, entry_form_dialog.dart, ledger_providers.dart
    loans/       loans_screen.dart, loan_detail_screen.dart
    salary_pf/   salary_pf_screen.dart
    occasions/   occasions_screen.dart        # Eid + Tour tabs
    projects/    projects_screen.dart         # Bazar + Home + Goals tabs
    backup/      backup_screen.dart
                 services/google_auth_service.dart
                 services/backup_service.dart   # AES + Drive appDataFolder
                 services/excel_export_service.dart
    settings/    settings_screen.dart         # re-exports Backup screen
test/
  currency_formatter_test.dart
  finance_calculations_test.dart   # variance, loan remaining months, gross…
  widget_test.dart
android/                         # applicationId com.shiblur.finance,
                                 # INTERNET permission in AndroidManifest.xml
```

## Excel-Sheet → App-Module Mapping

| Excel sheet group (original ledger) | App module | Where in code |
|---|---|---|
| Monthly summary / dashboard sheets | Dashboard cards + bar/pie charts | `features/dashboard/` |
| Monthly ledger 2020–2027 (Projected vs Actual) | LedgerEntries, variance | `features/ledger/`, `data/database.dart` |
| Income sheets (Earn 1, Earn 2, EOT, EL, Bonuses, Refunds) | Income categories | `core/constants/app_constants.dart` |
| Fixed expenses (Bari Vara, Barite Send, Dukan Bill, Utilities, Bazar) | Expense categories | `core/constants/app_constants.dart` |
| Personal loan sheet (Mehedi loan) | Loans (personal) + LoanPayments | `features/loans/` |
| Credit cards (BRAC, LankaBangla, City Bank) | Loans (credit_card), Mark as Paid | `features/loans/` |
| Salary structure sheet | SalaryStructures + gross calculator | `features/salary_pf/` |
| Provident Fund + PF loan sheets | PfEntries, PfLoanEntries | `features/salary_pf/` |
| Eid budget sheets (Abba, Maa, Bou, Omor, Ramim…) | OccasionBudgets/Items (`eid`) | `features/occasions/` |
| Tour sheets (Cox's Bazar, family tours) | OccasionBudgets/Items (`tour`) | `features/occasions/` |
| Bazar shop plan / grocery checklist | BazarShopItems (qty × price, target vs actual) | `features/projects/` |
| Home Made Cost (construction estimate) | HomeConstructionItems (budget / paid / remaining) | `features/projects/` |
| Future plan sheets (land, house, FD) | FutureGoals with progress + deadline | `features/projects/` |
| Whole workbook | Drive backup (encrypted JSON) + .xlsx export | `features/backup/` |

## Tech Stack

Flutter 3.24+ · Riverpod 2.5 · GoRouter 14 · Drift 2.20 (SQLite, offline) ·
fl_chart 0.69 · google_sign_in 6.2 + googleapis 13 (Drive v3) ·
excel 4.0 · share_plus 10 · intl 0.19 · encrypt 5.0 (AES) ·
flutter_secure_storage 9 · uuid · path_provider

## Notes

- AndroidManifest already includes `INTERNET` permission (only used for
  Drive backup / sign-in — the app is otherwise fully offline).
- To change the seeded demo data, edit `lib/data/seed_data_service.dart`
  and reinstall with a fresh database (clear app data).
- User language preference: in-app amounts/labels are English (matching the
  Excel sheets); BDT amounts always render with the ৳ symbol.
