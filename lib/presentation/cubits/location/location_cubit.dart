import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
 import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';

abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSucess extends LocationState {
  final LatLng? currentLocation;

  LocationSucess({
    this.currentLocation,
  });

  @override
  List<Object?> get props => [currentLocation];
}

class LocationFailure extends LocationState {
  final String? error;
  LocationFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());
  late StreamSubscription<Position> positionStreamSubscription;
  var markers = <Marker>{};

  void startLiveLocationTracking() async {

    try {
      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {

        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      updateDriverLocation(position);
      int firebaseUpdateTime=int.parse(box.get("firebaseUpdatedLocation")??"10");

      DateTime lastUpdateTime = DateTime.now().subtract(  Duration(seconds:  firebaseUpdateTime));

      positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen((Position position) {
        final now = DateTime.now();
        if (now.difference(lastUpdateTime).inSeconds >= firebaseUpdateTime) {
          lastUpdateTime = now;


          updateDriverLocation(position);
        }
      });
    // ignore: empty_catches
    } catch (e) {

    }
  }

  Future<LocationPermission> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    while (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

      }
    }

    if (permission == LocationPermission.deniedForever) {


      await Geolocator.openLocationSettings();
    }

    return permission;
  }

  void updateDriverLocation(Position position) async {

    try {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      emit(LocationSucess(
        currentLocation: currentLocation,
      ));
    } catch (error) {
      emit(LocationFailure(error: error.toString()));
    }
  }

  void clear() {
    emit(LocationInitial());
  }
}

// for ride screen

abstract class RideLocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideLocationInitial extends RideLocationState {}

class RideLocationLoading extends RideLocationState {}

class RideLocationSucess extends RideLocationState {
  final LatLng? currentLocation;

  RideLocationSucess({
    this.currentLocation,
  });

  @override
  List<Object?> get props => [currentLocation];
}
 class RideLocationFailure extends RideLocationState {
  final String? error;
  RideLocationFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class RideLocationCubit extends Cubit<RideLocationState> {
  RideLocationCubit() : super(RideLocationInitial());
  late StreamSubscription<Position> positionStreamSubscription;
  var markers = <Marker>{};

  Future<void> startLiveLocationTracking() async {

    try {
      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {

        return;
      }

      // Start live tracking via stream
      positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        updateDriverLocation(position);
      });
    } catch (e) {
      //
    }
  }

  Future<LocationPermission> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

    }



    return permission;
  }

  void updateDriverLocation(Position position) async {

    try {
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      emit(RideLocationSucess(
        currentLocation: currentLocation,
      ));
    } catch (error) {
      emit(RideLocationFailure(error: error.toString()));
    }
  }

  void clear() {
    emit(RideLocationInitial());
  }
}

abstract class MarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarkerInitial extends MarkerState {}

class MarkerUpdated extends MarkerState {
  final Set<Marker> markers;

  MarkerUpdated({required this.markers});

  @override
  List<Object?> get props => [markers];
}

class MarkerCubit extends Cubit<MarkerState> {
  MarkerCubit() : super(MarkerInitial());

  final Set<Marker> _markers = {};

  void addOrUpdateMarker(LatLng position, String title, String markerId,
      String image, int size) async {
    final Uint8List markerIcon = await getBytesFromAsset(image, size);

    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      draggable: false,
      zIndex: 2,
      flat: true,
      infoWindow: InfoWindow(title: title),
      // ignore: deprecated_member_use
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );

    _markers.removeWhere((m) => m.markerId.value == markerId);
    _markers.add(marker);

    emit(MarkerUpdated(markers: _markers));
  }

  void deleteMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    emit(MarkerUpdated(markers: _markers));
  }

  void removeMarker() {
    deleteMarker("User_marker");
    deleteMarker("Drop_marker");
    deleteMarker("Driver_marker");
    emit(MarkerInitial());

  }
}

abstract class HomeMarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeMarkerInitial extends HomeMarkerState {}

class HomeMarkerUpdated extends HomeMarkerState {
  final Set<Marker> markers;

  HomeMarkerUpdated({required this.markers});

  @override
  List<Object?> get props => [markers];
}

class HomeMarkerCubit extends Cubit<HomeMarkerState> {
  HomeMarkerCubit() : super(HomeMarkerInitial());

  final Set<Marker> _markers = {};

  void addOrUpdateMarker(LatLng position, String title, String markerId,
      String image, int size) async {
    final Uint8List markerIcon = await getBytesFromAsset(image, size);

    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      draggable: false,
      zIndex: 2,
      flat: true,
      infoWindow: InfoWindow(title: title),
      // ignore: deprecated_member_use
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );

    _markers.removeWhere((m) => m.markerId.value == markerId);
    _markers.add(marker);

    emit(HomeMarkerUpdated(markers: _markers));
  }

  void removeMarker() {
    emit(HomeMarkerInitial());
  }
}

abstract class RideMarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideMarkerInitial extends RideMarkerState {}

class RideMarkerSuccess extends RideMarkerState {
  final Set<Marker> markers;

  RideMarkerSuccess({required this.markers});

  @override
  List<Object?> get props => [markers];
}

class RideMarkerCubit extends Cubit<RideMarkerState> {
  RideMarkerCubit() : super(RideMarkerInitial());

  final Set<Marker> _markers = {};

  void addOrUpdateMarker(LatLng position, String title, String markerId,
      String image, int size) async {
    final Uint8List markerIcon = await getBytesFromAsset(image, size);

    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      draggable: false,
      zIndex: 2,
      flat: true,
      infoWindow: InfoWindow(title: title),
      // ignore: deprecated_member_use
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );

    _markers.removeWhere((m) => m.markerId.value == markerId);
    _markers.add(marker);

    emit(RideMarkerSuccess(markers: _markers));
  }

  void deleteMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    emit(RideMarkerSuccess(markers: _markers));
  }

  void removeMarker() {
    emit(RideMarkerInitial());
  }
}


abstract class GetDriverDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetDriverDataInitial extends GetDriverDataState {}

class GetDriverDataLoading extends GetDriverDataState {}

class DriverFetched extends GetDriverDataState {
  final String? status;


  DriverFetched({
    required this.status,

  });

  @override
  List<Object?> get props =>
      [status,  ];
}

class DriverError extends GetDriverDataState {
  final String message;

  DriverError(this.message);

  @override
  List<Object?> get props => [message];
}

class GetDriverDataCubit extends Cubit<GetDriverDataState> {
  GetDriverDataCubit() : super(GetDriverDataInitial());

  void updatedDriverStatus(String status)   {
    if(status.isNotEmpty){
      emit(DriverFetched(status: status,));

    }else{
      emit(DriverFetched(status: "inactive",));
    }
  }

  void removeGetDriverState() {
    emit(GetDriverDataInitial());
  }
}


