import '../../domain/entities/investment_entity.dart';
import '../../domain/repositories/investment_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/investment_model.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  final LocalDataSource localDataSource;

  InvestmentRepositoryImpl(this.localDataSource);

  @override
  Future<List<InvestmentEntity>> getInvestments() async {
    final models = await localDataSource.getInvestments();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addInvestment(InvestmentEntity investment) async {
    final model = InvestmentModel.fromEntity(investment);
    await localDataSource.addInvestment(model);
  }

  @override
  Future<void> updateInvestment(InvestmentEntity investment) async {
    final model = InvestmentModel.fromEntity(investment);
    await localDataSource.updateInvestment(model);
  }

  @override
  Future<void> deleteInvestment(String id) async {
    await localDataSource.deleteInvestment(id);
  }
}
