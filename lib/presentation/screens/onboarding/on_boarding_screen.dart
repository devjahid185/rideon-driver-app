import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../Splash/allow_location_screen.dart';

class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen({super.key});
  @override
  State<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends State<Onboardingscreen> {
  List content = [
    {
      "image": "assets/images/onBoarding1.png",
      "title": "Register Vehicle",
      "description":
          "Let's get you started by registering \n your vehicle on Amar!"
    },
    {
      "image": "assets/images/onBoarding2.png",
      "title": "Upload Documents",
      "description":
          "We would like to get to know you better. Let’s get \n some documents uploaded!"
    },
    {
      "image": "assets/images/onBoarding3.png",
      "title": "Earn Money",
      "description": "Click below and start making money!"
    }
  ];

  late PageController pageController;
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      body: Stack(
        children: [

          Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset("assets/images/EllipseTop.svg",)),
          Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset("assets/images/topEllipse.svg",)),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 150,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                      controller: pageController,
                      scrollDirection: Axis.horizontal,
                      onPageChanged: (int index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemCount: content.length,
                      itemBuilder: (context, index) {
                        return customOnboardingWidget(
                          context: context,
                          image: content[index]["image"],
                          title: content[index]["title"]
                              .toString()
                              .translate(context),
                          description: content[index]["description"]
                              .toString()
                              .translate(context),
                        );
                      }),
                ),
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        height: 12,
                        width: currentIndex == 0 ? 45 : 12,
                        decoration: BoxDecoration(
                            color: currentIndex == 0
                                ? themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeColor)),
                        duration: const Duration(milliseconds: 200),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      AnimatedContainer(
                        height: 12,
                        width: currentIndex == 1 ? 45 : 12,
                        decoration: BoxDecoration(
                            color: currentIndex == 1
                                ? themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeColor)),
                        duration: const Duration(milliseconds: 200),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      AnimatedContainer(
                        height: 12,
                        width: currentIndex == 2 ? 45 : 12,
                        decoration: BoxDecoration(
                            color: currentIndex == 2
                                ? themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeColor)),
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: CustomsButtons(
                      text: currentIndex == 0 ? "Get Started" : "Next",
                      textColor: blackColor,
                      backgroundColor: themeColor,
                      onPressed: () {
                        setState(() {
                          if (currentIndex == 0) {
                            currentIndex = 1;
                            pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.fastLinearToSlowEaseIn);
                          }
                          if (currentIndex == 1) {
                            currentIndex = 2;
                            pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.fastLinearToSlowEaseIn);
                          } else {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const AllowLocationScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  var begin = const Offset(1.0, 0.0);
                                  var end = Offset.zero;
                                  var curve = Curves.ease;
                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        });
                      }),
                ),
                const SizedBox(
                  height: 7,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget customOnboardingWidget({
  BuildContext? context,
  String? image,
  String? title,
  String? description,
}) {
  return Column(
    children: [
      const SizedBox(height: 20),
      Text(
        title!,
        style: regularBlack(context!)
            .copyWith(color: notifires.getGrey1whiteColor, fontSize: 24,fontWeight: FontWeight.w600),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          description!,
          style: regular(context).copyWith(color: notifires.getGrey1whiteColor),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 40),
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20, left:30,right:30),
        child: Container(
            padding: const EdgeInsets.only(top: 0, bottom: 30, left: 0,right: 0),
            child: Image.asset(image!)),
      ),
      const SizedBox(
        height: 20,
      ),
    ],
  );
}
