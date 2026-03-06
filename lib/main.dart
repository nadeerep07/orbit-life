import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/utils/app_routes.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/local_data_source.dart';
import 'data/models/account_model.dart';
import 'data/models/category_model.dart';
import 'data/models/expense_model.dart';
import 'data/models/savings_model.dart';
import 'data/models/income_model.dart';
import 'data/repositories/account_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'data/repositories/savings_repository_impl.dart';
import 'data/repositories/income_repository_impl.dart';
import 'presentation/viewmodels/accounts_view_model.dart';
import 'presentation/viewmodels/auth_view_model.dart';
import 'presentation/viewmodels/budget_view_model.dart';
import 'presentation/viewmodels/expense_view_model.dart';
import 'presentation/viewmodels/savings_view_model.dart';
import 'presentation/viewmodels/month_view_model.dart';
import 'presentation/viewmodels/theme_view_model.dart';
import 'presentation/viewmodels/income_view_model.dart';
import 'presentation/viewmodels/mileage_view_model.dart';
import 'data/models/mileage_entry_model.dart';
import 'data/repositories/mileage_repository_impl.dart';
import 'data/models/transfer_model.dart';
import 'data/repositories/transfer_repository_impl.dart';
import 'presentation/viewmodels/transfer_view_model.dart';

import 'data/models/goal_model.dart';
import 'data/repositories/goal_repository_impl.dart';
import 'presentation/viewmodels/goals_view_model.dart';

import 'data/models/service_model.dart';
import 'data/repositories/service_repository_impl.dart';
import 'presentation/viewmodels/service_view_model.dart';

import 'data/models/diet_model.dart';
import 'data/repositories/diet_repository_impl.dart';
import 'presentation/viewmodels/diet_view_model.dart';

import 'data/models/emi_tracker_model.dart';
import 'data/repositories/emi_tracker_repository_impl.dart';
import 'presentation/viewmodels/emi_tracker_view_model.dart';

import 'data/models/borrow_lend_model.dart';
import 'data/repositories/borrow_lend_repository_impl.dart';
import 'presentation/viewmodels/borrow_lend_view_model.dart';

import 'data/models/investment_model.dart';
import 'data/repositories/investment_repository_impl.dart';
import 'presentation/viewmodels/investment_view_model.dart';

import 'presentation/theme/light_theme.dart';
import 'presentation/theme/dark_theme.dart';

import 'presentation/widgets/app_lock_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // 🔥 Initialize Firebase FIRST
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Initialize Notifications
  await NotificationService().init();

  // 📦 Hive Initialization
  await Hive.initFlutter();
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(SavingsModelAdapter());
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(MileageEntryModelAdapter());
  Hive.registerAdapter(TransferModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(ServiceModelAdapter());
  Hive.registerAdapter(DietProfileModelAdapter());
  Hive.registerAdapter(MealEntryModelAdapter());
  Hive.registerAdapter(EmiTrackerModelAdapter());
  Hive.registerAdapter(BorrowLendModelAdapter());
  Hive.registerAdapter(InvestmentModelAdapter());
  await Hive.openBox('settingsBox'); // Initialize settingsBox

  // Data Sources & Repositories
  final localDataSource = HiveDataSourceImpl();
  await localDataSource.init();

  final categoryRepository = CategoryRepositoryImpl(localDataSource);
  final expenseRepository = ExpenseRepositoryImpl(localDataSource);
  final accountRepository = AccountRepositoryImpl(localDataSource);
  final savingsRepository = SavingsRepositoryImpl(localDataSource);
  final incomeRepository = IncomeRepositoryImpl(localDataSource);
  final mileageRepository = MileageRepositoryImpl(
    localDataSource: localDataSource,
  );
  final transferRepository = TransferRepositoryImpl(localDataSource);
  final goalRepository = GoalRepositoryImpl(localDataSource);
  final serviceRepository = ServiceRepositoryImpl(localDataSource);
  final dietRepository = DietRepositoryImpl(localDataSource);
  final emiTrackerRepository = EmiTrackerRepositoryImpl(localDataSource);
  final borrowLendRepository = BorrowLendRepositoryImpl(localDataSource);
  final investmentRepository = InvestmentRepositoryImpl(localDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MonthViewModel()),
        ChangeNotifierProxyProvider<MonthViewModel, BudgetViewModel>(
          create: (context) =>
              BudgetViewModel(categoryRepository)
                ..loadCategories(context.read<MonthViewModel>().currentMonth),
          update: (context, monthVM, previous) =>
              (previous ?? BudgetViewModel(categoryRepository))
                ..loadCategories(monthVM.currentMonth),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseViewModel(expenseRepository)..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountsViewModel(accountRepository)..loadAccounts(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingsViewModel(savingsRepository)..loadSavings(),
        ),
        ChangeNotifierProvider(
          create: (_) => IncomeViewModel(incomeRepository)..loadIncomes(),
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProxyProvider2<
          ExpenseViewModel,
          AccountsViewModel,
          MileageViewModel
        >(
          create: (context) => MileageViewModel(
            mileageRepository,
            context.read<ExpenseViewModel>(),
            context.read<AccountsViewModel>(),
          )..loadEntries(),
          update: (context, expenseVM, accountsVM, previous) =>
              (previous ??
                    MileageViewModel(mileageRepository, expenseVM, accountsVM))
                ..loadEntries(),
        ),
        ChangeNotifierProxyProvider2<
          AccountsViewModel,
          SavingsViewModel,
          TransferViewModel
        >(
          create: (context) => TransferViewModel(
            transferRepository,
            context.read<AccountsViewModel>(),
            context.read<SavingsViewModel>(),
          )..loadTransfers(),
          update: (context, accountsVM, savingsVM, previous) =>
              (previous ??
                    TransferViewModel(
                      transferRepository,
                      accountsVM,
                      savingsVM,
                    ))
                ..loadTransfers(),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(goalRepository)..loadGoals(),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceViewModel(serviceRepository)..loadServices(),
        ),
        ChangeNotifierProvider(
          create: (_) => DietViewModel(dietRepository)..loadDietData(),
        ),
        ChangeNotifierProvider(
          create: (_) => EmiTrackerViewModel(emiTrackerRepository)..loadEmis(),
        ),
        ChangeNotifierProxyProvider<AccountsViewModel, BorrowLendViewModel>(
          create: (context) => BorrowLendViewModel(
            borrowLendRepository,
            context.read<AccountsViewModel>(),
          )..loadEntries(),
          update: (context, accountsVM, previous) =>
              (previous ??
                    BorrowLendViewModel(borrowLendRepository, accountsVM))
                ..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              InvestmentViewModel(investmentRepository)..loadInvestments(),
        ),
      ],
      child: const AppLockWrapper(child: MyBudgetApp()),
    ),
  );
}

class MyBudgetApp extends StatelessWidget {
  const MyBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, child) {
        return MaterialApp(
          title: 'OrbitLife',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeVM.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
