// ignore_for_file: use_build_context_synchronously

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/data/repositories/payment_repository.dart';

import '../../../core/utils/common_widget.dart';
import '../../../domain/entities/get_payment_type.dart';
import '../../../domain/entities/payment_method.dart';


abstract class PaymentMethodState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentMethodInitial extends PaymentMethodState {}

class PaymentMethodLoading extends PaymentMethodState {}

class PayoutTypeLoading extends PaymentMethodState {}

class AddPaymentMethodLoading extends PaymentMethodState {}

class UpdatedPaymentMethodLoading extends PaymentMethodState {}

class PaymentMethodSuccess extends PaymentMethodState {
  final GetPaymentTypeModel model;

  PaymentMethodSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

class UpdatePaymentMethodSuccess extends PaymentMethodState {
  final GetPaymentTypeModel model;

  UpdatePaymentMethodSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

class PayoutTypeSuccess extends PaymentMethodState {
  final PaymentMethodModel model;

  PayoutTypeSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

class AddPaymentMethodSuccess extends PaymentMethodState {
  AddPaymentMethodSuccess();

  @override
  List<Object?> get props => [];
}

class PaymentMethodFailure extends PaymentMethodState {
  final String error;

  PaymentMethodFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class PaymentMethodCubits extends Cubit<PaymentMethodState> {
  final PaymentRepository repository;
  PaymentMethodCubits(this.repository) : super(PaymentMethodInitial());
  Future<void> addPaymentMethod(BuildContext context,
      {required Map<String, dynamic> map}) async {
    try {
      emit(AddPaymentMethodLoading());

      final response = await repository.addPaymentMethod(postData: map,context: context);

      if (response['status'] == 200) {
        if (response["data"] is Map<String, dynamic> &&
            (response["data"]["payout_methods"] == null ||
                response["data"]["payout_methods"] is List)) {
          emit(AddPaymentMethodSuccess());
          showToastMessage("Payment method updated successfully");
        }
      } else {
        emit(PaymentMethodFailure(response['error']));
      }
    } catch (e) {
      emit(PaymentMethodFailure("Something went wrong"));
    }
  }

  Future<void> updateStatusPaymentMethod(BuildContext context,
      {required Map<String, dynamic> map}) async {
    try {
      emit(UpdatedPaymentMethodLoading());

      final response = await repository.addPaymentMethod(postData: map,context: context);

      if (response['status'] == 200) {
        if (response["data"] is Map<String, dynamic> &&
            (response["data"]["payout_methods"] == null ||
                response["data"]["payout_methods"] is List)) {
          emit(UpdatePaymentMethodSuccess(
              GetPaymentTypeModel.fromJson(response)));

        }
      } else {
        emit(PaymentMethodFailure(response['error']));
      }
    } catch (e) {
      emit(PaymentMethodFailure("Something went wrong"));
    }
  }

  Future<void> getPaymentMethod(BuildContext context) async {
    try {
      emit(PaymentMethodLoading());
      final response = await repository.fetchPaymentMethod( context: context);
      if (response['status'] == 200) {
        emit(PaymentMethodSuccess(GetPaymentTypeModel.fromJson(response)));
      } else {
        emit(PaymentMethodFailure(response['error']));
      }
    } catch (e) {

      emit(PaymentMethodFailure("Something went wrong"));
    }
  }

  Future<void> getPayoutType(BuildContext context) async {
    try {


      emit(PayoutTypeLoading());
      final response = await repository.fetchPaymentType(context: context);
      if (response['status'] == 200) {
        getPaymentMethod(context);
        emit(PayoutTypeSuccess(PaymentMethodModel.fromJson(response)));
      } else {
        emit(PaymentMethodFailure(response['error']));
      }
    } catch (e) {

      emit(PaymentMethodFailure("Something went wrong"));
    }
  }

  void clear() {
    emit(PaymentMethodInitial());
  }
}
