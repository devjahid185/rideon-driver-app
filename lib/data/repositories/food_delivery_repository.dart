import 'package:ride_on_driver/core/extensions/workspace.dart';
import 'package:ride_on_driver/core/services/config.dart';
import 'package:ride_on_driver/core/services/http.dart';

class FoodDeliveryRepository {
  Future<Map<String, dynamic>> getAvailableOrders({int limit = 20}) async {
    // Keep this visible in debug logs because food dispatch depends on polling.
    // ignore: avoid_print
    print('[FoodDriver] available orders request limit=$limit');
    final response = await httpGet(
      Config.foodAvailableOrders,
      {'limit': limit.toString()},
      context: navigatorKey.currentContext!,
    );
    final mapped = Map<String, dynamic>.from(response ?? {});
    final data = mapped['data'];
    final count = data is List ? data.length : 'n/a';
    // ignore: avoid_print
    print('[FoodDriver] available orders response status=${mapped['status']} message=${mapped['message']} count=$count');
    return mapped;
  }

  Future<Map<String, dynamic>> getMyOrders({
    int limit = 100,
    String? status,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await httpGet(
      Config.foodMyOrders,
      query,
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final response = await httpGet(
      '${Config.foodAcceptOrder}/$orderId',
      {},
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final response = await httpPost(
      '${Config.foodAcceptOrder}/$orderId/accept',
      {},
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> rejectOrderOffer(int orderId) async {
    final response = await httpPost(
      '${Config.foodAcceptOrder}/$orderId/reject-offer',
      {},
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? note,
    String? deliveryOtp,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
      if (deliveryOtp != null && deliveryOtp.isNotEmpty) 'delivery_otp': deliveryOtp,
    };
    final response = await httpPost(
      '${Config.foodUpdateOrderStatus}/$orderId/status',
      payload,
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> orderTimeline(int orderId) async {
    final response = await httpGet(
      '${Config.foodOrderTimeline}/$orderId/timeline',
      {},
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }

  Future<Map<String, dynamic>> storeOrderLocation({
    required int orderId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    DateTime? recordedAt,
  }) async {
    final payload = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (heading != null) 'heading': heading.toString(),
      if (speed != null) 'speed': speed.toString(),
      if (accuracy != null) 'accuracy': accuracy.toString(),
      if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
    };
    final response = await httpPost(
      '${Config.foodOrderTracking}/$orderId/location',
      payload,
      context: navigatorKey.currentContext!,
    );
    return Map<String, dynamic>.from(response ?? {});
  }
}
