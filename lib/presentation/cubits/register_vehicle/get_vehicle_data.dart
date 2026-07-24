import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/get_all_categories.dart';
import '../../../domain/entities/get_item_vehicle.dart';

abstract class GetVehicleDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetVehicleInitial extends GetVehicleDataState {}

class GetVehicleLoading extends GetVehicleDataState {}

// ignore: must_be_immutable
class GetVehicleSuccess extends GetVehicleDataState {
  List<ItemTypes> itemTypes;

  GetVehicleSuccess(
    this.itemTypes,
  );
  @override
  List<Object?> get props => [
        itemTypes,
      ];
}

class GetVehcileFailure extends GetVehicleDataState {
  final String error;
  GetVehcileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class GetVehicleDataCubit extends Cubit<GetVehicleDataState> {
  final RegisterVehicleRepository registerVehicleRepository;
  GetVehicleDataCubit(this.registerVehicleRepository)
      : super(GetVehicleInitial());

  Future<void> getAllCategories({required BuildContext context}) async {
    try {
      emit(GetVehicleLoading());
      final response =
          await registerVehicleRepository.getCategories(context: context);
      if (response["status"] == 200) {
        GetAllCategories getAllCategories = GetAllCategories.fromJson(response);

        emit(GetVehicleSuccess(getAllCategories.data!.itemTypes!));
      } else {
        emit(GetVehcileFailure(response["error"] ?? "Something went wrong"));
      }
    } catch (e) {
      emit(GetVehcileFailure("Something went wrong $e"));
    }
  }
}

abstract class GetItemVehicleDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetItemInitial extends GetItemVehicleDataState {}

class GetItemLoading extends GetItemVehicleDataState {}


// ignore: must_be_immutable
class GetItemSuccess extends GetItemVehicleDataState {
  GetItemVehicleModel getItemVehicleModel;

  GetItemSuccess(this.getItemVehicleModel);
  @override
  List<Object?> get props => [getItemVehicleModel];
}

class GetItemFailure extends GetItemVehicleDataState {
  final String error;
  GetItemFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class GetItemVehicleDataCubit extends Cubit<GetItemVehicleDataState> {
  final RegisterVehicleRepository registerVehicleRepository;
  GetItemVehicleDataCubit(this.registerVehicleRepository)
      : super(GetItemInitial());

  Future<void> getVehicleItemData({required BuildContext context}) async {
    try {
      emit(GetItemLoading());
      final response =
          await registerVehicleRepository.getVehicleItemData(context: context);

      if (response["status"] == 200) {
        emit(GetItemSuccess(GetItemVehicleModel.fromJson(response)));
      } else {
        emit(GetItemFailure(response[""]));
      }
    } catch (e) {
      emit(GetItemFailure("Something went wrong $e"));
    }
  }

  void clear() {
    emit(GetItemInitial());
  }
}
