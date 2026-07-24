
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:ride_on_driver/presentation/cubits/realtime/listen_ride_request_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/realtime/manage_driver_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/realtime/ride_status_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/register_vehicle/make_model_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/register_vehicle/profile_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/register_vehicle/register_vehicle_document.dart';
import 'package:ride_on_driver/presentation/cubits/register_vehicle/single_image_upload_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/register_vehicle/vehicle_register_cubit.dart';

import '../../core/extensions/workspace.dart';
import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import 'account/update_profile_cubit.dart';
import 'auth/login_cubit.dart';
import 'auth/otp_verify_cubit.dart';
import 'auth/resend_otp_cubit.dart';
import 'auth/signup_cubit.dart';
import 'auth/user_authenticate_cubit.dart';
import 'localizations_cubit.dart';

abstract class LogoutState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LogoutInitial extends LogoutState {}

class LogoutLoading extends LogoutState {}

class LogoutSuccess extends LogoutState {}

class LogoutFailure extends LogoutState {
  final String error;
  LogoutFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit() : super(LogoutInitial());

  Future<void> logout(BuildContext context) async {
    try {
      emit(LogoutLoading());
       isFatechedData=false;
      final box = await Hive.openBox('appBox');
      await box.clear();

      box.delete("documentData");

      token = "";
      loginModel = null;
      latitudeGlobal = "";
      longitudeGlobal = "";
      appLocale = const Locale('en');
      clearData(context);
 
      bool defaultDarkMode = false;

      box.put("getDarkValue", defaultDarkMode);
      box.put("driver_status", false);
      notifires.setIsDark = defaultDarkMode;
      token = "";
      box.put('isDocumentStatusShown', false);

      emit(LogoutSuccess());
    } catch (e) {
      emit(LogoutFailure(e.toString()));
    }
  }
}

Future<void> clearData(BuildContext context) async {
  cancelRideRequestWhenLogout(
      rideId: context
          .read<UpdateDriverParameterCubit>()
          .state
          .rideId,
      context: context);
  final box = await Hive.openBox('appBox');
  await box.clear();

  box.delete("documentData");
  myImage="";
  myName="";

  token = "";
  loginModel = null;
  latitudeGlobal = "";
  longitudeGlobal = "";
  appLocale = const Locale('en');
  bool defaultDarkMode = false;

  box.put("getDarkValue", defaultDarkMode);
  box.put("driver_status", false);
  notifires.setIsDark = defaultDarkMode;
  token = "";
  box.put('isDocumentStatusShown', false);
      // ignore_for_file: use_build_context_synchronously
  context.read<MyImageCubit>().updateMyImage("");
  context.read<GetDocApprovalStatusCubit>().resetStatus();
  context.read<GetDriverStatusCubit>().resetStatus();
  context.read<ListenRideRequestCubit>().listenForRideRequests("", context: context);
  context.read<ListenRideRequestCubit>().stopListening();
   context.read<VehicleFormCubit>().removeVehicleState();
  context.read<GetVehicleDocumentCubit>().resetState();
  context.read<DocumentApprovedStatusCubit>().removeDocumentApprovedStatus();
  context.read<UpdateDriverCubit>().resetDriver();
  context.read<NameCubit>().removeName();
  context.read<PhoneCubit>().phoneReset();
  context.read<EmailCubit>().emailReset();
  context.read<GenderCubit>().genderResetState();
  context.read<MyImageCubit>().imageReset();
  context.read<RideStatusCubit>().resetAllParameters();
  context.read<UpdateDriverParameterCubit>().resetAllParameters();

  context.read<CheckUpdatedDocumentImage>().removeImageDocumentStatus();
  context.read<CheckUpdatedLicenceImage>().removeImageLicenceStatus();
  context.read<CheckUpdatedImage>().removeImageStatus();

  context.read<UpdateDriverParameterCubit>().removeDriverId();
  context.read<UpdateDriverCubit>().resetDriver();

  context.read<SetupStepCubit>().resetStep();

  context.read<RegisterProfileCubits>().resetState();
  context.read<SingleImageUploadCubits>().removeSingleImage();
  context.read<VehicleRegisterCubit>().resetState();
  context.read<LanguageCubit>().loadCurrentLanguage();
  context.read<AuthOtpVerifyCubit>().resetState();
  context.read<AuthResendOtpCubit>().resetState();
  context.read<AuthSignUpCubit>().resetState();
  context.read<AuthUserAuthenticateCubit>().resetState();

  context.read<AuthLoginCubit>().resetState();
  context.read<UpdateDocImage>().removeImage();
  context.read<UpdateImageCommonBase64Img>().removeImage();
  context.read<UpdateDocImageCommon>().updateImage("", "");
  context.read<UpdateLicenceImage>().removeImage();

  context.read<VehicleFormCubit>().textEditingVehicleNumberController.clear();
  context.read<GetDocVehicleFormCubit>().remove();
  context.read<VehicleFormCubit>().removeVehicleState();
  context.read<VehicleFormCubit>().updateVehicleMake("");
  context.read<VehicleFormCubit>().updateVehicleBase64Img("");
  context.read<VehicleFormCubit>().updateVehicleLicenceBase64Img("");
  context.read<VehicleFormCubit>().updateVehicleNumber("");
  context.read<VehicleFormCubit>().updateVehicleModel("");
  context.read<VehicleFormCubit>().updateVehicleTypeName("");
  context.read<VehicleFormCubit>().updateVehicleTypeId("");
  context.read<VehicleFormCubit>().updateVehicleTypeImageUrl("");
  context.read<VehicleFormCubit>().textEditingVehicleModelController.clear();
  context.read<VehicleFormCubit>().textEditingVehicleYearController.clear();
  context.read<VehicleFormCubit>().textEditingVehicleBrandController.clear();
  context.read<VehicleFormCubit>().textEditingVehicleColorController.clear();
  context.read<CheckUpdatedDocumentImage>().checkUpdatedDocumentImage(false);
  context.read<CheckUpdatedLicenceImage>().checkUpdatedLicenceImage(false);
  context.read<CheckUpdatedImage>().checkUpdatedImage(false);
  context.read<SetDocImage>().setImage("");
  context.read<SetInsuranceImage>().setImage("");
  context.read<SetVehicleImage>().setImage("");
  context.read<SetVehicleImage>().setImage("");
  context.read<SetVehicleImage>().setImage("");
  context.read<UpdateImage>().removeImage();
  context.read<CheckUpdatedImage>().removeImageStatus();
 
}
