
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/workspace.dart';
import 'manage_driver_cubit.dart';

class GetListenRideRequestBookingIdCubit extends Cubit<String> {
  GetListenRideRequestBookingIdCubit() : super("");
  final DatabaseReference _rideRequestsRef =
      FirebaseDatabase.instance.ref().child('ride_requests');

  void listenToRouteBookingId({required String rideId}) {
    _rideRequestsRef.child(rideId).onChildChanged.listen((event) {
      final updatedKey = event.snapshot.key;
      final updatedValue = event.snapshot.value;

      if (updatedKey == 'bookingId') {
        navigatorKey.currentContext!
            .read<UpdateDriverParameterCubit>()
            .updateBookingId(bookingId: updatedValue.toString());

        emit(updatedValue.toString());

      }
    });
  }

  Future<void> updatePaymentStatus({
    required String rideId,
    required String newStatus,
  }) async {
    try {
      final snapshot = await _rideRequestsRef.child(rideId).get();

      if (snapshot.exists) {


        await _rideRequestsRef.child(rideId).update({
          'paymentStatus': newStatus,
        });
        await _rideRequestsRef.child(rideId).remove();
      } 
    // ignore: empty_catches
    } catch (error) {

    }
  }

  Future<void> updateTotalTime({
    required String rideId,
    required String totalTime,
  }) async {
    try {
      final snapshot = await _rideRequestsRef.child(rideId).get();

      if (snapshot.exists) {
        await _rideRequestsRef.child(rideId).update({
          'totalTime': totalTime,
        });

      } else {

      }
    } catch (error) {
       //
    }
  }

  void resetState() {
    emit("");
  }
}
