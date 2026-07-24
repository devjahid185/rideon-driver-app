import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/get_wallet.dart';
import '../../../domain/entities/payout_transaction.dart';

abstract class WalletTransactionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletTransactionsInitial extends WalletTransactionsState {}

class WalletTransactionsLoading extends WalletTransactionsState {}

class WalletTransactionsSuccess extends WalletTransactionsState {
  final GetVendorWalletTransactions? transactions;

  WalletTransactionsSuccess(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class WalletTransactionsFailed extends WalletTransactionsState {
  final String error;

  WalletTransactionsFailed(this.error);
  @override
  List<Object?> get props => [error];
}

class WalletTransactionsCubit extends Cubit<WalletTransactionsState> {
  final PaymentRepository repository;
  WalletTransactionsCubit(this.repository) : super(WalletTransactionsInitial());

  Future<void> getTransactions({String? offset}) async {
    try {
      emit(WalletTransactionsLoading());
      final response = await repository.getWalletTransactions(offset: "$offset");

      if (response["status"] == 200) {
        emit(WalletTransactionsSuccess(GetVendorWalletTransactions.fromJson(response)));
      } else {
        emit(WalletTransactionsFailed(response["error"]));
      }
    } catch (e) {
      emit(WalletTransactionsFailed(e.toString()));
    }
  }

  void clear(){
    emit(WalletTransactionsInitial());
  }
}



///payout



abstract class PayoutTransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PayoutTransactionInitial extends PayoutTransactionState {}

class PayoutTransactionLoading extends PayoutTransactionState {}

class PayoutTransactionSuccess extends PayoutTransactionState {
  final PayoutTransaction? payoutTransaction;
  PayoutTransactionSuccess(this.payoutTransaction);
  @override
  List<Object?> get props => [payoutTransaction];
}

class PayoutTransactionFailed extends PayoutTransactionState {
  final String error;
  PayoutTransactionFailed(this.error);
  @override
  List<Object?> get props => [error];
}

class PayoutTransactionCubit extends Cubit<PayoutTransactionState> {
  final PaymentRepository repository;
  PayoutTransactionCubit(this.repository) : super(PayoutTransactionInitial());

  Future<void> getPayoutTransaction({String? offset}) async {
    try {
      emit(PayoutTransactionLoading());
      final response = await repository.getPayoutTransaction(offset: "$offset");

      if (response["status"] == 200) {
        emit(PayoutTransactionSuccess(PayoutTransaction.fromJson(response)));
      } else {
        emit(PayoutTransactionFailed(response["error"]));
      }
    } catch (e) {
      emit(PayoutTransactionFailed(e.toString()));
    }
  }
  Future<void> getPayoutTotal() async {
    try {
      emit(PayoutTransactionLoading());
      final response = await repository.getPayoutTotal();


      if (response["status"] == 200) {
        emit(PayoutTransactionSuccess(PayoutTransaction.fromJson(response)));
      } else {
        emit(PayoutTransactionFailed(response["error"]));
      }
    } catch (e) {
      emit(PayoutTransactionFailed(e.toString()));
    }
  }
  void clear(){
    emit(PayoutTransactionInitial());
  }
}



abstract class AmountPayoutState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AmountPayoutInitial extends AmountPayoutState {}

class AmountPayoutLoading extends AmountPayoutState {}

class AmountPayoutSuccess extends AmountPayoutState {}

class AmountPayoutFailed extends AmountPayoutState {
  final String error;
  AmountPayoutFailed(this.error);
  @override
  List<Object?> get props => [error];
}

class AmountPayoutCubit extends Cubit<AmountPayoutState> {
  final PaymentRepository repository;
  AmountPayoutCubit(this.repository) : super(AmountPayoutInitial());

  Future<void> getAmount({String? amount,String? methodId}) async {
    try {
      emit(AmountPayoutLoading());
      final response = await repository.getAmountWallet(amount: "$amount",methodId: methodId);

      if (response["status"] == 200) {
        emit(AmountPayoutSuccess());
      } else {
        emit(AmountPayoutFailed(response["error"]));
      }
    } catch (e) {
      emit(AmountPayoutFailed(e.toString()));
    }
  }
}
