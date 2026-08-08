// ignore_for_file: unnecessary_string_interpolations

import 'dart:convert';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/config.dart';
import '../../services/data_store.dart';
import '../../services/http.dart';
import '../../utils/common_widget.dart';
import '../../utils/theme/project_color.dart';
import '../workspace.dart';
import '../../../presentation/cubits/food_delivery_cubit.dart';
import '../../../presentation/screens/home/food_driver_orders_screen.dart';
import '../../../presentation/screens/home/food_active_delivery_screen.dart';
import '../../../data/repositories/food_delivery_repository.dart';
import '../../../presentation/cubits/location/ringtone_cubit.dart';

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
bool _isFcmRefreshListenerAttached = false;
bool _isNotificationListenerAttached = false;
String? _runtimeLastSyncedFcmToken;
DateTime? _lastFoodOrderOpenAt;
bool _foodDialogOpen = false;
Timer? _foodRequestWatcherTimer;
bool _isFoodWatcherTickRunning = false;
int? _lastAutoShownFoodOrderId;
const String _shownFoodOrderIdsKey = 'shownFoodOrderDialogIds';

bool _isNotificationForDriverApp(Map<String, dynamic> data) {
  final targetApp = data['target_app']?.toString().toLowerCase().trim();
  if (targetApp != null && targetApp.isNotEmpty && targetApp != 'driver') {
    return false;
  }

  final route = data['route']?.toString();
  return route != 'restaurant_food_order';
}

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotificationfromFirebase(RemoteMessage message) async {
  if (!_isNotificationForDriverApp(message.data)) {
    return;
  }

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'launch_background',
        ),
      ),
      payload: payload,
    );
  }
}

Future<void> setupPushNotifications() async {
  await FirebaseMessaging.instance.requestPermission();
  await setupFlutterNotifications();
  await getFCMTokenInitialToSetThedata(forceSync: true);
  _attachFcmTokenRefreshListener();
  await _attachNotificationListeners();
  _startFoodRequestWatcher();
}

void _attachFcmTokenRefreshListener() {
  if (_isFcmRefreshListenerAttached) {
    return;
  }
  _isFcmRefreshListenerAttached = true;
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint(
        '[PushDebug] onTokenRefresh received | tokenPreview=${newToken.substring(0, newToken.length > 16 ? 16 : newToken.length)}...');
    await _updateFcmTokenOnServer(
      newToken,
      trigger: 'onTokenRefresh',
      forceSync: true,
    );
  });
}

Future<void> getFCMTokenInitialToSetThedata({bool forceSync = false}) async {
  try {
    var fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _updateFcmTokenOnServer(
        fcmToken,
        trigger: 'init',
        forceSync: forceSync,
      );
    }
  } catch (_) {}
}

Future<void> getFCMToken({bool forceSync = false}) async {
  try {
    var fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _updateFcmTokenOnServer(
        fcmToken,
        trigger: 'refresh',
        forceSync: forceSync,
      );
    }
  } catch (_) {}
}

Future<void> syncPendingFcmTokenIfAny({bool forceSync = true}) async {
  try {
    String pendingToken = box.get('pendingFcmToken')?.toString() ?? '';
    if (pendingToken.isNotEmpty) {
      await _updateFcmTokenOnServer(
        pendingToken,
        trigger: 'pending_sync',
        forceSync: forceSync,
      );
      return;
    }

    await getFCMToken(forceSync: forceSync);
  } catch (e) {
    debugPrint('[PushDebug] syncPendingFcmTokenIfAny failed | error=$e');
  }
}

Future<void> _updateFcmTokenOnServer(
  String fcmToken, {
  String trigger = '',
  bool forceSync = false,
}) async {
  try {
    if (token.isEmpty) {
      box.put('pendingFcmToken', fcmToken);
      debugPrint(
          '[PushDebug] fcmUpdate delayed (user token missing) | trigger=$trigger');
      return;
    }

    if (!forceSync && _runtimeLastSyncedFcmToken == fcmToken) {
      debugPrint(
          '[PushDebug] fcmUpdate skipped (already synced this session) | trigger=$trigger');
      return;
    }

    await httpPost(
      Config.fcmUpdate,
      {'fcm': fcmToken},
      context: navigatorKey.currentContext!,
    );

    _runtimeLastSyncedFcmToken = fcmToken;
    box.put('lastSyncedFcmToken', fcmToken);
    box.delete('pendingFcmToken');
    debugPrint('[PushDebug] fcmUpdate success | trigger=$trigger');
  } catch (e) {
    box.put('pendingFcmToken', fcmToken);
    debugPrint('[PushDebug] fcmUpdate failed | trigger=$trigger | error=$e');
  }
}

Future<void> _attachNotificationListeners() async {
  if (_isNotificationListenerAttached) {
    return;
  }
  _isNotificationListenerAttached = true;

  FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
    showFlutterNotificationfromFirebase(event);
    if (!_isNotificationForDriverApp(event.data)) {
      return;
    }

    final route = event.data['route']?.toString();
    if (route == 'food_order') {
      handleNotificationClick(route, event.data);
    }
  });

  await setupFlutterNotifications();

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    if (_isNotificationForDriverApp(initialMessage.data)) {
      handleNotificationClick(
          initialMessage.data['route'], initialMessage.data);
    }
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
    if (event.data.isNotEmpty && _isNotificationForDriverApp(event.data)) {
      handleNotificationClick(event.data['route'], event.data);
    }
  });
}

Future<void> showNotification(context) async {
  await setupFlutterNotifications();
  await _attachNotificationListeners();
  _startFoodRequestWatcher();
}

void _startFoodRequestWatcher() {
  if (_foodRequestWatcherTimer != null) {
    return;
  }
  _foodRequestWatcherTimer =
      Timer.periodic(const Duration(seconds: 8), (_) async {
    await _checkAndShowIncomingFoodRequestFromApi();
  });
}

Future<void> _checkAndShowIncomingFoodRequestFromApi() async {
  if (_isFoodWatcherTickRunning || token.isEmpty || _foodDialogOpen) {
    return;
  }

  final lifecycle = WidgetsBinding.instance.lifecycleState;
  final isForeground = lifecycle == AppLifecycleState.resumed;
  if (!isForeground) return;

  _isFoodWatcherTickRunning = true;
  try {
    final response = await FoodDeliveryRepository().getAvailableOrders();
    if (response['status'] != 200) {
      // ignore: avoid_print
      print('[FoodDriver] watcher available orders failed response=$response');
      return;
    }
    final raw = response['data'];
    if (raw is! List || raw.isEmpty) {
      // ignore: avoid_print
      print(
          '[FoodDriver] watcher no available food order rawType=${raw.runtimeType}');
      return;
    }

    Map<String, dynamic>? order;
    for (final item in raw) {
      if (item is! Map) continue;
      final candidate = Map<String, dynamic>.from(item);
      final status = (candidate['status'] ?? '').toString();
      final driverId = (candidate['driver_id'] ?? '').toString();
      final orderId = int.tryParse((candidate['id'] ?? '').toString());
      final isIncoming =
          status == 'accepted' && (driverId.isEmpty || driverId == 'null');
      if (isIncoming && orderId != null && orderId > 0) {
        order = candidate;
        break;
      }
    }
    if (order == null) {
      final summaries = raw.whereType<Map>().map((candidate) {
        final id = (candidate['id'] ?? '').toString();
        final number = (candidate['order_number'] ?? '').toString();
        final status = (candidate['status'] ?? '').toString();
        final driverId = (candidate['driver_id'] ?? '').toString();
        return '$id:$number:$status:driver=$driverId';
      }).join(',');
      // ignore: avoid_print
      print(
          '[FoodDriver] watcher orders found but no incoming accepted order count=${raw.length} orders=$summaries');
      return;
    }

    final status = (order['status'] ?? '').toString();
    final orderId = int.tryParse((order['id'] ?? '').toString());
    if (orderId == null || orderId <= 0) return;
    if (_hasShownFoodOrderDialog(orderId)) {
      // ignore: avoid_print
      print('[FoodDriver] watcher skipped duplicate orderId=$orderId');
      return;
    }

    _handleIncomingFoodOrder({
      ...order,
      'route': 'food_order',
      'food_order_id': orderId.toString(),
      'food_order_number': (order['order_number'] ?? '').toString(),
      'food_order_status': status,
    });
  } catch (e) {
    // ignore: avoid_print
    print('[FoodDriver] watcher failed error=$e');
  } finally {
    _isFoodWatcherTickRunning = false;
  }
}

void handleNotificationClick(String? route, var data) {
  if (token.isEmpty) {
    showErrorToastMessage('Please Login first');
    return;
  }
  if (route == 'food_order') {
    final now = DateTime.now();
    if (_lastFoodOrderOpenAt != null &&
        now.difference(_lastFoodOrderOpenAt!).inMilliseconds < 1500) {
      return;
    }
    _lastFoodOrderOpenAt = now;
    _handleIncomingFoodOrder(data);
    return;
  }
}

void _handleIncomingFoodOrder(dynamic data) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    goTo(const FoodDriverOrdersScreen());
    return;
  }

  final orderId = int.tryParse((data?['food_order_id'] ?? '').toString());
  final orderNo = (data?['food_order_number'] ?? '').toString();
  final status = (data?['food_order_status'] ?? '').toString();
  final payload =
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  final branch = payload['branch'] is Map
      ? Map<String, dynamic>.from(payload['branch'])
      : <String, dynamic>{};
  final restaurant = payload['restaurant'] is Map
      ? Map<String, dynamic>.from(payload['restaurant'])
      : <String, dynamic>{};
  final pickupAddress = (branch['address'] ?? '').toString();
  final restaurantName = (restaurant['name'] ?? '').toString();
  final totalAmount = (payload['total_amount'] ?? '').toString();

  final driverId = (payload['driver_id'] ?? '').toString();
  final isAssignedToDriver = driverId.isNotEmpty && driverId != 'null';
  final isIncomingAvailableOrder =
      orderId != null && status == 'accepted' && !isAssignedToDriver;

  if (orderId != null && isIncomingAvailableOrder) {
    if (_hasShownFoodOrderDialog(orderId)) {
      return;
    }
    _rememberShownFoodOrderDialog(orderId);
  }

  if (orderId != null &&
      isAssignedToDriver &&
      ['accepted', 'preparing', 'ready_for_pickup', 'picked_up', 'on_the_way']
          .contains(status)) {
    goTo(FoodActiveDeliveryScreen(orderId: orderId));
    return;
  }

  if (_foodDialogOpen) {
    goTo(const FoodDriverOrdersScreen());
    return;
  }

  _foodDialogOpen = true;
  RingtoneHelper().playRingtone();
  final countdown = ValueNotifier<int>(15);
  Timer? countdownTimer;

  showModalBottomSheet(
    context: ctx,
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: .2),
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown.value <= 1) {
          t.cancel();
          if (Navigator.of(sheetCtx).canPop()) {
            Navigator.of(sheetCtx).pop();
          }
          return;
        }
        countdown.value = countdown.value - 1;
      });

      return ValueListenableBuilder<int>(
        valueListenable: countdown,
        builder: (context, left, _) {
          return SizedBox(
            height: MediaQuery.of(sheetCtx).size.height * 0.58,
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        height: 72,
                        width: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: themeColor, width: 3),
                        ),
                        child: Text(
                          "$left",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'seconds left',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'New Food Delivery Request',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delivery_dining,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (restaurantName.isNotEmpty) ...[
                            _foodInfoRow(
                              icon: Icons.storefront_outlined,
                              title: 'Restaurant',
                              value: restaurantName,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _foodInfoRow(
                            icon: Icons.confirmation_number_outlined,
                            title: 'Order',
                            value: orderNo.isEmpty
                                ? 'Food order request'
                                : orderNo,
                          ),
                          const SizedBox(height: 10),
                          _foodInfoRow(
                            icon: Icons.my_location_outlined,
                            title: 'Pickup',
                            value: pickupAddress.isEmpty
                                ? 'Restaurant pickup location'
                                : pickupAddress,
                          ),
                          const SizedBox(height: 10),
                          if (totalAmount.isNotEmpty) ...[
                            _foodInfoRow(
                              icon: Icons.payments_outlined,
                              title: 'Total',
                              value: totalAmount,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _foodInfoRow(
                            icon: Icons.timer_outlined,
                            title: 'Accept within',
                            value: '${left}s',
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CustomSlideButton(
                                  textActiveColor: Colors.white,
                                  iconColor: Colors.white,
                                  textInactiveColor: Colors.white,
                                  inactiveColor: themeColor,
                                  isOnRide: false,
                                  acceptedText: "ACCEPTED",
                                  defaultText: "ACCEPT DELIVERY",
                                  onChanged: (value) async {
                                    if (!value) return;
                                    Navigator.of(sheetCtx).pop();
                                    if (orderId != null && orderId > 0) {
                                      try {
                                        await ctx
                                            .read<DriverFoodCubit>()
                                            .acceptOrder(orderId);
                                      } catch (_) {}
                                      if (ctx.mounted) {
                                        goTo(FoodActiveDeliveryScreen(
                                            orderId: orderId));
                                        return;
                                      }
                                    }
                                    showToastMessage('Food order accepted');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () async {
                                    if (orderId != null && orderId > 0) {
                                      try {
                                        await FoodDeliveryRepository()
                                            .rejectOrderOffer(orderId);
                                      } catch (_) {}
                                    }
                                    if (!sheetCtx.mounted) return;
                                    Navigator.of(sheetCtx).pop();
                                  },
                                  child: Container(
                                    height: 55,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "Skip",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    countdownTimer?.cancel();
    countdown.dispose();
    RingtoneHelper().stopRingtone();
    _foodDialogOpen = false;
  });
}

bool _hasShownFoodOrderDialog(int orderId) {
  if (_lastAutoShownFoodOrderId == orderId) {
    return true;
  }
  return _shownFoodOrderDialogIds().contains(orderId);
}

Set<int> _shownFoodOrderDialogIds() {
  final raw = box.get(_shownFoodOrderIdsKey)?.toString() ?? '';
  if (raw.isEmpty) return <int>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .toSet();
    }
  } catch (_) {}
  return raw
      .split(',')
      .map((value) => int.tryParse(value.trim()))
      .whereType<int>()
      .toSet();
}

void _rememberShownFoodOrderDialog(int orderId) {
  _lastAutoShownFoodOrderId = orderId;
  final ids = _shownFoodOrderDialogIds()..add(orderId);
  final trimmed = ids.toList()..sort((a, b) => b.compareTo(a));
  box.put(_shownFoodOrderIdsKey, jsonEncode(trimmed.take(80).toList()));
}

Widget _foodInfoRow({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: Colors.grey.shade700),
      const SizedBox(width: 8),
      Text(
        '$title: ',
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Future<void> initializeNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('launch_background');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        try {
          final Map<String, dynamic> data =
              jsonDecode(notificationResponse.payload!);
          handleNotificationClick(data['route'], data);
        } catch (_) {}
      }
    },
  );
}

Future<void> sendNotificationDirect({
  required String playerId,
  required String title,
  required String message,
}) async {
  debugPrint(
      '[PushDebug] sendNotificationDirect skipped (OneSignal removed). title=$title');
}
