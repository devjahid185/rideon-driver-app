import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/document_image.dart';
import '../../cubits/auth/otp_verify_cubit.dart';
import '../../cubits/auth/resend_otp_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/register_vehicle_document.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../bottom_bar/home_main.dart';
import '../setup_account/setup_initial_screen.dart';

// ignore: must_be_immutable
class OtpScreen extends StatefulWidget {
  final String? number;
  final String? countryCode;
  String? otpValue;
  final String? email;
  final bool? changeMobile;
  final bool? changeEmail;
  final String? defaultCountry;
  final String? routeString;
  bool? loginWithSocialMedia;

  OtpScreen(
      {super.key,
      this.number,
      this.routeString,
      this.countryCode,
      this.otpValue,
      this.email,
      this.changeMobile,
      this.changeEmail,
      this.defaultCountry,
      this.loginWithSocialMedia});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isNumeric=false;
    WidgetsBinding.instance.addPostFrameCallback((_) {});

    Future.delayed(
      const Duration(seconds: 1),
      () {
        textEditingOtpController.text = widget.otpValue!;
      },
    );
    startResendTimer();
  }

  int _remainingTime = 30;
  bool _isResendEnabled = true;
  late Timer _timer;

  void startResendTimer() {
    setState(() {
      _isResendEnabled = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          _isResendEnabled = true;
          _remainingTime = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  TextEditingController textEditingOtpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: Dimensions.containerWidth,
        child: Scaffold(
            bottomSheet: isNumeric==true&& Platform.isIOS?KeyboardDoneButton(
              onTap: () {
                setState(() {
                  isNumeric = false;
                });
              },
            ):null,
            resizeToAvoidBottomInset: isNumeric,
            backgroundColor: notifires.getbgcolor,
            body: MultiBlocListener(
                listeners: [
                  BlocListener<AuthUserAuthenticateCubit,
                      AuthUserAuthenticateState>(listener: (context, state) {
                    if (state is UserLoading) {
                      Widgets.showLoader(context);
                    } else if (state is UserSucesss) {
                      Widgets.hideLoder(context);

                      if (state.loginModel.data != null) {
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateDriverNameAndNumber(
                                driverName:
                                    state.loginModel.data!.firstName ?? "",
                                driverNumber:
                                    state.loginModel.data!.phone ?? "",
                                driverPhoneCountryCode:
                                    state.loginModel.data!.phoneCountry ?? "");

                        context
                            .read<UpdateAddEditVehicleIdCubit>()
                            .updateItemId(
                                vehicleAddEditTypeId:
                                    loginModel?.data?.itemId??0);
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateDriverId(
                                driverId: state.loginModel.data!.fireStoreId
                                        ?.toString() ??
                                    "");
                      }

                      navigatorKey.currentContext!
                          .read<DocumentApprovedStatusCubit>()
                          .removeDocumentApprovedStatus();

                      context
                          .read<DocumentApprovedStatusCubit>()
                          .updateDocumentApprovedStatus(
                              docApprovedStatus: state.loginModel.data!
                                      .verificationDocumentStatus ??
                                  "");
                      final loginDocStatusRaw = state
                              .loginModel.data!.verificationDocumentStatus ??
                          "";
                      final loginDocStatusNormalized =
                          loginDocStatusRaw.trim().toLowerCase();
                      debugPrint(
                          "[DocDebug] OTP login response | verification_document_status(raw)=$loginDocStatusRaw | normalized=$loginDocStatusNormalized");

                      context.read<AuthUserAuthenticateCubit>().resetState();

                      if (widget.routeString == "Login") {
                        context.read<SetupStepCubit>().resetStep();
                        DocumentImageModel? documentImageModel;

                        final docStatus =
                            context.read<GetVehicleDocumentCubit>().state;
                        if (docStatus is GetDocumentSuccess) {
                          documentImageModel = docStatus.documentImageModel;
                        }

                        if (state.loginModel.data!.gender != null &&
                            state.loginModel.data!.gender!.isNotEmpty) {
                          if (state.loginModel.data!.itemTypeId != null) {
                            if (documentImageModel?.data
                                            ?.drivingLicenceFront?.drivingLicenceImage !=
                                        null &&
                                    documentImageModel?.data?.inspectionCertificate!
                                            .inspectionCertificateImage !=
                                        null &&
                                    documentImageModel
                                            ?.data
                                            ?.driverAuthorization!
                                            .driverAuthorizationImage !=
                                        null &&
                                    documentImageModel
                                            ?.data
                                            ?.hireServiceLicence!
                                            .hireServiceLicenceImage !=
                                        null ||
                                ((state.loginModel.data!
                                                .verificationDocumentStatus ??
                                            "")
                                        .trim()
                                        .toLowerCase() ==
                                    "approved")) {
                              setState(() {});
                              box.put("driverId",
                                  state.loginModel.data?.fireStoreId ?? "");
                              goToWithClear(HomeMain(
                                  initialIndex: 0, route: widget.routeString));
                            } else {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SetupInitialScreen(
                                              stepIndex: 2)));
                            }
                          } else {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SetupInitialScreen(
                                            stepIndex: 1)));
                          }
                        } else {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SetupInitialScreen(stepIndex: 0)));
                        }
                      }
                    } else if (state is UserFailure) {
                      Widgets.hideLoder(context);
                      if (state.error.isNotEmpty) {
                        showErrorToastMessage(state.error);
                      }
                    }
                  }),
                  BlocListener<AuthOtpVerifyCubit, OtpVerifyState>(
                      listener: (context, state) {
                    if (state is OtpLoading) {
                      Widgets.showLoader(context);
                    } else if (state is OtpSuccess) {
                      Widgets.hideLoder(context);
                      context
                          .read<GetVehicleDocumentCubit>()
                          .getUploadDocument(context: context);

                      context.read<UpdateDriverParameterCubit>().updateDriverId(
                          driverId:
                              state.loginModel.data?.fireStoreId?.toString() ??
                                  "");

                      if (state.loginModel.data != null &&
                          state.loginModel.data?.itemId != null) {
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateDriverNameAndNumber(
                                driverName:
                                    state.loginModel.data!.firstName ?? "",
                                driverNumber:
                                    state.loginModel.data!.phone ?? "",
                                driverPhoneCountryCode:
                                    state.loginModel.data!.phoneCountry ?? "");
                        context
                            .read<UpdateAddEditVehicleIdCubit>()
                            .updateItemId(
                                vehicleAddEditTypeId:
                                    loginModel!.data!.itemId!);
                      }

                      if (widget.routeString == "SignUp") {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SetupInitialScreen(
                                      stepIndex: 0,
                                    )));
                      }
                    } else if (state is OtpSuccessForChangePhoneSate) {
                      Widgets.hideLoder(context);
                      if (widget.loginWithSocialMedia == true) {
                        loginModel = state.loginModel;
                        box.put(
                            "driverId", loginModel?.data?.fireStoreId ?? "");
                        showToastMessage(loginModel?.message ?? "");
                        goToWithClear(const HomeMain(initialIndex: 0));
                        box.put('Remember', true);
                        box.put('Firstuser', true);
                      } else {
                        goBack();
                        loginModel = state.loginModel;
                        showToastMessage(loginModel?.message ?? "");
                      }
                    } else if (state is OtpFailure) {
                      Widgets.hideLoder(context);
                      if (state.error.isNotEmpty) {
                        showErrorToastMessage(state.error);
                      }
                    }
                  }),
                  BlocListener<AuthResendOtpCubit, ResendOtpState>(
                      listener: (context, state) {
                    if (state is ResendOtpLoading) {
                      Widgets.showLoader(context);
                    } else if (state is ResendOtpSuccess) {
                      Widgets.hideLoder(context);
                      if (state.otpValue!.isNotEmpty) {
                        textEditingOtpController.text = state.otpValue!;
                        widget.otpValue = state.otpValue;
                      }
                    } else if (state is ResendOtpFailure) {
                      Widgets.hideLoder(context);
                      showErrorToastMessage(state.error);
                    }
                  }),
                  BlocListener<GetVehicleDocumentCubit,
                      GetVehicleDocumentState>(listener: (context, state) {
                    if (state is GetDocumentSuccess) {
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
                      } else if (statusList.contains("rejected")) {
                        context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "rejected");
                        box.put("approved", false);
                      } else {
                        context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "pending");
                        context.read<UpdateDriverParameterCubit>().updateDocApprovedStatus(docApprovedStatus: "pending");
                        box.put("approved", false);
                      }
                    }
                  }),
                ],
                child: Stack(
                  children: [
                    Positioned(
                        right: 0,
                        top: 0,
                        child: SvgPicture.asset("assets/images/vector_top.svg",
                            colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn))),
                    Positioned(
                      bottom: -10,
                      left: 0,
                      child: IgnorePointer(
                        child: SvgPicture.asset(
                          "assets/images/vector_bottom.svg",
                          colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 10,
                      top: 0,
                      right: 0,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeLarge,
                              vertical: Dimensions.paddingSizeExtraLarge),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 120,
                                ),
                                SizedBox(
                                  height: 170,
                                  child: Image.asset(
                                      "assets/images/verification.png"),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text("Verification".translate(context), style: heading1(context)),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                    "Verification code was sent to your Phone number"
                                        .translate(context),
                                    style: regular(context)),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text("${widget.countryCode} ${widget.number}",
                                    style: regular3(context)
                                        .copyWith(fontWeight: FontWeight.w100)),
                                const SizedBox(height: 20),
                                _isResendEnabled
                                    ? SizedBox(
                                        height: 22,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                "Didn't receive code?"
                                                    .translate(context),
                                                style: regular3(context).copyWith(
                                                    color: notifires
                                                        .getGrey2whiteColor)),
                                            const SizedBox(width: 5),
                                            InkWell(
                                              onTap: () async {
                                                startResendTimer();
                                                setState(() {
                                                  _remainingTime = 30;
                                                  _isResendEnabled = false;
                                                });
                                                context
                                                    .read<AuthResendOtpCubit>()
                                                    .resendOtp(
                                                      context: context,
                                                      phone: widget.number,
                                                      phoneCountry: widget
                                                              .countryCode!
                                                              .startsWith("+")
                                                          ? widget.countryCode!
                                                          : "+${widget.countryCode!}",
                                                    );
                                              },
                                              child: Text(
                                                  "Resend".translate(context),
                                                  style: regular2(context)
                                                      .copyWith(
                                                          color: blackColor,
                                                          fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox(
                                        height: 22,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Resend code in"
                                                  .translate(context),
                                              style: regular3(context).copyWith(
                                                  color: notifires
                                                      .getGrey2whiteColor),
                                            ),
                                            const SizedBox(width: 5,),
                                            Text('00:$_remainingTime',
                                                style:
                                                    regular2(context).copyWith(
                                                  color: blackColor,
                                                  fontSize: 16,
                                                ))
                                          ],
                                        ),
                                      ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  onTap: () {
                                    setState(() {
                                      isNumeric = true;
                                    });
                                  },
                                  style: regular3(context).copyWith(
                                    fontSize: 20,
                                    color: notifires.getGrey2whiteColor,
                                  ),
                                  controller: textEditingOtpController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {},
                                  textDirection: TextDirection.ltr,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: notifires.getBoxColor,
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      borderSide: BorderSide(color: notifires.getGrey6whiteColor),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      borderSide: BorderSide(color: notifires.getGrey6whiteColor),
                                    ),
                                    hintText: "Enter OTP".translate(context),
                                    hintStyle: regular(context),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: notifires.getGrey6whiteColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: notifires.getGrey6whiteColor),
                                    ),
                                  ),
                                )
,
                                const SizedBox(height: 10),
                                const SizedBox(
                                  height: 40,
                                ),
                                CustomsButtons(
                                    textColor: blackColor,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (textEditingOtpController
                                            .text.isEmpty) {
                                          showErrorToastMessage(
                                              "Please Enter the Otp"
                                                  .translate(context));
                                          return;
                                        }
                                        if (widget.changeMobile == true) {
                                          context
                                              .read<AuthOtpVerifyCubit>()
                                              .otpVerificationForChangePhone({
                                            "phone": widget.number,
                                            "phone_country": widget.countryCode!
                                                    .startsWith('+')
                                                ? widget.countryCode!
                                                : '+${widget.countryCode!}',
                                            "otp_value":
                                                textEditingOtpController.text,
                                            "default_country":
                                                widget.defaultCountry,
                                          }, context);
                                          return;
                                        }

                                        if (widget.routeString == "Login") {
                                          context
                                              .read<AuthUserAuthenticateCubit>()
                                              .userAuthenticate(
                                                  context: context,
                                                  phoneNumber: widget.number!,
                                                  phoneCountry: widget
                                                          .countryCode!
                                                          .startsWith("+")
                                                      ? widget.countryCode!
                                                      : "+${widget.countryCode!}",
                                                  otpValue:
                                                      textEditingOtpController
                                                          .text);
                                        } else {
                                          context
                                              .read<AuthOtpVerifyCubit>()
                                              .otpVerification(
                                                  context: context,
                                                  phone: widget.number,
                                                  otpValue:
                                                      textEditingOtpController
                                                          .text,
                                                  countryCode: widget
                                                          .countryCode!
                                                          .startsWith("+")
                                                      ? widget.countryCode!
                                                      : "+${widget.countryCode!}",
                                                  email: widget.email,
                                                  changeEmail:
                                                      widget.changeEmail,
                                                  changeMobile:
                                                      widget.changeMobile,
                                                  defaultCountry:
                                                      widget.defaultCountry,
                                                  loginWithGoogle: widget
                                                      .loginWithSocialMedia);
                                        }
                                      }
                                    },
                                    text: "Continue",
                                    backgroundColor: themeColor),
                                const SizedBox(
                                  height: 40,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Try again".translate(context),
                                      style: regular3(context).copyWith(
                                          color: notifires.getGrey2whiteColor),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    InkWell(
                                        onTap: () {
                                          goBack();
                                        },
                                        child: Text(
                                          "Go Back".translate(context),
                                          style: boldstyle(context)
                                              .copyWith(color: blackColor),
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 300,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ))),
      ),
    );
  }
}
