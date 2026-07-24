import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../../core/extensions/helper/push_notifications.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/bottom_bar_cubit.dart';
import '../../cubits/general_cubit.dart';
 import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../widgets/internet_checkert.dart';
import '../Account/my_account_screen.dart';
import '../Home/item_home_screen.dart';
import '../Payment/finance_screen.dart';
import '../history/history_screen.dart';

class HomeMain extends StatefulWidget {
  final int? initialIndex;
  final String? route;

  const HomeMain({super.key, this.initialIndex, this.route});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain>
    with SingleTickerProviderStateMixin {
    late TabController tabController;

  List<Widget> pages = [
    const ItemHomeScreen(),
    const HistoryScreen(),
    const FinanceMainScreen(isFormHome: true),
    const MyAccountScreen(),
  ];

  late final StreamSubscription bottomBarSubscription;

  @override
  void initState() {
    super.initState();
    getFCMToken();
    showNotification(context);

    if (widget.initialIndex == 0) {
      context.read<BottomBarCubit>().changeTabIndex(0);
    }

    tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex??0,
    );


    bottomBarSubscription =
        context.read<BottomBarCubit>().stream.listen((state) {
      if (!mounted) return;
      if (tabController.index != state.index) {
        tabController.animateTo(state.index);

      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrency(context);
      getUserDataLocallyToHandleTheState(context,isHomePage: true);
      final driverIdUpdated = box.get("driverId") ?? "";
      if (driverIdUpdated.isNotEmpty) {
        driverId = driverIdUpdated;
        context
            .read<UpdateDriverParameterCubit>()
            .updateDriverId(driverId: driverIdUpdated);
        context
            .read<GetDocApprovalStatusCubit>()
            .listenToDocApprovalStatus(driverId: driverIdUpdated);
        context
            .read<GetDriverStatusCubit>()
            .listenDriverStatusStatus(driverId: driverIdUpdated);
        context
            .read<ListenRideRequestCubit>()
            .listenForRideRequests(driverIdUpdated, context: context);
      }
    });
  }

  @override
  void dispose() {
    bottomBarSubscription.cancel();
    tabController.dispose();
    super.dispose();
  }
    late Future<void> _startupBarrier;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectivityWrapper(
        child: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: tabController,
          children: pages,
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: InkWell(
        onTap: () {
          context.read<BottomBarCubit>().changeTabIndex(0);
        },
        child: Container(
          height: 60,
          width: 60,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: whiteColor,
              boxShadow: [
                BoxShadow(
                    color: grey1.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 3,
                    offset: const Offset(0, 4))
              ]),
          child: Center(
            child: Image.asset('assets/images/logos.png',
                height: 60, fit: BoxFit.contain),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BlocBuilder<BottomBarCubit, BottomBarChangeState>(
          builder: (context, state) {
        return BottomAppBar(
          height: 70,
          padding: EdgeInsets.zero,
          surfaceTintColor: notifires.getbgcolor,
          color: notifires.getbgcolor,
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              boxShadow: [
                BoxShadow(
                  color: grey4.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: TabBar(
                onTap: (index) async{
                  context.read<BottomBarCubit>().changeTabIndex(index);
                  if(index==0){

                    final driverIdUpdated =
                        box.get("driverId") ?? loginModel?.data?.fireStoreId ?? "";

                    _startupBarrier = checkAndCleanRideOnStartup(driverId: driverIdUpdated);

                    await _startupBarrier;
                  }
                },
                labelPadding: const EdgeInsets.all(0),
                indicatorColor: Colors.transparent,
                controller: tabController,
                tabs: [
                  Tab(
                    height: 55,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          SvgPicture.asset(
                            'assets/images/Home_icon.svg',
                            height: 22,
                            // ignore: deprecated_member_use
                            color: state.index == 0 ? blackColor : grey3,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Home".translate(context),
                            style: headingBlack(context).copyWith(
                                fontSize: 14,
                                color: state.index == 0 ? blackColor : grey3),
                          )
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 55,
                    child: Padding(
                      padding:
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? const EdgeInsets.only(
                                  left: 30) // Apply padding for Arabic
                              : const EdgeInsets.only(right: 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          SvgPicture.asset(
                            'assets/images/doc_icon.svg',
                            height: 22,
                            // ignore: deprecated_member_use
                            color: state.index == 1 ? blackColor : grey3,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "History".translate(context),
                            style: headingBlack(context).copyWith(
                                fontSize: 14,
                                color: state.index == 1 ? blackColor : grey3),
                          )
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 55,
                    child: Padding(
                      padding:
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? const EdgeInsets.only(
                                  right: 30) // Apply padding for Arabic
                              : const EdgeInsets.only(left: 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          SvgPicture.asset(
                            'assets/images/wallet_icon.svg',
                            height: 22,
                            // ignore: deprecated_member_use
                            color: state.index == 2 ? blackColor : grey3,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Finance".translate(context),
                            style: headingBlack(context).copyWith(
                                fontSize: 14,
                                color: state.index == 2 ? blackColor : grey3),
                          )
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 55,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          SvgPicture.asset(
                            'assets/images/profile_icon.svg',
                            height: 22,
                            // ignore: deprecated_member_use
                            color: state.index == 3 ? blackColor : grey3,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Account".translate(context),
                            style: headingBlack(context).copyWith(
                                fontSize: 14,
                                color: state.index == 3 ? blackColor : grey3),
                          )
                        ],
                      ),
                    ),
                  ),
                ]),
          ),
        );
      }),
    );
  }
}

void getCurrency(BuildContext context) {
  context.read<GeneralCubit>().fetchGeneralSetting(context);
}
