import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class UserDataState extends Equatable {
  final int driverStep;

  const UserDataState({
    this.driverStep = 0,
  });


  UserDataState copyWith({
    int? driverStep,
  }) {
    return UserDataState(
      driverStep: driverStep ?? this.driverStep,
    );
  }

  @override
  List<Object?> get props => [
        driverStep,
      ];
}

class UserDataCubit extends Cubit<UserDataState> {
  late final Box _box;

  UserDataCubit() : super(const UserDataState()) {
    _box = Hive.box('appBox');
  }

  Future<void> setDriverStep(int step) async {
    try {
      await _box.put('driverStep', step);
      emit(state.copyWith(driverStep: step));
    } catch (e) {
    //
    }
  }

  Future<void> getDriverStep() async {
    try {
      int step = _box.get('driverStep') ?? 0;
      emit(state.copyWith(driverStep: step));
    } catch (e) {
      //
    }
  }

  Future<void> clearUserData() async {
    try {
      await _box.delete("UserData");
      emit(const UserDataState());
    } catch (e) {
    //
    }
  }
}
