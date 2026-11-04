import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/backup/backup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/ledger/ledger_screen.dart';
import '../../features/loans/loan_detail_screen.dart';
import '../../features/loans/loans_screen.dart';
import '../../features/occasions/occasions_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/salary_pf/salary_pf_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Ledger'),
            NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Loans'),
            NavigationDestination(icon: Icon(Icons.celebration_outlined), selectedIcon: Icon(Icons.celebration), label: 'Occasions'),
            NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projects'),
          ],
        ),
      ),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/ledger', builder: (_, __) => const LedgerScreen())]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/loans', builder: (_, __) => const LoansScreen(), routes: [
            GoRoute(path: ':id', builder: (_, state) => LoanDetailScreen(loanId: int.parse(state.pathParameters['id']!))),
          ]),
        ]),
        StatefulShellBranch(routes: [GoRoute(path: '/occasions', builder: (_, __) => const OccasionsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/projects', builder: (_, __) => const ProjectsScreen())]),
      ],
    ),
    GoRoute(path: '/salary-pf', builder: (_, __) => const SalaryPfScreen()),
    GoRoute(path: '/backup', builder: (_, __) => const BackupScreen()),
  ],
);
