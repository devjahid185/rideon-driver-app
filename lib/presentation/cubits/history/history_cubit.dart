import 'package:ride_on_driver/data/repositories/history_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/history.dart';

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistorySuccess extends HistoryState {
  final HistoryModel? historyModel;
  final List<Bookings>? bookings;
  final String? type;

  HistorySuccess({this.historyModel, this.bookings,this.type});

  @override
  List<Object?> get props => [historyModel, bookings,type];
}

class HistoryError extends HistoryState {
  final String? errorMessage;
  HistoryError({this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryRepository historyRepository;
  HistoryCubit(this.historyRepository) : super(HistoryInitial());

  Future<void> getHistoryData({
    required BuildContext context,
    required String type,
    required Map<String, dynamic> bookingKeyMap,
  }) async {
    try {
      emit(HistoryLoading());
      var response = await historyRepository.getHistoryData(
          context: context, bookingKeyMap: bookingKeyMap);
      if (response["status"] == 200) {
        HistoryModel historyModel = HistoryModel.fromJson(response);

        emit(HistorySuccess(
            bookings: historyModel.data!.bookings, historyModel: historyModel,type: type));
      } else {
        emit(HistoryError(errorMessage: response["error"]));
      }
    } catch (error) {
      emit(HistoryError(errorMessage: "$error"));
    }
  }

  void resetHistoryData() {
    emit(HistoryInitial());
  }
}
