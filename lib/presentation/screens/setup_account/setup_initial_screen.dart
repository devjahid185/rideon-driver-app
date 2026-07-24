

import 'dart:convert';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
 import '../../cubits/logout_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/get_vehicle_data.dart';
import '../../cubits/register_vehicle/make_model_cubit.dart';
import '../../cubits/register_vehicle/profile_cubit.dart';
import '../../cubits/register_vehicle/register_vehicle_document.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';
import '../../widgets/welcome_screen.dart';
import '../Auth/login_screen.dart';
import 'driver_document_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_vehicle_screen.dart';

class SetupInitialScreen extends StatefulWidget {
  final int? stepIndex;
  const SetupInitialScreen({super.key, this.stepIndex});

  @override
  State<SetupInitialScreen> createState() => _SetupInitialScreenState();
}

class _SetupInitialScreenState extends State<SetupInitialScreen> {
  int activeStep = 0;
  final RefreshController refreshController = RefreshController();
  Map<String, dynamic>? initialVehicleData;

  final List<Widget> stepWidgets = [
    const Profile(),
    const DriverVehicleScreen(isEdit: false),
    const DriverDocumentScreen(),
  ];

  final List<String> stepTitles = [
    "Profile",
    "Vehicle's Information",
    "Documents",
  ];

  @override
  void initState() {
    super.initState();
    activeStep = widget.stepIndex ?? 0;
    _initializeCubits();
  }

  void _initializeCubits() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<GetVehicleDataCubit>().getAllCategories(context: context);
      context.read<MakeModelCubit>().getMakeModel(
        context: context,
        value: box.get("UpdatedItemTypeId") ??
            loginModel?.data?.itemTypeId.toString() ??
            "",
      );
      if (box.get("itemTypeId") == true) {
        context.read<GetItemVehicleDataCubit>().getVehicleItemData(context: context);
      }
    });
  }


  void _nextStep() {
    if (activeStep <= stepWidgets.length - 1) {
      if (_validateAndProceed(activeStep, activeStep + 1)) {
        _handleStepAction(activeStep);
      }
    } else {
      _navigateToWelcomeScreen();
     }
  }

  void _previousStep() {
    if (activeStep > 0) {
      setState(() => activeStep--);
    } else {
      _showLogoutBottomSheet();
    }
  }


  void _goToStep(int index) {
    if (index >= 0 && index < stepWidgets.length) {
      if (index <= activeStep) {
        setState(() => activeStep = index);
      } else {
        for (int i = activeStep; i < index; i++) {
          if (!_validateAndProceed(i, index)) return;
        }
        _handleStepAction(activeStep);
      }
    }
  }


  bool _validateAndProceed(int currentStep, int targetStep) {
    if (targetStep <= currentStep) return true;

    switch (currentStep) {
      case 0:
        return _validateProfileStep();
      case 1:
        return _validateVehicleStep();
      case 2:
        return _validateDocumentStep();
      default:
        return true;
    }
  }


  bool _validateProfileStep() {
    if (loginModel?.data?.gender == null || loginModel!.data!.gender!.isEmpty) {
      showErrorToastMessage("Please select gender".translate(context));
      return false;
    }
    if (loginModel?.data?.firstName == null || loginModel!.data!.firstName!.isEmpty) {
      showErrorToastMessage("Please select Name".translate(context));
      return false;
    }
    return true;
  }


  bool _validateVehicleStep() {
    final vehicleFormState = context.read<VehicleFormCubit>().state;
    if (vehicleFormState.vehicleTypeId.isEmpty) {
      showErrorToastMessage("Select the vehicle type".translate(context));
      return false;
    }
    if (vehicleFormState.vehicleMake.isEmpty) {
      showErrorToastMessage("Select the Brand type".translate(context));
      return false;
    }
    if (context.read<VehicleFormCubit>().textEditingVehicleModelController.text.isEmpty) {
      showErrorToastMessage("Select the Model type".translate(context));
      return false;
    }
    if (context.read<VehicleFormCubit>().textEditingVehicleNumberController.text.isEmpty) {
      showErrorToastMessage("Enter the vehicle registration number".translate(context));
      return false;
    }
    if (context.read<VehicleFormCubit>().textEditingVehicleColorController.text.isEmpty) {
      showErrorToastMessage("Enter the vehicle color".translate(context));
      return false;
    }
    if (vehicleFormState.vehicleYear.isEmpty) {
      showErrorToastMessage("Enter the vehicle Year".translate(context));
      return false;
    }
    if (vehicleFormState.vehicleBase64Image.isEmpty && box.get("itemTypeId") == false) {
      showErrorToastMessage("Select the vehicle Image".translate(context));
      return false;
    }
    if (vehicleFormState.vehicleDocBase64Image.isEmpty && box.get("itemTypeId") == false) {
      showErrorToastMessage("Select the vehicle Document Image".translate(context));
      return false;
    }
    if (vehicleFormState.vehicleLicenceBase64Image.isEmpty && box.get("itemTypeId") == false) {
      showErrorToastMessage("Select the vehicle License Image".translate(context));
      return false;
    }
    return true;
  }


  bool _validateDocumentStep() {
    final state = context.read<GetDocVehicleFormCubit>().state;
    if (state.drivingLicenceFront.isNotEmpty && state.driverIdFront.isNotEmpty) {
      return true;
    }
    showErrorToastMessage("All images are required. Please upload them before proceeding.");
    return false;
  }

  void _handleStepAction(int currentStep) {
    if (currentStep == 0) {
      context.read<RegisterProfileCubits>().registerProfile(
        gender: loginModel!.data!.gender ?? "",
        name: loginModel!.data!.firstName ?? "",
        context: context,
      );
    } else if (currentStep == 1 && _hasVehicleDataChanged()) {
      _updateVehicleData();
    } else if (currentStep == 2) {
      _navigateToWelcomeScreen();
    } else {
      setState(() => activeStep++);
    }
  }


  bool _hasVehicleDataChanged() {
    if (initialVehicleData == null) return true;
    final vehicleFormState = context.read<VehicleFormCubit>().state;
    final stateDriverParameter = context.read<UpdateDriverParameterCubit>().state;

    return vehicleFormState.vehicleTypeId != initialVehicleData!['vehicleTypeId'] ||
        stateDriverParameter.vehicleTypeId != initialVehicleData!['vehicleTypeId'] ||
        vehicleFormState.vehicleMake != initialVehicleData!['vehicleMake'] ||
        vehicleFormState.vehicleModel != initialVehicleData!['vehicleModel'] ||
        vehicleFormState.vehicleNumber != initialVehicleData!['vehicleNumber'] ||
        vehicleFormState.vehicleYear != initialVehicleData!['vehicleYear'] ||
        vehicleFormState.vehicleColor != initialVehicleData!['vehicleColor'] ||
        vehicleFormState.vehicleBase64Image != initialVehicleData!['vehicleBase64Image'] ||
        vehicleFormState.vehicleDocBase64Image != initialVehicleData!['vehicleDocBase64Image'] ||
        vehicleFormState.vehicleLicenceBase64Image != initialVehicleData!['vehicleLicenceBase64Image'];
  }


  void _updateVehicleData() {
    final vehicleFormState = context.read<VehicleFormCubit>().state;
    final metaDataMap = context.read<MetaDataMap>();
    metaDataMap.insertToMap("year", vehicleFormState.vehicleYear);
    metaDataMap.insertToMap(
        "vehicle_registration_number",
        context.read<VehicleFormCubit>().textEditingVehicleNumberController.text);
    metaDataMap.insertToMap("make", vehicleFormState.vehicleMake);
    metaDataMap.insertToMap(
        "model", context.read<VehicleFormCubit>().textEditingVehicleModelController.text);
    metaDataMap.insertToMap("service_type", "booking");

    final addItemMap = context.read<AddItemMap>();
    addItemMap.insertToMap("metaData", jsonEncode(metaDataMap.state));
    addItemMap.insertToMap("make", vehicleFormState.vehicleMake);
    addItemMap.insertToMap(
        "model", context.read<VehicleFormCubit>().textEditingVehicleModelController.text);
    addItemMap.insertToMap("year", vehicleFormState.vehicleYear);
    addItemMap.insertToMap(
        "color", context.read<VehicleFormCubit>().textEditingVehicleColorController.text);
    addItemMap.insertToMap(
        "registration_number",
        context.read<VehicleFormCubit>().textEditingVehicleNumberController.text);

    final state = context.read<GetVehicleDataCubit>().state;
    if (state is GetVehicleSuccess) {
      final vehicleId = context.read<UpdateAddEditVehicleIdCubit>().state.vehicleAddEditTypeId;
      if (vehicleId != null && vehicleId != 0) {
        context.read<VehicleRegisterCubit>().resetState();
        context.read<VehicleRegisterCubit>().insertItem(
          context: context,
          itemMap: addItemMap.state,
          itemId: vehicleId.toString(),
          itemTypeId: vehicleFormState.vehicleTypeId,
        );
        box.put("UpdatedItemTypeId", vehicleFormState.vehicleTypeId);
      } else {
        showErrorToastMessage("Vehicle ID is not being received.");
        return;
      }
    }
  }


  void _navigateToWelcomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }


  void _showLogoutBottomSheet() {
    showDynamicBottomSheets(
      context,
      title: "Logout".translate(context),
      description: "Are you sure you want to logout?".translate(context),
      firstButtontxt: "Cancel".translate(context),
      secondButtontxt: "Yes".translate(context),
      onpressed: () => Navigator.pop(context),
      onpressed1: () async {
        token = "";
        context.read<LogoutCubit>().logout(context);
        clearData(context);
      },
    );
  }


  void _onRefresh() {
    setState(() {});
    context.read<GetVehicleDocumentCubit>().getUploadDocument(context: context);
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CustomAppBar(
          title: "",
          onBackTap: _previousStep,
        ),
        backgroundColor: whiteColor,
        body: MultiBlocListener(
          listeners: [
            BlocListener<RegisterProfileCubits, RegisterProfileState>(
              listener: (context, state) {
                if (state is RegisterLoading) {
                  Widgets.showLoader(context);
                } else if (state is RegisterSuccess) {
                  Widgets.hideLoder(context);
                  loginModel = state.loginModel;
                  context.read<RegisterProfileCubits>().resetState();
                  setState(() => activeStep++);
                } else if (state is RegisterFailure) {
                  Widgets.hideLoder(context);
                  showErrorToastMessage(state.error);
                }
              },
            ),
            BlocListener<LogoutCubit, LogoutState>(
              listener: (context, state) {
                if (state is LogoutFailure) {
                  showErrorToastMessage("Logout Failed: ${state.error}");
                } else if (state is LogoutSuccess) {
                  box.put('isDocumentStatusShown', false);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
            BlocListener<VehicleRegisterCubit, VehicleRegisterState>(
              listener: (context, state) {
                if (state is VehcileLoading) {
                  Widgets.showLoader(context);
                } else if (state is VehicleSuccess) {
                  Widgets.hideLoder(context);
                  context.read<VehicleRegisterCubit>().resetState();
                  setState(() => activeStep++);
                } else if (state is VehicleFailure) {
                  Widgets.hideLoder(context);
                  showErrorToastMessage(state.errorMsg);
                }
              },
            ),
          ],
          child: BlocBuilder<GetItemVehicleDataCubit, GetItemVehicleDataState>(
            builder: (context, state) {
              if (state is GetItemSuccess) {
                _setVehicleData(state.getItemVehicleModel.data?.items?.first);
                context.read<GetItemVehicleDataCubit>().clear();
              }
              return SmartRefresher(
                controller: refreshController,
                onRefresh: _onRefresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Required Information".translate(context),
                      style: headingBlack(context).copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 30),
                    Text("Welcome Driver".translate(context), style: headingBlack(context)),
                    const SizedBox(height: 5),
                    Text(
                      "Follow these steps".translate(context),
                      style: headingBlack(context).copyWith(fontSize: 14),
                    ),
                    EasyStepper(
                      activeStep: activeStep,
                      stepShape: StepShape.circle,
                      finishedStepBackgroundColor: Colors.transparent,
                      unreachedStepTextColor: notifires.getwhiteblackColor,
                      activeStepBorderColor: Colors.transparent,
                      activeStepTextColor: notifires.getwhiteblackColor,
                      lineStyle: LineStyle(
                        lineLength: 50,
                        unreachedLineColor: notifires.getGrey3whiteColor,
                        defaultLineColor: notifires.getGrey3whiteColor,
                        finishedLineColor: acentColor,
                        lineThickness: 1.5,
                      ),
                      finishedStepTextColor: notifires.getwhiteblackColor,
                      internalPadding: 20,
                      showLoadingAnimation: false,
                      showStepBorder: false,
                      steppingEnabled: true,
                      steps: List.generate(
                        stepWidgets.length,
                            (index) => _buildStep(
                          step: index,
                          title: stepTitles[index].translate(context),
                        ),
                      ),
                      onStepReached: _goToStep,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: stepWidgets[activeStep],
                    ),
                    const SizedBox(height: 50),
                    CustomsButtons(
                      textColor: blackColor,
                      text: activeStep == stepWidgets.length - 1
                          ? "Final".translate(context)
                          : "Next".translate(context),
                      backgroundColor: themeColor,
                      onPressed: _nextStep,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  EasyStep _buildStep({required int step, required String title}) {
    return EasyStep(
      customStep: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeStep == step
              ? blackColor
              : step < activeStep
              ? gradientColor
              : whiteColor,
          border: Border.all(
            color: activeStep == step
                ? blackColor
                : step < activeStep
                ? gradientColor
                : blackColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            (step + 1).toString(),
            style: headingBlack(context).copyWith(
              color: activeStep == step
                  ? whiteColor
                  : step < activeStep
                  ? whiteColor
                  : blackColor,
            ),
          ),
        ),
      ),
      title: title,
    );
  }

  void _setVehicleData(myItems) {
    final state = context.read<VehicleFormCubit>();
    state.textEditingVehicleBrandController.text = myItems.vehicleMake?.toString() ?? "";
    state.textEditingVehicleColorController.text = myItems.vehicleColor ?? "Black";
    state.textEditingVehicleNumberController.text = myItems.vehicleNumber?.toString() ?? "";
    state.textEditingVehicleModelController.text = myItems.vehicleModel?.toString() ?? "";
    state.updateVehicleTypeId(myItems.itemTypeId?.toString() ?? "");
    context.read<CheckUpdatedDocumentImage>().checkUpdatedDocumentImage(true);
    context.read<CheckUpdatedLicenceImage>().checkUpdatedLicenceImage(true);
    context.read<CheckUpdatedImage>().checkUpdatedImage(true);
    context.read<SetVehicleImage>().setImage(myItems.frontImage?.url ?? "");
    context.read<SetDocImage>().setImage(myItems.frontImageDoc?.url ?? "");
    context.read<SetInsuranceImage>().setImage(myItems.itemInsuranceDoc?.url ?? "");
    context.read<UpdateDriverParameterCubit>().updateVehicleTypeName(
      vehcileTypeName: myItems.vehicleType?.toString() ?? "",
    );
    context.read<UpdateDriverParameterCubit>().updateVehicleTypeId(
      vehicleTypeId: myItems.itemTypeId?.toString() ?? "",
    );
    state.updateVehicleColor(myItems.vehicleColor ?? "Black");
    state.updateVehicleModel(myItems.vehicleModel?.toString() ?? "");
    state.updateVehicleMake(myItems.vehicleMake?.toString() ?? "");
    state.updateVehicleYear(myItems.vehicleYear ?? "2025");
    state.updateVehicleNumber(myItems.vehicleNumber?.toString() ?? "");
    context.read<UpdateDocImage>().removeImage();
    context.read<UpdateLicenceImage>().removeImage();
    context.read<UpdateImage>().removeImage();

    initialVehicleData = {
      'vehicleTypeId': myItems.itemTypeId?.toString() ?? "",
      'vehicleMake': myItems.vehicleMake?.toString() ?? "",
      'vehicleModel': myItems.vehicleModel?.toString() ?? "",
      'vehicleNumber': myItems.vehicleNumber?.toString() ?? "",
      'vehicleYear': myItems.vehicleYear ?? "2025",
      'vehicleColor': myItems.vehicleColor ?? "Black",
      'vehicleBase64Image': myItems.frontImage?.url ?? "",
      'vehicleDocBase64Image': myItems.frontImageDoc?.url ?? "",
      'vehicleLicenceBase64Image': myItems.itemInsuranceDoc?.url ?? "",
    };
  }
}