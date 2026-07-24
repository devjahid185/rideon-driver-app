import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/payment/payment_method_screen.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/get_payment_type.dart';
import '../../../domain/entities/payment_method.dart';
import '../../../domain/entities/payout_transaction.dart';
import '../../cubits/payment/payment_method_cubit.dart';
import '../../cubits/payment/wallet_cubit.dart';
import '../../widgets/custom_text_form_field.dart';

class PayoutScreen extends StatefulWidget {
  final double walletBalance;
  const PayoutScreen({super.key, required this.walletBalance});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _amountController = TextEditingController();
  num _offset = 0;
  List<PayoutTransactions> _transactions = [];

  @override
  void initState() {
    isNumeric = false;
    super.initState();
    maxLimit = widget.walletBalance;
    context.read<PayoutTransactionCubit>().getPayoutTransaction(offset: "0");
    context.read<PayoutTransactionCubit>().getPayoutTotal();
  }

  Future<void> _fetchTransactions() async {
    _offset = 0;
    _transactions.clear();
    isOnload = false;
    final cubit = context.read<PayoutTransactionCubit>();
    await cubit.getPayoutTransaction(offset: '$_offset');
    _refreshController.refreshCompleted();
  }

  Future<void> onLoading() async {

    isOnload = true;
    final cubit = context.read<PayoutTransactionCubit>();
    await cubit.getPayoutTransaction(offset: '$_offset');
    _refreshController.loadComplete();
  }

  void _withdrawAmount(String methodId) async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return;

    Widgets.showLoader(context);
    final cubit = context.read<AmountPayoutCubit>();
    await cubit.getAmount(amount: amount,methodId: methodId);
    // ignore: use_build_context_synchronously
    Widgets.hideLoder(context);

    if (cubit.state is AmountPayoutSuccess) {
      _amountController.clear();
      _fetchTransactions();
      showToastMessage("Withdrawal request submitted");
    } else if (cubit.state is AmountPayoutFailed) {
      showErrorToastMessage("Withdrawal failed" );
    }
  }

  bool isShimmer = true;
  bool isOnload = false;
  bool isLoading = false;
  double maxLimit = 0;
  List<PayoutMethod> paymentMethodsList = [];
  List<PayoutTypes> payOutList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: isNumeric == true && Platform.isIOS
          ? KeyboardDoneButton(
              onTap: () {
                setState(() {
                  isNumeric = false;
                });
              },
            )
          : null,
      backgroundColor: notifires.getbgcolor,
      appBar: CustomAppBar(
        title: "Payouts",
        titleColor: notifires.getGrey1whiteColor,
        backgroundColor: notifires.getbgcolor,
      ),
      body: BlocBuilder<PayoutTransactionCubit, PayoutTransactionState>(
          builder: (context, state) {
        if (state is PayoutTransactionLoading && isOnload == false) {
          isShimmer = true;
        } else if (state is PayoutTransactionSuccess) {
          isShimmer = false;
          if (_offset == 0) {
            _transactions =
                (state.payoutTransaction?.data?.payoutTransactions ?? []);
          } else {
            _transactions.addAll(
                state.payoutTransaction?.data?.payoutTransactions ?? []);
          }
          _offset = state.payoutTransaction?.data?.offset ?? 0;

          context.read<PayoutTransactionCubit>().clear();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: grey6,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: grey4.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: regular2(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            onChanged: (v) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText:
                                  "Enter withdrawal amount".translate(context),
                              hintStyle: regular2(context).copyWith(
                                color: notifires.getGrey1whiteColor
                                    .withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: notifires.getbgcolor,
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16, right: 8),
                                child: Text(
                                  currency,
                                  style: regular3(context).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0, minHeight: 0),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: themeColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Withdraw button only visible if amount is valid
                        if (_amountController.text.isNotEmpty &&
                            _isValidAmount(_amountController.text))
                          InkWell(
                            onTap: () {
                              final amount = _amountController.text.trim();
                              if (amount.isEmpty) return;
                              context
                                  .read<PaymentMethodCubits>()
                                  .getPaymentMethod(context);
                            },
                            child: BlocBuilder<PaymentMethodCubits,
                                PaymentMethodState>(
                              builder: (context, state) {
                                if (state is PaymentMethodLoading   && ModalRoute.of(context)?.isCurrent == true) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {

                                    Widgets.showLoader(context);

                                  });
                                }
                                if (state is PaymentMethodSuccess) {

                                  paymentMethodsList =
                                      state.model.data?.payoutMethods ?? [];

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    Widgets.hideLoder(context);

                                    payoutBottomSheet(paymentMethodsList);
                                  });
                                  context.read<PaymentMethodCubits>().clear();
                                }
                                if (state is PayoutTypeSuccess) {
                                  payOutList =
                                      state.model.data?.payoutTypes ?? [];

                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    Widgets.hideLoder(context);
                                  });
                                  context.read<PaymentMethodCubits>().clear();
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:isLoading?SizedBox(
                                    height: 25,width: 25,
                                      child: CircularProgressIndicator(color: whiteColor,)): Text(
                                    "Withdraw".translate(context),
                                    style: heading3Grey1(context)
                                        .copyWith(color: whiteColor),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Max limit hint
                  Text(
                    "${"Your maximum withdrawal limit is".translate(context)} $currency $maxLimit"
                        .translate(context),
                    style: regular2(context).copyWith(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Validation error
                  if (_amountController.text.isNotEmpty)
                    Builder(
                      builder: (_) {
                        final value =
                            double.tryParse(_amountController.text) ?? 0;
                        if (value <= 0) {
                          return Text(
                            "Amount must be greater than 0".translate(context),
                            style: regular2(context).copyWith(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else if (value > maxLimit) {
                          return Text(
                            "Amount exceeds maximum limit".translate(context),
                            style: regular2(context).copyWith(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "Transaction History".translate(context),
                    style: heading3(context),
                  ),
                  const Spacer(),
                  if (_transactions.isNotEmpty)
                    Text(
                      "${_transactions.length} ${"transactions".translate(context)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: notifires.getGrey1whiteColor.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            isShimmer && _transactions.isEmpty
                ? Expanded(child: buildShimmerLoader())
                : Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                enablePullUp: _offset == -1 ? false : true,
                onRefresh: () => _fetchTransactions(),
                onLoading: () => onLoading(),
                child:  _transactions.isEmpty
                        ? Center(
                            child: Text(
                            "No transactions found.".translate(context),
                            style: regular2(context),
                          ))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              return Card(
                                color: notifires.getbgcolor,
                                elevation: 3,
                                shadowColor: Colors.black12,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 🔹 Status Icon with background
                                      Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(tx.payoutStatus)
                                                  .withValues(alpha:0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getStatusIcon(tx.payoutStatus),
                                          color:
                                              _getStatusColor(tx.payoutStatus),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // 🔹 Transaction Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // 💰 Amount
                                            Text(
                                              '₹${tx.amount}',
                                              style: heading3Grey1(context)
                                                  .copyWith(fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),

                                            // 🔹 Status Chip
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        tx.payoutStatus)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                tx.payoutStatus!.toUpperCase(),
                                                style: regular(context)
                                                    .copyWith(
                                                        color: _getStatusColor(
                                                            tx.payoutStatus),
                                                        fontSize: 11),
                                              ),
                                            ),
                                            const SizedBox(height: 6),

                                            // 📅 Date + Method
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    "${"Date".translate(context)}: ${tx.createdAt ?? ""}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    "${"Method".translate(context)}: ${toTitleCaseFromCamel(tx.paymentMethod ?? "")}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      }),
    );
  }

  bool _isValidAmount(String amount) {
    try {
      final value = double.parse(amount);
      return value > 0 &&
          value <= maxLimit; // ✅ 0 se bada aur maxLimit se kam/barabar
    } catch (e) {
      return false;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case "success":
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.timelapse;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void payoutBottomSheet(List<PayoutMethod> payoutTypes) {
    final activePayoutTypes =
        payoutTypes.where((method) => method.details?.isActive == 1).toList();
    int? selectedMethodId =
        activePayoutTypes.isNotEmpty ? activePayoutTypes.first.id : null;

    showModalBottomSheet<void>(
      backgroundColor: notifires.getbgcolor,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Choose Payout Method".translate(context),
                    style: heading2Grey1(context).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  if (activePayoutTypes.isNotEmpty) ...[
                    // List of active payout methods
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: activePayoutTypes.length,
                        itemBuilder: (context, index) {
                          final method = activePayoutTypes[index];
                          if (method.id == null) return const SizedBox.shrink();

                          final isSelected = selectedMethodId == method.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedMethodId = method.id;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeColor.withValues(alpha:0.1)
                                    : notifires.getBoxColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        method.payoutMethod?.toLowerCase() ==
                                                "bank account"
                                            ? Icons.account_balance
                                            : Icons.account_balance_wallet,
                                        color: isSelected
                                            ? themeColor
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          method.payoutMethod ?? 'Unknown',
                                          style: heading3(context).copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isSelected
                                                ? themeColor
                                                : notifires.getGrey1whiteColor,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Show details dynamically
                                  if (method.payoutMethod?.toLowerCase() ==
                                      "bank account") ...[
                                    if (method.details?.accountName != null)
                                      Text(
                                          "${"Account Holder".translate(context)}: ${method.details!.accountName}",
                                          style: regular2(context)),
                                    if (method.details?.accountNumber != null)
                                      Text(
                                          "${"A/C Number".translate(context)}: ${method.details!.accountNumber}",
                                          style: regular2(context)),
                                    if (method.details?.bankName != null)
                                      Text("${"Bank".translate(context)}: ${method.details!.bankName}",
                                          style: regular2(context)),
                                    if (method.details?.branchName != null)
                                      Text(
                                          "${"Branch".translate(context)}: ${method.details!.branchName}",
                                          style: regular2(context)),
                                    if (method.details?.iban != null)
                                      Text("${"IBAN".translate(context)}: ${method.details!.iban}",
                                          style: regular2(context)),
                                    if (method.details?.swiftCode != null)
                                      Text(
                                          "${"SWIFT".translate(context)}: ${method.details!.swiftCode}",
                                          style: regular2(context)),
                                  ] else ...[
                                    if (method.details?.email != null)
                                      Text(
                                          "${"Email/UPI".translate(context)}: ${method.details!.email}",
                                          style: regular2(context)),
                                    if (method.details?.note != null)
                                      Text("${"Note".translate(context)}: ${method.details!.note}",
                                          style: regular2(context)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Empty state UI with row button
                    Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No active payout account added yet."
                              .translate(context),
                          style: regular2(context).copyWith(
                              fontSize: 14, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: CustomsButtons(
                              text: "Cancel",
                              backgroundColor: notifires.getBoxColor,
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                        ),
                      ),
                      if (activePayoutTypes.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: CustomsButtons(
                                text: "Proceed",
                                backgroundColor: themeColor,
                                onPressed: () {
                                  if (selectedMethodId == null) {
                                    showErrorToastMessage(
                                        "Please select a payment method.");
                                    return;
                                  }
                                  Navigator.pop(context, selectedMethodId);
                                  _withdrawAmount(selectedMethodId.toString());
                                }),
                          ),
                        )

                      ],
                      if (activePayoutTypes.isEmpty) ...[
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: CustomsButtons(
                                text: "Add Account",
                                backgroundColor: themeColor,
                                onPressed: () {
                                  goBack();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (builder) =>
                                          const PaymentMethodsScreen(),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
