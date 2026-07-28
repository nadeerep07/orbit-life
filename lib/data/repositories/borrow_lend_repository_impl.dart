import '../../domain/entities/borrow_lend_entity.dart';
import '../../domain/repositories/borrow_lend_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/borrow_lend_model.dart';

class BorrowLendRepositoryImpl implements BorrowLendRepository {
  final LocalDataSource localDataSource;

  BorrowLendRepositoryImpl(this.localDataSource);

  @override
  Future<List<BorrowLendEntity>> getBorrowLends() async {
    final models = await localDataSource.getBorrowLends();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addBorrowLend(BorrowLendEntity borrowLend) async {
    final model = BorrowLendModel.fromEntity(borrowLend);
    await localDataSource.addBorrowLend(model);
  }

  @override
  Future<void> updateBorrowLend(BorrowLendEntity borrowLend) async {
    final model = BorrowLendModel.fromEntity(borrowLend);
    await localDataSource.updateBorrowLend(model);
  }

  @override
  Future<void> deleteBorrowLend(String id) async {
    await localDataSource.deleteBorrowLend(id);
  }
}
