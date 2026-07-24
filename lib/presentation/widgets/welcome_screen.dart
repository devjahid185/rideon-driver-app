import 'package:flutter/material.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../screens/bottom_bar/home_main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: whiteColor,
        surfaceTintColor: whiteColor,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              Image.asset("assets/images/wellcomeImg.png"),
              const SizedBox(height: 15),
              Text("Congratulation".translate(context),
                  style: headingBlackBold(context).copyWith(fontSize: 20)),
              const SizedBox(height: 10),
              Text(
                textAlign: TextAlign.center,
                "Your document uploaded successfully ! Your document is pending approval, please wait.."
                    .translate(context),
                style: regularBlack(context).copyWith(fontSize: 14),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: CustomsButtons(
            textColor: blackColor,
            text: "${"Go to Home".translate(context)} >",
            backgroundColor: themeColor,
            onPressed: () {

              goToWithClear(const HomeMain(initialIndex: 0, ));

            }),
      ),
    );
  }
}
