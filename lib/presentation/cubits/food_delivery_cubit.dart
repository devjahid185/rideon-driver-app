import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/data/repositories/food_delivery_repository.dart';

abstract class DriverFoodState {}

class DriverFoodInitial extends DriverFoodState {}

class DriverFoodLoading extends DriverFoodState {}

class DriverFoodFailure extends DriverFoodState {
  final String message;

  DriverFoodFailure(this.message);
}

class DriverFoodAvailableLoaded extends DriverFoodState {
  final List<Map<String, dynamic>> orders;

  DriverFoodAvailableLoaded(this.orders);
}

class DriverFoodActionSuccess extends DriverFoodState {
  final String message;
  final Map<String, dynamic> order;

  DriverFoodActionSuccess({
    required this.message,
    required this.order,
  });
}

class DriverFoodTimelineLoaded extends DriverFoodState {
  final List<Map<String, dynamic>> timeline;

  DriverFoodTimelineLoaded(this.timeline);
}

class DriverFoodCubit extends Cubit<DriverFoodState> {
  final FoodDeliveryRepository repository;

  DriverFoodCubit(this.repository) : super(DriverFoodInitial());

  Future<void> loadAvailableOrders({int limit = 20}) async {
    emit(DriverFoodLoading());
    try {
      final response = await repository.getAvailableOrders(limit: limit);
      if (response['status'] == 200) {
        final List raw = (response['data'] as List?) ?? [];
        final data = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        emit(DriverFoodAvailableLoaded(data));
        return;
      }
      emit(DriverFoodFailure((response['message'] ?? 'Failed to load food orders').toString()));
    } catch (e) {
      emit(DriverFoodFailure(e.toString()));
    }
  }

  Future<void> acceptOrder(int orderId) async {
    emit(DriverFoodLoading());
    try {
      final response = await repository.acceptOrder(orderId);
      if (response['status'] == 200) {
        emit(DriverFoodActionSuccess(
          message: (response['message'] ?? 'Order accepted').toString(),
          order: Map<String, dynamic>.from((response['data'] as Map?) ?? {}),
        ));
        return;
      }
      emit(DriverFoodFailure((response['message'] ?? 'Failed to accept order').toString()));
    } catch (e) {
      emit(DriverFoodFailure(e.toString()));
    }
  }

  Future<void> updateStatus({
    required int orderId,
    required String status,
    String? note,
  }) async {
    emit(DriverFoodLoading());
    try {
      final response = await repository.updateOrderStatus(
        orderId: orderId,
        status: status,
        note: note,
      );
      if (response['status'] == 200) {
        emit(DriverFoodActionSuccess(
          message: (response['message'] ?? 'Order status updated').toString(),
          order: Map<String, dynamic>.from((response['data'] as Map?) ?? {}),
        ));
        return;
      }
      emit(DriverFoodFailure((response['message'] ?? 'Failed to update status').toString()));
    } catch (e) {
      emit(DriverFoodFailure(e.toString()));
    }
  }

  Future<void> loadTimeline(int orderId) async {
    emit(DriverFoodLoading());
    try {
      final response = await repository.orderTimeline(orderId);
      if (response['status'] == 200) {
        final List raw = (response['data'] as List?) ?? [];
        final data = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        emit(DriverFoodTimelineLoaded(data));
        return;
      }
      emit(DriverFoodFailure((response['message'] ?? 'Failed to load timeline').toString()));
    } catch (e) {
      emit(DriverFoodFailure(e.toString()));
    }
  }
}

