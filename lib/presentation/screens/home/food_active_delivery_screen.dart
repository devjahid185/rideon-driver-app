import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_on_driver/core/extensions/workspace.dart';
import 'package:ride_on_driver/core/utils/common_widget.dart';
import 'package:ride_on_driver/core/utils/theme/project_color.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/data/repositories/food_delivery_repository.dart';
import 'package:ride_on_driver/presentation/cubits/location/get_polyline_cubit.dart';
import 'package:ride_on_driver/presentation/cubits/location/location_cubit.dart';
import 'package:ride_on_driver/services/food_order_tracking_service.dart';

class FoodActiveDeliveryScreen extends StatefulWidget {
  final int orderId;
  const FoodActiveDeliveryScreen({super.key, required this.orderId});

  @override
  State<FoodActiveDeliveryScreen> createState() =>
      _FoodActiveDeliveryScreenState();
}

class _FoodActiveDeliveryScreenState extends State<FoodActiveDeliveryScreen> {
  final FoodDeliveryRepository _repository = FoodDeliveryRepository();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  late final MarkerCubit _markerCubit;
  late final GetPolylineCubit _polylineCubit;
  late final RideLocationCubit _rideLocationCubit;
  Timer? _timer;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _timeline = [];
  LatLng? _currentLocation;
  String? _lastRouteKey;
  bool _loading = true;
  bool _busy = false;
  bool _deliveredDialogShown = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _markerCubit = context.read<MarkerCubit>();
    _polylineCubit = context.read<GetPolylineCubit>();
    _rideLocationCubit = context.read<RideLocationCubit>();
    _markerCubit.removeMarker();
    _polylineCubit.resetPolylines();
    _rideLocationCubit.startLiveLocationTracking();
    _resolveInitialLocation();
    _load();
    _timer =
        Timer.periodic(const Duration(seconds: 6), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    final status = (_order?['status'] ?? '').toString();
    if (status == 'delivered' || status == 'cancelled') {
      FoodOrderTrackingService.instance.stop();
    }
    _timer?.cancel();
    _markerCubit.removeMarker();
    _polylineCubit.resetPolylines();
    if (_mapReady) {
      _mapController.future
          .then((controller) => controller.dispose())
          .catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _resolveInitialLocation() async {
    final lat = double.tryParse(latitudeGlobal);
    final lng = double.tryParse(longitudeGlobal);
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      _setCurrentLocation(LatLng(lat, lng));
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();
      final allowed = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!allowed) return;
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _setCurrentLocation(LatLng(position.latitude, position.longitude));
    } catch (_) {
      // The live location cubit will keep trying; keep map usable with pickup/drop markers.
    }
  }

  void _setCurrentLocation(LatLng location) {
    _currentLocation = location;
    _syncMap();
    if (mounted) setState(() {});
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    try {
      final detailsResp = await _repository.getOrderDetails(widget.orderId);
      if ((detailsResp['status'] ?? 0) == 200 && detailsResp['data'] is Map) {
        _order = Map<String, dynamic>.from(detailsResp['data']);
      } else {
        final ordersResp = await _repository.getAvailableOrders();
        if ((ordersResp['status'] ?? 0) == 200) {
          final List raw = (ordersResp['data'] as List?) ?? [];
          final list = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _order = list.cast<Map<String, dynamic>?>().firstWhere(
                (e) => (e?['id'] ?? '').toString() == widget.orderId.toString(),
                orElse: () => _order,
              );
        }
      }

      _syncLiveTracking();
      _syncMap();

      final timelineResp = await _repository.orderTimeline(widget.orderId);
      if ((timelineResp['status'] ?? 0) == 200) {
        final List raw = (timelineResp['data'] as List?) ?? [];
        _timeline = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      //
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _syncLiveTracking() async {
    final order = _order;
    if (order == null) return;
    final status = (order['status'] ?? '').toString();
    final orderNo = (order['order_number'] ?? '').toString();
    if (status == 'on_the_way') {
      await FoodOrderTrackingService.instance.start(
        orderId: widget.orderId,
        orderNumber: orderNo,
        status: status,
      );
      return;
    }
    if (status == 'delivered' || status == 'cancelled') {
      await FoodOrderTrackingService.instance.stop();
    }
  }

  void _syncMap() {
    final order = _order;
    if (order == null) return;

    final pickup = _pickupLatLng(order);
    final drop = _dropLatLng(order);
    final current = _currentLocation;

    if (current != null) {
      _markerCubit.addOrUpdateMarker(
        current,
        'Driver',
        'Driver_marker',
        'assets/images/car_marker.png',
        88,
      );
    }
    if (pickup != null) {
      _markerCubit.addOrUpdateMarker(
        pickup,
        'Restaurant Pickup',
        'User_marker',
        'assets/images/pin_user.png',
        44,
      );
    }
    if (drop != null) {
      _markerCubit.addOrUpdateMarker(
        drop,
        'Customer Drop-off',
        'Drop_marker',
        'assets/images/drop_pin.png',
        62,
      );
    }

    final target = _isHeadingToPickup(order) ? pickup : drop;
    if (current == null || target == null) return;

    final status = (order['status'] ?? '').toString();
    final routeKey =
        '${current.latitude.toStringAsFixed(5)},${current.longitude.toStringAsFixed(5)}'
        '-${target.latitude.toStringAsFixed(5)},${target.longitude.toStringAsFixed(5)}-$status';
    if (_lastRouteKey == routeKey) return;
    _lastRouteKey = routeKey;

    _polylineCubit.getPolyline(
      sourcelat: current.latitude,
      sourcelng: current.longitude,
      destinationlat: target.latitude,
      destinationlng: target.longitude,
      isPickupRoute: _isHeadingToPickup(order),
    );
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'ready_for_pickup':
        return 'picked_up';
      case 'picked_up':
        return 'on_the_way';
      case 'on_the_way':
        return 'delivered';
      default:
        return '';
    }
  }

  String _nextLabel(String next) {
    switch (next) {
      case 'picked_up':
        return 'ARRIVED / PICKED UP';
      case 'on_the_way':
        return 'START DELIVERY';
      case 'delivered':
        return 'DELIVERED';
      default:
        return 'WAITING';
    }
  }

  Future<void> _moveNext() async {
    if (_order == null || _busy) return;
    final status = (_order!['status'] ?? '').toString();
    final next = _nextStatus(status);
    if (next.isEmpty) return;
    String? deliveryOtp;
    if (next == 'delivered') {
      deliveryOtp = await _askCustomerDeliveryOtp();
      if (deliveryOtp == null || deliveryOtp.isEmpty) return;
    }
    setState(() => _busy = true);
    try {
      await _repository.updateOrderStatus(
        orderId: widget.orderId,
        status: next,
        deliveryOtp: deliveryOtp,
      );
      await _load(silent: true);
      await _syncLiveTracking();
      final current = (_order?['status'] ?? '').toString();
      if (current == 'delivered' && !_deliveredDialogShown && mounted) {
        _deliveredDialogShown = true;
        _showDeliveredDialog();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askCustomerDeliveryOtp() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Customer OTP'.translate(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask the customer for the delivery OTP shown in their order details.'
                  .translate(context),
              style: regular(context),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: headingBlack(context)
                  .copyWith(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.translate(context)),
          ),
          ElevatedButton(
            onPressed: () {
              final otp = controller.text.replaceAll(RegExp(r'\D'), '');
              if (otp.length != 4) return;
              Navigator.pop(ctx, otp);
            },
            child: Text('Verify'.translate(context)),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideLocationCubit, RideLocationState>(
      listener: (context, state) {
        if (state is RideLocationSucess && state.currentLocation != null) {
          _setCurrentLocation(state.currentLocation!);
        }
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Food Delivery'.translate(context))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Food Delivery'.translate(context))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Food order details not found'.translate(context),
              textAlign: TextAlign.center,
              style: headingBlack(context),
            ),
          ),
        ),
      );
    }

    final initial = _currentLocation ??
        _pickupLatLng(order) ??
        _dropLatLng(order) ??
        const LatLng(23.8103, 90.4125);

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: Stack(
          children: [
            _FoodRouteMap(
              initialPosition: initial,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                  _mapReady = true;
                }
                _syncMap();
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    _RoundMapButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _RoundMapButton(
                      icon: Icons.my_location_rounded,
                      onTap: _focusMap,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _FoodDeliverySheet(
                order: order,
                timeline: _timeline,
                currentLocation: _currentLocation,
                busy: _busy,
                nextStatus: _nextStatus((order['status'] ?? '').toString()),
                nextLabel:
                    _nextLabel(_nextStatus((order['status'] ?? '').toString())),
                headingToPickup: _isHeadingToPickup(order),
                onNavigate: _openNavigation,
                onMoveNext: _moveNext,
                onRefresh: () => _load(silent: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _focusMap() async {
    if (!_mapReady) return;
    final controller = await _mapController.future;
    final target =
        _currentLocation ?? (_order == null ? null : _pickupLatLng(_order!));
    if (target == null) return;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16)));
  }

  Future<void> _openNavigation() async {
    final order = _order;
    if (order == null) {
      showErrorToastMessage('Order is still loading. Please try again.');
      return;
    }

    final current = _currentLocation;
    final target =
        _isHeadingToPickup(order) ? _pickupLatLng(order) : _dropLatLng(order);
    if (target == null) {
      showErrorToastMessage(_isHeadingToPickup(order)
          ? 'Pickup location is not ready.'
          : 'Drop location is not ready.');
      return;
    }

    _lastRouteKey = null;
    _syncMap();
    if (!_mapReady) {
      showErrorToastMessage('Map is still loading. Please try again.');
      return;
    }

    final controller = await _mapController.future;
    if (current == null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      showErrorToastMessage(
          'Driver location is not ready yet. Showing destination.');
      return;
    }

    await _fitMapToPoints(controller, current, target);
  }

  Future<void> _fitMapToPoints(
    GoogleMapController controller,
    LatLng source,
    LatLng destination,
  ) async {
    final samePoint = source.latitude == destination.latitude &&
        source.longitude == destination.longitude;
    if (samePoint) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(source, 16));
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            source.latitude < destination.latitude
                ? source.latitude
                : destination.latitude,
            source.longitude < destination.longitude
                ? source.longitude
                : destination.longitude,
          ),
          northeast: LatLng(
            source.latitude > destination.latitude
                ? source.latitude
                : destination.latitude,
            source.longitude > destination.longitude
                ? source.longitude
                : destination.longitude,
          ),
        ),
        120,
      ),
    );
  }

  bool _isHeadingToPickup(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString();
    return status == 'placed' ||
        status == 'accepted' ||
        status == 'preparing' ||
        status == 'ready_for_pickup';
  }

  LatLng? _pickupLatLng(Map<String, dynamic> order) {
    final branch = _asMap(order['branch']);
    final lat = double.tryParse((branch?['latitude'] ?? '').toString());
    final lng = double.tryParse((branch?['longitude'] ?? '').toString());
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;
    return LatLng(lat, lng);
  }

  LatLng? _dropLatLng(Map<String, dynamic> order) {
    final lat = double.tryParse((order['delivery_latitude'] ?? '').toString());
    final lng = double.tryParse((order['delivery_longitude'] ?? '').toString());
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;
    return LatLng(lat, lng);
  }

  Future<void> _showDeliveredDialog() async {
    if (!mounted) return;
    final commission = double.tryParse(
          (_order?['driver_commission'] ?? _order?['delivery_fee'] ?? '0')
              .toString(),
        ) ??
        0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delivery Completed'.translate(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: greentext, size: 54),
            const SizedBox(height: 12),
            Text(
              'This food order has been marked as delivered successfully.'
                  .translate(context),
              textAlign: TextAlign.center,
              style: regular(context),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: greentext.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: greentext.withValues(alpha: .25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'ADDED TO YOUR WALLET'.translate(context),
                    style: TextStyle(
                      color: greentext,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency ${commission.toStringAsFixed(2)}',
                    style: headingBlackBold(context).copyWith(
                      color: greentext,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Back'.translate(context)),
          ),
        ],
      ),
    );
  }
}

class _FoodRouteMap extends StatefulWidget {
  const _FoodRouteMap({
    required this.initialPosition,
    required this.onMapCreated,
  });

  final LatLng initialPosition;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  State<_FoodRouteMap> createState() => _FoodRouteMapState();
}

class _FoodRouteMapState extends State<_FoodRouteMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarkerCubit, MarkerState>(
      builder: (context, markerState) {
        if (markerState is MarkerUpdated) {
          _markers = markerState.markers;
        }
        return BlocBuilder<GetPolylineCubit, GetPolylineState>(
          builder: (context, polylineState) {
            if (polylineState is GetPolylineUpdated) {
              _polylines = polylineState.polylines ?? {};
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
            }
            return GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: widget.initialPosition, zoom: 15),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _controller ??= controller;
                widget.onMapCreated(controller);
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
              },
            );
          },
        );
      },
    );
  }

  Future<void> _fitMap() async {
    final controller = _controller;
    if (controller == null) return;
    final points = [
      ..._polylines.expand((polyline) => polyline.points),
      ..._markers.map((marker) => marker.position),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(points.first, 16));
      return;
    }

    final minLat =
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final minLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final maxLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    if (minLat == maxLat && minLng == maxLng) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(points.first, 16));
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng)),
        110,
      ),
    );
  }
}

class _FoodDeliverySheet extends StatelessWidget {
  const _FoodDeliverySheet({
    required this.order,
    required this.timeline,
    required this.currentLocation,
    required this.busy,
    required this.nextStatus,
    required this.nextLabel,
    required this.headingToPickup,
    required this.onNavigate,
    required this.onMoveNext,
    required this.onRefresh,
  });

  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> timeline;
  final LatLng? currentLocation;
  final bool busy;
  final String nextStatus;
  final String nextLabel;
  final bool headingToPickup;
  final VoidCallback onNavigate;
  final Future<void> Function() onMoveNext;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '').toString();
    final customer = _asMap(order['customer']) ?? {};
    final branch = _asMap(order['branch']) ?? {};
    final customerName = _fullName(customer, fallback: 'Customer');
    final customerPhone = _phone(customer);
    final pickupAddress = (branch['address'] ?? '').toString();
    final dropAddress = (order['delivery_address'] ?? '').toString();
    final targetAddress = headingToPickup ? pickupAddress : dropAddress;
    final targetLabel =
        headingToPickup ? 'Pickup Location' : 'Drop-off Location';
    final targetLatLng =
        headingToPickup ? _latLngFromBranch(branch) : _latLngFromOrder(order);
    final distanceKm = currentLocation != null && targetLatLng != null
        ? Geolocator.distanceBetween(
              currentLocation!.latitude,
              currentLocation!.longitude,
              targetLatLng.latitude,
              targetLatLng.longitude,
            ) /
            1000
        : null;
    final etaMin = distanceKm == null
        ? null
        : ((distanceKm / 28) * 60).ceil().clamp(1, 999).toInt();

    return DraggableScrollableSheet(
      initialChildSize: .40,
      minChildSize: .29,
      maxChildSize: .68,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Center(
                child: InkWell(
                  onTap: onNavigate,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 16),
                    decoration: BoxDecoration(
                      color: yelloColor,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .16),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Colors.black),
                        const SizedBox(width: 12),
                        Text(
                          headingToPickup
                              ? 'Go to PickUp'.translate(context)
                              : 'Go to Drop'.translate(context),
                          style:
                              headingBlackBold(context).copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, -2)),
                    ],
                  ),
                  child: RefreshIndicator(
                    onRefresh: onRefresh,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.fastfood_rounded,
                                    color: Colors.black87, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customerName,
                                        style: headingBlackBold(context)
                                            .copyWith(fontSize: 17)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded,
                                            color: yelloColor, size: 20),
                                        const SizedBox(width: 3),
                                        Text('0.00',
                                            style: regular(context).copyWith(
                                                color: Colors.black54)),
                                        const SizedBox(width: 10),
                                        _StatusBadge(status: status),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (customerPhone.isNotEmpty)
                                InkWell(
                                  onTap: () => launchDialPad(customerPhone),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    height: 54,
                                    width: 54,
                                    decoration: BoxDecoration(
                                      color: greentext,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Icon(Icons.call_rounded,
                                        color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(height: 1),
                          const SizedBox(height: 18),
                          _MetricStrip(
                              distanceKm: distanceKm,
                              etaMin: etaMin,
                              order: order),
                          const SizedBox(height: 12),
                          _ActivePaymentBanner(order: order),
                          const SizedBox(height: 20),
                          Text(targetLabel.translate(context),
                              style: regular2(context).copyWith(fontSize: 16)),
                          const SizedBox(height: 14),
                          _AddressRow(
                            icon: headingToPickup
                                ? Icons.storefront_rounded
                                : Icons.location_on_rounded,
                            iconColor: headingToPickup ? themeColor : greentext,
                            address:
                                targetAddress.isEmpty ? '-' : targetAddress,
                          ),
                          if (pickupAddress.isNotEmpty &&
                              dropAddress.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _AddressRow(
                              icon: headingToPickup
                                  ? Icons.flag_rounded
                                  : Icons.storefront_rounded,
                              iconColor: Colors.black45,
                              address:
                                  headingToPickup ? dropAddress : pickupAddress,
                              compact: true,
                            ),
                          ],
                          const SizedBox(height: 22),
                          if (nextStatus.isNotEmpty)
                            AbsorbPointer(
                              absorbing: busy,
                              child: CustomSlideButton(
                                key: ValueKey(nextStatus),
                                textActiveColor: Colors.white,
                                textInactiveColor: Colors.white,
                                activeColor: nextStatus == 'delivered'
                                    ? greentext
                                    : themeColor,
                                inactiveColor: nextStatus == 'delivered'
                                    ? greentext
                                    : themeColor,
                                iconColor: Colors.white,
                                iconBoxColor:
                                    Colors.white.withValues(alpha: .35),
                                isOnRide: false,
                                acceptedText: 'DONE',
                                defaultText:
                                    busy ? 'PLEASE WAIT...' : nextLabel,
                                onChanged: (value) async {
                                  if (value && !busy) {
                                    await onMoveNext();
                                  }
                                },
                              ),
                            )
                          else
                            _WaitingStatus(status: status),
                          const SizedBox(height: 22),
                          if (timeline.isNotEmpty) ...[
                            Text('Timeline'.translate(context),
                                style: headingBlack(context)
                                    .copyWith(fontSize: 16)),
                            const SizedBox(height: 8),
                            ...timeline
                                .take(5)
                                .map((item) => _TimelineRow(item: item)),
                          ],
                        ],
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
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.distanceKm,
    required this.etaMin,
    required this.order,
  });

  final double? distanceKm;
  final int? etaMin;
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final commission = double.tryParse(
          (order['driver_commission'] ?? order['delivery_fee'] ?? '')
              .toString(),
        ) ??
        0;
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            label: 'Distance',
            value: distanceKm == null
                ? '-- km'
                : '${distanceKm!.toStringAsFixed(2)} km',
            icon: Icons.route_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniMetric(
            label: 'ETA',
            value: etaMin == null ? '-- min' : '$etaMin min',
            icon: Icons.timer_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniMetric(
            label: 'Your earning',
            value: commission == commission.roundToDouble()
                ? commission.toStringAsFixed(0)
                : commission.toStringAsFixed(2),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }
}

class _ActivePaymentBanner extends StatelessWidget {
  const _ActivePaymentBanner({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = (order['payment_status'] ?? '').toString();
    final method =
        (order['payment_method'] ?? '').toString().replaceAll('_', ' ').trim();
    final amount =
        double.tryParse((order['total_amount'] ?? '').toString()) ?? 0;
    final isPaid = status.trim().toLowerCase() == 'paid';
    final color = isPaid ? greentext : Colors.orange.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(isPaid ? Icons.verified_rounded : Icons.schedule_rounded,
              color: color, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'PAID • DO NOT COLLECT CASH' : 'PAYMENT PENDING',
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w900),
                ),
                if (method.isNotEmpty)
                  Text(
                    method.toUpperCase(),
                    style: TextStyle(
                        color: color.withValues(alpha: .8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          ),
          Text(
            amount == amount.roundToDouble()
                ? amount.toStringAsFixed(0)
                : amount.toStringAsFixed(2),
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 18),
          const SizedBox(height: 8),
          Text(label.translate(context),
              style: regular(context)
                  .copyWith(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headingBlackBold(context).copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.address,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String address;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: compact ? 34 : 42,
          width: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: iconColor, size: compact ? 18 : 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            address,
            style: compact
                ? regular(context).copyWith(color: Colors.black54)
                : headingBlack(context).copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            color: _statusColor(status),
            fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _WaitingStatus extends StatelessWidget {
  const _WaitingStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == 'delivered';
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (delivered ? greentext : Colors.orange).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        delivered
            ? 'Delivery Completed'.translate(context)
            : 'Waiting for restaurant to prepare'.translate(context),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: delivered ? greentext : Colors.orange,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final to = (item['to_status'] ?? '').toString().replaceAll('_', ' ');
    final date = (item['created_at'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: greentext, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(to.isEmpty ? '-' : to, style: regular(context))),
          Text(date.length > 16 ? date.substring(0, 16) : date,
              style: regular(context)
                  .copyWith(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

LatLng? _latLngFromBranch(Map<String, dynamic> branch) {
  final lat = double.tryParse((branch['latitude'] ?? '').toString());
  final lng = double.tryParse((branch['longitude'] ?? '').toString());
  if (lat == null || lng == null || lat == 0 || lng == 0) return null;
  return LatLng(lat, lng);
}

LatLng? _latLngFromOrder(Map<String, dynamic> order) {
  final lat = double.tryParse((order['delivery_latitude'] ?? '').toString());
  final lng = double.tryParse((order['delivery_longitude'] ?? '').toString());
  if (lat == null || lng == null || lat == 0 || lng == 0) return null;
  return LatLng(lat, lng);
}

String _fullName(Map<String, dynamic> data, {required String fallback}) {
  final name = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
  if (name.isNotEmpty) return name;
  return fallback;
}

String _phone(Map<String, dynamic> data) {
  final country = (data['phone_country'] ?? '').toString().trim();
  final phone = (data['phone'] ?? '').toString().trim();
  if (phone.isEmpty) return '';
  if (phone.startsWith('+') || country.isEmpty) return phone;
  return '$country$phone';
}

Color _statusColor(String status) {
  switch (status) {
    case 'ready_for_pickup':
      return Colors.blue;
    case 'picked_up':
      return Colors.indigo;
    case 'on_the_way':
      return Colors.orange;
    case 'delivered':
      return greentext;
    case 'cancelled':
      return Colors.redAccent;
    default:
      return Colors.black54;
  }
}
