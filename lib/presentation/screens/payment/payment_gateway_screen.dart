import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/bottom_bar/home_main.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final String? url;
  final String? bookingId;
  final dynamic price;
  final bool? fromBooking;

  const PaymentGatewayScreen({
    super.key,
    this.url,
    this.bookingId,
    this.price,
    this.fromBooking,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  Timer? timer;
  int secondsRemaining = 600;
  bool isDisposed = false;
  bool hasEndedSession = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    _listenKeyboardVisibility();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted && !isDisposed) setState(fn);
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isDisposed) {
        if (secondsRemaining <= 0) {
          timer.cancel();
          _showTimeoutBottomSheet();
        } else {
          safeSetState(() => secondsRemaining--);
        }
      }
    });
  }

  void handleNavigation(String url) {
    debugPrint("Navigated to: $url");

    if (hasEndedSession) return;

    if (url.contains("wallet_recharge_success")) {
      endSession(success: true);
      debugPrint('✅ wallet_recharge_success');
    } else if (url.contains("wallet_recharge_fail")) {
      endSession(message: "Your recharge failed");
      debugPrint('❌ wallet_recharge_fail');
    } else if (url.contains("payment_fail")) {
      endSession(message: "Your booking failed");
      debugPrint('❌ payment_fail');
    } else if (url.contains("/invalid-order")) {
      endSession(message: "Invalid Order");
      debugPrint('⚠️ invalid-order');
    }
  }

  void endSession({bool success = false, String? message}) {
    if (hasEndedSession) return;
    hasEndedSession = true;

    timer?.cancel();

    if (!isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (message != null) showErrorToastMessage(message);
        goToWithClear(const HomeMain(initialIndex: 2));
      });
    }
  }

  void _listenKeyboardVisibility() {
    KeyboardVisibilityController().onChange.listen((visible) {
      if (webViewController == null) return;

      final jsCode = visible
          ? """
          if (window.formData) {
            const inputs = document.querySelectorAll('input, textarea');
            inputs.forEach(input => {
              if (input.name && window.formData[input.name]) {
                input.value = window.formData[input.name];
              }
            });
          }
        """
          : """
          const inputs = document.querySelectorAll('input, textarea');
          const formData = {};
          inputs.forEach(input => {
            if (input.name) formData[input.name] = input.value;
          });
          window.formData = formData;
        """;

      webViewController!.evaluateJavascript(source: jsCode);
    });
  }

  void _showTimeoutBottomSheet() {
    if (isDisposed) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: notifires.getbgcolor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        Future.delayed(const Duration(seconds: 3), (){
          goBack();
          goBack();
        });
        return PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_off, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text("Payment Time Expired".translate(context),
                    style: heading2Grey1(context)),
                const SizedBox(height: 12),
                Text(
                  "Your payment session has timed out. Redirecting...",
                  textAlign: TextAlign.center,
                  style: regular2(context).copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      themeColor),
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _showBackDialog() async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: notifires.getbgcolor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: commonlyUserLogo(),
              ),
            ),
            const SizedBox(height: 16),
            Text("Go Back?".translate(context),
                style: heading1(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: notifires.getwhiteblackColor)),
            const SizedBox(height: 10),
            Text("Are you sure you want to go back?".translate(context),
                textAlign: TextAlign.center,
                style: regular2(context).copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _buildDialogButton("Cancel", onTap: () {
                  Navigator.pop(context);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDialogButton("Yes", filled: true, onTap: () {
                  Navigator.pop(context);
                  goBack();
                }),
              ),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildDialogButton(String text,
      {bool filled = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: notifires.getwhiteblackColor),
        ),
        child: Center(
          child: Text(
            text.translate(context),
            style: regular2(context).copyWith(
              color: filled ? Colors.white : notifires.getwhiteblackColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    isDisposed = true;
    timer?.cancel();
    webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: notifires.getbgcolor,
        appBar: CustomAppBars(
          backgroundColor: notifires.getbgcolor,
          title:
          "${"Payment".translate(context)} ${widget.fromBooking == true ? widget.price : ""}",
          titleColor: notifires.getwhiteblackColor,
          onBackButtonPressed: _showBackDialog,
          actions: [
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 4),
                Text(
                  _formatTime(secondsRemaining),
                  style: TextStyle(
                    color: notifires.getwhiteblackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
               initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  useHybridComposition: false,
                ),
              initialUrlRequest: widget.url != null
                  ? URLRequest(url: WebUri(widget.url!))
                  : null,
             onWebViewCreated: (controller) {
                  webViewController = controller;
                  controller.evaluateJavascript(source: """
                    document.addEventListener('focusout', function(e) {
                      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                        setTimeout(function() {
                          e.target.focus();
                        }, 0);
                      }
                    });
                  """);
                },
              onLoadStart: (_, __) => safeSetState(() => isLoading = true),
              onLoadStop: (controller, url) {
                safeSetState(() => isLoading = false);
                handleNavigation(url?.toString() ?? "");
              },
              shouldOverrideUrlLoading: (_, action) async {
                handleNavigation(action.request.url?.toString() ?? "");
                return NavigationActionPolicy.ALLOW;
              },
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
