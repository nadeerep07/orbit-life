import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/fd_lot_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';

// Events
abstract class FdLotsEvent extends Equatable {
  const FdLotsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFdLotsEvent extends FdLotsEvent {}

class DepositFdEvent extends FdLotsEvent {
  final double amount;
  final DateTime depositDate;
  final String remarks;
  final String? sourceAccountId;

  const DepositFdEvent({
    required this.amount,
    required this.depositDate,
    required this.remarks,
    this.sourceAccountId,
  });

  @override
  List<Object?> get props => [amount, depositDate, remarks, sourceAccountId];
}

class WithdrawFdEvent extends FdLotsEvent {
  final String fdId;
  const WithdrawFdEvent(this.fdId);
  @override
  List<Object?> get props => [fdId];
}

// States
abstract class FdLotsState extends Equatable {
  const FdLotsState();
  @override
  List<Object?> get props => [];
}

class FdLotsInitialState extends FdLotsState {}

class FdLotsLoadingState extends FdLotsState {}

class FdLotsLoadedState extends FdLotsState {
  final List<FdLotEntity> lots;
  const FdLotsLoadedState(this.lots);
  @override
  List<Object?> get props => [lots];
}

class FdDepositSuccessState extends FdLotsState {
  final FdLotEntity newLot;
  const FdDepositSuccessState(this.newLot);
  @override
  List<Object?> get props => [newLot];
}

class FdWithdrawSuccessState extends FdLotsState {
  final String message;
  const FdWithdrawSuccessState(this.message);
  @override
  List<Object?> get props => [message];
}

class FdLotsErrorState extends FdLotsState {
  final String message;
  const FdLotsErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FdLotsBloc extends Bloc<FdLotsEvent, FdLotsState> {
  final CreditCardRepository repository;

  FdLotsBloc({required this.repository}) : super(FdLotsInitialState()) {
    on<LoadFdLotsEvent>(_onLoadFdLots);
    on<DepositFdEvent>(_onDepositFd);
    on<WithdrawFdEvent>(_onWithdrawFd);
  }

  Future<void> _onLoadFdLots(
    LoadFdLotsEvent event,
    Emitter<FdLotsState> emit,
  ) async {
    emit(FdLotsLoadingState());
    try {
      final lots = await repository.getFdLots();
      emit(FdLotsLoadedState(lots));
    } catch (e) {
      emit(FdLotsErrorState(e.toString()));
    }
  }

  Future<void> _onDepositFd(
    DepositFdEvent event,
    Emitter<FdLotsState> emit,
  ) async {
    emit(FdLotsLoadingState());
    try {
      final newLot = await repository.depositFd(
        amount: event.amount,
        depositDate: event.depositDate,
        remarks: event.remarks,
        sourceAccountId: event.sourceAccountId,
      );
      emit(FdDepositSuccessState(newLot));
      final lots = await repository.getFdLots();
      emit(FdLotsLoadedState(lots));
    } catch (e) {
      emit(FdLotsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onWithdrawFd(
    WithdrawFdEvent event,
    Emitter<FdLotsState> emit,
  ) async {
    emit(FdLotsLoadingState());
    try {
      await repository.withdrawFd(event.fdId);
      emit(const FdWithdrawSuccessState('FD withdrawn successfully!'));
      final lots = await repository.getFdLots();
      emit(FdLotsLoadedState(lots));
    } catch (e) {
      emit(FdLotsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
