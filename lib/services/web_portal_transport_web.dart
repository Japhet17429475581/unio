import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

Dio webPortalTransport() =>
    Dio()..httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
