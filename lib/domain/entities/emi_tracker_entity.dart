import 'package:equatable/equatable.dart';

class EmiTrackerEntity extends Equatable {
  final String id;
  final String title;
  final String provider;
  final double totalAmount;
  final String notes;
  final DateTime startDate;
  final String accountId;

  /// true = Pay Later / Credit Card (one-time payment by dueDate)
  /// false = EMI (monthly installments)
  final bool isPayLater;

  // --- EMI-only fields ---
  final double monthlyEmi;
  final int totalMonths;
  final int paidMonths;

  // --- Pay Later fields ---
  final DateTime? dueDate;
  final bool isPaid;
  final bool isReminderEnabled;

  const EmiTrackerEntity({
    required this.id,
    required this.title,
    required this.provider,
    required this.totalAmount,
    required this.startDate,
    this.notes = '',
    this.isPayLater = false,
    // EMI
    this.monthlyEmi = 0,
    this.totalMonths = 0,
    this.paidMonths = 0,
    // Pay Later
    this.dueDate,
    this.isPaid = false,
    this.isReminderEnabled = false,
    this.accountId = 'cash',
  });

  // --- Computed (EMI mode) ---
  double get totalPaid => monthlyEmi * paidMonths;
  double get remainingBalance => totalAmount - totalPaid;
  int get remainingMonths => totalMonths - paidMonths;
  double get progress =>
      totalMonths > 0 ? (paidMonths / totalMonths).clamp(0.0, 1.0) : 0.0;

  // --- Computed (Pay Later mode) ---
  bool get isOverdue =>
      isPayLater &&
      !isPaid &&
      dueDate != null &&
      DateTime.now().isAfter(dueDate!);
  int get daysUntilDue =>
      dueDate != null ? dueDate!.difference(DateTime.now()).inDays : 0;

  @override
  List<Object?> get props => [
    id,
    title,
    provider,
    totalAmount,
    monthlyEmi,
    totalMonths,
    paidMonths,
    startDate,
    notes,
    isPayLater,
    dueDate,
    isPaid,
    isReminderEnabled,
    accountId,
  ];
}
