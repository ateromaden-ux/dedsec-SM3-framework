import '../models/soal_model.dart';
import 'api_client.dart';

class SoalService {
  static Future<List<SoalModel>> getAll(int kuisId) async {
    final json = await ApiClient.get('/kuis/$kuisId/soal');
    final list = json['data'] as List<dynamic>;
    return list
        .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SoalModel> getDetail(int kuisId, int soalId) async {
    final json = await ApiClient.get('/kuis/$kuisId/soal/$soalId');
    return SoalModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<SoalModel> create({
    required int kuisId,
    required String pertanyaan,
    required int poin,
    required int correctAnswer,
    required List<Map<String, dynamic>> options,
  }) async {
    final json = await ApiClient.post('/kuis/$kuisId/soal', {
      'pertanyaan': pertanyaan,
      'poin': poin,
      'correct_answer': correctAnswer,
      'options': options,
    });
    return SoalModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<SoalModel> update({
    required int kuisId,
    required int soalId,
    String? pertanyaan,
    int? poin,
    int? correctAnswer,
    List<Map<String, dynamic>>? options,
  }) async {
    final json = await ApiClient.put('/kuis/$kuisId/soal/$soalId', {
      'pertanyaan': pertanyaan,
      'poin': poin,
      'correct_answer': correctAnswer,
      'options': options,
    }..removeWhere((_, v) => v == null));
    return SoalModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  static Future<void> delete(int kuisId, int soalId) async {
    await ApiClient.delete('/kuis/$kuisId/soal/$soalId');
  }
}
