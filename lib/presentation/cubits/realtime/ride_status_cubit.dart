import 'package:ride_on_driver/data/repositories/realtime_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/realtime_ride_request.dart';

class RideStatusState extends Equatable {
  final bool rideAcceptedStatus;
  final bool rideArrivedStatus;
  final bool rideStartEndStatus;
  final bool rideCompletedStatus;

  const RideStatusState({
    this.rideCompletedStatus = false,
    this.rideAcceptedStatus = false,
    this.rideArrivedStatus = false,
    this.rideStartEndStatus = false,
  });

  RideStatusState copyWith(
      {bool? rideAcceptedStatus,
      bool? rideCompletedStatus,
      bool? rideArrivedStatus,
      bool? rideStartEndStatus}) {
    return RideStatusState(
      rideCompletedStatus: rideCompletedStatus ?? this.rideCompletedStatus,
      rideAcceptedStatus: rideAcceptedStatus ?? this.rideAcceptedStatus,
      rideArrivedStatus: rideArrivedStatus ?? this.rideArrivedStatus,
      rideStartEndStatus: rideStartEndStatus ?? this.rideStartEndStatus,
    );
  }

  @override
  List<Object?> get props => [
        rideCompletedStatus,
        rideAcceptedStatus,
        rideArrivedStatus,
        rideStartEndStatus,
      ];
}

class RideResetState extends RideStatusState {}

class RideStatusCubit extends Cubit<RideStatusState> {
  RideStatusCubit() : super(const RideStatusState());

  void updateRideCompleted({bool? rideCompletedStatus}) {
    var newState = state.copyWith(rideCompletedStatus: rideCompletedStatus);
    emit(newState);
  }

  void removeRideCompletedStatus() {
    emit(state.copyWith(rideCompletedStatus: false));
  }

  void updateRideAcceptedStatus({bool? rideAcceptedStatus}) {
    var newState = state.copyWith(rideAcceptedStatus: rideAcceptedStatus);
    emit(newState);
  }

  void removeRideAcceptedStatus() {
    emit(state.copyWith(rideAcceptedStatus: false));
  }

  void updateRideArrivedStatus({bool? rideArrivedStatus}) {
    var newState = state.copyWith(rideArrivedStatus: rideArrivedStatus);
    emit(newState);
  }

  void removeRideArrivedStatus() {
    emit(state.copyWith(rideArrivedStatus: false));
  }

  void updateRideStartEndStatus({bool? rideStartEndStatus}) {
    var newState = state.copyWith(rideStartEndStatus: rideStartEndStatus);
    emit(newState);
  }

  void removeRideStartEndStatus() {
    emit(state.copyWith(rideStartEndStatus: false));
  }

  void resetAllParameters() {
    emit(RideResetState());
    emit(const RideStatusState(
        rideStartEndStatus: false,
        rideAcceptedStatus: false,
        rideArrivedStatus: false,
        rideCompletedStatus: false));
  }
}

abstract class UpdateRideStatusInDatabaseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RideStatusInitial extends UpdateRideStatusInDatabaseState {}
class UpdatedRideStatusLoading extends UpdateRideStatusInDatabaseState {}
class RideStatusSuceessUpdated extends UpdateRideStatusInDatabaseState {
  final String? status;
  RideStatusSuceessUpdated({this.status});

  @override
  List<Object?> get props => [status];
}

class CompleteRideStatusSuceessUpdated extends UpdateRideStatusInDatabaseState {
  final String? status;
  CompleteRideStatusSuceessUpdated({this.status});

  @override
  List<Object?> get props => [status];
}
class CompleteRideStatusError extends UpdateRideStatusInDatabaseState {
  final String? error;
  CompleteRideStatusError({this.error});

  @override
  List<Object?> get props => [error];
}

class UpdateRideStatusInDatabaseCubit
    extends Cubit<UpdateRideStatusInDatabaseState> {
  RealtimeRepository realtimeRepository;
  UpdateRideStatusInDatabaseCubit(this.realtimeRepository)
      : super(RideStatusInitial());

  Future<void> updateRideStatus(
      {required BuildContext context,
      required String bookingId,
      required String rideStatus}) async {
    try {
      var response = await realtimeRepository.updateRideStatus(
          context: context, bookingId: bookingId, rideStatus: rideStatus);
      if (response["status"] == 200) {
        emit(RideStatusSuceessUpdated(status: "com"));

      }
    } catch (err) {
     //
    }
  }

  Future<void> updateCompleteRideStatus(
      {required BuildContext context,
      required String bookingId,
      required String rideStatus,
      required String json,
      required String totalTime,
      required String dropOtp
      }) async {
    try {

      emit(UpdatedRideStatusLoading());
      var response = await realtimeRepository.updateCompleteRideWithDataStatus(
          context: context,
          bookingId: bookingId,
          rideStatus: rideStatus,
          fireBaseJson: json,
          totalTime: totalTime,
        dropOtp: dropOtp

      );
      if (response["status"] == 200) {
        emit(CompleteRideStatusSuceessUpdated(status: "com"));


      }
      else{
        emit(CompleteRideStatusError(error: response["error"].toString()));

      }
    } catch (err) {
  //
    }
  }

  void resetStatus() {
    emit(RideStatusInitial());
  }
}



abstract class GetRideDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetRideDataInitial extends GetRideDataState {}

class GetRideDataLoading extends GetRideDataState {}

class GetRideDataSuccess extends GetRideDataState {
  final RealTimeRideRequest? requestDataModel;
  GetRideDataSuccess(this.requestDataModel);

  @override
  List<Object?> get props => [requestDataModel];
}
class GetRideDataSuccessForInitial extends GetRideDataState {
  final RealTimeRideRequest? requestDataModel;
  GetRideDataSuccessForInitial(this.requestDataModel);

  @override
  List<Object?> get props => [requestDataModel];
}

class UpdatedGetRideDataSuccess extends GetRideDataState {
  final RealTimeRideRequest? requestDataModel;
  UpdatedGetRideDataSuccess(this.requestDataModel);

  @override
  List<Object?> get props => [requestDataModel];
}
class UpdatedGetRideDataDropSuccess extends GetRideDataState {
  final RealTimeRideRequest? requestDataModel;
  UpdatedGetRideDataDropSuccess(this.requestDataModel);

  @override
  List<Object?> get props => [requestDataModel];
}


class GetRideDataFailed extends GetRideDataState {
  final String error;
  GetRideDataFailed(this.error);

  @override
  List<Object?> get props => [error];
}

class GetRideDataCubit extends Cubit<GetRideDataState> {
  GetRideDataCubit() : super(GetRideDataInitial());

  Future<void> fetchRideData(String rideId) async {
    emit(GetRideDataLoading()); // Uncomment to show loading state

    try {
      final ref =
          FirebaseDatabase.instance.ref().child("ride_requests").child(rideId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
        final data = RealTimeRideRequest.fromMap(dataMap);
        emit(GetRideDataSuccess(data));

      } else {

        emit(GetRideDataFailed("No ride found with ID: $rideId"));
      }
    } catch (e) {
      emit(GetRideDataFailed("Error fetching ride: $e"));

    }
  }
  Future<void> fetchRideDataForInitial(String rideId) async {
    emit(GetRideDataLoading()); // Uncomment to show loading state

    try {
      final ref =
          FirebaseDatabase.instance.ref().child("ride_requests").child(rideId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
        final data = RealTimeRideRequest.fromMap(dataMap);
        emit(GetRideDataSuccessForInitial(data));

      } else {

        emit(GetRideDataFailed("No ride found with ID: $rideId"));
      }
    } catch (e) {
      emit(GetRideDataFailed("Error fetching ride: $e"));

    }
  }

  Future<void> fetchUpdatedRideData(String rideId) async {
    try {
      final ref =
          FirebaseDatabase.instance.ref().child("ride_requests").child(rideId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = RealTimeRideRequest.fromMap(snapshot.value as Map);
        emit(UpdatedGetRideDataSuccess(data));
      } else {
        emit(GetRideDataFailed("No ride found with ID: $rideId"));
      }
    } catch (e) {
      emit(GetRideDataFailed("Error fetching ride: $e"));
    }
  }
 Future<void> fetchUpdatedRideDataForDrop(String rideId) async {
    try {
      final ref =
          FirebaseDatabase.instance.ref().child("ride_requests").child(rideId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = RealTimeRideRequest.fromMap(snapshot.value as Map);
        emit(UpdatedGetRideDataDropSuccess(data));
      } else {
        emit(GetRideDataFailed("No ride found with ID: $rideId"));
      }
    } catch (e) {
      emit(GetRideDataFailed("Error fetching ride: $e"));
    }
  }
  void clear() {
    emit(GetRideDataInitial());
  }
}

 