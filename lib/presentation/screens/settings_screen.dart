import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/export_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/developer_diagnostics_sheet.dart';
import '../../core/services/local_auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/savings_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/mileage_entry_model.dart';
import '../../data/models/transfer_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/diet_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final settings = settingsVM.settings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: User Profile Header ─────────────────────────────
            _buildProfileCard(context, authVM),
            const SizedBox(height: 16),

            // ── Section 2: Financial Allocation Strategy ───────────────────
            _buildStrategyCard(context, settingsVM),
            const SizedBox(height: 16),

            // ── Section 3: Financial Goals & Budgets ────────────────────────
            _buildBudgetsCard(context, settingsVM),
            const SizedBox(height: 16),

            // ── Section 4: Daily Spending Rules ─────────────────────────────
            _buildDailyRulesCard(context, settingsVM),
            const SizedBox(height: 16),

            // ── Section 5: App Lock & Security ──────────────────────────────
            _buildSecurityCard(context, settingsVM),
            const SizedBox(height: 16),

            // ── Section 6: Appearance Theme Mode ────────────────────────────
            _buildAppearanceCard(context, themeVM),
            const SizedBox(height: 16),

            // ── Section 7: Backup & Data Control ─────────────────────────────
            _buildBackupCard(context, authVM, expenseVM),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthViewModel authVM) {
    final user = authVM.currentUser;
    final settings = context.watch<SettingsViewModel>().settings;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user != null && user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: user == null || user.photoUrl == null
                  ? Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Financial Specialist',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Preferences Configured',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                settings.currencyCode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Financial Mode & Strategy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Money Allocation', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Direct incoming salaries to mandatory budgets automatically'),
              value: settings.enableAutoAllocation,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => settingsVM.updateAutoAllocation(val),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Select Engine Operating Mode:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildStrategyOption(
              context,
              settingsVM,
              title: 'Growth Mode',
              subtitle: 'Prioritize Wealth & Savings Goal setting',
              value: 'growth',
              groupValue: settings.financialMode,
            ),
            _buildStrategyOption(
              context,
              settingsVM,
              title: 'Recovery Mode',
              subtitle: 'Prioritize debt repayment outstanding liabilities',
              value: 'recovery',
              groupValue: settings.financialMode,
            ),
            _buildStrategyOption(
              context,
              settingsVM,
              title: 'Survival Mode',
              subtitle: 'Focus strictly on core EMI obligations & basic needs',
              value: 'survival',
              groupValue: settings.financialMode,
            ),
            _buildStrategyOption(
              context,
              settingsVM,
              title: 'Custom Mode',
              subtitle: 'Configure your own allocations flow priority',
              value: 'custom',
              groupValue: settings.financialMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyOption(
    BuildContext context,
    SettingsViewModel settingsVM, {
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => settingsVM.updateFinancialMode(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) {
                if (val != null) settingsVM.updateFinancialMode(val);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetsCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.wallet, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Budgets & Safety Targets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Currency Settings'),
              subtitle: Text('${settings.currencyCode} (${settings.currencySymbol})'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showCurrencyDialog(context, settingsVM),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Monthly Budget Limit'),
              subtitle: Text(CurrencyFormatter.format(settings.monthlyBudgetLimit)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showBudgetDialog(context, settingsVM),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Savings Target Goal'),
              subtitle: Text(CurrencyFormatter.format(settings.savingsGoal)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showSavingsGoalDialog(context, settingsVM),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Emergency Fund Target'),
              subtitle: Text(CurrencyFormatter.format(settings.emergencyFundGoal)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showEmergencyFundGoalDialog(context, settingsVM),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRulesCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.punch_clock, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Daily spending rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limit Rollover'),
              subtitle: const Text('Roll over unspent daily budget to next days'),
              value: settings.dailyLimitRollover,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => settingsVM.updateDailyLimitRollover(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Security & Privacy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Biometrics / PIN App Lock'),
              subtitle: const Text('Secure access to your sensitive financial logs'),
              value: settings.enableBiometrics,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) async {
                if (val) {
                  final authenticated = await LocalAuthService.authenticate();
                  if (authenticated) {
                    await settingsVM.updateBiometrics(true);
                  }
                } else {
                  await settingsVM.updateBiometrics(false);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set Passcode PIN'),
              subtitle: Text(settings.securityPin.isEmpty ? 'Not Set' : 'Active PIN Passcode'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showPinDialog(context, settingsVM),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, ThemeViewModel themeVM) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: themeVM.themeMode,
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => val != null ? themeVM.setTheme(val) : null,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: themeVM.themeMode,
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => val != null ? themeVM.setTheme(val) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, AuthViewModel authVM, ExpenseViewModel expenseVM) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Data Backup & CSV Control',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.build_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Database Diagnostics'),
              subtitle: const Text('Audit and repair ledger balance drift'),
              onTap: () => DeveloperDiagnosticsSheet.show(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Export all data to CSV'),
              onTap: () async {
                final success = await ExportService.exportToCsv(expenseVM.expenses);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'CSV Export ready!' : 'Failed to export CSV.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
            const Divider(),
            if (authVM.currentUser == null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Sign in with Google to Backup'),
                onTap: () => authVM.signInWithGoogle(),
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(authVM.currentUser!.photoUrl ?? ''),
                  radius: 12,
                ),
                title: Text(authVM.currentUser!.displayName ?? 'User'),
                subtitle: Text(authVM.currentUser!.email),
                trailing: TextButton(
                  onPressed: () => authVM.signOut(),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_upload, color: Colors.green),
                title: const Text('Backup to Cloud'),
                onTap: () => _backupData(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    if (authVM.currentUser == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backing up data...')));

    try {
      final remoteDataSource = FirebaseDataSource(FirebaseFirestore.instance);

      final categoriesBox = await Hive.openBox<CategoryModel>('categories');
      final expensesBox = await Hive.openBox<ExpenseModel>('expenses');
      final accountsBox = await Hive.openBox<AccountModel>('accounts');
      final savingsBox = await Hive.openBox<SavingsModel>('savingsBox');
      final incomesBox = await Hive.openBox<IncomeModel>('incomeBox');
      final mileageBox = await Hive.openBox<MileageEntryModel>('mileageBox');
      final transferBox = await Hive.openBox<TransferModel>('transferBox');
      final goalBox = await Hive.openBox<GoalModel>('goalBox');
      final serviceBox = await Hive.openBox<ServiceModel>('serviceBox');
      final dietProfileBox = await Hive.openBox<DietProfileModel>('dietProfileBox');
      final mealEntryBox = await Hive.openBox<MealEntryModel>('mealEntryBox');

      final categoriesJson = categoriesBox.values.map((e) => e.toJson()).toList();
      final expensesJson = expensesBox.values.map((e) => e.toJson()).toList();
      final accountsJson = accountsBox.values.map((e) => e.toJson()).toList();
      final savingsJson = savingsBox.values.isNotEmpty ? savingsBox.values.first.toJson() : null;
      final incomesJson = incomesBox.values.map((e) => e.toJson()).toList();
      final mileageJson = mileageBox.values.map((e) => e.toJson()).toList();
      final transfersJson = transferBox.values.map((e) => e.toJson()).toList();
      final goalsJson = goalBox.values.map((e) => e.toJson()).toList();
      final servicesJson = serviceBox.values.map((e) => e.toJson()).toList();
      final dietProfileJson = dietProfileBox.values.isNotEmpty ? dietProfileBox.values.first.toJson() : null;
      final mealEntriesJson = mealEntryBox.values.map((e) => e.toJson()).toList();

      await remoteDataSource.backupData(
        userId: authVM.currentUser!.id,
        categories: categoriesJson,
        expenses: expensesJson,
        accounts: accountsJson,
        savings: savingsJson,
        incomes: incomesJson,
        mileages: mileageJson,
        transfers: transfersJson,
        goals: goalsJson,
        services: servicesJson,
        dietProfile: dietProfileJson,
        mealEntries: mealEntriesJson,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Backup error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencyDialog(BuildContext context, SettingsViewModel settingsVM) {
    final codeCtrl = TextEditingController(text: settingsVM.settings.currencyCode);
    final symbolCtrl = TextEditingController(text: settingsVM.settings.currencySymbol);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Currency Code (e.g. USD, INR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: symbolCtrl,
              decoration: const InputDecoration(labelText: 'Currency Symbol (e.g. \$, \u20B9)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty && symbolCtrl.text.isNotEmpty) {
                await settingsVM.updateCurrency(codeCtrl.text, symbolCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, SettingsViewModel settingsVM) {
    final ctrl = TextEditingController(text: settingsVM.settings.monthlyBudgetLimit.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget Limit'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monthly Budget Limit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                await settingsVM.updateMonthlyBudget(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSavingsGoalDialog(BuildContext context, SettingsViewModel settingsVM) {
    final ctrl = TextEditingController(text: settingsVM.settings.savingsGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Savings Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Savings Goal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                await settingsVM.updateSavingsGoal(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyFundGoalDialog(BuildContext context, SettingsViewModel settingsVM) {
    final ctrl = TextEditingController(text: settingsVM.settings.emergencyFundGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Emergency Fund Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Emergency Fund Goal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                await settingsVM.updateEmergencyFundGoal(val);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, SettingsViewModel settingsVM) {
    final ctrl = TextEditingController(text: settingsVM.settings.securityPin);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Passcode PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN (digits only)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await settingsVM.updateSecurityPin(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
