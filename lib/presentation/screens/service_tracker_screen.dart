import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service_entity.dart';
import '../theme/app_theme.dart';
import '../viewmodels/service_view_model.dart';
import 'services_history_screen.dart';

class ServiceTrackerScreen extends StatefulWidget {
  final ServiceEntity? existingService;
  const ServiceTrackerScreen({super.key, this.existingService});

  @override
  State<ServiceTrackerScreen> createState() => _ServiceTrackerScreenState();
}

class _ServiceTrackerScreenState extends State<ServiceTrackerScreen> {
  final _titleController = TextEditingController();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextMileageController = TextEditingController();

  DateTime _serviceDate = DateTime.now();
  DateTime? _nextServiceDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingService != null) {
      final s = widget.existingService!;
      _titleController.text = s.title;
      _mileageController.text = s.mileageAtService.toString();
      _costController.text = s.cost.toString();
      _notesController.text = s.notes;
      _serviceDate = s.date;
      _nextServiceDate = s.nextServiceDate;
      if (s.nextServiceMileage != null) {
        _nextMileageController.text = s.nextServiceMileage.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingService == null ? 'Add Service' : 'Edit Service',
        ),
        actions: [
          if (widget.existingService == null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServicesHistoryScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IOSCard(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Service Title',
                      hintText: 'e.g. 10,000 KM General Service',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mileageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current Odometer (KM)',
                      hintText: '10050',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Total Cost (₹)',
                      hintText: '4500',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Service Date'),
                    trailing: Text(
                      DateFormat('dd MMM yyyy').format(_serviceDate),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _serviceDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _serviceDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Service Notes (Parts changed, etc.)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reminders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IOSCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Next Service Due (Date)'),
                    trailing: Text(
                      _nextServiceDate == null
                          ? 'Select'
                          : DateFormat('dd MMM yyyy').format(_nextServiceDate!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _nextServiceDate ??
                            DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _nextServiceDate = date);
                      }
                    },
                  ),
                  if (_nextServiceDate != null)
                    TextButton(
                      onPressed: () => setState(() => _nextServiceDate = null),
                      child: const Text('Clear Reminder'),
                    ),
                  const Divider(),
                  TextField(
                    controller: _nextMileageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Next Service Due (Odometer KM)',
                      hintText: '15000',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveService,
                child: Text(
                  widget.existingService == null
                      ? 'Save Record'
                      : 'Update Record',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveService() {
    final title = _titleController.text.trim();
    final mileage = int.tryParse(_mileageController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;
    final nextMileage = int.tryParse(_nextMileageController.text);

    if (title.isEmpty || mileage <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter valid title and current mileage'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final service = ServiceEntity(
      id:
          widget.existingService?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: _serviceDate,
      mileageAtService: mileage,
      cost: cost,
      notes: _notesController.text.trim(),
      nextServiceDate: _nextServiceDate,
      nextServiceMileage: nextMileage,
    );

    final vm = context.read<ServiceViewModel>();
    if (widget.existingService == null) {
      vm.addService(service);
    } else {
      vm.updateService(service);
    }

    Navigator.pop(context);
  }
}
