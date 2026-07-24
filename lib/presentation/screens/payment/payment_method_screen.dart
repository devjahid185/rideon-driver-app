import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
 
import '../../../../core/utils/theme/project_color.dart';
import '../../../../core/utils/theme/theme_style.dart';
import '../../../core/utils/common_widget.dart';
import '../../../domain/entities/get_payment_type.dart';
import '../../../domain/entities/payment_method.dart';
import '../../cubits/payment/payment_method_cubit.dart';
import 'add_payment_method_screen.dart';
 




class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  PayoutTypes? _selectedPaymentMethod;
  List<PayoutMethod> paymentMethodsList = [];
  List<PayoutTypes> payOutList = [];

  @override
  void initState() {
    super.initState();
    context.read<PaymentMethodCubits>().getPayoutType(context);
  }

  void _onPaymentMethodSelected(PayoutTypes? method) {
    if (method == null) return;

    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  PaymentDetails? _getPaymentDetailsForType(PayoutTypes payoutType) {
    try {
      final existingMethod = paymentMethodsList.firstWhere(
            (method) => method.id == payoutType.id,
        orElse: () => PayoutMethod(id: 0, payoutMethod: 'None'),
      );

      return existingMethod.id != 0 ? existingMethod.details : null;
    } catch (e) {
      return null;
    }
  }

  bool _isMethodConfigured(PayoutTypes payoutType) {
    return paymentMethodsList.any((method) => method.id == payoutType.id);
  }

  bool _isMethodActive(PayoutTypes payoutType) {
    try {
      final method = paymentMethodsList.firstWhere(
            (method) => method.id == payoutType.id,
      );
      return method.details?.isActive == 1;
    } catch (e) {
      return false;
    }
  }

  String _getStatusText(PayoutTypes payoutType) {
    if (!_isMethodConfigured(payoutType)) {
      return 'Not Configured';
    }
    return _isMethodActive(payoutType) ? 'Active' : 'Inactive';
  }

  Color _getStatusColor(PayoutTypes payoutType) {
    if (!_isMethodConfigured(payoutType)) {
      return Colors.grey;
    }
    return _isMethodActive(payoutType) ? Colors.green : Colors.red;
  }

  Color _getStatusBackgroundColor(PayoutTypes payoutType) {
    if (!_isMethodConfigured(payoutType)) {
      return Colors.grey.withValues(alpha:0.1);
    }
    return _isMethodActive(payoutType)
        ? Colors.green.withValues(alpha:0.1)
        : Colors.red.withValues(alpha:0.1);
  }

  IconData _getMethodIcon(String? methodName) {
    switch (methodName?.toLowerCase()) {
      case 'bank account':
        return Icons.account_balance;
      case 'paypal':
        return Icons.payment;
      case 'stripe':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  void _navigateToAddEditScreen(PayoutTypes payoutType) {
    final isConfigured = _isMethodConfigured(payoutType);
    final existingDetails = _getPaymentDetailsForType(payoutType);

    goTo(AddPaymentDetails(
      addedit: isConfigured ? "Edit" : "Add",
      id: payoutType.id ?? 0,
      type: payoutType.name ?? '',
      existingPayoutMethods: paymentMethodsList,
      paymentDetails: existingDetails,
    ));
  }

  Future<void> _updatePaymentMethodStatus(
      BuildContext context,
      int methodId,
      int isActive,
      ) async {
    try {
      final existingPayoutMethods = paymentMethodsList;

      List<Map<String, dynamic>> payoutMethodsList =
      existingPayoutMethods.map((method) {
        final int parsedMethodId = method.id ?? 0;
        final int methodIsActive = parsedMethodId == methodId
            ? isActive
            : (method.details?.isActive ?? 0);
        return {
          "payout_method_id": parsedMethodId,
          "is_active": methodIsActive,
          if (method.payoutMethod?.toLowerCase() == "bank account") ...{
            "account_name": method.details?.accountName,
            "bank_name": method.details?.bankName,
            "branch_name": method.details?.branchName,
            "account_number": method.details?.accountNumber,
            "iban": method.details?.iban,
            "swift_code": method.details?.swiftCode,
          } else ...{
            "email": method.details?.email,
            "note": method.details?.note,
          }
        };
      }).toList();

      var map = {
        "payout_methods": payoutMethodsList,
        "active_payout_method_id": methodId,
      };
      context.read<PaymentMethodCubits>().updateStatusPaymentMethod(context, map: map);
    } catch (e) {
      showErrorToastMessage("An error occurred: $e");
      debugPrint("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      appBar: CustomAppBar(
        title: "Add/Edit Payout Method".translate(context),
        backgroundColor: notifires.getbgcolor,

        titleColor: notifires.getGrey1whiteColor,
      ),
      body: BlocConsumer<PaymentMethodCubits, PaymentMethodState>(
        listener: (context, state) {
          if (state is PaymentMethodSuccess) {
            paymentMethodsList = state.model.data?.payoutMethods ?? [];
            context.read<PaymentMethodCubits>().clear();
          }
          if (state is UpdatePaymentMethodSuccess) {
            Widgets.hideLoder(context);
            paymentMethodsList = state.model.data?.payoutMethods ?? [];
            context.read<PaymentMethodCubits>().clear();
          }
          if (state is UpdatedPaymentMethodLoading) {
            Widgets.showLoader(context);
          }
        },
        builder: (context, state) {
          if (state is PayoutTypeLoading || state is PaymentMethodLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          }

          if (state is PayoutTypeSuccess) {
            payOutList = state.model.data?.payoutTypes ?? [];
            if (_selectedPaymentMethod == null && payOutList.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onPaymentMethodSelected(payOutList.first);
              });
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildHeaderSection(),
                const SizedBox(height: 24),


                _buildPaymentMethodsList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 6),
        Text(
          "Add your preferred account to receive your payouts securely."
              .translate(context),
          style: regular2(context).copyWith(
            fontSize: 14,
            color: notifires.getGrey1whiteColor.withValues(alpha:0.7),
            height: 1.4,
          ),
        ),
       ],
    );
  }



  Widget _buildPaymentMethodsList() {
    if (payOutList.isEmpty) {
      return Expanded(
        child: Center(
          child: Text("Data not found".translate(context),style: regular2(context),),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: payOutList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payoutType = payOutList[index];

          if (payoutType.id == null || payoutType.name == null) {
            return const SizedBox.shrink();
          }

          final isConfigured = _isMethodConfigured(payoutType);
          final statusText = _getStatusText(payoutType);
          final statusColor = _getStatusColor(payoutType);
          final statusBackgroundColor = _getStatusBackgroundColor(payoutType);
          final isActive = _isMethodActive(payoutType);
          final methodIcon = _getMethodIcon(payoutType.name);

          return _buildPaymentMethodCard(
            payoutType: payoutType,
            isConfigured: isConfigured,
            statusText: statusText,
            statusColor: statusColor,
            statusBackgroundColor: statusBackgroundColor,
            isActive: isActive,
            methodIcon: methodIcon,
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PayoutTypes payoutType,
    required bool isConfigured,
    required String statusText,
    required Color statusColor,
    required Color statusBackgroundColor,
    required bool isActive,
    required IconData methodIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: notifires.getbgcolor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notifires.getGrey1whiteColor.withValues(alpha:0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _onPaymentMethodSelected(payoutType);
            _navigateToAddEditScreen(payoutType);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    methodIcon,
                    color: whiteColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (payoutType.name ?? 'Unknown').toString().toUpperCase(),
                        style: heading3Grey1(context).copyWith(
                          fontSize: 15,
                          // fontWeight: FontWeight.w600,
                          color: notifires.getGrey1whiteColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: regular2(context).copyWith(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    if (isConfigured)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (bool newValue) async {
                              await _updatePaymentMethodStatus(
                                context,
                                payoutType.id ?? 0,
                                newValue ? 1 : 0,
                              );
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          _onPaymentMethodSelected(payoutType);
                          _navigateToAddEditScreen(payoutType);
                        },
                        icon: Icon(
                          isConfigured ? Icons.edit_outlined : Icons.add,
                          size: 18,
                          color: blackColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
