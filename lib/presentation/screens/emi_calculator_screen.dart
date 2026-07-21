import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/emi_tracker_view_model.dart';
import '../../domain/entities/emi_tracker_entity.dart';
import 'add_emi_screen.dart';
import '../widgets/custom_snackbar.dart';

class EmiTrackerScreen extends StatefulWidget {
  const EmiTrackerScreen({super.key});

  @override
  State<EmiTrackerScreen> createState() => _EmiTrackerScreenState();
}

class _EmiTrackerScreenState extends State<EmiTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmiTrackerViewModel>().loadEmis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EmiTrackerViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("EMI Tracker")),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.emis.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.emis.length,
              itemBuilder: (context, index) {
                final emi = vm.emis[index];
                return Dismissible(
                  key: Key(emi.id),
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
                    vm.deleteEmi(emi.id);
                    AppSnackBar.show(
                      context,
                      message: "${emi.title} deleted",
                      isError: false,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: emi.isPayLater
                        ? _buildPayLaterCard(context, emi, vm)
                        : _buildEmiCard(context, emi, vm),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEmiScreen()),
          );
        },
      ),
    );
  }

  /// ─── EMI Card ───
  Widget _buildEmiCard(
    BuildContext context,
    EmiTrackerEntity emi,
    EmiTrackerViewModel vm,
  ) {
    return IOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Edit
          Row(
            children: [
              Expanded(
                child: Text(
                  emi.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEmiScreen(existingEmi: emi),
                  ),
                ),
              ),
            ],
          ),

          Text(
            emi.provider,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          /// EMI / month + progress %
          Row(
            children: [
              Expanded(
                child: Text(
                  "EMI: ₹${emi.monthlyEmi.toStringAsFixed(0)} / month",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${(emi.progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: emi.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            color: emi.remainingMonths == 0
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 12),

          /// Remaining
          Row(
            children: [
              Expanded(
                child: Text(
                  emi.remainingMonths > 0
                      ? "Remaining: ₹${emi.remainingBalance.toStringAsFixed(0)}"
                      : "Fully Paid 🎉",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: emi.remainingMonths > 0 ? null : Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Months Left: ${emi.remainingMonths}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                emi.remainingMonths > 0
                    ? Icons.check_circle_outline
                    : Icons.done_all,
              ),
              label: Text(
                emi.remainingMonths > 0 ? "Mark EMI as Paid" : "Completed",
              ),
              onPressed: emi.remainingMonths > 0
                  ? () => vm.markEmiPaid(emi.id)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// ─── Pay Later / Credit Card Card ───
  Widget _buildPayLaterCard(
    BuildContext context,
    EmiTrackerEntity emi,
    EmiTrackerViewModel vm,
  ) {
    final isOverdue = emi.isOverdue;
    final isPaid = emi.isPaid;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = Colors.green;
      statusText = "Paid ✓";
      statusIcon = Icons.done_all;
    } else if (isOverdue) {
      statusColor = Theme.of(context).colorScheme.error;
      statusText = "Overdue!";
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Theme.of(context).colorScheme.primary;
      statusText = emi.dueDate != null
          ? "${emi.daysUntilDue} days left"
          : "No due date";
      statusIcon = Icons.schedule;
    }

    return IOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Edit
          Row(
            children: [
              Expanded(
                child: Text(
                  emi.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEmiScreen(existingEmi: emi),
                  ),
                ),
              ),
            ],
          ),

          Text(
            emi.provider,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          /// Amount
          Row(
            children: [
              Expanded(
                child: Text(
                  "Amount: ₹${emi.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (emi.dueDate != null) ...[
            const SizedBox(height: 8),
            Text(
              "Due: ${DateFormat("dd MMM yyyy").format(emi.dueDate!)}",
              style: TextStyle(
                color: isOverdue && !isPaid
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isOverdue && !isPaid ? FontWeight.bold : null,
              ),
            ),
          ],

          const Divider(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(isPaid ? Icons.done_all : Icons.payment),
              label: Text(isPaid ? "Paid" : "Mark as Paid"),
              onPressed: isPaid ? null : () => vm.markPayLaterPaid(emi.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No EMIs Tracked",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to add an EMI or Pay Later entry.",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
