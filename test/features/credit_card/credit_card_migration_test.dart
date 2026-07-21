import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/credit_card_account_entity.dart';
import 'package:my_budget_pro/features/credit_card/domain/entities/fd_lot_entity.dart';

void main() {
  group('Credit Card Migration & Preservation Tests', () {
    test('Seeded initial credit card state matches exact user parameters including cashback breakdown', () {
      final seeded = CreditCardAccountEntity.initialSeeded();

      expect(seeded.id, equals('supermoney'));
      expect(seeded.creditLimit, equals(21204.0));
      expect(seeded.availableCredit, equals(6790.0));
      expect(seeded.usedCredit, equals(14414.0));
      expect(seeded.initialCreditMigrated, isTrue);

      // Exact user cashback breakdown figures
      expect(seeded.lifetimeCashback, equals(1279.38));
      expect(seeded.cashbackRedeemed, equals(741.92));
      expect(seeded.cashbackPending, equals(371.38));
      expect(seeded.cashbackAvailable, equals(166.08));

      // Mathematical balance relation: Redeemed + Pending + Available == Lifetime
      expect(
        seeded.cashbackRedeemed + seeded.cashbackPending + seeded.cashbackAvailable,
        closeTo(seeded.lifetimeCashback, 0.01),
      );

      // Verify credit limit balance relation: Used + Available == Limit
      expect(seeded.usedCredit + seeded.availableCredit, equals(seeded.creditLimit));
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
