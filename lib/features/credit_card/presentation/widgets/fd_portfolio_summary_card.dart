import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/fd_lot_entity.dart';

class FdPortfolioSummaryCard extends StatelessWidget {
  final List<FdLotEntity> fdLots;
  final VoidCallback onAddFdTap;

  const FdPortfolioSummaryCard({
    super.key,
    required this.fdLots,
    required this.onAddFdTap,
  });

  @override
  Widget build(BuildContext context) {
    final double totalPrincipal = fdLots.fold(0.0, (sum, fd) => sum + fd.principal);
    final double totalValue = fdLots.fold(0.0, (sum, fd) => sum + fd.currentValue);
    final double totalInterest = (totalValue - totalPrincipal).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: Colors.teal, size: 18),
                  SizedBox(width: 8),
                  Text('FD Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 6),
                  Text('(6.0% Daily)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: onAddFdTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        'New FD',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricTile('Principal', '$currencySymbol${totalPrincipal.toStringAsFixed(0)}', Colors.grey),
              _buildMetricTile('Current Value', '$currencySymbol${totalValue.toStringAsFixed(2)}', Colors.teal),
              _buildMetricTile('Total Interest', '+$currencySymbol${totalInterest.toStringAsFixed(2)}', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
