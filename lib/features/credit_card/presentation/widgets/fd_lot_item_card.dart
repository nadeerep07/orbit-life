import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/fd_lot_entity.dart';

class FdLotItemCard extends StatelessWidget {
  final FdLotEntity fdLot;
  final ValueChanged<String> onWithdrawTap;

  const FdLotItemCard({
    super.key,
    required this.fdLot,
    required this.onWithdrawTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = fdLot.isLocked;
    final lockText = isLocked ? 'Unlocks in ${fdLot.daysUntilUnlock}d' : 'Unlocked';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isLocked ? Colors.orange : Colors.green).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
              size: 16,
              color: isLocked ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'FD • $currencySymbol${fdLot.principal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(+$currencySymbol${fdLot.interestEarned.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Credit Boost: +$currencySymbol${fdLot.creditLimitContribution.toStringAsFixed(0)} • $lockText',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isLocked ? null : () => onWithdrawTap(fdLot.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked ? Colors.grey.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.12),
              foregroundColor: isLocked ? Colors.grey : Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isLocked ? 'Locked' : 'Withdraw',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
