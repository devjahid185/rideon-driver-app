import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/theme/theme_style.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/cubits/food_delivery_cubit.dart';
import 'dart:async';
import 'package:ride_on_driver/presentation/screens/home/food_active_delivery_screen.dart';

class FoodDriverOrdersScreen extends StatefulWidget {
  const FoodDriverOrdersScreen({super.key});

  @override
  State<FoodDriverOrdersScreen> createState() => _FoodDriverOrdersScreenState();
}

class _FoodDriverOrdersScreenState extends State<FoodDriverOrdersScreen> {
  Timer? _refreshTimer;
  int? _acceptingOrderId;

  @override
  void initState() {
    super.initState();
    context.read<DriverFoodCubit>().loadAvailableOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      context.read<DriverFoodCubit>().loadAvailableOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'ready_for_pickup':
        return 'picked_up';
      case 'picked_up':
        return 'on_the_way';
      case 'on_the_way':
        return 'delivered';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Orders'.translate(context)),
        actions: [
          IconButton(
            onPressed: () => context.read<DriverFoodCubit>().loadAvailableOrders(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<DriverFoodCubit, DriverFoodState>(
        listener: (context, state) {
          if (state is DriverFoodFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is DriverFoodActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            final acceptedId = int.tryParse((state.order['id'] ?? '').toString());
            if (_acceptingOrderId != null &&
                acceptedId == _acceptingOrderId) {
              _acceptingOrderId = null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodActiveDeliveryScreen(orderId: acceptedId!),
                ),
              );
              return;
            }
            context.read<DriverFoodCubit>().loadAvailableOrders();
          }
        },
        builder: (context, state) {
          if (state is DriverFoodLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DriverFoodAvailableLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                child: Text('No available food order'.translate(context), style: regular(context)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final o = state.orders[index];
                final orderId = int.tryParse((o['id'] ?? '').toString()) ?? 0;
                final orderNo = (o['order_number'] ?? '').toString();
                final status = (o['status'] ?? '').toString();
                final total = (o['total_amount'] ?? '').toString();
                final commission =
                    (o['driver_commission'] ?? o['delivery_fee'] ?? '0')
                        .toString();
                final paymentStatus = (o['payment_status'] ?? '').toString();
                final paymentMethod = (o['payment_method'] ?? '').toString();
                final address = (o['delivery_address'] ?? '').toString();
                final hasDriver = o['driver_id'] != null;
                final next = _nextStatus(status);
                final isWaitingForRestaurant = hasDriver &&
                    (status == 'placed' || status == 'accepted' || status == 'preparing');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(orderNo, style: headingBlack(context).copyWith(fontSize: 14)),
                          Text('Status: $status', style: regular(context)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Total: $total', style: regular(context)),
                      const SizedBox(height: 8),
                      _DriverPaymentBanner(
                        status: paymentStatus,
                        method: paymentMethod,
                        amount: total,
                      ),
                      const SizedBox(height: 8),
                      _DriverEarningBanner(amount: commission),
                      const SizedBox(height: 6),
                      Text(address, style: regular(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!hasDriver && (status == 'placed' || status == 'ready_for_pickup'))
                            Expanded(
                              child: ElevatedButton(
                                onPressed: orderId == 0
                                    ? null
                                    : () {
                                        _acceptingOrderId = orderId;
                                        context.read<DriverFoodCubit>().acceptOrder(orderId);
                                      },
                                child: Text('Accept'.translate(context)),
                              ),
                            ),
                          if (hasDriver && next.isNotEmpty)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: orderId == 0
                                    ? null
                                    : () => context.read<DriverFoodCubit>().updateStatus(
                                          orderId: orderId,
                                          status: next,
                                        ),
                                child: Text('Mark $next'.translate(context)),
                              ),
                            ),
                          if (isWaitingForRestaurant)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Waiting for restaurant'.translate(context),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: orderId == 0
                                ? null
                                : () => context.read<DriverFoodCubit>().loadTimeline(orderId),
                            child: Text('Timeline'.translate(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is DriverFoodTimelineLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: state.timeline.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final t = state.timeline[i];
                return ListTile(
                  title: Text('${t['from_status'] ?? 'start'} -> ${t['to_status'] ?? ''}'),
                  subtitle: Text((t['created_at'] ?? '').toString()),
                );
              },
            );
          }

          if (state is DriverFoodFailure) {
            return Center(child: Text(state.message, style: regular(context)));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DriverPaymentBanner extends StatelessWidget {
  const _DriverPaymentBanner({
    required this.status,
    required this.method,
    required this.amount,
  });

  final String status;
  final String method;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.trim().toLowerCase() == 'paid';
    final color = isPaid ? const Color(0xFF168A4A) : Colors.orange.shade800;
    final methodLabel = method.replaceAll('_', ' ').trim().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(isPaid ? Icons.verified_rounded : Icons.schedule_rounded, color: color, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isPaid
                  ? 'PAID • DO NOT COLLECT CASH${methodLabel.isEmpty ? '' : ' • $methodLabel'}'
                  : 'PAYMENT PENDING${methodLabel.isEmpty ? '' : ' • $methodLabel'}',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DriverEarningBanner extends StatelessWidget {
  const _DriverEarningBanner({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF168A4A).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF168A4A).withValues(alpha: .3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFF168A4A),
            size: 23,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'YOUR EARNING AFTER DELIVERY'.translate(context),
              style: const TextStyle(
                color: Color(0xFF168A4A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFF168A4A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
