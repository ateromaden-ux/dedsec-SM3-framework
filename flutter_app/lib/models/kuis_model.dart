import 'materi_model.dart';
import 'soal_model.dart';

class KuisModel {
  final int idKuis;
  final String judulKuis;
  final String? deskripsi;
  final int jumlahSoal;
  final int batasLulus;
  final String status;
  final int idMateri;
  final MateriModel? materi;
  final List<SoalModel> soal;

  const KuisModel({
    required this.idKuis,
    required this.judulKuis,
    this.deskripsi,
    required this.jumlahSoal,
    required this.batasLulus,
    required this.status,
    required this.idMateri,
    this.materi,
    this.soal = const [],
  });

  factory KuisModel.fromJson(Map<String, dynamic> json) {
    MateriModel? materi;
    if (json['materi'] != null) {
      materi = MateriModel.fromJson(json['materi'] as Map<String, dynamic>);
    }

    final soalList = (json['soal'] as List<dynamic>? ?? [])
        .map((s) => SoalModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return KuisModel(
      idKuis: json['id_kuis'] as int,
      judulKuis: json['judul_kuis'] as String,
      deskripsi: json['deskripsi'] as String?,
      jumlahSoal: json['jumlah_soal'] as int,
      batasLulus: json['batas_lulus'] as int,
      status: json['status'] as String,
      idMateri: json['id_materi'] as int,
      materi: materi,
      soal: soalList,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
}
