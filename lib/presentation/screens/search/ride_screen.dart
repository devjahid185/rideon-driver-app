import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/search/drop_otp_verify_screen.dart';
import 'package:ride_on_driver/presentation/screens/search/pickup_parcel_image_screen.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/realtime_ride_request.dart';
import '../../cubits/location/get_polyline_cubit.dart';
import '../../cubits/location/location_cubit.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/realtime/ride_status_cubit.dart';
import '../../widgets/sos_widget.dart';
import '../Payment/payment_screen.dart';
import '../bottom_bar/home_main.dart';
import 'otp_verify_ride_screen.dart';

class RideScreens extends StatefulWidget {
  final String? tripTitle;
  final String? buttonTitle;
  final String? rideId;
  final bool? isOnDutyCompleted;
  final bool? isOnDutyStart;
  final bool? isOnDutyArrived;
  final bool? fromInitialPage;
  final LatLng? currentLatLang;

  const RideScreens({
    super.key,
    this.tripTitle,
    this.buttonTitle,
    this.rideId,
    this.isOnDutyCompleted,
    this.isOnDutyArrived,
    this.fromInitialPage,
    this.isOnDutyStart,
    this.currentLatLang,
  });

  @override
  State<RideScreens> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreens> {
  GoogleMapController? mapController;
  final Completer<GoogleMapController> _controller = Completer();
  RealTimeRideRequest? rideData;
  ParcalData? parcalData;
  bool isOnDutyCompleted = false;
  bool isShowPopUp = false;
  bool _isMapInitialized = false;
  LatLng? currentLocation;
  bool showNoData = false;
  bool hasRetried = false;
  @override
  void initState() {
    super.initState();
    currentLocation = widget.currentLatLang;
    context.read<MarkerCubit>().removeMarker();
    context.read<GetPolylineCubit>().resetPolylines();
    context.read<GetRideDataCubit>().clear();
    context.read<GetRideDataCubit>().fetchRideData(widget.rideId!);
    context
        .read<GetRideRequestStatusCubit>()
        .listenToRouteStatus(rideId: widget.rideId!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideLocationCubit>().startLiveLocationTracking();
      context.read<LocationCubit>().startLiveLocationTracking();
    });
    isOnDutyCompleted = widget.isOnDutyCompleted ?? false;
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && currentLocation == null) {
        setState(() {
          showNoData = true;
        });
      }
    });
  }

  bool _isLocationStarted = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isLocationStarted) {
      context.read<RideLocationCubit>().startLiveLocationTracking();
      context.read<LocationCubit>().startLiveLocationTracking();
      _isLocationStarted = true;
    }
  }

  void showGoHomeDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: notifires.getbgcolor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              Text(
                "Leave Ride?".translate(context),
                style: heading1Grey1(context),
              ),
            ],
          ),
          content: Text(
            "If you go home now, this ride will be canceled.\nAre you sure you want to leave?"
                .translate(context),
            style: regular2(context),
          ),
          actionsPadding: const EdgeInsets.all(12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "No, Stay".translate(context),
                style: heading3Grey1(context).copyWith(fontSize: 15),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text(
                "Yes, Go Home".translate(context),
                style: heading3Grey1(context)
                    .copyWith(color: whiteColor, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isLoad = false;
  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: notifires.getbgcolor,
        body: MultiBlocListener(
          listeners: [
            BlocListener<GetRideRequestStatusCubit, String>(
                listener: (context, status) {
              if (status == "cancelled") {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (ModalRoute.of(context)?.isCurrent == true &&
                      !isShowPopUp) {
                    isShowPopUp = true;
                    box.delete("ride_id");
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PopScope(
                        canPop: false,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                          title: Column(
                            children: [
                              const Icon(Icons.cancel,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                "Ride Cancelled".translate(context),
                                textAlign: TextAlign.center,
                                style: heading2Grey1(context),
                              ),
                            ],
                          ),
                          content: Text(
                            "The rider has cancelled the ride request.\n\nYou can head back to the home screen and wait for another ride."
                                .translate(context),
                            textAlign: TextAlign.center,
                            style: regular2(context),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            InkWell(
                              onTap: () {
                                box.delete("ride_id");
                                goToWithClear(const HomeMain(initialIndex: 0));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.home, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Go Home".translate(context),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                });
                return;
              }
            }),
            BlocListener<UpdateBookingIdCubit, String>(
              listener: (context, bookingId) {
                if (bookingId.isNotEmpty) {
                  context
                      .read<UpdateDriverParameterCubit>()
                      .updateBookingId(bookingId: bookingId);
                  context
                      .read<UpdateRideStatusInDatabaseCubit>()
                      .updateRideStatus(
                        context: context,
                        bookingId: bookingId,
                        rideStatus: "pick_up",
                      );
                }
              },
            ),
            BlocListener<LocationCubit, LocationState>(
                listener: (context, state) {
              if (state is LocationSucess) {
                context.read<UpdateDriverCubit>().updateDriverLocation(
                      driverId: loginModel?.data?.fireStoreId ?? "",
                      currentLocation: state.currentLocation,
                    );
              }
            }),
          ],
          child: BlocBuilder<GetRideDataCubit, GetRideDataState>(
            builder: (context, state) {
              if (state is GetRideDataLoading) {
                return const MapShimmerScreen();
              }

              if (state is GetRideDataSuccess) {
                rideData = state.requestDataModel;
                parcalData = state.requestDataModel?.parcalData;

                context
                    .read<UpdateDriverParameterCubit>()
                    .updateRideId(rideId: rideData?.rideId);

                if (widget.fromInitialPage == true) {
                  _updateInitialDriverParameters();
                }

                context.read<GetRideDataCubit>().clear();
              }

              return Stack(
                children: [
                  BlocBuilder<RideLocationCubit, RideLocationState>(
                    builder: (context, locationState) {
                      if (locationState is RideLocationSucess &&
                          rideData != null) {
                        currentLocation = locationState.currentLocation;
                        context
                            .read<UpdateDriverParameterCubit>()
                            .updateLoaction(
                              lat: currentLocation?.latitude ?? 0.0,
                              lng: currentLocation?.longitude ?? 0.0,
                            );

                        if (isLoad == false) {
                          isLoad = true;
                          _updateMarkersAndPolylines(currentLocation!);
                        }
                      }

                      return BlocBuilder<MarkerCubit, MarkerState>(
                        builder: (context, markerState) {
                          if (currentLocation == null) {
                            if (showNoData) {
                              return RetryWithGoHome(
                                showNoData: showNoData,
                                hasRetried: hasRetried,
                                onRetry: () {
                                  setState(() {
                                    showNoData = false;
                                    hasRetried = true;
                                  });

                                  context.read<MarkerCubit>().removeMarker();
                                  context
                                      .read<GetPolylineCubit>()
                                      .resetPolylines();
                                  context
                                      .read<RideStatusCubit>()
                                      .resetAllParameters();
                                  context
                                      .read<GetRideDataCubit>()
                                      .fetchRideData(widget.rideId ?? "");
                                  context
                                      .read<RideLocationCubit>()
                                      .startLiveLocationTracking();

                                  Future.delayed(const Duration(seconds: 15),
                                      () {
                                    if (mounted && currentLocation == null) {
                                      setState(() {
                                        showNoData = true;
                                      });
                                    }
                                  });
                                },
                                onGoHome: () {
                                  showGoHomeDialog(context, () async {
                                    final bookingId = await context
                                        .read<UpdateBookingIdCubit>()
                                        .getBookingId(
                                            rideId: widget.rideId ?? "");
                                    box.delete('ride_id');
                                    cancelRideRequestByError(
                                        rideId: widget.rideId ?? "",
                                        bookingId: bookingId ?? "",
                                        // ignore: use_build_context_synchronously
                                        context: context);
                                  });
                                },
                              );
                            } else if (rideData == null) {
                              return const MapShimmerScreen();
                            } else {
                              return forMapLoadingShimmer();
                            }
                          } else {
                            return _buildMap(currentLocation!);
                          }
                        },
                      );
                    },
                  ),
                  BlocConsumer<RideStatusCubit, RideStatusState>(
                    builder: (context, state) {
                      if (rideData == null) return const SizedBox();
                      if (rideData!.rideId == null &&
                          rideData!.travelCharges == null &&
                          rideData!.pickupLocation!.lat == null) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.3,
                          minChildSize: 0.3,
                          maxChildSize: 0.3,
                          builder: (context, scrollController) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Something went wrong".translate(context),
                                      style: heading2Grey1(context),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Please retry again".translate(context),
                                      textAlign: TextAlign.center,
                                      style: regular2(context),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                          ),
                                          onPressed: () {
                                            context
                                                .read<GetPolylineCubit>()
                                                .resetPolylines();
                                            context
                                                .read<RideStatusCubit>()
                                                .resetAllParameters();
                                            context
                                                .read<GetRideDataCubit>()
                                                .fetchRideData(
                                                    widget.rideId ?? "");
                                            context
                                                .read<RideLocationCubit>()
                                                .startLiveLocationTracking();
                                          },
                                          icon: const Icon(Icons.refresh,
                                              color: Colors.white),
                                          label: Text(
                                              "Retry".translate(context),
                                              style: heading3Grey1(context)
                                                  .copyWith(color: whiteColor)),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.home_outlined,
                                              size: 18),
                                          onPressed: () async {
                                            final bookingId = await context
                                                .read<UpdateBookingIdCubit>()
                                                .getBookingId(
                                                    rideId:
                                                        widget.rideId ?? "");
                                            cancelRideRequestByError(
                                                rideId: widget.rideId ?? "",
                                                bookingId: bookingId ?? "",
                                                // ignore: use_build_context_synchronously
                                                context: context);
                                            box.delete('ride_id');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: whiteColor,
                                            backgroundColor: themeColor,
                                            side: BorderSide(
                                                color: themeColor, width: 1.2),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 22, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          label: Text(
                                              "Go Home".translate(context),
                                              style: heading3Grey1(context)
                                                  .copyWith(
                                                      color: whiteColor,
                                                      fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }

                      if (!state.rideArrivedStatus) {
                        return CustomRideBottomSheet(
                          onTap: () {
                            _focusInAppRoute(toPickup: true);
                          },
                          rideRequest: rideData!,
                          pickupString: "Go to PickUp",
                          acceptedText: "",
                          textActiveColor: blackColor,
                          textInactiveColor: blackColor,
                          isOnDutyRide: state.rideArrivedStatus,
                          onChanged: (value) {
                            if (value) {
                              _handleArrivedStatus();
                            }
                          },
                          titleText: "Customer Verified Location",
                          activeColor: themeColor,
                          inactiveColor: themeColor,
                          defaultText: "ARRIVED",
                          addressText: rideData!.pickupLocation?.pickupAddress,
                        );
                      } else if (!state.rideStartEndStatus &&
                          state.rideArrivedStatus) {
                        return CustomRideBottomSheetForStartRide(
                          onTap: () {
                            _focusInAppRoute(toPickup: false);
                          },
                          rideRequest: rideData!,
                          pickupString: "Go to Drop",
                          acceptedText: "",
                          textActiveColor: blackColor,
                          textInactiveColor: whiteColor,
                          isOnDutyRide: state.rideStartEndStatus,
                          onChanged: (value) {
                            if (value) {
                              _handleStartRide();
                            }
                          },
                          titleText: "Customer Verified Location",
                          activeColor: greentext,
                          inactiveColor: greentext,
                          defaultText: "START RIDE",
                          addressText:
                              rideData!.dropoffLocation?.dropoffAddress ?? "",
                        );
                      }
                      return const SizedBox();
                    },
                    listener: (context, state) {},
                  ),
                  if (isOnDutyCompleted && rideData != null)
                    CustomBottomSheet(
                      rideRequest: rideData!,
                      onNavigateToDrop: () => _focusInAppRoute(toPickup: false),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _updateInitialDriverParameters() {
    final driverParams = context.read<UpdateDriverParameterCubit>();
    driverParams.updateBookingId(bookingId: rideData?.bookingId ?? "");
    driverParams.updateDriverId(driverId: rideData!.selectedDriverId ?? "");
    driverParams.updateDriverDropOffLatAndLng(
      driverDropOffLat: rideData!.dropoffLocation?.lat ?? 0.0,
      driverDropOffLng: rideData!.dropoffLocation?.lng ?? 0.0,
    );
    driverParams.updateDriverPickupLatAndLng(
      driverPickupLat: rideData!.pickupLocation?.lat ?? 0.0,
      driverPickupLng: rideData!.pickupLocation?.lng ?? 0.0,
    );

    if (rideData?.status == "accepted") {
      context
          .read<RideStatusCubit>()
          .updateRideArrivedStatus(rideArrivedStatus: false);
    } else if (rideData?.status == "confirmed") {
      context.read<RideStatusCubit>()
        ..updateRideStartEndStatus(rideStartEndStatus: false)
        ..updateRideArrivedStatus(rideArrivedStatus: true);
    } else if (rideData?.status == "ongoing") {
      context.read<RideStatusCubit>()
        ..updateRideArrivedStatus(rideArrivedStatus: true)
        ..updateRideStartEndStatus(rideStartEndStatus: true);
      isOnDutyCompleted = true;
    }
  }

  void _updateMarkersAndPolylines(LatLng currentLocation) {
    context.read<MarkerCubit>().addOrUpdateMarker(
          LatLng(currentLocation.latitude, currentLocation.longitude),
          'Driver',
          'Driver_marker',
          'assets/images/car_marker.png',
          90,
        );

    if (isOnDutyCompleted == true &&
        context.read<RideStatusCubit>().state.rideStartEndStatus == true) {
      context.read<MarkerCubit>().deleteMarker("User_marker");
      context.read<MarkerCubit>().addOrUpdateMarker(
            LatLng(
              rideData!.dropoffLocation?.lat ?? 0.0,
              rideData!.dropoffLocation?.lng ?? 0.0,
            ),
            'User Drop Location',
            'Drop_marker',
            'assets/images/drop_pin.png',
            65,
          );
      context.read<GetPolylineCubit>().getPolyline(
            sourcelat: currentLocation.latitude,
            sourcelng: currentLocation.longitude,
            isPickupRoute: false,
            destinationlat: rideData!.dropoffLocation!.lat ?? 0.0,
            destinationlng: rideData!.dropoffLocation!.lng ?? 0.0,
          );
    } else if (isOnDutyCompleted == false) {
      context.read<MarkerCubit>().addOrUpdateMarker(
            LatLng(
              rideData!.pickupLocation?.lat ?? 0.0,
              rideData!.pickupLocation?.lng ?? 0.0,
            ),
            'User Location',
            'User_marker',
            'assets/images/pin_user.png',
            40,
          );
      context.read<GetPolylineCubit>().getPolyline(
            sourcelat: rideData!.pickupLocation!.lat ?? 0.0,
            sourcelng: rideData!.pickupLocation!.lng ?? 0.0,
            isPickupRoute: true,
            destinationlat: currentLocation.latitude,
            destinationlng: currentLocation.longitude,
          );
    }
  }

  void _focusInAppRoute({required bool toPickup}) {
    final current = currentLocation;
    final ride = rideData;
    if (current == null || ride == null) {
      showErrorToastMessage("Current location is not ready yet.");
      return;
    }

    final targetLat =
        toPickup ? ride.pickupLocation?.lat : ride.dropoffLocation?.lat;
    final targetLng =
        toPickup ? ride.pickupLocation?.lng : ride.dropoffLocation?.lng;

    if (targetLat == null ||
        targetLng == null ||
        targetLat == 0.0 ||
        targetLng == 0.0) {
      showErrorToastMessage(toPickup
          ? "Pickup location is not ready."
          : "Drop location is not ready.");
      return;
    }

    final target = LatLng(targetLat, targetLng);
    final markerCubit = context.read<MarkerCubit>();

    markerCubit.addOrUpdateMarker(
      current,
      'Driver',
      'Driver_marker',
      'assets/images/car_marker.png',
      90,
    );

    markerCubit.addOrUpdateMarker(
      target,
      toPickup ? 'Pickup Location' : 'Drop Location',
      toPickup ? 'User_marker' : 'Drop_marker',
      toPickup ? 'assets/images/pin_user.png' : 'assets/images/drop_pin.png',
      toPickup ? 40 : 65,
    );

    context.read<GetPolylineCubit>().getPolyline(
          sourcelat: current.latitude,
          sourcelng: current.longitude,
          isPickupRoute: toPickup,
          destinationlat: target.latitude,
          destinationlng: target.longitude,
        );

    _fitMapToPoints(current, target);
  }

  Future<void> _fitMapToPoints(LatLng source, LatLng destination) async {
    final controller = mapController;
    if (controller == null) return;

    final samePoint = source.latitude == destination.latitude &&
        source.longitude == destination.longitude;
    if (samePoint) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(source, 16),
      );
      return;
    }

    final southWest = LatLng(
      source.latitude < destination.latitude
          ? source.latitude
          : destination.latitude,
      source.longitude < destination.longitude
          ? source.longitude
          : destination.longitude,
    );
    final northEast = LatLng(
      source.latitude > destination.latitude
          ? source.latitude
          : destination.latitude,
      source.longitude > destination.longitude
          ? source.longitude
          : destination.longitude,
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southWest, northeast: northEast),
        120,
      ),
    );
  }

  void _handleArrivedStatus() {
    final driverParams = context.read<UpdateDriverParameterCubit>();
    driverParams.removeBookingId();

    context.read<UpdateBookingIdCubit>()
      ..resetState()
      ..updateBookingId(rideId: widget.rideId ?? "");

    context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
          rideId: widget.rideId ?? "",
          newStatus: "pick_up",
        );

    Future.delayed(const Duration(milliseconds: 200), () {
      if ((parcalData!.name ?? "").isEmpty &&
          (parcalData!.reciverNumber ?? "").isEmpty) {
        goTo(OtpVerifyRideScreen(
          // ignore: use_build_context_synchronously
          bookingId: context.read<UpdateBookingIdCubit>().state,
          userName: rideData?.customer?.userName ?? "",
        ));
        return;
      }

      goTo(ParcelImageScreen(
        // ignore: use_build_context_synchronously
        bookingId: context.read<UpdateBookingIdCubit>().state,
        userName: rideData?.customer?.userName ?? "",
      ));
    });
  }

  void _handleStartRide() {
    context
        .read<RideStatusCubit>()
        .updateRideStartEndStatus(rideStartEndStatus: true);

    final bookingId =
        context.read<UpdateDriverParameterCubit>().state.bookingId.isEmpty
            ? rideData?.bookingId ?? ""
            : context.read<UpdateDriverParameterCubit>().state.bookingId;

    if (bookingId.isNotEmpty) {
      context.read<UpdateRideRequestCubit>().updatePendingRideRequests(
          rideId: widget.rideId ?? "", newStatus: "ongoing");

      context.read<UpdateRideStatusInDatabaseCubit>().updateRideStatus(
            context: context,
            bookingId: bookingId,
            rideStatus: "Ongoing",
          );
    }
    setState(() {
      isOnDutyCompleted = true;
      isLoad = false;
    });
  }

  Widget _buildMap(LatLng currentLocation) {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      top: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PersistentGoogleMap(
            initialPosition: currentLocation,
            myLocationEnabled: false,
            onMapCreated: (controller) async {
              if (!_isMapInitialized) {
                mapController = controller;
                _isMapInitialized = true;
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isMapInitialized && mapController != null) {
      mapController?.dispose();
      mapController = null;
    }
    _isMapInitialized = false;
    _controller.future
        .then((controller) => controller.dispose())
        .catchError((_) {});
    super.dispose();
  }
}

class CustomBottomSheet extends StatefulWidget {
  final RealTimeRideRequest rideRequest;
  final VoidCallback onNavigateToDrop;

  const CustomBottomSheet({
    super.key,
    required this.rideRequest,
    required this.onNavigateToDrop,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  bool isOnDutyCompleteRide = false;
  String totalTime = "";

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetRideDataCubit, GetRideDataState>(
        builder: (context, state) {
      if (state is UpdatedGetRideDataSuccess) {
        final RealTimeRideRequest model = state.requestDataModel!;
        final bookingId =
            context.read<UpdateDriverParameterCubit>().state.bookingId.isEmpty
                ? model.bookingId ?? ""
                : context.read<UpdateDriverParameterCubit>().state.bookingId;
        // model.setTotalTime(totalTime);

        context
            .read<UpdateRideStatusInDatabaseCubit>()
            .updateCompleteRideStatus(
                context: context,
                bookingId: bookingId,
                rideStatus: "Completed",
                json: jsonEncode(model.toJson()),
                dropOtp: "",
                totalTime: totalTime);
      }
      return DraggableScrollableSheet(
        snap: true,
        initialChildSize: .4,
        minChildSize: .4,
        maxChildSize: .4,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  const SizedBox(),
                  InkWell(
                    onTap: widget.onNavigateToDrop,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: yelloColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      height: 50,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_upward, size: 25),
                          Text(
                            "Go to Drop".translate(context),
                            style: headingBlackBold(context)
                                .copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SosButtonWidget()
                ],
              ),
              Expanded(
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text("Drop Location".translate(context),
                            style: regular2(context)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: greentext),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rideRequest.dropoffLocation
                                            ?.dropoffAddress ??
                                        "",
                                    style: regular2(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: BlocConsumer<
                                  UpdateRideStatusInDatabaseCubit,
                                  UpdateRideStatusInDatabaseState>(
                                builder: (context, state) {
                                  return CustomSlideButton(
                                    activeColor: themeColor,
                                    iconColor: whiteColor,
                                    inactiveColor: themeColor,
                                    isOnRide: isOnDutyCompleteRide,
                                    textActiveColor: whiteColor,
                                    textInactiveColor: whiteColor,
                                    acceptedText: "Completed",
                                    defaultText: "COMPLETE RIDE",
                                    onChanged: (value) {
                                      box.put("rideEndTime", DateTime.now());
                                      setState(() {
                                        isOnDutyCompleteRide = value;
                                        if (value) {
                                          context
                                              .read<
                                                  UpdateRideStatusInDatabaseCubit>()
                                              .resetStatus();
                                          final bookingId = context
                                                  .read<
                                                      UpdateDriverParameterCubit>()
                                                  .state
                                                  .bookingId
                                                  .isEmpty
                                              ? widget.rideRequest.bookingId ??
                                                  ""
                                              : context
                                                  .read<
                                                      UpdateDriverParameterCubit>()
                                                  .state
                                                  .bookingId;
                                          if (bookingId.isNotEmpty) {
                                            if ((widget.rideRequest.parcalData?.name ?? "").isNotEmpty &&
                                                (widget.rideRequest.parcalData
                                                            ?.reciverNumber ??
                                                        "")
                                                    .isNotEmpty &&
                                                (widget.rideRequest.parcalData
                                                            ?.reciverName ??
                                                        "")
                                                    .isNotEmpty) {
                                              final endTime =
                                                  getCurrentFormattedTime();
                                              box.put("end_time", endTime);
                                              final startTime =
                                                  box.get("start_time");
                                              totalTime =
                                                  calculateMinutesBetween(
                                                          startTime, endTime)
                                                      .toString();
                                              // context
                                              //     .read<
                                              //         GetListenRideRequestBookingIdCubit>()
                                              //     .updateTotalTime(
                                              //         rideId: widget.rideRequest
                                              //                 .rideId ??
                                              //             "",
                                              //         totalTime:
                                              //             "$totalTime mins");

                                              goTo(DropOtpVerifyRideScreen(
                                                bookingId: bookingId,
                                                realTimeRideRequest:
                                                    widget.rideRequest,
                                                userName: widget.rideRequest
                                                        .customer?.userName ??
                                                    "",
                                                totalTime: totalTime,
                                              ));
                                              return;
                                            } else {
                                              context
                                                  .read<
                                                      UpdateRideRequestCubit>()
                                                  .updatePendingRideRequests(
                                                    rideId: widget.rideRequest
                                                            .rideId ??
                                                        "",
                                                    newStatus: "completed",
                                                  );
                                              final endTime =
                                                  getCurrentFormattedTime();
                                              box.put("end_time", endTime);
                                              final startTime =
                                                  box.get("start_time");
                                              totalTime =
                                                  calculateMinutesBetween(
                                                          startTime, endTime)
                                                      .toString();
                                              // context
                                              //     .read<
                                              //         GetListenRideRequestBookingIdCubit>()
                                              //     .updateTotalTime(
                                              //         rideId: widget.rideRequest
                                              //                 .rideId ??
                                              //             "",
                                              //         totalTime:
                                              //             "$totalTime mins");
                                              context
                                                  .read<GetRideDataCubit>()
                                                  .fetchUpdatedRideData(widget
                                                          .rideRequest.rideId
                                                          ?.toString() ??
                                                      "");
                                              box.delete("ride_id");

                                              goTo(PaymentScreen(
                                                rideRequest: widget.rideRequest,
                                              ));
                                            }
                                          }
                                          Future.delayed(
                                              const Duration(milliseconds: 200),
                                              () {
                                            isOnDutyCompleteRide = false;
                                          });
                                        }
                                      });
                                    },
                                  );
                                },
                                listener: (context, state) {
                                  if (state
                                      is CompleteRideStatusSuceessUpdated) {}
                                },
                              ),
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
      );
    });
  }
}

class PersistentGoogleMap extends StatefulWidget {
  final LatLng initialPosition;

  final bool myLocationEnabled;
  final Function(GoogleMapController) onMapCreated;

  const PersistentGoogleMap({
    super.key,
    required this.initialPosition,
    required this.myLocationEnabled,
    required this.onMapCreated,
  });

  @override
  PersistentGoogleMapState createState() => PersistentGoogleMapState();
}

class PersistentGoogleMapState extends State<PersistentGoogleMap> {
  GoogleMapController? _mapController;

  Set<Marker> markers = {};
  Set<Polyline> polyline = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarkerCubit, MarkerState>(
      builder: (context, markerState) {
        if (markerState is MarkerUpdated) {
          markers = markerState.markers;
        }

        return BlocBuilder<GetPolylineCubit, GetPolylineState>(
          builder: (context, polylineState) {
            if (polylineState is GetPolylineUpdated) {
              polyline = polylineState.polylines ?? {};
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _moveCameraToFitPolylineAndMarkers();
              });
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 15,
              ),
              myLocationEnabled: widget.myLocationEnabled,
              markers: markers,
              polylines: polyline,
              onMapCreated: (controller) {
                if (_mapController == null) {
                  _mapController = controller;
                  widget.onMapCreated(controller);
                }
              },
            );
          },
        );
      },
    );
  }

  void _moveCameraToFitPolylineAndMarkers() {
    if (_mapController == null || (polyline.isEmpty && markers.isEmpty)) return;

    LatLngBounds bounds;

    final points = [
      ...polyline.expand((p) => p.points),
      ...markers.map((m) => m.position),
    ];

    if (points.isEmpty) return;

    final southwestLat =
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final southwestLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final northeastLat =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final northeastLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    bounds = LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 130), // 50 = padding
    );
  }
}

class RetryWithGoHome extends StatelessWidget {
  final bool showNoData;
  final bool hasRetried;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  const RetryWithGoHome({
    super.key,
    required this.showNoData,
    required this.hasRetried,
    required this.onRetry,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    if (!showNoData) return const SizedBox();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            myAssetImage("assets/images/something.png",
                height: 120, width: 120),
            const SizedBox(height: 12),
            Text(
              "Something went wrong".translate(context),
              style: heading3Grey1(context).copyWith(color: grey2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Please try again".translate(context),
              style: regular3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    "Try Again".translate(context),
                    style: heading3Grey1(context)
                        .copyWith(color: Colors.white, fontSize: 15),
                  ),
                ),
                if (hasRetried) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: whiteColor,
                    ),
                    onPressed: onGoHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: whiteColor,
                      backgroundColor: themeColor,
                      side: BorderSide(color: themeColor, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text("Go Home".translate(context),
                        style: heading3Grey1(context)
                            .copyWith(color: whiteColor, fontSize: 15)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
