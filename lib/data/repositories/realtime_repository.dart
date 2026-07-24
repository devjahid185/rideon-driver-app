
import 'package:flutter/material.dart';

import '../../core/services/config.dart';
import '../../core/services/http.dart';

class RealtimeRepository {
  Future<Map<String, dynamic>> updateRideStatus(
      {required BuildContext context,
      required String bookingId,
      required String rideStatus}) async {
    try {
      var response = await httpPost(Config.updateBookingStatusByDriver,
          {"booking_id": bookingId, "status": rideStatus},
          context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCompleteRideWithDataStatus({
    required BuildContext context,
    required String bookingId,
    required String rideStatus,
    required String fireBaseJson,
    required String totalTime,
    required String dropOtp,
  }) async {
    try {
      var response = await httpPost(
          Config.updateBookingStatusByDriver,
          {
            "booking_id": bookingId,
            "status": rideStatus,
            "firebase_json": fireBaseJson,
             "drop_otp":dropOtp,
            "total_time_taken": totalTime
          },
          context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
