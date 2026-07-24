import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/register_vehicle_document.dart';
import 'driver_document_screen.dart';

class EditDriverDocumentScreen extends StatefulWidget {
  const EditDriverDocumentScreen({super.key});

  @override
  State<EditDriverDocumentScreen> createState() =>
      _EditDriverDocumentScreenState();
}

class _EditDriverDocumentScreenState extends State<EditDriverDocumentScreen> {
  RefreshController refreshController = RefreshController();
  onRefresh() {
    setState(() {});
    context.read<GetVehicleDocumentCubit>().getUploadDocument(context: context);
    refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: ""),
        backgroundColor: notifires.getbgcolor,
        body: MultiBlocListener(
            listeners: [
              BlocListener<GetVehicleDocumentCubit, GetVehicleDocumentState>(
                  listener: (context, state) {
                if (state is GetDocumentSuccess) {
                  final documents = state.documentImageModel.data;

                  if (documents?.drivingLicenceFront?.drivingLicenceImage?.isNotEmpty ?? false) {
                    context.read<GetDocVehicleFormCubit>().updateDrivingLicenceFront(
                      documents?.drivingLicenceFront?.drivingLicenceImage ?? "",
                      documents?.drivingLicenceFront?.drivingLicenceStatus ?? "",
                    );
                  }
                  if (documents?.drivingLicenceBack?.drivingLicenceImageBack?.isNotEmpty ?? false) {
                    context.read<GetDocVehicleFormCubit>().updateDrivingLicenceBack(
                      documents?.drivingLicenceBack?.drivingLicenceImageBack ?? "",
                      documents?.drivingLicenceBack?.drivingLicenceBackStatus ?? "",
                    );
                  }

                  if (documents?.driverIdFront?.driverIdFrontImage?.isNotEmpty ?? false) {
                    context.read<GetDocVehicleFormCubit>().updateDriverIdFront(
                      documents?.driverIdFront?.driverIdFrontImage??"",
                      documents?.driverIdFront?.driverIdFrontImageStatus??"",
                    );
                  }
                  if (documents?.driverIdBack?.driverIdBackImage?.isNotEmpty ?? false) {
                    context.read<GetDocVehicleFormCubit>().updateDriverIdBack(
                      documents?.driverIdBack?.driverIdBackImage??"",
                      documents?.driverIdBack?.driverIdBackImageStatus??"",
                    );
                  }

                  final stateAll = context.read<GetDocVehicleFormCubit>().state;
                  List<String> statusList = [
                    stateAll.driverIdFrontStatus,
                    stateAll.driverIdBackStatus,
                    stateAll.drivingLicenceFrontStatus,
                    stateAll.drivingLicenceBackStatus,
                  ];

                  if (statusList.every((status) => status == "approved")) {
                    context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "approved");
                    box.put("approved", true);
                  } else if (statusList.contains("rejected")) {
                    context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "rejected");
                    box.put("approved", false);
                  } else {
                    context.read<DocumentApprovedStatusCubit>().updateDocumentApprovedStatus(docApprovedStatus: "pending");
                    context.read<UpdateDriverParameterCubit>().updateDocApprovedStatus(docApprovedStatus: "pending");
                    box.put("approved", false);
                  }



                } else if (state is GetDocumentFailure) {}
              })
            ],
            child: SmartRefresher(
              controller: refreshController,
              onRefresh: onRefresh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text("Required Information".translate(context),
                        style: headingBlack(context).copyWith(fontSize: 20)),
                    const SizedBox(height: 30),
                    InkWell(
                        onTap: () {
                          setState(() {});
                        },
                        child: Text("Welcome Driver".translate(context),
                            style: headingBlack(context))),
                    const SizedBox(height: 5),
                    Text(
                        "Follow these steps to begin your ride."
                            .translate(context),
                        style: headingBlack(context).copyWith(fontSize: 14)),
                    const SizedBox(height: 40),
                    const DriverDocumentScreen(),
                  ],
                ),
              ),
            )));
  }
}
