import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Client for the GiziLens data API (FastAPI + PostgreSQL).
///
/// Firebase is only used for authentication; every profile, inspection,
/// subscription plan and transaction is persisted through this service.
class BackendApiService {
  BackendApiService._();

  static final BackendApiService instance = BackendApiService._();

  String get _baseUrl {
    final url = dotenv.isInitialized
        ? dotenv.env['BACKEND_BASE_URL']?.trim()
        : null;
    if (url == null || url.isEmpty) return 'https://api.gizilens.web.id';
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  String get _apiKey {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['BACKEND_API_KEY'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      };

  /// Turn a relative `/media/...` path returned by the API into an absolute URL.
  String? resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final value = path.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return value.startsWith('/') ? '$_baseUrl$value' : '$_baseUrl/$value';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl/api/v1$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    try {
      final uri = _uri(path, query);
      late final http.Response response;
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: _headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: _headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 12));
          break;
        default:
          response =
              await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 12),
          );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'BackendApiService $method $path failed: '
          '${response.statusCode} ${response.body}',
        );
        return null;
      }
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error) {
      debugPrint('BackendApiService $method $path error: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>?> getUserProfile(String uid) {
    return _send('GET', '/users/${Uri.encodeComponent(uid)}');
  }

  Future<Map<String, dynamic>?> upsertUser(
    String uid,
    Map<String, dynamic> data,
  ) {
    return _send(
      'POST',
      '/users',
      body: <String, dynamic>{...data, 'uid': uid},
    );
  }

  // ---------------------------------------------------------------------
  // Inspections
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>?> createInspection(
    Map<String, dynamic> payload,
  ) {
    return _send('POST', '/inspections', body: payload);
  }

  Future<List<Map<String, dynamic>>?> fetchInspections({
    String? userId,
    String? since,
    int limit = 50,
  }) async {
    return _fetchInspectionList('/inspections/full', userId, since, limit);
  }

  Future<List<Map<String, dynamic>>?> fetchInspectionSummaries({
    String? userId,
    String? since,
    int limit = 500,
  }) async {
    return _fetchInspectionList('/inspections', userId, since, limit);
  }

  Future<List<Map<String, dynamic>>?> _fetchInspectionList(
    String path,
    String? userId,
    String? since,
    int limit,
  ) async {
    final collected = <Map<String, dynamic>>[];
    var page = 1;

    while (collected.length < limit) {
      final pageSize = math.min(100, limit - collected.length);
      final query = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
      };
      if (userId != null && userId.isNotEmpty) query['userId'] = userId;
      if (since != null && since.isNotEmpty) query['since'] = since;

      final response = await _send('GET', path, query: query);
      if (response == null) return null;
      final items = response['items'];
      if (items is! List) return collected;
      final batch = items.whereType<Map<String, dynamic>>().toList();
      collected.addAll(batch);
      if (batch.length < pageSize) break;
      page++;
    }

    return collected;
  }

  Future<Map<String, dynamic>?> fetchInspectionDetail(String id) {
    return _send('GET', '/inspections/${Uri.encodeComponent(id)}');
  }

  // ---------------------------------------------------------------------
  // Plans & transactions
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    final response = await _send('GET', '/plans');
    final items = response?['items'];
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> createTransaction(
    Map<String, dynamic> payload,
  ) {
    return _send('POST', '/transactions', body: payload);
  }

  Future<Map<String, dynamic>?> updateTransactionStatus(
    String orderId,
    String status,
  ) {
    return _send(
      'PATCH',
      '/transactions/${Uri.encodeComponent(orderId)}/status',
      body: {'status': status},
    );
  }
}
