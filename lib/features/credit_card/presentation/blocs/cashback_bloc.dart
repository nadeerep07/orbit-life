import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cashback_transaction_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';

// Events
abstract class CashbackEvent extends Equatable {
  const CashbackEvent();
  @override
  List<Object?> get props => [];
}

class LoadCashbackEvent extends CashbackEvent {}

class RedeemCashbackEvent extends CashbackEvent {
  final double amount;
  final String destinationType;
  final String? targetAccountId;

  const RedeemCashbackEvent({
    required this.amount,
    required this.destinationType,
    this.targetAccountId,
  });

  @override
  List<Object?> get props => [amount, destinationType, targetAccountId];
}

// States
abstract class CashbackState extends Equatable {
  const CashbackState();
  @override
  List<Object?> get props => [];
}

class CashbackInitialState extends CashbackState {}

class CashbackLoadingState extends CashbackState {}

class CashbackLoadedState extends CashbackState {
  final List<CashbackTransactionEntity> transactions;
  const CashbackLoadedState(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class CashbackRedeemSuccessState extends CashbackState {
  final String message;
  const CashbackRedeemSuccessState(this.message);
  @override
  List<Object?> get props => [message];
}

class CashbackErrorState extends CashbackState {
  final String message;
  const CashbackErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CashbackBloc extends Bloc<CashbackEvent, CashbackState> {
  final CreditCardRepository repository;

  CashbackBloc({required this.repository}) : super(CashbackInitialState()) {
    on<LoadCashbackEvent>(_onLoadCashback);
    on<RedeemCashbackEvent>(_onRedeemCashback);
  }

  Future<void> _onLoadCashback(
    LoadCashbackEvent event,
    Emitter<CashbackState> emit,
  ) async {
    emit(CashbackLoadingState());
    try {
      final txs = await repository.getCashbackTransactions();
      emit(CashbackLoadedState(txs));
    } catch (e) {
      emit(CashbackErrorState(e.toString()));
    }
  }

  Future<void> _onRedeemCashback(
    RedeemCashbackEvent event,
    Emitter<CashbackState> emit,
  ) async {
    emit(CashbackLoadingState());
    try {
      await repository.redeemCashback(
        amount: event.amount,
        destinationType: event.destinationType,
        targetAccountId: event.targetAccountId,
      );
      emit(const CashbackRedeemSuccessState('Cashback redeemed successfully!'));
      final txs = await repository.getCashbackTransactions();
      emit(CashbackLoadedState(txs));
    } catch (e) {
      emit(CashbackErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
