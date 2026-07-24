import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/login.dart' as logmod;
import '../../cubits/account/update_profile_cubit.dart';
import '../../cubits/auth/email_otp_cubit.dart';
import '../../cubits/auth/otp_verify_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../widgets/custom_dropdown_widget.dart';
import '../../widgets/custom_text_form_field.dart';
import '../Auth/email_update_screen.dart';
import '../Auth/phone_update_screen.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? image;
  final picker = ImagePicker();
  GlobalKey buttonKey = GlobalKey();

  TextEditingController textEditingEditProfileNameController =
      TextEditingController();
  TextEditingController textEditingEditProfileEmailController =
      TextEditingController();
  TextEditingController textEditingEditProfileNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (loginModel!.data != null && loginModel!.data!.gender != null) {
      final gender = loginModel!.data!.gender;
      context.read<GenderCubit>().genderUpdate(gender: gender);
    }
    textEditingEditProfileNameController.text = loginModel?.data?.firstName ?? "";
    textEditingEditProfileNumberController.text = loginModel?.data?.phone ?? "";
    textEditingEditProfileEmailController.text = loginModel?.data?.email ?? "";
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final base64Img = await compressAndUploadImage(pickedFile.path);
      setState(() {
        image = File(pickedFile.path);
      });
      // ignore: use_build_context_synchronously
      context.read<UpdateProfileCubit>().uploadProfileImage(postData: {
        "profile_image": base64Img,
      });
    }
  }

  List<String> optionsList = ["Male", "Female", "Others"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(
        title: "Edit Profile",
        onBackTap: () {
          goBack();
        },
      ),
      body: BlocBuilder<UpdateProfileCubit, UpdateProfileState>(
          builder: (context, state) {
        if (state is UpdateProfileLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Widgets.showLoader(context);
          });
        } else if (state is UpdateProfileSuccess) {
          Widgets.hideLoder(context);
          loginModel = logmod.LoginModel(
              data: logmod.Data.fromJson(state.loginModel.data!.toJson()));
          loginModel = loginModel;
          UserData userObj = UserData();
          userObj.saveLoginData("UserData", jsonEncode(loginModel!.toJson()));
          context.read<UpdateProfileCubit>().clear();
          context
              .read<NameCubit>()
              .updateName("${state.loginModel.data!.firstName}");

          showToastMessage(state.loginModel.message ?? "");
        } else if (state is UpdateProfileImageSuccess) {
          Widgets.hideLoder(context);

          loginModel!.data!.profileImageSetter = state.imageUrl;
          myImage = state.imageUrl;
          context.read<MyImageCubit>().updateMyImage(myImage);
          context.read<UpdateDriverCubit>().updateFirebaseImageUrl(
              driverImageUrl: state.imageUrl,
              driverId:
                  context.read<UpdateDriverParameterCubit>().state.driverId);

          UserData userObj = UserData();
          userObj.saveLoginData("UserData", jsonEncode(loginModel!.toJson()));
        } else if (state is UpdateProfileFailed) {
          Widgets.hideLoder(context);

          showErrorToastMessage(state.error);
          context.read<UpdateProfileCubit>().clear();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        myImage.isNotEmpty
                            ? Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(child: myNetworkImage(myImage)),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: grey6,
                                ),
                                child: Icon(
                                  CupertinoIcons.profile_circled,
                                  size: 110,
                                  color: themeColor,
                                ),
                              ),
                        GestureDetector(
                          key: buttonKey,
                          onTap: () {
                            getButtonPosition(buttonKey);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: blackColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    TextFieldAdvance(
                        icons: Icon(Icons.person_2_outlined,
                            color: notifires.getGrey2whiteColor),
                        txt: "Enter Your Name".translate(context),
                        textEditingControllerCommon:
                            textEditingEditProfileNameController,
                        inputType: TextInputType.name,
                        inputAlignment: TextAlign.start),
                    const SizedBox(height: 20),
                    BlocBuilder<EmailOtpCubit, EmailOtpState>(
                        builder: (context, state) {
                      if (state is OtpSuccessForChangeEmailSate) {
                        textEditingEditProfileEmailController.text =
                            state.loginModel.data?.email ?? "";
                        context
                            .read<EmailCubit>()
                            .updateEmail(state.loginModel.data?.email ?? "");
                      }
                      return Stack(
                        children: [
                          TextFieldAdvance(
                              icons: Icon(Icons.email_outlined,
                                  color: notifires.getGrey2whiteColor),
                              txt: "Enter Your Email".translate(context),
                              readOnly: true,
                              textEditingControllerCommon:
                                  textEditingEditProfileEmailController,
                              inputType: TextInputType.name,
                              inputAlignment: TextAlign.start),
                          Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              left: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        goTo(const EmailUpdateScreen());
                                      },
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                              color: themeColor.withValues(alpha: .7),
                                              height: 30,
                                              width: 30,
                                              child:   Icon(
                                                Icons.mode,
                                                color: whiteColor,
                                                size: 17,
                                              )),
                                        ),
                                      )),
                                ],
                              ))
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    BlocBuilder<AuthOtpVerifyCubit, OtpVerifyState>(
                        builder: (context, state) {
                          if (state is OtpSuccessForChangePhoneSate) {
                            textEditingEditProfileNumberController.text =
                                state.loginModel.data?.phone ?? "";
                            context
                                .read<PhoneCubit>()
                                .updatePhone(state.loginModel.data?.phone ?? "");
                            context.read<AuthOtpVerifyCubit>().resetState();
                          }
                        return Stack(
                          children: [
                            TextFieldAdvance(
                                icons: Icon(Icons.call_outlined,
                                    color: notifires.getGrey2whiteColor),
                                txt: "Enter Your Mobile".translate(context),
                                readOnly: true,
                                textEditingControllerCommon:
                                    textEditingEditProfileNumberController,
                                inputType: TextInputType.name,
                                inputAlignment: TextAlign.start),
                            Positioned(
                                right: 10,
                                top: 0,
                                bottom: 0,
                                left: 10,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                        onTap: () {
                                          context.read<SetCountryCubit>().setCountry(dialCode: loginModel?.data?.phoneCountry??"+1", countryCode: loginModel?.data?.defaultCountry??"US");

                                          goTo(PhoneUpdateScreen(
                                              phone:
                                                  textEditingEditProfileNumberController
                                                      .text));
                                        },
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                                color: themeColor.withValues(alpha: .7),
                                                height: 30,
                                                width: 30,
                                                child:   Icon(
                                                  Icons.mode,
                                                  color: whiteColor,
                                                  size: 17,
                                                )),
                                          ),
                                        )),
                                  ],
                                ))
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<GenderCubit, String>(
                        builder: (context, gender) {
                          return CustomDropdown(
                            selectedEditInitialValue: gender.translate(context),
                            prefixIconColor: blackColor,
                            textStyle: regularBlack(context).copyWith(fontSize: 16),
                            prefixIconImage: "assets/images/gender-icon.png",
                            options: optionsList,
                            onSelected: (value) {
                              loginModel!.data!.gender = value;
                            },
                            hintText: "Gender".translate(context),
                            checkmarkColor: acentColor,
                          );
                        })
                  ],
                ),
              ),
            ),
            CustomsButtons(
                textColor: blackColor,
                text: "Update Profile".translate(context),
                backgroundColor: themeColor,
                onPressed: () {
                  if (loginModel!.data!.gender == null) {
                    showErrorToastMessage("Please select gender");
                    return;
                  }
                  context
                      .read<UpdateProfileCubit>()
                      .updateProfileMethod(postData: {
                    "gender": loginModel!.data!.gender!,
                    "first_name": textEditingEditProfileNameController.text,
                  });
                }),
            const SizedBox(
              height: 50,
            )
          ]),
        );
      }),
    );
  }

  void showImagePickerPopup(BuildContext context, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + 10, offset.dy + 10),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: themeColor),
              const SizedBox(width: 10),
              Text("Camera".translate(context)),
            ],
          ),
          onTap: () {
            pickImage(ImageSource.camera);
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.photo, color: themeColor),
              const SizedBox(width: 10),
              Text("Gallery".translate(context)),
            ],
          ),
          onTap: () {
            pickImage(ImageSource.gallery);
          },
        ),
      ],
      elevation: 10,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  void getButtonPosition(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    showImagePickerPopup(context, offset);
  }
}
