import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/core/services/data_store.dart';
import 'package:ride_on_driver/core/utils/common_widget.dart';
 import 'package:ride_on_driver/presentation/cubits/realtime/ride_status_cubit.dart';
import 'package:ride_on_driver/presentation/screens/Splash/splash_screen.dart';
import 'package:ride_on_driver/presentation/screens/bottom_bar/home_main.dart';
import 'package:ride_on_driver/presentation/screens/payment/payment_screen.dart';
import 'package:ride_on_driver/presentation/widgets/custome_review_widget.dart';
import '../../../core/extensions/helper/push_notifications.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/theme/project_color.dart';
import '../Onboarding/on_boarding_screen.dart';
import '../Search/ride_screen.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});
  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    setScreen(context);
  }

  Future<void> setScreen(BuildContext context) async {
    var box = Hive.box('appBox');
    final duration = Duration(
      seconds: box.get('Firstuser', defaultValue: null) == null ? 4 : 0,
    );

    Timer(duration, () async {
      if (box.get('Firstuser', defaultValue: false) != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Onboardingscreen(),
          ),
        );
      } else {
        String? rideId = box.get('ride_id');
        if (rideId == null || rideId.isEmpty) {
          await getUserDataLocallyToHandleTheState(context,isHomePage: false);
          await syncPendingFcmTokenIfAny(forceSync: true);
        } else {
          await getUserDataLocallyToHandleTheState(context,isHomePage: true);
          await syncPendingFcmTokenIfAny(forceSync: true);
          getCurrency(context);
          context.read<GetRideDataCubit>().fetchRideDataForInitial(rideId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return Scaffold(
        backgroundColor: notifires.getbgcolor, body: BlocListener<GetRideDataCubit, GetRideDataState>(
          listener: (context, state) {
            if (state is GetRideDataSuccessForInitial) {

              String rideStatus=state.requestDataModel?.status??"";
              String paymentStatus=state.requestDataModel?.paymentStatus??"";

              if(rideStatus== "completed" &&
                  paymentStatus == ""){
                    goToWithReplacement(PaymentScreen(rideRequest: state.requestDataModel!));
                  }else if(rideStatus== "completed" &&
                  paymentStatus == "collected"){
                    clearDriverData(context);
                    goToWithReplacement( const HomeMain(initialIndex: 0,));
                  }else if(rideStatus=="accepted"||rideStatus=="ongoing"||rideStatus=="pick_up"||rideStatus=="confirmed"){
                    goToWithReplacement( RideScreens(
                rideId: state.requestDataModel?.rideId??box.get('ride_id'),
                fromInitialPage: true,
              ));
                  }else{
                    clearDriverData(context);
                     goToWithReplacement( const HomeMain(initialIndex: 0,));
                  }


              
              
            } else if (state is GetRideDataFailed) {
               clearDriverData(context);

              goToWithReplacement( const HomeMain(initialIndex: 0,));
            }
          },child: const SplashScreen()));
  }
}
