import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum HttpMethod { get, post, put, delete, patch }

class ApiService {
  ApiService({
    required this.apiUrl,
    required this.logout,
    required this.refreshToken,
    required this.getApiToken,
    this.scaffoldMessengerKey,
  });

  final FutureOr<String?> Function(String token) refreshToken;
  final FutureOr<String?> Function() getApiToken;
  final void Function({bool? isLoginPage}) logout;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  final String apiUrl;
  // final String apiUrl = "${AppConfig.instance.baseUrl}/v1/s1";
  // final String API_URL = '${BASE_URL}api/v1';

  http.MultipartRequest getMultipartRequest(
    final String url, {
    bool isAddCustomerToUrl = true,
    HttpMethod method = HttpMethod.post,
  }) {
    String urlLocal = getApiUrl(url);
    return http.MultipartRequest(
        method.name.toUpperCase(), Uri.parse(urlLocal));
  }

  ///
  /// [params] must be Map or List<Map>
  ///
  Future<T?> execute<T extends BaseApiResponse>(String url, T responseInstance,
      {dynamic params,
      Map<String, dynamic>? queryParams,
      bool isJsonBody = true,
      HttpMethod method = HttpMethod.post,
      bool showSuccessAlert = false,
      bool showErrorMsg = true,
      http.MultipartRequest? multipartRequest,
      String? token,
      bool isTokenRequired = true,
      bool ignoreUnAutherise = false,
      bool acceptNullBody = false,
      int? logoutStatusCode,
      List<int>? additionalSuccessStatus,
      bool isThrowExc = false}) async {
    if (await checkInternet() == false) {
      if (isThrowExc) {
        return Future.error('No Internet Connection');
      }
      showToast('No Internet Connection');
      return null;
    }
    if (params != null && params is! List<Map> && params is! Map) {
      if (isThrowExc) {
        return Future.error('params only accep Map or List<Map>');
      }
      showToast('Params type not suitable');
      return null;
    }
    // loadingNotifer?.isLoading = true;
    var localUrl = getApiUrl(url);
    final queryParamsValues =
        queryParams?.values.where((element) => element != null);
    if (queryParamsValues != null && queryParamsValues.isNotEmpty) {
      queryParams!.removeWhere((key, value) => value == null);
      // final queryParamsStr = queryParams.entries.map((entry) {
      //   final key = Uri.encodeComponent(entry.key);
      //   final value = Uri.encodeComponent(entry.value.toString());
      //   return '$key=$value';
      // }).join('&');

      final queryParamsStr = queryParams.entries.expand((entry) {
        final key = Uri.encodeComponent(entry.key);
        final value = entry.value;
        if (value is Iterable) {
          return value.map((v) => '$key=${Uri.encodeComponent(v.toString())}');
        } else {
          return ['$key=${Uri.encodeComponent(value.toString())}'];
        }
      }).join('&');

      localUrl += '${localUrl.contains('?') ? '&' : '?'}$queryParamsStr';
    }
    params ??= {};
    if (!acceptNullBody) {
      if (params is List<Map>) {
        for (var element in params) {
          element.removeWhere((key, value) => value == null);
        }
      } else {
        params.removeWhere((key, value) => value == null);
      }
    }

    final header = <String, String>{};

    var accessToken = token ?? await getApiToken();

    if (isTokenRequired &&
        accessToken != null &&
        accessToken.trim().isNotEmpty) {
      if (JwtDecoder.isExpired(accessToken)) {
        final mAccessToken = await refreshToken(accessToken);
        if (mAccessToken == accessToken) {
          logout(isLoginPage: ignoreUnAutherise);
          if (isThrowExc) {
            return Future.error("Token expired!");
          }
          logout();
          return null;
        }
        accessToken = mAccessToken;
      }
      header['Authorization'] = 'Bearer $accessToken';
    }
    // header['Host'] = 'example.com';

    if (isJsonBody && params.isNotEmpty) {
      header['content-type'] = 'application/json';
    }

    printWrapped("MJM api method: ${method.name} ---- headers: $header");

    Uri uri = Uri.parse(localUrl);
    http.Response resp;
    try {
      if (multipartRequest != null) {
        multipartRequest.headers.addAll(header);
        // multipartRequest.fields.removeWhere((key, value) => value == null);
        _printMultipartParameters(multipartRequest);
        var response = await multipartRequest.send();
        resp = await http.Response.fromStream(response);
      } else {
        printWrapped("MJM api url: $localUrl \n MJM params: $params");
        final postBody =
            (isJsonBody && params.isNotEmpty) ? json.encode(params) : params;

        switch (method) {
          case HttpMethod.get:
            resp = await http.get(uri, headers: header);
            break;
          case HttpMethod.post:
            resp = await http.post(uri, headers: header, body: postBody);
            break;
          case HttpMethod.put:
            resp = await http.put(uri, headers: header, body: postBody);
            break;
          case HttpMethod.patch:
            resp = await http.patch(uri, headers: header, body: postBody);
            break;
          case HttpMethod.delete:
            resp = await http.delete(uri, headers: header, body: postBody);
            break;
        }
      }
    } catch (e) {
      debugPrint('MJM Unable to connect to server! $e');
      // showToast('Unable to connect to server!');
      if (isThrowExc) {
        return Future.error('Unable to connect to server!');
      }
      return null;
    }

    printWrapped('MJM ------response headers: ${resp.headers}');

    dynamic responseJson;
    try {
      final decoded = utf8.decode(resp.bodyBytes);
      // Log.d('MJM $url code = ${resp.statusCode} - response: ${resp.body.trim()}');
      responseJson = json.decode(decoded);
      Log.log('MJM $url code = ${resp.statusCode} - response: $responseJson');
    } catch (e) {
      debugPrint('MJM json decode exception $e');
    }

    if (responseJson == null) {
      if (isThrowExc) {
        return Future.error("Something went wrong!");
      }
      if (showErrorMsg) {
        showToast("Something went wrong!");
      }
      return null;
    }

    String? message;
    if (responseJson['message'] is String) {
      message = responseJson['message'].toString();
    }
    if (message.isNullOrEmpty && responseJson['detail'] is String) {
      message = responseJson['detail'].toString();
    }

    // final successCode = [200, 201, 202, 203, 204, 404];
    final successCode = [
      200,
      201,
      202,
      203,
      204,
      ...(additionalSuccessStatus ?? [])
    ];

    // bool isSuccess = responseJson['success'] ?? responseJson['status'] ?? true;
    bool isSuccess = successCode.contains(resp.statusCode);
    if (!isSuccess && showErrorMsg) {
      showToast(message ?? 'Api failed - ${resp.statusCode}',
          isSuccess: isSuccess);
    }
    if (showSuccessAlert && isSuccess) {
      // showAlert(message);
      showToast(message, isSuccess: isSuccess);
      // } else {
      //   showToast(message, isSuccess: isSuccess);
    }
    // loadingNotifer?.isLoading = false;
    if (resp.statusCode == 401 ||
        (logoutStatusCode != null && logoutStatusCode == resp.statusCode)) {
      logout();
      // logout(url == Constants.socialLogingApi);
      if (isThrowExc) {
        return Future.error('Token Expired!');
      }
      return null;
    }

    try {
      final responseModel = responseInstance
        ..fromJson(responseJson is Map<String, dynamic> ? responseJson : {})
        ..statusCode = resp.statusCode
        ..success = isSuccess;
      return responseModel;
    } catch (e) {
      debugPrint('MJM Apiservice fromJson conversion error: $e');
      return null;
    }
  }

  String getApiUrl(String url) {
    var localUrl = url;
    if (!url.startsWith('http')) {
      // _url = "$API_URL${isAddCustomerToUrl ? 'customerapp/' : ''}$url";
      localUrl = '$apiUrl$url';
    }
    return localUrl;
  }

  void _printMultipartParameters(http.MultipartRequest multipartRequest) {
    debugPrint(
        'MJM mulipart url: ${multipartRequest.url} \n params: ${multipartRequest.fields}');
    for (final element in multipartRequest.files) {
      debugPrint(
          'MJM params mulipart file: ${element.field} : ${element.filename} contentType: ${element.contentType}');
    }
  }

  Future<bool> checkInternet() async {
    if (kIsWeb) {
      return await _hasNetworkWeb();
    } else {
      return await _hasNetworkMobile();
    }
  }

  Future<bool> _hasNetworkWeb() async {
    try {
      final result = await http.get(Uri.parse('google.com'));
      if (result.statusCode == 200) return true;
    } on SocketException catch (_) {}
    return false;
  }

  Future<bool> _hasNetworkMobile() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {}
    return false;
  }

  void showToast(String? message, {bool isSuccess = false}) {
    if (message == null ||
        message.trim().isEmpty ||
        // context == null ||
        message.trim().toLowerCase() == 'success') {
      return;
    }

    // Get.snackbar(isSuccess ? 'Success' : 'Error', message,
    //     backgroundColor: isSuccess ? Colors.green : Colors.red,
    //     colorText: Colors.white);
    try {
      showSnackBar(scaffoldMessengerKey, message, isSuccess: isSuccess);
    } catch (e) {
      debugPrint('MJM error when showCustomSnackbar :$e');
    }
  }

  void showAlert(String? message) {
    if (message == null || message.trim().isEmpty) {
      return;
    }
    try {
      // showDialog(
      //   context: context!,
      //   builder: (context) => AlertDialog(
      //     title: const Text("Message"),
      //     content: Text(message),
      //     actions: [
      //       ElevatedButton(
      //           onPressed: () => Navigator.of(context).pop(),
      //           child: const Text('OK'))
      //     ],
      //   ),
      // );
    } catch (e) {
      debugPrint('MJM ApiService showAlert error:${e.toString()}');
    }
  }
}

// extension _DynamicExt on dynamic {
//   bool get isNotEmpty {
//     if (this is List) {
//       return (this as List).isNotEmpty;
//     }
//     if (this is Map) {
//       return (this as Map).isNotEmpty;
//     }
//     return false;
//   }
// }
