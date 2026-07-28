import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/transfer_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import '../widgets/custom_snackbar.dart';
class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransferViewModel>().loadTransfers();
    });
  }

  String _getAccountName(String id, AccountsViewModel accountsVM) {
    if (id == 'savings') return 'Savings';

    try {
      return accountsVM.accounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transferVM = context.watch<TransferViewModel>();
    final accountsVM = context.watch<AccountsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer History')),

      body: transferVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transferVM.transfers.isEmpty
          ? const Center(child: Text('No transfers found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transferVM.transfers.length,

              itemBuilder: (context, index) {
                final t = transferVM.transfers[index];

                final fromName = _getAccountName(t.fromAccountId, accountsVM);

                final toName = _getAccountName(t.toAccountId, accountsVM);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),

                  child: Dismissible(
                    key: Key(t.id),

                    direction: DismissDirection.endToStart,

                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),

                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    onDismissed: (_) {
                      transferVM.deleteTransfer(t);
                      AppSnackBar.show(
                        context,
                        message: 'Transfer deleted',
                        isError: false,
                      );
                    },

                    child: IOSCard(
                      padding: const EdgeInsets.all(14),

                      child: Row(
                        children: [
                          /// LEFT SECTION (Account names + date)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// ACCOUNT TRANSFER ROW
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fromName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Icon(
                                        Icons.arrow_right_alt,
                                        size: 18,
                                      ),
                                    ),

                                    Flexible(
                                      child: Text(
                                        toName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                /// DATE
                                Text(
                                  DateFormat('dd MMM yyyy').format(t.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),

                                /// DESCRIPTION
                                if (t.description.isNotEmpty)
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          /// RIGHT SIDE AMOUNT
                          const SizedBox(width: 10),

                          Text(
                            "₹${t.amount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
