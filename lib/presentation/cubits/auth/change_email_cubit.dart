import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/data/repositories/auth_repository.dart';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/check_email.dart';

abstract class ChangeEmailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangeEmailInitial extends ChangeEmailState {}

class ChangeEmailLoading extends ChangeEmailState {}

class ChangeEmailSuccess extends ChangeEmailState {
  final CheckEmail checkEmail;

  ChangeEmailSuccess(this.checkEmail);

  @override
  List<Object?> get props => [checkEmail];
}

class ChangeEmailFailure extends ChangeEmailState {
  final String error;

  ChangeEmailFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ChangeEmailCubits extends Cubit<ChangeEmailState> {
  final AuthRepository repository;
  ChangeEmailCubits(this.repository) : super(ChangeEmailInitial());
  Future<void> changeEmail(String email) async {
    try {
      emit(ChangeEmailLoading());
      final response = await repository.changeEmail(email: email);
      if (response['status'] == 200) {
        emit(ChangeEmailSuccess(CheckEmail.fromJson(response)));
      } else {
        emit(ChangeEmailFailure(response['error']));
      }
    } catch (e) {
      emit(ChangeEmailFailure("Something went wrong"));
    }
  }
}
