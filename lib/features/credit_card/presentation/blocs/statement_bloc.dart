import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/credit_card_statement_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';

// Events
abstract class StatementEvent extends Equatable {
  const StatementEvent();
  @override
  List<Object?> get props => [];
}

class LoadStatementsEvent extends StatementEvent {}

class GenerateStatementEvent extends StatementEvent {
  final int month;
  final int year;
  const GenerateStatementEvent(this.month, this.year);
  @override
  List<Object?> get props => [month, year];
}

class MakeCardPaymentEvent extends StatementEvent {
  final String sourceAccountId;
  final double amount;
  final DateTime date;
  final String reference;

  const MakeCardPaymentEvent({
    required this.sourceAccountId,
    required this.amount,
    required this.date,
    required this.reference,
  });

  @override
  List<Object?> get props => [sourceAccountId, amount, date, reference];
}

// States
abstract class StatementState extends Equatable {
  const StatementState();
  @override
  List<Object?> get props => [];
}

class StatementInitialState extends StatementState {}

class StatementLoadingState extends StatementState {}

class StatementLoadedState extends StatementState {
  final List<CreditCardStatementEntity> statements;
  const StatementLoadedState(this.statements);
  @override
  List<Object?> get props => [statements];
}

class PaymentSuccessState extends StatementState {
  final String message;
  const PaymentSuccessState(this.message);
  @override
  List<Object?> get props => [message];
}

class StatementErrorState extends StatementState {
  final String message;
  const StatementErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class StatementBloc extends Bloc<StatementEvent, StatementState> {
  final CreditCardRepository repository;

  StatementBloc({required this.repository}) : super(StatementInitialState()) {
    on<LoadStatementsEvent>(_onLoadStatements);
    on<GenerateStatementEvent>(_onGenerateStatement);
    on<MakeCardPaymentEvent>(_onMakePayment);
  }

  Future<void> _onLoadStatements(
    LoadStatementsEvent event,
    Emitter<StatementState> emit,
  ) async {
    emit(StatementLoadingState());
    try {
      final statements = await repository.getStatements();
      emit(StatementLoadedState(statements));
    } catch (e) {
      emit(StatementErrorState(e.toString()));
    }
  }

  Future<void> _onGenerateStatement(
    GenerateStatementEvent event,
    Emitter<StatementState> emit,
  ) async {
    emit(StatementLoadingState());
    try {
      await repository.generateMonthlyStatement(event.month, event.year);
      final statements = await repository.getStatements();
      emit(StatementLoadedState(statements));
    } catch (e) {
      emit(StatementErrorState(e.toString()));
    }
  }

  Future<void> _onMakePayment(
    MakeCardPaymentEvent event,
    Emitter<StatementState> emit,
  ) async {
    emit(StatementLoadingState());
    try {
      await repository.makeCardPayment(
        sourceAccountId: event.sourceAccountId,
        amount: event.amount,
        date: event.date,
        reference: event.reference,
      );
      emit(const PaymentSuccessState('Payment recorded successfully!'));
      final statements = await repository.getStatements();
      emit(StatementLoadedState(statements));
    } catch (e) {
      emit(StatementErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
