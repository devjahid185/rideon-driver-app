
import 'package:flutter/material.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, String>> notifications = [
    {"type": "System", "message": "Your booking #5445 has been successful."},
    {"type": "Promotion", "message": "Invite friends - Get 3 coupons each!"},
    {"type": "System", "message": "Thank You! Your transaction is complete."},
    {"type": "Promotion", "message": "Invite friends - Get 3 coupons each!"},
    {"type": "System", "message": "Your booking #5445 has been successful."},
    {"type": "Promotion", "message": "Invite friends - Get 3 coupons each!"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(
        title: "Notifications",
        onBackTap: () {
          goBack();
        },
      ),
      body: Column(children: [
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: grey5,
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification["type"]!,
                            style: headingBlackBold(context)
                                .copyWith(fontSize: 18),
                            softWrap: true,
                          ),
                          Text(
                            notification["message"]!,
                            style: regularBlack(context).copyWith(fontSize: 14),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ),
      ]),
    );
  }
}
