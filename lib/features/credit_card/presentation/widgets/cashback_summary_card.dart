import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/credit_card_account_entity.dart';

class CashbackSummaryCard extends StatelessWidget {
  final CreditCardAccountEntity account;
  final VoidCallback onRedeemTap;

  const CashbackSummaryCard({
    super.key,
    required this.account,
    required this.onRedeemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CASHBACK WALLET',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
              ),
              Icon(Icons.stars_rounded, color: Colors.purple.shade300, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$currencySymbol${account.cashbackAvailable.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple),
          ),
          const SizedBox(height: 6),
          Text(
            'Pending: $currencySymbol${account.cashbackPending.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: account.cashbackAvailable > 0 ? onRedeemTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withValues(alpha: 0.12),
                foregroundColor: Colors.purple,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Redeem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
