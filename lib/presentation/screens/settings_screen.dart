import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/export_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/income_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../viewmodels/theme_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/borrow_lend_view_model.dart';
import '../viewmodels/emi_tracker_view_model.dart';
import '../viewmodels/investment_view_model.dart';
import '../viewmodels/goals_view_model.dart';
import '../viewmodels/transfer_view_model.dart';
import '../viewmodels/mileage_view_model.dart';
import '../viewmodels/service_view_model.dart';
import '../viewmodels/diet_view_model.dart';
import '../widgets/developer_diagnostics_sheet.dart';
import '../widgets/modern_budget_target_dialog.dart';
import '../../core/services/local_auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../data/models/transaction_model.dart';
import '../../data/models/borrow_lend_model.dart';
import '../../data/models/emi_tracker_model.dart';
import '../../data/models/investment_model.dart';
import '../../features/credit_card/data/models/credit_card_account_model.dart';
import '../../features/credit_card/data/models/fd_lot_model.dart';
import '../../features/credit_card/data/models/credit_card_statement_model.dart';
import '../../features/credit_card/data/models/cashback_transaction_model.dart';
import '../../core/services/cloud_sync_service.dart';
import '../widgets/custom_snackbar.dart';
import '../../features/credit_card/presentation/blocs/credit_card_bloc.dart';
import '../../features/credit_card/presentation/blocs/fd_lots_bloc.dart';
import '../../features/credit_card/presentation/blocs/statement_bloc.dart';
import '../../features/credit_card/presentation/blocs/cashback_bloc.dart';

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
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section 1: Hero User Profile Banner ─────────────────────────────
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthViewModel authVM) {
    final user = authVM.currentUser;
    final settings = context.watch<SettingsViewModel>().settings;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bannerGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF022C22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bannerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: user != null && user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: user == null || user.photoUrl == null
                  ? Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Pro Financial Specialist',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? 'Cloud Sync Active',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: Text(
              '${settings.currencyCode} (${settings.currencySymbol})',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStrategyCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return _buildSectionContainer(
      context: context,
      icon: Icons.insights_rounded,
      title: 'Financial Mode & Strategy',
      children: [
        _buildCustomSwitchRow(
          context,
          title: 'Auto Money Allocation',
          subtitle: 'Direct incoming salaries to mandatory budgets automatically',
          value: settings.enableAutoAllocation,
          onChanged: (val) => settingsVM.updateAutoAllocation(val),
        ),
        const SizedBox(height: 16),
        const Text(
          'SELECT OPERATING MODE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => settingsVM.updateFinancialMode(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : (isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.3) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade400,
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                radius: 5,
                backgroundColor: isSelected ? accentColor : Colors.transparent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isSelected ? accentColor : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.8)
                          : (isDarkMode ? Colors.white38 : const Color(0xFF64748B)),
                    ),
                  ),
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
    return _buildSectionContainer(
      context: context,
      icon: Icons.account_balance_wallet_rounded,
      title: 'Budgets & Safety Targets',
      children: [
        _buildCustomSettingsRow(
          context,
          title: 'Currency Settings',
          value: '${settings.currencyCode} (${settings.currencySymbol})',
          onTap: () => _showCurrencyDialog(context, settingsVM),
        ),
        const SizedBox(height: 12),
        _buildCustomSettingsRow(
          context,
          title: 'Monthly Budget Limit',
          value: CurrencyFormatter.format(settings.monthlyBudgetLimit),
          onTap: () => _showBudgetDialog(context, settingsVM),
        ),
        const SizedBox(height: 12),
        _buildCustomSettingsRow(
          context,
          title: 'Savings Target Goal',
          value: CurrencyFormatter.format(settings.savingsGoal),
          onTap: () => _showSavingsGoalDialog(context, settingsVM),
        ),
        const SizedBox(height: 12),
        _buildCustomSettingsRow(
          context,
          title: 'Emergency Fund Target',
          value: CurrencyFormatter.format(settings.emergencyFundGoal),
          onTap: () => _showEmergencyFundGoalDialog(context, settingsVM),
        ),
      ],
    );
  }

  Widget _buildDailyRulesCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return _buildSectionContainer(
      context: context,
      icon: Icons.auto_awesome_rounded,
      title: 'Daily Spending Rules',
      children: [
        _buildCustomSwitchRow(
          context,
          title: 'Limit Rollover',
          subtitle: 'Roll over unspent daily budget to next days',
          value: settings.dailyLimitRollover,
          onChanged: (val) => settingsVM.updateDailyLimitRollover(val),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(BuildContext context, SettingsViewModel settingsVM) {
    final settings = settingsVM.settings;
    return _buildSectionContainer(
      context: context,
      icon: Icons.shield_rounded,
      title: 'Security & Privacy',
      children: [
        _buildCustomSwitchRow(
          context,
          title: 'Biometrics / PIN App Lock',
          subtitle: 'Secure access to sensitive financial logs',
          value: settings.enableBiometrics,
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
        const SizedBox(height: 12),
        _buildCustomSettingsRow(
          context,
          title: 'Passcode PIN',
          value: settings.securityPin.isEmpty ? 'Not Configured' : 'Active Passcode',
          onTap: () => _showPinDialog(context, settingsVM),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(BuildContext context, ThemeViewModel themeVM) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return _buildSectionContainer(
      context: context,
      icon: Icons.palette_rounded,
      title: 'Appearance Mode',
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => themeVM.setTheme(ThemeMode.light),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: themeVM.themeMode == ThemeMode.light
                        ? accentColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: themeVM.themeMode == ThemeMode.light
                          ? accentColor
                          : Theme.of(context).dividerColor.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        color: themeVM.themeMode == ThemeMode.light ? accentColor : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Light Theme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeVM.themeMode == ThemeMode.light ? accentColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => themeVM.setTheme(ThemeMode.dark),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: themeVM.themeMode == ThemeMode.dark
                        ? accentColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: themeVM.themeMode == ThemeMode.dark
                          ? accentColor
                          : Theme.of(context).dividerColor.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.dark_mode_rounded,
                        color: themeVM.themeMode == ThemeMode.dark ? accentColor : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dark Theme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeVM.themeMode == ThemeMode.dark ? accentColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomSettingsRow(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.04)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? Colors.white24 : Colors.black26,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSwitchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white38 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, AuthViewModel authVM, ExpenseViewModel expenseVM) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Backup & Cloud Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Secure your diagnostics, exports, and cloud logs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Diagnostics and CSV Actions
          _buildAdvancedSettingsTile(
            context,
            icon: Icons.analytics_outlined,
            iconBgColor: const Color(0xFF06B6D4).withValues(alpha: 0.15),
            iconColor: const Color(0xFF06B6D4),
            title: 'Database Diagnostics',
            subtitle: 'Audit and repair ledger balance drift',
            onTap: () => DeveloperDiagnosticsSheet.show(context),
          ),
          const SizedBox(height: 12),
          _buildAdvancedSettingsTile(
            context,
            icon: Icons.table_view_rounded,
            iconBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            iconColor: const Color(0xFFF59E0B),
            title: 'Export all data to CSV',
            subtitle: 'Generate offline spreadsheet records',
            onTap: () async {
              final success = await ExportService.exportToCsv(expenseVM.expenses);
              if (context.mounted) {
                AppSnackBar.show(
                  context,
                  message: success ? 'CSV Export ready!' : 'Failed to export CSV.',
                  isError: !success,
                );
              }
            },
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1),
          ),

          // User Profile Section
          if (authVM.currentUser == null) ...[
            // Sign In Required
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cloud Sync Disabled',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sign in to secure details',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white38 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = await authVM.signInWithGoogle();
                        if (user != null && context.mounted) {
                          AppSnackBar.show(
                            context,
                            message: 'Signed in as ${user.displayName ?? user.email}',
                            isError: false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackBar.show(
                            context,
                            message: 'Google Sign-In failed: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Profile Card with Sign Out
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(authVM.currentUser!.photoUrl ?? ''),
                      radius: 20,
                      backgroundColor: Colors.grey.shade800,
                      child: authVM.currentUser!.photoUrl == null
                          ? Text(
                              (authVM.currentUser!.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authVM.currentUser!.displayName ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authVM.currentUser!.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white38 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showLogoutDialog(context, authVM),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                      ),
                    ),
                    child: const Text('Sign Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Backup and Restore Buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _backupData(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(height: 6),
                          Text(
                            'Backup to Cloud',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _restoreData(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_download_rounded, color: Color(0xFF3B82F6), size: 20),
                          SizedBox(height: 6),
                          Text(
                            'Restore from Cloud',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1),
          ),

          // Hard Reset Option
          InkWell(
            onTap: () => _handleFullHardReset(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hard Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Clear all local data and erase Firebase cloud backup',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white38 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.redAccent.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white38 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode ? Colors.white24 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFullHardReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hard Reset All Data?'),
          ],
        ),
        content: const Text(
          'This action will PERMANENTLY erase all your local app data (transactions, accounts, budgets, credit cards, investments, diet profiles, etc.) AND delete your backup stored on Firebase Cloud.\n\nThis cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      CloudSyncService.isSyncPaused = true;

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
      final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');
      final borrowLendBox = await Hive.openBox<BorrowLendModel>('borrowLendBox');
      final emiTrackerBox = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
      final investmentBox = await Hive.openBox<InvestmentModel>('investmentBox');
      final ccAccountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
      final fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
      final statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
      final cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');

      await categoriesBox.clear();
      await expensesBox.clear();
      await accountsBox.clear();
      await savingsBox.clear();
      await incomesBox.clear();
      await mileageBox.clear();
      await transferBox.clear();
      await goalBox.clear();
      await serviceBox.clear();
      await dietProfileBox.clear();
      await mealEntryBox.clear();
      await transactionBox.clear();
      await borrowLendBox.clear();
      await emiTrackerBox.clear();
      await investmentBox.clear();
      await ccAccountBox.clear();
      await fdBox.clear();
      await statementBox.clear();
      await cashbackBox.clear();

      if (await Hive.boxExists('settingsBox')) {
        final settingsBox = await Hive.openBox('settingsBox');
        await settingsBox.clear();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final remoteDataSource = FirebaseDataSource(FirebaseFirestore.instance);
        await remoteDataSource.deleteUserData(user.uid);
      }

      if (context.mounted) {
        final currentMonth = context.read<MonthViewModel>().currentMonth;
        context.read<BudgetViewModel>().loadCategories(currentMonth);
        context.read<ExpenseViewModel>().loadExpenses();
        context.read<AccountsViewModel>().loadAccounts();
        context.read<SavingsViewModel>().loadSavings();
        context.read<IncomeViewModel>().loadIncomes();
        context.read<TransferViewModel>().loadTransfers();
        context.read<GoalsViewModel>().loadGoals();
        context.read<ServiceViewModel>().loadServices();
        context.read<DietViewModel>().loadDietData();
        context.read<EmiTrackerViewModel>().loadEmis();
        context.read<BorrowLendViewModel>().loadEntries();
        context.read<InvestmentViewModel>().loadInvestments();
        context.read<MileageViewModel>().loadEntries();
        context.read<CreditCardBloc>().add(LoadCreditCardAccountEvent());
        context.read<FdLotsBloc>().add(LoadFdLotsEvent());
        context.read<StatementBloc>().add(LoadStatementsEvent());
        context.read<CashbackBloc>().add(LoadCashbackEvent());

        AppSnackBar.show(
          context,
          message: 'Hard Reset completed successfully. All local data and Firebase cloud backup cleared.',
          isError: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Hard Reset failed: $e',
          isError: true,
        );
      }
    } finally {
      CloudSyncService.isSyncPaused = false;
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    if (authVM.currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data from Cloud?'),
        content: const Text(
          'This will overwrite your current local data with the backed up data from Cloud Firestore. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    AppSnackBar.show(context, message: 'Restoring data from cloud...', isError: false, icon: Icons.cloud_download_outlined);

    try {
      CloudSyncService.isSyncPaused = true;
      final remoteDataSource = FirebaseDataSource(FirebaseFirestore.instance);
      final data = await remoteDataSource.restoreData(authVM.currentUser!.id);

      if (data == null) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: 'No cloud backup found for this Google account.',
            isError: true,
          );
        }
        return;
      }

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
      final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');
      final borrowLendBox = await Hive.openBox<BorrowLendModel>('borrowLendBox');
      final emiTrackerBox = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
      final investmentBox = await Hive.openBox<InvestmentModel>('investmentBox');

      if (data['categories'] != null) {
        await categoriesBox.clear();
        for (var item in (data['categories'] as List)) {
          final cat = CategoryModel.fromJson(Map<String, dynamic>.from(item));
          await categoriesBox.put(cat.id, cat);
        }
      }

      if (data['expenses'] != null) {
        await expensesBox.clear();
        for (var item in (data['expenses'] as List)) {
          final exp = ExpenseModel.fromJson(Map<String, dynamic>.from(item));
          await expensesBox.put(exp.id, exp);
        }
      }

      if (data['accounts'] != null) {
        await accountsBox.clear();
        for (var item in (data['accounts'] as List)) {
          final acc = AccountModel.fromJson(Map<String, dynamic>.from(item));
          await accountsBox.put(acc.id, acc);
        }
      }

      if (data['savings'] != null) {
        await savingsBox.clear();
        final sav = SavingsModel.fromJson(Map<String, dynamic>.from(data['savings']));
        await savingsBox.put(sav.id, sav);
      }

      if (data['incomes'] != null) {
        await incomesBox.clear();
        for (var item in (data['incomes'] as List)) {
          final inc = IncomeModel.fromJson(Map<String, dynamic>.from(item));
          await incomesBox.put(inc.id, inc);
        }
      }

      if (data['mileages'] != null) {
        await mileageBox.clear();
        for (var item in (data['mileages'] as List)) {
          final m = MileageEntryModel.fromJson(Map<String, dynamic>.from(item));
          await mileageBox.put(m.id, m);
        }
      }

      if (data['transfers'] != null) {
        await transferBox.clear();
        for (var item in (data['transfers'] as List)) {
          final t = TransferModel.fromJson(Map<String, dynamic>.from(item));
          await transferBox.put(t.id, t);
        }
      }

      if (data['goals'] != null) {
        await goalBox.clear();
        for (var item in (data['goals'] as List)) {
          final g = GoalModel.fromJson(Map<String, dynamic>.from(item));
          await goalBox.put(g.id, g);
        }
      }

      if (data['services'] != null) {
        await serviceBox.clear();
        for (var item in (data['services'] as List)) {
          final s = ServiceModel.fromJson(Map<String, dynamic>.from(item));
          await serviceBox.put(s.id, s);
        }
      }

      if (data['dietProfile'] != null) {
        await dietProfileBox.clear();
        final dp = DietProfileModel.fromJson(Map<String, dynamic>.from(data['dietProfile']));
        await dietProfileBox.put('main_profile', dp);
      }

      if (data['mealEntries'] != null) {
        await mealEntryBox.clear();
        for (var item in (data['mealEntries'] as List)) {
          final me = MealEntryModel.fromJson(Map<String, dynamic>.from(item));
          await mealEntryBox.put(me.id, me);
        }
      }

      if (data['transactions'] != null) {
        await transactionBox.clear();
        for (var item in (data['transactions'] as List)) {
          final tx = TransactionModel.fromJson(Map<String, dynamic>.from(item));
          await transactionBox.put(tx.id, tx);
        }
      }

      if (data['borrowLends'] != null) {
        await borrowLendBox.clear();
        for (var item in (data['borrowLends'] as List)) {
          final bl = BorrowLendModel.fromJson(Map<String, dynamic>.from(item));
          await borrowLendBox.put(bl.id, bl);
        }
      }

      if (data['emis'] != null) {
        await emiTrackerBox.clear();
        for (var item in (data['emis'] as List)) {
          final emi = EmiTrackerModel.fromJson(Map<String, dynamic>.from(item));
          await emiTrackerBox.put(emi.id, emi);
        }
      }

      if (data['investments'] != null) {
        await investmentBox.clear();
        for (var item in (data['investments'] as List)) {
          final inv = InvestmentModel.fromJson(Map<String, dynamic>.from(item));
          await investmentBox.put(inv.id, inv);
        }
      }

      final ccAccountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
      final fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
      final statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
      final cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');

      if (data['creditCardAccount'] != null) {
        await ccAccountBox.clear();
        final ccAcc = CreditCardAccountModel.fromJson(Map<String, dynamic>.from(data['creditCardAccount']));
        await ccAccountBox.put('supermoney_account', ccAcc);
      }

      if (data['fdLots'] != null) {
        await fdBox.clear();
        for (var item in (data['fdLots'] as List)) {
          final lot = FdLotModel.fromJson(Map<String, dynamic>.from(item));
          await fdBox.put(lot.id, lot);
        }
      }

      if (data['statements'] != null) {
        await statementBox.clear();
        for (var item in (data['statements'] as List)) {
          final stmt = CreditCardStatementModel.fromJson(Map<String, dynamic>.from(item));
          await statementBox.put(stmt.id, stmt);
        }
      }

      if (data['cashbacks'] != null) {
        await cashbackBox.clear();
        for (var item in (data['cashbacks'] as List)) {
          final cb = CashbackTransactionModel.fromJson(Map<String, dynamic>.from(item));
          await cashbackBox.put(cb.id, cb);
        }
      }

      if (context.mounted) {
        context.read<AccountsViewModel>().loadAccounts();
        context.read<ExpenseViewModel>().loadExpenses();
        context.read<IncomeViewModel>().loadIncomes();
        context.read<SavingsViewModel>().loadSavings();
        context.read<BorrowLendViewModel>().loadEntries();
        context.read<EmiTrackerViewModel>().loadEmis();
        context.read<InvestmentViewModel>().loadInvestments();
        context.read<GoalsViewModel>().loadGoals();
        context.read<TransferViewModel>().loadTransfers();
        context.read<MileageViewModel>().loadEntries();
        context.read<ServiceViewModel>().loadServices();
        context.read<DietViewModel>().loadDietData();
        
        context.read<CreditCardBloc>().add(LoadCreditCardAccountEvent());
        context.read<FdLotsBloc>().add(LoadFdLotsEvent());
        context.read<StatementBloc>().add(LoadStatementsEvent());
        context.read<CashbackBloc>().add(LoadCashbackEvent());

        final currentMonth = context.read<MonthViewModel>().currentMonth;
        context.read<BudgetViewModel>().loadCategories(currentMonth);

        AppSnackBar.show(
          context,
          message: 'Data restored successfully from cloud!',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint("Restore error: $e");
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Restore failed: $e',
          isError: true,
        );
      }
    } finally {
      CloudSyncService.isSyncPaused = false;
    }
  }

  Future<void> _backupData(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    if (authVM.currentUser == null) return;

    AppSnackBar.show(context, message: 'Backing up data...', isError: false, icon: Icons.cloud_upload_outlined);

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
      final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');
      final borrowLendBox = await Hive.openBox<BorrowLendModel>('borrowLendBox');
      final emiTrackerBox = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
      final investmentBox = await Hive.openBox<InvestmentModel>('investmentBox');

      final ccAccountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
      final fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
      final statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
      final cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');

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
      final transactionsJson = transactionBox.values.map((e) => e.toJson()).toList();
      final borrowLendsJson = borrowLendBox.values.map((e) => e.toJson()).toList();
      final emisJson = emiTrackerBox.values.map((e) => e.toJson()).toList();
      final investmentsJson = investmentBox.values.map((e) => e.toJson()).toList();
      final creditCardAccountJson = ccAccountBox.values.isNotEmpty ? ccAccountBox.values.first.toJson() : null;
      final fdLotsJson = fdBox.values.map((e) => e.toJson()).toList();
      final statementsJson = statementBox.values.map((e) => e.toJson()).toList();
      final cashbacksJson = cashbackBox.values.map((e) => e.toJson()).toList();

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
        transactions: transactionsJson,
        borrowLends: borrowLendsJson,
        emis: emisJson,
        investments: investmentsJson,
        creditCardAccount: creditCardAccountJson,
        fdLots: fdLotsJson,
        statements: statementsJson,
        cashbacks: cashbacksJson,
      );

      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Backup completed successfully',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint("Backup error: $e");
      if (context.mounted) {
        final isPermissionDenied = e.toString().contains('permission-denied');
        AppSnackBar.show(
          context,
          message: isPermissionDenied
              ? 'Backup failed: Firestore permission denied. Please update rules in Firebase Console.'
              : 'Backup failed: $e',
          isError: true,
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
    ModernBudgetTargetDialog.show(
      context: context,
      type: BudgetTargetType.monthlyBudget,
      initialValue: settingsVM.settings.monthlyBudgetLimit,
      onSave: (newVal) async {
        await settingsVM.updateMonthlyBudget(newVal);
      },
    );
  }

  void _showSavingsGoalDialog(BuildContext context, SettingsViewModel settingsVM) {
    ModernBudgetTargetDialog.show(
      context: context,
      type: BudgetTargetType.savingsGoal,
      initialValue: settingsVM.settings.savingsGoal,
      onSave: (newVal) async {
        await settingsVM.updateSavingsGoal(newVal);
      },
    );
  }

  void _showEmergencyFundGoalDialog(BuildContext context, SettingsViewModel settingsVM) {
    ModernBudgetTargetDialog.show(
      context: context,
      type: BudgetTargetType.emergencyFund,
      initialValue: settingsVM.settings.emergencyFundGoal,
      monthlyBudgetLimit: settingsVM.settings.monthlyBudgetLimit,
      onSave: (newVal) async {
        await settingsVM.updateEmergencyFundGoal(newVal);
      },
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

  Future<void> _showLogoutDialog(BuildContext context, AuthViewModel authVM) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cardBorderColor, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from Cloud Sync? Your local offline data will remain safe.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authVM.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
