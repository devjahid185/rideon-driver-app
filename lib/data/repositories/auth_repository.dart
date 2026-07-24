import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/workspace.dart';
import '../../core/services/config.dart';
import '../../core/services/http.dart';
import '../../presentation/cubits/auth/user_authenticate_cubit.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(
      {required String phoneNumber,
      required String phoneCountry,
      required BuildContext context}) async {
    if (!phoneCountry.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    try {
      final data = {
        "phone": phoneNumber,
        "phone_country": phoneCountry,
      };
      var response =
          await httpPost(Config.sendMobileLoginOtp, data, context: context);
      debugPrint(
          "[DocDebug][API] sendMobileLoginOtp | status=${response["status"]} | message=${response["message"] ?? response["error"] ?? ""}");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forChangeEmail({
    otp,
    email,
  }) async {
    try {
      var response = await httpPost(
          Config.changeEmail, {"email": email, "otp_value": otp},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> userAuthenticateLogin(
      {required BuildContext context,
      required String phoneNumber,
      required String phoneCountry,
      required String otpValue}) async {
    if (!phoneCountry.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    try {
      var response = await httpPost(
          Config.userMobileLogin,
          {
            "phone": phoneNumber,
            "phone_country": phoneCountry,
            "otp_value": otpValue,
          },
          context: context);
      final rawDocStatus = response["data"]?["verification_document_status"];
      final dynamic dataObj = response["data"];
      final dataKeys = dataObj is Map ? dataObj.keys.toList() : [];
      final firestoreId = dataObj is Map
          ? (dataObj["firestore_id"] ??
              dataObj["fire_store_id"] ??
              dataObj["fireStoreId"] ??
              dataObj["driver_firestore_id"])
          : null;
      debugPrint(
          "[DocDebug][API] userMobileLogin | status=${response["status"]} | verification_document_status=$rawDocStatus | firestoreId=$firestoreId | dataKeys=$dataKeys | fullMessage=${response["message"] ?? response["error"] ?? ""}");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signUp(
      {required BuildContext context,
      String? name,
      String? phoneNumber,
      String? email,
      String? phoneCountry,
      String? defaultCountry}) async {
    if (!phoneCountry!.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    final response = await httpPost(
        Config.registerUser,
        {
          'phone': phoneNumber,
          'email': email,
          "phone_country": phoneCountry,
          "default_country": defaultCountry,
          "first_name": name
        },
        context: context);
    return response;
  }

  Future<Map<String, dynamic>> resendOtp({
    required BuildContext context,
    String? phone,
    String? phoneCountry,

  }) async {
    if (!phoneCountry!.startsWith("+")) {
      phoneCountry = '+$phoneCountry';
    }
    try {


       var   response = await httpPost(
          context: context,
          Config.resendOtp,
          {"phone": phone, "phone_country": phoneCountry});

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePhone({String? phone}) async {

    try {
      var data = {
        "phone": phone,
        "phone_country": navigatorKey.currentContext!
            .read<SetCountryCubit>()
            .state
            .dialCode,
        "default_country":
            navigatorKey.currentContext!.read<SetCountryCubit>().state.countryCode,
      };
      var response = await httpPost(Config.checkMobileNumber, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changeEmail({String? email}) async {
    try {
      var data = {"email": email};
      var response = await httpPost(Config.checkEmail, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> otpVerify(
      {String? phone,
      required BuildContext context,
      String? otpValue,
      String? countryCode,
      String? email,
      String? resetToken,
      bool? changeEmail,
      bool? changeMobile,
      String? defaultCountry}) async {

    if (!countryCode!.startsWith("+")) {
      countryCode = '+$countryCode';
    }
    try {
 

     var     response = await httpPost(context: context, Config.otpVerification, {
        "phone": phone,
        "otp_value": otpValue,
        "phone_country": countryCode
      });
      final rawDocStatus = response["data"]?["verification_document_status"];
      final dynamic dataObj = response["data"];
      final dataKeys = dataObj is Map ? dataObj.keys.toList() : [];
      final firestoreId = dataObj is Map
          ? (dataObj["firestore_id"] ??
              dataObj["fire_store_id"] ??
              dataObj["fireStoreId"] ??
              dataObj["driver_firestore_id"])
          : null;
      debugPrint(
          "[DocDebug][API] otpVerification | status=${response["status"]} | verification_document_status=$rawDocStatus | firestoreId=$firestoreId | dataKeys=$dataKeys | fullMessage=${response["message"] ?? response["error"] ?? ""}");

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendEmailOtpForChange(
      Map<String, dynamic> data) async {
    try {
      var response = await httpPost(Config.resendTokenEmailChange, data,
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forChangePhoneNumberOtpVerification(
      {required Map<String, dynamic> data,
      required BuildContext context}) async {
    try {
      var response =
          await httpPost(Config.changeMobileNumber, data, context: context);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
