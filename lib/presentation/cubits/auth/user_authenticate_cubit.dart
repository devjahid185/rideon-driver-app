import 'dart:convert';

import 'package:ride_on_driver/data/repositories/auth_repository.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/extensions/helper/push_notifications.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../domain/entities/login.dart';
import '../logout_cubit.dart';
import '../register_vehicle/vehicle_register_cubit.dart';

abstract class AuthUserAuthenticateState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserInitial extends AuthUserAuthenticateState {}

class UserLoading extends AuthUserAuthenticateState {}

class UserSucesss extends AuthUserAuthenticateState {
  final LoginModel loginModel;
  UserSucesss(this.loginModel);
  @override
  List<Object?> get props => [loginModel];
}

class UserFailure extends AuthUserAuthenticateState {
  final String error;
  UserFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class AuthUserAuthenticateCubit extends Cubit<AuthUserAuthenticateState> {
  AuthRepository authRepository;
  AuthUserAuthenticateCubit(this.authRepository) : super(UserInitial());

  Future<void> userAuthenticate(
      {required BuildContext context,
      required String phoneNumber,
      required String phoneCountry,
      required String otpValue}) async {
    // try {
      emit(UserLoading());

      clearData(context);

      var response = await authRepository.userAuthenticateLogin(
          context: context,
          phoneNumber: phoneNumber,
          phoneCountry: phoneCountry,
          otpValue: otpValue);

      if (response["status"] == 200) {
        box.put('Remember', true);
        box.put('Firstuser', true);
        UserData userObj = UserData();
        loginModel = LoginModel.fromJson(response);
        userObj.saveLoginData("UserData", jsonEncode(response));
        if (loginModel != null && loginModel!.data != null) {
          token = loginModel!.data!.token ?? '';
          await syncPendingFcmTokenIfAny(forceSync: true);

          if (loginModel!.data!.itemTypeId != null) {
            box.put("itemTypeId", true);
            // ignore: use_build_context_synchronously
            context.read<GetItemIdCubit>().updateItemId(
                itemTypeId: loginModel!.data!.itemTypeId!.toString());
          } else {
            box.put("itemTypeId", false);
          }

          if (loginModel!.data!.remainingItems == 0) {
            box.put('remainingItems', true);
          } else {
            box.put('remainingItems', false);
          }
          if (loginModel?.data?.gender != null &&
              loginModel!.data!.gender!.isNotEmpty) {
            box.put("gender", true);
          } else {
            box.put("gender", false);
          }
        }

        emit(UserSucesss(LoginModel.fromJson(response)));
      } else {
        emit(UserFailure(response["error"]));
      }
    // } catch (e) {
    //   emit(UserFailure("Something went wrong $e "));
    // }
  }

  void resetState() {
    emit(UserInitial());
  }
}

class SetCountryState extends Equatable {
  final String dialCode; // e.g., +1
  final String countryCode; // e.g., US

  const SetCountryState({
    required this.dialCode,
    required this.countryCode,
  });

  SetCountryState copyWith({
    String? dialCode,
    String? countryCode,
  }) {
    return SetCountryState(
      dialCode: dialCode ?? this.dialCode,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props => [dialCode, countryCode];
}

class SetCountryCubit extends Cubit<SetCountryState> {
  SetCountryCubit()
      : super(const SetCountryState(
          dialCode: "+1",
          countryCode: "US",
        ));

  void setCountry({required String dialCode, required String countryCode}) {
    emit(SetCountryState(dialCode: dialCode, countryCode: countryCode));
  }

  void reset() {
   }
   void clear() {
    emit(const SetCountryState(dialCode: "+1", countryCode: "US"));
  }
}
