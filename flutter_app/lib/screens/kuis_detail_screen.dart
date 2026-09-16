import 'package:flutter/material.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await KuisService.getDetail(_kuis.idKuis);
      if (mounted) {
        setState(() {
          _kuis = detail;
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
      final updated =
          await KuisService.update(_kuis.idKuis, status: newStatus);
      if (mounted) setState(() => _kuis = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'published'
                  ? 'Kuis dipublikasikan.'
                  : 'Kuis dikembalikan ke draft.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _deleteSoal(SoalModel soal) async {
    final confirm = await _confirmDialog(
      title: 'Hapus Soal',
      content:
          'Hapus soal "${_truncate(soal.pertanyaan, 60)}"? Tindakan ini tidak bisa dibatalkan.',
    );
    if (confirm != true) return;

    try {
      await SoalService.delete(_kuis.idKuis, soal.idSoal!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Soal dihapus.')));
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _confirmDialog(
          {required String title, required String content}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content:
              Text(content, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _kuis.judulKuis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Toggle status
          TextButton.icon(
            onPressed: _toggleStatus,
            icon: Icon(
              _kuis.isDraft
                  ? Icons.publish_rounded
                  : Icons.unpublished_outlined,
              size: 18,
              color:
                  _kuis.isDraft ? Colors.greenAccent : Colors.orangeAccent,
            ),
            label: Text(
              _kuis.isDraft ? 'Publish' : 'Draft',
              style: TextStyle(
                color:
                    _kuis.isDraft ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSoalForm(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Soal',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _KuisInfoHeader(kuis: _kuis),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1)),
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
            const Icon(Icons.help_outline, size: 60, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Belum ada soal.',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Tekan tombol + untuk menambah soal.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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

class _KuisInfoHeader extends StatelessWidget {
  final KuisModel kuis;
  const _KuisInfoHeader({required this.kuis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kuis.deskripsi != null && kuis.deskripsi!.isNotEmpty) ...[
            Text(
              kuis.deskripsi!,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (kuis.materi != null)
                _Chip(
                  icon: Icons.book_outlined,
                  label: kuis.materi!.judulMateri,
                  color: const Color(0xFF6366F1),
                ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.help_outline,
                label: '${kuis.jumlahSoal} soal',
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.check_circle_outline,
                label: 'KKM ${kuis.batasLulus}%',
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Soal card ────────────────────────────────────────────────────────────────

class _SoalCard extends StatefulWidget {
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
  State<_SoalCard> createState() => _SoalCardState();
}

class _SoalCardState extends State<_SoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final soal = widget.soal;
    final correctIdx = soal.correctAnswerIndex;

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // Header soal
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Nomor
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.nomor}',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          soal.pertanyaan,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_outline,
                                size: 13, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              '${soal.poin} poin',
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.format_list_bulleted,
                                size: 13, color: Colors.white38),
                            const SizedBox(width: 3),
                            Text(
                              '${soal.pilihanJawaban.length} pilihan',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF6366F1), size: 19),
                        tooltip: 'Edit soal',
                        onPressed: widget.onEdit,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 19),
                        tooltip: 'Hapus soal',
                        onPressed: widget.onDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pilihan jawaban (expand)
          if (_expanded && soal.pilihanJawaban.isNotEmpty) ...[
            const Divider(
                height: 1, color: Color(0xFF0F172A), thickness: 1),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: soal.pilihanJawaban.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  final isCorrect = idx == correctIdx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.shade900.withValues(alpha: 0.35)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade600
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade700
                                : const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.labelPilihan,
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.isiPilihan,
                                style: TextStyle(
                                  color: isCorrect
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              if (p.penjelasan.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Penjelasan: ${p.penjelasan}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCorrect)
                          const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 18),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
