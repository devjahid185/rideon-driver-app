import 'dart:async';
 import 'package:ride_on_driver/core/extensions/workspace.dart';
import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/presentation/cubits/general_cubit.dart';

import '../../../core/services/data_store.dart';
import '../../../domain/entities/initial_ride_request.dart';
import '../location/ringtone_cubit.dart';

abstract class ListenRideRequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListenRideRequestInitial extends ListenRideRequestState {}

class ListenRideRequestLoading extends ListenRideRequestState {}

class ListenRideRequestSuccess extends ListenRideRequestState {
  final InitialRideRequest? rideRequest;
  final String? rideId;
  ListenRideRequestSuccess({this.rideRequest, this.rideId});
  @override
  List<Object?> get props => [rideRequest, rideId];
}

class ListenRideRequestFailure extends ListenRideRequestState {
  final String error;
  ListenRideRequestFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class ListenRideRequestCubit extends Cubit<ListenRideRequestState> {
  ListenRideRequestCubit() : super(ListenRideRequestInitial());

  bool checkBookingIdFlag = false;

  StreamSubscription<DatabaseEvent>? _addedSubscription;
  StreamSubscription<DatabaseEvent>? _changedSubscription;

  void listenForRideRequests(String driverId, {required BuildContext context}) {


    if (driverId.isEmpty) {
      emit(ListenRideRequestFailure("Driver ID is empty"));
      return;
    }
    try {
      FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final driverData = snapshot.data()!;
          final rideRequestData =
              driverData['ride_request'] as Map<String, dynamic>?;
          if (rideRequestData == null || rideRequestData.isEmpty) {
            emit(ListenRideRequestSuccess(rideRequest: null));
            return;
          }
          try {
            final rideRequest = InitialRideRequest.fromJson(rideRequestData);
            if (rideRequest.status != "pending") {
              return;
            }
            emit(ListenRideRequestSuccess(
              rideRequest: rideRequest,
              rideId: rideRequest.rideId,
            ));
          } catch (e) {
            debugPrint(
                "[RideRequestDebug] failed to parse ride_request for driverId=$driverId | error=$e | payload=$rideRequestData");
          }
        } else {
        }
      }, onError: (error) {
        emit(ListenRideRequestFailure("Failed to fetch ride request: $error"));
      });
    } catch (error) {
      emit(ListenRideRequestFailure("Exception: $error"));
    }
  }

  void resetListenRideRequest() {
    emit(ListenRideRequestInitial());

  }

  void stopListening() {
    _addedSubscription?.cancel();
    _changedSubscription?.cancel();

    emit(ListenRideRequestInitial());

  }

  @override
  Future<void> close() {
    stopListening();
    return super.close();
  }
}

class UpdateBookingIdCubit extends Cubit<String> {
  UpdateBookingIdCubit() : super("");
  final DatabaseReference _rideRequestsRef =
      FirebaseDatabase.instance.ref().child('ride_requests');
  Future<void> updateBookingId({
    required String rideId,
  }) async {
    try {
      final snapshot = await _rideRequestsRef.child(rideId).get();

      if (snapshot.exists) {
        final rideData = Map<String, dynamic>.from(snapshot.value as Map);

        final bookingId = rideData['bookingId'];

        emit(bookingId);
      }
    } catch (error) {
     //
    }
  }

  Future<String?> getBookingId({
    required String rideId,
  }) async {
    try {
      final snapshot = await _rideRequestsRef.child(rideId).get();

      if (snapshot.exists) {
        final rideData = Map<String, dynamic>.from(snapshot.value as Map);
        final bookingId = rideData['bookingId'];
        return bookingId?.toString();
      } else {

        return null;
      }
    } catch (error) {

      return null;
    }
  }

  void resetState() {
    emit("");
  }
}

abstract class UpdateRideRequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateRideRequestInitial extends UpdateRideRequestState {}

class UpdateRideRequestLoading extends UpdateRideRequestState {}

// ignore: must_be_immutable
class UpdateRideRequestSuccess extends UpdateRideRequestState {
  String? message;

  UpdateRideRequestSuccess({
    this.message,
  });
  @override
  List<Object?> get props => [
        message,
      ];
}

class UpdateRideRequestFailure extends UpdateRideRequestState {
  final String? error;
  UpdateRideRequestFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class UpdateRideRequestCubit extends Cubit<UpdateRideRequestState> {
  final DatabaseReference _rideRequestsRef =
      FirebaseDatabase.instance.ref().child('ride_requests');

  UpdateRideRequestCubit() : super(UpdateRideRequestInitial());

  Future<void> updateNewRideRequestsStatus({
    required String rideId,
    required String driverId,
    required String newStatus,
  }) async {
    try {
      if (driverId.isEmpty) {

        return;
      }

      final driverDocRef =
          FirebaseFirestore.instance.collection('drivers').doc(driverId);
      final driverSnapshot = await driverDocRef.get();

      if (!driverSnapshot.exists) {

        return;
      }

      final driverData = driverSnapshot.data();
      if (driverData == null || !driverData.containsKey('ride_request')) {

        return;
      }

      final rideRequestData = driverData['ride_request'];
      if (rideRequestData is Map<String, dynamic>) {
        final existingRideId = rideRequestData['rideId']?.toString();

        if (existingRideId == rideId) {
          final realtimeSelectedDriverId =
              (driverData['driverId'] ?? driverData['api_user_id'] ?? '')
                  .toString();

          await driverDocRef.update({
            'ride_request.status': newStatus,
          });

          if (newStatus == "accepted") {
            await _rideRequestsRef.child(rideId).update({
              'status': 'accepted',
              if (realtimeSelectedDriverId.isNotEmpty)
                'selectedDriverId': realtimeSelectedDriverId,
            });
            debugPrint(
                "[RideAcceptDebug] driver accepted | rideId=$rideId | driverDocId=$driverId | selectedDriverId=$realtimeSelectedDriverId");
          }
        } else {

        }
      } else {

      }
    } catch (error) {
      //
    }
  }

  Future<void> updatePendingRideRequests({
    required String rideId,
    required String newStatus,
  }) async {
    try {
      final snapshot = await _rideRequestsRef.child(rideId).get();

      if (snapshot.exists) {


        await _rideRequestsRef.child(rideId).update({
          'status': newStatus,
        });


        if(newStatus=="rejected"){
          await _rideRequestsRef.child((rideId)).remove();
        }

        emit(UpdateRideRequestSuccess(
          message: 'Route status updated successfully for rideId: $rideId.',
        ));
      } 
    // ignore: empty_catches
    } catch (error) {

    }
  }

  Future<void> updateDriverRating({
    required String driverId,
    required String newRating,
  }) async {
    try {
      if (driverId.isEmpty) {

        return;
      }

      final driverDocRef =
          FirebaseFirestore.instance.collection('drivers').doc(driverId);
      final driverSnapshot = await driverDocRef.get();

      if (!driverSnapshot.exists) {

        return;
      }

      await driverDocRef.update({
        'driverRating': newRating.toString(),
      });


    // ignore: empty_catches
    } catch (error) {

    }
  }

  Future<void> removeRideRequest(
      {required String rideId,
      required String driverId,
      bool? skipStatus}) async {
    try {
      if (skipStatus == true) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .update({
          'rejected_rides': FieldValue.arrayUnion([rideId]),
          'rideStatus': 'available',
          'ride_request': {},
        });
      }

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
        'ride_request': {},
        'rideStatus': 'available',
      });
    } catch (error) {

      emit(UpdateRideRequestFailure('Error updating ride request: $error'));
    }
  }

  void resetRideRequestState() {
    emit(UpdateRideRequestInitial());
  }
}


abstract class BookRideConfirmOtpState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookRideConfirmOtpInitial extends BookRideConfirmOtpState {}

class BookRideConfirmOtpLoading extends BookRideConfirmOtpState {}

class BookRideConfirmOtpSuccess extends BookRideConfirmOtpState {
  final String? message;
  BookRideConfirmOtpSuccess({this.message});
  @override
  List<Object?> get props => [message];
}

class BookRideConfirmOtpSuccessFailure extends BookRideConfirmOtpState {
  final String? error;
  BookRideConfirmOtpSuccessFailure({this.error});
  @override
  List<Object?> get props => [error];
}

class BookRideConfirmOtpCubit extends Cubit<BookRideConfirmOtpState> {
  final RegisterVehicleRepository registerVehicleRepository;
  BookRideConfirmOtpCubit(this.registerVehicleRepository)
      : super(BookRideConfirmOtpInitial());

  Future<void> confirmBookRideOtp({
    required BuildContext context,
    required String pickupOtp,
    required String bookingId,
    required String deliveryImage1,
    required String deliveryImage2,
  }) async {
    try {
      emit(BookRideConfirmOtpLoading());
      final response = await registerVehicleRepository.confirmBookRideOtp(
          context: context, pickupOtp: pickupOtp, bookingId: bookingId,deliveryImage1: deliveryImage1,deliveryImage2: deliveryImage2);

      if (response["status"] == 200) {
        emit(BookRideConfirmOtpSuccess(message: response["message"]));
      } else {
        emit(BookRideConfirmOtpSuccessFailure(error: response["error"]));

      }
    } catch (error) {
      emit(BookRideConfirmOtpSuccessFailure(error: "error$error"));

    }
  }
   
  void resetState() {
    emit(BookRideConfirmOtpInitial());
  }
}

Future<void> completeRide({
  required String driverId,
  required String rideId,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({
      'completed_rides': FieldValue.arrayUnion([rideId]),
    });

  // ignore: empty_catches
  } catch (e) {

  }
}

Future<void> rejectedRide({
  required String driverId,
  required String rideId,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({
      'rejected_rides': FieldValue.arrayUnion([rideId]),
    });

  } catch (e) {
  //
  }
}

/// for get ride request status

class GetRideRequestStatusCubit extends Cubit<String> {
  GetRideRequestStatusCubit() : super("");
  final DatabaseReference _rideRequestsRef =
      FirebaseDatabase.instance.ref().child('ride_requests');

  void listenToRouteStatus({required String rideId}) {
    _rideRequestsRef.child(rideId).onChildChanged.listen((event) {
      final updatedKey = event.snapshot.key;
      final updatedValue = event.snapshot.value;

      if (updatedKey == 'status') {
        emit(updatedValue.toString());

      }
    });
  }

  void resetState() {
    emit("");
  }
}

/// for check doc status
class GetDocApprovalStatusCubit extends Cubit<String> {
  GetDocApprovalStatusCubit() : super('');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  void listenToDocApprovalStatus({required String driverId}) {
    if (driverId.trim().isEmpty) {
      debugPrint(
          "[DocDebug] listenToDocApprovalStatus skipped: empty driverId");
      return;
    }
    _subscription?.cancel(); // Cancel previous subscription if any

    _subscription = _firestore
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        debugPrint("[DocDebug] firestore snapshot empty | driverId=$driverId");
        return;
      }

      final rawStatus = data['docApprovedStatus']?.toString() ?? '';
      final normalizedStatus = rawStatus.trim().toLowerCase();
      final rawIsVerified = data['isVerified']?.toString() ?? '';
      final normalizedIsVerified = rawIsVerified.trim().toLowerCase();

      debugPrint(
          "[DocDebug] firestore doc status | driverId=$driverId | rawStatus=$rawStatus | normalizedStatus=$normalizedStatus | isVerified=$rawIsVerified");

      if (normalizedIsVerified == "yes") {
        box.put("isApproved", true);
      }
      emit(normalizedStatus);
    });
  }
  void setIsApprovedStatus({
    required String driverId,
    required String status,
  }) {
    _firestore.collection("drivers").doc(driverId).update({
      "isVerified": status,
    });
  }

  void resetStatus() {
    emit('');
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
class GetDriverStatusCubit extends Cubit<String> {
  GetDriverStatusCubit() : super('');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  void listenDriverStatusStatus({required String driverId}) {
    _subscription?.cancel(); // Cancel previous subscription if any

    _subscription = _firestore
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data.containsKey('driverStatus')) {
        final status = data['driverStatus'].toString();
        emit(status);

      }
    });
  }

  void resetStatus() {
    emit('');
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}


class GetPaymentStatusAndMethodCubit extends Cubit<Map<String, String>> {
  GetPaymentStatusAndMethodCubit() : super({});

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _subscription;

  void listenToPaymentStatusAndMethod({required String rideId}) {

    _subscription?.cancel();

    _subscription =
        _database.child('ride_requests').child(rideId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final paymentStatus = data['paymentStatus']?.toString() ?? '';
        final paymentMethod = data['paymentMethod']?.toString() ?? '';
       

        emit({
          'paymentStatus': paymentStatus,
          'paymentMethod': paymentMethod,
   
        });


      }
    });
  }
  

  void resetStatus() {
    emit({});
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
class GetPaymentAmountCubit extends Cubit<Map<String, String>> {
  GetPaymentAmountCubit() : super({});

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _subscription;

  void listenToPaymentAmount({required String rideId}) {

    _subscription?.cancel();

    _subscription =
        _database.child('ride_requests').child(rideId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
 
        final totalFare = data['travelCharges']?.toString() ?? '';
        final couponApply = data['couponApply']?.toString() ?? 'no';
        final discountFare = data['discountFare']?.toString() ?? '';

         

        emit({
        
          "totalFare":totalFare,
          "couponApply":couponApply,
          "discountFare":discountFare
        });


      }
    });
  }
  

  void resetStatus() {
    emit({});
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
/// check ride is exit or not in realtime
Future<void> checkAndCleanRideOnStartup({
  required String driverId,
}) async {
  try {

    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();


    if (!driverDoc.exists || driverDoc.data() == null) return;
     final data = driverDoc.data()!;
    final driverIdNumeric=data["driverId"].toString();
    final rideReq = (data['ride_request'] as Map<String, dynamic>?) ?? {};
    if (rideReq.isEmpty) return;
     final rideId = rideReq['rideId']?.toString() ?? '';
    final requestTime=   rideReq['requestTime'];

    if (rideId.isEmpty) {
      await _clearDriverRideRequest(driverId);
      return;
    }
     final rideRef = FirebaseDatabase.instance.ref('ride_requests/$rideId');
    final snap = await rideRef.get();

    if (!snap.exists) {
      await _clearDriverRideRequest(driverId);

      return;
    }
     final selectedDriverId = (snap.child('selectedDriverId').value ?? '').toString();
    final rideStatus = (snap.child('status').value ?? '').toString();


    if(selectedDriverId==driverIdNumeric){

      return;
    }
     if (selectedDriverId.isNotEmpty&&selectedDriverId!=driverIdNumeric) {
      await _clearDriverRideRequest(driverId);

      return;
    }

    if (requestTime != null) {

      DateTime? reqTime;


      if (requestTime is Timestamp) {
        reqTime = requestTime.toDate();
      } else if (requestTime is DateTime) {
        reqTime = requestTime;
      } else if (requestTime is String) {
        reqTime = DateTime.tryParse(requestTime);
      }

      if (reqTime != null) {
        final now = DateTime.now();
        final diff = now.difference(reqTime).inSeconds;
        final howMuchDiff=int.parse(navigatorKey.currentContext!.read<DriverSearchIntervalCubit>().state.value??box.get("DriverSearchIntervalCubit")??60)+5;

        if (diff > howMuchDiff) {
          debugPrint(
              "Ride $rideId expired ($diff seconds old) — clearing request... not $howMuchDiff");
          await _clearDriverRideRequest(driverId);

          if(rideStatus.isNotEmpty){
            if(rideStatus=="pending"){
              rideRef.remove();
            }
          }
          return;
        }
      }
    }


    final rawTs = snap.child('timestamp').value;

    final rideTime = _parseRideTimestamp(rawTs); // helper use
    if (rideTime != null) {
      final now = DateTime.now();
      final diff = now.difference(rideTime);

      if (diff.inSeconds >= 90) {
        await _clearDriverRideRequest(driverId);

        return;
      }
    } else {
      debugPrint('Ride timestamp missing/invalid for $rideId');
    }

  } catch (e) {
    debugPrint('checkAndCleanRideOnStartup error: $e');
  }
}





DateTime? _parseRideTimestamp(dynamic raw) {
  try {
    if (raw == null) return null;

     if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: false);
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: false);
    }


    final s = raw.toString().trim();
    if (s.isEmpty) return null;


    final dt = DateTime.tryParse(s);
    return dt;
  } catch (_) {
    return null;
  }
}
Future<void> _clearDriverRideRequest(String driverId) async {
  try {
    await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({

      'ride_request': {},
      'rideStatus': 'available',
    });
    RingtoneHelper().stopRingtone();


  } catch (e) {
    debugPrint('Failed to clear driver ride_request: $e');
  }
}
