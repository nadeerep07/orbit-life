import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/credit_card_account_entity.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/fd_lot_entity.dart';

void main() {
  group('Credit Card Migration & Preservation Tests', () {
    test('Initial credit card state is zeroed', () {
      final zero = CreditCardAccountEntity.zero();

      expect(zero.id, equals('supermoney'));
      expect(zero.creditLimit, equals(0.0));
      expect(zero.availableCredit, equals(0.0));
      expect(zero.usedCredit, equals(0.0));
      expect(zero.initialCreditMigrated, isTrue);

      expect(zero.lifetimeCashback, equals(0.0));
      expect(zero.cashbackRedeemed, equals(0.0));
      expect(zero.cashbackPending, equals(0.0));
      expect(zero.cashbackAvailable, equals(0.0));

      expect(
        zero.cashbackRedeemed + zero.cashbackPending + zero.cashbackAvailable,
        equals(zero.lifetimeCashback),
      );

      expect(zero.usedCredit + zero.availableCredit, equals(zero.creditLimit));
    });

    test('Initial seeded FD lot matches ₹23,560 principal and ₹24,016.39 value', () {
      final initialFd = FdLotEntity(
        id: 'fd_initial_seeded',
        principal: 23560.0,
        currentValue: 24016.39,
        depositDate: DateTime.now().subtract(const Duration(days: 120)),
        maturityDate: DateTime.now().add(const Duration(days: 245)),
        lockUntil: DateTime.now().subtract(const Duration(days: 113)),
        status: FdStatus.active,
        autoRenew: true,
      );

      expect(initialFd.principal, equals(23560.0));
      expect(initialFd.currentValue, equals(24016.39));
      expect(initialFd.interestEarned, closeTo(456.39, 0.01));
      expect(initialFd.creditLimitContribution, equals(21204.0)); // 90% of 23560
      expect(initialFd.isLocked, isFalse); // Unlocked initial seed
    });
  });
}
