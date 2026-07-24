import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

import '../../../core/services/config.dart';

abstract class GetPolylineState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetPolylineInitial extends GetPolylineState {}

class ResetPolylineInitial extends GetPolylineState {}

class GetPolylineLoading extends GetPolylineState {
  final Set<Polyline> polylines;
  GetPolylineLoading(this.polylines);

  @override
  List<Object?> get props => [polylines];
}

class GetPolylineUpdated extends GetPolylineState {
  final Set<Polyline>? polylines;
  GetPolylineUpdated({this.polylines});

  @override
  List<Object?> get props => [polylines];
}

class GetPolylineUpdatedError extends GetPolylineState {
  final String error;
  GetPolylineUpdatedError(this.error);

  @override
  List<Object?> get props => [error];
}

class GetPolylineCubit extends Cubit<GetPolylineState> {
  GetPolylineCubit() : super(GetPolylineInitial());

  final Map<PolylineId, Polyline> _polylines = {};
  final PolylinePoints _polylinePoints = PolylinePoints();

   Future<void> getPolyline({
    required double sourcelat,
    required double sourcelng,
    required double destinationlat,
    required double destinationlng,
    required bool isPickupRoute, // true for pickup, false for dropoff
  }) async {
    try {
      if (sourcelat <= 0 ||
          sourcelng <= 0 ||
          destinationlat <= 0 ||
          destinationlng <= 0) {
        emit(GetPolylineUpdatedError("Invalid coordinates"));
        return;
      }

      emit(GetPolylineLoading(_polylines.values.toSet()));

      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Config.googleKey,
        request: PolylineRequest(
          origin: PointLatLng(sourcelat, sourcelng),
          destination: PointLatLng(destinationlat, destinationlng),
          mode: TravelMode.driving,
        ),
      );

      if (result.status == 'OK') {
        final polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final PolylineId polylineId = isPickupRoute
            ? const PolylineId("DriverPickupToUser")
            : const PolylineId("DriverDropoffToUser");

         final PolylineId oppositePolylineId = isPickupRoute
            ? const PolylineId("DriverDropoffToUser")
            : const PolylineId("DriverPickupToUser");
        _polylines.remove(oppositePolylineId);

         _polylines.remove(polylineId);

        _addPolyLine(
          coordinates: polylineCoordinates,
          id: polylineId,
          color: isPickupRoute ? Colors.blue : Colors.green,
        );

        emit(GetPolylineUpdated(polylines: _polylines.values.toSet()));
      } else {
        emit(GetPolylineUpdatedError(
            result.errorMessage ?? "Failed to get polyline"));
      }
    } catch (e) {
      emit(GetPolylineUpdatedError("Exception: $e"));
    }
  }

  void _addPolyLine({
    required List<LatLng> coordinates,
    required PolylineId id,
    required Color color,
  }) {
    final polyline = Polyline(
      polylineId: id,
      color: color,
      width: 5,
      points: coordinates,
    );
    _polylines[id] = polyline;
  }

  Set<Polyline> get currentPolylines => _polylines.values.toSet();

  void resetPolylines() {
    _polylines.clear();
    emit(GetPolylineInitial());
  }
}

// Driver States
abstract class UpdateRideMarkerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideMarkerInitial extends UpdateRideMarkerState {}

class RideMarkerLoading extends UpdateRideMarkerState {
  final Set<Marker> markers;
  RideMarkerLoading(this.markers);

  @override
  List<Object?> get props => [markers];
}

class RideMarkerUpdated extends UpdateRideMarkerState {
  final Set<Marker> markers;
  RideMarkerUpdated(this.markers);

  @override
  List<Object?> get props => [markers];
}

class RideMarkerError extends UpdateRideMarkerState {
  final String error;
  RideMarkerError(this.error);

  @override
  List<Object?> get props => [error];
}

// Driver Map Cubit
class UpdateRideMarkerCubit extends Cubit<UpdateRideMarkerState> {
  UpdateRideMarkerCubit() : super(RideMarkerInitial());

  Future<void> getRideMarker({
    required BuildContext context,
    required double sourcelat,
    required double sourcelng,
    required double destinationlat,
    required double destinationlng,
    required String pickupImage,
    required String dropOffImage,
  }) async {
    emit(RideMarkerLoading(const <Marker>{}));

    try {
      final Uint8List markerIconDropOff =
          await getBytesFromAsset(dropOffImage, 40);

      Set<Marker> markers = {};


      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(sourcelat, sourcelng),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));


      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(destinationlat, destinationlng),
        icon: BitmapDescriptor.bytes(markerIconDropOff),
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      ));

      emit(RideMarkerUpdated(markers));
    } catch (e) {

      emit(RideMarkerError(e.toString()));
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void resetState() {
    emit(RideMarkerInitial());
  }
}
