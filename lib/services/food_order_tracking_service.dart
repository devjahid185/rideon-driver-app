import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_on_driver/core/services/data_store.dart';
import 'package:ride_on_driver/data/repositories/food_delivery_repository.dart';

class FoodOrderTrackingService {
  FoodOrderTrackingService._();

  static final FoodOrderTrackingService instance = FoodOrderTrackingService._();

  final FoodDeliveryRepository _repository = FoodDeliveryRepository();
  StreamSubscription<Position>? _subscription;
  DateTime? _lastBackendSyncAt;
  int? _activeOrderId;
  bool _firebaseWritable = true;

  bool get isRunning => _subscription != null;

  Future<void> start({
    required int orderId,
    required String orderNumber,
    String? status,
  }) async {
    if (_activeOrderId == orderId && _subscription != null) return;
    await stop(markInactive: false);
    _activeOrderId = orderId;
    _firebaseWritable = true;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final ref = FirebaseDatabase.instance.ref('food_order_tracking/$orderId');
    try {
      await ref.update({
        'order_id': orderId,
        'order_number': orderNumber,
        'driver_id': box.get('driverId')?.toString() ?? '',
        'status': status ?? 'on_the_way',
        'tracking_active': true,
        'started_at': ServerValue.timestamp,
      });
    } catch (_) {
      _firebaseWritable = false;
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 12,
      ),
    ).listen((position) async {
      await _publish(orderId, orderNumber, position, status: status);
    });

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      await _publish(orderId, orderNumber, current, status: status);
    } catch (_) {}
  }

  Future<void> stop({bool markInactive = true}) async {
    final orderId = _activeOrderId;
    await _subscription?.cancel();
    _subscription = null;
    _activeOrderId = null;
    _lastBackendSyncAt = null;
    if (markInactive && orderId != null) {
      try {
        await FirebaseDatabase.instance.ref('food_order_tracking/$orderId').update({
          'tracking_active': false,
          'stopped_at': ServerValue.timestamp,
        });
      } catch (_) {}
    }
  }

  Future<void> _publish(
    int orderId,
    String orderNumber,
    Position position, {
    String? status,
  }) async {
    final now = DateTime.now();
    final payload = {
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': position.heading,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'recorded_at': now.toIso8601String(),
      'updated_at': ServerValue.timestamp,
    };
    if (_firebaseWritable) {
      try {
        final ref = FirebaseDatabase.instance.ref('food_order_tracking/$orderId');
        await ref.child('current').set(payload);
        await ref.child('route_points').push().set(payload);
        await ref.update({
          'order_id': orderId,
          'order_number': orderNumber,
          'driver_id': box.get('driverId')?.toString() ?? '',
          'status': status ?? 'on_the_way',
          'tracking_active': true,
          'updated_at': ServerValue.timestamp,
        });
      } catch (_) {
        _firebaseWritable = false;
      }
    }

    if (_lastBackendSyncAt == null ||
        now.difference(_lastBackendSyncAt!).inSeconds >= 12) {
      _lastBackendSyncAt = now;
      try {
        final response = await _repository.storeOrderLocation(
          orderId: orderId,
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed,
          accuracy: position.accuracy,
          recordedAt: now,
        );
        // ignore: avoid_print
        print('[FoodTracking] backend sync status=${response['status']} message=${response['message']}');
      } catch (error) {
        // ignore: avoid_print
        print('[FoodTracking] backend sync failed error=$error');
        // Firebase remains the realtime source if archive sync fails briefly.
      }
    }
  }
}
