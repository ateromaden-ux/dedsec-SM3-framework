import 'package:flutter/material.dart';
import '../main.dart' show AppColors;
import '../models/materi_model.dart';
import '../services/kuis_service.dart';
import '../services/api_client.dart';

/// Form buat kuis baru.
/// Guru mengisi: info kuis + langsung soal pertama lengkap (A/B/C/D + penjelasan + jawaban benar).
/// Setelah simpan, soal tambahan bisa ditambah dari halaman detail kuis.
class KuisFormScreen extends StatefulWidget {
  const KuisFormScreen({super.key});

  @override
  State<KuisFormScreen> createState() => _KuisFormScreenState();
}

class _KuisFormScreenState extends State<KuisFormScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _judulCtrl     = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _batasCtrl     = TextEditingController(text: '70');

  // Soal pertama
  final _pertanyaanCtrl                       = TextEditingController();
  final List<TextEditingController> _isiCtrl  = List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _penCtrl  = List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  String _status = 'draft';
  MateriModel? _selectedMateri;
  List<MateriModel> _materiList = [];
  bool _loadingMateri = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _batasCtrl.dispose();
    _pertanyaanCtrl.dispose();
    for (final c in _isiCtrl) c.dispose();
    for (final c in _penCtrl) c.dispose();
    super.dispose();
  }

  Future<void> _loadMateri() async {
    setState(() { _loadingMateri = true; _error = null; });
    try {
      final list = await KuisService.getMateri();
      if (mounted) setState(() { _materiList = list; _loadingMateri = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = 'Gagal memuat materi: ${e.message}'; _loadingMateri = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Gagal memuat materi: $e'; _loadingMateri = false; });
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMateri == null) {
      setState(() => _error = 'Pilih materi terlebih dahulu.');
      return;
    }
    for (int i = 0; i < 4; i++) {
      if (_isiCtrl[i].text.trim().isEmpty) {
        setState(() => _error = 'Pilihan ${String.fromCharCode(65 + i)} tidak boleh kosong.');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await KuisService.create(
        judulKuis : _judulCtrl.text.trim(),
        deskripsi : _deskripsiCtrl.text.trim().isEmpty ? null : _deskripsiCtrl.text.trim(),
        idMateri  : _selectedMateri!.idMateri,
        batasLulus: int.parse(_batasCtrl.text.trim()),
        status    : _status,
        questions : [
          {
            'pertanyaan'    : _pertanyaanCtrl.text.trim().isEmpty
                ? 'Soal pertama'
                : _pertanyaanCtrl.text.trim(),
            'poin'          : 10,
            'correct_answer': _correctIndex,
            'options'       : List.generate(4, (i) => {
              'isi_pilihan': _isiCtrl[i].text.trim().isEmpty
                  ? 'Pilihan ${String.fromCharCode(65 + i)}'
                  : _isiCtrl[i].text.trim(),
              'penjelasan' : _penCtrl[i].text.trim(),
            }),
          },
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Buat Kuis Baru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // Error banner
            if (_error != null) ...[
              _ErrorBox(message: _error!),
              const SizedBox(height: 16),
            ],

            // ── INFORMASI KUIS ─────────────────────────────────────────
            _SectionCard(
              title: 'Informasi Kuis',
              icon: Icons.quiz_outlined,
              children: [
                _Label('Judul Kuis'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _judulCtrl,
                  decoration: const InputDecoration(hintText: 'contoh: Kuis HTML Dasar'),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 14),
                _Label('Deskripsi (opsional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _deskripsiCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Deskripsi singkat kuis...'),
                ),
                const SizedBox(height: 14),
                _Label('Materi'),
                const SizedBox(height: 6),
                if (_loadingMateri)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                  )
                else if (_materiList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCC02)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_outlined, color: Color(0xFFF57F17), size: 16),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Tidak ada materi. Jalankan seeder dulu.',
                          style: TextStyle(color: Color(0xFFF57F17), fontSize: 13))),
                      TextButton(
                        onPressed: _loadMateri,
                        child: const Text('Refresh'),
                      ),
                    ]),
                  )
                else
                  DropdownButtonFormField<MateriModel>(
                    // ignore: deprecated_member_use
                    value: _selectedMateri,
                    decoration: const InputDecoration(hintText: 'Pilih materi'),
                    items: _materiList.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.judulMateri, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (m) => setState(() => _selectedMateri = m),
                    validator: (v) => v == null ? 'Pilih materi' : null,
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('KKM (%)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _batasCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '70'),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            return (n == null || n < 0 || n > 100) ? '0–100' : null;
                          },
                        ),
                      ],
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Status'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _status,
                          items: const [
                            DropdownMenuItem(value: 'draft', child: Text('Draft')),
                            DropdownMenuItem(value: 'published', child: Text('Published')),
                          ],
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),

            // ── SOAL PERTAMA ──────────────────────────────────────────
            _SectionCard(
              title: 'Soal Pertama',
              icon: Icons.help_outline,
              subtitle: 'Isi soal pertama sekarang. Soal lain bisa ditambah dari halaman kuis.',
              children: [
                _Label('Pertanyaan'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pertanyaanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Masukkan pertanyaan...'),
                ),
                const SizedBox(height: 18),
                _Label('Pilihan Jawaban'),
                const SizedBox(height: 4),
                const Text('Pilih satu jawaban yang benar.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                const SizedBox(height: 12),

                // 4 pilihan jawaban inline (Wayground style)
                ...List.generate(4, (i) => _InlineAnswerCard(
                  label      : String.fromCharCode(65 + i),
                  index      : i,
                  isCorrect  : i == _correctIndex,
                  isiCtrl    : _isiCtrl[i],
                  penCtrl    : _penCtrl[i],
                  onCorrect  : () => setState(() => _correctIndex = i),
                )),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol simpan
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Buat Kuis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Inline answer card (Wayground style) ─────────────────────────────────────
// Kompak: satu baris = label + isi + radio "benar" + penjelasan collapsible

class _InlineAnswerCard extends StatefulWidget {
  final String label;
  final int    index;
  final bool   isCorrect;
  final TextEditingController isiCtrl;
  final TextEditingController penCtrl;
  final VoidCallback onCorrect;

  const _InlineAnswerCard({
    required this.label,
    required this.index,
    required this.isCorrect,
    required this.isiCtrl,
    required this.penCtrl,
    required this.onCorrect,
  });

  @override
  State<_InlineAnswerCard> createState() => _InlineAnswerCardState();
}

class _InlineAnswerCardState extends State<_InlineAnswerCard> {
  bool _showPen = false;

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFF66BB6A) : AppColors.cardBorder,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Baris utama
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lingkaran label A/B/C/D
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF2E7D32) : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.label,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 12),

                // Field isi jawaban
                Expanded(
                  child: TextField(
                    controller: widget.isiCtrl,
                    style: TextStyle(
                      color: isCorrect ? const Color(0xFF1B5E20) : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jawaban ${widget.label}...',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),

                const SizedBox(width: 8),

                // Tombol penjelasan
                GestureDetector(
                  onTap: () => setState(() => _showPen = !_showPen),
                  child: Tooltip(
                    message: 'Penjelasan',
                    child: Icon(
                      _showPen ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 18,
                      color: _showPen ? const Color(0xFFF9A825) : AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Radio jawaban benar
                GestureDetector(
                  onTap: widget.onCorrect,
                  child: Tooltip(
                    message: isCorrect ? 'Jawaban benar' : 'Jadikan jawaban benar',
                    child: Icon(
                      isCorrect ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isCorrect ? const Color(0xFF2E7D32) : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Penjelasan (collapsible)
          if (_showPen) ...[
            Divider(height: 1, color: isCorrect ? const Color(0xFFA5D6A7) : AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: widget.penCtrl,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Penjelasan jawaban ${widget.label} (opsional)...',
                        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          )),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFB00020), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
