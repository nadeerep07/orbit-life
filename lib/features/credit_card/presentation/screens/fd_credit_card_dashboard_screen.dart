import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/credit_card_bloc.dart';
import '../blocs/fd_lots_bloc.dart';
import '../blocs/statement_bloc.dart';
import '../blocs/cashback_bloc.dart';
import '../../domain/entities/credit_card_account_entity.dart';
import '../../domain/entities/fd_lot_entity.dart';
import '../widgets/credit_gauge_card.dart';
import '../widgets/outstanding_due_card.dart';
import '../widgets/fd_portfolio_summary_card.dart';
import '../widgets/fd_lot_item_card.dart';
import '../widgets/cashback_summary_card.dart';
import '../widgets/quick_actions_row.dart';
import 'add_fd_deposit_screen.dart';
import 'credit_card_payment_screen.dart';
import 'statement_history_screen.dart';
import 'import_statement_screen.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../presentation/widgets/custom_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../presentation/viewmodels/accounts_view_model.dart';

class FdCreditCardDashboardScreen extends StatefulWidget {
  const FdCreditCardDashboardScreen({super.key});

  @override
  State<FdCreditCardDashboardScreen> createState() => _FdCreditCardDashboardScreenState();
}

class _FdCreditCardDashboardScreenState extends State<FdCreditCardDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshAllData(context);
      }
    });
  }

  void _refreshAllData(BuildContext context) {
    context.read<CreditCardBloc>().add(LoadCreditCardAccountEvent());
    context.read<FdLotsBloc>().add(LoadFdLotsEvent());
    context.read<StatementBloc>().add(LoadStatementsEvent());
    context.read<CashbackBloc>().add(LoadCashbackEvent());
    context.read<AccountsViewModel>().loadAccounts();
  }

  void _onWithdraw(BuildContext context, String fdId) {
    context.read<FdLotsBloc>().add(WithdrawFdEvent(fdId));
  }

  void _showRedeemCashbackModal(BuildContext context, CreditCardAccountEntity account) {
    final amountController = TextEditingController(text: account.cashbackAvailable.toStringAsFixed(0));
    String selectedDest = 'sbi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final accountsVM = ctx.watch<AccountsViewModel>();
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Redeem Cashback Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Available Cashback: $currencySymbol${account.cashbackAvailable.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Redemption Amount ($currencySymbol)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destination dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDest,
                    decoration: InputDecoration(
                      labelText: 'Credit Destination Account',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: [
                      ...accountsVM.accounts
                          .where((a) => a.id != 'supermoney')
                          .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${currencySymbol}${a.openingBalance.toStringAsFixed(0)})'))),
                      const DropdownMenuItem(value: 'credit_payment', child: Text('Credit Card Bill Settlement')),
                      const DropdownMenuItem(value: 'fd', child: Text('Reinvest in New FD')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedDest = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                       if (amount <= 0 || amount > account.cashbackAvailable) {
                        AppSnackBar.show(
                          context,
                          message: 'Invalid redemption amount',
                          isError: true,
                        );
                        return;
                      }

                      context.read<CashbackBloc>().add(
                            RedeemCashbackEvent(
                              amount: amount,
                              destinationType: (selectedDest == 'credit_payment' || selectedDest == 'fd') ? selectedDest : 'bank',
                              targetAccountId: (selectedDest == 'credit_payment' || selectedDest == 'fd') ? null : selectedDest,
                            ),
                          );

                      Navigator.pop(ctx);
                    },
                    child: const Text('Confirm & Credit Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCardModal(BuildContext context, CreditCardAccountEntity account) {
    final fdState = context.read<FdLotsBloc>().state;
    final totalFd = (fdState is FdLotsLoadedState)
        ? fdState.lots.where((l) => l.status != FdStatus.withdrawn).fold<double>(0.0, (s, l) => s + (l.currentValue > 0 ? l.currentValue : l.principal))
        : 0.0;
    final recommendedLimit = (totalFd * 0.90).roundToDouble();

    final nameCtrl = TextEditingController(text: account.name);
    final limitCtrl = TextEditingController(text: account.creditLimit.toStringAsFixed(0));
    final usedCtrl = TextEditingController(text: account.usedCredit.toStringAsFixed(0));
    final stmtCtrl = TextEditingController(text: account.statementDateDay.toString());
    final dueCtrl = TextEditingController(text: account.dueDateDay.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Card Settings & Limit Reconcile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (totalFd > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Active FD Backing:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('$currencySymbol${totalFd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('90% Backed Limit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('$currencySymbol${recommendedLimit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amberAccent,
                                  side: const BorderSide(color: Colors.amberAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: const Text('Reconcile Limit to 90% of FDs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setModalState(() {
                                    limitCtrl.text = recommendedLimit.toStringAsFixed(0);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Card Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Total Credit Limit ($currencySymbol)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Current Used / Outstanding Due ($currencySymbol)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stmtCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Statement Day',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: dueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Due Day',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final newLimit = double.tryParse(limitCtrl.text.trim()) ?? account.creditLimit;
                        final newUsed = double.tryParse(usedCtrl.text.trim()) ?? account.usedCredit;
                        final newAvailable = (newLimit - newUsed).clamp(0.0, newLimit);
                        final newStmtDay = int.tryParse(stmtCtrl.text.trim()) ?? account.statementDateDay;
                        final newDueDay = int.tryParse(dueCtrl.text.trim()) ?? account.dueDateDay;

                        final updated = account.copyWith(
                          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : account.name,
                          creditLimit: newLimit,
                          usedCredit: newUsed,
                          availableCredit: newAvailable,
                          statementDateDay: newStmtDay,
                          dueDateDay: newDueDay,
                          lastUpdated: DateTime.now(),
                        );

                        context.read<CreditCardBloc>().add(UpdateCreditCardAccountEvent(updated));
                        Navigator.pop(ctx);
                        AppSnackBar.show(context, message: 'Credit card settings saved successfully', isError: false);
                        _refreshAllData(context);
                      },
                      child: const Text('Save Card Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Credit Card', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          BlocBuilder<CreditCardBloc, CreditCardState>(
            builder: (context, state) {
              if (state is CreditCardLoadedState) {
                return IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _showEditCardModal(context, state.account),
                  tooltip: 'Card Settings & Reconcile Limit',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementHistoryScreen())).then((_) => _refreshAllData(context)),
            tooltip: 'Billing Statements',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<FdLotsBloc, FdLotsState>(
            listener: (context, state) {
              if (state is FdLotsErrorState) {
                AppSnackBar.show(context, message: state.message, isError: true);
              } else if (state is FdWithdrawSuccessState || state is FdDepositSuccessState) {
                _refreshAllData(context);
              }
            },
          ),
          BlocListener<StatementBloc, StatementState>(
            listener: (context, state) {
              if (state is StatementErrorState) {
                AppSnackBar.show(context, message: state.message, isError: true);
              } else if (state is PaymentSuccessState) {
                AppSnackBar.show(context, message: state.message, isError: false);
                _refreshAllData(context);
              }
            },
          ),
          BlocListener<CashbackBloc, CashbackState>(
            listener: (context, state) {
              if (state is CashbackErrorState) {
                AppSnackBar.show(context, message: state.message, isError: true);
              } else if (state is CashbackRedeemSuccessState) {
                AppSnackBar.show(context, message: state.message, isError: false, icon: Icons.stars_rounded);
                _refreshAllData(context);
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Credit Gauge Card
              BlocBuilder<CreditCardBloc, CreditCardState>(
                builder: (context, state) {
                  if (state is CreditCardLoadedState) {
                    return CreditGaugeCard(account: state.account);
                  }
                  return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
                },
              ),

              const SizedBox(height: 12),

              // 2. Quick Actions
              QuickActionsRow(
                onAddExpenseTap: () => Navigator.pushNamed(context, AppRoutes.addExpense).then((_) => _refreshAllData(context)),
                onPayBillTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditCardPaymentScreen())).then((_) => _refreshAllData(context)),
                onAddFdTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFdDepositScreen())).then((_) => _refreshAllData(context)),
                onImportStatementTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportStatementScreen())).then((_) => _refreshAllData(context)),
              ),

              const SizedBox(height: 12),

              // 3. Outstanding Due & Cashback Side-by-Side Grid
              BlocBuilder<CreditCardBloc, CreditCardState>(
                builder: (context, state) {
                  if (state is CreditCardLoadedState) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: OutstandingDueCard(
                              account: state.account,
                              onPayNowTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditCardPaymentScreen())).then((_) => _refreshAllData(context)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CashbackSummaryCard(
                              account: state.account,
                              onRedeemTap: () => _showRedeemCashbackModal(context, state.account),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 14),

              // 4. FD Portfolio Summary Card
              BlocBuilder<FdLotsBloc, FdLotsState>(
                builder: (context, state) {
                  if (state is FdLotsLoadedState) {
                    return FdPortfolioSummaryCard(
                      fdLots: state.lots,
                      onAddFdTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFdDepositScreen())).then((_) => _refreshAllData(context)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 16),

              // 5. FD Lots List Header
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'ACTIVE FIXED DEPOSITS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                ),
              ),

              // 6. FD Lots List
              BlocBuilder<FdLotsBloc, FdLotsState>(
                builder: (context, state) {
                  if (state is FdLotsLoadedState) {
                    if (state.lots.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No active Fixed Deposits found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.lots.length,
                      itemBuilder: (context, index) {
                        return FdLotItemCard(
                          fdLot: state.lots[index],
                          onWithdrawTap: (fdId) => _onWithdraw(context, fdId),
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
