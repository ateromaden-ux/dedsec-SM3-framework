class GuruModel {
  final int idGuru;
  final String namaGuru;
  final String email;
  final String? mataPelajaran;

  const GuruModel({
    required this.idGuru,
    required this.namaGuru,
    required this.email,
    this.mataPelajaran,
  });

  factory GuruModel.fromJson(Map<String, dynamic> json) {
    return GuruModel(
      idGuru: json['id_guru'] as int,
      namaGuru: (json['nama_guru'] ?? json['email'] ?? '') as String,
      email: json['email'] as String,
      mataPelajaran: json['mata_pelajaran'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_guru': idGuru,
        'nama_guru': namaGuru,
        'email': email,
        'mata_pelajaran': mataPelajaran,
      };
}
