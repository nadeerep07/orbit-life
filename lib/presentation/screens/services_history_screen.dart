import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/service_view_model.dart';
import 'service_tracker_screen.dart';
import '../widgets/custom_snackbar.dart';

class ServicesHistoryScreen extends StatefulWidget {
  const ServicesHistoryScreen({super.key});

  @override
  State<ServicesHistoryScreen> createState() => _ServicesHistoryScreenState();
}

class _ServicesHistoryScreenState extends State<ServicesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceViewModel>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceVM = context.watch<ServiceViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Service History')),
      body: serviceVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : serviceVM.services.isEmpty
          ? const Center(child: Text('No service records found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: serviceVM.services.length,
              itemBuilder: (context, index) {
                final svc = serviceVM.services[index];

                return Dismissible(
                  key: Key(svc.id),
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
                    serviceVM.deleteService(svc.id);
                    AppSnackBar.show(
                      context,
                      message: 'Service record deleted',
                      isError: false,
                    );
                  },
                  child: IOSCard(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              svc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceTrackerScreen(
                                    existingService: svc,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Date: \${DateFormat("dd MMM yyyy").format(svc.date)}',
                          ),
                          Text('Odo: \${svc.mileageAtService} KM'),
                          if (svc.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              svc.notes,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (svc.nextServiceDate != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Next Due: \${DateFormat("dd MMM yyyy").format(svc.nextServiceDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        '₹\${svc.cost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
