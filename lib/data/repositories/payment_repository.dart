
import 'package:flutter/material.dart';
 
import '../../core/extensions/workspace.dart';
import '../../core/services/config.dart';
import '../../core/services/http.dart';

class PaymentRepository {
  Future<Map<String, dynamic>> updatePaymentStatusByDriver(
      {required BuildContext context,
      required String bookingId,
      required String paymentMethod}) async {
    try {
      var response = await httpPost(Config.updatePaymentStatusByDriver,
          {"booking_id": bookingId, "payment_method": paymentMethod},
          context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEarningDriver(
      {required BuildContext context,
      required Map<String, dynamic> mapData}) async {
    try {
      var response =
          await httpPost(Config.getDriverEarings, mapData, context: context);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHostWallet() async {
    try {
      var response = await httpPost(Config.getVendorWallet, {},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWalletTransactions({String? offset}) async {
    try {
      var response = await httpPost(
          Config.getVendorWalletTransactions, {"offset": "$offset"},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPayoutTransaction({String? offset}) async {
    try {
      var response = await await httpPost(
          Config.getPayoutTransactions, {"offset": "$offset"},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPayoutTotal() async {
    try {
      var response = await await httpPost(
          Config.getTotalPayoutAmount, {},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAmountWallet({String? amount,String? methodId}) async {
    try {
      var response = await httpPost(
          Config.insertPayout, {"amount": "$amount", "currency": currency,"active_payout_method_id":methodId},
          context: navigatorKey.currentContext!);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentMethod({required BuildContext context,}) async {
    try {
      var response = await httpPost(Config.getPayoutMethod, {},context:context );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addPaymentMethod(
      {required Map<String, dynamic> postData,required BuildContext context,}) async {
    try {
      var response = await httpPost(Config.addPaymentMethod, postData,context:context );

      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchPaymentMethod({required BuildContext context}) async {
    try {
      var response = await httpPost(Config.getPayoutMethod, {},context:context );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchPaymentType(
      {required BuildContext context}) async {
    try {
      var response = await httpGet(Config.getPayoutType, {},context: context);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
