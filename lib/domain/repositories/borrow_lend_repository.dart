import '../entities/borrow_lend_entity.dart';

abstract class BorrowLendRepository {
  Future<List<BorrowLendEntity>> getBorrowLends();
  Future<void> addBorrowLend(BorrowLendEntity borrowLend);
  Future<void> updateBorrowLend(BorrowLendEntity borrowLend);
  Future<void> deleteBorrowLend(String id);
}
