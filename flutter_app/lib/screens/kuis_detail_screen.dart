import 'package:flutter/material.dart';
import '../main.dart' show AppColors;
import '../models/kuis_model.dart';
import '../models/soal_model.dart';
import '../services/kuis_service.dart';
import '../services/soal_service.dart';
import '../services/api_client.dart';
import 'soal_form_screen.dart';

class KuisDetailScreen extends StatefulWidget {
  final KuisModel kuis;
  const KuisDetailScreen({super.key, required this.kuis});

  @override
  State<KuisDetailScreen> createState() => _KuisDetailScreenState();
}

class _KuisDetailScreenState extends State<KuisDetailScreen> {
  late KuisModel _kuis;
  List<SoalModel> _soalList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kuis = widget.kuis;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await KuisService.getDetail(_kuis.idKuis);
      if (mounted) {
        setState(() {
          _kuis     = detail;
          _soalList = detail.soal;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat soal.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus = _kuis.isDraft ? 'published' : 'draft';
    try {
      final updated = await KuisService.update(_kuis.idKuis, status: newStatus);
      if (mounted) {
        setState(() => _kuis = updated);
        _snack(newStatus == 'published'
            ? 'Kuis dipublikasikan.'
            : 'Kuis dikembalikan ke draft.');
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _deleteSoal(SoalModel soal) async {
    final ok = await _confirm(
      title: 'Hapus Soal',
      content: 'Soal ini beserta semua pilihan jawabannya akan dihapus permanen.',
    );
    if (ok != true) return;
    try {
      await SoalService.delete(_kuis.idKuis, soal.idSoal!);
      _load();
      if (mounted) _snack('Soal berhasil dihapus.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _openSoalForm({SoalModel? soal}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SoalFormScreen(kuisId: _kuis.idKuis, soal: soal),
      ),
    );
    if (saved == true) _load();
  }

  Future<bool?> _confirm({required String title, required String content}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          content: Text(content,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB00020)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _kuis.judulKuis,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Tombol publish / draft
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _toggleStatus,
              icon: Icon(
                _kuis.isDraft
                    ? Icons.publish_rounded
                    : Icons.unpublished_outlined,
                size: 16,
                color: _kuis.isDraft
                    ? const Color(0xFF81C784)
                    : const Color(0xFFFFCC02),
              ),
              label: Text(
                _kuis.isDraft ? 'Publish' : 'Draft',
                style: TextStyle(
                  color: _kuis.isDraft
                      ? const Color(0xFF81C784)
                      : const Color(0xFFFFCC02),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info header kuis ─────────────────────────────────────────────
          _KuisHeader(kuis: _kuis),

          // ── Daftar soal ──────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),

      // ── FAB tambah soal ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSoalForm(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Soal',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textHint, size: 44),
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_soalList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.help_outline,
                  size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada soal',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tekan tombol "+ Tambah Soal" untuk mulai.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _soalList.length,
        itemBuilder: (_, i) => _SoalCard(
          soal: _soalList[i],
          nomor: i + 1,
          onEdit: () => _openSoalForm(soal: _soalList[i]),
          onDelete: () => _deleteSoal(_soalList[i]),
        ),
      ),
    );
  }
}

// ─── Header info kuis ─────────────────────────────────────────────────────────

class _KuisHeader extends StatelessWidget {
  final KuisModel kuis;
  const _KuisHeader({required this.kuis});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kuis.deskripsi != null && kuis.deskripsi!.isNotEmpty) ...[
            Text(
              kuis.deskripsi!,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (kuis.materi != null)
                _HeaderChip(
                    icon: Icons.book_outlined,
                    label: kuis.materi!.judulMateri),
              _HeaderChip(
                  icon: Icons.help_outline,
                  label: '${kuis.jumlahSoal} Soal'),
              _HeaderChip(
                  icon: Icons.check_circle_outline,
                  label: 'KKM ${kuis.batasLulus}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Soal Card — selalu tampil semua pilihan jawaban ─────────────────────────

class _SoalCard extends StatelessWidget {
  final SoalModel soal;
  final int nomor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SoalCard({
    required this.soal,
    required this.nomor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final correctIdx = soal.correctAnswerIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header soal ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor soal
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(top: 1, right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$nomor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Pertanyaan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        soal.pertanyaan,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${soal.poin} poin',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol EDIT & HAPUS
                Column(
                  children: [
                    _ActionBtn(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: AppColors.secondary,
                      onTap: onEdit,
                    ),
                    const SizedBox(height: 6),
                    _ActionBtn(
                      label: 'Hapus',
                      icon: Icons.delete_outline,
                      color: const Color(0xFFB00020),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ── Pilihan jawaban ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: soal.pilihanJawaban.asMap().entries.map((e) {
                final idx = e.key;
                final p   = e.value;
                final isCorrect = idx == correctIdx;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFE8F5E9)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF81C784)
                          : AppColors.cardBorder,
                      width: isCorrect ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label A/B/C/D
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.accent
                                      .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.labelPilihan,
                              style: TextStyle(
                                color: isCorrect
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.isiPilihan,
                              style: TextStyle(
                                color: isCorrect
                                    ? const Color(0xFF1B5E20)
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF2E7D32), size: 18),
                        ],
                      ),
                      // Penjelasan
                      if (p.penjelasan.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  size: 13,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.penjelasan,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tombol aksi kecil ────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
