import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/services/data_store.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/cubits/general_cubit.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/realtime_ride_request.dart';
import '../../cubits/payment/payment_cubit.dart';
import '../../cubits/realtime/listen_ride_request_booking_id_cubit.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../widgets/custome_review_widget.dart';
import '../bottom_bar/home_main.dart';

class PaymentScreen extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  const PaymentScreen({super.key, required this.rideRequest});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = "";
  String totalFare = "";
  String discountFare = "";
  String couponApply = "";

  @override
  void initState() {
    super.initState();
    totalFare = widget.rideRequest.travelCharges ?? "";

    context.read<ListenRideRequestCubit>().resetListenRideRequest();
    context
        .read<GetPaymentStatusAndMethodCubit>()
        .listenToPaymentStatusAndMethod(
          rideId: widget.rideRequest.rideId ?? "",
        );
    context
        .read<GetPaymentAmountCubit>()
        .listenToPaymentAmount(
          rideId: widget.rideRequest.rideId ?? "",
        );
  }

  void _onProceed(BuildContext context, PaymentMethod? method) {
    if (method == null) {
      showErrorToastMessage("Please select a payment method");
      return;
    }

    if (method == PaymentMethod.cash) {
      _showConfirmationDialog(context, "cash",
          "Has the payment been received by cash? If yes, click to proceed.");
    } else if (method == PaymentMethod.online) {
      _showConfirmationDialog(context, "online",
          "Are you sure you want to confirm that you’ve received this payment online?");
    }
  }

  void _showConfirmationDialog(
      BuildContext context, String method, String text) {
    showDialog(
      context: context,
      builder: (_) => PaymentConfirmationDialogs(
        onPressed: () async {
          Navigator.pop(context);
          final bookingId =
              context.read<UpdateDriverParameterCubit>().state.bookingId;

          if (method == "cash") {
            await context
                .read<UpdatePaymentStatusByDriverCubit>()
                .updatePaymentStatusByDriver(
                  context: context,
                  bookingId: widget.rideRequest.bookingId!.isEmpty
                      ? bookingId
                      : widget.rideRequest.bookingId!,
                  paymentMethod: method,
                );
          } else {
            final rideId = widget.rideRequest.rideId;

            completeRide(driverId: driverId, rideId: rideId ?? "");

            try {
              await FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(driverId)
                  .update({'ride_request': {}, 'rideStatus': 'available'});
              clearDriverData(context);

              goToWithClear(const HomeMain(
                initialIndex: 0,
              ));
            } catch (e) {
              // print('Error updating driver status: $e');
            }
          }
        },
        text: text,
      ),
    );
    setState(() {
      paymentMethod = method;
    });
  }

  Future<void> _completeRideProcess(BuildContext context) async {
    final rideId = widget.rideRequest.rideId;
    completeRide(driverId: driverId, rideId: rideId ?? "");
    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({'ride_request': {}, 'rideStatus': 'available'});
    } catch (e) {
      //
    }

    if (isOpenBottomsheet) return;

    isOpenBottomsheet = true;
    clearDriverData(context);
    // ignore_for_file: use_build_context_synchronously
    showModalBottomSheet(
      barrierColor: blackColor.withAlpha(64),
      elevation: 0,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomReviewWidget(
        rideRequest: widget.rideRequest,
      ),
    );
  }

  bool isOpenBottomsheet = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: CustomAppBar(
          title: "Trip Summary",
          onBackTap: () async {
            if (paymentMethod == "cash") {
              _onProceed(context, PaymentMethod.cash);
            } else {
              _onProceed(context, PaymentMethod.online);
            }
          },
        ),
        body: BlocListener<GetPaymentStatusAndMethodCubit, Map<String, String>>(
          listener: (context, state) async {

             setState(()=>  
              paymentMethod = state["paymentMethod"] ?? "");
               
            if (state["paymentStatus"] == "collected") {
              await _completeRideProcess(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<PaymentCubit, PaymentMethod?>(
              builder: (context, selectedMethod) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCustomerInfo(context),
                    const SizedBox(height: 20),
                    BlocConsumer<UpdatePaymentStatusByDriverCubit,
                        UpdatePaymentStatusByDriverState>(
                      builder: (context, state) {
                        return _buildActionButton(context, selectedMethod);
                      },
                      listener: (context, state) async {
                        if (state is UpdatePaymentLoading) {
                          Widgets.showLoader(context);
                        }
                        if (state is UpdatePaymentSuceess) {
                          Widgets.hideLoder(context);
                          context
                              .read<GetListenRideRequestBookingIdCubit>()
                              .updatePaymentStatus(
                                rideId: widget.rideRequest.rideId ?? "",
                                newStatus: "collected",
                              );
                          await _completeRideProcess(context);
                        } else if (state is UpdatePaymentFailure) {
                          Widgets.hideLoder(context);
                          showErrorToastMessage(state.paymentMessage ?? "");
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            height: 60,
            width: 60,
            child: myNetworkImage(widget.rideRequest.customer?.userPhoto ?? ""),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        InkWell(
          onTap: () {
            launchDialPad(
                "${widget.rideRequest.customer?.userPhoneCountry} ${widget.rideRequest.customer?.userPhone}");
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call, size: 16, color: themeColor),
              const SizedBox(width: 8),
              Text(
                  "${widget.rideRequest.customer?.userPhoneCountry ?? ""} ${widget.rideRequest.customer?.userPhone ?? ""}",
                  style: regular(context)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildStatusTag(context),
        const SizedBox(height: 15),
        Text(
          "${"Please collect fare from".translate(context)} \n ${widget.rideRequest.customer?.userName ?? ""}.",
          style: heading3Grey1(context).copyWith(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Divider(color: grey5),
        const SizedBox(height: 30),
        _buildLocationDetails(context),
        const SizedBox(height: 20),
       BlocBuilder<GeneralCubit, GeneralState>(
  builder: (context, state) {
    return BlocListener<GetPaymentAmountCubit, Map<String, String>>(
      listener: (context, paymentState) async {
        totalFare = paymentState["totalFare"] ?? "0";
        couponApply = paymentState["couponApply"] ?? "no";
        discountFare = paymentState["discountFare"] ?? "0";
        setState(() {});
      },
      child: 
     couponApply=="yes"? Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Payment Summary".translate(context),
        style: headingBlack(context).copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),

      // TOTAL FARE
      _itemRow(
        context,
        title: "Total Fare".translate(context),
        value: "${box.get("currency") ?? currency} ${(double.tryParse(totalFare) ?? 0) + (double.tryParse(discountFare) ?? 0)}",
        titleColor: Colors.black87,
        valueColor: Colors.black,
        boldValue: true,
      ),

      const SizedBox(height: 6),

      // COUPON SECTION ONLY IF APPLIED
      if (couponApply == "yes")
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha:       .06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    "Coupon Applied".translate(context),
                    style: regular(context).copyWith(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "-${box.get("currency") ?? currency} $discountFare",
                    style: regular(context).copyWith(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "(${"Paid by Admin".translate(context)})",
                    style: regular(context).copyWith(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

      const SizedBox(height: 8),

      // FINAL FARE
      Divider(color: Colors.grey.shade300, thickness: 1),

      const SizedBox(height: 8),

      _itemRow(
        context,
        title: "Final Fare".translate(context),
        value: "${box.get("currency") ?? currency} ${(double.tryParse(totalFare) ?? 0)}",
        titleColor: Colors.black87,
        valueColor: greentext,
        boldValue: true,
      ),
    ],
  ),
):Text("${box.get("currency") ?? currency} $totalFare",style: heading1Grey1(context).copyWith(color: greentext),),
    );
  },
)
      ],
    );
  }

  Widget _buildStatusTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: greentext,
        border: Border.all(color: greentext),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: whiteColor, size: 18),
          const SizedBox(width: 10),
          Text("RIDE COMPLETE".translate(context),
              style: regular(context)
                  .copyWith(color: whiteColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  size: 20,
                  color: Colors.green,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade200, Colors.red.shade200],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pickup".translate(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rideRequest.pickupLocation?.pickupAddress ?? "",
                  style: heading3Grey1(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 20),
                Text(
                  "Drop".translate(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rideRequest.dropoffLocation?.dropoffAddress ?? "",
                  style: heading3Grey1(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, PaymentMethod? selectedMethod) {
    if (paymentMethod == "cash" || paymentMethod == "") {
      return CustomsButtons(
        textColor: blackColor,
        backgroundColor: themeColor,
        onPressed: () => _onProceed(context, selectedMethod),
        text: "Collect",
      );
    } else {
      return CustomsButtons(
        textColor: blackColor,
        backgroundColor: themeColor,
        onPressed: () {},
        text: "Waiting for payment...",
      );
    }
  }
  Widget _itemRow(
  BuildContext context, {
  required String title,
  required String value,
  Color titleColor = Colors.black,
  Color valueColor = Colors.black,
  bool boldValue = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: regular(context).copyWith(
          fontSize: 14,
          color: titleColor,
        ),
      ),
      Text(
        value,
        style: headingBlack(context).copyWith(
          fontSize: 16,
          color: valueColor,
          fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}
}
