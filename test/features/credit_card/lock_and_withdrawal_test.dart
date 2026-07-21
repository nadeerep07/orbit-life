import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/fd_lot_entity.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/credit_card_account_entity.dart';

void main() {
  group('7-Day Lock & FD Withdrawal Validation Tests', () {
    test('Newly created FD is locked for 7 days', () {
      final now = DateTime.now();
      final lockedFd = FdLotEntity(
        id: 'fd_locked',
        principal: 5000.0,
        currentValue: 5000.0,
        depositDate: now,
        maturityDate: now.add(const Duration(days: 365)),
        lockUntil: now.add(const Duration(days: 7)),
        status: FdStatus.locked,
      );

      expect(lockedFd.isLocked, isTrue);
      expect(lockedFd.daysUntilUnlock, greaterThanOrEqualTo(6));
    });

    test('FD after 7 days is unlocked', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final unlockedFd = FdLotEntity(
        id: 'fd_unlocked',
        principal: 5000.0,
        currentValue: 5000.0,
        depositDate: pastDate,
        maturityDate: pastDate.add(const Duration(days: 365)),
        lockUntil: pastDate.add(const Duration(days: 7)),
        status: FdStatus.active,
      );

      expect(unlockedFd.isLocked, isFalse);
      expect(unlockedFd.daysUntilUnlock, equals(0));
    });

    test('Withdrawal validation blocks when Used Credit > resulting limit', () {
      final account = CreditCardAccountEntity(
        id: 'supermoney',
        creditLimit: 21204.0,
        availableCredit: 6790.0,
        usedCredit: 14414.0, // High used credit
        lastUpdated: DateTime.now(),
      );

      final fdToWithdraw = FdLotEntity(
        id: 'fd_to_withdraw',
        principal: 10000.0,
        currentValue: 10200.0,
        depositDate: DateTime.now().subtract(const Duration(days: 20)),
        maturityDate: DateTime.now().add(const Duration(days: 345)),
        lockUntil: DateTime.now().subtract(const Duration(days: 13)),
        status: FdStatus.active,
      );

      final creditReduction = fdToWithdraw.creditLimitContribution; // 9000
      final resultingLimit = account.creditLimit - creditReduction; // 12204

      // 14414 used credit > 12204 resulting limit => SHOULD BE BLOCKED
      final isBlocked = account.usedCredit > resultingLimit;
      expect(isBlocked, isTrue);
    });
  });
}
