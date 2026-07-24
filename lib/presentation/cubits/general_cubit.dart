// ignore_for_file: use_build_context_synchronously

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/workspace.dart';
import '../../core/services/data_store.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/general_setting.dart';

abstract class GeneralState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GeneralInitial extends GeneralState {}

class GeneralLoading extends GeneralState {}

class GeneralSuccess extends GeneralState {
  final GeneralDataModel generalDataModel;

  GeneralSuccess(
    this.generalDataModel,
  );
  @override
  List<Object?> get props => [generalDataModel];
}

class GeneralFailed extends GeneralState {
  final String error;

  GeneralFailed(this.error);
  @override
  List<Object?> get props => [
        error,
      ];
}

class GeneralCubit extends Cubit<GeneralState> {
  final ProfileRepository repositories;
  GeneralCubit(this.repositories) : super(GeneralInitial());

  Future<void> fetchGeneralSetting(BuildContext context) async {
    try {
      final response = await repositories.getGeneralData(postData: {});

      if (response['status'] == 200) {
        box.put("generalSettings", response);

        GeneralDataModel generalModel = GeneralDataModel.fromJson(response);
        currency = generalModel.data?.metaData?.generalDefaultCurrency ?? "";

        box.put("currency", currency);

        context.read<FirebaseUpdateIntervalCubit>().update(generalModel.data?.metaData?.firebaseUpdateInterval ?? "");
        context.read<BackgroundLocationIntervalCubit>().update(generalModel.data?.metaData?.backgroundLocationInterval ?? "");
        context.read<DriverSearchIntervalCubit>().update(generalModel.data?.metaData?.driverSearchInterval ?? "60");
        context.read<MinimumNegativeCubit>().update(generalModel.data?.metaData?.minimumNegative ?? "20");
          box.put("backgroundUpdatedLocation", context.read<BackgroundLocationIntervalCubit>().state.value);
          box.put("DriverSearchIntervalCubit", context.read<DriverSearchIntervalCubit>().state.value);
        box.put("firebaseUpdatedLocation", context.read<FirebaseUpdateIntervalCubit>().state.value);

        emit(GeneralSuccess(GeneralDataModel.fromJson(response)));
      } else {
        emit(GeneralFailed(response['error']));
      }
    } catch (e) {
      GeneralFailed("Something went wrong");
    }
  }
}

abstract class SimpleState<T> extends Equatable {
  final T value;
  const SimpleState(this.value);

  @override
  List<Object?> get props => [value];
}

class SimpleInitial<T> extends SimpleState<T> {
  const SimpleInitial(super.value);
}

class FirebaseUpdateIntervalCubit extends Cubit<SimpleState<String?>> {
  FirebaseUpdateIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}

class BackgroundLocationIntervalCubit extends Cubit<SimpleState<String?>> {
  BackgroundLocationIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}

class DriverSearchIntervalCubit extends Cubit<SimpleState<String?>> {
  DriverSearchIntervalCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}

class MinimumNegativeCubit extends Cubit<SimpleState<String?>> {
  MinimumNegativeCubit() : super(const SimpleInitial(null));

  void update(String? val) => emit(SimpleInitial(val));
}
