import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../viewmodels/accounts_view_model.dart';
import '../viewmodels/savings_view_model.dart';
import 'custom_snackbar.dart';

class DeveloperDiagnosticsSheet extends StatefulWidget {
  const DeveloperDiagnosticsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DeveloperDiagnosticsSheet(),
    );
  }

  @override
  State<DeveloperDiagnosticsSheet> createState() => _DeveloperDiagnosticsSheetState();
}

class _DeveloperDiagnosticsSheetState extends State<DeveloperDiagnosticsSheet> {
  bool _isPerformingAudit = false;
  Map<String, _AccountAuditResult> _auditResults = {};
  int _totalTransactionsCount = 0;
  bool _savingsPassed = true;
  double _savingsStored = 0;
  double _savingsCalculated = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDiagnostics();
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isPerformingAudit = true;
    });

    final txRepo = context.read<TransactionRepository>();
    final accountsVM = context.read<AccountsViewModel>();
    final savingsVM = context.read<SavingsViewModel>();

    // Reload accounts
    await accountsVM.loadAccounts();
    await savingsVM.loadSavings();

    final allTransactions = await txRepo.getAllTransactions();
    _totalTransactionsCount = allTransactions.length;

    // Audit Accounts
    final Map<String, _AccountAuditResult> results = {};
    for (var acc in accountsVM.accounts) {
      double calculated = 0;
      for (var tx in allTransactions) {
        if (tx.accountId == acc.id) {
          if (tx.type == TransactionType.income || tx.type == TransactionType.borrow) {
            calculated += tx.amount;
          } else {
            calculated -= tx.amount;
          }
        }
        if (tx.targetAccountId == acc.id) {
          if (tx.type == TransactionType.transfer || tx.type == TransactionType.savings) {
            calculated += tx.amount;
          }
        }
      }

      results[acc.id] = _AccountAuditResult(
        accountName: acc.name,
        storedBalance: acc.openingBalance,
        calculatedBalance: calculated,
      );
    }

    // Audit Savings
    double savingsAdded = 0.0;
    double savingsDebited = 0.0;
    for (var tx in allTransactions) {
      if (tx.targetAccountId == 'savings') {
        savingsAdded += tx.amount;
      }
      if (tx.accountId == 'savings') {
        savingsDebited += tx.amount;
      }
    }
    _savingsStored = savingsVM.savings?.currentBalance ?? 0.0;
    _savingsCalculated = savingsAdded - savingsDebited;
    _savingsPassed = (_savingsStored - _savingsCalculated).abs() < 0.01;

    setState(() {
      _auditResults = results;
      _isPerformingAudit = false;
    });
  }

  Future<void> _repairLedger() async {
    setState(() {
      _isPerformingAudit = true;
    });

    final txRepo = context.read<TransactionRepository>();
    await txRepo.recalculateBalances();
    await _runDiagnostics();

    if (mounted) {
      AppSnackBar.show(
        context,
        message: "Ledger repaired successfully. Stored balances resynced.",
        isError: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Developer Diagnostics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isPerformingAudit ? null : _runDiagnostics,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              if (_isPerformingAudit)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Auditing local ledger transactions..."),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      // Summary Card
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.primary.withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ledger Summary",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text("Total Transactions in Log: $_totalTransactionsCount"),
                              const SizedBox(height: 4),
                              Text(
                                "Database Health Status: ${_isHealthy() ? 'PASSED ✅' : 'DISCREPANCY DETECTED ⚠️'}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isHealthy() ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Accounts Auditing",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._auditResults.values.map((res) {
                        final diff = (res.storedBalance - res.calculatedBalance).abs();
                        final passed = diff < 0.01;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: passed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    res.accountName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    passed ? "PASS" : "DRIFT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: passed ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Stored: $currencySymbol${res.storedBalance.toStringAsFixed(2)}"),
                                  Text("Calculated: $currencySymbol${res.calculatedBalance.toStringAsFixed(2)}"),
                                ],
                              ),
                              if (!passed) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Difference: $currencySymbol${(res.storedBalance - res.calculatedBalance).toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ]
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text(
                        "Virtual Savings Auditing",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _savingsPassed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Savings Pool",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _savingsPassed ? "PASS" : "DRIFT",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _savingsPassed ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Stored: $currencySymbol${_savingsStored.toStringAsFixed(2)}"),
                                Text("Calculated: $currencySymbol${_savingsCalculated.toStringAsFixed(2)}"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build_outlined, color: Colors.white),
                        label: const Text("Recalculate & Repair Ledger", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _repairLedger,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isHealthy() {
    if (!_savingsPassed) return false;
    for (var res in _auditResults.values) {
      if ((res.storedBalance - res.calculatedBalance).abs() >= 0.01) {
        return false;
      }
    }
    return true;
  }
}

class _AccountAuditResult {
  final String accountName;
  final double storedBalance;
  final double calculatedBalance;

  _AccountAuditResult({
    required this.accountName,
    required this.storedBalance,
    required this.calculatedBalance,
  });
}
