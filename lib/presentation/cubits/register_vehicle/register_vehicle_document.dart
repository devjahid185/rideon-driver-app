import 'dart:convert';
import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/data_store.dart';
import '../../../domain/entities/document_image.dart';

abstract class RegisterVehicleDocumentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DocumentInitial extends RegisterVehicleDocumentState {}

class DocumentReset extends RegisterVehicleDocumentState {}

class DocumentLoading extends RegisterVehicleDocumentState {}

class DocumentSuccess extends RegisterVehicleDocumentState {
  @override
  List<Object?> get props => [];
}

class DocumentFailure extends RegisterVehicleDocumentState {
  final String error;
  DocumentFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class RegisterVehicleDocumentCubit extends Cubit<RegisterVehicleDocumentState> {
  final RegisterVehicleRepository registerVehicleRepository;
  RegisterVehicleDocumentCubit(this.registerVehicleRepository)
      : super(DocumentInitial());
  Future<void> uploadDocument(
      {required String vehicleId,
      required Map<String, dynamic> itemImageMap,
      required BuildContext context}) async {
    try {
      emit(DocumentLoading());

      final response = await registerVehicleRepository.uploadSingleDocumentImg(
          context: context, vehicleId: vehicleId, itemImageMap: itemImageMap);

      if (response["status"] == 200) {
        emit(DocumentSuccess());
      } else {
        emit(DocumentFailure(response["message"]));
      }
    } catch (err) {
      emit(DocumentFailure("Something went wrong $err"));
    }
  }

  void resetState() {
    emit(DocumentReset());
    emit(DocumentInitial());
  }
}

abstract class GetVehicleDocumentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetDocumentInitial extends GetVehicleDocumentState {}

class GetDocumentLoading extends GetVehicleDocumentState {}

class GetDocumentSuccess extends GetVehicleDocumentState {
  final DocumentImageModel documentImageModel;
  GetDocumentSuccess(this.documentImageModel);
  @override
  List<Object?> get props => [documentImageModel];
}

class GetDocumentFailure extends GetVehicleDocumentState {
  final String error;
  GetDocumentFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class GetVehicleDocumentCubit extends Cubit<GetVehicleDocumentState> {
  final RegisterVehicleRepository registerVehicleRepository;
  GetVehicleDocumentCubit(this.registerVehicleRepository)
      : super(GetDocumentInitial());

  Future<void> getUploadDocument({required BuildContext context}) async {
    try {
      emit(GetDocumentLoading());
      final response =
          await registerVehicleRepository.getVehicleDocument(context: context);
      if (response["status"] == 200) {
        UserData userObj = UserData();
        userObj.saveLoginData("documentData", jsonEncode(response));

        emit(GetDocumentSuccess(DocumentImageModel.fromJson(response)));
      } else {
        emit(GetDocumentFailure(response["message"]));
      }
    } catch (err) {
      emit(GetDocumentFailure("Something went wrong $err"));
    }
  }

  void resetState() {
    emit(GetDocumentInitial());
  }
}

class GetDocVehicleFormState extends Equatable {
  final String driverIdFront;
  final String driverIdBack;
  final String drivingLicenceFront;
  final String drivingLicenceBack;
  final String driverIdFrontStatus;
  final String driverIdBackStatus;
  final String drivingLicenceFrontStatus;
  final String drivingLicenceBackStatus;
  final String vehicleId;

  const GetDocVehicleFormState({
    this.driverIdFront = '',
    this.driverIdBack = '',
    this.drivingLicenceFront = '',
    this.drivingLicenceBack = '',
    this.vehicleId = "",
    this.driverIdFrontStatus = "",
    this.driverIdBackStatus = "",
    this.drivingLicenceFrontStatus = "",
    this.drivingLicenceBackStatus = "",
  });

  GetDocVehicleFormState copyWith(
      {String? driverIdFront,
      String? driverIdBack,
      String? drivingLicenceFront,
      String? drivingLicenceBack,
      String? driverIdFrontStatus,
      String? driverIdBackStatus,
      String? drivingLicenceFrontStatus,
      String? drivingLicenceBackStatus,
      String? vehicleId,
      bool? checkAllStatusApprovded}) {
    return GetDocVehicleFormState(
      vehicleId: vehicleId ?? this.vehicleId,
      driverIdFront: driverIdFront ?? this.driverIdFront,
      driverIdBack: driverIdBack ?? this.driverIdBack,
      drivingLicenceFront: drivingLicenceFront ?? this.drivingLicenceFront,
      drivingLicenceBack: drivingLicenceBack ?? this.drivingLicenceBack,
      driverIdFrontStatus: driverIdFrontStatus ?? this.driverIdFrontStatus,
      driverIdBackStatus: driverIdBackStatus ?? this.driverIdBackStatus,
      drivingLicenceFrontStatus: drivingLicenceFrontStatus ?? this.drivingLicenceFrontStatus,
      drivingLicenceBackStatus: drivingLicenceBackStatus ?? this.drivingLicenceBackStatus,

    );
  }

  @override
  List<Object?> get props => [
        driverIdFront,
        driverIdBack,
        drivingLicenceFront,
        drivingLicenceBack,
        driverIdFrontStatus,
        driverIdBackStatus,
        drivingLicenceFrontStatus,
        drivingLicenceBackStatus,
        vehicleId
      ];
}

class GetDocVehicleFormCubit extends Cubit<GetDocVehicleFormState> {
  GetDocVehicleFormCubit() : super(const GetDocVehicleFormState());

  void updateDrivingLicenceFront(String image, String status) {
    var newState = state.copyWith(
        drivingLicenceFront: image, drivingLicenceFrontStatus: status);
    emit(newState);
  }
  void updateDrivingLicenceBack(String image, String status) {
    var newState = state.copyWith(
        drivingLicenceBack: image, drivingLicenceBackStatus: status);
    emit(newState);
  }

  void updateDriverIdFront(
      String image,   String status) {
    var newState = state.copyWith(
        driverIdFront: image, driverIdFrontStatus: status);
    emit(newState);
  }
  void updateDriverIdBack(
      String image, String status) {
    var newState = state.copyWith(
        driverIdBack: image, driverIdBackStatus: status);
    emit(newState);
  }

  void updateVehicleId(String id) {
    var newState = state.copyWith(vehicleId: id);
    emit(newState);
  }

  void remove() {
    emit(const GetDocVehicleFormState());
  }
}

class UpdateDocImageStatusCommon extends Cubit<String?> {
  UpdateDocImageStatusCommon() : super("");

  void updateStatus(String status) {
    emit(status);
  }

  void removeStatus() {
    emit("");
  }
}

class SetupStepState extends Equatable {
  final int currentStep;

  const SetupStepState({
    this.currentStep = 0,
  });

  SetupStepState copyWith({int? currentStep}) {
    return SetupStepState(
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [currentStep];
}

class SetupStepCubit extends Cubit<SetupStepState> {
  SetupStepCubit({int? initialStep})
      : super(SetupStepState(currentStep: initialStep ?? 0));

  void goToStep(int step) {
    var newState = state.copyWith(
      currentStep: step,
    );
    emit(newState);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      var newState = state.copyWith(
        currentStep: state.currentStep + 1,
      );

      emit(newState);
    }
  }

  void resetStep() => emit(state.copyWith(
        currentStep: 0,
      ));
}
