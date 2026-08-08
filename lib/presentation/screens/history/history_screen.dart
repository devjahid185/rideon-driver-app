import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../data/repositories/food_delivery_repository.dart';
import '../../../domain/entities/history.dart';
import '../../cubits/history/history_cubit.dart';
import '../home/food_active_delivery_screen.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool? isBackButton;
  const HistoryScreen({super.key, this.isBackButton});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FoodDeliveryRepository _foodRepository = FoodDeliveryRepository();
  final RefreshController refreshController = RefreshController();

  final List<String> statuses = const [
    'All',
    'Completed',
    'Rejected',
    'Cancelled',
  ];

  List<Bookings> bookings = [];
  List<Map<String, dynamic>> foodOrders = [];
  List<Map<String, dynamic>> availableFoodOrders = [];
  int offset = 0;
  bool isPaginating = true;
  bool foodLoading = false;
  int? acceptingFoodOrderId;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData(isInitial: true);
    });
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  Future<void> fetchData({bool isInitial = false}) async {
    if (isInitial) {
      offset = 0;
      await _loadFoodOrders();
    }

    final type = statuses[selectedIndex].toLowerCase();
    await context.read<HistoryCubit>().getHistoryData(
          context: context,
          bookingKeyMap: {
            'type': type,
            'offset': offset.toString(),
          },
          type: type,
        );
  }

  String? _foodStatusForSelectedTab() {
    final status = statuses[selectedIndex].toLowerCase();
    if (status == 'all') return null;
    if (status == 'completed') return 'delivered';
    if (status == 'cancelled') return 'cancelled';
    return '__empty__';
  }

  Future<void> _loadFoodOrders() async {
    final foodStatus = _foodStatusForSelectedTab();
    if (foodStatus == '__empty__') {
      if (mounted) {
        setState(() {
          foodOrders = [];
          availableFoodOrders = [];
        });
      }
      return;
    }

    if (mounted) setState(() => foodLoading = true);
    try {
      final assignedResponse =
          await _foodRepository.getMyOrders(status: foodStatus);
      final assignedRaw = assignedResponse['data'];
      final assigned = assignedRaw is List
          ? assignedRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      List<Map<String, dynamic>> available = [];
      if (statuses[selectedIndex].toLowerCase() == 'all') {
        final availableResponse = await _foodRepository.getAvailableOrders();
        final availableRaw = availableResponse['data'];
        available = availableRaw is List
            ? availableRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where((order) {
                final driverId = (order['driver_id'] ?? '').toString();
                return driverId.isEmpty || driverId == 'null';
              }).toList()
            : <Map<String, dynamic>>[];
      }

      if (mounted) {
        setState(() {
          foodOrders = assigned;
          availableFoodOrders = available;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          foodOrders = [];
          availableFoodOrders = [];
        });
      }
    } finally {
      if (mounted) setState(() => foodLoading = false);
    }
  }

  Future<void> _acceptAvailableFoodOrder(Map<String, dynamic> order) async {
    final orderId = int.tryParse('${order['id']}') ?? 0;
    if (orderId <= 0 || acceptingFoodOrderId != null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final orderNo = (order['order_number'] ?? 'Food Order').toString();
        final amount = double.tryParse(
                '${order['driver_commission'] ?? order['delivery_fee'] ?? 0}') ??
            0;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.delivery_dining_rounded,
                      color: themeColor, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  'Accept this delivery?'.translate(context),
                  style: headingBlackBold(context).copyWith(fontSize: 19),
                ),
                const SizedBox(height: 6),
                Text(
                  '$orderNo  |  $currency ${_formatMoney(amount)}',
                  style: regular(context).copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  'This order is still available. Once accepted, it will be added to your active deliveries.'
                      .translate(context),
                  textAlign: TextAlign.center,
                  style: regular(context)
                      .copyWith(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text('Not now'.translate(context)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(sheetContext, true),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text('Accept Order'.translate(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() => acceptingFoodOrderId = orderId);
    try {
      final response = await _foodRepository.acceptOrder(orderId);
      if (!mounted) return;
      if (response['status'] == 200) {
        setState(() {
          availableFoodOrders
              .removeWhere((item) => '${item['id']}' == '$orderId');
          acceptingFoodOrderId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted successfully'.translate(context)),
            backgroundColor: appgreen,
          ),
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodActiveDeliveryScreen(orderId: orderId),
          ),
        );
        if (mounted) await _loadFoodOrders();
        return;
      }
      throw Exception(
          (response['message'] ?? 'This order is no longer available')
              .toString());
    } catch (error) {
      if (!mounted) return;
      setState(() => acceptingFoodOrderId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: redColor,
        ),
      );
      await _loadFoodOrders();
    }
  }

  void onRefresh() async {
    bookings.clear();
    offset = 0;
    isPaginating = true;
    await fetchData(isInitial: true);
    refreshController.refreshCompleted();
    refreshController.loadComplete();
  }

  void onLoading() async {
    if (offset == -1) {
      refreshController.loadComplete();
      refreshController.loadNoData();
      return;
    }

    isPaginating = false;
    await fetchData();
    refreshController.loadComplete();
  }

  String formatSimpleDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      final inputDate = DateTime.tryParse(dateStr);
      if (inputDate == null) return dateStr;
      return DateFormat('dd MMM yyyy').format(inputDate);
    } catch (_) {
      return dateStr;
    }
  }

  String formatTime(String dateStr) {
    try {
      if (dateStr.isEmpty) return '';
      final inputDate = DateTime.tryParse(dateStr);
      if (inputDate == null) return '';
      return DateFormat('hh:mm a').format(inputDate);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.isBackButton == true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: widget.isBackButton == true
            ? const CustomAppBar(title: 'History')
            : AppBar(
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'History'.translate(context),
                  style: headingBlackBold(context)
                      .copyWith(fontSize: 24, color: blackColor),
                ),
                backgroundColor: const Color(0xFFF6F7FB),
                automaticallyImplyLeading: false,
                elevation: 0,
              ),
        body: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            if (state is HistorySuccess &&
                statuses[selectedIndex].toLowerCase() == state.type) {
              isPaginating = true;
              if (offset == 0) {
                bookings = state.bookings ?? [];
              } else {
                bookings.addAll(state.bookings ?? []);
              }
              offset = state.historyModel?.data?.offset ?? 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.read<HistoryCubit>().resetHistoryData();
              });
            }

            final loadingInitial = state is HistoryLoading &&
                isPaginating &&
                bookings.isEmpty &&
                foodOrders.isEmpty;
            final entries = _mixedEntries();

            return SmartRefresher(
              controller: refreshController,
              onRefresh: onRefresh,
              onLoading: onLoading,
              enablePullUp: offset != -1,
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _HeaderSummary(
                    selectedLabel: statuses[selectedIndex],
                    rideCount: bookings.length,
                    foodCount: foodOrders.length + availableFoodOrders.length,
                    totalAmount: _totalAmount(),
                  ),
                  _StatusSelector(
                    statuses: statuses,
                    selectedIndex: selectedIndex,
                    onChanged: (index) {
                      if (selectedIndex == index) return;
                      bookings.clear();
                      foodOrders.clear();
                      availableFoodOrders.clear();
                      setState(() {
                        selectedIndex = index;
                        offset = 0;
                        isPaginating = true;
                      });
                      fetchData(isInitial: true);
                    },
                  ),
                  if (loadingInitial || (foodLoading && entries.isEmpty))
                    const _HistoryShimmerList()
                  else if (entries.isEmpty)
                    _EmptyHistory(status: statuses[selectedIndex])
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      child: Column(
                        children: [
                          ...entries.map((entry) {
                            return entry.isFood
                                ? _FoodHistoryCard(
                                    order: entry.foodOrder!,
                                    formatDate: formatSimpleDate,
                                    formatTime: formatTime,
                                    isAvailable: entry.isAvailableFood,
                                    isAccepting: acceptingFoodOrderId ==
                                        int.tryParse(
                                            '${entry.foodOrder!['id']}'),
                                    onAccept: _acceptAvailableFoodOrder,
                                  )
                                : _RideHistoryCard(
                                    rideData: entry.booking!,
                                    formatDate: formatSimpleDate,
                                    formatTime: formatTime,
                                  );
                          }),
                          if (foodLoading) const _SmallLoadingCard(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_HistoryEntry> _mixedEntries() {
    final entries = <_HistoryEntry>[
      ...bookings.map((booking) => _HistoryEntry.ride(booking)),
      ...foodOrders.map((order) => _HistoryEntry.food(order)),
      ...availableFoodOrders.map((order) => _HistoryEntry.availableFood(order)),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  double _totalAmount() {
    double sum = 0;
    for (final booking in bookings) {
      sum += double.tryParse(
            '${booking.vendorCommission ?? booking.total ?? 0}',
          ) ??
          0;
    }
    for (final order in foodOrders) {
      sum += double.tryParse(
            '${order['driver_commission'] ?? order['delivery_fee'] ?? 0}',
          ) ??
          0;
    }
    return sum;
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    super.key,
    required this.selectedLabel,
    required this.rideCount,
    required this.foodCount,
    required this.totalAmount,
  });

  final String selectedLabel;
  final int rideCount;
  final int foodCount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final totalCount = rideCount + foodCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, const Color(0xFF0B2F6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: .25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.timeline_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedLabel.translate(context)} history',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ride and food delivery records'.translate(context),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _SummaryTile(label: 'Orders', value: '$totalCount')),
              const SizedBox(width: 10),
              Expanded(
                  child: _SummaryTile(label: 'Rides', value: '$rideCount')),
              const SizedBox(width: 10),
              Expanded(child: _SummaryTile(label: 'Food', value: '$foodCount')),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryTile(
            label: 'Total earnings',
            value: '$currency ${_formatMoney(totalAmount)}',
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, this.wide = false});

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.translate(context),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .68), fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector(
      {required this.statuses,
      required this.selectedIndex,
      required this.onChanged});

  final List<String> statuses;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? themeColor : const Color(0xFFE2E6EF)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: themeColor.withValues(alpha: .20),
                            blurRadius: 14,
                            offset: const Offset(0, 7))
                      ]
                    : null,
              ),
              child: Text(
                statuses[index].translate(context),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemCount: statuses.length,
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard(
      {required this.rideData,
      required this.formatDate,
      required this.formatTime});

  final Bookings rideData;
  final String Function(String) formatDate;
  final String Function(String) formatTime;

  @override
  Widget build(BuildContext context) {
    final status = rideData.status ?? '';
    final isParcel = (rideData.deliveryPhotos ?? []).isNotEmpty;
    final date = '${rideData.rideDate ?? rideData.createdAt ?? ''}';
    final pickup = rideData.pickupLocation?.address ?? '';
    final drop = rideData.dropoffLocation?.address ?? '';

    return _HistoryCardShell(
      onTap: () => goTo(HistoryDetailScreen(rideData: rideData)),
      accentColor: isParcel ? orangeColor : themeColor,
      leadingIcon:
          isParcel ? Icons.inventory_2_rounded : Icons.local_taxi_rounded,
      title: isParcel
          ? 'Parcel Delivery'.translate(context)
          : 'Ride Booking'.translate(context),
      subtitle: formatDate(date),
      trailing: '$currency ${rideData.total ?? 0}',
      status: status,
      statusColor: getStatusColor(status),
      child: Column(
        children: [
          _RouteLine(
            pickup: pickup.isEmpty
                ? 'Pickup location not available'.translate(context)
                : pickup,
            drop: drop.isEmpty
                ? 'Drop-off location not available'.translate(context)
                : drop,
            pickupIcon: Icons.radio_button_checked_rounded,
            dropIcon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 14),
          _CardFooter(
            leftIcon: Icons.access_time_rounded,
            leftText:
                formatTime(date).isEmpty ? formatDate(date) : formatTime(date),
            rightIcon: isParcel
                ? Icons.shopping_bag_rounded
                : Icons.directions_car_filled_rounded,
            rightText: isParcel
                ? 'Parcel'.translate(context)
                : 'Ride'.translate(context),
          ),
        ],
      ),
    );
  }
}

class _FoodHistoryCard extends StatelessWidget {
  const _FoodHistoryCard({
    required this.order,
    required this.formatDate,
    required this.formatTime,
    required this.isAvailable,
    required this.isAccepting,
    required this.onAccept,
  });

  final Map<String, dynamic> order;
  final String Function(String) formatDate;
  final String Function(String) formatTime;
  final bool isAvailable;
  final bool isAccepting;
  final ValueChanged<Map<String, dynamic>> onAccept;

  @override
  Widget build(BuildContext context) {
    final orderId = int.tryParse('${order['id']}') ?? 0;
    final status = (order['status'] ?? '').toString();
    final orderNo = (order['order_number'] ?? '').toString();
    final total = double.tryParse('${order['total_amount'] ?? 0}') ?? 0;
    final commission = double.tryParse(
          '${order['driver_commission'] ?? order['delivery_fee'] ?? 0}',
        ) ??
        0;
    final createdAt =
        (order['created_at'] ?? order['placed_at'] ?? '').toString();
    final restaurant = _asMap(order['restaurant']) ?? {};
    final branch = _asMap(order['branch']) ?? {};
    final pickup = [
      (restaurant['name'] ?? '').toString(),
      (branch['address'] ?? '').toString(),
    ].where((part) => part.trim().isNotEmpty).join(' - ');
    final drop = (order['delivery_address'] ?? '').toString();

    return _HistoryCardShell(
      onTap: isAvailable || orderId <= 0
          ? null
          : () => goTo(FoodActiveDeliveryScreen(orderId: orderId)),
      accentColor: isAvailable ? themeColor : _foodStatusColor(status),
      leadingIcon: Icons.fastfood_rounded,
      title: orderNo.isEmpty ? 'Food Delivery'.translate(context) : orderNo,
      subtitle: formatDate(createdAt),
      trailing: '$currency ${_formatMoney(commission)}',
      status: isAvailable
          ? 'Available'.translate(context)
          : _foodStatusLabel(status).translate(context),
      statusColor: isAvailable ? themeColor : _foodStatusColor(status),
      child: Column(
        children: [
          _RouteLine(
            pickup: pickup.isEmpty
                ? 'Restaurant pickup'.translate(context)
                : pickup,
            drop: drop.isEmpty
                ? 'Delivery address not available'.translate(context)
                : drop,
            pickupIcon: Icons.storefront_rounded,
            dropIcon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 14),
          _CardFooter(
            leftIcon: Icons.access_time_rounded,
            leftText: formatTime(createdAt).isEmpty
                ? formatDate(createdAt)
                : formatTime(createdAt),
            rightIcon: Icons.payments_outlined,
            rightText:
                '${'Order total'.translate(context)}: $currency ${_formatMoney(total)}',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: appgreen.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: appgreen.withValues(alpha: .22),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: appgreen, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAvailable
                        ? 'Available delivery earning'.translate(context)
                        : 'Driver earning'.translate(context),
                    style: regular(context).copyWith(
                      color: appgreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$currency ${_formatMoney(commission)}',
                  style: headingBlackBold(context).copyWith(
                    color: appgreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isAvailable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isAccepting ? null : () => onAccept(order),
                icon: isAccepting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delivery_dining_rounded),
                label: Text(isAccepting
                    ? 'Accepting...'.translate(context)
                    : 'Accept this available order'.translate(context)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryCardShell extends StatelessWidget {
  const _HistoryCardShell({
    required this.onTap,
    required this.accentColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.status,
    required this.statusColor,
    required this.child,
  });

  final VoidCallback? onTap;
  final Color accentColor;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String trailing;
  final String status;
  final Color statusColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE9EDF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(leadingIcon, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              headingBlackBold(context).copyWith(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: regular(context)
                              .copyWith(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trailing,
                        style: headingBlackBold(context)
                            .copyWith(fontSize: 15, color: greentext)),
                    const SizedBox(height: 7),
                    _StatusPill(text: status, color: statusColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine(
      {required this.pickup,
      required this.drop,
      required this.pickupIcon,
      required this.dropIcon});

  final String pickup;
  final String drop;
  final IconData pickupIcon;
  final IconData dropIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(pickupIcon, size: 20, color: themeColor),
            Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFD8DEEA)),
            Icon(dropIcon, size: 21, color: Colors.black87),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickup,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: headingBlack(context)
                      .copyWith(fontSize: 13, height: 1.35)),
              const SizedBox(height: 18),
              Text(drop,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: headingBlack(context)
                      .copyWith(fontSize: 13, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter(
      {required this.leftIcon,
      required this.leftText,
      required this.rightIcon,
      required this.rightText});

  final IconData leftIcon;
  final String leftText;
  final IconData rightIcon;
  final String rightText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(leftIcon, size: 17, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
              child: Text(leftText,
                  style: regular(context)
                      .copyWith(fontSize: 12, color: Colors.black54))),
          Icon(rightIcon, size: 17, color: Colors.black54),
          const SizedBox(width: 6),
          Text(rightText,
              style: regular(context)
                  .copyWith(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HistoryShimmerList extends StatelessWidget {
  const _HistoryShimmerList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        children: List.generate(
          5,
          (_) => const _SmallLoadingCard(height: 178),
        ),
      ),
    );
  }
}

class _SmallLoadingCard extends StatelessWidget {
  const _SmallLoadingCard({this.height = 92});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Shimmer.fromColors(
        baseColor: grey5,
        highlightColor: Colors.white,
        child: Container(
          height: height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 28),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.history_toggle_off_rounded,
                  color: themeColor, size: 34),
            ),
            const SizedBox(height: 18),
            Text('No history found'.translate(context),
                style: headingBlackBold(context).copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'No ${status.toLowerCase()} records are available right now.'
                  .translate(context),
              textAlign: TextAlign.center,
              style:
                  regular(context).copyWith(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry {
  _HistoryEntry.ride(this.booking)
      : foodOrder = null,
        isFood = false,
        isAvailableFood = false,
        date = _parseBookingDate(booking);

  _HistoryEntry.food(this.foodOrder)
      : booking = null,
        isFood = true,
        isAvailableFood = false,
        date = _parseFoodDate(foodOrder);

  _HistoryEntry.availableFood(this.foodOrder)
      : booking = null,
        isFood = true,
        isAvailableFood = true,
        date = _parseFoodDate(foodOrder);

  final Bookings? booking;
  final Map<String, dynamic>? foodOrder;
  final bool isFood;
  final bool isAvailableFood;
  final DateTime date;
}

DateTime _parseBookingDate(Bookings? booking) {
  return DateTime.tryParse(
          '${booking?.rideDate ?? booking?.createdAt ?? ''}') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime _parseFoodDate(Map<String, dynamic>? order) {
  return DateTime.tryParse(
          '${order?['created_at'] ?? order?['placed_at'] ?? ''}') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _foodStatusLabel(String status) {
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

Color _foodStatusColor(String status) {
  switch (status) {
    case 'delivered':
      return appgreen;
    case 'cancelled':
      return redColor;
    case 'ready_for_pickup':
    case 'picked_up':
      return Colors.deepPurple;
    case 'on_the_way':
      return blueColor;
    case 'accepted':
    case 'preparing':
      return orangeColor;
    default:
      return Colors.black54;
  }
}

String _formatMoney(double amount) {
  if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
  return amount.toStringAsFixed(2);
}
