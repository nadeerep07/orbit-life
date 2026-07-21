import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddExpenseTap;
  final VoidCallback onPayBillTap;
  final VoidCallback onAddFdTap;
  final VoidCallback onImportStatementTap;

  const QuickActionsRow({
    super.key,
    required this.onAddExpenseTap,
    required this.onPayBillTap,
    required this.onAddFdTap,
    required this.onImportStatementTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildActionBtn(context, Icons.shopping_bag_outlined, 'Card Expense', Colors.redAccent, onAddExpenseTap),
          _buildActionBtn(context, Icons.payments_outlined, 'Pay Bill', Colors.green, onPayBillTap),
          _buildActionBtn(context, Icons.add_circle_outline, 'New FD', Colors.teal, onAddFdTap),
          _buildActionBtn(context, Icons.file_upload_outlined, 'Import Stmt', Colors.blue, onImportStatementTap),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 105,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
