import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService({
    String baseUrl = 'https://api.kolobokvpn.com',
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client();

  static const _tokenKey = 'kolobok_token';
  final String _baseUrl;
  final http.Client _client;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) {
    return _post(
      '/api/v1/auth/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      '/api/v1/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Token not found in login response');
    }
    await saveToken(token);
    return data;
  }

  Future<List<Map<String, dynamic>>> getNodes() async {
    final data = await _get('/api/v1/nodes', auth: true);
    return _extractList(data);
  }

  Future<Map<String, dynamic>> getProfile() {
    return _get('/api/v1/profile', auth: true);
  }

  Future<Map<String, dynamic>> getSubscription() {
    return _get('/api/v1/subscription', auth: true);
  }

  Future<Map<String, dynamic>> getSubscriptionConfigs() {
    return _get('/api/v1/subscription/configs', auth: true);
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    final data = await _get('/api/v1/plans', auth: true);
    return _extractList(data);
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final data = await _get('/api/v1/countries', auth: true);
    return _extractList(data);
  }

  Future<Map<String, dynamic>> activatePlan(String planId) {
    return _post('/api/v1/subscription/activate/$planId', auth: true);
  }

  Future<Map<String, dynamic>> _get(String path, {bool auth = false}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();
    final dynamic decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }

    String message = 'Request failed: ${response.statusCode}';
    if (decoded is Map<String, dynamic>) {
      message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          decoded['detail']?.toString() ??
          message;
    }
    throw Exception(message);
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> data) {
    final dynamic raw =
        data['data'] ?? data['items'] ?? data['results'] ?? data['nodes'] ?? data['plans'] ?? data['countries'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (data.isNotEmpty && data.values.first is List) {
      final values = data.values.first as List;
      return values.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return <Map<String, dynamic>>[];
  }
}
