import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/login.dart';
import '../../cubits/auth/signup_cubit.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';
import '../../widgets/custom_dropdown_widget.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/form_validations.dart';

class Profile extends StatefulWidget {
  const Profile({
    super.key,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    if (box.get("UserData") != null) {
      String data = box.get("UserData");

      if (data.isNotEmpty) {
        try {
          selectedCountry = "";
          var json = jsonDecode(data);
          loginModel = LoginModel.fromJson(json);
          if (loginModel != null && loginModel?.data != null) {
            if (loginModel?.data?.email != null) {
              textEditingEditProfileEmailController.text =
                  loginModel!.data!.email!.toString();
            }
            if (loginModel?.data?.firstName != null) {
              textEditingEditProfileNameController.text =
                  loginModel!.data!.firstName!.toString();
            }
            if (loginModel?.data?.gender != null) {
              textEditingEditProfileNameController.text =
                  loginModel!.data!.firstName!.toString();
            } if (loginModel?.data?.itemId != null) {

              context
                  .read<UpdateAddEditVehicleIdCubit>().updateItemId(vehicleAddEditTypeId: loginModel?.data?.itemId??0);

            }
            if (loginModel?.data?.phone != null &&
                loginModel?.data?.phoneCountry != null) {
              selectedCountry = loginModel!.data!.phoneCountry!;
              textEditingEditProfileNumberController.text =
                  "$selectedCountry ${loginModel!.data!.phone!}";
            }
          }
        } catch (err) {
          // print(err);
        }
      }
    }
  }

  TextEditingController textEditingEditProfileNameController =
      TextEditingController();

  TextEditingController textEditingEditProfileEmailController =
      TextEditingController();

  TextEditingController textEditingEditProfileNumberController =
      TextEditingController();

  TextEditingController textEditingEditProfileGenderController =
      TextEditingController();

  List<String> optionsList = ["Male", "Female", "Others"];

  String selectedCountry = "";

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: BlocBuilder<AuthSignUpCubit, AuthSignUpState>(
            builder: (context, state) {
          if (state is SignUpSuccess) {
            if (state.loginModel.data != null) {
              selectedCountry = "";
              textEditingEditProfileNameController.text =
                  state.loginModel.data!.firstName!;
              textEditingEditProfileEmailController.text =
                  state.loginModel.data!.email!;
              selectedCountry = state.loginModel.data!.phoneCountry!;
              textEditingEditProfileNumberController.text =
                  "$selectedCountry ${state.loginModel.data!.phone!}";
            }
          }

          return Column(children: [
            TextFieldAdvance(
                icons: Icon(Icons.person_2_outlined,
                    color: notifires.getGrey3whiteColor),
                txt: "Name".translate(context),
                hintStyle: regular(context),
                validator: (value) {
                  if (isValidName(value!)) {
                    return null;
                  } else {
                    return "Name is invalid".translate(context);
                  }
                },
                onChange: (value) {
                  loginModel!.data!.firstNameSetter = value;
                  return null;
                },
                textEditingControllerCommon:
                    textEditingEditProfileNameController,
                inputType: TextInputType.name,
                inputAlignment: TextAlign.start),
            const SizedBox(height: 20),
            AbsorbPointer(
              absorbing: true,
              child: TextFieldAdvance(
                  icons: Icon(Icons.email_outlined,
                      color: notifires.getGrey3whiteColor),
                  txt: "Email".translate(context),
                  hintStyle: regular(context),
                  textEditingControllerCommon:
                      textEditingEditProfileEmailController,
                  inputType: TextInputType.name,
                  validator: (value) {
                    return validateEmail(value!, context);
                  },
                  inputAlignment: TextAlign.start),
            ),
            const SizedBox(height: 20),
            AbsorbPointer(
              absorbing: true,
              child: TextFieldAdvance(
                  icons: Icon(Icons.call_outlined,
                      color: notifires.getGrey3whiteColor),
                  txt: "Phone".translate(context),
                  hintStyle: regular(context),
                  textEditingControllerCommon:
                      textEditingEditProfileNumberController,
                  inputType: TextInputType.name,
                  inputAlignment: TextAlign.start),
            ),
            const SizedBox(height: 20),
            CustomDropdown(
              textStyle: regularBlack(context).copyWith(fontSize: 16),
              prefixIconImage: "assets/images/gender-icon.png",
              options: optionsList,
              onSelected: (value) {
                loginModel!.data!.gender = value;
              },
              selectedEditInitialValue: loginModel?.data?.gender ?? "",
              hintText: "Gender".translate(context),
              checkmarkColor: acentColor,
            ),
          ]);
        }));
  }
}
