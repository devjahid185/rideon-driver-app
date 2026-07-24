import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import 'package:ride_on_driver/presentation/screens/Payment/payout_screen.dart';
import 'package:ride_on_driver/presentation/screens/payment/wallet_recharge_screen.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/get_wallet.dart';
import '../../../domain/entities/vendor_wallet.dart';
import '../../cubits/payment/wallet_cubit.dart';
import '../../cubits/payment/wallet_data_cubit.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});
  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    context.read<WalletDataCubit>().getWallet();
    context.read<WalletTransactionsCubit>().getTransactions(offset: "0");
  }

  void _onRefresh() async {
    isOnload = false;
    walletTransactions.clear();
    isLoadingWallet = false;
    setState(() {});
    context.read<WalletDataCubit>().getWallet();
    context.read<WalletTransactionsCubit>().getTransactions(offset: "0");
    _refreshController.refreshCompleted();
  }

  bool isOnload = false;
  void onLoading() async {
    isOnload = true;

    setState(() {});
    context.read<WalletTransactionsCubit>().getTransactions(offset: "$offset");
    _refreshController.loadComplete();
  }

  VendorWallet? wallet;
  bool isLoadingWallet = false;
  num offset = 0;
  List<WalletTransactionsDetails> walletTransactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: BlocBuilder<WalletDataCubit, WalletDataState>(
          builder: (context, state) {
        if (state is WalletDataLoading) {
          isLoadingWallet = true;

        } else if (state is WalletDataSuccess) {
          isLoadingWallet = false;


          wallet = state.vendorWallet;
          walletBalance = double.parse(
            (wallet?.data?.walletBalance ?? "0.0").replaceAll(",", ""),
          );
        } else if (state is WalletDataFailed) {
          isLoadingWallet = true;

          showErrorToastMessage(state.error);
        }
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet,
                            color: themeColor, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Balance".translate(context),
                            style: heading3Grey1(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoadingWallet
                                ? "$currency .........."
                                : "$currency ${wallet?.data?.walletBalance ?? "0.00"}",
                            style: heading1(context).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              color: blackColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {

                            final result = await navigatorKey.currentState!.push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const WalletRechargeScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );

                            // Agar result true hai, to refresh function call karo
                            if (result == true) {
                              _onRefresh();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: notifires.getboxcolor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: blackColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "Add Money".translate(context),
                                  style: heading3Grey1(context).copyWith(
                                    color: blackColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            goTo(
                              PayoutScreen(
                                walletBalance: double.parse(
                                  (wallet?.data?.pendingPayout ?? "0")
                                      .toString()
                                      .replaceAll(
                                          ',', ''),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_circle_up_outlined,
                                    color: whiteColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "Withdraw".translate(context),
                                  style: heading3Grey1(context).copyWith(
                                    color: whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Transactions".translate(context),
                      style: heading2Grey1(context)),
                  const SizedBox(
                    width: 10,
                  ),
                  Icon(Icons.history, color: grey3),
                ],
              ),
            ),

            // Transactions List with SmartRefresher
            BlocBuilder<WalletTransactionsCubit, WalletTransactionsState>(
                builder: (context, state) {
              if (state is WalletTransactionsLoading && isOnload == false) {
                return Expanded(child: buildShimmerLoader());
              } else if (state is WalletTransactionsSuccess) {
                isOnload = false;
                offset = state.transactions?.data?.offset ?? 0;
                walletTransactions.addAll(
                    state.transactions?.data?.walletTransactionsDetails ?? []);

                context.read<WalletTransactionsCubit>().clear();
              }
              return Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  enablePullDown: true,
                  enablePullUp: offset == -1 ? false : true,
                  onLoading: onLoading,
                  header: WaterDropHeader(
                    complete: Icon(Icons.check, color: greentext),
                    waterDropColor: themeColor,
                  ),
                  child: walletTransactions.isEmpty
                      ? Center(
                          child: Text(
                            "No transaction found".translate(context),
                            style: regular2(context),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: walletTransactions.length,
                          itemBuilder: (context, index) =>
                              _buildTransactionTile(walletTransactions[index]),
                        ),
                ),
              );
            }),
          ],
        );
      }),

      // Withdraw Button
    );
  }

  Widget _buildTransactionTile(
      WalletTransactionsDetails walletTransactionDetail) {
    bool isCredit =
        walletTransactionDetail.type.toString().toLowerCase() == "credit";
    final description = walletTransactionDetail.description ?? "";
    final isFoodEarning =
        description.toLowerCase().startsWith("food delivery earning");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    isCredit ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isFoodEarning
                      ? Icons.delivery_dining_rounded
                      : isCredit
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isFoodEarning
                              ? "Food delivery earning".translate(context)
                              : walletTransactionDetail.type
                                      ?.translate(context) ??
                                  "",
                          style: heading3Grey1(context).copyWith(
                            color: isFoodEarning
                                ? Colors.green.shade800
                                : null,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 0),
                      Text(description,
                          style: regular(context)),
                      if (isFoodEarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Added after successful delivery"
                                  .translate(context),
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        "${walletTransactionDetail.createdAt}",
                        style: regular(context).copyWith(color: grey4),
                      )
                    ]),
              ),
              Text(
                "$currency ${walletTransactionDetail.amount ?? ""}",
                style: TextStyle(
                  fontSize: 14,
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
