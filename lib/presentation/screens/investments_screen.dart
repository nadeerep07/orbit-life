import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/investment_view_model.dart';
import '../../core/utils/app_routes.dart';
import '../../domain/entities/investment_entity.dart';
import 'investment_detail_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvestmentViewModel>().loadInvestments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvestmentViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Portfolio')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildDashboardSummary(context, viewModel),
                  const Divider(),
                  Expanded(
                    child: viewModel.investments.isEmpty
                        ? const Center(
                            child: Text('No investments yet. Add one!'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: viewModel.investments.length,
                            itemBuilder: (context, index) {
                              final inv = viewModel.investments[index];
                              return _buildInvestmentCard(
                                context,
                                inv,
                                viewModel,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addInvestment),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardSummary(
    BuildContext context,
    InvestmentViewModel viewModel,
  ) {
    final double profitLoss = viewModel.totalProfitLoss;
    final bool isProfit = profitLoss >= 0;

    return IOSCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Portfolio Value',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${viewModel.currentPortfolioValue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Invested',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${viewModel.totalInvested.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Return',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isProfit
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                      Text(
                        '₹${profitLoss.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isProfit
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    InvestmentEntity inv,
    InvestmentViewModel viewModel,
  ) {
    final double profitLoss = inv.currentValue - inv.investedAmount;
    final bool isProfit = profitLoss >= 0;

    IconData typeIcon;
    switch (inv.type) {
      case 'stock':
        typeIcon = Icons.show_chart;
        break;
      case 'sip':
        typeIcon = Icons.auto_graph;
        break;
      default:
        typeIcon = Icons.domain;
    }

    return Dismissible(
      key: Key(inv.id),
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
        viewModel.deleteInvestment(inv.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Investment deleted')));
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvestmentDetailScreen(investment: inv),
            ),
          );
        },
        child: IOSCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  typeIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invested: ₹${inv.investedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${inv.currentValue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isProfit ? '+' : '-'}₹${profitLoss.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isProfit
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
