import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/domain/entities/realtime_ride_request.dart';
import 'package:ride_on_driver/presentation/screens/payment/payment_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/realtime/ride_status_cubit.dart';

class DropOtpVerifyRideScreen extends StatefulWidget {
  final String bookingId, userName, totalTime;
  final RealTimeRideRequest realTimeRideRequest;

  const DropOtpVerifyRideScreen({
    super.key,
    required this.bookingId,
    required this.userName,
    required this.totalTime,
    required this.realTimeRideRequest,
  });

  @override
  State<DropOtpVerifyRideScreen> createState() =>
      _DropOtpVerifyRideScreenState();
}

class _DropOtpVerifyRideScreenState extends State<DropOtpVerifyRideScreen> {
  final TextEditingController otpController = TextEditingController();
  RealTimeRideRequest? model;

  @override
  void initState() {
    super.initState();
    context.read<BookRideConfirmOtpCubit>().resetState();

    final rideId = context.read<UpdateDriverParameterCubit>().state.rideId;

    context.read<UpdateBookingIdCubit>().updateBookingId(rideId: rideId);
    context
        .read<GetRideRequestStatusCubit>()
        .listenToRouteStatus(rideId: rideId);
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar:   CustomAppBar(
        title: "Drop OTP Verification".translate(context),
        isCenterTitle: true,
        onBackTap: goBack,
      ),
      body: BlocBuilder<GetRideDataCubit, GetRideDataState>(
        builder: (context, state) {
          if (state is UpdatedGetRideDataDropSuccess) {
            model = state.requestDataModel;

            context
                .read<UpdateRideStatusInDatabaseCubit>()
                .updateCompleteRideStatus(
                  context: context,
                  bookingId: widget.bookingId,
                  rideStatus: "Completed",
                  json: jsonEncode(model?.toJson()),
                  dropOtp: otpController.text,
                  totalTime: widget.totalTime,
                );

            context.read<GetRideDataCubit>().clear();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRideHeader(context),
                const SizedBox(height: 20),
                _buildOtpCard(context),
                const SizedBox(height: 20),
                _buildReceiverCard(context),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

 
  Widget _buildRideHeader(BuildContext context) {
    final rideId = context.read<UpdateDriverParameterCubit>().state.rideId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: themeColor.withValues(alpha: .1)),
      child: Row(
        children: [
         
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withValues(alpha: .6)],
              ),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),

          const SizedBox(width: 12),

      
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "order id".translate(context),
                  style: regular(context).copyWith(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rideId.isNotEmpty ? rideId : "---",
                  style: headingBlack(context).copyWith(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Right: User info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.person, size: 16, color: themeColor),
              const SizedBox(height: 2),
              Text(
                widget.userName,
                style: regular(context).copyWith(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _sectionTitle("Enter Drop OTP", Icons.lock_outline),
          const SizedBox(height: 10),
          Text(
            "Ask the receiver for the OTP to complete the ride"
                .translate(context),
            style: regular(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: themeColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Do not complete the ride without verifying OTP from receiver".translate(context),
                    style: regular(context).copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Pinput(
              controller: otpController,
              length: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              defaultPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: headingBlack(context).copyWith(fontSize: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: grey4),
                ),
              ),
              submittedPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: headingBlack(context).copyWith(fontSize: 20),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor, width: 2),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: headingBlack(context).copyWith(fontSize: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverCard(BuildContext context) {
    final parcel = widget.realTimeRideRequest.parcalData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Receiver Details".translate(context), Icons.person_outline),
          const SizedBox(height: 10),
          _infoTile(Icons.person, "Name", parcel?.reciverName ?? "-"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                    Icons.phone, "Phone", parcel?.reciverNumber ?? "-"),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _makePhoneCall(parcel?.reciverNumber ?? ""),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColor.withValues(alpha: .7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoTile(
              Icons.scale, "Parcel Weight", "${parcel?.weight} Kg"),
          const SizedBox(height: 10),
          _infoTile(
            Icons.notes,
            "Instructions",
            parcel?.instruction?.isNotEmpty == true
                ? parcel!.instruction!
                : "None",
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    await launchUrl(launchUri);
  }

  Widget _buildBottomBar(BuildContext context) {
    return BlocConsumer<UpdateRideStatusInDatabaseCubit,
        UpdateRideStatusInDatabaseState>(
      listener: (context, state) {
        if (state is UpdatedRideStatusLoading) {
          Widgets.showLoader(context);
        }

        if (state is CompleteRideStatusSuceessUpdated) {
          Widgets.hideLoder(context);
          box.delete("ride_id");

          context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
                rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
                newStatus: "completed",
              );

          goTo(PaymentScreen(rideRequest: widget.realTimeRideRequest));
        }

        if (state is CompleteRideStatusError) {
          Widgets.hideLoder(context);
          showErrorToastMessage(state.error ?? "An error occurred.");
        }
      },
      builder: (context, state) {
        final isEnabled = otpController.text.length == 4;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? themeColor : grey4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isEnabled
                  ? () {
                      context.read<BookRideConfirmOtpCubit>().resetState();
                      context
                          .read<GetRideDataCubit>()
                          .fetchUpdatedRideDataForDrop(
                            widget.realTimeRideRequest.rideId?.toString() ?? "",
                          );
                    }
                  : null,
              child: Text(
                "Complete Ride".translate(context),
                style: headingBlack(context).copyWith(
                    color: isEnabled ? blackColor : grey3, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }

 
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: themeColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(title.translate(context), style: headingBlack(context).copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.translate(context),
                    style:
                        regular(context).copyWith(fontSize: 12, color: grey2)),
                const SizedBox(height: 2),
                Text(value,
                    style: headingBlack(context).copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
