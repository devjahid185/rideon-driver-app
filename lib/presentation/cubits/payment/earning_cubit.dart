
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/earning.dart';


abstract class EarningState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EarningInitial extends EarningState {}

class EarningLoading extends EarningState {}

class EarningSuccess extends EarningState {
  final DriverWalletModel? model;


  EarningSuccess({this.model,  });

  @override
  List<Object?> get props => [model];
}

class EarningError extends EarningState {
  final String? errorMessage;
  EarningError({this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}

class EarningCubit extends Cubit<EarningState> {
  PaymentRepository repository;
  EarningCubit(this.repository) : super(EarningInitial());

  Future<void> getEarningData({required BuildContext context,
    required Map<String, dynamic> mapData,

  }) async {
    try {
      emit(EarningLoading());
      var response = await repository.getEarningDriver(context: context,
          mapData: mapData);

      if (response["status"] == 200) {
        DriverWalletModel model=DriverWalletModel.fromJson(response);



        emit(EarningSuccess(model: model));
      } else {
        emit(EarningError(errorMessage: response["error"]));
      }
    } catch (error) {
      emit(EarningError(errorMessage: "$error"));
    }
  }

  void resetEarningData() {
    emit(EarningInitial());
  }
}
