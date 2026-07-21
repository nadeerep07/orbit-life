import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_budget_pro/domain/repositories/settings_repository.dart';
import 'package:my_budget_pro/domain/repositories/transaction_repository.dart';
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

import 'features/credit_card/data/models/fd_lot_model.dart';
import 'features/credit_card/data/models/credit_card_account_model.dart';
import 'features/credit_card/data/models/credit_card_statement_model.dart';
import 'features/credit_card/data/models/cashback_transaction_model.dart';
import 'features/credit_card/data/datasources/credit_card_local_data_source.dart';
import 'features/credit_card/domain/repositories/credit_card_repository.dart';
import 'features/credit_card/data/repositories/credit_card_repository_impl.dart';
import 'features/credit_card/presentation/blocs/credit_card_bloc.dart';
import 'features/credit_card/presentation/blocs/fd_lots_bloc.dart';
import 'features/credit_card/presentation/blocs/statement_bloc.dart';
import 'features/credit_card/presentation/blocs/cashback_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'data/models/borrow_lend_transaction_model.dart';
import 'data/repositories/borrow_lend_repository_impl.dart';
import 'presentation/viewmodels/borrow_lend_view_model.dart';

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:firebase_core/firebase_core.dart';

// import 'core/services/notification_service.dart';
import 'core/utils/data_fixer.dart';
// import 'data/datasources/local_data_source.dart';

import 'data/models/investment_model.dart';
import 'data/models/transaction_model.dart';
import 'data/models/settings_model.dart';
import 'data/repositories/investment_repository_impl.dart';
import 'presentation/viewmodels/investment_view_model.dart';

import 'data/repositories/transaction_repository_impl.dart';
import 'presentation/viewmodels/account_detail_view_model.dart';

import 'presentation/theme/light_theme.dart';
import 'presentation/theme/dark_theme.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'presentation/viewmodels/settings_view_model.dart';

import 'presentation/widgets/app_lock_wrapper.dart';
import 'core/utils/currency_formatter.dart';

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
  Hive.registerAdapter(BorrowLendTransactionModelAdapter());
  Hive.registerAdapter(InvestmentModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(FdLotModelAdapter());
  Hive.registerAdapter(CreditCardAccountModelAdapter());
  Hive.registerAdapter(CreditCardStatementModelAdapter());
  Hive.registerAdapter(CashbackTransactionModelAdapter());
  await Hive.openBox('settingsBox'); // Initialize settingsBox

  // Data Sources & Repositories
  final localDataSource = HiveDataSourceImpl();
  await localDataSource.init();

  final creditCardDataSource = CreditCardLocalDataSourceImpl();
  await creditCardDataSource.init();

  final settingsRepository = SettingsRepositoryImpl(localDataSource);
  final settings = await settingsRepository.getSettings();
  currencySymbol = settings.currencySymbol;

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
  final transactionRepository = TransactionRepositoryImpl(localDataSource);
  final creditCardRepository = CreditCardRepositoryImpl(
    localDataSource: creditCardDataSource,
    transactionRepository: transactionRepository,
  );

  // 🛠 Run one-time data fixes and balance resync
  await DataFixer.runFixes(localDataSource, transactionRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(settingsRepository),
        ),
        ChangeNotifierProvider(create: (_) => MonthViewModel()),
        ChangeNotifierProxyProvider<MonthViewModel, BudgetViewModel>(
          create: (context) =>
              BudgetViewModel(categoryRepository)
                ..loadCategories(context.read<MonthViewModel>().currentMonth),
          update: (context, monthVM, previous) {
            final vm = previous ?? BudgetViewModel(categoryRepository);
            // Only reload if the month actually changed to prevent feedback loops
            if (vm.lastLoadedMonth == null ||
                vm.lastLoadedMonth!.month != monthVM.currentMonth.month ||
                vm.lastLoadedMonth!.year != monthVM.currentMonth.year) {
              vm.loadCategories(monthVM.currentMonth);
            }
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseViewModel(expenseRepository, transactionRepository)..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountsViewModel(accountRepository, transactionRepository)..loadAccounts(),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingsViewModel(savingsRepository, transactionRepository)..loadSavings(),
        ),
        ChangeNotifierProvider(
          create: (_) => IncomeViewModel(incomeRepository, transactionRepository)..loadIncomes(),
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
        ChangeNotifierProvider(
          create: (_) => TransferViewModel(transferRepository, transactionRepository)..loadTransfers(),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(goalRepository, transactionRepository)..loadGoals(),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceViewModel(serviceRepository, transactionRepository)..loadServices(),
        ),
        ChangeNotifierProvider(
          create: (_) => DietViewModel(dietRepository)..loadDietData(),
        ),
        ChangeNotifierProvider(
          create: (_) => EmiTrackerViewModel(emiTrackerRepository, transactionRepository)..loadEmis(),
        ),
        ChangeNotifierProvider(
          create: (_) => BorrowLendViewModel(borrowLendRepository, transactionRepository)..loadEntries(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvestmentViewModel(investmentRepository, transactionRepository)..loadInvestments(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AccountDetailViewModel(repository: transactionRepository),
        ),
        Provider<CreditCardRepository>.value(value: creditCardRepository),
        BlocProvider(
          create: (_) => CreditCardBloc(repository: creditCardRepository)..add(LoadCreditCardAccountEvent()),
        ),
        BlocProvider(
          create: (_) => FdLotsBloc(repository: creditCardRepository)..add(LoadFdLotsEvent()),
        ),
        BlocProvider(
          create: (_) => StatementBloc(repository: creditCardRepository)..add(LoadStatementsEvent()),
        ),
        BlocProvider(
          create: (_) => CashbackBloc(repository: creditCardRepository)..add(LoadCashbackEvent()),
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
