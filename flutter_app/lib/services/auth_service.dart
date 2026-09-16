import '../models/guru_model.dart';
import 'api_client.dart';

class AuthService {
  /// Login dan simpan token. Kembalikan [GuruModel].
  static Future<GuruModel> login(String email, String password) async {
    final json = await ApiClient.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );

    final token = json['token'] as String;
    await ApiClient.saveToken(token);

    return GuruModel.fromJson(json['guru'] as Map<String, dynamic>);
  }

  /// Logout: hapus token di server dan lokal.
  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Tetap hapus token lokal meski request gagal
    }
    await ApiClient.clearToken();
  }

  /// Info guru yang sedang login.
  static Future<GuruModel> me() async {
    final json = await ApiClient.get('/auth/me');
    return GuruModel.fromJson(json);
  }
}
