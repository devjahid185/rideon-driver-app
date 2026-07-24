import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/get_all_categories.dart';
import '../../../domain/entities/get_makes.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/register_vehicle/get_vehicle_data.dart';
import '../../cubits/register_vehicle/make_model_cubit.dart';
import '../../cubits/register_vehicle/single_image_upload_cubit.dart';
import '../../cubits/register_vehicle/vehicle_register_cubit.dart';
import '../../widgets/custom_dropdown_widget.dart';
import '../../widgets/custom_text_form_field.dart';

class DriverVehicleScreen extends StatefulWidget {
  final bool isEdit;
  const DriverVehicleScreen({
    super.key,
    required this.isEdit,
  });

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen> {
  List<ItemTypes> itemTypes = [];
  List<MakeTypes> makesTypes = [];
  List<String> yearList = [];
  @override
  void initState() {
    super.initState();
    yearList = getYearList();
  }

  String value1 = "";
  String value2 = "";
  String value3 = "";
  List<String> getYearList() {
    return List.generate(
      DateTime.now().year - 1999,
      (index) => (2000 + index).toString(), // Convert to String
    );
  }

  bool documentUploadSuccess = false;
  bool frontImageSheetOpened = false;
  bool insuranceDocSheetOpened = false;
  bool registrationDocSheetOpened = false;

  void openBottomSheet(VoidCallback onCloseCallback, BuildContext context) {
    showModalBottomSheet(
      backgroundColor: whiteColor,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CustomBottomSheet(
          onClose: () {
            goBack();
            setState(() {
              documentUploadSuccess = false;
            });
            onCloseCallback(); // Reset flag
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<SingleImageUploadCubits, SingleImageUploadState>(
            listener: (context, state) async {
              if (state is SingleImageLoading) {
                Widgets.showLoader(context);
              } else if (state is SingleImageSuccess) {
                Widgets.hideLoder(context);

                // Set image-specific flags and trigger relevant Cubit updates
                if (state.status == "front_image") {
                  context.read<CheckUpdatedImage>().checkUpdatedImage(true);

                  if (!frontImageSheetOpened) {
                    frontImageSheetOpened = true;
                    openBottomSheet(() {
                      frontImageSheetOpened = false;
                    }, context);
                  }
                } else if (state.status == "vehicle_insurance_doc") {
                  context
                      .read<CheckUpdatedLicenceImage>()
                      .checkUpdatedLicenceImage(true);

                  if (!insuranceDocSheetOpened) {
                    insuranceDocSheetOpened = true;
                    openBottomSheet(() {
                      insuranceDocSheetOpened = false;
                    }, context);
                  }
                } else if (state.status == 'vehicle_registration_doc') {
                  context
                      .read<CheckUpdatedDocumentImage>()
                      .checkUpdatedDocumentImage(true);

                  if (!registrationDocSheetOpened) {
                    registrationDocSheetOpened = true;
                    openBottomSheet(() {
                      registrationDocSheetOpened = false;
                    }, context);
                  }
                }

                context.read<SingleImageUploadCubits>().removeSingleImage();
              } else if (state is SingleImageFailure) {
                Widgets.hideLoder(context);

                if (state.status == "front_image") {
                  context.read<CheckUpdatedImage>().checkUpdatedImage(false);
                } else if (state.status == "vehicle_insurance_doc") {
                  context
                      .read<CheckUpdatedLicenceImage>()
                      .checkUpdatedLicenceImage(false);
                } else if (state.status == "vehicle_registration_doc") {
                  context
                      .read<CheckUpdatedDocumentImage>()
                      .checkUpdatedDocumentImage(false);
                }
              }
            },
          )
        ],
        child: Column(children: [
          BlocBuilder<GetVehicleDataCubit, GetVehicleDataState>(
              builder: (context, state) {
            if (state is GetVehicleSuccess) {
              itemTypes = state.itemTypes;
            }
            return CustomDropdownList(
              checkImage: true,
              onSelectedImageUrl: (img) {
                context
                    .read<UpdateDriverParameterCubit>()
                    .updateVehicleImageUrl(vechicleImageUrl: img.toString());
              },
              onSelectedValue: (value) {
                context
                    .read<UpdateDriverParameterCubit>()
                    .updateVehicleTypeName(vehcileTypeName: value.toString());
              },
              options: itemTypes,
              onSelected: (value) {
                context
                    .read<VehicleFormCubit>()
                    .updateVehicleTypeId(value.toString());
                context
                    .read<UpdateDriverParameterCubit>()
                    .updateVehicleTypeId(vehicleTypeId: value.toString());
                context
                    .read<MakeModelCubit>()
                    .getMakeModel(context: context, value: value);
                context.read<VehicleFormCubit>().textEditingVehicleModelController.clear();


              },
              hintText: "Vehicle Type".translate(context),
              checkmarkColor: acentColor,
              selectedEditInitialValue:
                  context.read<VehicleFormCubit>().state.vehicleTypeId,
            );
          }),
          const SizedBox(height: 20),
          BlocBuilder<MakeModelCubit, MakeModelState>(
              builder: (context, state) {
            if (state is MakeModelSuccess) {
              makesTypes = state.makeType;


            }

            return BlocListener<VehicleFormCubit,VehicleFormState>(
              listener: (context,vehicleState){

              },
              child: CustomDropdownList(
                key: ValueKey(context.read<VehicleFormCubit>().state.vehicleTypeId),
                checkImage: false,
                onSelectedImageUrl: (img) {},
                onSelectedValue: (value) {

                  context
                      .read<UpdateDriverParameterCubit>()
                      .updateVehicleMake(vechileMake: value);
                },
                options: makesTypes,
                checkMake: true,
                // clearDataonVehgicletype: context.read<VehicleFormCubit>().state.shouldClearMake,
                selectedEditInitialValue:
                context.read<VehicleFormCubit>().state.vehicleMake,
                onSelected: (value) {


                  context
                      .read<VehicleFormCubit>()
                      .updateVehicleMake(value.toString());
                },
                hintText: "Vehicle Make".translate(context),
                checkmarkColor: acentColor,
              ),
            );
          }),
          const SizedBox(height: 20),
          BlocBuilder<VehicleFormCubit, VehicleFormState>(
            builder: (context, state) {
              final vehicleCubit = context.read<VehicleFormCubit>();

              return Column(
                children: [
                  TextFieldAdvance(
                      cumpulsoryIcon: true,
                      textStyle: regular2(context),
                      txt: "Vehicle Model".translate(context),
                      hintStyle: regular2(context),
                      inputFormatters: [
                        UpperCaseTextFormatter(), // 👈 Add this
                      ],
                      textEditingControllerCommon:
                          vehicleCubit.textEditingVehicleModelController,
                      inputType: TextInputType.text,
                      onChange: (value) {
                        vehicleCubit.updateVehicleModel(value!);
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateVehicleModel(vechileModel: value);
                        return null;
                      },
                      inputAlignment: TextAlign.start),
                  const SizedBox(height: 20),
                  TextFieldAdvance(
                      cumpulsoryIcon: true,
                      textStyle: regular2(context),
                      txt: "Vehicle Number".translate(context),
                      hintStyle: regular2(context),
                      textEditingControllerCommon:
                          vehicleCubit.textEditingVehicleNumberController,
                      inputType: TextInputType.text,
                      inputFormatters: [
                        UpperCaseTextFormatter(), // 👈 Add this
                      ],
                      onChange: (value) {
                        vehicleCubit.updateVehicleNumber(value!);
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateVehicleNumber(vechileNumber: value);
                        return null;
                      },
                      inputAlignment: TextAlign.start),
                  const SizedBox(height: 20),
                  TextFieldAdvance(
                      cumpulsoryIcon: true,
                      textStyle: regular2(context),
                      txt: "Vehicle Color".translate(context),
                      hintStyle: regular2(context),
                      textEditingControllerCommon:
                          vehicleCubit.textEditingVehicleColorController,
                      inputType: TextInputType.text,
                      onChange: (value) {
                        vehicleCubit.updateVehicleColor(value!);
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateVehicleColor(color: value);
                        return null;
                      },
                      inputAlignment: TextAlign.start),
                  const SizedBox(height: 20),
                  CustomDropdown(
                    options: yearList,
                    onSelected: (value) {
                      vehicleCubit.updateVehicleYear(value);
                    },
                    selectedEditInitialValue:
                        vehicleCubit.state.vehicleYear.isEmpty
                            ? null
                            : vehicleCubit.state.vehicleYear,
                    hintText: "Vehicle Year".translate(context),
                    checkmarkColor: acentColor,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CustomBottomSheetVechicle(
                      SourceType: "Document",
                      title: "Upload Vehicle Document".translate(context),
                      descrption:
                          "Securely Upload Your Document".translate(context),
                      imageUrl: context.read<SetDocImage>().state,
                      onTap: () {
                        final vehicleFormState =
                            context.read<VehicleFormCubit>().state;
                        goBack();
                        setState(() {});

                        if (context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                null &&
                            context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                0) {
                          context
                              .read<SingleImageUploadCubits>()
                              .uploadSingleImage(
                                  context: context,
                                  itemId: context
                                      .read<UpdateAddEditVehicleIdCubit>()
                                      .state
                                      .vehicleAddEditTypeId
                                      .toString(),
                                  status: "vehicle_registration_doc",
                                  itemImageMap: {
                                'vehicle_registration_doc':
                                    vehicleFormState.vehicleDocBase64Image,
                              });
                        } else {
                          showErrorToastMessage(
                              "Vehicle ID is not being received.");
                        }
                      },
                    ),
                  );
                },
                child: BlocBuilder<CheckUpdatedDocumentImage, bool?>(
                    builder: (context, value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: value == true
                                ? greentext
                                : notifires.getBoxColor),
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: BlocBuilder<UpdateDocImage, XFile?>(
                        builder: (context, image) {
                      if (image == null) {
                        return BlocBuilder<SetDocImage, String>(
                            builder: (context, imageUrl) {
                          if (imageUrl.isNotEmpty) {
                            context
                                .read<CheckUpdatedDocumentImage>()
                                .checkUpdatedDocumentImage(true);
                            return Row(children: [
                              const SizedBox(width: 10),
                              Image.asset("assets/images/fileImg.png",
                                  color: blackColor),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                imageUrl,
                                style: regular(context),
                              )),
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                              ),
                              const SizedBox(
                                width: 10,
                              )
                            ]);
                          }
                          return Row(children: [
                            const SizedBox(width: 10),
                            Image.asset("assets/images/fileImg.png",
                                color: blackColor),
                            const SizedBox(width: 10),
                            RichText(
                                text: TextSpan(
                                    text: "Vehicle Document".translate(context),
                                    style: regular2(context),
                                    children: [
                                  TextSpan(
                                      text: " *",
                                      style: TextStyle(
                                          color: redColor, fontSize: 16))
                                ])),
                          ]);
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                    text: TextSpan(
                                  text: basename(image.path),
                                  style: regular(context).copyWith(
                                      overflow: TextOverflow.ellipsis),
                                )),
                              ),
                              InkWell(
                                onTap: () {
                                  context.read<UpdateDocImage>().removeImage();
                                  context
                                      .read<CheckUpdatedDocumentImage>()
                                      .removeImageDocumentStatus();
                                },
                                child: value == true
                                    ? Icon(
                                        Icons.cancel_outlined,
                                        color: redColor,
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        color: redColor,
                                      ),
                              )
                            ]),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CustomBottomSheetVechicle(
                      SourceType: "licence",
                      imageUrl: context.read<SetInsuranceImage>().state,
                      title:
                          "Upload Vehicle license details".translate(context),
                      descrption: "Securely Upload Your license details"
                          .translate(context),
                      onTap: () {
                        final vehicleFormState =
                            context.read<VehicleFormCubit>().state;
                        goBack();
                        setState(() {});

                        if (context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                null &&
                            context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                0) {
                          context
                              .read<SingleImageUploadCubits>()
                              .uploadSingleImage(
                                  context: context,
                                  itemId:
                                      context
                                          .read<UpdateAddEditVehicleIdCubit>()
                                          .state
                                          .vehicleAddEditTypeId
                                          .toString(),
                                  status: "vehicle_insurance_doc",
                                  itemImageMap: {
                                "vehicle_insurance_doc":
                                    vehicleFormState.vehicleLicenceBase64Image
                              });
                        } else {
                          showErrorToastMessage(
                              "Vehicle ID is not being received.");
                        }
                      },
                    ),

                  );
                },
                child: BlocBuilder<CheckUpdatedLicenceImage, bool?>(
                    builder: (context, value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: value == true
                                ? greentext
                                : notifires.getBoxColor),
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: BlocBuilder<UpdateLicenceImage, XFile?>(
                        builder: (context, image) {
                      if (image == null) {
                        return BlocBuilder<SetInsuranceImage, String>(
                            builder: (context, imageUrl) {
                          if (imageUrl.isNotEmpty) {
                            context
                                .read<CheckUpdatedLicenceImage>()
                                .checkUpdatedLicenceImage(true);
                            return Row(children: [
                              const SizedBox(width: 10),
                              Image.asset("assets/images/fileImg.png",
                                  color: blackColor),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                imageUrl,
                                style: regular(context),
                              )),
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                              ),
                              const SizedBox(
                                width: 10,
                              )
                            ]);
                          }
                          return Row(children: [
                            const SizedBox(width: 10),
                            Image.asset("assets/images/fileImg.png",
                                color: blackColor),
                            const SizedBox(width: 10),
                            RichText(
                                text: TextSpan(
                                    text: "license, insurance, vehicle details"
                                        .translate(context),
                                    style: regular2(context),
                                    children: [
                                  TextSpan(
                                      text: " *",
                                      style: TextStyle(
                                          color: redColor, fontSize: 16))
                                ])),
                          ]);
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                    text: TextSpan(
                                  text: basename(image.path),
                                  style: regular(context).copyWith(
                                      overflow: TextOverflow.ellipsis),
                                )),
                              ),
                              InkWell(
                                onTap: () {
                                  context
                                      .read<CheckUpdatedLicenceImage>()
                                      .removeImageLicenceStatus();
                                  context
                                      .read<UpdateLicenceImage>()
                                      .removeImage();
                                },
                                child: value == true
                                    ? Icon(
                                        Icons.cancel_outlined,
                                        color: redColor,
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        color: redColor,
                                      ),
                              )
                            ]),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CustomBottomSheetVechicle(
                      SourceType: "VehicleImg",
                      imageUrl: context.read<SetVehicleImage>().state,
                      title: "Securely upload your vehicle images"
                          .translate(context),
                      descrption: "Please add an external photo of your vehicle"
                          .translate(context),
                      onTap: () {
                        final vehicleFormState =
                            context.read<VehicleFormCubit>().state;
                        goBack();
                        setState(() {});

                        if (context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                null &&
                            context
                                    .read<UpdateAddEditVehicleIdCubit>()
                                    .state
                                    .vehicleAddEditTypeId !=
                                0) {
                          context
                              .read<SingleImageUploadCubits>()
                              .uploadSingleImage(
                                  context: context,
                                  itemId:
                                      context
                                          .read<UpdateAddEditVehicleIdCubit>()
                                          .state
                                          .vehicleAddEditTypeId
                                          .toString(),
                                  status: "front_image",
                                  itemImageMap: {
                                "front_image":
                                    vehicleFormState.vehicleBase64Image
                              });
                        } else {
                          showErrorToastMessage(
                              "Vehicle ID is not being received.");
                        }
                      },
                    ),
                  );
                },
                child: BlocBuilder<CheckUpdatedImage, bool?>(
                    builder: (context, value) {
                  return Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: value == true
                                  ? greentext
                                  : notifires.getBoxColor),
                          color: notifires.getBoxColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: BlocBuilder<UpdateImage, XFile?>(
                          builder: (context, image) {
                        if (image == null) {
                          return BlocBuilder<SetVehicleImage, String>(
                              builder: (context, imageUrl) {
                            if (imageUrl.isNotEmpty) {
                              context
                                  .read<CheckUpdatedImage>()
                                  .checkUpdatedImage(true);
                              return Row(children: [
                                const SizedBox(width: 10),
                                Image.asset("assets/images/fileImg.png",
                                    color: blackColor),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                  imageUrl,
                                  style: regular(context),
                                )),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                ),
                                const SizedBox(
                                  width: 10,
                                )
                              ]);
                            }
                            return Row(children: [
                              const SizedBox(width: 10),
                              Image.asset("assets/images/fileImg.png",
                                  color: blackColor),
                              const SizedBox(width: 10),
                              RichText(
                                  text: TextSpan(
                                      text: "Vehicle Image".translate(context),
                                      style: regular2(context),
                                      children: [
                                    TextSpan(
                                        text: " *",
                                        style: TextStyle(
                                            color: redColor, fontSize: 16))
                                  ])),
                            ]);
                          });
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: RichText(
                                      text: TextSpan(
                                    text: basename(image.path),
                                    style: regular(context).copyWith(
                                        overflow: TextOverflow.ellipsis),
                                  )),
                                ),
                                InkWell(
                                  onTap: () {
                                    context.read<UpdateImage>().removeImage();
                                    context
                                        .read<CheckUpdatedImage>()
                                        .removeImageStatus();
                                  },
                                  child: value == true
                                      ? Icon(
                                          Icons.cancel_outlined,
                                          color: redColor,
                                        )
                                      : Icon(
                                          Icons.image_not_supported,
                                          color: redColor,
                                        ),
                                ),
                              ]),
                        );
                      }));
                }),
              ),
            ],
          ),
        ]));
  }

  Widget buildImageCard(
    BuildContext context,
    String imageUrl, {
    bool fullWidth = false,
    required String imageType, // e.g., "Front View", "Side View"
    required IconData imageTypeIcon,
  }) {
    return Container(
      height: fullWidth ? 200 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: myNetworkImage(imageUrl),
          ),

          // Edit Button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit clicked')),
                  );
                },
              ),
            ),
          ),

          // Image Type Tag (e.g., Front View)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(imageTypeIcon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    imageType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
