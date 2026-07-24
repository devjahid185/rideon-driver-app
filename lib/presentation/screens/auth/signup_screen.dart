import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/onboarding/language_select_screen.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/signup_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/form_validations.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController textEditingSignUpControllerName =
      TextEditingController();
  TextEditingController textEditingSignUpControllerEmail =
      TextEditingController();

  TextEditingController textEditingSingUpControllerPhoneNumber =
      TextEditingController();
  TextEditingController textEditingSignUpControllerPassword =
      TextEditingController();

  bool isChecked = false;

  @override
  void initState() {


    isNumeric = false;
    context.read<SetCountryCubit>().reset();
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (v) async {},
      child: Scaffold(
          resizeToAvoidBottomInset: isNumeric,
          bottomSheet: isNumeric == true && Platform.isIOS
              ? KeyboardDoneButton(
                  onTap: () {
                    setState(() {
                      isNumeric = false;
                    });
                  },
                )
              : null,
          backgroundColor: notifires.getbgcolor,
          body: MultiBlocListener(
              listeners: [
                BlocListener<AuthSignUpCubit, AuthSignUpState>(
                    listener: (context, state) {
                  if (state is SignUpLoading) {
                    Widgets.showLoader(context);
                  } else if (state is SignUpSuccess) {
                    context.read<UpdateDriverParameterCubit>().updateDriverId(
                        driverId:
                            state.loginModel.data!.fireStoreId!.toString());
                    Widgets.hideLoder(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OtpScreen(
                                  number: state.loginModel.data!.phone,
                                  countryCode:
                                      state.loginModel.data!.phoneCountry,
                                  otpValue: state.loginModel.data!.otpValue,
                                  email: "",
                                  defaultCountry:
                                      state.loginModel.data!.defaultCountry,
                                  changeMobile: false,
                                  loginWithSocialMedia: false,
                                  routeString: "SignUp",
                                )));
                  } else if (state is SignUpFailure) {
                    Widgets.hideLoder(context);
                    showErrorToastMessage(state.error);
                  }
                })
              ],
              child: Stack(
                children: [
                  Positioned(
                      left: 0,
                      top: 0,
                      child: SvgPicture.asset(
                        "assets/images/EllipseTop.svg",
                      )),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: Dimensions.containerWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeLarge,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 150),
                                  commonlyUserLogo(),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Sign Up".translate(context),
                                      style: heading1(context)),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFieldAdvance(
                                    onTap: () {
                                      setState(() {
                                        isNumeric = false;
                                      });
                                    },
                                    inputAlignment: TextAlign.start,
                                    txt: "Name".translate(context),
                                    icons: Icon(
                                      Icons.person_2_outlined,
                                      color: blackColor,
                                    ),
                                    textEditingControllerCommon:
                                        textEditingSignUpControllerName,
                                    inputType: TextInputType.name,
                                    validator: (value) {
                                      if (isValidName(value!)) {
                                        return null;
                                      } else {
                                        return "Name is invalid"
                                            .translate(context);
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BlocBuilder<SetCountryCubit, SetCountryState>(
                                      builder: (context, state) {
                                    return IntelPhoneFieldRefs(
                                      onTap: (){
                                        setState(() {
                                          isNumeric=true;
                                        });
                                      },
                                      key: ValueKey(state.countryCode),
                                      defultcountry: state.countryCode,
                                      textEditingControllerCommons:
                                          textEditingSingUpControllerPhoneNumber,
                                      oncountryChanged: (number) {
                                        context.read<SetCountryCubit>().reset();
                                        textEditingSingUpControllerPhoneNumber
                                            .clear();
                                       context
                                            .read<SetCountryCubit>()
                                            .setCountry(
                                                dialCode: "+${number.dialCode}",
                                                countryCode: number.code);
                                      },
                                      onChanged: (number) {
                                        return null;
                                      },
                                      validator: (phoneNumber) {
                                        if (phoneNumber == null ||
                                            phoneNumber.number.isEmpty) {
                                          return "Please enter your phone number"
                                              .translate(context);
                                        }
                                        int expectedLength = phoneLengths[
                                                phoneNumber.countryISOCode] ??
                                            10;
                                        if (phoneNumber.number.length !=
                                            expectedLength) {
                                          return "${"Phone number must be"} $expectedLength ${"digits"}";
                                        }
                                        return null;
                                      },
                                    );
                                  }),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFieldAdvance(
                                    onTap: () {
                                      setState(() {
                                        isNumeric = false;
                                      });
                                    },
                                    inputAlignment: TextAlign.start,
                                    txt: "Email".translate(context),
                                    icons: Icon(
                                      Icons.mail_outline_outlined,
                                      color: blackColor,
                                    ),
                                    textEditingControllerCommon:
                                        textEditingSignUpControllerEmail,
                                    inputType: TextInputType.emailAddress,
                                    validator: (value) {
                                      return validateEmail(value!, context);
                                    },
                                  ),
                                  const SizedBox(height: 35),
                                  CustomsButtons(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          if (textEditingSingUpControllerPhoneNumber
                                              .text.isEmpty) {
                                            showErrorToastMessage(
                                                "Fill valid mobile number"
                                                    .translate(context));
                                          }
                                          context
                                              .read<AuthSignUpCubit>()
                                              .signUp(
                                                context: context,
                                                name:
                                                    textEditingSignUpControllerName
                                                        .text,
                                                phoneCountry: context
                                                        .read<SetCountryCubit>()
                                                        .state
                                                        .dialCode
                                                        .startsWith("+")
                                                    ? context
                                                        .read<SetCountryCubit>()
                                                        .state
                                                        .dialCode
                                                    : "+${context.read<SetCountryCubit>().state.dialCode}",
                                                defaultCountry: context
                                                    .read<SetCountryCubit>()
                                                    .state
                                                    .countryCode,
                                                phoneNumber:
                                                    textEditingSingUpControllerPhoneNumber
                                                        .text,
                                                email:
                                                    textEditingSignUpControllerEmail
                                                        .text,
                                              );
                                        }
                                      },
                                      textColor: blackColor,
                                      text: "Sign Up",
                                      backgroundColor: themeColor),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account?".translate(context),
                                        style: regular3(context)
                                            .copyWith(color: notifires.getGrey2whiteColor),
                                      ),
                                      const SizedBox(width: 5),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => const LoginScreen()));
                                        },
                                        child: Text(
                                          "Sign in".translate(context),
                                          style: heading1(context).copyWith(
                                            color: blackColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  const SizedBox(height: 300)
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
Positioned(
                  top: 70,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      languageButton(onTap: (){

                        goTo(const SelectLanguageScreen(isBack: true,));
                      },),
                    ],
                  )),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: IgnorePointer(
                      child: SvgPicture.asset(
                        "assets/images/vector_bottom.svg",
                        colorFilter:
                            ColorFilter.mode(themeColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }
}
