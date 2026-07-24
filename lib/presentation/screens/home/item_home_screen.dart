import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/cubits/general_cubit.dart';
import '../../../core/extensions/helper/push_notifications.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/initial_ride_request.dart';
import '../../../main.dart';
import '../../cubits/account/update_profile_cubit.dart';
import '../../cubits/bottom_bar_cubit.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/location/location_cubit.dart';
import '../../cubits/location/ringtone_cubit.dart';
import '../../cubits/payment/wallet_data_cubit.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../cubits/realtime/ride_status_cubit.dart';
import '../Search/ride_screen.dart';
import '../splash/allow_location_screen.dart';

class ItemHomeScreen extends StatefulWidget {
  const ItemHomeScreen({super.key});

  @override
  State<ItemHomeScreen> createState() => _ItemHomeScreenState();
}

class _ItemHomeScreenState extends State<ItemHomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  GoogleMapController? mapController;
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? currentLocation;

  bool isOnDuty = false;
  String? lastHandledRideId;
  bool isBottomSheetOpen = false;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;
  late Future<void> _startupBarrier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LocationCubit>().startLiveLocationTracking();
      context.read<WalletDataCubit>().getWallet();
      final driverIdUpdated =
          box.get("driverId") ?? loginModel?.data?.fireStoreId ?? "";

      if (driverIdUpdated.isNotEmpty) {
        driverId = driverIdUpdated;
        context
            .read<UpdateDriverParameterCubit>()
            .updateDriverId(driverId: driverIdUpdated.toString());
        _startupBarrier = checkAndCleanRideOnStartup(driverId: driverIdUpdated);

        await _startupBarrier;
        // ignore_for_file: use_build_context_synchronously
        context
            .read<GetDocApprovalStatusCubit>()
            .listenToDocApprovalStatus(driverId: driverIdUpdated);
        context
            .read<GetDriverStatusCubit>()
            .listenDriverStatusStatus(driverId: driverIdUpdated);

        context
            .read<ListenRideRequestCubit>()
            .listenForRideRequests(driverIdUpdated, context: context);
      }
      context.read<DashboardCubit>().dashBoardDriver(context: context);
      context.read<MyImageCubit>().updateMyImage(myImage);
    });
    showNotification(context);
  }

  void zoomIn() => mapController?.animateCamera(CameraUpdate.zoomIn());
  void zoomOut() => mapController?.animateCamera(CameraUpdate.zoomOut());

  void centerMap() {
    if (currentLocation != null) {
      mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation!));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    mapController?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  bool get appIsInForeground => _appLifecycleState == AppLifecycleState.resumed;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        dialogExit(context);
        return false;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<GetDocApprovalStatusCubit, String>(
            listener: (context, state) {
              bool isApproved = box.get("isApproved") ?? false;
              if (state == "approved" && isApproved == false) {
                box.put("isApproved", true);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                    title: const Column(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 48),
                        SizedBox(height: 10),
                        Text(
                          "Documents Approved",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Your documents have been successfully verified! 🎉\nYou are now ready to receive ride requests.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context
                              .read<GetDocApprovalStatusCubit>()
                              .setIsApprovedStatus(
                                  driverId: context
                                      .read<UpdateDriverParameterCubit>()
                                      .state
                                      .driverId,
                                  status: "yes"); // Close dialog
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Great!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                context.read<GetDocApprovalStatusCubit>().setIsApprovedStatus(
                    driverId: context
                        .read<UpdateDriverParameterCubit>()
                        .state
                        .driverId,
                    status: "yes");
                loginModel!.data!.itemDocumentStatus = "approved";
                UserData userObj = UserData();
                userObj.saveLoginData(
                    "UserData", jsonEncode(loginModel!.toJson()));
              } else if (isApproved && state == "rejected") {
                box.put("isApproved", false);
                box.put("driver_status", false);
                loginModel!.data!.itemDocumentStatus = "rejected";
                UserData userObj = UserData();
                userObj.saveLoginData(
                    "UserData", jsonEncode(loginModel!.toJson()));
                context.read<UpdateDriverParameterCubit>().updateDriverStatus(
                      driverStatus: "inactive",
                    );
                context.read<UpdateDriverCubit>().updateFirebaseDriverStatus(
                      driverId: context
                          .read<UpdateDriverParameterCubit>()
                          .state
                          .driverId,
                      driverStatus: "inactive",
                    );
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                    title: const Column(
                      children: [
                        Icon(Icons.cancel_rounded,
                            color: Colors.redAccent, size: 48),
                        SizedBox(height: 10),
                        Text(
                          "Documents Rejected",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Unfortunately, your submitted documents have been rejected.\n\nPlease review the requirements and upload valid documents again, or contact support for help.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context
                              .read<GetDocApprovalStatusCubit>()
                              .setIsApprovedStatus(
                                  driverId: context
                                      .read<UpdateDriverParameterCubit>()
                                      .state
                                      .driverId,
                                  status: "no"); // Close dialog
                          // Optionally navigate to document upload screen
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                context.read<GetDocApprovalStatusCubit>().setIsApprovedStatus(
                    driverId: context
                        .read<UpdateDriverParameterCubit>()
                        .state
                        .driverId,
                    status: "no");
              }
            },
          ),
          BlocListener<GetDriverStatusCubit, String>(
              listener: (context, state) {
            if (state == "active") {
              context.read<UpdateDriverParameterCubit>().updateDriverStatus(
                    driverStatus: "active",
                  );
              context.read<UpdateDriverCubit>().updateFirebaseDriverStatus(
                    driverId: context
                        .read<UpdateDriverParameterCubit>()
                        .state
                        .driverId,
                    driverStatus: "active",
                  );
              context.read<GetDriverDataCubit>().updatedDriverStatus(state);
            } else {
              context.read<UpdateDriverParameterCubit>().updateDriverStatus(
                    driverStatus: "inactive",
                  );
              context.read<UpdateDriverCubit>().updateFirebaseDriverStatus(
                    driverId: context
                        .read<UpdateDriverParameterCubit>()
                        .state
                        .driverId,
                    driverStatus: "inactive",
                  );

              context.read<GetDriverDataCubit>().updatedDriverStatus(state);
            }
          }),
          BlocListener<ListenRideRequestCubit, ListenRideRequestState>(
            listener: (context, state) async {
              if (state is ListenRideRequestSuccess) {
                if (state.rideRequest != null) {
                  if (state.rideId == lastHandledRideId) {
                    return;
                  }
                  if (!box.get("driver_status", defaultValue: false)) return;

                  isBottomSheetOpen = true;
                  lastHandledRideId = state.rideId;
                  context
                      .read<UpdateDriverParameterCubit>()
                      .removeDriverPickupLatAndLng();
                  context
                      .read<UpdateDriverParameterCubit>()
                      .removeDriverDropOffLatAndLng();

                  context
                      .read<UpdateDriverParameterCubit>()
                      .updateRideId(rideId: state.rideId);
                  context
                      .read<UpdateDriverParameterCubit>()
                      .updateRideRequest(rideRequest: state.rideRequest);
                  context
                      .read<UpdateDriverParameterCubit>()
                      .updateDriverPickupAndDropOffAddress(
                        pickupAddress: state.rideRequest!.pickupLocation,
                        dropOffAddress: state.rideRequest!.dropoffLocation,
                      );

                  final requestStartTime =
                      box.get("ride_request_start_time") ?? DateTime.now();
                  box.put("ride_request_start_time", requestStartTime);
                  RingtoneHelper().playRingtone();
                  if (appIsInBackground) {
                    await showRideNotification(
                      pickup: state.rideRequest!.pickupLocation,
                      drop: state.rideRequest!.dropoffLocation,
                      distance: double.parse(
                          state.rideRequest!.travelDistance.toString()),
                      fare: double.parse(
                          state.rideRequest!.travelCharges.toString()),
                    );
                  }

                  showCustomBottomSheet(context,
                      rideRequest: state.rideRequest,
                      currebtLatlng: currentLocation ?? const LatLng(0, 0));
                  context
                      .read<ListenRideRequestCubit>()
                      .resetListenRideRequest();
                } else if (state.rideRequest == null) {
                  isBottomSheetOpen = false;
                  lastHandledRideId = null;
                  RingtoneHelper().stopRingtone();
                  flutterLocalNotificationsPlugin.cancel(100);

                  box.delete("ride_request_start_time");
                }
              }
            },
          ),
          BlocListener<WalletDataCubit, WalletDataState>(
            listener: (context, state) async {
              if (state is WalletDataSuccess) {
                walletBalance = double.parse(
                    (state.vendorWallet?.data?.walletBalance ?? "0.0")
                        .replaceAll(",", ""));
                double minimumNegative = double.parse(
                    context.read<MinimumNegativeCubit>().state.value ?? "20.0");
                debugPrint('min balance -$minimumNegative');
                debugPrint('current wallet balance $walletBalance');
                if (walletBalance < -minimumNegative) {
                  context.read<UpdateDriverParameterCubit>().updateDriverStatus(
                        driverStatus: "inactive",
                      );
                  context.read<UpdateDriverCubit>().updateFirebaseDriverStatus(
                        driverId: context
                            .read<UpdateDriverParameterCubit>()
                            .state
                            .driverId,
                        driverStatus: "inactive",
                      );
                }
              }
            },
          ),
        ],
        child: Scaffold(
          body: Stack(
            children: [
              BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) {
                  if (state is LocationSucess) {
                    currentLocation = state.currentLocation;
                    centerMap();
                    final driverId = context
                        .read<UpdateDriverParameterCubit>()
                        .state
                        .driverId;
                    if (driverId.isNotEmpty && currentLocation != null) {
                      context.read<UpdateDriverCubit>().updateDriverLocation(
                            driverId: driverId,
                            currentLocation: currentLocation!,
                          );
                    }

                    context.read<HomeMarkerCubit>().addOrUpdateMarker(
                          currentLocation!,
                          'Driver Location',
                          'driver_marker',
                          'assets/images/driverPin.png',
                          90,
                        );
                  }

                  return BlocBuilder<HomeMarkerCubit, HomeMarkerState>(
                    builder: (context, markerState) {
                      if (currentLocation == null) {
                        return FutureBuilder(
                          future: Future.delayed(const Duration(seconds: 15)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return _buildReloadMapButton(context);
                            } else {
                              return forMapLoadingShimmer();
                            }
                          },
                        );
                      } else {
                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: currentLocation ?? const LatLng(0, 0),
                            zoom: 12,
                          ),
                          markers: markerState is HomeMarkerUpdated
                              ? markerState.markers
                              : {},
                          onMapCreated: (controller) {
                            mapController = controller;
                            if (!_controller.isCompleted) {
                              _controller.complete(controller);
                            }
                          },
                        );
                      }
                    },
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: () {
                              context.read<BottomBarCubit>().changeTabIndex(3);
                            },
                            child: BlocBuilder<MyImageCubit, dynamic>(
                              builder: (context, state) {
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[200],
                                  child: state.isEmpty
                                      ? const Icon(
                                          CupertinoIcons.profile_circled,
                                          size: 50,
                                          color: Colors.black)
                                      : ClipOval(
                                          child: myNetworkImage(state,
                                              height: 50, width: 50)),
                                );
                              },
                            ),
                          ),
                          // Status Toggle
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<GetDriverDataCubit, GetDriverDataState>(
                  builder: (context, state) {
                if (state is DriverFetched) {
                  if (state.status == "active") {
                    box.put("driver_status", true);
                  } else {
                    box.put("driver_status", false);
                  }
                  context.read<GetDriverDataCubit>().removeGetDriverState();
                }
                return SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(),
                            const SizedBox(),
                            BlocBuilder<GetDocApprovalStatusCubit, String>(
                                builder: (context, status) {
                              return CustomToggleSwitch(
                                current: box.get("driver_status",
                                    defaultValue: false),
                                onChanged: (value) async {
                                  if (status == "approved") {
                                    box.put("driver_status", value);
                                    if (value == false) {
                                      showDutyConfirmationDialog(
                                        context: context,
                                        goingOnline: value,
                                        onConfirmed: () {
                                          setState(() {
                                            isOnDuty = value;
                                          });

                                          context
                                              .read<
                                                  UpdateDriverParameterCubit>()
                                              .updateDriverStatus(
                                                driverStatus: "inactive",
                                              );
                                          context
                                              .read<UpdateDriverCubit>()
                                              .updateFirebaseDriverStatus(
                                                driverId: context
                                                    .read<
                                                        UpdateDriverParameterCubit>()
                                                    .state
                                                    .driverId,
                                                driverStatus: "inactive",
                                              );
                                        },
                                      );
                                    } else {
                                      if (walletBalance <
                                          -double.parse(context
                                                  .read<MinimumNegativeCubit>()
                                                  .state
                                                  .value ??
                                              "20.0")) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            backgroundColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.all(24),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .account_balance_wallet_rounded,
                                                    color: themeColor,
                                                    size: 28),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Low Wallet Balance"
                                                        .translate(context),
                                                    style:
                                                        heading2Grey1(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              "Low balance! Recharge or add money now to stay active on the platform."
                                                  .translate(context),
                                              style: regular2(context),
                                              textAlign: TextAlign.center,
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  OutlinedButton(
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          Colors.grey[800],
                                                      side: const BorderSide(
                                                          color: Colors.grey),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      "Later"
                                                          .translate(context),
                                                      style:
                                                          heading3Grey1(context)
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          themeColor,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      context
                                                          .read<
                                                              BottomBarCubit>()
                                                          .changeTabIndex(2);
                                                    },
                                                    child: Text(
                                                      "Add Money"
                                                          .translate(context),
                                                      style:
                                                          heading3Grey1(context)
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }
                                      if (Platform.isIOS) {
                                        bool locationOK =
                                            await checkAndRequestAlwaysLocationPermission(
                                                context);

                                        if (locationOK) {
                                          setState(() {
                                            isOnDuty = value;
                                          });

                                          context
                                              .read<
                                                  UpdateDriverParameterCubit>()
                                              .updateDriverStatus(
                                                driverStatus: "active",
                                              );
                                          context
                                              .read<UpdateDriverCubit>()
                                              .updateFirebaseDriverStatus(
                                                driverId: context
                                                    .read<
                                                        UpdateDriverParameterCubit>()
                                                    .state
                                                    .driverId,
                                                driverStatus: "active",
                                              );
                                        }
                                      } else {
                                        setState(() {
                                          isOnDuty = value;
                                        });

                                        context
                                            .read<UpdateDriverParameterCubit>()
                                            .updateDriverStatus(
                                              driverStatus: "active",
                                            );
                                        context
                                            .read<UpdateDriverCubit>()
                                            .updateFirebaseDriverStatus(
                                              driverId: context
                                                  .read<
                                                      UpdateDriverParameterCubit>()
                                                  .state
                                                  .driverId,
                                              driverStatus: "active",
                                            );
                                      }
                                    }
                                  } else {
                                    // Pending verification or unknown status
                                    showModalBottomSheet(
                                      backgroundColor: notifires.getbgcolor,
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                      ),
                                      builder: (context) {
                                        return Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.info_outline,
                                                  color: Colors.orangeAccent,
                                                  size: 50),
                                              const SizedBox(height: 16),
                                              Text(
                                                "Account Verification In Progress"
                                                    .translate(context),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "We’re currently reviewing your documents. You’ll get full access once verification is complete. Thanks for your patience!"
                                                    .translate(context),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              );
                            }),
                            const SizedBox(width: 45),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              }),
              Positioned(
                top: 8,
                right: 16,
                left: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          _MapButton(icon: Icons.zoom_in, onTap: zoomIn),
                          const SizedBox(height: 8),
                          _MapButton(icon: Icons.zoom_out, onTap: zoomOut),
                          const SizedBox(height: 8),
                          _MapButton(icon: Icons.location_on, onTap: centerMap),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, state) {
                if (state is DashboardSuceess) {
                  context.read<UpdateRideRequestCubit>().updateDriverRating(
                      driverId: driverId,
                      newRating: state.totalRating.toString());
                }
                return Stack(
                  children: [
                    DraggableScrollableSheet(
                      initialChildSize: 0.13,
                      minChildSize: 0.13,
                      maxChildSize: 0.13,
                      builder: (context, scrollController) {
                        return Container(
                          alignment: Alignment.topCenter,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 15, left: 30, right: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                dashboardInfoTile(
                                  context,
                                  title: "Earnings",
                                  value: state is DashboardSuceess
                                      ? "$currency ${(double.tryParse(state.totalEarning) ?? 0.0).toStringAsFixed(2)}"
                                      : "$currency 0.00",
                                ),
                                dashboardInfoTile(
                                  context,
                                  title: "Ratings",
                                  value: state is DashboardSuceess
                                      ? state.totalRating.toString()
                                      : "0",
                                  icon: Icons.star,
                                  iconColor: yelloColor,
                                ),
                                dashboardInfoTile(
                                  context,
                                  title: "Total Order's",
                                  value: state is DashboardSuceess
                                      ? state.totalOrder.toString()
                                      : "0",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReloadMapButton(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 64,
              color: themeColor,
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to get location".translate(context),
              style: heading2Grey1(context),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your connection and try again".translate(context),
              style: regular2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger location fetch again
                context.read<LocationCubit>().startLiveLocationTracking();
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                "Reload Map".translate(context),
                style: heading3Grey1(context).copyWith(color: whiteColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: whiteColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardInfoTile(
    BuildContext context, {
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.translate(context),
          style: headingBlackBold(context).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 4),
        icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: regularBlack(context)),
                  const SizedBox(width: 4),
                  Icon(icon, color: iconColor ?? Colors.black, size: 15),
                ],
              )
            : Text(value, style: regularBlack(context)),
      ],
    );
  }
}

// Helper widget for map control buttons
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

class CustomBottomSheetForParcel extends StatefulWidget {
  final InitialRideRequest? rideRequest;
  final LatLng currentLatlang;

  const CustomBottomSheetForParcel({
    super.key,
    this.rideRequest,
    required this.currentLatlang,
  });

  @override
  CustomBottomSheetForParcelState createState() =>
      CustomBottomSheetForParcelState();
}

class CustomBottomSheetForParcelState extends State<CustomBottomSheetForParcel>
    with WidgetsBindingObserver {
  int durationShowPopUp = popupDuration();
  int _remainingTime = popupDuration();
  DateTime? _rideStartTime;
  Timer? _autoCloseTimer;

  bool get hasParcel {
    final p = widget.rideRequest?.parcalData;
    if (p == null) return false;
    return (p.name?.isNotEmpty ?? false) ||
        (p.weight?.isNotEmpty ?? false) ||
        (p.reciverName?.isNotEmpty ?? false) ||
        (p.reciverNumber?.isNotEmpty ?? false) ||
        (p.instruction?.isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    context.read<RideStatusCubit>().removeRideAcceptedStatus();
    WidgetsBinding.instance.addObserver(this);

    _rideStartTime = box.get('ride_request_start_time');
    if (_rideStartTime == null) {
      _rideStartTime = DateTime.now();
      box.put('ride_request_start_time', _rideStartTime);
    }

    final elapsed = DateTime.now().difference(_rideStartTime!).inSeconds;
    _remainingTime = durationShowPopUp - elapsed;

    if (_remainingTime <= 0) {
      _closeSheetIfNotAccepted();
      return;
    }

    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remainingTime--);
      if (_remainingTime <= 0) {
        timer.cancel();
        _closeSheetIfNotAccepted();
      }
    });
  }

  void _closeSheetIfNotAccepted() {
    final rideAccepted =
        context.read<RideStatusCubit>().state.rideAcceptedStatus;
    if (!rideAccepted && Navigator.canPop(context)) {
      Navigator.pop(context);
      RingtoneHelper().stopRingtone();
      box.delete('ride_request_start_time');
      _rejectRide(context, false);
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    box.delete('ride_request_start_time');
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final rideRequestState = context.read<ListenRideRequestCubit>().state;
    if (rideRequestState is ListenRideRequestSuccess &&
        rideRequestState.rideRequest == null) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _autoCloseTimer?.cancel();
      RingtoneHelper().stopRingtone();
      box.delete('ride_request_start_time');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.rideRequest!;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: PopScope(
        canPop: false,
        child: BlocListener<ListenRideRequestCubit, ListenRideRequestState>(
          listener: (context, state) {
            if (state is ListenRideRequestSuccess &&
                state.rideRequest == null) {
              if (Navigator.canPop(context)) Navigator.pop(context);
              _autoCloseTimer?.cancel();
              RingtoneHelper().stopRingtone();
              box.delete('ride_request_start_time');
            }
          },
          child: SizedBox(
            height: 750,
            child: Column(
              children: [
                _buildTimerCircle(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 600,
                      color: whiteColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildUserRow(ride),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildLocations(ride),
                          if (hasParcel) _buildParcelCard(ride.parcalData),
                          const SizedBox(height: 10),
                          _buildButtons(ride),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 140,
      alignment: Alignment.center,
      child: Container(
        height: 100,
        width: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: greentext, width: 3),
          color: whiteColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          "$_remainingTime",
          style: heading1(context).copyWith(fontSize: 35, color: blackColor),
        ),
      ),
    );
  }

  Widget _buildUserRow(InitialRideRequest ride) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ClipOval(
              child: Container(
                height: 70,
                width: 70,
                color: notifires.getBoxColor,
                child: myNetworkImage(ride.customer.userPhoto ?? ""),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.customer.userName, style: headingBlackBold(context)),
                Row(
                  children: [
                    Icon(Icons.star, color: orangeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      ride.customer.userRating.isEmpty
                          ? "0.0"
                          : ride.customer.userRating,
                      style: regular(context)
                          .copyWith(color: notifires.getGrey3whiteColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("$currency ${ride.travelCharges}",
                style: headingBlack(context).copyWith(color: greentext)),
            Row(
              children: [
                Icon(Icons.timer_sharp, color: grey3, size: 14),
                const SizedBox(width: 5),
                Text(
                  "${ride.travelTime} (${double.parse(ride.travelDistance).toStringAsFixed(2)} km)",
                  style: regular(context),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocations(InitialRideRequest ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _locationRow(Icons.circle, Colors.green, "Pickup".translate(context),
            ride.pickupLocation),
        const SizedBox(height: 6),
        _locationRow(Icons.location_on, Colors.red, "Drop".translate(context),
            ride.dropoffLocation),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _locationRow(IconData icon, Color color, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 12),
              children: [
                TextSpan(
                    text: "$title:  ",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParcelCard(ParcalData? p) {
    if (p == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Parcel Details".translate(context),
              style: heading1Grey1(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoTile("Item", p.name, Icons.inventory_2),
              const SizedBox(width: 6),
              _infoTile("Weight".translate(context),
                  "${p.weight} ${"Kg".translate(context)}", Icons.scale),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _infoTile("Receiver", p.reciverName, Icons.person),
              const SizedBox(width: 6),
              _infoTile("Phone", p.reciverNumber, Icons.call),
            ],
          ),
          if (p.instruction != null && p.instruction!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("${"Instruction".translate(context)}: ${p.instruction}",
                style: TextStyle(fontSize: 12, color: grey3)),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(String title, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.translate(context),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(InitialRideRequest ride) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CustomSlideButton(
            textActiveColor: whiteColor,
            iconColor: whiteColor,
            textInactiveColor: whiteColor,
            inactiveColor: themeColor,
            isOnRide: context.read<RideStatusCubit>().state.rideAcceptedStatus,
            acceptedText: "ACCEPTED",
            defaultText: "ACCEPT RIDE",
            onChanged: (value) async {
              if (value) {
                context
                    .read<RideStatusCubit>()
                    .updateRideAcceptedStatus(rideAcceptedStatus: true);
                context
                    .read<UpdateRideRequestCubit>()
                    .updateNewRideRequestsStatus(
                      driverId: driverId,
                      rideId: ride.rideId,
                      newStatus: "accepted",
                    );
                box.put("ride_id", ride.rideId);
                box.put("start_time", getCurrentFormattedTime());
                goBack();
                box.delete('ride_request_start_time');
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RideScreens(
                    tripTitle: "Start Pickup",
                    isOnDutyArrived: box.get("driver_status"),
                    currentLatLang: widget.currentLatlang,
                    rideId:
                        context.read<UpdateDriverParameterCubit>().state.rideId,
                  );
                }));
                RingtoneHelper().stopRingtone();
                sendNotificationDirect(
                    playerId: widget.rideRequest!.playerId,
                    title: "Ride Accepted 🚗",
                    message:
                        "Your captain has accepted the ride and is on the way to pick you up."
                            .translate(context));
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: InkWell(
            onTap: () => _rejectRide(context, true),
            child: Container(
              height: 55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: notifires.getBoxColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("Skip".translate(context),
                  style: headingBlack(context).copyWith(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  void _rejectRide(BuildContext context, bool? skipStatus) async {
    _autoCloseTimer?.cancel();
    box.delete('ride_request_start_time');

    context.read<UpdateRideRequestCubit>().removeRideRequest(
          skipStatus: skipStatus,
          rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
          driverId: context.read<UpdateDriverParameterCubit>().state.driverId,
        );
    RingtoneHelper().stopRingtone();
  }
}

class CustomBottomSheet extends StatefulWidget {
  final InitialRideRequest? rideRequest;
  final LatLng currentLatlang;

  const CustomBottomSheet({
    super.key,
    this.rideRequest,
    required this.currentLatlang,
  });

  @override
  CustomBottomSheetState createState() => CustomBottomSheetState();
}

class CustomBottomSheetState extends State<CustomBottomSheet>
    with WidgetsBindingObserver {
  int durationShowPopUp = popupDuration();
  int _remainingTime = popupDuration();
  DateTime? _rideStartTime;
  Timer? _autoCloseTimer;
  @override
  void initState() {
    super.initState();
    context.read<RideStatusCubit>().removeRideAcceptedStatus();
    WidgetsBinding.instance.addObserver(this);

    _rideStartTime = box.get('ride_request_start_time');
    if (_rideStartTime == null) {
      _rideStartTime = DateTime.now();
      box.put('ride_request_start_time', _rideStartTime);
    }

    final elapsed = DateTime.now().difference(_rideStartTime!).inSeconds;
    _remainingTime = durationShowPopUp - elapsed;

    if (_remainingTime <= 0) {
      _closeSheetIfNotAccepted();
      return;
    }

    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remainingTime--);

      if (_remainingTime <= 0) {
        timer.cancel();
        _closeSheetIfNotAccepted();
      }
    });
  }

  void _closeSheetIfNotAccepted() {
    final rideAccepted =
        context.read<RideStatusCubit>().state.rideAcceptedStatus;
    if (!rideAccepted && Navigator.canPop(context)) {
      Navigator.pop(context);
      RingtoneHelper().stopRingtone();
      box.delete('ride_request_start_time');
      _rejectRide(context, false);
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    box.delete('ride_request_start_time'); // clear after use

    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final rideRequestState = context.read<ListenRideRequestCubit>().state;
      if (rideRequestState is ListenRideRequestSuccess &&
          rideRequestState.rideRequest == null) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _autoCloseTimer?.cancel();
        RingtoneHelper().stopRingtone();
        box.delete('ride_request_start_time');
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final rideRequestState = context.read<ListenRideRequestCubit>().state;
      if (rideRequestState is ListenRideRequestSuccess &&
          rideRequestState.rideRequest == null) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _autoCloseTimer?.cancel();
        RingtoneHelper().stopRingtone();
        box.delete('ride_request_start_time');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: PopScope(
        canPop: false,
        child: BlocListener<ListenRideRequestCubit, ListenRideRequestState>(
          listener: (context, state) async {
            if (state is ListenRideRequestSuccess) {
              if (state.rideRequest == null) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                box.delete('ride_request_start_time');
                _autoCloseTimer?.cancel();
                RingtoneHelper().stopRingtone();
              }
            }
          },
          child: SizedBox(
            height: 680,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: greentext, width: 3),
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          "$_remainingTime",
                          style: heading1(context)
                              .copyWith(fontSize: 35, color: blackColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      height: 600,
                      color: whiteColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ClipOval(
                                      child: Container(
                                        height: 70,
                                        width: 70,
                                        color: notifires.getBoxColor,
                                        child: myNetworkImage(widget.rideRequest
                                                ?.customer.userPhoto ??
                                            ""),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.rideRequest!.customer.userName,
                                          style: headingBlackBold(context),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.star,
                                                color: orangeColor, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.rideRequest!.customer
                                                      .userRating
                                                      .toString()
                                                      .isEmpty
                                                  ? "0.0"
                                                  : widget.rideRequest!.customer
                                                      .userRating
                                                      .toString(),
                                              style: regular(context).copyWith(
                                                  color: notifires
                                                      .getGrey3whiteColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$currency ${widget.rideRequest!.travelCharges}",
                                      style: headingBlack(context)
                                          .copyWith(color: greentext),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_sharp,
                                            color: grey3, size: 14),
                                        const SizedBox(width: 5),
                                        Text(
                                          "${widget.rideRequest!.travelTime}(${(double.parse(widget.rideRequest!.travelDistance)).toStringAsFixed(2)} ${"km".translate(context)})",
                                          style: regular(context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          height: 45,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: greentext,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: whiteColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Image.asset("assets/images/line2.png",
                                            scale: 0.9),
                                        const SizedBox(height: 5),
                                        Container(
                                          height: 45,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: whiteColor,
                                            border: Border.all(
                                                width: 1, color: grey4),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(top: 10),
                                            height: 10,
                                            width: 10,
                                            decoration: BoxDecoration(
                                              color: themeColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 15),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "Verified Pickup".translate(
                                                  context),
                                              style: headingBlack(context)
                                                  .copyWith(
                                                      color: notifires
                                                          .getGrey3whiteColor,
                                                      fontSize: 14)),
                                          const SizedBox(height: 5),
                                          Text(
                                            widget.rideRequest!.pickupLocation,
                                            style: headingBlack(context)
                                                .copyWith(fontSize: 14),
                                            softWrap: true,
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                              "Verified Drop At"
                                                  .translate(context),
                                              style: headingBlack(context)
                                                  .copyWith(
                                                      color: notifires
                                                          .getGrey3whiteColor,
                                                      fontSize: 14)),
                                          const SizedBox(height: 5),
                                          Text(
                                            widget.rideRequest!.dropoffLocation,
                                            style: headingBlack(context)
                                                .copyWith(fontSize: 14),
                                            softWrap: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CustomSlideButton(
                                    textActiveColor: whiteColor,
                                    iconColor: whiteColor,
                                    textInactiveColor: whiteColor,
                                    inactiveColor: themeColor,
                                    isOnRide: context
                                        .read<RideStatusCubit>()
                                        .state
                                        .rideAcceptedStatus,
                                    acceptedText: "ACCEPTED",
                                    defaultText: "ACCEPT RIDE",
                                    onChanged: (value) async {
                                      if (value) {
                                        context
                                            .read<RideStatusCubit>()
                                            .updateRideAcceptedStatus(
                                                rideAcceptedStatus: true);
                                        context
                                            .read<UpdateRideRequestCubit>()
                                            .updateNewRideRequestsStatus(
                                              driverId: driverId,
                                              rideId:
                                                  widget.rideRequest?.rideId ??
                                                      "",
                                              newStatus: "accepted",
                                            );
                                        box.put("ride_id",
                                            widget.rideRequest?.rideId ?? "");
                                        box.put("start_time",
                                            getCurrentFormattedTime());
                                        goBack();
                                        box.delete('ride_request_start_time');
                                        sendNotificationDirect(
                                            playerId:
                                                widget.rideRequest!.playerId,
                                            title: "Ride Accepted",
                                            message:
                                                "Your ride has been accepted by the driver.");
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return RideScreens(
                                            tripTitle: "Start Pickup",
                                            isOnDutyArrived:
                                                box.get("driver_status"),
                                            currentLatLang:
                                                widget.currentLatlang,
                                            rideId: context
                                                .read<
                                                    UpdateDriverParameterCubit>()
                                                .state
                                                .rideId,
                                          );
                                        }));

                                        RingtoneHelper().stopRingtone();

                                        box.delete('ride_request_start_time');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () => _rejectRide(context, true),
                                    child: Container(
                                      height: 55,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: notifires.getBoxColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text("Skip".translate(context),
                                          style: headingBlack(context)
                                              .copyWith(fontSize: 16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _rejectRide(BuildContext context, bool? skipStatus) async {
    _autoCloseTimer?.cancel();
    box.delete('ride_request_start_time');

    context.read<UpdateRideRequestCubit>().removeRideRequest(
        skipStatus: skipStatus,
        rideId: context.read<UpdateDriverParameterCubit>().state.rideId,
        driverId: context.read<UpdateDriverParameterCubit>().state.driverId);
    RingtoneHelper().stopRingtone();
  }
}

void showCustomBottomSheet(BuildContext context,
    {InitialRideRequest? rideRequest, required LatLng currebtLatlng}) {
  showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    barrierColor: blackColor.withValues(alpha: .2),
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      if ((rideRequest?.parcalData.name ?? "").isEmpty ||
          (rideRequest?.parcalData.reciverName ?? "").isEmpty) {
        return CustomBottomSheet(
          rideRequest: rideRequest,
          currentLatlang: currebtLatlng,
        );
      } else {
        return CustomBottomSheetForParcel(
          rideRequest: rideRequest,
          currentLatlang: currebtLatlng,
        );
      }
    },
  );
}

bool get appIsInBackground {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive ||
      state == AppLifecycleState.detached;
}
