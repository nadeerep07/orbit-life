import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/credit_card_account_entity.dart';
import '../../domain/repositories/credit_card_repository.dart';

// Events
abstract class CreditCardEvent extends Equatable {
  const CreditCardEvent();
  @override
  List<Object?> get props => [];
}

class LoadCreditCardAccountEvent extends CreditCardEvent {}

class UpdateCreditCardAccountEvent extends CreditCardEvent {
  final CreditCardAccountEntity account;
  const UpdateCreditCardAccountEvent(this.account);
  @override
  List<Object?> get props => [account];
}

// States
abstract class CreditCardState extends Equatable {
  const CreditCardState();
  @override
  List<Object?> get props => [];
}

class CreditCardInitialState extends CreditCardState {}

class CreditCardLoadingState extends CreditCardState {}

class CreditCardLoadedState extends CreditCardState {
  final CreditCardAccountEntity account;
  const CreditCardLoadedState(this.account);
  @override
  List<Object?> get props => [account];
}

class CreditCardErrorState extends CreditCardState {
  final String message;
  const CreditCardErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CreditCardBloc extends Bloc<CreditCardEvent, CreditCardState> {
  final CreditCardRepository repository;
  StreamSubscription? _subscription;

  CreditCardBloc({required this.repository}) : super(CreditCardInitialState()) {
    on<LoadCreditCardAccountEvent>(_onLoadAccount);
    on<UpdateCreditCardAccountEvent>(_onUpdateAccount);

    _subscription = repository.watchCreditCardAccount().listen((_) {
      add(LoadCreditCardAccountEvent());
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadAccount(
    LoadCreditCardAccountEvent event,
    Emitter<CreditCardState> emit,
  ) async {
    emit(CreditCardLoadingState());
    try {
      final account = await repository.getCreditCardAccount();
      emit(CreditCardLoadedState(account));
    } catch (e) {
      emit(CreditCardErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateCreditCardAccountEvent event,
    Emitter<CreditCardState> emit,
  ) async {
    try {
      await repository.saveCreditCardAccount(event.account);
      emit(CreditCardLoadedState(event.account));
    } catch (e) {
      emit(CreditCardErrorState(e.toString()));
    }
  }
}
