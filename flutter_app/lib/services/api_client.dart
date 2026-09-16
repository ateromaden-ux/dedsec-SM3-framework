import 'dart:convert';
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

  // ── Headers ────────────────────────────────────────────────────────────────

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

  // ── Response handler ───────────────────────────────────────────────────────

  static Map<String, dynamic> _handle(http.Response res) {
    final body = utf8.decode(res.bodyBytes);

    // Coba decode JSON
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // Bukan JSON — kembalikan raw body sebagai pesan error
      throw ApiException(
        res.statusCode,
        'Server mengembalikan respons tidak valid (${res.statusCode}):\n$body',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    // Ambil pesan error dari berbagai format Laravel response
    String message;
    if (json['errors'] != null) {
      // Validation errors — gabungkan semua field
      final errors = json['errors'] as Map<String, dynamic>;
      message = errors.entries
          .map((e) {
            final msgs = e.value is List
                ? (e.value as List).join(', ')
                : e.value.toString();
            return '${e.key}: $msgs';
          })
          .join('\n');
    } else {
      message = json['message'] as String? ?? 'Error ${res.statusCode}';
    }

    throw ApiException(res.statusCode, message);
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Gagal terhubung ke server: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Gagal terhubung ke server: $e');
    }
  }
}
