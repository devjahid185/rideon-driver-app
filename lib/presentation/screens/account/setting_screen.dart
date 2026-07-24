import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isdark = box.get("getDarkValue") ?? false;

  bool darkMode = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return PopScope(
      canPop: false,

  
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: Dimensions.containerWidth,
          child: Scaffold(
            backgroundColor: notifires.getbgcolor,
            appBar: CustomAppBars(
              onBackButtonPressed: () {
                Navigator.pop(context);
              },
              title: 'Setting'.translate(context),
              backgroundColor: notifires.getbgcolor,
              iconColor: notifires.getwhiteblackColor,
              titleColor: notifires.getwhiteblackColor,
            ),
            body: SingleChildScrollView(
              child: Column(children: [
                Column(
                  children: [
                    const SizedBox(
                      height: 38,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 2),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                            color: notifires.getBoxColor,
                            borderRadius: BorderRadius.circular(13)),
                        alignment: Alignment.center,
                        width: double.maxFinite,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            Icon(
                              Icons.dark_mode_outlined,
                              color: notifires.getGrey3whiteColor,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text("Dark Mode".translate(context),
                                style: regular3(context).copyWith(
                                    color: notifires.getGrey2whiteColor)),
                            const Spacer(),
                            Transform.scale(
                              scale: .8,
                              child: Switch(
                                value: isdark,
                                inactiveTrackColor: grey4,
                                activeTrackColor: acentColor,
                                inactiveThumbColor: Colors.white,
                                trackOutlineColor:
                                    WidgetStateProperty.resolveWith<Color?>(
                                        (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return notifires.getBoxColor;
                                  }
                                  return notifires.getBoxColor;
                                }),
                                onChanged: (value) async {

                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: InkWell(
                    onTap: () {

                    },
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                          color: notifires.getBoxColor,
                          borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      width: double.maxFinite,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                          ),
                          Icon(
                            Icons.password_sharp,
                            color: notifires.getGrey3whiteColor,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(
                            "Change Password".translate(context),
                            style: regular3(context)
                                .copyWith(color: notifires.getGrey2whiteColor),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: notifires.getGrey3whiteColor,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                InkWell(
                  onTap: () async {

                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                          color: notifires.getBoxColor,
                          borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      width: double.maxFinite,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                          ),
                          Icon(
                            Icons.language,
                            color: notifires.getGrey3whiteColor,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(
                            "Change Language".translate(context),
                            style: regular3(context)
                                .copyWith(color: notifires.getGrey2whiteColor),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: notifires.getGrey3whiteColor,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
