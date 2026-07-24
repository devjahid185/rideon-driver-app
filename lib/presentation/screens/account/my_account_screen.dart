import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/Account/profile_screen.dart';
import 'package:ride_on_driver/presentation/screens/Account/static_screen.dart';
import 'package:ride_on_driver/presentation/screens/Account/vehicle_information_screen.dart';
import 'package:ride_on_driver/presentation/screens/payment/payment_method_screen.dart';
import '../../../core/extensions/change_language.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/account/update_profile_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/logout_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../Auth/login_screen.dart';
import '../home/food_driver_orders_screen.dart';
import '../Payment/finance_screen.dart';
import '../history/history_screen.dart';
import '../setup_account/edit_driver_document_screen.dart';
import 'faq_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NameCubit>().updateName(loginModel?.data?.firstName ?? "");
      context.read<PhoneCubit>().updatePhone(loginModel?.data?.phone ?? "");
      context.read<MyImageCubit>().updateMyImage(myImage);
            context.read<SetCountryCubit>().setCountry(dialCode: loginModel?.data?.phoneCountry??"", countryCode: loginModel?.data?.defaultCountry??"");

      context.read<UpdateDriverCubit>().updateFirebaseImageUrl(
          driverImageUrl: myImage,
          driverId: context.read<UpdateDriverParameterCubit>().state.driverId);
      context.read<EmailCubit>().updateEmail(loginModel?.data?.email ?? "");
      context
          .read<UpdateDriverParameterCubit>()
          .updateDriverId(driverId: driverId.toString());
    });
    super.initState();
  }

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: notifires.getbgcolor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          surfaceTintColor: notifires.getbgcolor,
          backgroundColor: notifires.getbgcolor,
          title: Text(
            "My Accounts".translate(context),
            style: headingBlack(context).copyWith(fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: grey3.withValues(alpha: .15),
                            blurRadius: 6,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            BlocBuilder<MyImageCubit, dynamic>(
                                builder: (context, state) {
                              return myImage.isEmpty
                                  ? Icon(
                                      CupertinoIcons.profile_circled,
                                      size: 60,
                                      color: blackColor,
                                    )
                                  : SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: ClipOval(
                                        child: myNetworkImage(
                                            context.read<MyImageCubit>().state),
                                      ),
                                    );
                            }),
                            const SizedBox(width: 15),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BlocBuilder<NameCubit, dynamic>(
                                    builder: (context, state) {
                                  return Row(
                                    children: [
                                      Text(context.read<NameCubit>().state,
                                          style: headingBlack(context)
                                              .copyWith(fontSize: 14)),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 5),
                                BlocBuilder<EmailCubit, dynamic>(
                                    builder: (context, state) {
                                  return Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 14),
                                      const SizedBox(width: 5),
                                      Text(context.read<EmailCubit>().state,
                                          style: headingBlack(context)
                                              .copyWith(fontSize: 14)),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 5),
                                BlocBuilder<PhoneCubit, dynamic>(
                                    builder: (context, state) {
                                  return Row(
                                    children: [
                                      const Icon(Icons.call_outlined, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                          "${context.read<SetCountryCubit>().state.dialCode} ${context.read<PhoneCubit>().state}",
                                          style: headingBlack(context)
                                              .copyWith(fontSize: 14)),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ]),
                          InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfile()));
                              },
                              child: ClipOval(
                                child: Container(
                                    color: themeColor,
                                    height: 30,
                                    width: 30,
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    )),
                              ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<DashboardCubit, DashboardState>(
                        builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      state is DashboardSuceess
                                          ? Text("${state.totalRating}",
                                              style: headingBlackBold(context))
                                          : Text("0",
                                              style: headingBlackBold(context)),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Icon(
                                        Icons.star,
                                        color: yelloColor,
                                        size: 20,
                                      )
                                    ],
                                  ),
                                  Text(
                                    "RATING".translate(context),
                                    style: regular(context),
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  state is DashboardSuceess
                                      ? Text("${state.totalOrder}",
                                          style: headingBlackBold(context))
                                      : Text("0",
                                          style: headingBlackBold(context)),
                                  Text(
                                    "ORDERS".translate(context),
                                    style: regular(context),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  state is DashboardSuceess
                                      ? Text(
                                          "$currency ${(double.tryParse(state.totalEarning) ?? 0.0).toStringAsFixed(2)}",
                                          style: headingBlackBold(context),
                                        )
                                      : Text("$currency 0",
                                          style: headingBlackBold(context)),
                                  Text("Earnings".translate(context),
                                      style: regular(context)),
                                ],
                              )
                            ]),
                      );
                    }),
                    const SizedBox(height: 20),
                    Text("QUICK LINKS".translate(context),
                        style: headingBlack(context)),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/ride_history.svg",
                      title: "History",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HistoryScreen(isBackButton: true)));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "",
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Earnings",
                      onTap: () {
                        goTo(const FinanceMainScreen(
                          isFormHome: false,
                        ));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "",
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Payout Options",
                      onTap: () {
                        goTo(const PaymentMethodsScreen(
                          
                        ));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/question-icon 1.svg",
                      title: "FAQ",
                      onTap: () {
                        goTo(const DriverFAQScreen());
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "",
                      icon: Icons.delivery_dining_outlined,
                      title: "Food Orders",
                      onTap: () {
                        goTo(const FoodDriverOrdersScreen());
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "",
                      icon: CupertinoIcons.car,
                      title: "Vehicle's Information",
                      onTap: () {
                        goTo(const VehicleInformationScreen());
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/ride_history.svg",
                      title: "Edit Document",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditDriverDocumentScreen()));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/ride_history.svg",
                      title: "About us",
                      onTap: () {
                        goTo(const StaticScreen(
                          data: "About Us",
                          isBack: true,
                        ));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/question-icon 1.svg",
                      title: "Help and Support",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const StaticScreen(
                                      data: "Help and Support",
                                      isBack: true,
                                    )));
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "assets/images/add_location.svg",
                      title: "Change Language",
                      onTap: () {
                        goTo(const ChangeLanguage());
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomRowAccountItem(
                      imagePath: "",
                      icon: Icons.delete_outline,
                      title: "Delete Account",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const DeleteConfirmationDialogs();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    BlocConsumer<LogoutCubit, LogoutState>(
                      listener: (context, state) {
                        if (state is LogoutFailure) {
                          showErrorToastMessage("Logout Failed: ${state.error}");
                        } else if (state is LogoutSuccess) {
                          box.put('isDocumentStatusShown', false);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()));
                        }
                      },
                      builder: (context, state) {
                        return CustomRowAccountItem(
                          imagePath: "",
                          icon: Icons.logout_outlined,
                          title: "Logout",
                          onTap: () {
                            showDynamicBottomSheets(context,
                                title: "Logout".translate(context),
                                description: "Are you sure You Want to Logout?"
                                    .translate(context),
                                firstButtontxt: "Cancel".translate(context),
                                secondButtontxt: "Yes".translate(context),
                                onpressed: () {
                              Navigator.pop(context);
                            }, onpressed1: () async {
                              token = "";
                              context.read<LogoutCubit>().logout(context);
                              clearData(context);
                               
                            });
                          },
                        );
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Text("${"Version".translate(context)} 1.0.0",style: regular(context),),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomRowAccountItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap; // Add onTap callback
  final IconData? icon;

  const CustomRowAccountItem(
      {super.key,
      required this.imagePath,
      required this.title,
      this.onTap,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: grey3.withValues(alpha: .15),
              blurRadius: 6,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                imagePath.isNotEmpty
                    ? SvgPicture.asset(
                        imagePath,
                        width: 30,
                        height: 30,
                      )
                    : (icon != null
                        ? Icon(icon, size: 30, color: blackColor)
                        : const SizedBox()),
                const SizedBox(width: 10),
                Text(
                  title.translate(context),
                  style: heading3Grey1(context),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_outlined,
              size: 14,
              color: grey4,
            )
          ],
        ),
      ),
    );
  }
}
