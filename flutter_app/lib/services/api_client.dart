import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // Ganti sesuai IP/domain Laravel kamu.
  // Emulator Android: 10.0.2.2  |  Device fisik: IP lokal misal 192.168.x.x
  static const String baseUrl = 'http://localhost/Project-DedSec/public/api';

  static const String _tokenKey = 'api_token';

  // ── Token helpers ──────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ── Request helpers ────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    late Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'Respons tidak valid dari server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final message = json['message'] as String? ??
        (json['errors'] != null
            ? (json['errors'] as Map).values.first.toString()
            : 'Terjadi kesalahan.');
    throw ApiException(response.statusCode, message);
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
      );
      return _handleResponse(res);
    } on SocketException {
      throw const ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      );
      return _handleResponse(res);
    } on SocketException {
      throw const ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return _handleResponse(res);
    } on SocketException {
      throw const ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(),
      );
      return _handleResponse(res);
    } on SocketException {
      throw const ApiException(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }
}
