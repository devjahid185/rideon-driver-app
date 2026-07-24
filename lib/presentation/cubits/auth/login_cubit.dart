import 'package:ride_on_driver/data/repositories/auth_repository.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/extensions/helper/push_notifications.dart';
 
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../domain/entities/login.dart';
import '../realtime/manage_driver_cubit.dart';

abstract class AuthLoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends AuthLoginState {}

class LoginLoading extends AuthLoginState {}

class LoginSuccess extends AuthLoginState {
  final LoginModel loginModel;
  LoginSuccess(this.loginModel);
  @override
  List<Object?> get props => [loginModel];
}

class LoginFailure extends AuthLoginState {
  final String error;
  LoginFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class AuthLoginCubit extends Cubit<AuthLoginState> {
  final AuthRepository authRepository;
  AuthLoginCubit(this.authRepository) : super(LoginInitial());

  Future<void> login(
      {required BuildContext context,
      required String phoneNumber,
      required String phoneCountry}) async {
    try {
      emit(LoginLoading());

      final response = await authRepository.login(
          context: context,
          phoneCountry: phoneCountry,
          phoneNumber: phoneNumber);

      if (response['status'] == 200) {
        loginModel = LoginModel.fromJson(response);


        if (loginModel != null && loginModel!.data != null) {
          token = loginModel!.data!.token ?? '';
          await syncPendingFcmTokenIfAny(forceSync: true);

          // ignore: use_build_context_synchronously
          context.read<UpdateDriverParameterCubit>().updateDriverId(
              driverId: loginModel!.data!.fireStoreId?.toString() ?? "");
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
        emit(LoginSuccess(LoginModel.fromJson(response)));
      } else {
        emit(LoginFailure(response['error']));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously

      emit(LoginFailure('Something went wrong: $e'));
    }
  }

  void resetState() {
    emit(LoginInitial());
  }
}
