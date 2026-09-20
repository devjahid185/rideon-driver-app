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

String _bodyPreview(String body, {int limit = 700}) {
  return body.length > limit ? body.substring(0, limit) : body;
}

void _logHttpFailure(
  String method,
  String url,
  int statusCode,
  String body, {
  Object? exception,
}) {
  debugPrint(
    "[HTTP][$method][FAIL] url=$url | code=$statusCode | hasUserToken=${token.isNotEmpty} | userTokenLength=${token.length} | hasBearer=${bearerToken.isNotEmpty}",
  );
  if (body.isNotEmpty) {
    debugPrint("[HTTP][$method][FAIL] body=${_bodyPreview(body)}");
  }
  if (exception != null) {
    debugPrint("[HTTP][$method][FAIL] exception=$exception");
  }
}

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
    var rawBody = const Utf8Codec().decode(response.bodyBytes);
    var responseData = json.decode(rawBody);
    if (response.statusCode >= 400 ||
        (responseData is Map &&
            (responseData["status"] == 419 ||
                responseData["ResponseCode"] == 419 ||
                responseData["message"]
                    .toString()
                    .toLowerCase()
                    .contains("token")))) {
      _logHttpFailure("POST", url, response.statusCode, rawBody);
    }
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
        rawBody = const Utf8Codec().decode(response.bodyBytes);
        responseData = json.decode(rawBody);
      } else {
        return responseData is Map
            ? responseData
            : {"error": "Request failed. Please try again."};
      }
    }
    return responseData;
  } catch (err) {
    _logHttpFailure("POST", Config.baseUrl + path.toString(), 0, "",
        exception: err);
    return {"error": "Something went wrong", "exception": err.toString()};
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

    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    if (response.statusCode >= 400 || rawBody.toLowerCase().contains("token")) {
      _logHttpFailure("MULTIPART", url, response.statusCode, rawBody);
    }

    return json.decode(rawBody);
  } catch (err) {
    _logHttpFailure("MULTIPART", Config.baseUrl + path, 0, "", exception: err);
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
    final rawBody = const Utf8Codec().decode(response.bodyBytes);
    if (response.statusCode == 200) {
      responsegetData = json.decode(rawBody);
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
      responsegetData = json.decode(rawBody);
      _logHttpFailure("GET", fullUrl, response.statusCode, rawBody);
      // Keep the driver logged in even if the API session expires. The app will
      // keep local auth data and let the next request regenerate the bearer.
    }
  } on TimeoutException {
    _logHttpFailure("GET", Config.baseUrl + path, 0, "", exception: "timeout");
    responsegetData = {'error': "Something went wrong. Please try again."};
  } catch (e) {
    _logHttpFailure("GET", Config.baseUrl + path, 0, "", exception: e);
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
      "user_token": token,
    };
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    var data = json.decode(response.body);
    if (response.statusCode >= 400) {
      _logHttpFailure("TOKEN", url, response.statusCode, response.body);
    }
    if (response.statusCode == 419 && token.isNotEmpty) {
      response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({"secret": Config.secretKey}),
      );
      data = json.decode(response.body);
    }

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
    _logHttpFailure(
        "TOKEN", Config.baseUrlForBearer + Config.generateToken, 0, "",
        exception: e);
    completer.complete(null);
  } finally {
    _tokenFuture = null;
  }
  return await completer.future;
}
