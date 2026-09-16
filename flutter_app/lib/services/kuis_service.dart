import '../models/kuis_model.dart';
import '../models/materi_model.dart';
import 'api_client.dart';

class KuisService {
  // ── Materi ─────────────────────────────────────────────────────────────────

  static Future<List<MateriModel>> getMateri() async {
    final json = await ApiClient.get('/materi');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => MateriModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Kuis ───────────────────────────────────────────────────────────────────

  static Future<List<KuisModel>> getAll() async {
    final json = await ApiClient.get('/kuis');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => KuisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<KuisModel> getDetail(int idKuis) async {
    final json = await ApiClient.get('/kuis/$idKuis');
    return KuisModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<KuisModel> create({
    required String judulKuis,
    String? deskripsi,
    required int idMateri,
    required int batasLulus,
    required String status,
    required List<Map<String, dynamic>> questions,
  }) async {
    final json = await ApiClient.post('/kuis', {
      'judul_kuis': judulKuis,
      'deskripsi': deskripsi,
      'id_materi': idMateri,
      'batas_lulus': batasLulus,
      'status': status,
      'questions': questions,
    });
    return KuisModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<KuisModel> update(
    int idKuis, {
    String? judulKuis,
    String? deskripsi,
    int? idMateri,
    int? batasLulus,
    String? status,
  }) async {
    final json = await ApiClient.put('/kuis/$idKuis', {
      'judul_kuis': judulKuis,
      'deskripsi': deskripsi,
      'id_materi': idMateri,
      'batas_lulus': batasLulus,
      'status': status,
    }..removeWhere((_, v) => v == null));
    return KuisModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<void> delete(int idKuis) async {
    await ApiClient.delete('/kuis/$idKuis');
  }
}
