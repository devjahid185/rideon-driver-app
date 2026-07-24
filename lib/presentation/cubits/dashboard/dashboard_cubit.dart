import 'package:ride_on_driver/data/repositories/dashborad_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/dashborad_data.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardReset extends DashboardState {}

class DashboardSuceess extends DashboardState {
  final String? totalOrder;
  final dynamic totalEarning;
  final dynamic totalRating;
  DashboardSuceess({this.totalEarning, this.totalOrder, this.totalRating});
  @override
  List<Object?> get props => [totalEarning, totalOrder, totalRating];
}

class DashboardFailure extends DashboardState {
  final String? paymentMessage;
  DashboardFailure({this.paymentMessage});
  @override
  List<Object?> get props => [];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboradRepository dashboradRepository;
  DashboardCubit(this.dashboradRepository) : super(DashboardInitial());

  Future<void> dashBoardDriver({
    required BuildContext context,
  }) async {
    // try {
      emit(DashboardLoading());

      var response =
          await dashboradRepository.dashboradDriver(context: context);

      if (response["status"] == 200) {
        DashboardModel dashboardModel = DashboardModel.fromJson(response);

        emit(
          DashboardSuceess(
              totalEarning: dashboardModel.data!.totalEarnings.toString(),
              totalOrder: dashboardModel.data!.totalOrders!.toString(),
              totalRating: dashboardModel.data!.averageRating!),
        );
      } else {
        emit(DashboardFailure(paymentMessage: response["error"]));
      }
    // } catch (err) {
    //   emit(DashboardFailure(paymentMessage: "$err"));
    // }
  }

  void resetState() {
    emit(DashboardReset());
    emit(DashboardInitial());
  }
}
