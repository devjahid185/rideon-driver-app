import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/realtime/ride_status_cubit.dart';
import '../bottom_bar/home_main.dart';

class OtpVerifyRideScreen extends StatefulWidget {
  final String bookingId, userName, image1, image2;
  const OtpVerifyRideScreen(
      {super.key,
      required this.bookingId,
      required this.userName,
      this.image1 = "",
      this.image2 = ""});

  @override
  State<OtpVerifyRideScreen> createState() => _OtpVerifyRideScreenState();
}

class _OtpVerifyRideScreenState extends State<OtpVerifyRideScreen> {
  TextEditingController textEditingOtpConfirmationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BookRideConfirmOtpCubit>().resetState();
    context.read<UpdateBookingIdCubit>().updateBookingId(
        rideId: context.read<UpdateDriverParameterCubit>().state.rideId);
    context.read<GetRideRequestStatusCubit>().listenToRouteStatus(
        rideId: context.read<UpdateDriverParameterCubit>().state.rideId);
  }

  bool isShowPopUp = false;
  final defaultPinTheme = PinTheme(
    width: 60,
    height: 60,
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black, // Adjust based on theme
    ),
    decoration: BoxDecoration(
      color: whiteColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: notifires.getblackwhiteColor, width: 1.5),
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBar(
        isCenterTitle: false,
        title: "Caption",
        onBackTap: () {
          goBack();
        },
      ),
      body:  BlocListener<GetRideRequestStatusCubit, String>(
                      listener: (context, status) {
                        if (status == "cancelled") {
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (ModalRoute.of(context)?.isCurrent == true && !isShowPopUp) {
                    isShowPopUp = true;
                      box.delete("ride_id");
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PopScope(
                        canPop: false,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                          title: Column(
                            children: [
                              const Icon(Icons.cancel,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                "Ride Cancelled".translate(context),
                                textAlign: TextAlign.center,
                                style: heading2Grey1(context),
                              ),
                            ],
                          ),
                          content: Text(
                            "The rider has cancelled the ride request.\n\nYou can head back to the home screen and wait for another ride."
                                .translate(context),
                            textAlign: TextAlign.center,
                            style: regular2(context),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            InkWell(
                              onTap: () {
                                box.delete("ride_id");
                                goToWithClear(const HomeMain(initialIndex: 0));

                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.home, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Go Home".translate(context),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                });
                          return;
                        }
                        
                      },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: themeColor.withValues(alpha: .4)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          "${"Order ID".translate(context)}:${context.read<UpdateDriverParameterCubit>().state.rideId.isNotEmpty ? context.read<UpdateDriverParameterCubit>().state.rideId : " DR3040539495944"}",
                          style: headingBlack(context)
                              .copyWith(color: blackColor)),
                      Text(widget.userName,
                          style: headingBlack(context)
                              .copyWith(color: blackColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: notifires.getbgcolor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Enter Verification Code".translate(context),
                        style: headingBlack(context).copyWith(fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Pinput(
                          onChanged: (v){
                            setState(() {

                            });
                          },
                          controller: textEditingOtpConfirmationController,
                          keyboardType: TextInputType.number,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          length: 4,
                          defaultPinTheme: PinTheme(
                            width: 60,
                            height: 60,
                            textStyle:
                                headingBlack(context).copyWith(fontSize: 20),
                            decoration: BoxDecoration(
                              color: grey5,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: grey4, width: 1),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 60,
                            height: 60,
                            textStyle:
                                headingBlack(context).copyWith(fontSize: 20),
                            decoration: BoxDecoration(
                              color: grey5,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: blackColor, width: 1.5),
                            ),
                          ),
                          submittedPinTheme: PinTheme(
                            width: 60,
                            height: 60,
                            textStyle:
                                headingBlack(context).copyWith(fontSize: 20,color: whiteColor),
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: themeColor, width: 1.5),
                            ),
                          ),
                          errorPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Please ask customer for OTP".translate(context),
                        style: regular(context),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child:
                BlocConsumer<BookRideConfirmOtpCubit, BookRideConfirmOtpState>(
                    builder: (context, state) {
              if (state is BookRideConfirmOtpSuccess) {
                context.read<RideStatusCubit>().removeRideArrivedStatus();
                context
                    .read<RideStatusCubit>()
                    .updateRideArrivedStatus(rideArrivedStatus: true);
                context
                    .read<UpdateRideRequestCubit>()
                    .updatePendingRideRequests(
                        rideId: context
                            .read<UpdateDriverParameterCubit>()
                            .state
                            .rideId,
                        newStatus: "confirmed");
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: BlocBuilder<UpdateBookingIdCubit, String>(
                    builder: (context, bookingId) {
                  return CustomsButtons(
                      text: "Verify",
                      textColor: textEditingOtpConfirmationController
                          .text.length==4? blackColor:grey6,
                      backgroundColor: textEditingOtpConfirmationController
                          .text.length==4?themeColor:grey4,
                      onPressed: () async {
                        context.read<BookRideConfirmOtpCubit>().resetState();

                        if(textEditingOtpConfirmationController.text.isEmpty){
                          showErrorToastMessage("Please enter the OTP.");
                          return;
                        }
                        if( bookingId.isEmpty){


                          var newBookingId= await context.read<UpdateBookingIdCubit>().getBookingId(rideId: context.read<UpdateDriverParameterCubit>().state.rideId);
                         // ignore_for_file: use_build_context_synchronously

                          context.read<UpdateDriverParameterCubit>().updateBookingId(bookingId: newBookingId.toString());
                          if (newBookingId.toString().isNotEmpty &&
                              textEditingOtpConfirmationController
                                  .text.isNotEmpty) {
                            context
                                .read<BookRideConfirmOtpCubit>()
                                .confirmBookRideOtp(
                                context: context,
                                pickupOtp:
                                textEditingOtpConfirmationController.text
                                    .toString(),
                                     deliveryImage1: widget.image1,
                                    deliveryImage2: widget.image2,
                                bookingId: newBookingId.toString());
                          }

                          return;
                        }
                        if (bookingId.isNotEmpty ) {
                          context
                              .read<BookRideConfirmOtpCubit>()
                              .confirmBookRideOtp(
                                  context: context,
                                  pickupOtp:
                                      textEditingOtpConfirmationController.text
                                          .toString(),
                                           deliveryImage1: widget.image1,
                                    deliveryImage2: widget.image2,
                                  bookingId: widget.bookingId.isNotEmpty
                                      ? widget.bookingId
                                      : bookingId);
                        }
                      });
                }),
              );
            }, listener: (context, state) {
              if (state is BookRideConfirmOtpLoading) {
                Widgets.showLoader(context);
              }
              if (state is BookRideConfirmOtpSuccess) {
                context
                    .read<RideStatusCubit>()
                    .updateRideArrivedStatus(rideArrivedStatus: true);
                Widgets.hideLoder(context);

                Navigator.of(context).pop();
              }
              if (state is BookRideConfirmOtpSuccessFailure) {
                isOnDutyArrived = false;
                Widgets.hideLoder(context);
                showErrorToastMessage(state.error??"");
              }
            }),
          ),
        ],
      ),
    );
  }
}
