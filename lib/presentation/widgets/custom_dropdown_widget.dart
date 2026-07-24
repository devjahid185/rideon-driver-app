import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/extensions/workspace.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../cubits/register_vehicle/make_model_cubit.dart';

class CustomDropdownList extends StatefulWidget {
  final List options;
  final String hintText;
  final Function(String) onSelected;
  final Function(String) onSelectedValue;
  final Function(String) onSelectedImageUrl;
  final Color checkmarkColor;
  final String? heading;
  final dynamic selectedEditInitialValue;
  final bool? removeAll;
  final bool? clearDataonVehgicletype;
  final bool? checkMake;
  final bool? checkModel;
  final bool? checkImage;
  final bool? cumpulsoryIcon;

  const CustomDropdownList({
    super.key,
    this.cumpulsoryIcon = false,
    this.heading,
    required this.options,
    required this.onSelectedImageUrl,
    this.checkModel = false,
    this.checkImage = false,
    this.checkMake = false,
    required this.onSelectedValue,
    required this.onSelected,
    required this.checkmarkColor,
    this.hintText = 'Select One',
    this.selectedEditInitialValue,
    this.removeAll,
    this.clearDataonVehgicletype,
  });

  @override
  CustomDropdownListState createState() => CustomDropdownListState();
}

class CustomDropdownListState extends State<CustomDropdownList> {
  String? selectedValue;
  int? selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.checkMake == true) {

        syncInitialValueForMake();
      } else {
        syncInitialValue();
      }
    });
  }

  void syncInitialValue() {
    if (widget.clearDataonVehgicletype == true ||
        widget.selectedEditInitialValue == null ||
        widget.selectedEditInitialValue.toString().isEmpty) {
      if (selectedValue != null || selectedId != null) {
        setState(() {
          selectedValue = null;
          selectedId = null;
        });
      }
      return;
    }

    final matched = widget.options.firstWhereOrNull(
          (item) =>
      item.id.toString() == widget.selectedEditInitialValue.toString(),
    );

    if (matched != null &&
        (matched.id != selectedId || matched.name != selectedValue)) {
      setState(() {
        selectedValue = matched.name;
        selectedId = matched.id;
      });
    }
  }

  void syncInitialValueForMake() {

    if (widget.clearDataonVehgicletype == true ||
        widget.selectedEditInitialValue == null ||
        widget.selectedEditInitialValue.toString().isEmpty) {
      if (selectedValue != null || selectedId != null) {


        setState(() {
          selectedValue = null;
          selectedId = null;
        });
      }
      return;
    }

    final matched = widget.options.firstWhereOrNull(
          (item) =>
      item.id.toString() == widget.selectedEditInitialValue.toString(),
    );


    if (matched != null &&
        (matched.id != selectedId || matched.name != selectedValue)) {
      setState(() {
        selectedValue = matched.name;
        selectedId = matched.id;
      });

    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: notifires.getbgcolor,
      shape: const BeveledRectangleBorder(),
      context: context,
      builder: (BuildContext context) {
        List<dynamic> filteredOptions = List.from(widget.options);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: greyColor2.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Text(
                    "${"Select".translate(context)} ${widget.hintText.translate(context)}".translate(context),
                    style: heading3Grey1(context),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.close,
                      color: notifires.getwhiteblackColor,
                    ),
                  ),
                ],
              ),
            ),
            filteredOptions.isEmpty?SizedBox(
              height: 350,
                child: Center(child: Text("No data available".translate(context),style: regular2(context),),)): Expanded(
              child: ListView.separated(
                itemCount: filteredOptions.length,
                itemBuilder: (BuildContext context, int index) {
                  bool isSelected = filteredOptions[index].id == selectedId;

                  return Container(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        filteredOptions[index].name ?? "select one".translate(context),
                        style: regular2(context),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: widget.checkmarkColor)
                          : const SizedBox(),
                      onTap: () {
                        setState(() {
                          selectedId = filteredOptions[index].id;
                          selectedValue = filteredOptions[index].name;
                        });
                        if (widget.checkMake == true) {
                          widget.onSelected(
                              filteredOptions[index].id.toString());
                        } else {
                          widget
                              .onSelected(filteredOptions[index].id.toString());
                        }
                        widget.onSelectedValue(
                            filteredOptions[index].name.toString());
                        if (widget.checkImage == true) {
                          if (filteredOptions[index]
                              .image
                              .toString()
                              .isNotEmpty) {
                            widget.onSelectedImageUrl(
                                filteredOptions[index].image.toString());
                          }
                        }

                        if (widget.checkModel == true) {
                          context
                              .read<SelectedCubit>()
                              .updateSelectedValue(false);
                        }

                        Navigator.pop(context);
                      },
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MakeModelCubit, MakeModelState>(
      builder: (context,makeState) {

        if (makeState is MakeModelLoading&& widget.checkMake==true) {
          return   LoadingDropdownBox(
            loadingText: "Fetching vehicle make...".translate(context),
          );
        }
        return GestureDetector(
          onTap: () {
            if (widget.checkMake == true) {

              if(context.read<VehicleFormCubit>().state.vehicleTypeId.isEmpty){
                showErrorToastMessage("Please select first vehicle type");
                return;
              }
              context.read<SelectedCubit>().updateSelectedValue(true);
            }

            _openBottomSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            decoration: BoxDecoration(
              color: notifires.getBoxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.checkModel == true
                    ? Expanded(
                  child: BlocBuilder<SelectedCubit, bool>(
                    builder: (context, value) {
                      return RichText(
                          text: TextSpan(
                              text: value
                                  ? widget.hintText
                                  : selectedValue ?? widget.hintText,
                              style: regular2(context),
                              children: [
                                widget.cumpulsoryIcon == true
                                    ? TextSpan(
                                    text: "  *",
                                    style: TextStyle(color: redColor))
                                    : const TextSpan()
                              ]));
                    },
                  ),
                )
                    : Expanded(
                  child: RichText(
                      text: TextSpan(
                          text: selectedValue ?? widget.hintText,
                          style: regular2(context)
                              .copyWith(overflow: TextOverflow.ellipsis),
                          children: [
                            widget.cumpulsoryIcon == true
                                ? TextSpan(
                                text: "  *",
                                style: TextStyle(color: redColor))
                                : const TextSpan()
                          ])),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: notifires.getwhiteblackColor,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class CustomDropdown extends StatefulWidget {
  final List options;
  final String hintText;
  final String? prefixIconImage;
  final Function(String) onSelected;
  final Color checkmarkColor;
  final String? heading;
  final String? selectedEditInitialValue;
  final bool? removeAll;
  final bool? clearDataonVehgicletype;
  final TextStyle? textStyle;
  final Color? prefixIconColor;

  const CustomDropdown({
    super.key,
    this.heading,
    this.prefixIconColor,
    this.textStyle,
    this.prefixIconImage,
    required this.options,
    required this.onSelected,
    required this.checkmarkColor,
    this.hintText = 'Select One',
    this.selectedEditInitialValue,
    this.removeAll,
    this.clearDataonVehgicletype,
  });

  @override
  CustomDropdownState createState() => CustomDropdownState();
}

class CustomDropdownState extends State<CustomDropdown> {
  String? selectedValue;
  int? selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedEditInitialValue != null) {
        setState(() {
          selectedValue = widget.selectedEditInitialValue;
        });
      }
    });
  }


  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: notifires.getbgcolor,
      shape: const BeveledRectangleBorder(),
      context: context,
      builder: (BuildContext context) {
        List<dynamic> filteredOptions = List.from(widget.options);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: greyColor2.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Text(
                    "${"Select".translate(context)} ${widget.hintText.translate(context)}".translate(context),
                    style: heading3Grey1(context),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.close,
                      color: notifires.getwhiteblackColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: filteredOptions.length,
                itemBuilder: (BuildContext context, int index) {
                  bool isSelected = filteredOptions[index] == selectedValue;
                  return Container(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        filteredOptions[index].toString().translate(context),
                        style: regular2(context),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: widget.checkmarkColor)
                          : const SizedBox(),
                      onTap: () {
                        setState(() {
                          selectedValue = filteredOptions[index];
                        });
                        widget.onSelected(filteredOptions[index].toString());
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _openBottomSheet(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: widget.prefixIconImage != null &&
                widget.prefixIconImage!.isNotEmpty
                ? 5
                : 0,
            vertical: 16),
        decoration: BoxDecoration(
            color: notifires.getBoxColor,
            borderRadius: BorderRadius.circular(12)),
        // border: Border.all(color: notifires.getGrey4whiteColor)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  widget.prefixIconImage != null &&
                      widget.prefixIconImage!.isNotEmpty
                      ? Image.asset(
                    "${widget.prefixIconImage}",
                    height: 30,
                    color: widget.prefixIconColor ?? grey3,
                  )
                      : const SizedBox(),
                  const SizedBox(width: 13),
                  Text(
                    (selectedValue == null || selectedValue!.isEmpty)
                        ? widget.hintText
                        : selectedValue.toString().translate(context),
                    style: widget.textStyle ?? regular2(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: notifires.getwhiteblackColor,
            ),
            const SizedBox(
              width: 8,
            )
          ],
        ),
      ),
    );
  }
}
class LoadingDropdownBox extends StatelessWidget {
  final String loadingText;

  const LoadingDropdownBox({
    super.key,
    this.loadingText = "Loading...",
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer( // disables tap
      ignoring: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: notifires.getBoxColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                loadingText,
                style: regular2(context).copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
