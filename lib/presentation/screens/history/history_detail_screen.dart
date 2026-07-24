import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/history.dart';
import '../../../domain/entities/realtime_ride_request.dart';

class HistoryDetailScreen extends StatefulWidget {
  final Bookings? rideData;

  const HistoryDetailScreen({super.key, this.rideData});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  static const double _mapHeight = 250;
  static const double _iconSize = 25;
  static const double _statusFontSize = 14;
  static const EdgeInsets _horizontalPadding =
      EdgeInsets.symmetric(horizontal: 25);

  RealTimeRideRequest? bookingRideData;
  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    try {
      Map<String, dynamic> json =
          jsonDecode(widget.rideData!.rideData.toString());
      bookingRideData = RealTimeRideRequest.fromMap(json);

      // ignore: empty_catches
    } catch (e) {}
  }

  String formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return "";

      final inputDate = DateTime.tryParse(dateStr);
      if (inputDate == null) return dateStr;

      final formattedDate = DateFormat("dd MMM yyyy").format(inputDate);
      return formattedDate;
    } catch (e) {
      return dateStr;
    }
  }

  Color getStatusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return greenColor2;
      case 'cancelled':
        return redColor;
      case 'pending':
        return Colors.yellow.shade700;
      default:
        return grey4;
    }
  }

  Color getStatusColor(String status) {
    return status.toLowerCase() == 'completed' ? whiteColor : Colors.black87;
  }

  void copyTokenToClipboard(String? token) {
    if (token != null && token.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: token));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rideData == null) {
      return Scaffold(
        backgroundColor: whiteColor,
        body: Center(
          child: Text(
            "No ride data available".translate(context),
            style: headingBlack(context),
            semanticsLabel: "No ride data available".translate(context),
          ),
        ),
      );
    }

    final rideData = widget.rideData!;

    return Scaffold(
      backgroundColor: whiteColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildMapSection(context, rideData),
            const SizedBox(height: 24),
            buildLocationSection(context, rideData),
            const SizedBox(height: 30),
            bookingRideData != null ? buildRideInfo(context) : const SizedBox(),
            const SizedBox(height: 20),
            bookingRideData != null ? Divider(color: grey5) : const SizedBox(),
            bookingRideData != null
                ? buildDriverInfo(context)
                : const SizedBox(),
            Divider(color: grey5),
            const SizedBox(height: 15),
            buildBillDetailsSection(context, rideData),
          ],
        ),
      ),
    );
  }

  Widget buildRideInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ride Information".translate(context),
            style: heading2(context).copyWith(
              fontSize: 18,
              color: blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          rideInfoItem(
            icon: Icons.access_time,
            title: "Date & Time",
            value: formatTimestamp(bookingRideData?.timestamp ?? ""),
          ),
          Row(
            children: [
              Expanded(
                child: rideInfoItem(
                  icon: Icons.straighten,
                  title: "Distance",
                  value:
                      "${bookingRideData?.totalDistance ?? ""} ${"Km".translate(context)}",
                ),
              ),
              Expanded(
                child: rideInfoItem(
                  icon: Icons.timer,
                  title: "Duration",
                  value:
                      bookingRideData?.totalTime ?? "",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ParcelInfoWidget(
              name: bookingRideData?.parcalData?.name ?? "",
              weight: bookingRideData?.parcalData?.weight ?? "",
              receiverName: bookingRideData?.parcalData?.reciverName ?? "",
              receiverPhone: bookingRideData?.parcalData?.reciverNumber ?? "",
              pickupInstructions:
                  bookingRideData?.parcalData?.instruction ?? ""),
                     if ((widget.rideData?.deliveryPhotos ?? []).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Parcel Images".translate(context),
              style: heading3Grey1(context).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.rideData?.deliveryPhotos?.length ?? 0,
                itemBuilder: (context, index) {
                  String imageUrl =
                      widget.rideData?.deliveryPhotos?[index] ?? "";
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParcelImagePreviewScreen(
                              images: widget.rideData?.deliveryPhotos ?? [],
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: myNetworkImage(
                          imageUrl,
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildDriverInfo(BuildContext context) {
    final rating =
        double.tryParse(widget.rideData?.reviewRating?.toString() ?? "0") ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: myNetworkImage(bookingRideData?.customer?.userPhoto ?? ""),
            ),
          ),
          const SizedBox(width: 16),

          // Driver and vehicle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver name
                Text(
                  bookingRideData?.customer?.userName ?? "",
                  style: heading3Grey1(context)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                ),

                const SizedBox(height: 4),

                // Rating and vehicle number
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      bookingRideData?.customer?.userRating ?? "0.0",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 11),
                  ],
                ),
                const SizedBox(height: 8),

                // Rider feedback
                Row(
                  children: [
                    Text(
                      "${"You Rated".translate(context)} :",
                      style: regular(context),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 18,
                          color:
                              index < rating ? Colors.orange : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMapSection(BuildContext context, Bookings rideData) {
    return Stack(
      children: [
        Image.asset(
          "assets/images/basemap_image.png",
          height: _mapHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          semanticLabel: "Map preview".translate(context),
        ),
        Positioned(
          top: 70,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: _iconSize,
                    color: grey2,
                    semanticLabel: "Back".translate(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: 20,
          child: Text(
            formatDate(rideData.rideDate!),
            style: headingBlackBold(context).copyWith(fontSize: 15),
            semanticsLabel:
                "${"Ride date".translate(context)}: ${formatDate(rideData.rideDate!)}",
          ),
        ),
        Positioned(
          top: 150,
          left: 20,
          child: GestureDetector(
            onTap: () => copyTokenToClipboard(rideData.token),
            child: Row(
              children: [
                Text(
                  rideData.token?.translate(context) ??
                      "N/A".translate(context),
                  style: headingBlackBold(context).copyWith(fontSize: 18),
                  semanticsLabel:
                      "${"Ride token".translate(context)}: ${rideData.token ?? "N/A".translate(context)}",
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: grey2,
                  semanticLabel: "Copy token".translate(context),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: 20,
          child: rideData.status != null && rideData.status!.isNotEmpty
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: getStatusBackground(rideData.status!)),
                    borderRadius: BorderRadius.circular(20),
                    color: getStatusBackground(rideData.status!),
                  ),
                  child: Text(
                    rideData.status!.translate(context),
                    style: headingBlack(context).copyWith(
                      color: getStatusColor(rideData.status!),
                      fontSize: _statusFontSize,
                    ),
                    semanticsLabel:
                        "${"Status".translate(context)}: ${rideData.status}",
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  Widget buildLocationSection(BuildContext context, Bookings rideData) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                Icons.circle,
                color: greenColor2,
                size: 8,
                semanticLabel: "Pickup location marker".translate(context),
              ),
              SvgPicture.asset(
                "assets/images/Line.svg",
                height: 65,
                // ignore: deprecated_member_use
                color: grey4,
                semanticsLabel: "Route line".translate(context),
              ),
              Icon(
                Icons.circle,
                color: redColor,
                size: 8,
                semanticLabel: "DropOff location marker".translate(context),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rideData.pickupLocation?.address ?? "N/A".translate(context),
                  style: headingBlack(context).copyWith(fontSize: 12),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                Text(
                  rideData.dropoffLocation?.address ?? "N/A".translate(context),
                  style: headingBlack(context).copyWith(fontSize: 12),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    String formatted = DateFormat('MMM dd, yyyy – h:mm a').format(dateTime);
    return formatted;
  }

  Widget rideInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.translate(context),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isNonZero(dynamic value) {
    if (value == null) return false;
    try {
      return double.tryParse(value.toString()) != 0.0;
    } catch (_) {
      return false;
    }
  }

  Widget buildBillDetailsSection(BuildContext context, Bookings rideData) {
    return Padding(
      padding: _horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bill Details".translate(context),
            style: headingBlackBold(context).copyWith(fontSize: 16),
            semanticsLabel: "Bill Details section".translate(context),
          ),
          const SizedBox(height: 16),
          if (isNonZero(rideData.basePrice))
            buildBillRow(
              context,
              "Base Fare".translate(context),
              "${rideData.currencyCode ?? ""} ${rideData.basePrice}",
            ),
          if (isNonZero(rideData.basePrice)) const SizedBox(height: 12),
          if (isNonZero(rideData.adminCommission))
            buildBillRow(
              context,
              "Platform Fee".translate(context),
              "${rideData.currencyCode ?? ""} ${rideData.adminCommission}",
            ),
          if (isNonZero(rideData.adminCommission)) const SizedBox(height: 12),
          if (isNonZero(rideData.ivaTax))
            buildBillRow(
              context,
              "Tax".translate(context),
              "${rideData.currencyCode ?? ""} ${rideData.ivaTax}",
            ),
          if (isNonZero(rideData.ivaTax)) const SizedBox(height: 12),
          if (isNonZero(rideData.serviceCharge))
            buildBillRow(
              context,
              "Service Charges".translate(context),
              "${rideData.currencyCode ?? ""} ${rideData.serviceCharge}",
            ),
          if (isNonZero(rideData.serviceCharge)) const SizedBox(height: 12),
          if (isNonZero(rideData.vendorCommission))
            buildBillRow(
              context,
              "Driver Earnings".translate(context),
              "${rideData.currencyCode ?? ""} ${rideData.vendorCommission}",
            ),
          const SizedBox(
            height: 20,
          ),
          rideData.status.toString() == "Completed"
              ? Row(
                  children: [
                    Text(
                      "Payment method".translate(context),
                      style: heading3Grey1(context),
                    ),
                    const Spacer(),
                    Text(
                      rideData.paymentMethod ?? "",
                      style:
                          heading3Grey1(context).copyWith(color: Colors.green),
                    )
                  ],
                )
              : const SizedBox(),
          const SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }

  Widget buildBillRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.translate(context),
          style: regularBlack(context),
          semanticsLabel: label,
        ),
        Text(
          value,
          style: regularBlack(context),
          semanticsLabel: value,
        ),
      ],
    );
  }
}

class ParcelImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ParcelImagePreviewScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ParcelImagePreviewScreen> createState() =>
      _ParcelImagePreviewScreenState();
}

class _ParcelImagePreviewScreenState extends State<ParcelImagePreviewScreen> {
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "${currentIndex + 1}/${widget.images.length}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
        },
        itemBuilder: (context, index) {
          return Center(
            child: Hero(
              tag: "parcel_$index",
              child: InteractiveViewer(
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

