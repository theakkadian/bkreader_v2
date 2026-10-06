import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import '../utils/app_logger.dart';

/// Thin HTTP wrapper with cancel support and retry/backoff.
class HttpClientWrapper {
  HttpClientWrapper({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, http.Client> _namedClients = {};

  http.Client _clientFor(String? cancelToken) {
    if (cancelToken == null) return _client;
    return _namedClients.putIfAbsent(cancelToken, http.Client.new);
  }

  /// Cancels in-flight requests associated with [cancelToken].
  void cancel(String cancelToken) {
    final named = _namedClients.remove(cancelToken);
    named?.close();
  }

  void dispose() {
    for (final c in _namedClients.values) {
      c.close();
    }
    _namedClients.clear();
    _client.close();
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    String? cancelToken,
    int maxRetries = AppConstants.maxRetries,
    Duration timeout = AppConstants.networkTimeout,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _clientFor(cancelToken)
            .get(uri, headers: headers)
            .timeout(timeout);
        return response;
      } on http.ClientException catch (e, st) {
        lastError = e;
        AppLogger.e('HTTP GET failed (attempt ${attempt + 1})', e, st);
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(
            AppConstants.retryBackoff * (attempt + 1),
          );
        }
      } on TimeoutException catch (e, st) {
        lastError = e;
        AppLogger.e('HTTP timeout (attempt ${attempt + 1})', e, st);
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(
            AppConstants.retryBackoff * (attempt + 1),
          );
        }
      }
    }
    throw NetworkException(
      lastError is TimeoutException
          ? 'Request timed out. Please try again.'
          : (lastError?.toString() ?? 'Network request failed'),
    );
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final response = await get(uri, headers: headers, cancelToken: cancelToken);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw ApiException('Unexpected JSON shape');
  }

  Future<String> getBody(
    Uri uri, {
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final response = await get(uri, headers: headers, cancelToken: cancelToken);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}');
    }
    return response.body;
  }

  Future<List<int>> getBytes(
    Uri uri, {
    Map<String, String>? headers,
    String? cancelToken,
  }) async {
    final response = await get(uri, headers: headers, cancelToken: cancelToken);
    if (response.statusCode != 200) {
      throw TextLoadException('HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
