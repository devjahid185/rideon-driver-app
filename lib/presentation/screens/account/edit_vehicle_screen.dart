import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../domain/entities/get_item_vehicle.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/get_vehicle_data.dart';
import '../../cubits/register_vehicle/make_model_cubit.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';
import '../setup_account/driver_vehicle_screen.dart';

class EditVehicleScreen extends StatefulWidget {
  final Items myItems;
  const EditVehicleScreen({super.key, required this.myItems});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() {
    final state = context.read<VehicleFormCubit>();
    state.textEditingVehicleBrandController.text =
        widget.myItems.vehicleMake?.toString() ?? "";
    state.textEditingVehicleColorController.text =
        widget.myItems.vehicleColor ?? "Black";
    state.textEditingVehicleNumberController.text =
        widget.myItems.vehicleNumber?.toString() ?? "";
    state.textEditingVehicleModelController.text =
        widget.myItems.vehicleModel?.toString() ?? "";
    state.updateVehicleTypeId(widget.myItems.itemTypeId?.toString() ?? "",);
    context.read<CheckUpdatedDocumentImage>().checkUpdatedDocumentImage(true);
    context.read<CheckUpdatedLicenceImage>().checkUpdatedLicenceImage(true);
    context.read<CheckUpdatedImage>().checkUpdatedImage(true);
    context
        .read<SetVehicleImage>()
        .setImage(widget.myItems.frontImage?.url ?? "");
    context
        .read<SetDocImage>()
        .setImage(widget.myItems.frontImageDoc?.url ?? "");
    context
        .read<SetInsuranceImage>()
        .setImage(widget.myItems.itemInsuranceDoc?.url ?? "");
    context.read<UpdateDriverParameterCubit>().updateVehicleTypeName(
        vehcileTypeName: widget.myItems.vehicleType?.toString() ?? "");
    context.read<UpdateDriverParameterCubit>().updateVehicleTypeId(
        vehicleTypeId: widget.myItems.itemTypeId?.toString() ?? "");
    state.updateVehicleColor(widget.myItems.vehicleColor ?? "Black");
    state.updateVehicleModel(widget.myItems.vehicleModel?.toString() ?? "");
    state.updateVehicleMake(widget.myItems.vehicleMake?.toString() ?? "");
    state.updateVehicleYear(widget.myItems.vehicleYear ?? "2025");
    state.updateVehicleNumber(widget.myItems.vehicleNumber?.toString() ?? "");

    context.read<UpdateDocImage>().removeImage();
    context.read<UpdateLicenceImage>().removeImage();
    context.read<UpdateImage>().removeImage();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        context
            .read<GetItemVehicleDataCubit>()
            .getVehicleItemData(context: context);
        goBack();
        return false;
      },
      child: Scaffold(
        bottomNavigationBar: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: CustomsButtons(
                text: "Updated",
                textColor: blackColor,
                backgroundColor: themeColor,
                onPressed: () {
                  final state = context.read<VehicleFormCubit>();
                  final metaDataMap = context.read<MetaDataMap>();


                  if (state.state.vehicleTypeId.isEmpty) {
                    showErrorToastMessage("Select the vehicle type".translate(context));
                    return;
                  }
                  if (state.state.vehicleMake.isEmpty) {
                    showErrorToastMessage("Select the Brand type".translate(context));
                    return ;
                  }
                  if (state.textEditingVehicleModelController.text.isEmpty) {
                    showErrorToastMessage("Select the Model type".translate(context));
                    return ;
                  }
                  if (state.textEditingVehicleNumberController.text.isEmpty) {
                    showErrorToastMessage(
                        "Enter the vehicle registration number".translate(context));
                    return ;
                  }
                  if ( state.textEditingVehicleColorController.text.isEmpty) {
                    showErrorToastMessage(
                        "Enter the vehicle color".translate(context));
                    return ;
                  }
                  if (state.state.vehicleYear.isEmpty) {
                    showErrorToastMessage("Enter the vehicle Year".translate(context));
                    return ;
                  }
                  metaDataMap.insertToMap("year", state.state.vehicleYear);
                  metaDataMap.insertToMap("vehicle_registration_number",
                      state.textEditingVehicleNumberController.text);
                  metaDataMap.insertToMap(
                      "make", state.textEditingVehicleBrandController.text);
                  metaDataMap.insertToMap(
                      "model", state.textEditingVehicleModelController.text);
                  metaDataMap.insertToMap("service_type", "booking");

                  final addItemMap = context.read<AddItemMap>();
                  addItemMap.insertToMap(
                      "metaData", jsonEncode(metaDataMap.state));
                  addItemMap.insertToMap("make", state.state.vehicleMake);

                  addItemMap.insertToMap(
                      "model", state.textEditingVehicleModelController.text);
                  addItemMap.insertToMap("year", state.state.vehicleYear);
                  addItemMap.insertToMap(
                      "color", state.textEditingVehicleColorController.text);
                  addItemMap.insertToMap("registration_number",
                      state.textEditingVehicleNumberController.text);
                  context.read<VehicleRegisterCubit>().insertItem(
                        context: context,
                        itemMap: context.read<AddItemMap>().state,
                        itemId: context
                            .read<UpdateAddEditVehicleIdCubit>()
                            .state
                            .vehicleAddEditTypeId
                            .toString(),
                        itemTypeId: context.read<VehicleFormCubit>().state.vehicleTypeId,
                      );
                }),
          ),
        ),
        backgroundColor: notifires.getbgcolor,
        appBar: CustomAppBars(
            onBackButtonPressed: () {
              context
                  .read<GetItemVehicleDataCubit>()
                  .getVehicleItemData(context: context);
              goBack();
            },
            title: "Edit Vehicle",
            backgroundColor: notifires.getbgcolor,
            titleColor: notifires.getGrey1whiteColor),
        body: BlocListener<VehicleRegisterCubit, VehicleRegisterState>(
          listener: (context, state) {
            if (state is VehcileLoading) {
              Widgets.showLoader(context);
            } else if (state is VehicleSuccess) {
              Widgets.hideLoder(context);
              context
                  .read<GetItemVehicleDataCubit>()
                  .getVehicleItemData(context: context);
              goBack();
            } else if (state is VehicleFailure) {
              Widgets.hideLoder(context);
              showErrorToastMessage(state.errorMsg);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: const [
              DriverVehicleScreen(
                isEdit: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
