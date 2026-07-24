import 'package:ride_on_driver/data/repositories/register_vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/data_store.dart';

abstract class VehicleRegisterState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VehicleInitial extends VehicleRegisterState {}

class VehcileLoading extends VehicleRegisterState {}

class VehicleSuccess extends VehicleRegisterState {
  final bool triggered;
  VehicleSuccess({this.triggered = false});

  VehicleSuccess copyWith({bool? triggered}) {
    return VehicleSuccess(triggered: triggered ?? this.triggered);
  }

  @override
  List<Object?> get props => [triggered];
}

class VehicleFailure extends VehicleRegisterState {
  final String errorMsg;
  VehicleFailure(this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}

class VehicleRegisterCubit extends Cubit<VehicleRegisterState> {
  final RegisterVehicleRepository registerVehicleRepository;
  VehicleRegisterCubit(this.registerVehicleRepository)
      : super(VehicleInitial());

  Future<void> insertItem(
      {required BuildContext context,
      required Map<String, dynamic> itemMap,
      required String itemTypeId,
      required String itemId}) async {
    try {
      emit(VehcileLoading());

      final response = await registerVehicleRepository.registerVehicle(
        context: context,
        itemId: itemId,
        itemMap: itemMap,
        itemTypeId: itemTypeId,
      );

      if (response["status"] == 200) {
        if (response["data"] != null &&
            response["data"]["item_type_id"] != null) {

          box.put("itemTypeId", true);
        }

        emit(VehicleSuccess());
      } else {
        emit(VehicleFailure(response["message"] ?? "Registration failed"));
      }
    } catch (error) {
      emit(VehicleFailure("Something went wrong"));
    }
  }

  void setTrigger() {
    if (state is VehicleSuccess) {
      emit((state as VehicleSuccess).copyWith(triggered: true));
    }
  }

  void resetState() {
    emit(VehicleInitial());
  }
}

class MetaDataMap extends Cubit<Map<String, dynamic>> {
  MetaDataMap() : super({});

  void insertToMap(String key, dynamic value) {
    final updatedMap = Map<String, dynamic>.from(state);
    updatedMap[key] = value;
    emit(updatedMap);
  }

  dynamic getFromMap(String key) {
    return state[key];
  }

  void clearMap() {
    emit({});
  }
}

class AddItemMap extends Cubit<Map<String, dynamic>> {
  AddItemMap() : super({});

  void insertToMap(String key, dynamic value) {
    final updatedMap = Map<String, dynamic>.from(state);
    updatedMap[key] = value;
    emit(updatedMap);
  }

  dynamic getFromMap(String key) {
    return state[key];
  }

  void clearMap() {
    emit({});
  }
}

class GetLocationState {
  final String? currentLatitude;
  final String? currentLongitude;

  GetLocationState({
    this.currentLatitude,
    this.currentLongitude,
  });
}

class GetCurrentLocationCubit extends Cubit<GetLocationState> {
  GetCurrentLocationCubit() : super(GetLocationState());

  void updateCurrentLocation({
    String? currentLatitude,
    String? currentLongitude,
  }) {
    emit(GetLocationState(
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
    ));
  }

  void removeCurrentLocation() {
    emit(GetLocationState(currentLatitude: "", currentLongitude: ""));
  }
}

class GetItemIdState {
  final String? itemTypeId;

  GetItemIdState({this.itemTypeId});
}

class GetItemIdCubit extends Cubit<GetItemIdState> {
  GetItemIdCubit() : super(GetItemIdState());

  void updateItemId({String? itemTypeId}) {
    emit(GetItemIdState(itemTypeId: itemTypeId));
  }

  void removeItemId() {
    emit(GetItemIdState(itemTypeId: ""));
  }
}

class UpdateAddEditVehicleIdState {
  final int? vehicleAddEditTypeId;

  UpdateAddEditVehicleIdState({this.vehicleAddEditTypeId});
}

class UpdateAddEditVehicleIdCubit extends Cubit<UpdateAddEditVehicleIdState> {
  UpdateAddEditVehicleIdCubit() : super(UpdateAddEditVehicleIdState());

  void updateItemId({int? vehicleAddEditTypeId}) {
    emit(UpdateAddEditVehicleIdState(
        vehicleAddEditTypeId: vehicleAddEditTypeId));
  }

  void removeItemId() {
    emit(UpdateAddEditVehicleIdState(vehicleAddEditTypeId: 0));
  }
}
