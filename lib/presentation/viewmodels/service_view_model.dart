import 'package:flutter/foundation.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../core/services/notification_service.dart';

class ServiceViewModel extends ChangeNotifier {
  final ServiceRepository _repository;
  final TransactionRepository _transactionRepository;
  final NotificationService _notificationService = NotificationService();

  List<ServiceEntity> _services = [];
  bool _isLoading = false;

  ServiceViewModel(this._repository, this._transactionRepository);

  List<ServiceEntity> get services => _services;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();

    _services = await _repository.getServices();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addService(ServiceEntity service, String accountId) async {
    await _repository.addService(service);
    _services.insert(0, service);

    if (service.cost > 0) {
      final tx = TransactionEntity(
        id: 'service_exp_${service.id}',
        amount: service.cost,
        type: TransactionType.service,
        accountId: accountId,
        categoryOrSource: 'Service - ${service.title}',
        date: service.date,
        description: service.notes,
        referenceId: service.id,
      );
      await _transactionRepository.addTransaction(tx);
    }

    if (service.nextServiceDate != null) {
      _notificationService.scheduleNotification(
        id: service.id.hashCode,
        title: 'Vehicle Service Reminder',
        body: 'Your upcoming service "${service.title}" is due soon.',
        scheduledDate: service.nextServiceDate!.subtract(
          const Duration(days: 3),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> updateService(ServiceEntity service, String accountId) async {
    await _repository.updateService(service);
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _services[index] = service;

      if (service.cost > 0) {
        final tx = TransactionEntity(
          id: 'service_exp_${service.id}',
          amount: service.cost,
          type: TransactionType.service,
          accountId: accountId,
          categoryOrSource: 'Service - ${service.title}',
          date: service.date,
          description: service.notes,
          referenceId: service.id,
        );
        await _transactionRepository.updateTransaction(tx);
      } else {
        await _transactionRepository.deleteTransactionsByReference(service.id);
      }

      // Update notification
      _notificationService.cancelNotification(service.id.hashCode);
      if (service.nextServiceDate != null) {
        _notificationService.scheduleNotification(
          id: service.id.hashCode,
          title: 'Vehicle Service Reminder',
          body: 'Your upcoming service "${service.title}" is due soon.',
          scheduledDate: service.nextServiceDate!.subtract(
            const Duration(days: 3),
          ),
        );
      }

      notifyListeners();
    }
  }

  Future<void> deleteService(String id) async {
    await _repository.deleteService(id);
    _services.removeWhere((s) => s.id == id);
    _notificationService.cancelNotification(id.hashCode);

    // Delete transaction from ledger to refund cost automatically
    await _transactionRepository.deleteTransactionsByReference(id);

    notifyListeners();
  }
}
