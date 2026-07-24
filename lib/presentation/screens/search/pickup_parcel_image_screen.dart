import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_on_driver/core/utils/common_widget.dart';
import 'package:ride_on_driver/core/utils/theme/project_color.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/Search/otp_verify_ride_screen.dart';

class ParcelImageScreen extends StatefulWidget {
  final String bookingId, userName;
  const ParcelImageScreen(
      {super.key, required this.bookingId, required this.userName});

  @override
  State<ParcelImageScreen> createState() => _ParcelImageScreenState();
}

class _ParcelImageScreenState extends State<ParcelImageScreen> {
  final ImagePicker picker = ImagePicker();

  List<File> pickedImages = [];
  List<String> base64Images = [];

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (file != null) {
      final imageFile = File(file.path);
      final base64 = await compressAndUploadImage(file.path);

      setState(() {
        pickedImages.add(imageFile);
        base64Images.add(base64);
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      pickedImages.removeAt(index);
      base64Images.removeAt(index);
    });
  }

  bool get isContinueEnabled => pickedImages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInstructionCard(),
                    const SizedBox(height: 20),
                    _buildImagePreviewSection(),
                    const SizedBox(height: 12),
                    _buildMandatoryNote(),
                    const SizedBox(height: 24),
                    _buildTipsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomButtonBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 6)
      ]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: grey6, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Parcel Photos".translate(context),
                style: heading1(context).copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
            Text("${"Booking".translate(context)}: ${widget.bookingId}",
                style: regular(context).copyWith(fontSize: 11, color: grey2)),
          ]),
          const Spacer(),
          Text("${pickedImages.length}/2 ${"added".translate(context)}",
              style: regular(context).copyWith(fontSize: 12, color: themeColor)),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: themeColor.withValues(alpha:.07),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.camera_alt_outlined, color: themeColor, size: 20),
          const SizedBox(width: 10),
            Expanded(
            child: Text(
              "Please upload at least 1 clear parcel photo. You can add maximum 2 photos.".translate(context)
              ,
              style: regular(context).copyWith(
                  fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMandatoryNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha:0.4)),
      ),
      child: Row(
        children:   [
          const Icon(Icons.info_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Parcel image is mandatory. You cannot continue without uploading at least one image.".translate(context),
              style: regular(context).copyWith(fontSize: 12, color: Colors.red, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pickedImages.length < 2 ? pickedImages.length + 1 : 2,
      itemBuilder: (context, index) {
        if (index < pickedImages.length) return _buildImageContainer(index);
        return _buildAddImageSlot();
      },
    );
  }

  Widget _buildImageContainer(int index) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(pickedImages[index],
            fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: () => removeImage(index),
          child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white)),
        ),
      ),
      if (index == 0)
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.6),
                borderRadius: BorderRadius.circular(6)),
            child: const Text("Mandatory",
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
    ]);
  }

  Widget _buildAddImageSlot() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        decoration: BoxDecoration(
            color: grey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grey3)),
        child: const Center(child: Icon(Icons.add_a_photo_outlined, size: 26)),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:.04), blurRadius: 6)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Quick tips".translate(context), style: regular(context).copyWith(color: blackColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text("• Good lighting\n• Show labels if any\n• Avoid blur".translate(context),
            style: regular(context).copyWith(fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _buildBottomButtonBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha:.08),
            blurRadius: 6,
            offset: const Offset(0, -2))
      ]),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isContinueEnabled
              ? () {
                  goToWithReplacement(
                    OtpVerifyRideScreen(
                      bookingId: widget.bookingId,
                      userName: widget.userName,
                      image1: base64Images.isNotEmpty ? base64Images[0] : "",
                      image2: base64Images.length > 1 ? base64Images[1] : "",
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            disabledBackgroundColor: themeColor.withValues(alpha:0.4),
            foregroundColor: whiteColor,
            disabledForegroundColor: whiteColor.withValues(alpha: .75),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:   Text("Continue".translate(context),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,color: whiteColor)),
        ),
      ),
    );
  }
}
