import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/vendor_wallet.dart';


abstract class WalletDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletDataInitial extends WalletDataState {}

class WalletDataLoading extends WalletDataState {}

class WalletDataSuccess extends WalletDataState {
  final VendorWallet? vendorWallet;

  WalletDataSuccess({this.vendorWallet});
  @override
  List<Object?> get props => [vendorWallet];
}

class WalletDataFailed extends WalletDataState {
  final String error;
  WalletDataFailed(this.error);
  @override
  List<Object?> get props => [error];
}

class WalletDataCubit extends Cubit<WalletDataState> {
  final PaymentRepository repository;
  WalletDataCubit(this.repository) : super(WalletDataInitial());

  Future<void> getWallet() async {
    try {
      emit(WalletDataLoading());
      final response = await repository.getHostWallet();

      if (response["status"] == 200) {

        emit(WalletDataSuccess(vendorWallet: VendorWallet.fromJson(response)));
      } else {
        emit(WalletDataFailed(response["error"]));
      }
    } catch (e) {
      emit(WalletDataFailed(e.toString()));
    }
  }
  void clear(){
    emit(WalletDataInitial());
  }
}
