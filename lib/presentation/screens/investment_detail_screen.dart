import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/investment_view_model.dart';
import '../../domain/entities/investment_entity.dart';

class InvestmentDetailScreen extends StatefulWidget {
  final InvestmentEntity investment;
  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  State<InvestmentDetailScreen> createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends State<InvestmentDetailScreen> {
  late TextEditingController _currentValueCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentValueCtrl = TextEditingController(
      text: widget.investment.currentValue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _currentValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.investment;

    final double profitLoss = inv.currentValue - inv.investedAmount;
    final bool isProfit = profitLoss >= 0;
    final double profitPercent = (profitLoss / inv.investedAmount) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final double? newVal = double.tryParse(_currentValueCtrl.text);
                if (newVal != null) {
                  final updated = InvestmentEntity(
                    id: inv.id,
                    name: inv.name,
                    type: inv.type,
                    investedAmount: inv.investedAmount,
                    currentValue: newVal,
                    quantity: inv.quantity,
                    buyPrice: inv.buyPrice,
                    date: inv.date,
                    notes: inv.notes,
                  );
                  await context.read<InvestmentViewModel>().updateInvestment(
                    updated,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildValueCard(
                context,
                inv,
                profitLoss,
                isProfit,
                profitPercent,
              ),
              const SizedBox(height: 16),
              _buildDetailsList(context, inv),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard(
    BuildContext context,
    InvestmentEntity inv,
    double profitLoss,
    bool isProfit,
    double profitPercent,
  ) {
    return IOSCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Current Value',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            TextField(
              controller: _currentValueCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: UnderlineInputBorder(),
              ),
            )
          else
            Text(
              '₹${inv.currentValue.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isProfit
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isProfit
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${profitLoss.abs().toStringAsFixed(0)} (${profitPercent.abs().toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isProfit
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList(BuildContext context, InvestmentEntity inv) {
    return IOSCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildDetailRow('Investment Name', inv.name),
          _buildDetailRow('Type', inv.type.toUpperCase()),
          _buildDetailRow(
            'Total Invested',
            '₹${inv.investedAmount.toStringAsFixed(2)}',
          ),
          if (inv.quantity != null)
            _buildDetailRow('Quantity/Units', inv.quantity!.toStringAsFixed(2)),
          if (inv.buyPrice != null)
            _buildDetailRow(
              'Average Buy Price',
              '₹${inv.buyPrice!.toStringAsFixed(2)}',
            ),
          _buildDetailRow(
            'Start Date',
            DateFormat('dd MMM yyyy').format(inv.date),
          ),
          if (inv.notes.isNotEmpty) _buildDetailRow('Notes', inv.notes),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
