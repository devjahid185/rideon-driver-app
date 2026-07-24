import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../domain/entities/get_item_vehicle.dart';
import '../../../domain/entities/get_makes.dart';
import '../../cubits/register_vehicle/get_vehicle_data.dart';
import '../../cubits/register_vehicle/make_model_cubit.dart';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() =>
      _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  Items? itemVehicleModel;
  List<MakeTypes> makeType = [];
  String selectedMake = "";

  @override
  void initState() {
    super.initState();
    context
        .read<GetItemVehicleDataCubit>()
        .getVehicleItemData(context: context);
    context.read<GetVehicleDataCubit>().getAllCategories(context: context);
    context.read<MakeModelCubit>().getMakeModel(
          context: context,
          value: box.get("UpdatedItemId") ?? loginModel?.data?.itemTypeId ?? "",
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      appBar: CustomAppBars(
          title: "Vehicle Information",
          backgroundColor: notifires.getbgcolor,
          titleColor: notifires.getGrey1whiteColor),
      body: BlocBuilder<GetItemVehicleDataCubit, GetItemVehicleDataState>(
        builder: (context, state) {
          if (state is GetItemLoading) {
            return const VehicleInformationShimmer();
          } else if (state is GetItemSuccess) {
            itemVehicleModel = state.getItemVehicleModel.data?.items?.first;
            context.read<GetItemVehicleDataCubit>().clear();
          } else if (state is GetItemFailure) {
            showErrorToastMessage(state.error);
          }

          return BlocBuilder<MakeModelCubit, MakeModelState>(
            builder: (context, makeState) {
              if (makeState is MakeModelSuccess) {
                makeType = makeState.makeType;
                for (var e in makeType) {
                  if (e.id.toString() ==
                      itemVehicleModel?.vehicleMake.toString()) {
                    selectedMake = e.name ?? "N/A";
                  }
                }
              }

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleImageCard(context),
                    const SizedBox(height: 24),
                    _buildVehicleInfoCard(context),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(height: 160, child: _buildVehicleDocCard(context))
                  ],
                ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
              );
            },
          );
        },
      ),
    );
  }

  /// Enhanced Vehicle Image Card with Modern Design
  Widget _buildVehicleImageCard(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: itemVehicleModel?.frontImage?.url ?? "",
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.grey[200],
                height: 200,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error, color: Colors.red, size: 40),
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: .8),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemVehicleModel?.vehicleNumber ?? "N/A",
                  style: heading2Grey1(context).copyWith(color: Colors.white),
                ),
                Text(
                  "${itemVehicleModel?.vehicleModel ?? "Unknown"} • ${itemVehicleModel?.vehicleYear ?? ""}",
                  style: heading3Grey1(context).copyWith(color: grey5),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOut);
  }

  Widget _buildVehicleDocCard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: itemVehicleModel?.itemInsuranceDoc?.url ?? "",
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.grey[200],
                          height: 120,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error,
                            color: Colors.red, size: 40),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        color: Colors.black54, // semi-transparent background
                        child: Text(
                          "Vehicle Licence".translate(context),
                          style: heading3Grey1(context)
                              .copyWith(color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // 👈 if name is big
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: itemVehicleModel?.frontImageDoc?.url ?? "",
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.grey[200],
                          height: 120,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error,
                            color: Colors.red, size: 40),
                      ),
                    ),

                    // 👇 Overlay text at bottom-left
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        color: Colors.black54,
                        child: Text(
                          "Vehicle Document".translate(context),
                          style: heading3Grey1(context)
                              .copyWith(color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
          duration: 1000.ms,
          delay: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildVehicleInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Details".translate(context),
            style: heading2Grey1(context),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: buildInfoTile(
                  icon: CupertinoIcons.number_circle,
                  label: "Vehicle No.",
                  value: itemVehicleModel?.vehicleNumber ?? "NA",
                  iconColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInfoTile(
                  icon: Icons.directions_car_filled,
                  label: "Make",
                  value: selectedMake,
                  iconColor: Colors.teal,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: buildInfoTile(
                  icon: Icons.car_rental,
                  label: "Model",
                  value: itemVehicleModel?.vehicleModel ?? "NA",
                  iconColor: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInfoTile(
                  icon: Icons.directions_bus,
                  label: "Type",
                  value: itemVehicleModel?.vehicleType ?? "NA",
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: buildInfoTile(
                  icon: Icons.date_range,
                  label: "Year",
                  value: itemVehicleModel?.vehicleYear ?? "NA",
                  iconColor: Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInfoTile(
                  icon: Icons.color_lens,
                  label: "Color",
                  value: itemVehicleModel?.vehicleColor ?? "NA",
                  iconColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1000.ms, delay: 300.ms, curve: Curves.easeOut);
  }

  Widget buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withValues(alpha: .1),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.translate(context),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 200.ms);
  }
}
