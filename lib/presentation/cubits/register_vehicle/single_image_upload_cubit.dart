import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SingleImageUploadState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SingleImageInitial extends SingleImageUploadState {}

class SingleImageLoading extends SingleImageUploadState {}

class SingleImageReset extends SingleImageUploadState {}

class SingleImageSuccess extends SingleImageUploadState {
  final String? status;
  SingleImageSuccess({this.status});
  @override
  List<Object?> get props => [status];
}

class SingleImageFailure extends SingleImageUploadState {
  final String? error;
  final String? status;
  SingleImageFailure({this.error, this.status});
  @override
  List<Object?> get props => [error, status];
}

class SingleImageUploadCubits extends Cubit<SingleImageUploadState> {
  final RegisterVehicleRepository registerVehicleRepository;
  SingleImageUploadCubits(this.registerVehicleRepository)
      : super(SingleImageInitial());
  Future<void> uploadSingleImage(
      {required String itemId,
      required BuildContext context,
      required Map<String, dynamic> itemImageMap,
      String? status}) async {
    try {
      emit(SingleImageLoading());
      final response = await registerVehicleRepository.uploadSingleImg(
          context: context, itemId: itemId, itemImageMap: itemImageMap);
      if (response["status"] == 200) {
        emit(SingleImageSuccess(status: status));
      } else {
        emit(SingleImageFailure(
            error: response["message"], status: status ?? ""));
      }
    } catch (err) {
      emit(SingleImageFailure(
          error: "Something went wrong $err", status: status));
    }
  }

  removeSingleImage() {
    emit(SingleImageReset());
    emit(SingleImageInitial());
  }
}
