import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../extensions/workspace.dart';
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
        return responseData is Map
            ? responseData
            : {"error": "Request failed. Please try again."};
      }
    }
    return responseData;
  } catch (err) {
    return {"error": "Something went wrong"};
  }
}

Future<dynamic> httpMultipartPost(
  String path,
  Map<String, String> fields, {
  required BuildContext context,
  required String fileField,
  required File file,
}) async {
  try {
    final url = Config.baseUrl + path;
    if (bearerToken.isEmpty) {
      bearerToken = await generateToken() ?? "";
    }

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Authorization': 'Bearer $bearerToken',
      'x-auth-token': token,
    });
    request.fields.addAll({
      ...fields,
      'module_id': '2',
      'user_type': 'driver',
      'token': token,
      'latitude': latitudeGlobal,
      'longitude': longitudeGlobal,
    });
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 498) {
      final newToken = await generateToken();
      if (newToken != null) {
        bearerToken = newToken;
        final retryRequest = http.MultipartRequest('POST', Uri.parse(url));
        retryRequest.headers.addAll({
          'Authorization': 'Bearer $newToken',
          'x-auth-token': token,
        });
        retryRequest.fields.addAll(request.fields);
        retryRequest.files
            .add(await http.MultipartFile.fromPath(fileField, file.path));
        streamedResponse = await retryRequest.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }

    return json.decode(const Utf8Codec().decode(response.bodyBytes));
  } catch (err) {
    return {"error": "Something went wrong", "exception": err.toString()};
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
        return responsegetData is Map
            ? responsegetData
            : {"error": "Request failed. Please try again."};
      }
    } else {
      responsegetData =
          json.decode(const Utf8Codec().decode(response.bodyBytes));
      // Keep the driver logged in even if the API session expires. The app will
      // keep local auth data and let the next request regenerate the bearer.
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
      completer.complete(null);
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
