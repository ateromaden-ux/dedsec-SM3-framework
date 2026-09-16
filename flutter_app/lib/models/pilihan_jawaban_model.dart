class PilihanJawabanModel {
  final int? idPilihan;
  final int? idSoal;
  final String labelPilihan;
  final String isiPilihan;
  final bool isBenar;
  final String penjelasan;

  const PilihanJawabanModel({
    this.idPilihan,
    this.idSoal,
    required this.labelPilihan,
    required this.isiPilihan,
    required this.isBenar,
    required this.penjelasan,
  });

  factory PilihanJawabanModel.fromJson(Map<String, dynamic> json) {
    return PilihanJawabanModel(
      idPilihan: json['id_pilihan'] as int?,
      idSoal: json['id_soal'] as int?,
      labelPilihan: json['label_pilihan'] as String,
      isiPilihan: json['isi_pilihan'] as String,
      isBenar: json['is_benar'] == true || json['is_benar'] == 1,
      penjelasan: (json['penjelasan'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        if (idPilihan != null) 'id_pilihan': idPilihan,
        'label_pilihan': labelPilihan,
        'isi_pilihan': isiPilihan,
        'is_benar': isBenar,
        'penjelasan': penjelasan,
      };

  PilihanJawabanModel copyWith({
    String? isiPilihan,
    bool? isBenar,
    String? penjelasan,
  }) {
    return PilihanJawabanModel(
      idPilihan: idPilihan,
      idSoal: idSoal,
      labelPilihan: labelPilihan,
      isiPilihan: isiPilihan ?? this.isiPilihan,
      isBenar: isBenar ?? this.isBenar,
      penjelasan: penjelasan ?? this.penjelasan,
    );
  }
}
