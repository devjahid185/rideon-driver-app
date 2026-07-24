import 'package:ride_on_driver/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ResendOtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ResendOtpInitial extends ResendOtpState {}

class ResendOtpLoading extends ResendOtpState {}

class ResendOtpSuccess extends ResendOtpState {
  final String? otpValue;
  ResendOtpSuccess(this.otpValue);
  @override
  List<Object?> get props => [otpValue];
}

class ResendOtpFailure extends ResendOtpState {
  final String error;
  ResendOtpFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class AuthResendOtpCubit extends Cubit<ResendOtpState> {
  final AuthRepository authRepository;
  AuthResendOtpCubit(this.authRepository) : super(ResendOtpInitial());
  // ignore: prefer_typing_uninitialized_variables
  var response;

  Future<void> resendOtp({
    String? phone,
    String? phoneCountry,
    required BuildContext context,

  }) async {
    try {
      emit(ResendOtpLoading());
      response = await authRepository.resendOtp(
        context: context,
        phone: phone,
        phoneCountry: phoneCountry,

      );

      if (response["status"] == 200) {

        emit(ResendOtpSuccess(response['data']['otp_value']));

      } else {
        emit(ResendOtpFailure(response['error']));
      }
    } catch (error) {
      emit(ResendOtpFailure(error.toString()));

    }
  }

  void resetState() {
    emit(ResendOtpInitial());
  }
}
