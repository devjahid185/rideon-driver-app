
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/extensions/workspace.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/make_model_cubit.dart';
import '../../cubits/register_vehicle/register_vehicle_document.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';

class DriverDocumentScreen extends StatefulWidget {
  const DriverDocumentScreen({super.key});

  @override
  State<DriverDocumentScreen> createState() => _DriverDocumentScreenState();
}

class _DriverDocumentScreenState extends State<DriverDocumentScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool showIconFirst = false;
  bool showIconFourth = false;

  bool documentUploadSuccess = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetVehicleDocumentCubit>().getUploadDocument(context: context);
    });
  }

  void safeGoBack() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [

        BlocListener<RegisterVehicleDocumentCubit, RegisterVehicleDocumentState>(
          listener: (context, state) {
            if (state is DocumentLoading) {
              Widgets.showLoader(context);
            } else if (state is DocumentSuccess) {
              _onUploadSuccess(context);
            } else if (state is DocumentFailure) {
              Widgets.hideLoder(context);
              showErrorToastMessage(state.error);
            }
          },
        ),


        BlocListener<GetVehicleDocumentCubit, GetVehicleDocumentState>(
          listener: (context, state) {
            if (state is GetDocumentLoading) {
              isLoading = true;
            } else if (state is GetDocumentSuccess) {
              isLoading = false;
              _onFetchDocuments(context, state);
            } else if (state is GetDocumentFailure) {
              isLoading = false;
            }
          },
        ),
      ],
      child: Column(
        children: [

          BlocBuilder<GetDocVehicleFormCubit, GetDocVehicleFormState>(
            builder: (context, state) {
              return _buildUploadItem(
                context,
                title: "Driving License",
                subtitle: "A Driving license is an official document",
                status: getDocStatus(state.drivingLicenceFrontStatus, state.drivingLicenceBackStatus),
                frontStatus: state.drivingLicenceFrontStatus,
                backStatus: state.drivingLicenceBackStatus,
                showIcon: showIconFirst,
                frontImageUrl: state.drivingLicenceFront,
                backImageUrl: state.drivingLicenceBack,
                onUpdate: (base64, isFront) {
                  isFront
                      ? context.read<DriverLicenseImageCubit>().updateFrontImage(base64)
                      : context.read<DriverLicenseImageCubit>().updateBackImage(base64);
                },
                onTap: () => _onUploadTap(
                  context,
                  state.drivingLicenceFront,
                  state.drivingLicenceBack,
                  state.drivingLicenceFrontStatus,
                  context.read<DriverLicenseImageCubit>().state,
                  "driving_licence_front",
                  "driving_licence_back",
                ),
              );
            },
          ),


          BlocBuilder<GetDocVehicleFormCubit, GetDocVehicleFormState>(
            builder: (context, state) {
              return _buildUploadItem(
                context,
                title: "Driver Id",
                subtitle: "Add photo",
                status: getDocStatus(state.driverIdFrontStatus, state.driverIdBackStatus),
                frontStatus: state.driverIdFrontStatus,
                backStatus: state.driverIdBackStatus,
                showIcon: showIconFourth,
                frontImageUrl: state.driverIdFront,
                backImageUrl: state.driverIdBack,
                onUpdate: (base64, isFront) {
                  isFront
                      ? context.read<DriverIdImageCubit>().updateFrontImage(base64)
                      : context.read<DriverIdImageCubit>().updateBackImage(base64);
                },
                onTap: () => _onUploadTap(
                  context,
                  state.driverIdFront,
                  state.driverIdBack,
                  state.driverIdFrontStatus,
                  context.read<DriverIdImageCubit>().state,
                  "driver_id_front",
                  "driver_id_back",
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  void _onUploadSuccess(BuildContext context) {
    documentUploadSuccess = false;
    context.read<RegisterVehicleDocumentCubit>().resetState();
    Widgets.hideLoder(context);

    showModalBottomSheet(
      backgroundColor: whiteColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CustomBottomSheet(
          onClose: () {
            safeGoBack();
            setState(() => documentUploadSuccess = false);
          },
        );
      },
    );

    context.read<UpdateImageCommon>().removeImage();
    context.read<UpdateImageCommonBase64Img>().removeImage();
    context.read<GetVehicleDocumentCubit>().getUploadDocument(context: context);
  }


  void _onFetchDocuments(BuildContext context, GetDocumentSuccess state) {
    final documents = state.documentImageModel.data;

    if (documents?.drivingLicenceFront?.drivingLicenceImage?.isNotEmpty ?? false) {
      context.read<GetDocVehicleFormCubit>().updateDrivingLicenceFront(
        documents?.drivingLicenceFront?.drivingLicenceImage ?? "",
        documents?.drivingLicenceFront?.drivingLicenceStatus ?? "",
      );
    }
    if (documents?.drivingLicenceBack?.drivingLicenceImageBack?.isNotEmpty ?? false) {
      context.read<GetDocVehicleFormCubit>().updateDrivingLicenceBack(
        documents?.drivingLicenceBack?.drivingLicenceImageBack ?? "",
        documents?.drivingLicenceBack?.drivingLicenceBackStatus ?? "",
      );
    }

    if (documents?.driverIdFront?.driverIdFrontImage?.isNotEmpty ?? false) {
      context.read<GetDocVehicleFormCubit>().updateDriverIdFront(
          documents?.driverIdFront?.driverIdFrontImage??"",
         documents?.driverIdFront?.driverIdFrontImageStatus??"",
      );
    }
    if (documents?.driverIdBack?.driverIdBackImage?.isNotEmpty ?? false) {
      context.read<GetDocVehicleFormCubit>().updateDriverIdBack(
        documents?.driverIdBack?.driverIdBackImage??"",
        documents?.driverIdBack?.driverIdBackImageStatus??"",
      );
    }

    final stateAll = context.read<GetDocVehicleFormCubit>().state;
    List<String> statusList = [
      stateAll.driverIdFrontStatus,
      stateAll.driverIdBackStatus,
      stateAll.drivingLicenceFrontStatus,
      stateAll.drivingLicenceBackStatus,
    ];

    if (statusList.every((status) => status == "approved")) {
      context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "approved");
      box.put("approved", true);
      loginModel!.data!.itemDocumentStatus="approved";
      UserData userObj = UserData();
      userObj.saveLoginData("UserData", jsonEncode(loginModel!.toJson()));
    } else if (statusList.contains("rejected")) {
      context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "rejected");
      box.put("approved", false);
    } else {
      context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "pending");
      context.read<UpdateDriverParameterCubit>().updateDocApprovedStatus(docApprovedStatus: "pending");
      box.put("approved", false);
    }
  }


  Widget _buildUploadItem(
      BuildContext context, {
        required String title,
        required String subtitle,
        required String status,
        required String frontStatus,
        required String backStatus,
        required bool showIcon,
        required String frontImageUrl,
        required String backImageUrl,
        required Function(String, bool) onUpdate,
        required Function() onTap,
      }) {
    return UploadItem(
      assetImagePath: status == "pending"
          ? "assets/images/pendings.png"
          : status == "approved"
          ? "assets/images/approvedIcon.png"
          : status == "rejected"
          ? "assets/images/editing.png"
          : showIcon
          ? "assets/images/uploadImgBlack.png"
          : "assets/images/uploadImg.png",
      title: title,
      subtitle: subtitle,
      onUploadPressed: () {
        if (isLoading) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CustomBottomSheetDocument(
            title: title,
            description: "${"Please upload front and back side of your".translate(context)} ${title.translate(context)}",
            frontLabel: "Front",
            backLabel: "Back",
            frontImageUrl: frontImageUrl,
            backImageUrl: backImageUrl,
            onImageUpdate: onUpdate,
            onTap: onTap, frontStatus: frontStatus, backStatus: backStatus,
          ),
        );
      },
    );
  }


  void _onUploadTap(
      BuildContext context,
      String oldFront,
      String oldBack,
      String status,
      dynamic cubitState,
      String frontKey,
      String backKey,
      ) {
    safeGoBack();

    if ((oldFront.isEmpty || oldBack.isEmpty) &&
        (cubitState.frontImage!.isEmpty || cubitState.backImage!.isEmpty)) {
      showErrorToastMessage("Select image first".translate(context));
      return;
    }


    final vehicleId = context.read<UpdateAddEditVehicleIdCubit>().state.vehicleAddEditTypeId;
    if (vehicleId == null || vehicleId == 0) {
      showErrorToastMessage("Vehicle ID is not being received.");
      return;
    }

    final Map<String, String> itemImageMap = {};
    if (cubitState.frontImage != null && cubitState.frontImage!.isNotEmpty) {
      itemImageMap[frontKey] = cubitState.frontImage!;
    }
    if (cubitState.backImage != null && cubitState.backImage!.isNotEmpty) {
      itemImageMap[backKey] = cubitState.backImage!;
    }

    context.read<RegisterVehicleDocumentCubit>().uploadDocument(
      context: context,
      vehicleId: vehicleId.toString(),
      itemImageMap: itemImageMap,
    );
  }
}

