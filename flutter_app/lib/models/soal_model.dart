import 'pilihan_jawaban_model.dart';

class SoalModel {
  final int? idSoal;
  final int idKuis;
  final String pertanyaan;
  final int poin;
  final int urutan;
  final List<PilihanJawabanModel> pilihanJawaban;

  const SoalModel({
    this.idSoal,
    required this.idKuis,
    required this.pertanyaan,
    required this.poin,
    required this.urutan,
    required this.pilihanJawaban,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    final pilihanList = (json['pilihan_jawaban'] as List<dynamic>? ?? [])
        .map((p) => PilihanJawabanModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return SoalModel(
      idSoal: json['id_soal'] as int?,
      idKuis: json['id_kuis'] as int,
      pertanyaan: json['pertanyaan'] as String,
      poin: json['poin'] as int,
      urutan: json['urutan'] as int,
      pilihanJawaban: pilihanList,
    );
  }

  /// Index (0-based) jawaban yang benar, -1 jika tidak ada.
  int get correctAnswerIndex =>
      pilihanJawaban.indexWhere((p) => p.isBenar);
}
