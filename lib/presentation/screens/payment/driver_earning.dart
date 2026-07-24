import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/earning.dart';
import '../../cubits/payment/earning_cubit.dart';
import 'dart:ui' as ui;

class DriverEarning extends StatefulWidget {
  const DriverEarning({super.key});

  @override
  State<DriverEarning> createState() => _DriverEarningState();
}

class _DriverEarningState extends State<DriverEarning> {
  DateRangePickerController _datePickerController = DateRangePickerController();
  final DateRangePickerController customDatePickerController =
      DateRangePickerController();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String totalEarning = "0.0";
  String totalBooking = "0";
  DriverWalletModel? model;
  final List<String> _rangeOptions = [
    "Today",
    "Last 7 Days",
    "Last 30 Days",
    "This Month",
    "Custom",
  ];
  String _selectedRange = 'Today';
  DateTime? _startDate;
  DateTime? _endDate;
  bool isLoading = false;
  int offset = 0;
  List<DriverRide> rideList = [];

  @override
  void initState() {
    super.initState();
    _datePickerController = DateRangePickerController();
    _datePickerController.selectedDate = DateTime.now();
    _setDateRange('Today');
  }

  void _fetchEarnings({bool isRefresh = false}) {
    if (_startDate == null || _endDate == null) return;

    String formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate!);
    String formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate!);

    context.read<EarningCubit>().getEarningData(
      context: context,
      mapData: {
        'offset': "$offset",
        "limit": "10",
        "startDate": formattedStartDate,
        "endDate": formattedEndDate,
      },
    );

    if (isRefresh) {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.loadComplete();
    }
  }

  void _setDateRange(String range) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (range) {
      case 'Today':
        start = end = now;
        break;
      case 'Last 7 Days':
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 29));
        end = now;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'Custom':
        _showCustomDateRangePicker();
        return;
    }

    setState(() {
      _selectedRange = range;
      _startDate = start;
      _endDate = end;
      offset = 0;
      rideList.clear();
    });

    _fetchEarnings();
  }

  void _onLoading() {
    if ((offset.toString() == totalBooking)) {
      _refreshController.loadNoData();
    } else {
      _fetchEarnings();
    }
  }

  void _onRefresh() {
    setState(() {
      offset = 0;
      rideList.clear();
    });
    _fetchEarnings(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: BlocBuilder<EarningCubit, EarningState>(
        builder: (context, state) {
          if (state is EarningLoading && offset == 0) {
            isLoading = true;
          } else if (state is EarningSuccess) {
            isLoading = false;
            model = state.model;
            totalBooking = model?.data?.totalRides.toString() ?? "0";
            totalEarning = model?.data?.totalEarnings.toString() ?? "0";
            offset = model?.data?.offset ?? 0;
            if (offset == 0) {
              rideList = model?.data?.driverRides ?? [];
            } else {
              rideList.addAll(model?.data?.driverRides ?? []);
            }
            context.read<EarningCubit>().resetEarningData();
          } else if (state is EarningError) {
            isLoading = false;
            showErrorToastMessage(state.errorMessage ?? "");
            context.read<EarningCubit>().resetEarningData();
          }

          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: offset.toString() == totalBooking ? false : true,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      height: 130,
                      child: Directionality(
                        textDirection:
                            Localizations.localeOf(context).languageCode == "ar"
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                        child: SfDateRangePicker(
                          backgroundColor: notifires.getbgcolor,
                          controller: _datePickerController,
                          view: DateRangePickerView.month,
                          selectionMode: DateRangePickerSelectionMode.single,
                          initialSelectedDate: _startDate,
                          showNavigationArrow: true,
                          allowViewNavigation: false,
                          headerHeight: 40,
                          headerStyle: DateRangePickerHeaderStyle(
                            backgroundColor: notifires.getbgcolor,
                            textAlign: TextAlign.center,
                            textStyle: heading2Grey1(context),
                          ),
                          monthViewSettings:
                              const DateRangePickerMonthViewSettings(
                            numberOfWeeksInView: 1,
                            enableSwipeSelection: false,
                            dayFormat: '',
                            viewHeaderHeight: 0,
                          ),
                          maxDate: DateTime.now(),
                          enablePastDates: true,
                          showTodayButton: false,
                          selectionColor: Colors.transparent,
                          startRangeSelectionColor: Colors.transparent,
                          endRangeSelectionColor: Colors.transparent,
                          rangeSelectionColor: Colors.transparent,
                          onSelectionChanged:
                              (DateRangePickerSelectionChangedArgs args) {
                            if (args.value is DateTime) {
                              setState(() {
                                _selectedRange = 'Custom';
                                _startDate = args.value;
                                _endDate = args.value;
                                _datePickerController.selectedDate = args.value;
                                offset = 0; // Reset offset for new selection
                                rideList
                                    .clear(); // Clear ride list for new selection
                              });
                              _fetchEarnings();
                            }
                          },
                          cellBuilder: (context, cellDetails) {
                            final isSelected = isSameDate(
                                _datePickerController.selectedDate,
                                cellDetails.date);
                            final now = DateTime.now();
                            final today =
                                DateTime(now.year, now.month, now.day);
                            final isTodayOrPast =
                                !cellDetails.date.isAfter(today);

                            return IgnorePointer(
                              ignoring: !isTodayOrPast,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected && isTodayOrPast
                                      ? themeColor
                                      : isTodayOrPast
                                          ? Colors.transparent
                                          : grey5,
                                  border: Border.all(
                                      color: isTodayOrPast
                                          ? themeColor.withValues(alpha: 0.3)
                                          : grey5),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat.E(
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                          .format(cellDetails.date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected && isTodayOrPast
                                            ? whiteColor
                                            : isTodayOrPast
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      convertToLocaleDigits(context,
                                          cellDetails.date.day.toString()),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected && isTodayOrPast
                                            ? whiteColor
                                            : isTodayOrPast
                                                ? Colors.black87
                                                : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_startDate != null && _endDate != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_startDate.toString() !=
                                        _endDate.toString())
                                      Text(
                                        "From".translate(context),
                                        style: regular(context)
                                            .copyWith(color: grey3),
                                      ),
                                    Text(
                                      DateFormat(
                                              'dd MMM yyyy',
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                          .format(_startDate!),
                                      style: regular(context)
                                          .copyWith(color: grey1),
                                    ),
                                  ],
                                ),
                              ),
                            if (_startDate.toString() != _endDate.toString())
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "To".translate(context),
                                      style: regular(context)
                                          .copyWith(color: grey3),
                                    ),
                                    Text(
                                      DateFormat(
                                              'dd MMM yyyy',
                                              Localizations.localeOf(context)
                                                  .languageCode)
                                          .format(_endDate!),
                                      style: regular(context)
                                          .copyWith(color: grey1),
                                    ),
                                  ],
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                showMenu(
                                  color: notifires.getbgcolor,
                                  context: context,
                                  position: const RelativeRect.fromLTRB(
                                      100, 200, 16, 100),
                                  items: _rangeOptions.map((option) {
                                    IconData iconData;
                                    switch (option) {
                                      case 'Today':
                                        iconData = Icons.today;
                                        break;
                                      case 'Last 7 Days':
                                        iconData = Icons.calendar_view_week;
                                        break;
                                      case 'Last 30 Days':
                                        iconData = Icons.calendar_month;
                                        break;
                                      case 'This Month':
                                        iconData = Icons.date_range;
                                        break;
                                      case 'Custom':
                                        iconData = Icons.edit_calendar;
                                        break;
                                      default:
                                        iconData = Icons.calendar_today;
                                    }
                                    return PopupMenuItem<String>(
                                      value: option,
                                      child: Row(
                                        children: [
                                          Icon(iconData, color: themeColor),
                                          const SizedBox(width: 10),
                                          Text(
                                            option.translate(context),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ).then((val) {
                                  if (val != null) _setDateRange(val);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list,
                                        color: Colors.blueAccent),
                                    const SizedBox(width: 10),
                                    Text(
                                      _selectedRange.translate(context),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isLoading) LinearProgressIndicator(color: themeColor),
                    const SizedBox(height: 20),
                    if (!isLoading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCard("$currency $totalEarning",
                              "Total Earnings".translate(context)),
                          const SizedBox(width: 12),
                          _buildCard(totalBooking,
                              "Total Bookings".translate(context)),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (!isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Transactions".translate(context),
                              style: headingBlack(context),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!isLoading)
                      rideList.isEmpty
                          ? Center(
                              child: Text(
                                  "No transactions found".translate(context)))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (context, index) =>
                                  Divider(color: grey5),
                              itemCount: rideList.length,
                              itemBuilder: (context, index) {
                                final data = rideList[index];
                                return GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 15),
                                    decoration: BoxDecoration(
                                      color: whiteColor,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // LEFT SIDE
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data.status
                                                      ?.toString()
                                                      .translate(context) ??
                                                  "",
                                              style: headingBlack(context)
                                                  .copyWith(fontSize: 16),
                                              softWrap: true,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  data.rideDate.toString(),
                                                  style: regular(context)
                                                      .copyWith(fontSize: 12),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  data.token ?? "",
                                                  style: regular(context).copyWith(color: grey1,fontWeight: FontWeight.bold)
                                                      .copyWith(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // RIGHT SIDE
                                        Text(
                                          "$currency ${data.vendorCommission ?? "0"}",
                                          style: headingBlack(context).copyWith(
                                            color: greentext,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(String value, String label) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.translate(context),
            style: headingBlackBold(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(label, style: regular(context)),
        ],
      ),
    );
  }

  bool isSameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showCustomDateRangePicker() {
    showModalBottomSheet(
      backgroundColor: notifires.getbgcolor,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        DateTime? tempStart;
        DateTime? tempEnd;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Custom Date Range".translate(context),
                    style: headingBlack(context).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Theme(
                    data: Theme.of(context).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green, // text color
                          textStyle: heading2Grey1(context),
                        ),
                      ),
                    ),
                    child: SfDateRangePicker(
                        backgroundColor: notifires.getbgcolor,
                        controller: customDatePickerController,
                        headerStyle: DateRangePickerHeaderStyle(
                          backgroundColor: notifires.getbgcolor,
                          textAlign: TextAlign.center,
                          textStyle: heading2Grey1(context),
                        ),
                        cancelText: "CANCEL".translate(context),
                        confirmText: "OK".translate(context),
                        selectionColor: themeColor,
                        startRangeSelectionColor: themeColor,
                        rangeSelectionColor: themeColor.withValues(alpha: .1),
                        monthViewSettings: DateRangePickerMonthViewSettings(
                          dayFormat: 'EEE',
                          viewHeaderStyle: DateRangePickerViewHeaderStyle(
                            textStyle: regular2(context),
                          ),
                        ),
                        endRangeSelectionColor: themeColor,
                        selectionMode: DateRangePickerSelectionMode.range,
                        showActionButtons: true,
                        maxDate: DateTime.now(),
                        onSelectionChanged:
                            (DateRangePickerSelectionChangedArgs args) {
                          if (args.value is PickerDateRange) {
                            final PickerDateRange range = args.value;
                            setModalState(() {
                              if (range.startDate != null &&
                                  range.endDate != null) {
                                tempStart = range.startDate!;
                                tempEnd = range.endDate!;
                              }
                            });
                          }
                        },
                        onCancel: () => Navigator.pop(context),
                        onSubmit: (val) {
                          debugPrint("Start: $tempStart, End: $tempEnd");

                          if (tempStart != null && tempEnd != null) {
                            setState(() {
                              _selectedRange = 'Custom';
                              _startDate = tempStart;
                              _endDate = tempEnd;
                              offset = 0;
                              rideList.clear();
                            });
                            _fetchEarnings();
                            Navigator.pop(context);
                          }
                        }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _datePickerController.dispose();
    super.dispose();
  }
}

String convertToLocaleDigits(BuildContext context, String input) {
  final locale = Localizations.localeOf(context).languageCode;

  if (locale == 'ar') {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  // For non-Arabic locales, return original input
  return input;
}
