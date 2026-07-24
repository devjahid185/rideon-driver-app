import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_on_driver/app/app_localizations.dart';
import 'package:ride_on_driver/app/register_cubits.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/presentation/cubits/localizations_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/location/ringtone_cubit.dart';
import 'package:ride_on_driver/presentation/screens/Splash/initial_screen.dart';
import 'core/extensions/helper/push_notifications.dart';
import 'core/extensions/workspace.dart';
import 'core/utils/theme/project_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('appBox');
  await Hive.openBox('lanBox');
  await initializeNotifications();
  await setupPushNotifications();
  await _ensureLocationServiceEnabledOnStart();
  notifires = ColorNotifires();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(defaultPresentSound: false);

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
 FlutterError.onError = (FlutterErrorDetails details) {};
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

Future<void> _ensureLocationServiceEnabledOnStart() async {
  try {
    final location = loc.Location();
    final isServiceEnabled = await location.serviceEnabled();
    if (!isServiceEnabled) {
      await location.requestService();
    }
  } catch (_) {}
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const platform =
      MethodChannel('com.wgn.driver.taxiapp/floating_bubble');
  StreamSubscription<Position>? positionStreamSubscription;
  DateTime? lastUpdateTime;
  @override
  initState() {
    super.initState();
    if (Platform.isIOS) {
      configureAudioSessionAndPermissions();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    positionStreamSubscription?.cancel();
    RingtoneHelper().stopRingtone();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final appBox = Hive.box('appBox');
    bool? driverStatus = appBox.get('driver_status');
    String? driverId = appBox.get('driverId');

    if (Platform.isAndroid && driverStatus == true) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        await _requestLocationPermissions();
        await _showFloatingBubble();
        if (driverId == null || driverId.isEmpty) {
          return;
        }

        positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((Position position) async {
          final now = DateTime.now();
          int duration =
              int.parse(appBox.get("backgroundUpdatedLocation") ?? "10");
          if (lastUpdateTime != null &&
              now.difference(lastUpdateTime!).inSeconds < duration) {
            return;
          }

          lastUpdateTime = now;

          try {
            GeoFirePoint geoPoint =
                GeoFirePoint(GeoPoint(position.latitude, position.longitude));

            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .update({
              'geo': geoPoint.data,
              'timestamp': DateTime.now(),
            });

            final driverDoc = await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .get();
            final driverData = driverDoc.data();

            if (driverData != null &&
                driverData.containsKey('ride_request') &&
                driverData['ride_request'].isNotEmpty) {
              final rideRequest =
                  driverData['ride_request'] as Map<String, dynamic>;
              final rideId = rideRequest['rideId'];

              FirebaseDatabase.instance
                  .ref()
                  .child('ride_requests')
                  .child(rideId)
                  .child('driverLocation')
                  .update({
                    'lat': position.latitude,
                    'lng': position.longitude,
                  })
                  .then((_) {})
                  .catchError((error) {});
            }
          } catch (e) {
            BotToast.showText(text: "Failed to update location: $e");
          }
        }, onError: (e) {
          BotToast.showText(text: "Location stream error: $e");
        });
      } else if (state == AppLifecycleState.resumed) {
        await _hideFloatingBubble();
      }
    }

    if (Platform.isIOS && driverStatus == true) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        if (driverId == null || driverId.isEmpty) {
          return;
        }

        await _startBackgroundLocation();

        positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((Position position) async {
          final now = DateTime.now();
          int duration =
              int.parse(appBox.get("backgroundUpdatedLocation") ?? "10");

          if (lastUpdateTime != null &&
              now.difference(lastUpdateTime!).inSeconds < duration) {
            return;
          }

          lastUpdateTime = now;

          try {
            GeoFirePoint geoPoint =
                GeoFirePoint(GeoPoint(position.latitude, position.longitude));

            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .update({
              'geo': geoPoint.data,
              'timestamp': DateTime.now(),
            });

            final driverDoc = await FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .get();
            final driverData = driverDoc.data();

            if (driverData != null &&
                driverData.containsKey('ride_request') &&
                driverData['ride_request'].isNotEmpty) {
              final rideRequest =
                  driverData['ride_request'] as Map<String, dynamic>;
              final rideId = rideRequest['rideId'];

              await FirebaseDatabase.instance
                  .ref()
                  .child('ride_requests')
                  .child(rideId)
                  .child('driverLocation')
                  .update({
                'lat': position.latitude,
                'lng': position.longitude,
              });
            }
          } catch (e) {
            //
          }
        }, onError: (e) {});
      } else if (state == AppLifecycleState.resumed) {
        await positionStreamSubscription?.cancel();
      }
    }
  }

  Future<void> _requestLocationPermissions() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (Platform.isAndroid && await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }
    if (await Permission.locationAlways.isPermanentlyDenied) {
      BotToast.showText(
          text: "Enable 'All Time Location' permission from settings.");
      await openAppSettings();
      return;
    }
  }

  Future<void> _startBackgroundLocation() async {
    if (Platform.isIOS) {
      try {
        await platform.invokeMethod('startBackgroundLocation');
      } catch (e) {
        BotToast.showText(text: "Failed to start background location: $e");
      }
    }
  }

  Future<void> configureAudioSessionAndPermissions() async {
    try {
      await platform.invokeMethod('setupAudioSession');

      await platform.invokeMethod('requestMicrophonePermission');
      // ignore: unused_catch_clause
    } on PlatformException catch (e) {
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _showFloatingBubble() async {
    try {
      await platform.invokeMethod('showBubble');
    } on PlatformException catch (e) {
      BotToast.showText(text: "Failed to show bubble: ${e.message}");
    } catch (e) {
      BotToast.showText(text: "Unexpected error: $e");
    }
  }

  Future<void> _hideFloatingBubble() async {
    try {
      await platform.invokeMethod('hideBubble');
    } on PlatformException catch (e) {
      BotToast.showText(text: "Failed to hide bubble: ${e.message}");
    } catch (e) {
      BotToast.showText(text: "Unexpected error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        ...RegisterCubits().providers,
      ],
      child: ChangeNotifierProvider.value(
        value: notifires,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            context.read<LanguageCubit>().loadCurrentLanguage();
            return BlocBuilder<LanguageCubit, LanguageState>(
              builder: (context, state) {
                if (state is LanguageLoader) {
                  appLocale = Locale(state.language ?? "en");
                }

                return MaterialApp(
                  builder: BotToastInit(),
                  navigatorObservers: [BotToastNavigatorObserver()],
                  navigatorKey: navigatorKey,
                  theme: ThemeData(fontFamily: 'Gilroy Regular'),
                  debugShowCheckedModeBanner: false,
                  locale: appLocale,
                  supportedLocales: const [
                    Locale('en', 'US'),
                    Locale('ar', 'AR'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const InitialScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> showRideNotification({
  required String pickup,
  required String drop,
  required double fare,
  required double distance,
  bool playSound = false, // Add this parameter
}) async {
  const String title = '🚖 New Ride Request!';

  final String body = '''
💰 Fare: $currency ${fare.toStringAsFixed(0)}     📏 ${distance.toStringAsFixed(1)} km

🟢 Pickup: $pickup
🔴 Drop:   $drop

🕒 Accept within 50 seconds
''';

  final androidDetails = AndroidNotificationDetails(
    'ride_channel',
    'Ride Request',
    channelDescription: 'RideOn Driver ride notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    styleInformation: BigTextStyleInformation(
      body,
      htmlFormatContent: true,
      htmlFormatTitle: true,
    ),
    color: const Color(0xFF0A84FF), // clean blue
    colorized: true,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    presentBadge: false,
  );

  final platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    100,
    title,
    body,
    platformDetails,
  );
}
