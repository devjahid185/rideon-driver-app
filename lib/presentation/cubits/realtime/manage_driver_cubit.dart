import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/entities/initial_ride_request.dart';

abstract class UpdateDriverState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateDriverInitial extends UpdateDriverState {}

class UpdateDriverLoading extends UpdateDriverState {}

class UpdateDriverUpdated extends UpdateDriverState {}

class UpdateDriverError extends UpdateDriverState {
  final String message;
  UpdateDriverError(this.message);
  @override
  List<Object?> get props => [message];
}


class UpdateDriverCubit extends Cubit<UpdateDriverState> {
  UpdateDriverCubit() : super(UpdateDriverInitial());


  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateFirebaseDriverStatus({
    required String driverId,
    String? driverStatus,
  }) async {
    emit(UpdateDriverLoading());

    try {
      if (driverId.isNotEmpty) {
        await firestore.collection('drivers').doc(driverId).update({
          "driverStatus": driverStatus ?? "inactive",
          if(driverStatus=="inactive")'rideStatus':'available',
        });

        emit(UpdateDriverUpdated());
      } else {

        emit(UpdateDriverError("driverId is required"));
      }
    } catch (e) {

      emit(UpdateDriverError(e.toString()));
    }
  }


  Future<void> updateDriverLocation({
    required String driverId,
    LatLng? currentLocation,
  }) async {
    emit(UpdateDriverLoading());

    try {
      final geoPoint = GeoFirePoint(
        GeoPoint(currentLocation!.latitude, currentLocation.longitude),
      );


      await firestore.collection('drivers').doc(driverId).update({
        'geo': geoPoint.data,
        'timestamp':DateTime.now(),
      });


      final driverDoc =
          await firestore.collection('drivers').doc(driverId).get();
      final driverData = driverDoc.data();

      if (driverData != null &&
          driverData.containsKey('ride_request') &&
          driverData['ride_request'].isNotEmpty) {
        final rideRequest = driverData['ride_request'] as Map<String, dynamic>;
        final rideId = rideRequest['rideId'];

        FirebaseDatabase.instance
            .ref()
            .child('ride_requests')
            .child(rideId)
            .child('driverLocation')
            .update({
          'lat': currentLocation.latitude,
          'lng': currentLocation.longitude,
        }).then((_) {

        }).catchError((error) {

        });
      }

      emit(UpdateDriverUpdated());
    } catch (e) {
      emit(UpdateDriverError(e.toString()));
    }
  }

  Future<void> updateFirebaseDriverDocStatus({
    required String driverId,
    String? docApprovedStatus,
  }) async {
    emit(UpdateDriverLoading());
    try {
      await firestore.collection('drivers').doc(driverId).update({
        "docApprovedStatus": docApprovedStatus ?? "",
      });

      emit(UpdateDriverUpdated());
    } catch (e) {

      emit(UpdateDriverError(e.toString()));
    }
  }

  Future<void> updateFirebaseImageUrl({
    required String driverImageUrl,
    required String driverId,
  }) async {
    try {
      await firestore.collection('drivers').doc(driverId).update({
        "driverImageUrl": driverImageUrl,
      });
    } catch (e) {
      //
    }
  }



  void resetDriver() {
    emit(UpdateDriverInitial());
  }
}


abstract class AddDriverState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddDriverInitial extends AddDriverState {}

class AddDriverLoading extends AddDriverState {}

class AddDriverUpdated extends AddDriverState {}

class AddDriverError extends AddDriverState {
  final String message;
  AddDriverError(this.message);
  @override
  List<Object?> get props => [message];
}

class AddDriverCubit extends Cubit<AddDriverState> {
  AddDriverCubit() : super(AddDriverInitial());

  final CollectionReference _driversCollection =
      FirebaseFirestore.instance.collection('drivers');

  Future<void> addDriver({
    required String driverId,
    required double lat,
    required double lng,
    String? vehicleTypeName,
    String? driverStatus,
    String? vehicleImageUrl,
    String? driverName,
    int? driverRating,
    String? vehicleMake,
    String? vechileModel,
    String? driverNumber,
    required String itemId,
    String? driverImageUrl,
    String? vehicleTypeId,
    String? vehicleNumber,
    String? docApprovedStatus,
    String? driverPhoneCountryCode,
  }) async {
    emit(AddDriverLoading());
    try {
      GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));

      await _driversCollection.doc(driverId).set({
        'geo': geoFirePoint.data,
        "driverStatus": driverStatus ?? "inactive",
        "itemTypeId": vehicleTypeId ?? "",
        "itemTypeName": vehicleTypeName ?? "",
        "driverRating": driverRating ?? "",
        "vehicleMake": vehicleMake ?? "",
        "vehicleModel": vechileModel ?? "",
        "itemId": itemId,
        "vehicleNumber": vehicleNumber ?? "",
        "driverName": driverName ?? "",
        "driverNumber": driverNumber ?? "",
        'rideStatus': 'available',
        "driverImageUrl": driverImageUrl ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        "docApprovedStatus": docApprovedStatus ?? "Pending",
        "phoneCountry": driverPhoneCountryCode ?? "",
      });
      emit(AddDriverUpdated());
    } catch (e) {

      emit(AddDriverError(e.toString()));
    }
  }

  void resetAddDriver() {
    emit(AddDriverInitial());
  }
}

class UpdateDriverParameterState extends Equatable {
  final String rideId;
  final String bookingId;
  final String driverId;
  final double lat;
  final double lng;
  final String vehicleTypeName;
  final String vechicleImageUrl;
  final String vechileMake;
  final String vechileModel;
  final String itemId;
  final String vechileNumber;
  final InitialRideRequest? rideRequest;
  final String docApprovedStatus;
  final String vehicleTypeId;
  final String driverStatus;
  final String driverName;
  final String driverNumber;
  final String driverPhoneCountryCode;
  final double driverPickupLat;
  final double driverPickupLng;
  final double driverDropOffLat;
  final double driverDropOffLng;
  final String userName;
  final String userPhoneNumber;
  final String userImageUrl;
  final String vechileColor;

  final String pickupAddress;
  final String dropOffAddress;

  const UpdateDriverParameterState(
      {this.driverId = "",
      this.vechileMake = "",
      this.userImageUrl = "",
      this.vechileModel = "",
      this.rideId = '',
      this.itemId = "",
      this.vechileNumber = "",
      this.bookingId = "",
      this.lat = 0.0,
      this.rideRequest,
      this.lng = 0.0,
      this.userName = "",
      this.userPhoneNumber = "",
      this.driverDropOffLat = 0.0,
      this.pickupAddress = "",
      this.dropOffAddress = "",
      this.driverDropOffLng = 0.0,
      this.driverPickupLat = 0.0,
      this.driverPickupLng = 0.0,
      this.vehicleTypeName = "",
      this.docApprovedStatus = "",
      this.driverStatus = "inactive",
      this.vechicleImageUrl = "",
      this.vehicleTypeId = '',
      this.vechileColor = '',
      this.driverName = '',
      this.driverPhoneCountryCode = '',
      this.driverNumber = ''});

  UpdateDriverParameterState copyWith(
      {String? bookingId,
      String? driverId,
      String? rideId,
      String? userImageUrl,
      double? lat,
      String? vechileMake,
      String? vechileModel,
      String? userName,
      String? userPhoneNumber,
      double? lng,
      String? vehicleTypeName,
      String? itemId,
      String? vechileNumber,
      String? vechileColor,
      InitialRideRequest? rideRequest,
      double? driverPickupLat,
      String? pickupAddress,
      String? dropOffAddress,
      double? driverPickupLng,
      double? driverDropOffLat,
      double? driverDropOffLng,
      String? docApprovedStatus,
      String? driverStatus,
      String? driverPhoneCountryCode,
      String? vechicleImageUrl,
      String? vehicleTypeId,
      String? driverName,
      String? driverNumber}) {
    return UpdateDriverParameterState(
        userImageUrl: userImageUrl ?? this.userImageUrl,
        vechileMake: vechileMake ?? this.vechileMake,
        vechileModel: vechileModel ?? this.vechileModel,
        vechileNumber: vehicleTypeName ?? this.vechileNumber,
        itemId: itemId ?? this.itemId,
        rideId: rideId ?? this.rideId,
        bookingId: bookingId ?? this.bookingId,
        rideRequest: rideRequest ?? this.rideRequest,
        userName: userName ?? this.userName,
        userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        dropOffAddress: dropOffAddress ?? this.dropOffAddress,
        driverDropOffLat: driverDropOffLat ?? this.driverDropOffLat,
        driverDropOffLng: driverDropOffLng ?? this.driverDropOffLng,
        driverPickupLat: driverPickupLat ?? this.driverPickupLat,
        driverPickupLng: driverPickupLng ?? this.driverPickupLng,
        driverName: driverName ?? this.driverName,
        driverNumber: driverNumber ?? this.driverNumber,
        driverId: driverId ?? this.driverId,
        driverStatus: driverStatus ?? this.driverStatus,
        vechicleImageUrl: vechicleImageUrl ?? this.vechicleImageUrl,
        vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
        vehicleTypeName: vehicleTypeName ?? this.vehicleTypeName,
        driverPhoneCountryCode:
            driverPhoneCountryCode ?? this.driverPhoneCountryCode,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        docApprovedStatus: docApprovedStatus ?? this.docApprovedStatus);
  }

  @override
  List<Object?> get props => [
        userImageUrl,
        vechileNumber,
        vechileMake,
        vechileModel,
        rideId,
        bookingId,
        driverId,
        vehicleTypeId,
        vechicleImageUrl,
        driverStatus,
        vehicleTypeName,
        docApprovedStatus,
        rideRequest,
        lat,
        lng,
        pickupAddress,
        userName,
        userPhoneNumber,
        dropOffAddress,
        driverName,
        driverNumber,
        driverPhoneCountryCode,
        driverDropOffLat,
        driverDropOffLng,
        driverPickupLat,
        driverPickupLng
      ];
}

class UpdateDriverParameterCubit extends Cubit<UpdateDriverParameterState> {
  UpdateDriverParameterCubit() : super(const UpdateDriverParameterState());
  void removeUserParameter(
      {String? userName, String? userImageUrl, String? userPhoneNumber}) {
    var newState = state.copyWith(
        userName: userName,
        userImageUrl: userImageUrl,
        userPhoneNumber: userPhoneNumber);
    emit(newState);
  }

  void updateUserParameter(
      {String? userName, String? userImageUrl, String? userPhoneNumber}) {
    var newState = state.copyWith(
        userName: userName,
        userImageUrl: userImageUrl,
        userPhoneNumber: userPhoneNumber);
    emit(newState);
  }

  void updateVehicleModel({String? vechileModel}) {
    var newState = state.copyWith(vechileModel: vechileModel);
    emit(newState);
  }

  void removeVehicleModel() {
    var newState = state.copyWith(vechileModel: "");
    emit(newState);
  }

  void updateVehicleMake({String? vechileMake}) {
    var newState = state.copyWith(vechileMake: vechileMake);
    emit(newState);
  }

  void removeVehicleMake() {
    var newState = state.copyWith(vechileMake: "");
    emit(newState);
  }

  void updateVehicleNumber({String? vechileNumber}) {
    var newState = state.copyWith(vechileNumber: vechileNumber);
    emit(newState);
  }

  void updateVehicleColor({String? color}) {
    var newState = state.copyWith(vechileColor: color);
    emit(newState);
  }

  void removeVehicleNumber() {
    var newState = state.copyWith(vechileNumber: "");
    emit(newState);
  }

  void updateItemId({String? itemId}) {
    var newState = state.copyWith(itemId: itemId);
    emit(newState);
  }

  void removeItemId() {
    var newState = state.copyWith(itemId: "");
    emit(newState);
  }

  void updateVehicleTypeName({String? vehcileTypeName}) {
    var newState = state.copyWith(vehicleTypeName: vehcileTypeName);
    emit(newState);
  }

  void updateRideId({String? rideId}) {
    var newState = state.copyWith(rideId: rideId);
    emit(newState);
  }

  void removeRideId() {
    var newState = state.copyWith(rideId: "");
    emit(newState);
  }

  void updateBookingId({String? bookingId}) {
    emit(state.copyWith(bookingId: bookingId));
  }

  void removeBookingId({String? bookingId}) {
    emit(state.copyWith(bookingId: bookingId));
  }

  void updateVehicleTypeId({String? vehicleTypeId}) {
    var newState = state.copyWith(
      vehicleTypeId: vehicleTypeId,
    );
    emit(newState);
  }

  void updateLoaction({double? lat, double? lng}) {
    var newState = state.copyWith(lat: lat, lng: lng);
    emit(newState);
  }

  void removeLoaction() {
    var newState = state.copyWith(lat: 0.0, lng: 0.0);
    emit(newState);
  }

  void updateDriverId({String? driverId}) {
    var newState = state.copyWith(driverId: driverId);
    emit(newState);
  }

  void removeDriverId() {
    emit(state.copyWith(driverId: ''));
  }

  void updateVehicleImageUrl({String? vechicleImageUrl}) {
    emit(state.copyWith(vechicleImageUrl: vechicleImageUrl));
  }

  void updateDriverStatus({String? driverStatus}) {
    emit(state.copyWith(driverStatus: driverStatus));
  }

  void removeDriverStatus() {
    emit(state.copyWith(driverStatus: ""));
  }

  void updateDocApprovedStatus({String? docApprovedStatus}) {
    emit(state.copyWith(docApprovedStatus: docApprovedStatus));
  }

  void removeDocApprovedStatus() {
    emit(state.copyWith(docApprovedStatus: ""));
  }

  void updateDriverNameAndNumber(
      {String? driverName,
      String? driverNumber,
      String? driverPhoneCountryCode}) {
    emit(state.copyWith(
        driverName: driverName,
        driverNumber: driverNumber,
        driverPhoneCountryCode: driverPhoneCountryCode));
  }

  void removeDriverNameAndNumber() {
    emit(state.copyWith(
        driverName: "", driverNumber: "", driverPhoneCountryCode: ""));
  }

  void updateDriverPickupLatAndLng({
    double? driverPickupLat,
    double? driverPickupLng,
  }) {
    emit(state.copyWith(
      driverPickupLat: driverPickupLat,
      driverPickupLng: driverPickupLng,
    ));
  }

  void removeDriverPickupLatAndLng() {
    emit(state.copyWith(
      driverPickupLat: 0.0,
      driverPickupLng: 0.0,
    ));
  }

  void updateDriverDropOffLatAndLng({
    double? driverDropOffLat,
    double? driverDropOffLng,
  }) {
    emit(state.copyWith(
      driverDropOffLat: driverDropOffLat,
      driverDropOffLng: driverDropOffLng,
    ));
  }

  void removeDriverDropOffLatAndLng() {
    emit(state.copyWith(
      driverDropOffLat: 0.0,
      driverDropOffLng: 0.0,
    ));
  }

  void updateDriverPickupAndDropOffAddress({
    String? pickupAddress,
    String? dropOffAddress,
  }) {
    emit(state.copyWith(
      pickupAddress: pickupAddress,
      dropOffAddress: dropOffAddress,
    ));
  }

  void removeDriverPickupAndDropOffAddress() {
    emit(state.copyWith(
      pickupAddress: "",
      dropOffAddress: "",
    ));
  }

  void updateRideRequest({
    InitialRideRequest? rideRequest,
  }) {
    emit(state.copyWith(
      rideRequest: rideRequest,
    ));
  }

  void resetAllParameters() {
    emit(const UpdateDriverParameterState());
  }
}

class DocumentApprovedStatusState extends Equatable {
  final String docApprovedStatus;

  const DocumentApprovedStatusState({
    this.docApprovedStatus = "",
  });

  DocumentApprovedStatusState copyWith({
    String? docApprovedStatus,
  }) {
    return DocumentApprovedStatusState(
      docApprovedStatus: docApprovedStatus ?? this.docApprovedStatus,
    );
  }

  @override
  List<Object?> get props => [docApprovedStatus];
}

class DocumentApprovedStatusCubit extends Cubit<DocumentApprovedStatusState> {
  DocumentApprovedStatusCubit() : super(const DocumentApprovedStatusState());

  void updateDocumentApprovedStatus({String? docApprovedStatus}) {
    var newState = state.copyWith(docApprovedStatus: docApprovedStatus);
    emit(newState);
  }

  void removeDocumentApprovedStatus() {
    emit(state.copyWith(docApprovedStatus: ""));
  }
}
