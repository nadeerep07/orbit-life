import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/statement_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/credit_card_statement_entity.dart';

class StatementHistoryScreen extends StatefulWidget {
  const StatementHistoryScreen({super.key});

  @override
  State<StatementHistoryScreen> createState() => _StatementHistoryScreenState();
}

class _StatementHistoryScreenState extends State<StatementHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StatementBloc>().add(LoadStatementsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Statements', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<StatementBloc, StatementState>(
        builder: (context, state) {
          if (state is StatementLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StatementLoadedState) {
            if (state.statements.isEmpty) {
              return const Center(
                child: Text('No historical billing statements generated yet.', style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.statements.length,
              itemBuilder: (context, index) {
                final stmt = state.statements[index];
                return _StatementTile(statement: stmt);
              },
            );
          }
          return const Center(child: Text('Generate statement on 1st of month'));
        },
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  final CreditCardStatementEntity statement;

  const _StatementTile({required this.statement});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(statement.statementDate);
    final isPaid = statement.status == StatementStatus.paid;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statement.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Statement Amt: $currencySymbol${statement.closingOutstanding.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Min Due: $currencySymbol${statement.minimumDue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Due Date: ${DateFormat('dd MMM yyyy').format(statement.dueDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
