import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/presentation/cubits/localizations_cubit.dart';
 import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ride_on_driver/core/utils/theme/project_color.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../domain/entities/realtime_ride_request.dart';
import '../../presentation/cubits/account/delete_account_cubit.dart';
import '../../presentation/cubits/dashboard/dashboard_cubit.dart';
import '../../presentation/cubits/logout_cubit.dart';
import '../../presentation/cubits/realtime/listen_ride_request_cubit.dart';
import '../../presentation/cubits/realtime/manage_driver_cubit.dart';
import '../../presentation/cubits/realtime/ride_status_cubit.dart';
import '../../presentation/cubits/register_vehicle/make_model_cubit.dart';
import '../../presentation/screens/bottom_bar/home_main.dart';
import '../extensions/workspace.dart';
import '../services/data_store.dart';

Widget commonlyUserLogo() {
  return Image.asset(
    'assets/images/logos.png',
    height: 130,
  );
}

class CustomsButtons extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color backgroundColor;
  final Icon? icon;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color? borderColor;
  final bool? alignment;
  final double? fontSize;

  const CustomsButtons(
      {super.key,
      this.alignment,
      this.fontSize,
      required this.text,
      this.borderColor,
      this.width,
      this.height,
      required this.backgroundColor,
      required this.onPressed,
      this.icon,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    final shouldUseLightForeground =
        backgroundColor == themeColor || backgroundColor.computeLuminance() < .45;
    final effectiveForeground =
        shouldUseLightForeground ? whiteColor : (textColor ?? blackColor);

    return ConstrainedBox(
      constraints: BoxConstraints.expand(
          width: width ?? double.infinity, height: height ?? 55.0),
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
              backgroundColor: backgroundColor,
              foregroundColor: effectiveForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: borderColor ?? Colors.transparent, width: 1),
                  borderRadius: BorderRadius.circular(8))),
          child: Row(
            mainAxisAlignment: alignment == true
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) const SizedBox(width: 10),
              if (icon != null)
                Icon(
                  icon!.icon,
                  color: effectiveForeground,
                  size: icon!.size,
                ),
              const SizedBox(width: 10),
              Text(
                text.translate(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: headingBlackBold(context).copyWith(
                    color: effectiveForeground,
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w400),
              ),
            ],
          )),
    );
  }
}

class CustomAppBars extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color? iconColor;
  final Color titleColor;
  final VoidCallback? onBackButtonPressed;
  final List<Widget>? actions;
  final double elevation;
  final bool? centerTitle;

  const CustomAppBars(
      {super.key,
      required this.title,
      required this.backgroundColor,
      this.iconColor,
      required this.titleColor,
      this.onBackButtonPressed,
      this.actions,
      this.elevation = 0.0,
      this.centerTitle});

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return AppBar(
      centerTitle: true,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: elevation,
      leadingWidth: 85,
      leading: GestureDetector(
        onTap: onBackButtonPressed ??
            () {
              Navigator.pop(context);
            },
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, top: 8, bottom: 8, right: 20),
          child: PhysicalModel(
            color: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 1.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                  color: notifires.getblackwhiteColor,
                  borderRadius: BorderRadius.circular(30)),
              child: Icon(Icons.arrow_back_ios_new,
                  color: notifires.getGrey3whiteColor),
            ),
          ),
        ),
      ),
      title: Text(title.translate(context),
          style: heading2Grey1(context).copyWith(color: titleColor)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class UploadItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUploadPressed;
  final IconData? iconData;
  final String? assetImagePath;

  const UploadItem({
    super.key,
    required this.title,
    this.assetImagePath,
    required this.subtitle,
    this.iconData,
    required this.onUploadPressed,
  });

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onUploadPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: grey5,
              blurRadius: 4.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title.translate(context),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    softWrap: true,
                  ),
                  Text(
                    widget.subtitle.translate(context),
                    style: const TextStyle(color: Colors.grey),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            Image.asset(
              widget.assetImagePath ?? "",
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "assets/images/uploadImg.png",
                  height: 30,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class CustomBottomSheetDriver extends StatefulWidget {
  final VoidCallback onTap;
  final String? title;
  final String? description;
  final String? frontImageUrl;
  final String? backImageUrl;

  const CustomBottomSheetDriver({
    super.key,
    required this.onTap,
    this.title,
    this.description,
    this.frontImageUrl,
    this.backImageUrl,
  });

  @override
  State<CustomBottomSheetDriver> createState() =>
      _CustomBottomSheetDriverState();
}

class _CustomBottomSheetDriverState extends State<CustomBottomSheetDriver> {
  XFile? frontImage;
  XFile? backImage;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  Future<void> _pickImage({
    required Function(XFile, String?) onSelect,
    required ImageSource source,
  }) async {
    try {
      setState(() => isLoading = true);
      final picked = await picker.pickImage(source: source);
      if (picked != null && mounted) {
        final base64String = await compressAndUploadImage(picked.path);
        onSelect(picked, base64String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting photo: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> showPickerDialog(Function(XFile, String?) onSelect) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("Take a Photo".translate(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(onSelect: onSelect, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text("Choose from Gallery".translate(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(onSelect: onSelect, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      snap: true,
      initialChildSize: 0.85,
      minChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title?.translate(context) ??
                                  "Driving License".translate(context),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description?.translate(context) ??
                                  "Please upload both front and back images",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Front License
                  buildImageSection(
                    label: "Front License".translate(context),
                    file: frontImage,
                    fallbackUrl: widget.frontImageUrl,
                    onSelect: (file, base64) {
                      setState(() => frontImage = file);

                      context
                          .read<DriverLicenseImageCubit>()
                          .updateFrontImage(base64 ?? "");
                    },
                    onDelete: () => setState(() => frontImage = null),
                  ),

                  const SizedBox(height: 20),

                  buildImageSection(
                    label: "Back License".translate(context),
                    file: backImage,
                    fallbackUrl: widget.backImageUrl,
                    onSelect: (file, base64) {
                      setState(() => backImage = file);
                      context
                          .read<DriverLicenseImageCubit>()
                          .updateBackImage(base64 ?? "");
                    },
                    onDelete: () => setState(() => backImage = null),
                  ),

                  const SizedBox(height: 80),
                ],
              ),

              // Bottom Upload Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  color: Colors.white,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          ((frontImage != null || backImage != null) &&
                                  ((frontImage != null ||
                                          (widget.frontImageUrl?.isNotEmpty ??
                                              false)) &&
                                      (backImage != null ||
                                          (widget.backImageUrl?.isNotEmpty ??
                                              false))))
                              ? Colors.black
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: ((frontImage != null || backImage != null) &&
                            ((frontImage != null ||
                                    (widget.frontImageUrl?.isNotEmpty ??
                                        false)) &&
                                (backImage != null ||
                                    (widget.backImageUrl?.isNotEmpty ??
                                        false))) &&
                            !isLoading)
                        ? widget.onTap
                        : null,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            "Upload".translate(context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildImageSection({
    required String label,
    required XFile? file,
    required String? fallbackUrl,
    required Function(XFile, String?) onSelect,
    required VoidCallback onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + Change button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (file != null || (fallbackUrl?.isNotEmpty ?? false))
              InkWell(
                onTap: isLoading ? null : () => showPickerDialog(onSelect),
                child: const Text("Change >",
                    style: TextStyle(color: Colors.blue)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Image Container
        GestureDetector(
          onTap: isLoading ? null : () => showPickerDialog(onSelect),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              image: file != null
                  ? DecorationImage(
                      image: FileImage(File(file.path)), fit: BoxFit.contain)
                  : (fallbackUrl?.isNotEmpty ?? false)
                      ? DecorationImage(
                          image: NetworkImage(fallbackUrl!),
                          fit: BoxFit.contain,
                        )
                      : null,
            ),
            child: Stack(
              children: [
                if (file == null && (fallbackUrl?.isEmpty ?? true))
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_rounded,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Tap to upload"),
                      ],
                    ),
                  ),
                if (file != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 18,
                        // ignore: deprecated_member_use
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          onPressed: isLoading ? null : onDelete,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CustomBottomSheetDocument extends StatefulWidget {
  final VoidCallback onTap;
  final String? title;
  final String frontStatus;
  final String backStatus;
  final String? description;
  final String frontLabel;
  final String backLabel;
  final String? frontImageUrl;
  final String? backImageUrl;
  final Function(String base64, bool isFront) onImageUpdate;

  const CustomBottomSheetDocument({
    super.key,
    required this.onTap,
    required this.frontStatus,
    required this.backStatus,
    this.title,
    this.description,
    required this.frontLabel,
    required this.backLabel,
    this.frontImageUrl,
    this.backImageUrl,
    required this.onImageUpdate, // cubit update callback
  });

  @override
  State<CustomBottomSheetDocument> createState() =>
      _CustomBottomSheetDocumentState();
}

class _CustomBottomSheetDocumentState extends State<CustomBottomSheetDocument> {
  XFile? frontImage;
  XFile? backImage;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  Future<void> _pickImage({
    required Function(XFile, String?) onSelect,
    required ImageSource source,
  }) async {
    try {
      setState(() => isLoading = true);
      final picked = await picker.pickImage(source: source);
      if (picked != null && mounted) {
        final base64String = await compressAndUploadImage(picked.path);
        onSelect(picked, base64String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting photo: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> showPickerDialog(Function(XFile, String?) onSelect) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("Take a Photo".translate(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(onSelect: onSelect, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text("Choose from Gallery".translate(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(onSelect: onSelect, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      snap: true,
      initialChildSize: 0.85,
      minChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title?.translate(context) ?? "Document",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.description?.translate(context) ??
                                  "Please upload both front and back images",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Front
                  buildImageSection(
                    label: widget.frontLabel,
                    status: widget.frontStatus,
                    file: frontImage,
                    fallbackUrl: widget.frontImageUrl,
                    onSelect: (file, base64) {
                      setState(() => frontImage = file);
                      widget.onImageUpdate(base64 ?? "", true);
                    },
                    onDelete: () => setState(() => frontImage = null),
                  ),

                  const SizedBox(height: 20),

                  // Back
                  buildImageSection(
                    label: widget.backLabel,
                    status: widget.backStatus,
                    file: backImage,
                    fallbackUrl: widget.backImageUrl,
                    onSelect: (file, base64) {
                      setState(() => backImage = file);
                      widget.onImageUpdate(base64 ?? "", false);
                    },
                    onDelete: () => setState(() => backImage = null),
                  ),

                  const SizedBox(height: 80),
                ],
              ),

              // Bottom Upload Button
              getDocStatus(widget.frontStatus, widget.backStatus) == "approved"
                  ? const SizedBox()
                  : Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        color: Colors.white,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ((frontImage != null ||
                                        backImage != null) &&
                                    ((frontImage != null ||
                                            (widget.frontImageUrl?.isNotEmpty ??
                                                false)) &&
                                        (backImage != null ||
                                            (widget.backImageUrl?.isNotEmpty ??
                                                false))))
                                ? Colors.black
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: ((frontImage != null ||
                                      backImage != null) &&
                                  ((frontImage != null ||
                                          (widget.frontImageUrl?.isNotEmpty ??
                                              false)) &&
                                      (backImage != null ||
                                          (widget.backImageUrl?.isNotEmpty ??
                                              false))) &&
                                  !isLoading)
                              ? widget.onTap
                              : null,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "Upload".translate(context),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget buildImageSection({
    required String label,
    required String status, // "approved" | "pending" | "rejected"
    required XFile? file,
    required String? fallbackUrl,
    required Function(XFile, String?) onSelect,
    required VoidCallback onDelete,
  }) {
    bool isApproved = status.toLowerCase() == "approved";
    bool isRejected = status.toLowerCase() == "rejected";
    bool isPending = status.toLowerCase() == "pending";

    // Dynamic status design
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isApproved) {
      statusIcon = Icons.verified_rounded;
      statusColor = Colors.green.shade600;
      statusText = "Approved";
    } else if (isRejected) {
      statusIcon = Icons.error_rounded;
      statusColor = Colors.red.shade600;
      statusText = "Rejected";
    } else if (isPending) {
      statusIcon = Icons.hourglass_bottom_rounded;
      statusColor = Colors.amber.shade700;
      statusText = "Pending";
    } else {
      statusIcon = Icons.hourglass_bottom_rounded;
      statusColor = Colors.amber.shade700;
      statusText = "";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.translate(context),
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87)),
            if (!isApproved &&
                (file != null || (fallbackUrl?.isNotEmpty ?? false)))
              GestureDetector(
                onTap: isLoading ? null : () => showPickerDialog(onSelect),
                child: Text(
                  "change".translate(context),
                  style: TextStyle(
                      color: Colors.blue.shade600, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: (isApproved || isLoading)
              ? null
              : () => showPickerDialog(onSelect),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              image: file != null
                  ? DecorationImage(
                      image: FileImage(File(file.path)), fit: BoxFit.cover)
                  : (fallbackUrl?.isNotEmpty ?? false)
                      ? DecorationImage(
                          image: NetworkImage(fallbackUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: Stack(
              children: [
                if (file == null && (fallbackUrl?.isEmpty ?? true))
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_rounded,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload".translate(context),
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                if (!isApproved && file != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 20,
                      // ignore: deprecated_member_use
                      backgroundColor: Colors.black.withOpacity(0.55),
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever_rounded,
                            size: 20, color: Colors.white),
                        onPressed: isLoading ? null : onDelete,
                      ),
                    ),
                  ),
                if ((file == null && (fallbackUrl?.isNotEmpty ?? false)) &&
                    statusText.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            statusText.translate(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VehicleInformationShimmer extends StatelessWidget {
  const VehicleInformationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image Card Shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background shimmer
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Overlay content shimmer
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Vehicle Details Title Shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 24,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle Details Grid Shimmer
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: List.generate(6, (index) => _buildDetailCardShimmer()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon shimmer
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Text content shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getDocStatus(String front, String back) {
  if (front == "approved" && back == "approved") {
    return "approved";
  } else if (front == "rejected" || back == "rejected") {
    return "rejected";
  } else if (front == "pending" && back == "pending") {
    return "pending";
  } else {
    return ""; // Default case (ek Approved aur ek Pending)
  }
}

class CustomBottomSheetVechicle extends StatefulWidget {
  final VoidCallback onTap;
  final String? title;
  final String? descrption;
  final String? imageUrl;
  // ignore: non_constant_identifier_names
  final String SourceType;

  const CustomBottomSheetVechicle(
      {super.key,
      required this.onTap,
      // ignore: non_constant_identifier_names
      required this.SourceType,
      this.title,
      this.imageUrl,
      this.descrption});

  @override
  State<CustomBottomSheetVechicle> createState() =>
      _CustomBottomSheetVechicleState();
}

class _CustomBottomSheetVechicleState extends State<CustomBottomSheetVechicle> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.sizeOf(context).height;
    return BlocBuilder<CheckSelectedCubit, bool>(builder: (context, state) {
      return DraggableScrollableSheet(
        snap: false,
        initialChildSize: state == true ? 0.7 : 0.58,
        minChildSize: state == true ? 0.7 : 0.58, // Minimum size (half-open)
        maxChildSize: state == true ? 0.7 : 0.58, // Maximum size (full screen)
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          softWrap: true,
                          textAlign: TextAlign.start,
                          widget.title ?? "",
                          style: regularBlack(context).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          textAlign: TextAlign.start,
                          widget.descrption ?? "",
                          style: regularBlack(context).copyWith(fontSize: 14),
                          softWrap: true,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          goBack();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                BlocBuilder<CheckSelectedCubit, bool>(
                    builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15, bottom: 10),
                    child: InkWell(
                      onTap: () {
                        selectImageWithSource(ImageSource.gallery,
                            context: context,
                            status: "change",
                            imgSource: widget.SourceType);
                      },
                      child:
                          state == true || widget.imageUrl.toString().isNotEmpty
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text("${"change".translate(context)} >",
                                        style: regularBlack(context))
                                  ],
                                )
                              : const SizedBox(),
                    ),
                  );
                }),
                InkWell(
                  onTap: () {
                    selectImageWithSource(ImageSource.gallery,
                        context: context,
                        status: "Add",
                        imgSource: widget.SourceType);
                  },
                  child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          widget.SourceType == "VehicleImg"
                              ? BlocBuilder<UpdateImage, XFile?>(
                                  builder: (context, image) {
                                    if (image == null) {
                                      context
                                          .read<CheckSelectedCubit>()
                                          .checkSelectedValue(false);
                                      return Column(
                                        children: [
                                          widget.imageUrl.toString().isNotEmpty
                                              ? customImageContainer(
                                                  widget.imageUrl ?? "",
                                                  screenHeight / 5)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: grey4,
                                                          width: 2)),
                                                  height: screenHeight / 5,
                                                  width: screenHeight / 5 + 50,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                          Icons.add_outlined,
                                                          size: 30),
                                                      Text(
                                                          "Select file"
                                                              .translate(
                                                                  context),
                                                          style: regular3(
                                                              context)),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      );
                                    }
                                    context
                                        .read<CheckSelectedCubit>()
                                        .checkSelectedValue(true);

                                    return Stack(
                                      children: [
                                        Container(
                                          height: screenHeight / 5,
                                          width: screenHeight / 5 + 50,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: grey4, width: 2)),
                                          child: Image.file(
                                            File(image.path),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return SizedBox(
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                        Icons.error_outline,
                                                        size: 30,
                                                        color: Colors.red),
                                                    Text(
                                                        "Failed to load image"
                                                            .translate(context),
                                                        style:
                                                            regular3(context)),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        BlocBuilder<UpdateImage, XFile?>(
                                            builder: (context, image) {
                                          return Positioned(
                                              right: 10,
                                              top: 10,
                                              child: InkWell(
                                                  onTap: () {
                                                    context
                                                        .read<UpdateImage>()
                                                        .removeImage();
                                                  },
                                                  child: const Icon(
                                                    CupertinoIcons.delete,
                                                    color: Colors.red,
                                                  )));
                                        })
                                      ],
                                    );
                                  },
                                )
                              : widget.SourceType == "licence"
                                  ? BlocBuilder<UpdateLicenceImage, XFile?>(
                                      builder: (context, image) {
                                        if (image == null) {
                                          context
                                              .read<CheckSelectedCubit>()
                                              .checkSelectedValue(false);
                                          return widget.imageUrl
                                                  .toString()
                                                  .isNotEmpty
                                              ? customImageContainer(
                                                  widget.imageUrl ?? "",
                                                  screenHeight / 5)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: grey4,
                                                          width: 2)),
                                                  height: screenHeight / 5,
                                                  width: screenHeight / 5 + 50,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                          Icons.add_outlined,
                                                          size: 30),
                                                      Text(
                                                          "Select file"
                                                              .translate(
                                                                  context),
                                                          style: regular3(
                                                              context)),
                                                    ],
                                                  ),
                                                );
                                        }
                                        context
                                            .read<CheckSelectedCubit>()
                                            .checkSelectedValue(true);

                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: grey4, width: 2)),
                                              height: screenHeight / 5,
                                              width: screenHeight / 5 + 50,
                                              child: Image.file(
                                                File(image.path),
                                                height: 300,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return SizedBox(
                                                    child: Column(
                                                      children: [
                                                        const Icon(
                                                            Icons.error_outline,
                                                            size: 30,
                                                            color: Colors.red),
                                                        Text(
                                                            "Failed to load image"
                                                                .translate(
                                                                    context),
                                                            style: regular3(
                                                                context)),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            BlocBuilder<UpdateLicenceImage,
                                                    XFile?>(
                                                builder: (context, image) {
                                              return Positioned(
                                                  right: 10,
                                                  top: 10,
                                                  child: InkWell(
                                                      onTap: () {
                                                        context
                                                            .read<
                                                                UpdateLicenceImage>()
                                                            .removeImage();
                                                      },
                                                      child: const Icon(
                                                        CupertinoIcons.delete,
                                                        color: Colors.red,
                                                      )));
                                            })
                                          ],
                                        );
                                      },
                                    )
                                  : BlocBuilder<UpdateDocImage, XFile?>(
                                      builder: (context, image) {
                                        if (image == null) {
                                          context
                                              .read<CheckSelectedCubit>()
                                              .checkSelectedValue(false);
                                          return widget.imageUrl
                                                  .toString()
                                                  .isNotEmpty
                                              ? customImageContainer(
                                                  widget.imageUrl ?? "",
                                                  screenHeight / 5)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: grey4,
                                                          width: 2)),
                                                  height: screenHeight / 5,
                                                  width: screenHeight / 5 + 50,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                          Icons.add_outlined,
                                                          size: 30),
                                                      Text(
                                                          "Select file"
                                                              .translate(
                                                                  context),
                                                          style: regular3(
                                                              context)),
                                                    ],
                                                  ),
                                                );
                                        }
                                        context
                                            .read<CheckSelectedCubit>()
                                            .checkSelectedValue(true);

                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                      color: grey4, width: 2)),
                                              height: screenHeight / 5,
                                              width: screenHeight / 5 + 50,
                                              child: Image.file(
                                                File(image.path),
                                                height: 300,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return SizedBox(
                                                    child: Column(
                                                      children: [
                                                        const Icon(
                                                            Icons.error_outline,
                                                            size: 30,
                                                            color: Colors.red),
                                                        Text(
                                                            "Failed to load image"
                                                                .translate(
                                                                    context),
                                                            style: regular3(
                                                                context)),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            BlocBuilder<UpdateDocImage, XFile?>(
                                                builder: (context, image) {
                                              return Positioned(
                                                  right: 10,
                                                  top: 10,
                                                  child: InkWell(
                                                      onTap: () {
                                                        context
                                                            .read<
                                                                UpdateDocImage>()
                                                            .removeImage();
                                                      },
                                                      child: const Icon(
                                                        CupertinoIcons.delete,
                                                        color: Colors.red,
                                                      )));
                                            })
                                          ],
                                        );
                                      },
                                    ),
                        ],
                      )),
                ),
                const SizedBox(height: 10),
                Text("or".translate(context), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                CustomsButtons(
                    icon: Icon(
                      Icons.camera_alt,
                      color: blackColor,
                    ),
                    textColor: blackColor,
                    text: "Open Camera & Take Photo",
                    backgroundColor: themeColor,
                    onPressed: () {
                      selectImageWithSource(ImageSource.camera,
                          context: context,
                          status: "Add",
                          imgSource: widget.SourceType);
                    }),
                const SizedBox(height: 30),
                BlocBuilder<CheckSelectedCubit, bool>(
                    builder: (context, state) {
                  return state == true
                      ? CustomsButtons(
                          textColor: blackColor,
                          text: "Done",
                          backgroundColor: themeColor,
                          onPressed: widget.onTap)
                      : const SizedBox();
                }),
              ],
            ),
          );
        },
      );
    });
  }
}

class CustomBottomSheetVehicleLicense extends StatefulWidget {
  final VoidCallback onTap;
  final String? title;
  final String? description;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String sourceType;

  const CustomBottomSheetVehicleLicense({
    super.key,
    required this.onTap,
    required this.sourceType,
    this.title,
    this.description,
    this.frontImageUrl,
    this.backImageUrl,
  });

  @override
  State<CustomBottomSheetVehicleLicense> createState() =>
      _CustomBottomSheetVehicleLicenseState();
}

class _CustomBottomSheetVehicleLicenseState
    extends State<CustomBottomSheetVehicleLicense> {
  XFile? frontImage;
  XFile? backImage;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;

  Future<bool> _requestCameraPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
        return false;
      }
    }
    return true;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Camera Permission Required".translate(context)),
        content: Text(
          "Camera access is needed to take photos. Please enable it in Settings."
              .translate(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel".translate(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Open Settings".translate(context)),
          ),
        ],
      ),
    );
  }

  Future<void> showPickerDialog(Function(XFile, String?) onSelect) async {
    await showModalBottomSheet(
      backgroundColor: notifires.getbgcolor,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("Take a Photo".translate(context)),
              onTap: () async {
                Navigator.pop(context);
                if (await _requestCameraPermission()) {
                  try {
                    setState(() => isLoading = true);
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      preferredCameraDevice: CameraDevice.rear,
                    );
                    if (picked != null && mounted) {
                      final base64String =
                          await compressAndUploadImage(picked.path);
                      onSelect(picked, base64String);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "${"Error taking photo".translate(context)}: $e")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text("Choose from Gallery".translate(context)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  setState(() => isLoading = true);
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null && mounted) {
                    final base64String =
                        await compressAndUploadImage(picked.path);
                    onSelect(picked, base64String);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error selecting photo: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LicenseSelectionCubit, LicenseImageState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          snap: true,
          initialChildSize: 0.85,
          minChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title?.translate(context) ??
                                      "Vehicle License".translate(context),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.description?.translate(context) ??
                                      "Please upload both front and back images",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<UpdateLicenceImage, XFile?>(
                          builder: (context, image) {
                        return buildImageSection(
                          label: "Front License".translate(context),
                          file: image ?? frontImage,
                          fallbackUrl: widget.frontImageUrl,
                          onSelect: (file, base64) async {
                            setState(() => frontImage = file);
                            if (base64 != null) {
                              context
                                  .read<LicenseSelectionCubit>()
                                  .setFrontImage(file, base64);
                              context
                                  .read<UpdateLicenceImage>()
                                  .updateImage(file);
                              context
                                  .read<VehicleFormCubit>()
                                  .updateVehicleLicenceBase64Img(
                                      base64.toString());
                            }
                            context
                                .read<LicenseSelectionCubit>()
                                .setFrontSelected(true);
                          },
                          onDelete: () {
                            setState(() => frontImage = null);
                            context
                                .read<LicenseSelectionCubit>()
                                .setFrontImage(null, null);
                            context
                                .read<LicenseSelectionCubit>()
                                .setFrontSelected(false);
                            context.read<UpdateLicenceImage>().removeImage();
                            context
                                .read<VehicleFormCubit>()
                                .removeVehicleLicenceBase64Img();
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                      BlocBuilder<UpdateLicenceImage2, XFile?>(
                          builder: (context, image) {
                        return buildImageSection(
                          label: "Back License".translate(context),
                          file: image ?? backImage,
                          fallbackUrl: widget.backImageUrl,
                          onSelect: (file, base64) async {
                            setState(() => backImage = file);
                            if (base64 != null) {
                              context
                                  .read<LicenseSelectionCubit>()
                                  .setBackImage(file, base64);
                              context
                                  .read<UpdateLicenceImage2>()
                                  .updateImage(file);
                              context
                                  .read<VehicleFormCubit>()
                                  .updateVehicleLicenceBase64Img2(
                                      base64.toString());
                            }
                            context
                                .read<LicenseSelectionCubit>()
                                .setBackSelected(true);
                          },
                          onDelete: () {
                            setState(() => backImage = null);
                            context
                                .read<LicenseSelectionCubit>()
                                .setBackImage(null, null);
                            context
                                .read<LicenseSelectionCubit>()
                                .setBackSelected(false);
                            context.read<UpdateLicenceImage2>().removeImage();
                            context
                                .read<VehicleFormCubit>()
                                .removeVehicleLicenceBase64Img2();
                          },
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      color: Colors.white,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              state.frontSelected && state.backSelected
                                  ? Colors.black
                                  : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: state.frontSelected &&
                                state.backSelected &&
                                !isLoading
                            ? widget.onTap
                            : null,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Upload License".translate(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildImageSection({
    required String label,
    required XFile? file,
    required String? fallbackUrl,
    required Function(XFile, String?) onSelect,
    required VoidCallback onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (file != null || (fallbackUrl != null && fallbackUrl.isNotEmpty))
              InkWell(
                onTap: isLoading ? null : () => showPickerDialog(onSelect),
                child: Text(
                  "${"Change".translate(context)} >",
                  style: regular2(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isLoading ? null : () => showPickerDialog(onSelect),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              image: file != null
                  ? DecorationImage(
                      image: FileImage(File(file.path)), fit: BoxFit.contain)
                  : fallbackUrl != null && fallbackUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(fallbackUrl), fit: BoxFit.contain)
                      : null,
            ),
            child: Stack(
              children: [
                if (file == null &&
                    (fallbackUrl == null || fallbackUrl.isEmpty))
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_rounded,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text("Tap to upload".translate(context),
                            style: regular(context)),
                      ],
                    ),
                  ),
                if (file != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          onPressed: isLoading ? null : onDelete,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> selectImageWithSource(ImageSource source,
    // ignore: non_constant_identifier_names
    {String? status,
    String? imgSource,
    BuildContext? context}) async {
  try {
    final imagePicker = ImagePicker();
    XFile? pickedImage = await imagePicker.pickImage(source: source);

    await Future.delayed(const Duration(milliseconds: 150));

    if (pickedImage == null) {
      return;
    }

    final base64Img = await compressAndUploadImage(pickedImage.path);

    if (imgSource == "VehicleImg") {
      // ignore: use_build_context_synchronously
      context!.read<UpdateImage>().updateImage(pickedImage);
      // ignore: use_build_context_synchronously
      context
          .read<VehicleFormCubit>()
          .updateVehicleBase64Img(base64Img.toString());
    } else if (imgSource == "Document") {
      // ignore: use_build_context_synchronously
      context!.read<UpdateDocImage>().updateImage(pickedImage);
      // ignore: use_build_context_synchronously
      context
          .read<VehicleFormCubit>()
          .updateVehicleDocBase64Img(base64Img.toString());
    } else if (imgSource == "licence") {
      // ignore: use_build_context_synchronously
      context!.read<UpdateLicenceImage>().updateImage(pickedImage);
      // ignore: use_build_context_synchronously
      context
          .read<VehicleFormCubit>()
          .updateVehicleLicenceBase64Img(base64Img.toString());
    } else if (imgSource == "common") {
      // ignore: use_build_context_synchronously
      context!.read<UpdateImageCommon>().updateImage(pickedImage);
      // ignore: use_build_context_synchronously
      context.read<UpdateImageCommonBase64Img>().updateImage(base64Img);
    }
  } on PlatformException {
    if (Platform.isIOS) {
      showErrorToastMessage(
        "Please check the app settings and grant the necessary permissions."
            // ignore: use_build_context_synchronously
            .translate(context!),
      );
    }
  }
}

int fileSizeThreshold = 1024 * 1024;
int goodQuality = 85;
int badQuality = 50;
int maxWidth = 800;
int maxHeight = 600;

Future<String> compressAndUploadImage(String imagePath) async {
  var imageFile = File(imagePath);
  int originalSize = await imageFile.length();
  int quality = originalSize > fileSizeThreshold ? badQuality : goodQuality;
  var compressedImage = await FlutterImageCompress.compressWithFile(
    imagePath,
    quality: quality,
    minWidth: maxWidth,
    minHeight: maxHeight,
  );

  // ignore: unused_local_variable
  int compressedSize = compressedImage!.length;

  var base64Image = base64Encode(compressedImage);

  String format = '';
  if (compressedImage.length > 8) {
    if (compressedImage[0] == 0xFF && compressedImage[1] == 0xD8) {
      format = 'jpeg';
    } else if (compressedImage[0] == 0x89 && compressedImage[1] == 0x50) {
      format = 'png';
    }
  }

  String finalBase64 = "data:image/$format;base64,$base64Image";
  return finalBase64;
}

void goTo(Widget screen) {
  navigatorKey.currentState!.push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

void goBack() {
  navigatorKey.currentState!.pop();
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final bool? isCenterTitle;
  final bool? isBackButton;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? fontSize;
  const CustomAppBar({
    super.key,
    required this.title,
    this.titleColor,
    this.onBackTap,
    this.fontSize,
    this.backgroundColor,
    this.isCenterTitle,
    this.isBackButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      centerTitle: isCenterTitle ?? true,
      leadingWidth: 70,
      title: Text(title.translate(context),
          style: headingBlack(context).copyWith(
              fontSize: fontSize ?? 18, color: titleColor ?? blackColor)),
      leading: isBackButton == true
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: InkWell(
                  onTap: onBackTap ?? () => Navigator.of(context).pop(),
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: backgroundColor ?? notifires.getbgcolor,
                          border:
                              Border.all(color: notifires.getGrey3whiteColor)),
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Icon(Icons.arrow_back,
                            size: 20, color: notifires.getwhiteblackColor),
                      )),
                ),
              ),
            ),
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class CustomToggleSwitch extends StatelessWidget {
  final bool current;
  final Function(bool) onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedToggleSwitch<bool>.dual(
      current: current,
      first: false,
      second: true,
      textMargin: const EdgeInsets.all(0),
      height: 50,
      style: ToggleStyle(
        indicatorColor: Colors.white,
        backgroundColor: Colors.white,
        borderColor: current ? greentext : redColor,
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      borderWidth: 2.0,
      onChanged: onChanged,
      iconBuilder: (value) => value
          ? Icon(Icons.check_circle, color: greentext, size: 24)
          : Icon(Icons.donut_large, color: redColor, size: 24),
      textBuilder: (value) => value
          ? Transform.translate(
              offset: Offset(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? -10
                      : 10,
                  0),
              child: Text(
                "ON DUTY".translate(context),
                style: headingBlackBold(context)
                    .copyWith(color: greentext, fontSize: 14),
              ),
            )
          : Transform.translate(
              offset: Offset(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 10
                      : -10,
                  0),
              child: Text(
                "OFF DUTY".translate(context),
                style: headingBlackBold(context)
                    .copyWith(color: redColor, fontSize: 14),
              ),
            ),
    );
  }
}

class CustomSlideButton extends StatefulWidget {
  final bool isOnRide;
  final Function(bool) onChanged;
  final String acceptedText;
  final String defaultText;
  final Color activeColor;
  final Color inactiveColor;
  final Color iconColor;
  final Duration animationDuration;
  final double knobWidth;
  final Color? iconBoxColor;
  final Color? textInactiveColor;
  final Color? textActiveColor;

  const CustomSlideButton({
    super.key,
    required this.isOnRide,
    required this.onChanged,
    this.iconBoxColor,
    this.textActiveColor,
    this.textInactiveColor,
    this.acceptedText = "ACCEPTED",
    this.defaultText = "ACCEPT RIDE",
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.iconColor = Colors.black,
    this.animationDuration = const Duration(milliseconds: 300),
    this.knobWidth = 60,
  });

  @override
  State<CustomSlideButton> createState() => _CustomSlideButtonState();
}

String toTitleCaseFromCamel(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    var char = text[i];
    if (i == 0) {
      buffer.write(char.toUpperCase());
    } else if (char.toUpperCase() == char && char != ' ') {
      buffer.write(' $char');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

class _CustomSlideButtonState extends State<CustomSlideButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  late double _maxDrag;
  late AnimationController _controller;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.isOnRide ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(CustomSlideButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.isOnRide != oldWidget.isOnRide) {
      _controller.animateTo(
        widget.isOnRide ? 1.0 : 0.0,
        curve: Curves.easeInOut,
      );
    }
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0, _maxDrag);
      _controller.value = _dragPosition / _maxDrag;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    final shouldAccept = _controller.value > 0.6;
    _controller.animateTo(shouldAccept ? 1.0 : 0.0, curve: Curves.easeOut);
    if (shouldAccept != widget.isOnRide) {
      widget.onChanged(shouldAccept);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final totalWidth = constraints.maxWidth;
        _maxDrag = totalWidth - widget.knobWidth;
        final knobLeft = _controller.value * _maxDrag;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.isOnRide ? widget.activeColor : widget.inactiveColor,
          ),
          child: Stack(
            children: [
              // Centered Text
              Center(
                child: Text(
                  widget.isOnRide
                      ? widget.acceptedText.toString().translate(context)
                      : widget.defaultText.toString().translate(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isOnRide
                        ? widget.textActiveColor ?? Colors.white
                        : widget.textInactiveColor ?? Colors.white,
                  ),
                ),
              ),

              // Sliding knob
              Positioned(
                left: knobLeft,
                child: GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: widget.knobWidth,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.iconBoxColor ??
                          Colors.white.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                        right: Radius.circular(14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.isOnRide
                          ? Icons.check
                          : Localizations.localeOf(context).languageCode == 'ar'
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_forward_ios_rounded,
                      color: widget.iconColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomRideBottomSheet extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  final VoidCallback onTap;
  final String titleText;
  final Color activeColor;
  final Color inactiveColor;
  final String acceptedText;
  final String defaultText;
  final String? addressText;
  final bool isOnDutyRide;
  final Color? textInactiveColor;
  final Color? textActiveColor;
  final Function(bool) onChanged;
  final String? pickupString;

  final String? userPhoneCountry;
  // ignore: non_constant_identifier_names
  final Color? IconBoxColor;

  const CustomRideBottomSheet(
      {super.key,
      required this.titleText,
      required this.onTap,
      required this.rideRequest,
      this.pickupString,
      required this.isOnDutyRide,
      required this.activeColor,
      this.textActiveColor,
      this.textInactiveColor,
      required this.onChanged,
      required this.inactiveColor,
      // ignore: non_constant_identifier_names
      this.IconBoxColor,
      this.userPhoneCountry,
      required this.acceptedText,
      required this.defaultText,
      required this.addressText});

  @override
  // ignore: library_private_types_in_public_api
  _CustomRideBottomSheetState createState() => _CustomRideBottomSheetState();
}

class _CustomRideBottomSheetState extends State<CustomRideBottomSheet> {
  ValueNotifier<bool> hasUnreadMessage = ValueNotifier(false);

  void listenForUnread(String rideId, String driverId) {
    final ref =
        FirebaseDatabase.instance.ref("ride_requests/$rideId/chat/messages");

    ref.onValue.listen((event) {
      if (!event.snapshot.exists) {
        hasUnreadMessage.value = false;
        return;
      }

      Map data = event.snapshot.value as Map;

      bool unreadExists = data.values
          .any((msg) => msg["senderId"] != driverId && msg["seen"] == false);

      hasUnreadMessage.value = unreadExists;
    });
  }

  @override
  initState() {
    super.initState();
    listenForUnread(widget.rideRequest.rideId ?? "", driverId);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.5,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: widget.onTap,
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: yelloColor,
                        borderRadius: BorderRadius.circular(30)),
                    height: 50,
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_drop_up,
                          size: 50,
                        ),
                        Text(
                          widget.pickupString?.translate(context) ??
                              "Head to pickup"
                                  .translate(context), // Dynamic Title
                          style:
                              headingBlackBold(context).copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  color: notifires.getBoxColor,
                                  child: myNetworkImage(
                                      widget.rideRequest.customer?.userPhoto),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rideRequest.customer?.userName ?? "",
                                    style: headingBlackBold(context)
                                        .copyWith(fontSize: 14),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: orangeColor,
                                        size: 15,
                                      ),
                                      Text(
                                        widget.rideRequest.customer?.userRating
                                                    ?.isNotEmpty ==
                                                true
                                            ? widget.rideRequest.customer!
                                                .userRating!
                                            : "0.0",
                                        style: regular2(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () async {
                                  final bookingId = await context
                                      .read<UpdateBookingIdCubit>()
                                      .getBookingId(
                                          rideId: context
                                              .read<
                                                  UpdateDriverParameterCubit>()
                                              .state
                                              .rideId);
                                  _showCancelRideBottomSheet(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      bookingId.toString());
                                },
                                child: Container(
                                  height: 35,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: redColor,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    "Cancel".translate(context),
                                    style: regular(context).copyWith(
                                        color: whiteColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          Text(
                            widget.pickupString.toString() == "Go to Drop"
                                ? "Drop Location".translate(context)
                                : "Pickup Location".translate(context),
                            style: regular2(context),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: greentext,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.addressText ?? "",
                                  style: headingBlack(context)
                                      .copyWith(fontSize: 12),
                                  softWrap: true,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  launchDialPad(
                                      "${widget.rideRequest.customer?.userPhoneCountry} ${widget.rideRequest.customer?.userPhone}");
                                },
                                child: ClipOval(
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    color: greentext,
                                    child: Icon(
                                      Icons.call,
                                      color: whiteColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: CustomSlideButton(
                                    textActiveColor: widget.textActiveColor,
                                    textInactiveColor: widget.textInactiveColor,
                                    activeColor: widget.activeColor,
                                    inactiveColor: widget.inactiveColor,
                                    isOnRide: widget.isOnDutyRide,
                                    acceptedText: widget.acceptedText,
                                    defaultText: widget.defaultText,
                                    onChanged: widget.onChanged),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showCancelRideBottomSheet(BuildContext context, String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: notifires.getbgcolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: themeColor, size: 40),
              const SizedBox(height: 12),
              Text(
                "Cancel Ride Confirmation".translate(context),
                style: heading2Grey1(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "You have already accepted this ride.\nCanceling now may impact your rating or future ride requests."
                    .translate(context),
                style: regular(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      box.delete('ride_id');
                      cancelRideRequest(
                          rideId: context
                              .read<UpdateDriverParameterCubit>()
                              .state
                              .rideId,
                          bookingId: bookingId); // Close the sheet after action
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Cancel Ride".translate(context),
                        style: regular2(context).copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      alignment: Alignment.center,
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Continue Ride".translate(context),
                        style: regular2(context).copyWith(
                            color: grey1, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> cancelRideRequest({
    required String rideId,
    required String bookingId,
  }) async {
    try {
      if (rideId.isEmpty) {
        throw Exception('Ride ID cannot be empty');
      }

      context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
            rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
            newStatus: "rejected",
          );
      context.read<UpdateRideStatusInDatabaseCubit>().updateRideStatus(
            context: context,
            bookingId: bookingId,
            rideStatus: "Rejected",
          );

      context.read<UpdateRideRequestCubit>().removeRideRequest(
          skipStatus: true, rideId: rideId, driverId: driverId);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeMain(initialIndex: 0),
        ),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Emit error state

      throw Exception('Failed to cancel ride request: $e');
    }
  }
}

Future<void> cancelRideRequestByError({
  required String rideId,
  required String bookingId,
  required BuildContext context,
}) async {
  try {
    goToWithClear(const HomeMain(initialIndex: 0));
    if (rideId.isEmpty) {
      throw Exception('Ride ID cannot be empty');
    }

    context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
          rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
          newStatus: "rejected",
        );
    context.read<UpdateRideStatusInDatabaseCubit>().updateRideStatus(
          context: context,
          bookingId: bookingId,
          rideStatus: "Rejected",
        );

    context.read<UpdateRideRequestCubit>().removeRideRequest(
        skipStatus: true,
        rideId: rideId,
        driverId: loginModel?.data?.fireStoreId ?? "");
  } catch (e) {
    // Emit error state

    throw Exception('Failed to cancel ride request: $e');
  }
}

Future<void> cancelRideRequestWhenLogout({
  required String rideId,
  required BuildContext context,
}) async {
  try {
    if (rideId.isEmpty) {
      throw Exception('Ride ID cannot be empty');
    }

    context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
          rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
          newStatus: "rejected",
        );

    context.read<UpdateRideRequestCubit>().removeRideRequest(
        skipStatus: true,
        rideId: rideId,
        driverId: loginModel?.data?.fireStoreId ?? "");
  } catch (e) {
    // Emit error state

    // throw Exception('Failed to cancel ride request: $e');
  }
}

class CustomRideBottomSheetForStartRide extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  final String titleText;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final String acceptedText;
  final String defaultText;
  final String? addressText;
  final bool isOnDutyRide;
  final Color? textInactiveColor;
  final Color? textActiveColor;
  final Function(bool) onChanged;
  final String? pickupString;

  const CustomRideBottomSheetForStartRide(
      {super.key,
      required this.rideRequest,
      required this.titleText,
      required this.onTap,
      this.pickupString,
      required this.isOnDutyRide,
      required this.activeColor,
      this.textActiveColor,
      this.textInactiveColor,
      required this.onChanged,
      required this.inactiveColor,
      required this.acceptedText,
      required this.defaultText,
      required this.addressText});

  @override
  CustomRideBottomSheetForStartRideState createState() =>
      CustomRideBottomSheetForStartRideState();
}

class CustomRideBottomSheetForStartRideState
    extends State<CustomRideBottomSheetForStartRide> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 70,
                                  width: 70,
                                  color: notifires.getBoxColor,
                                  child: myNetworkImage(
                                      widget.rideRequest.customer?.userPhoto),
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rideRequest.customer?.userName ?? "",
                                    style: headingBlackBold(context)
                                        .copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: orangeColor,
                                        size: 15,
                                      ),
                                      Text(
                                        widget.rideRequest.customer?.userRating
                                                    ?.isNotEmpty ==
                                                true
                                            ? widget.rideRequest.customer!
                                                .userRating!
                                            : "0.0",
                                        style: regular2(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          Text(
                            "Drop Location".translate(context),
                            style: regular2(context),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: greentext,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.addressText ?? "",
                                  style: headingBlack(context)
                                      .copyWith(fontSize: 14),
                                  softWrap: true,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  launchDialPad(
                                      "${widget.rideRequest.customer?.userPhoneCountry} ${widget.rideRequest.customer?.userPhone}");
                                },
                                child: ClipOval(
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    color: themeColor,
                                    child: Icon(
                                      Icons.call,
                                      color: whiteColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: CustomSlideButton(
                                    textActiveColor: widget.textActiveColor,
                                    textInactiveColor: widget.textInactiveColor,
                                    activeColor: widget.activeColor,
                                    inactiveColor: widget.inactiveColor,
                                    isOnRide: widget.isOnDutyRide,
                                    acceptedText: widget.acceptedText,
                                    defaultText: widget.defaultText,
                                    iconColor: widget.textInactiveColor!,
                                    onChanged: widget.onChanged),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DeleteConfirmationDialogs extends StatelessWidget {
  final String? desc;
  final String? firstButtontext;
  final String? secondButtontext;

  const DeleteConfirmationDialogs({
    super.key,
    this.desc,
    this.firstButtontext,
    this.secondButtontext,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountLoading) {
          Widgets.showLoader(context); // Your custom loader
        } else {
          Widgets.hideLoder(context);
          if (state is DeleteAccountSuccess) {
            showToastMessage(state.message);
            Navigator.pop(context);
            context.read<LogoutCubit>().logout(context);
            // Close dialog
          } else if (state is DeleteAccountFailed) {
            showToastMessage(state.error);
          }
        }
      },
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: Colors.transparent,
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notifires.getboxcolor,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: themeColor),
              const SizedBox(height: 16),
              Text(
                "Are you sure you want to delete your account?"
                    .translate(context),
                textAlign: TextAlign.center,
                style: regular(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: notifires.getGrey2whiteColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This action is permanent and cannot be undone."
                    .translate(context),
                textAlign: TextAlign.center,
                style: regular(context).copyWith(
                  fontSize: 14,
                  color: notifires.getGrey2whiteColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: notifires.getBoxColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                notifires.getGrey2whiteColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Cancel'.translate(context),
                          style: heading3Grey1(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<DeleteAccountCubit>()
                            .deleteAccount(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Yes, Delete".translate(context),
                          style: heading3Grey1(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

buildShowDialog(BuildContext context) {
  return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: blackColor.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return Center(
            child:
                CircularProgressIndicator(color: yelloColor, strokeWidth: 3));
      });
}

class Widgets {
  static bool isLoadingShowing = false;

  static void showLoader(BuildContext context) async {
    if (isLoadingShowing) {
      return;
    }
    isLoadingShowing = true;
    showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (BuildContext context) {
          return AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.black.withValues(alpha: 0.2),
            ),
            child: SafeArea(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  return;
                },
                child: Center(
                    child: CircularProgressIndicator(
                  color: yelloColor2,
                )),
              ),
            ),
          );
        });
  }

  static void hideLoder(BuildContext context) {
    if (isLoadingShowing) {
      isLoadingShowing = false;
      Navigator.of(context).pop();
    }
  }
}

// ignore: prefer_typing_uninitialized_variables
var closeLoading;
showLoading() {
  closeLoading = BotToast.showLoading();
}

showErrorToastMessage(String message) {
  BotToast.showCustomText(
    duration: const Duration(seconds: 3),
    align: Alignment.bottomCenter
        .add(const Alignment(0, -0.12)), // Moves up slightly
    toastBuilder: (context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15), // Adds bottom padding
        child: CustomToastMessages(
          message: message.toString(),
          error: true,
        ),
      );
    },
  );
}

showToastMessage(String message) {
  BotToast.showCustomText(
    align: Alignment.bottomCenter.add(const Alignment(0, -0.12)), // Moves
    toastBuilder: (_) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: CustomToastMessages(
        message: message,
        error:
            false, // add this if you are supporting both success & error cases
      ),
    ),
    duration: const Duration(seconds: 3),

// prevents it from showing across routes/screens
  );
}

class CustomToastMessages extends StatefulWidget {
  final String message;
  final bool? error;

  const CustomToastMessages({
    super.key,
    required this.message,
    this.error,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CustomToastMessagesState createState() => _CustomToastMessagesState();
}

class _CustomToastMessagesState extends State<CustomToastMessages>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isError = widget.error ?? false;
    final Color color = isError ? redColor : greentext;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin:
                    const EdgeInsets.only(top: 20), // Space for floating text
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      // ignore: deprecated_member_use
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        isError ? Icons.warning_amber : Icons.check,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.message.translate(context),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => BotToast.removeAll(),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 14,
                        child: Icon(
                          Icons.close,
                          color: whiteColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating "Error!" or "Success!" text
              Positioned(
                top: 0,
                left: 16,
                child: Text(
                  isError
                      ? "Error!".translate(context)
                      : "Success!".translate(context),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    // ignore: deprecated_member_use
                    color: color.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: whiteColor.withValues(alpha: .9),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomBottomSheet extends StatelessWidget {
  final VoidCallback? onClose;

  const CustomBottomSheet({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SizedBox(
          height: 280,
          width: double.infinity,
          child: Container(
              decoration: BoxDecoration(color: notifires.getbgcolor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  SvgPicture.asset(
                    "assets/images/thanku_img.svg",
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Uploaded successfully".translate(context),
                    style: regularBlack(context).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    textAlign: TextAlign.center,
                    "Upload successfull Your document has \nbeen received"
                        .translate(context),
                    style: regularBlack(context),
                  )
                ],
              ))),
    );
  }
}

void showDynamicBottomSheets(BuildContext context,
    {required String title,
    required String description,
    required String firstButtontxt,
    required String secondButtontxt,
    required final VoidCallback onpressed,
    required final VoidCallback onpressed1}) {
  showModalBottomSheet(
    isScrollControlled: false,
    constraints:
        const BoxConstraints.expand(width: double.infinity, height: 240),
    context: context,
    builder: (context) {
      return DynamicBottomSheetContent(
        title: title,
        description: description,
        firstButtontxt: firstButtontxt,
        secondButtontxt: secondButtontxt,
        onpressed: onpressed,
        onpressed1: onpressed1,
      );
    },
  );
}

class DynamicBottomSheetContent extends StatefulWidget {
  final String title;
  final String description;
  final String firstButtontxt;
  final String secondButtontxt;
  final VoidCallback onpressed;
  final VoidCallback onpressed1;

  const DynamicBottomSheetContent(
      {super.key,
      required this.title,
      required this.description,
      required this.firstButtontxt,
      required this.secondButtontxt,
      required this.onpressed,
      required this.onpressed1});

  @override
  State<DynamicBottomSheetContent> createState() =>
      _DynamicBottomSheetContentState();
}

class _DynamicBottomSheetContentState extends State<DynamicBottomSheetContent> {
  bool isCancelSelected = true; // Initially, the "Cancel" button is selected
  bool isDeleteSelected = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // height:100,
      decoration: BoxDecoration(
          color: notifires.getblackwhiteColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0), topRight: Radius.circular(0))),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: Text(widget.title.translate(context),
                  style: heading2Grey1(context).copyWith())),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: notifires.getGrey3whiteColor,
          ),
          const SizedBox(height: 15),
          Flexible(
              child: Text(widget.description.translate(context),
                  style: heading3Grey1(context))),
          const SizedBox(height: 30),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              // height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.38),
                      child: ElevatedButton(
                        onPressed: widget.onpressed,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: notifires.getBoxColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge),
                          ),
                        ),
                        child: Text(widget.firstButtontxt.translate(context),
                            style: heading3(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.38),
                      child: ElevatedButton(
                        onPressed: widget.onpressed1,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          // onPrimary: WhiteColor, // Customize the text color
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1.0, color: themeColor),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge),
                          ),
                        ),
                        child: Text(widget.secondButtontxt.translate(context),
                            style: heading3(context)
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

void showOpenAppSettingsDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Platform.isIOS
          ? CupertinoAlertDialog(
              title: const Text("Permission Required"),
              content: Text(
                message,
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text(
                    "Open Settings",
                    // style: regular2(context).copyWith()
                  ),
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          : AlertDialog(
              backgroundColor: notifires.getbgcolor,
              title: Text(
                "Permission Required",
                style: heading3Grey1(context).copyWith(
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              content: Text(
                message,
                style: regular2(context).copyWith(),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "Cancel",
                    style: heading3Grey1(context).copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    "Open Settings",
                    style: heading3Grey1(context).copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
    },
  );
}

dialogExit(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: notifires.getboxcolor,
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Icon(
                Icons.error,
                size: 75,
                color: redColor,
              ),
              Text(
                "Do you want to exit?".translate(context),
                textAlign: TextAlign.center,
                style: headingBlack(context)
                    .copyWith(color: notifires.getwhiteblackColor),
              )
            ],
          ),
        ),
        actions: <Widget>[
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  border: Border.all(color: grey5),
                                  color: grey4,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(
                                "Cancel".translate(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ))))),
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.pop(context);

                            SystemNavigator.pop();
                          },
                          child: Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  border: Border.all(color: blackColor),
                                  color: blackColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(
                                "Exit".translate(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ))))),
                ],
              ),
              const SizedBox(
                height: 8,
              )
            ],
          )
        ],
      );
    },
  );
}

class DocumentStatusBottomSheet extends StatelessWidget {
  final String status;

  const DocumentStatusBottomSheet({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
          color: notifires.getblackwhiteColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0), topRight: Radius.circular(0))),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == "rejected"
              ? const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 50,
                )
              : const Icon(Icons.access_time,
                  color: Colors.orangeAccent, size: 50),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              textAlign: TextAlign.center,
              status == "rejected"
                  ? "Oops! Your documents were rejected. Please head to the edit section to update your documents."
                  : "Your documents are still under review. We’ll notify you once the verification is complete.",
              style: heading2Grey1(context).copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget buildShimmerLoader() {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 30,
              height: 30,
              color: Colors.white,
            ),
            title: Container(
              width: 80,
              height: 14,
              color: Colors.white,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  color: Colors.white,
                ),
                Container(
                  width: 60,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

Widget myNetworkImage(String? image,
    {double height = 150.0, double width = 150.0}) {
  if (image != null && Uri.tryParse(image)?.hasAbsolutePath == true) {
    // Valid URL, proceed with loading
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
        errorBuilder: (context, exception, stackTrace) {
          return getErrorImage();
        },
      ),
    );
  } else {
    return getErrorImage();
  }
}

Widget getErrorImage() {
  return Padding(
    padding: const EdgeInsets.all(4),
    child: Image.asset(
      "assets/images/logos.png",
      fit: BoxFit.contain,
    ),
  );
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Completed':
      return appgreen;
    case 'Cancelled':
      return redColor;
    case 'Declined':
      return redColor;
    case 'Pending':
      return orangeColor; // define if not yet
    case 'Accepted':
    case 'Arrived':
    case 'Live':
      return blueColor; // define as per your theme
    case 'Confirmed':
      return Colors.deepPurple; // custom if needed
    case 'Expired':
    case 'Refunded':
      return greyColor2; // soft grey maybe
    default:
      return Colors.black54;
  }
}

Color getStatusBackground(String status) {
  // ignore: deprecated_member_use
  return getStatusColor(status).withOpacity(0.2);
}

Widget buildLocationRow({
  required IconData icon,
  required Color color,
  required Color bgColor,
  required String text,
  required BuildContext context,
}) {
  return Row(
    children: [
      ClipOval(
        child: Container(
          height: 25,
          width: 25,
          color: bgColor,
          child: Icon(icon, color: color, size: 16),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: regular(context).copyWith(color: grey1),
        ),
      ),
    ],
  );
}

void goToWithClear(Widget screen) {
  navigatorKey.currentState!.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
    (route) => false,
  );
}

void goToWithReplacement(Widget screen) {
  navigatorKey.currentState!.pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeIn;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

Widget myAssetImage(String? image, {double? height, double? width}) {
  if (image != null && image.isNotEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
      ),
    );
  } else {
    return getErrorImage();
  }
}

Future<void> showDutyConfirmationDialog({
  required BuildContext context,
  required bool goingOnline,
  required VoidCallback onConfirmed,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/logos.png",
                height: 50,
              ),
              const SizedBox(height: 20),
              Text(
                goingOnline
                    ? "Go Online?".translate(context)
                    : "Go Offline?".translate(context),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: goingOnline ? greentext : redColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                goingOnline
                    ? "You are about to go ON DUTY. Riders will now be able to see and book you."
                        .translate(context)
                    : "You are about to go OFF DUTY. You will not receive any more bookings."
                        .translate(context),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel".translate(context),
                        style: TextStyle(color: notifires.getGrey1whiteColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirmed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goingOnline ? greentext : themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Confirm".translate(context),
                        style: TextStyle(color: whiteColor),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}

class PaymentConfirmationDialogs extends StatefulWidget {
  final String? desc;
  final String? firstButtontext;
  final String? secondButtontext;
  final String? text;
  final Function()? onPressed;

  const PaymentConfirmationDialogs({
    super.key,
    this.desc,
    this.firstButtontext,
    this.secondButtontext,
    this.text,
    this.onPressed,
  });

  @override
  PaymentConfirmationDialogsState createState() =>
      PaymentConfirmationDialogsState();
}

class PaymentConfirmationDialogsState
    extends State<PaymentConfirmationDialogs> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: greentext,
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 34,
                color: whiteColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.text?.translate(context) ?? "Confirm Payment",
              textAlign: TextAlign.center,
              style: heading3Grey1(context),
            ),
            if (widget.desc != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.desc!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: notifires.getBoxColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: notifires.getBoxColor.withOpacity(0.3),
                              width: 1),
                        ),
                        child: Text(
                          "Cancel".translate(context),
                          style: TextStyle(
                            color: notifires.getGrey1whiteColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: widget.onPressed,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: .3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.secondButtontext?.translate(context) ??
                              "Confirm".translate(context),
                          style: heading3Grey1(context)
                              .copyWith(color: whiteColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget commonlyUserlogoAlert() {
  return Center(
    child: ClipOval(
        child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: blackColor),
      child: Image.asset('assets/images/logos.png', fit: BoxFit.fill),
    )),
  );
}

void loginExpireAlertToExitFromApp({required BuildContext context}) {
  int countdown = 3;
  late Timer timer;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 1) {
              countdown--;
              setState(() {});
            } else {
              t.cancel();
              Navigator.of(context).pop();
              context.read<LogoutCubit>().logout(context);
            }
          });

          return AlertDialog(
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  commonlyUserlogoAlert(),
                  const SizedBox(height: 5),
                  Text(
                    'Your token is Expired. Please login again.'
                        .translate(context),
                    textAlign: TextAlign.center,
                    style: headingBlack(context).copyWith(color: blackColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Redirecting to login in $countdown seconds...'
                        .translate(context),
                    textAlign: TextAlign.center,
                    style: headingBlack(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            actions: const [SizedBox(height: 8)],
          );
        },
      );
    },
  ).then((_) {
    if (timer.isActive) {
      timer.cancel();
    }
  });
}

class EarningsSummaryCard extends StatelessWidget {
  const EarningsSummaryCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 0.2,
      builder: (context, scrollController) {
        return BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
          return Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Earnings",
                          style:
                              headingBlackBold(context).copyWith(fontSize: 18)),
                      state is DashboardSuceess
                          ? Text(
                              state.totalEarning ?? "",
                              style: regularBlack(context),
                            )
                          : Text(
                              "0",
                              style: regularBlack(context),
                            ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Ratings",
                          style:
                              headingBlackBold(context).copyWith(fontSize: 18)),
                      state is DashboardSuceess
                          ? Text(
                              state.totalRating.toString(),
                              style: regularBlack(context),
                            )
                          : Text(
                              "0",
                              style: regularBlack(context),
                            ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Total Order's",
                          style:
                              headingBlackBold(context).copyWith(fontSize: 18)),
                      state is DashboardSuceess
                          ? Text(
                              state.totalOrder.toString(),
                              style: regularBlack(context),
                            )
                          : Text(
                              "0",
                              style: regularBlack(context),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

Widget forMapLoadingShimmer() {
  return SizedBox(
    height: double.maxFinite,
    width: double.maxFinite,
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    ),
  );
}

class MapShimmerScreen extends StatelessWidget {
  const MapShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    right: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Shimmer.fromColors(
                        baseColor: Colors.amber[400]!,
                        highlightColor: Colors.amber[200]!,
                        child: Container(
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer verification section
                  Row(
                    children: [
                      // Profile image shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Pickup location title
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location icon shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.green[300]!,
                        highlightColor: Colors.green[100]!,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Address text shimmer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 20,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Call button shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[600]!,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Arrived button shimmer
                  Shimmer.fromColors(
                    baseColor: themeColor,
                    highlightColor: themeColor,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomGoogleMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final CameraPosition? initialCameraPosition;
  final Function(LatLng)? onMapTap;
  final Function(LatLng)? onMapLongPress;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool zoomControlsEnabled;
  final String? mapStyle;
  final VoidCallback? zoomIn; // Optional JSON string for custom map style
  final VoidCallback? zoomOut; // Optional JSON string for custom map style
  final VoidCallback? currentLocation;
  final Function(GoogleMapController)? onMapCreated;

  const CustomGoogleMap(
      {super.key,
      required this.initialPosition,
      this.markers = const {},
      this.polylines = const {},
      this.initialCameraPosition,
      this.onMapTap,
      this.onMapLongPress,
      this.mapType = MapType.normal,
      this.myLocationEnabled = true,
      this.zoomControlsEnabled = true,
      this.mapStyle,
      this.zoomIn,
      this.zoomOut,
      this.currentLocation,
      this.onMapCreated});

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          key: ValueKey('google_map_${DateTime.timestamp().microsecond}'),
          initialCameraPosition: widget.initialCameraPosition ??
              CameraPosition(
                target: widget.initialPosition,
                zoom: 14,
              ),
          markers: widget.markers,
          polylines: widget.polylines,
          mapType: widget.mapType,
          myLocationEnabled: widget.myLocationEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          onTap: widget.onMapTap,
          onLongPress: widget.onMapLongPress,
          onMapCreated: widget.onMapCreated,
        ),
        Positioned(
          top: 100,
          right: 16,
          child: Column(
            children: [
              _MapButton(icon: Icons.zoom_in, onTap: widget.zoomIn ?? () {}),
              const SizedBox(height: 8),
              _MapButton(icon: Icons.zoom_out, onTap: widget.zoomOut ?? () {}),
              const SizedBox(height: 8),
              widget.currentLocation == null
                  ? const SizedBox()
                  : _MapButton(
                      icon: Icons.location_on,
                      onTap: widget.currentLocation ?? () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

String getCurrentFormattedTime() {
  final now = DateTime.now();
  final hour = now.hour > 12
      ? now.hour - 12
      : now.hour == 0
          ? 12
          : now.hour;
  final period = now.hour >= 12 ? "PM" : "AM";
  final formattedTime =
      "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period";
  return formattedTime;
}

DateTime parseTime(String timeString) {
  final now = DateTime.now();
  final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
  final match = format.firstMatch(timeString.toUpperCase());

  if (match != null) {
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    final period = match.group(3);

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(now.year, now.month, now.day, hour, minute);
  } else {
    throw FormatException("Invalid time format: $timeString");
  }
}

int calculateMinutesBetween(String startTime, String endTime) {
  final start = parseTime(startTime);
  final end = parseTime(endTime);

  return end.difference(start).inMinutes;
}

Future<void> launchDialPad(String phoneNumber) async {
  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phoneNumber.replaceAll(' ', ''),
  );

  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch dialer for $phoneNumber';
  }
}

customImageContainer(String imageUrl, double imageHeight) {
  return Stack(
    children: [
      Container(
        height: imageHeight,
        width: imageHeight + 50,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: grey4, width: 2)),
        child: myNetworkImage(imageUrl),
      ),
    ],
  );
}

Future<void> startLiveNavigation({
  required double sourceLat,
  required double sourceLng,
  required double destLat,
  required double destLng,
}) async {
  final Uri googleNavigationUri = Uri.parse(
    "google.navigation:q=$destLat,$destLng&mode=d", // mode=d for driving
  );

  if (await canLaunchUrl(googleNavigationUri)) {
    await launchUrl(googleNavigationUri, mode: LaunchMode.externalApplication);
  } else {
    // fallback: open route in maps if navigation fails
    final fallbackUri = Uri.parse("https://www.google.com/maps/dir/?api=1"
        "&origin=$sourceLat,$sourceLng"
        "&destination=$destLat,$destLng"
        "&travelmode=driving");
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}

class LoadingDropdownPlaceholder extends StatelessWidget {
  const LoadingDropdownPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              height: 12,
              width: 120,
              color: Colors.grey.shade400,
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

Widget languageButton({
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: themeColor.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, color: themeColor, size: 18),
          const SizedBox(width: 6),
          BlocBuilder<LCodeCubit, String>(builder: (context, state) {
            return Text(
              state.toUpperCase(),
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            );
          }),
          Icon(Icons.keyboard_arrow_down_rounded, color: themeColor, size: 18),
        ],
      ),
    ),
  );
}

class ParcelInfoWidget extends StatelessWidget {
  final String name;
  final String weight;
  final String receiverName;
  final String receiverPhone;
  final String pickupInstructions;

  const ParcelInfoWidget({
    super.key,
    required this.name,
    required this.weight,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupInstructions,
  });

  bool get _shouldHide =>
      name.trim().isEmpty &&
      receiverName.trim().isEmpty &&
      receiverPhone.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Parcel Details".translate(context),
            style: heading1Grey1(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange,
            ),
          ),

          const SizedBox(height: 10),

          // Grid rows
          Row(
            children: [
              Expanded(
                  child: _infoCard("Item".translate(context), name,
                      Icons.inventory_2_outlined)),
              const SizedBox(width: 8),
              Expanded(
                  child: _infoCard(
                      "Weight".translate(context),
                      "$weight ${"Kg".translate(context)}",
                      Icons.scale_outlined)),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                  child: _infoCard("Receiver".translate(context), receiverName,
                      Icons.person_outline)),
              const SizedBox(width: 8),
              Expanded(
                  child: _infoCard("Phone".translate(context), receiverPhone,
                      Icons.call_outlined)),
            ],
          ),

          if (pickupInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "${"Instruction".translate(context)}: $pickupInstructions",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.brown,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE0C2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.deepOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
