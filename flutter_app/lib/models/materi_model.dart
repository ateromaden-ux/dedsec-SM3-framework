class MateriModel {
  final int idMateri;
  final String judulMateri;
  final String? kategori;

  const MateriModel({
    required this.idMateri,
    required this.judulMateri,
    this.kategori,
  });

  factory MateriModel.fromJson(Map<String, dynamic> json) {
    return MateriModel(
      idMateri: json['id_materi'] as int,
      judulMateri: json['judul_materi'] as String,
      kategori: json['kategori'] as String?,
    );
  }

  @override
  String toString() => judulMateri;
}
