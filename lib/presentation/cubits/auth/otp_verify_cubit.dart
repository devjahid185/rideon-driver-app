import 'dart:convert';
import 'package:ride_on_driver/data/repositories/auth_repository.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../domain/entities/login.dart';

abstract class OtpVerifyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OtpInitial extends OtpVerifyState {}

class OtpLoading extends OtpVerifyState {}

class OtpSuccess extends OtpVerifyState {
  final LoginModel loginModel;
  final String? successMessage;
  OtpSuccess(this.loginModel, {this.successMessage});
  @override
  List<Object?> get props => [loginModel, successMessage];
}

class OtpSuccessForChangePhoneSate extends OtpVerifyState {
  final LoginModel loginModel;

  OtpSuccessForChangePhoneSate(this.loginModel);
  @override
  List<Object?> get props => [loginModel];
}

class OtpFailure extends OtpVerifyState {
  final String error;
  OtpFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class AuthOtpVerifyCubit extends Cubit<OtpVerifyState> {
  final AuthRepository authRepository;

  AuthOtpVerifyCubit(this.authRepository) : super(OtpInitial());

  Future<void> otpVerification(
      {required BuildContext context,
      String? phone,
      String? otpValue,
      String? countryCode,
      String? email,
      String? resetToken,
      String? defaultCountry,
      bool? changeEmail,
      bool? changeMobile,
      bool? loginWithGoogle}) async {
    try {
      emit(OtpLoading());

      final response = await authRepository.otpVerify(
          context: context,
          phone: phone,
          otpValue: otpValue,
          countryCode: countryCode,
          email: email,
          resetToken: otpValue,
          changeEmail: changeEmail,
          changeMobile: changeMobile,
          defaultCountry: defaultCountry);

      if (response["status"] == 200) {
        box.put('Remember', true);
        box.put('Firstuser', true);
        loginModel = LoginModel.fromJson(response);
        if (loginModel != null && loginModel!.data != null) {
          if (loginModel!.data!.itemId != null) {}
          if (loginModel!.data!.gender != null) {
            box.put('gender', true);
          } else {
            box.put('gender', false);
          }
        }
        UserData userObj = UserData();
        userObj.saveLoginData("UserData", jsonEncode(response));

        emit(
          OtpSuccess(LoginModel.fromJson(response),
              successMessage: response["message"]),
        );
      } else {
        emit(OtpFailure(response['error']));
      }
    } catch (e) {
      emit(OtpFailure("Something went wrong $e"));
    }
  }

  Future<void> otpVerificationForChangePhone(
      Map<String, dynamic> data, BuildContext context) async {
    try {
      emit(OtpLoading());
      final response = await authRepository.forChangePhoneNumberOtpVerification(
          data: data, context: context);

      LoginModel loginModel = LoginModel.fromJson(response);
      if (loginModel.status == 200) {
        UserData userObj = UserData();
        userObj.saveLoginData("UserData", jsonEncode(response));
        emit(OtpSuccessForChangePhoneSate(loginModel));
      } else {
        emit(OtpFailure(response["error"].toString()));
      }
    } catch (e) {
      emit(OtpFailure("something went wrong"));
    }
  }

  void resetState() {
    emit(OtpInitial());
  }
}
