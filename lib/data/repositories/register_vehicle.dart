
import 'package:flutter/material.dart';

import '../../core/services/config.dart';
import '../../core/services/http.dart';

class RegisterVehicleRepository {
  Future<Map<String, dynamic>> registerProfile({
    required BuildContext context,
    required String name,
    required String gender,
  }) async {
    try {
      var response = await httpPost(
          context: context,
          Config.editProfile,
          {"first_name": name, "gender": gender});

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories(
      {required BuildContext context}) async {
    try {
      var response =
          await httpGet(context: context, Config.getAllCategories, {});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVehicleItemData(
      {required BuildContext context}) async {
    try {
      var response = await httpPost(context: context, Config.myItems, {});
      return response;
    } catch (e) {
      rethrow;
    }
  }


  Future<Map<String, dynamic>> getMakesModel(contest, value) async {
    try {
      var response = await httpGet(
          Config.getMakes, {"item_type": "${value == "" ? "" : value}"},
          context: contest);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerVehicle({
    required BuildContext context,
    required String itemTypeId,
    required Map<String, dynamic> itemMap,
    required String itemId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "item_type_id": itemTypeId,
        "id": itemId,
        ...itemMap,
      };
      var response = await httpPost(
        context: context,
        Config.editItem,
        data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSingleDocumentImg({
    required BuildContext context,
    required String vehicleId,
    required Map<String, dynamic> itemImageMap,
  }) async {
    try {
      final response = await httpPost(
          context: context,
          Config.addEditVerificationDocuments,
          {"id": vehicleId, ...itemImageMap});

      return response;
    } catch (err) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadSingleImg({
    required BuildContext context,
    required String itemId,
    required Map<String, dynamic> itemImageMap,
  }) async {
    try {
      final response = await httpPost(
          context: context,
          Config.addEditItemImages,
          {"id": itemId, ...itemImageMap});

      return response;
    } catch (err) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVehicleDocument(
      {required BuildContext context}) async {
    try {
      final response =
          await httpPost(context: context, Config.getVerificationDocuments, {});

      return response;
    } catch (err) {
      rethrow;
    }
  }

Future<Map<String, dynamic>> confirmBookRideOtp({
    required BuildContext context,
    required String pickupOtp,
    required String bookingId,
    required String deliveryImage1,
    required String deliveryImage2,
  }) async {
    try {
      Map<String, dynamic> mapData = {
        "booking_id": bookingId,
        "pickup_otp": pickupOtp,
        "delivery_image_1": deliveryImage1,
        "delivery_image_2": deliveryImage2,
      };
      final response = await httpPost(
          context: context, Config.confirmBookingByHost, mapData);

      return response;
    } catch (e) {

      rethrow;
    }
  }
}
