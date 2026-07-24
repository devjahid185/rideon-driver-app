import 'dart:convert';

import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../domain/entities/login.dart';

abstract class RegisterProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterProfileState {}

class RegisterLoading extends RegisterProfileState {}

class RegisterSuccess extends RegisterProfileState {
  final LoginModel loginModel;
  RegisterSuccess(this.loginModel);

  @override
  List<Object?> get props => [loginModel];
}

class RegisterFailure extends RegisterProfileState {
  final String error;
  RegisterFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class RegisterProfileCubits extends Cubit<RegisterProfileState> {
  final RegisterVehicleRepository registerVehicleRepository;
  RegisterProfileCubits(this.registerVehicleRepository)
      : super(RegisterInitial());

  Future registerProfile(
      {required String name,
      required String gender,
      required BuildContext context}) async {
    try {
      emit(RegisterLoading());

      var response = await registerVehicleRepository.registerProfile(
          context: context, name: name, gender: gender);

      if (response["status"] == 200) {
        if (loginModel?.data?.gender != null &&
            loginModel!.data!.gender!.isNotEmpty) {
          UserData userObj = UserData();
          loginModel = LoginModel.fromJson(response);
          userObj.saveLoginData("UserData", jsonEncode(response));

          box.put("gender", true);
        } else {
          box.put("gender", false);
        }

        emit(RegisterSuccess(LoginModel.fromJson(response)));
      } else {
        emit(RegisterFailure(response["error"]));
      }
    } catch (e) {
      emit(RegisterFailure("Something went wrong $e"));
    }
  }

  void resetState() {
    emit(RegisterInitial());
  }
}
