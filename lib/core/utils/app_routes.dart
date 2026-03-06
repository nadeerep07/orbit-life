import 'package:flutter/material.dart';
import 'package:my_budget_pro/presentation/screens/account_detail_screen.dart';
import 'package:my_budget_pro/presentation/screens/accounts_screen.dart';
import 'package:my_budget_pro/presentation/screens/add_expense_screen.dart';
import 'package:my_budget_pro/presentation/screens/analytics_screen.dart';
import 'package:my_budget_pro/presentation/screens/budget_screen.dart';
import 'package:my_budget_pro/presentation/screens/savings_screen.dart';
import 'package:my_budget_pro/presentation/screens/settings_screen.dart';
import 'package:my_budget_pro/presentation/screens/all_expenses_screen.dart';
import 'package:my_budget_pro/presentation/screens/income_screen.dart';
import 'package:my_budget_pro/presentation/screens/mileage_screen.dart';
import 'package:my_budget_pro/presentation/screens/transfer_screen.dart';
import 'package:my_budget_pro/presentation/screens/transfer_history_screen.dart';
import 'package:my_budget_pro/presentation/screens/goals_screen.dart';
import 'package:my_budget_pro/presentation/screens/emi_calculator_screen.dart';
import 'package:my_budget_pro/presentation/screens/splash_screen.dart';
import 'package:my_budget_pro/presentation/screens/service_tracker_screen.dart';
import 'package:my_budget_pro/presentation/screens/services_history_screen.dart';
import 'package:my_budget_pro/presentation/screens/diet_dashboard_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';

import '../../presentation/screens/borrow_lend_screen.dart';
import '../../presentation/screens/add_borrow_lend_screen.dart';
import '../../presentation/screens/borrow_lend_detail_screen.dart';

import '../../presentation/screens/investments_screen.dart';
import '../../presentation/screens/add_investment_screen.dart';
import '../../presentation/screens/investment_detail_screen.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/entities/account_entity.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String addExpense = '/addExpense';
  static const String budget = '/budget';
  static const String accounts = '/accounts';
  static const String accountDetail = '/accountDetail';
  static const String analytics = '/analytics';
  static const String setting = '/settings';
  static const String savings = '/savings';
  static const String allExpenses = '/allExpenses';
  static const String income = '/income';
  static const String mileage = '/mileage';
  static const String transfer = '/transfer';
  static const String transferHistory = '/transferHistory';
  static const String goals = '/goals';
  static const String emiCalculator = '/emiCalculator';
  static const String splash = '/splash';
  static const String serviceTracker = '/serviceTracker';
  static const String serviceHistory = '/serviceHistory';
  static const String dietDashboard = '/dietDashboard';

  static const String borrowLend = '/borrowLend';
  static const String addBorrowLend = '/addBorrowLend';
  static const String borrowLendDetail = '/borrowLendDetail';

  static const String investments = '/investments';
  static const String addInvestment = '/addInvestment';
  static const String investmentDetail = '/investmentDetail';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      case budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
      case accounts:
        return MaterialPageRoute(builder: (_) => const AccountsScreen());
      case accountDetail:
        final account = settings.arguments as AccountEntity?;
        if (account == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Account not found')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: account),
        );
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case savings:
        return MaterialPageRoute(builder: (_) => const SavingsScreen());
      case allExpenses:
        return MaterialPageRoute(builder: (_) => const AllExpensesScreen());
      case setting:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case income:
        return MaterialPageRoute(builder: (_) => const IncomeScreen());
      case mileage:
        return MaterialPageRoute(builder: (_) => const MileageScreen());
      case transfer:
        return MaterialPageRoute(builder: (_) => const TransferScreen());
      case transferHistory:
        return MaterialPageRoute(builder: (_) => const TransferHistoryScreen());
      case goals:
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case emiCalculator:
        return MaterialPageRoute(builder: (_) => const EmiTrackerScreen());
      case serviceTracker:
        return MaterialPageRoute(builder: (_) => const ServiceTrackerScreen());
      case serviceHistory:
        return MaterialPageRoute(builder: (_) => const ServicesHistoryScreen());
      case dietDashboard:
        return MaterialPageRoute(builder: (_) => const DietDashboardScreen());

      // Borrow & Lend
      case borrowLend:
        return MaterialPageRoute(builder: (_) => const BorrowLendScreen());
      case addBorrowLend:
        return MaterialPageRoute(builder: (_) => const AddBorrowLendScreen());
      case borrowLendDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => BorrowLendDetailScreen(
            personName: args['personName'] ?? '',
            phoneNumber: args['phoneNumber'] ?? '',
          ),
        );

      // Investments
      case investments:
        return MaterialPageRoute(builder: (_) => const InvestmentsScreen());
      case addInvestment:
        return MaterialPageRoute(builder: (_) => const AddInvestmentScreen());
      case investmentDetail:
        final investment = settings.arguments as InvestmentEntity?;
        if (investment == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Investment details not found')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => InvestmentDetailScreen(investment: investment),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
