import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 0.0;
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    controller?.forward();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller!,
                    reverseCurve: Curves.bounceInOut,
                    curve: Curves.easeInCubic,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    commonlyUserLogo(),
                    Text("WGN Move Driver",style: heading1(context).copyWith(color: Colors.black,fontSize: 25),)
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: SvgPicture.asset("assets/images/vector_bottom.svg",colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn),),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SvgPicture.asset("assets/images/vector_top.svg",colorFilter: ColorFilter.mode(themeColor, BlendMode.srcIn)),
        )
      ],
    );
    // );
  }
}
