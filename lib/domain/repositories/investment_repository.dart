import '../entities/investment_entity.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentEntity>> getInvestments();
  Future<void> addInvestment(InvestmentEntity investment);
  Future<void> updateInvestment(InvestmentEntity investment);
  Future<void> deleteInvestment(String id);
}
