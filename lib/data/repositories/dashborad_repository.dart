
import 'package:flutter/material.dart';

import '../../core/services/config.dart';
import '../../core/services/http.dart';

class DashboradRepository {
  Future<Map<String, dynamic>> dashboradDriver({
    required BuildContext context,
  }) async {
    try {
      var response =
          await httpPost(Config.getDriverDashboardStats, {}, context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
