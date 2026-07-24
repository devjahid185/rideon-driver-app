import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../presentation/cubits/logout_cubit.dart';
import '../../presentation/screens/Auth/login_screen.dart';
import '../extensions/workspace.dart';
import '../utils/common_widget.dart';
import 'config.dart';
import 'data_store.dart';

bool connectionLost = false;
String latitudeGlobal = '';
String longitudeGlobal = '';
bool shouldLogout = false;
Future<dynamic> httpPost(path, data, {required BuildContext context}) async {
  try {
    String apiBaseUrl = Config.baseUrl;
    var url = apiBaseUrl + path;
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }
    var headers = {
      'Content-Type': 'application/json',
      "Authorization": "Bearer $bearerToken",
    };
    data['module_id'] = "2";
    data['user_type'] = "driver";
    data.putIfAbsent('latitude', () => latitudeGlobal);
    data.putIfAbsent('longitude', () => longitudeGlobal);
    data['token'] = token;

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );
    var responseData =
        json.decode(const Utf8Codec().decode(response.bodyBytes));
    if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        headers["Authorization"] = "Bearer $newToken";
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(data),
        );
        responseData =
            json.decode(const Utf8Codec().decode(response.bodyBytes));
      } else {
        return {"error": "Token regeneration failed"};
      }
    }
    if (response.statusCode == 419) {
      showErrorToastMessage("Session expired. Please log in again.");
      Future.delayed(const Duration(seconds: 1), () {
        clearData(navigatorKey.currentContext!);
        goToWithClear(const LoginScreen());
      });
    }
    return responseData;
  } catch (err) {
    return {"error": "Something went wrong"};
  }
}

Future<dynamic> httpGet(String path, Map<String, dynamic> data,
    {required BuildContext context}) async {
  dynamic responsegetData;
  try {
    String apiBaseUrl = Config.baseUrl;
    var url = apiBaseUrl + path;
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }
    var headers = {
      'Content-Type': 'application/json',
      'x-auth-token': token,
      'Authorization': "Bearer $bearerToken",
    };
    data['module_id'] = "2";
    data['user_type'] = "driver";
    data['latitude'] = latitudeGlobal;
    data['longitude'] = longitudeGlobal;
    data['token'] = token;
    data['time_zone'] = "";

    String queryString = Uri(
        queryParameters:
            data.map((key, value) => MapEntry(key, value.toString()))).query;
    var fullUrl = "$url?$queryString";
    var response = await http
        .get(Uri.parse(fullUrl), headers: headers)
        .timeout(const Duration(seconds: 15)); // Timeout after 15 seconds
    if (response.statusCode == 200) {
      responsegetData =
          json.decode(const Utf8Codec().decode(response.bodyBytes));
    } else if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        headers['Authorization'] = "Bearer $bearerToken";
        response = await http.get(Uri.parse(fullUrl), headers: headers);
        responsegetData =
            json.decode(const Utf8Codec().decode(response.bodyBytes));
      } else {
        showErrorToastMessage("Token regeneration failed.");
        return {"error": "Token regeneration failed"};
      }
    } else {
      responsegetData =
          json.decode(const Utf8Codec().decode(response.bodyBytes));
      if (response.statusCode == 419) {
        showErrorToastMessage("Session expired. Please log in again.");
        Future.delayed(const Duration(seconds: 1), () {
          clearData(navigatorKey.currentContext!);
          goToWithClear(const LoginScreen());
        });
      }
    }
  } on TimeoutException {
    responsegetData = {'error': "Something went wrong. Please try again."};
  }
  return responsegetData;
}

Future<String?>? _tokenFuture;
Future<String?> generateToken() async {
  if (_tokenFuture != null) {
    return _tokenFuture;
  }
  final completer = Completer<String?>();
  _tokenFuture = completer.future;
  try {
    const String url = '${Config.baseUrlForBearer}${Config.generateToken}';
    const Map<String, String> headers = {
      "Content-Type": "application/json",
    };
    Map<String, dynamic> body = {
      "secret": Config.secretKey,
      "user_token": token
    };
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      final token = data['data']["token"].toString();
      bearerToken = token;
      box.put("bearerToken", token);
      completer.complete(token);
    } else if (response.statusCode == 419) {
      showErrorToastMessage("Session expired. Please log in again.");
      Future.delayed(const Duration(seconds: 1), () {
        clearData(navigatorKey.currentContext!);
        goToWithClear(const LoginScreen());
      });
    } else {
      completer.complete(null);
    }
  } catch (e) {
    completer.complete(null);
  } finally {
    _tokenFuture = null;
  }
  return await completer.future;
}
