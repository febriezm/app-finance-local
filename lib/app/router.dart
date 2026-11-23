import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'scaffold_with_nav_bar.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import '../features/wallets/presentation/screens/wallets_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/budgets/presentation/screens/budgets_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/receipt_scanner/presentation/screens/receipt_scanner_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _transactionsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'transactions');
final GlobalKey<NavigatorState> _walletsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'wallets');
final GlobalKey<NavigatorState> _reportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reports');

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String transactions = '/transactions';
  static const String wallets = '/wallets';
  static const String reports = '/reports';
  static const String budgets = '/budgets';
  static const String settings = '/settings';
  static const String receiptScanner = '/receipt-scanner';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Transactions
          StatefulShellBranch(
            navigatorKey: _transactionsNavigatorKey,
            routes: [
              GoRoute(
                path: transactions,
                builder: (context, state) {
                  DateTime? initialMonth;
                  if (state.extra is Map && (state.extra as Map).containsKey('initialMonth')) {
                    final val = (state.extra as Map)['initialMonth'];
                    if (val is DateTime) initialMonth = val;
                  } else if (state.extra is DateTime) {
                    initialMonth = state.extra as DateTime;
                  }
                  return TransactionsScreen(initialMonth: initialMonth);
                },
              ),
            ],
          ),

          // Branch 2: Wallets
          StatefulShellBranch(
            navigatorKey: _walletsNavigatorKey,
            routes: [
              GoRoute(
                path: wallets,
                builder: (context, state) => const WalletsScreen(),
              ),
            ],
          ),

          // Branch 3: Reports
          StatefulShellBranch(
            navigatorKey: _reportsNavigatorKey,
            routes: [
              GoRoute(
                path: reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone Routes (accessible via context.push)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: budgets,
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: receiptScanner,
        builder: (context, state) => const ReceiptScannerScreen(),
      ),
    ],
  );
}
