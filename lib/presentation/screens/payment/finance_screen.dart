import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/translate.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../cubits/bottom_bar_cubit.dart';
import 'driver_earning.dart';
import 'driver_wallet.dart';

class FinanceMainScreen extends StatefulWidget {
  final bool isFormHome;
  const FinanceMainScreen({super.key, required this.isFormHome});

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends State<FinanceMainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.isFormHome == true) {
          context.read<BottomBarCubit>().changeTabIndex(0);
        } else {
          goBack();
        }
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Finance".translate(context),
          isCenterTitle: true,
          isBackButton: widget.isFormHome,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabItem(0, "Wallet".translate(context)),
                  const SizedBox(width: 10),
                  _buildTabItem(1, "Earning".translate(context))
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: selectedIndex == 0
                  ? const Center(child: DriverWalletScreen())
                  : const Center(child: DriverEarning()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? themeColor : Colors.transparent, width: 1.5),
          boxShadow: isSelected == false
              ? [BoxShadow(color: grey5, blurRadius: 5)]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? whiteColor : grey2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
