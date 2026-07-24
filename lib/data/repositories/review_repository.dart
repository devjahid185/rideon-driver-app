
import 'package:flutter/material.dart';

import '../../core/services/config.dart';
import '../../core/services/http.dart';

class ReviewRepository {
  Future<Map<String, dynamic>> submitReview(
      {required BuildContext context,
      required String bookingId,
      required String rating,
      required String message}) async {
    try {
      var response = await httpPost(Config.giveReviewByHost,
          {"booking_id": bookingId, "rating": rating, "message": message},
          context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
