
import 'package:flutter/material.dart';

import '../../core/services/config.dart';
import '../../core/services/http.dart';

class HistoryRepository {
  Future<Map<String, dynamic>> getHistoryData({
    required BuildContext context,
    required Map<String, dynamic> bookingKeyMap,
  }) async {
    try {
      var response = await httpPost(Config.vendorbookingRecord, bookingKeyMap,
          context: context);

      return response;
    } catch (err) {
      rethrow;
    }
  }
}
