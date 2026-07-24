import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../domain/entities/get_makes.dart';

abstract class MakeModelState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MakeModelInitial extends MakeModelState {}

class MakeModelLoading extends MakeModelState {}

class MakeModelSuccess extends MakeModelState {
  final List<MakeTypes> makeType;

  MakeModelSuccess(
    this.makeType,
  );
  @override
  List<Object?> get props => [makeType];
}

class MakeModelFailure extends MakeModelState {
  final String error;
  MakeModelFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class MakeModelCubit extends Cubit<MakeModelState> {
  final RegisterVehicleRepository registerVehicleRepository;
  MakeModelCubit(this.registerVehicleRepository) : super(MakeModelInitial());

  Future<void> getMakeModel(
      {required BuildContext context, String? value}) async {
    try {
      emit(MakeModelLoading());
      final response =
          await registerVehicleRepository.getMakesModel(context, value ?? "");
      if (response["status"] == 200) {
        GetMakeModel getMakeModel = GetMakeModel.fromJson(response);

        emit(MakeModelSuccess(getMakeModel.data!.makesTypes!));
      } else {
        emit(MakeModelFailure(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(MakeModelFailure("Something went wrong $e"));
    }
  }
  void reset() {
    emit(MakeModelInitial());
  }
}

class ModelState extends Equatable {
  final List<Models> models;
  final String? selectedModelId;

  const ModelState({required this.models, this.selectedModelId});

  @override
  List<Object?> get props => [models, selectedModelId];
}

class ModelCubit extends Cubit<ModelState> {
  ModelCubit() : super(const ModelState(models: [], selectedModelId: null));

  void updateList(List<Models> modelList) {
    emit(ModelState(models: List.from(modelList), selectedModelId: null));
  }

  void updateModelId(String modelId) {
    emit(ModelState(models: state.models, selectedModelId: modelId));
  }
}

class SelectedCubit extends Cubit<bool> {
  SelectedCubit() : super(false);

  void updateSelectedValue(bool selectedValue) {
    emit(false);

    emit(selectedValue);
  }
}

class UpdateImage extends Cubit<XFile?> {
  UpdateImage() : super(null);

  void updateImage(XFile newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit(null);
  }
}

class SetDocImage extends Cubit<String> {
  SetDocImage() : super("");

  void setImage(String newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit("");
  }
}

class SetInsuranceImage extends Cubit<String> {
  SetInsuranceImage() : super("");

  void setImage(String newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit("");
  }
}

class SetVehicleImage extends Cubit<String> {
  SetVehicleImage() : super("");

  void setImage(String newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit("");
  }
}

class CheckUpdatedImage extends Cubit<bool?> {
  CheckUpdatedImage() : super(false);

  void checkUpdatedImage(bool checkUpdatedImage) {
    emit(checkUpdatedImage);
  }

  void removeImageStatus() {
    emit(false);
  }
}

class CheckUpdatedLicenceImage extends Cubit<bool?> {
  CheckUpdatedLicenceImage() : super(false);

  void checkUpdatedLicenceImage(bool checkUpdatedImage) {
    emit(checkUpdatedImage);
  }

  void removeImageLicenceStatus() {
    emit(false);
  }
}

class CheckUpdatedDocumentImage extends Cubit<bool?> {
  CheckUpdatedDocumentImage() : super(false);

  void checkUpdatedDocumentImage(bool checkUpdatedImage) {
    emit(checkUpdatedImage);
  }

  void removeImageDocumentStatus() {
    emit(false);
  }
}

class UpdateImageCommon extends Cubit<XFile?> {
  UpdateImageCommon() : super(null);

  void updateImage(XFile newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit(null);
  }
}

class DocImageState {
  final String? imageUrl;
  final String status;

  DocImageState({this.imageUrl, required this.status});
}

class UpdateDocImageCommon extends Cubit<DocImageState> {
  UpdateDocImageCommon() : super(DocImageState(imageUrl: "", status: ""));

  void updateImage(String newImage, String newStatus) {
    emit(DocImageState(imageUrl: newImage, status: newStatus));
  }

  void removeImage() {
    emit(DocImageState(imageUrl: "", status: ""));
  }
}

/// Cubit for managing license images
class DriverLicenseImageState {
  final String? frontImage;
  final String? backImage;

  DriverLicenseImageState({this.frontImage = "", this.backImage = ""});

  DriverLicenseImageState copyWith({String? frontImage, String? backImage}) {
    return DriverLicenseImageState(
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
    );
  }
}


class DriverLicenseImageCubit extends Cubit<DriverLicenseImageState> {
  DriverLicenseImageCubit() : super(DriverLicenseImageState());

  void updateFrontImage(String base64Img) {
    emit(state.copyWith(frontImage: base64Img));
  }

  void removeFrontImage() {
    emit(state.copyWith(frontImage: ""));
  }

  void updateBackImage(String base64Img) {
    emit(state.copyWith(backImage: base64Img));
  }

  void removeBackImage() {
    emit(state.copyWith(backImage: ""));
  }

  void clearAll() {
    emit(DriverLicenseImageState(frontImage: "", backImage: ""));
  }
}

class DriverIdImageState {
  final String? frontImage;
  final String? backImage;

  DriverIdImageState({this.frontImage = "", this.backImage = ""});

  DriverIdImageState copyWith({String? frontImage, String? backImage}) {
    return DriverIdImageState(
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
    );
  }
}


class DriverIdImageCubit extends Cubit<DriverIdImageState> {
  DriverIdImageCubit() : super(DriverIdImageState());

  void updateFrontImage(String base64Img) {
    emit(state.copyWith(frontImage: base64Img));
  }

  void removeFrontImage() {
    emit(state.copyWith(frontImage: ""));
  }

  void updateBackImage(String base64Img) {
    emit(state.copyWith(backImage: base64Img));
  }

  void removeBackImage() {
    emit(state.copyWith(backImage: ""));
  }

  void clearAll() {
    emit(DriverIdImageState(frontImage: "", backImage: ""));
  }
}



class UpdateImageCommonBase64Img extends Cubit<String?> {
  UpdateImageCommonBase64Img() : super("");

  void updateImage(String base64Img) {
    emit(base64Img);
  }

  void removeImage() {
    emit("");
  }
}

class CheckSelectedCubit extends Cubit<bool> {
  CheckSelectedCubit() : super(false);

  void checkSelectedValue(bool selectedValue) {
    emit(selectedValue);
  }

  void removeSelectedValue() {
    emit(false);
  }
}

class LicenseImageState {
  final bool frontSelected;
  final bool backSelected;
  final XFile? frontImage;
  final String? frontBase64;
  final XFile? backImage;
  final String? backBase64;

  LicenseImageState({
    this.frontSelected = false,
    this.backSelected = false,
    this.frontImage,
    this.frontBase64,
    this.backImage,
    this.backBase64,
  });

  LicenseImageState copyWith({
    bool? frontSelected,
    bool? backSelected,
    XFile? frontImage,
    String? frontBase64,
    XFile? backImage,
    String? backBase64,
  }) {
    return LicenseImageState(
      frontSelected: frontSelected ?? this.frontSelected,
      backSelected: backSelected ?? this.backSelected,
      frontImage: frontImage ?? this.frontImage,
      frontBase64: frontBase64 ?? this.frontBase64,
      backImage: backImage ?? this.backImage,
      backBase64: backBase64 ?? this.backBase64,
    );
  }
}

class LicenseSelectionCubit extends Cubit<LicenseImageState> {
  LicenseSelectionCubit() : super(LicenseImageState());

  void setFrontSelected(bool selected) {
    emit(state.copyWith(frontSelected: selected));
  }

  void setBackSelected(bool selected) {
    emit(state.copyWith(backSelected: selected));
  }

  void setFrontImage(XFile? image, String? base64) {
    emit(state.copyWith(frontImage: image, frontBase64: base64));
  }

  void setBackImage(XFile? image, String? base64) {
    emit(state.copyWith(backImage: image, backBase64: base64));
  }
}

class UpdateDocImage extends Cubit<XFile?> {
  UpdateDocImage() : super(null); // Initialize with null

  void updateImage(XFile newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit(null);
  }
}

class UpdateLicenceImage extends Cubit<XFile?> {
  UpdateLicenceImage() : super(null); // Initialize with null

  void updateImage(XFile newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit(null);
  }
}
class UpdateLicenceImage2 extends Cubit<XFile?> {
  UpdateLicenceImage2() : super(null); // Initialize with null

  void updateImage(XFile newImage) {
    emit(newImage);
  }

  void removeImage() {
    emit(null);
  }
}
class VehicleFormState extends Equatable {
  final String vehicleNumber;
  final String vehicleYear;
  final String vehicleColor;
  final String vehicleTypeId;
  final String vehcileTypeName;
  final String vechicleImageUrl;
  final String driverStatus;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleBase64Image;
  final String vehicleDocBase64Image;
  final String vehicleLicenceBase64Image;
  final String vehicleLicenceBase64Image2;
  final bool shouldClearMake;
  final bool shouldClearModel;

  const VehicleFormState({
    this.driverStatus = '',
    this.vehicleNumber = '',
    this.vehicleColor = '',
    this.vehicleYear = '',
    this.vehcileTypeName = "",
    this.vechicleImageUrl = "",
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.vehicleTypeId = '',
    this.vehicleDocBase64Image = '',
    this.vehicleBase64Image = '',
    this.vehicleLicenceBase64Image = '',
    this.vehicleLicenceBase64Image2 = '',
     this.shouldClearMake=false,
     this.shouldClearModel=false
  });

  VehicleFormState copyWith(
      {String? vehicleNumber,
      String? vehicleYear,
      String? vehicleColor,
      String? vehcileTypeName,
      String? vechicleImageUrl,
      String? vehicleMake,
      String? vehicleDocBase64Image,
      String? vehicleModel,
      String? vehicleTypeId,
      String? vehicleBase64Image,
      String? vehicleLicenceBase64Image,
      String? vehicleLicenceBase64Image2,
      String? driverStatus,
        bool? shouldClearMake,
        bool? shouldClearModel,
      }) {
    return VehicleFormState(
      driverStatus: driverStatus ?? this.driverStatus,
      vechicleImageUrl: vechicleImageUrl ?? this.vechicleImageUrl,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleLicenceBase64Image: vehicleLicenceBase64Image ?? this.vehicleLicenceBase64Image,
      vehicleLicenceBase64Image2: vehicleLicenceBase64Image2 ?? this.vehicleLicenceBase64Image2,
      vehcileTypeName: vehcileTypeName ?? this.vehcileTypeName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      vehicleBase64Image: vehicleBase64Image ?? this.vehicleBase64Image,
      vehicleDocBase64Image:
          vehicleDocBase64Image ?? this.vehicleDocBase64Image,
      shouldClearMake: shouldClearMake ?? this.shouldClearMake,
      shouldClearModel: shouldClearModel ?? this.shouldClearModel,
    );
  }

  @override
  List<Object?> get props => [
        vehicleNumber,
        vehicleYear,
        vehicleMake,
        vehicleModel,
        vehicleColor,
        vehcileTypeName,
        vehicleTypeId,
        driverStatus,
        vehicleBase64Image,
        vehicleDocBase64Image,
        vehicleLicenceBase64Image,
    vehicleLicenceBase64Image2,
        vechicleImageUrl,
    shouldClearMake,
    shouldClearModel,
      ];
}

class VehicleFormCubit extends Cubit<VehicleFormState> {
  TextEditingController textEditingVehicleNumberController =
      TextEditingController();
  TextEditingController textEditingVehicleBrandController =
      TextEditingController();
  TextEditingController textEditingVehicleModelController =
      TextEditingController();
  TextEditingController textEditingVehicleYearController =
      TextEditingController();
  TextEditingController textEditingVehicleColorController =
      TextEditingController();

  VehicleFormCubit() : super(const VehicleFormState());

  void updateVehicleBase64Img(String base64Img) {
    var newState = state.copyWith(vehicleBase64Image: base64Img);
    emit(newState);
  }

  void removeVehicleBase64Img() {
    var newState = state.copyWith(vehicleBase64Image: "");
    emit(newState);
  }

  void updateDriverStatus(String driverStatus) {
    emit(state.copyWith(driverStatus: driverStatus));
  }

  String getDriverStatus() {
    return state.driverStatus;
  }

  void updateVehicleDocBase64Img(String base64Img) {
    var newState = state.copyWith(vehicleDocBase64Image: base64Img);
    emit(newState);
  }

  void removeVehicleDocBase64Img() {
    var newState = state.copyWith(vehicleDocBase64Image: "");
    emit(newState);
  }

  void updateVehicleLicenceBase64Img(String base64Img) {
    var newState = state.copyWith(vehicleLicenceBase64Image: base64Img);
    emit(newState);
  }

  void removeVehicleLicenceBase64Img() {
    var newState = state.copyWith(vehicleLicenceBase64Image: "");
    emit(newState);
  }
  void updateVehicleLicenceBase64Img2(String base64Img) {
    var newState = state.copyWith(vehicleLicenceBase64Image2: base64Img);
    emit(newState);
  }

  void removeVehicleLicenceBase64Img2() {
    var newState = state.copyWith(vehicleLicenceBase64Image2: "");
    emit(newState);
  }

  void updateVehicleNumber(String number) {
    emit(state.copyWith(vehicleNumber: number));
  }

  void updateVehicleColor(String color) {
    emit(state.copyWith(vehicleColor: color));
  }

  void updateVehicleYear(String year) {
    emit(state.copyWith(vehicleYear: year));
  }

  void updateVehicleModel(String model) {
    emit(state.copyWith(vehicleModel: model));
  }

  void updateVehicleMake(String make) {
    emit(state.copyWith(vehicleMake: make));
  }


  void updateVehicleTypeId(String vehicleTypeId,
      ) {

    emit(state.copyWith(
      vehicleTypeId: vehicleTypeId,
      vehicleMake: '',
      shouldClearMake: true,
      shouldClearModel: true,
    ));


      // Reset Make data

    Future.delayed(const Duration(milliseconds: 300), () {
      emit(state.copyWith(
        shouldClearMake: false,
        shouldClearModel: false,
      ));
    });
  }

  void updateVehicleTypeName(String vehicleTypeName) {
    emit(state.copyWith(vehcileTypeName: vehicleTypeName));
  }

  void updateVehicleTypeImageUrl(String vechicleImageUrl) {
    emit(state.copyWith(vechicleImageUrl: vechicleImageUrl));
  }

  @override
  Future<void> close() {
    textEditingVehicleNumberController.dispose();

    return super.close();
  }

  void removeVehicleState() {
    textEditingVehicleNumberController.clear();
    emit(const VehicleFormState());
  }
}
