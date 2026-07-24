import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ride_on_driver/core/services/data_store.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/widgets/thanku_screen.dart';
import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../../domain/entities/realtime_ride_request.dart';
import '../cubits/location/get_polyline_cubit.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/realtime/listen_ride_request_cubit.dart';
import '../cubits/realtime/manage_driver_cubit.dart';
import '../cubits/realtime/ride_status_cubit.dart';
import '../cubits/review/review_cubit.dart';
import '../screens/bottom_bar/home_main.dart';
import 'custom_text_form_field.dart';

class CustomReviewWidget extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  const CustomReviewWidget({super.key, required this.rideRequest});
  @override
  State<CustomReviewWidget> createState() => _CustomReviewWidgetState();
}

class _CustomReviewWidgetState extends State<CustomReviewWidget> {
  @override
  void initState() {
    super.initState();
  }

  String ratingData = "";

  TextEditingController textEditingReviewController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.79,
        minChildSize: 0.79,
        maxChildSize: 0.79,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        goToWithClear(const HomeMain(
                          initialIndex: 0,
                        ));
                        clearDriverData(context);

                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              border: Border.all(width: 1, color: blackColor),
                              borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text("Skip".translate(context))),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: ClipOval(
                        child: myNetworkImage(
                            widget.rideRequest.customer?.userPhoto ?? ""),
                      ),
                    )
                  ],
                ),
                Column(children: [
                  Text(widget.rideRequest.customer?.userName ?? "",
                      style: headingBlack(context).copyWith(fontSize: 14)),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(
                        Icons.cable_rounded,
                        color: greentext,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(widget.rideRequest.rideId ?? "",
                          style: regular(context))
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("How was the rider?".translate(context),
                      style: regular2(context).copyWith(
                        fontSize: 16,
                      )),
                  const SizedBox(height: 5),
                  SizedBox(
                      height: 40,
                      child: RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: yelloColor,
                        ),
                        onRatingUpdate: (rating) {
                          final intRating = rating.toInt();

                          ratingData = intRating.toString();
                          setState(() {

                          });
           
                        },
                      )),
                ]),
                const SizedBox(height: 30),
                TextFieldAdvance(
                    maxlines: 5,
                    backgroundColor: grey6,

                    txt: "Add a comment for the rider ...".translate(context),
                    textEditingControllerCommon: textEditingReviewController,
                    inputType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    inputAlignment: TextAlign.start),
                const SizedBox(height: 30),
                const SizedBox(height: 10),
                BlocConsumer<ReviewCubit, ReviewState>(builder: (context, state) {
                  return CustomsButtons(
                      text: "Submit",
                      backgroundColor: ratingData.isEmpty?grey4: themeColor,
                      textColor: ratingData.isEmpty?grey2:blackColor,
                      onPressed: () {
                        if (ratingData.isEmpty) {

                          return;
                        }
                        context.read<ReviewCubit>().submitReview(
                            message: textEditingReviewController.text,
                            context: context,
                            bookingId: context
                                .read<UpdateDriverParameterCubit>()
                                .state
                                .bookingId.isEmpty?widget.rideRequest.bookingId??"":context
                                .read<UpdateDriverParameterCubit>()
                                .state
                                .bookingId,
                            rating: ratingData);
                      });
                }, listener: (context, state) {
                  if (state is ReviewLoading) {
                    Widgets.showLoader(context);
                  }

                  if (state is ReviewSuceess) {
                    Widgets.hideLoder(context);
                   context.read<UpdateDriverParameterCubit>().removeBookingId(bookingId: "");
                    clearDriverData(context);

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>   ThankuScreen(rating: int.parse(ratingData),msg: textEditingReviewController.text,)));
                  }
                  if (state is ReviewFailure) {
                    Widgets.hideLoder(context);
                  }
                }),
                const SizedBox(
                  height: 400,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

void clearDriverData(BuildContext context) {
  box.delete("ride_id");
  context.read<UpdateDriverParameterCubit>().removeDriverDropOffLatAndLng();
  context.read<UpdateDriverParameterCubit>().removeDriverPickupLatAndLng();
  context.read<UpdateDriverParameterCubit>().removeRideId();
  context.read<ListenRideRequestCubit>().resetListenRideRequest();
  context.read<MarkerCubit>().removeMarker();
  context.read<RideStatusCubit>().resetAllParameters();
  context.read<UpdateRideRequestCubit>().resetRideRequestState();
  context.read<UpdateBookingIdCubit>().resetState();
  context.read<GetRideDataCubit>().clear();
  context.read<GetPolylineCubit>().resetPolylines();
  
}
