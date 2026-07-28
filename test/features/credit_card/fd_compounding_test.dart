import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/fd_lot_entity.dart';

void main() {
  group('FD Compounding & 90% Credit Limit Tests', () {
    test('Daily compounding interest calculation at 6.0% p.a.', () {
      final depositDate = DateTime(2026, 1, 1);
      final targetDate = DateTime(2026, 1, 366); // 365 days

      final val = FdLotEntity.calculateCompoundedValueAt(
        principal: 10000.0,
        rate: 6.0,
        depositDate: depositDate,
        targetDate: targetDate,
      );

      // Formula: 10000 * (1 + 0.06/365)^365 ≈ 10618.31
      expect(val, closeTo(10618.31, 1.0));
    });

    test('New FD deposit increases credit limit by 90% of principal only', () {
      final fd1 = FdLotEntity(
        id: 'fd1',
        principal: 5000.0,
        currentValue: 5000.0,
        depositDate: DateTime.now(),
        maturityDate: DateTime.now().add(const Duration(days: 365)),
        lockUntil: DateTime.now().add(const Duration(days: 7)),
        status: FdStatus.locked,
      );

      final fd2 = FdLotEntity(
        id: 'fd2',
        principal: 10000.0,
        currentValue: 10000.0,
        depositDate: DateTime.now(),
        maturityDate: DateTime.now().add(const Duration(days: 365)),
        lockUntil: DateTime.now().add(const Duration(days: 7)),
        status: FdStatus.locked,
      );

      expect(fd1.creditLimitContribution, equals(4500.0)); // 90% of 5000
      expect(fd2.creditLimitContribution, equals(9000.0)); // 90% of 10000
    });
  });
}
