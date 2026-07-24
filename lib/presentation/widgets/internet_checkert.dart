import 'dart:async';
import 'package:connection_notifier/connection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:internet_connection_checker/internet_connection_checker.dart';


class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<InternetConnectionStatus> _internetSubscription;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        final status = await InternetConnectionChecker().connectionStatus;
        setState(() => _hasInternet = status == InternetConnectionStatus.connected);
      } else {
        setState(() => _hasInternet = false);
      }
    });

    // Internet status listener
    _internetSubscription = InternetConnectionChecker().onStatusChange.listen((status) {
      setState(() => _hasInternet = status == InternetConnectionStatus.connected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your main content
        widget.child,
        // Internet status banner
        if (!_hasInternet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              color: Colors.red,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _internetSubscription.cancel();
    super.dispose();
  }
}

class CustomConnectionNotifier extends StatelessWidget {
  final Widget child;
  final double height;
  final Alignment alignment;

  const CustomConnectionNotifier({
    super.key,
    required this.child,
    this.height = 50.0,
    this.alignment = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context) {
    return LocalConnectionNotifier(
      connectionNotificationOptions: ConnectionNotificationOptions(
        connectedText: "Welcome back!!",
        disconnectedText: "Connection Lost",
        animationDuration: const Duration(seconds: 2),
        pauseConnectionListenerWhenAppInBackground: true,
        height: height,
        alignment: alignment,
      ),
      child: child,
    );
  }
}