import 'package:ride_on_driver/data/repositories/payment_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PaymentMethod { cash, online }

class PaymentCubit extends Cubit<PaymentMethod?> {
  PaymentCubit() : super(PaymentMethod.cash);

  void selectMethod(PaymentMethod method) => emit(method);
}

abstract class UpdatePaymentStatusByDriverState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdatePaymentInitial extends UpdatePaymentStatusByDriverState {}

class UpdatePaymentLoading extends UpdatePaymentStatusByDriverState {}

class UpdatePaymentReset extends UpdatePaymentStatusByDriverState {}

class UpdatePaymentSuceess extends UpdatePaymentStatusByDriverState {
  @override
  List<Object?> get props => [];
}

class UpdatePaymentFailure extends UpdatePaymentStatusByDriverState {
  final String? paymentMessage;
  UpdatePaymentFailure({this.paymentMessage});
  @override
  List<Object?> get props => [];
}

class UpdatePaymentStatusByDriverCubit
    extends Cubit<UpdatePaymentStatusByDriverState> {
  PaymentRepository paymentRepository;
  UpdatePaymentStatusByDriverCubit(this.paymentRepository)
      : super(UpdatePaymentInitial());

  Future<void> updatePaymentStatusByDriver(
      {required BuildContext context,
      required String bookingId,
      required String paymentMethod}) async {
    try {
      emit(UpdatePaymentLoading());

      var response = await paymentRepository.updatePaymentStatusByDriver(
          context: context, bookingId: bookingId, paymentMethod: paymentMethod);
      if (response["status"] == 200) {
        emit(UpdatePaymentSuceess());
      } else {
        emit(UpdatePaymentFailure(paymentMessage: response["error"]));
      }
    } catch (err) {
      emit(UpdatePaymentFailure(paymentMessage: "$err"));
    }
  }

  void resetState() {
    emit(UpdatePaymentReset());

    emit(UpdatePaymentInitial());
  }
}
