import 'package:flutter/material.dart';
import '../main.dart' show AppColors;
import '../models/soal_model.dart';
import '../services/soal_service.dart';
import '../services/api_client.dart';

/// Form create / edit soal.
/// Design: Wayground-inspired — setiap pilihan jawaban adalah baris kompak
/// dengan label lingkaran, field isi, ikon penjelasan, dan radio jawaban benar.
class SoalFormScreen extends StatefulWidget {
  final int kuisId;
  final SoalModel? soal;
  const SoalFormScreen({super.key, required this.kuisId, this.soal});

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _pertanyaanCtrl = TextEditingController();
  final _poinCtrl       = TextEditingController(text: '10');

  final List<TextEditingController> _isiCtrl = [];
  final List<TextEditingController> _penCtrl = [];
  int _correctIndex = 0;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.soal != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.soal!;
      _pertanyaanCtrl.text = s.pertanyaan;
      _poinCtrl.text       = s.poin.toString();
      _correctIndex = s.correctAnswerIndex.clamp(0, s.pilihanJawaban.length - 1);
      for (int i = 0; i < 4; i++) {
        if (i < s.pilihanJawaban.length) {
          _isiCtrl.add(TextEditingController(text: s.pilihanJawaban[i].isiPilihan));
          _penCtrl.add(TextEditingController(text: s.pilihanJawaban[i].penjelasan));
        } else {
          _isiCtrl.add(TextEditingController());
          _penCtrl.add(TextEditingController());
        }
      }
    } else {
      for (int i = 0; i < 4; i++) {
        _isiCtrl.add(TextEditingController());
        _penCtrl.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _poinCtrl.dispose();
    for (final c in _isiCtrl) c.dispose();
    for (final c in _penCtrl) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < 4; i++) {
      if (_isiCtrl[i].text.trim().isEmpty) {
        setState(() => _error =
            'Pilihan ${String.fromCharCode(65 + i)} tidak boleh kosong.');
        return;
      }
    }

    setState(() => _saving = true);

    final options = List.generate(4, (i) => {
          'isi_pilihan': _isiCtrl[i].text.trim(),
          'penjelasan' : _penCtrl[i].text.trim(),
        });

    try {
      if (_isEdit) {
        await SoalService.update(
          kuisId       : widget.kuisId,
          soalId       : widget.soal!.idSoal!,
          pertanyaan   : _pertanyaanCtrl.text.trim(),
          poin         : int.parse(_poinCtrl.text.trim()),
          correctAnswer: _correctIndex,
          options      : options,
        );
      } else {
        await SoalService.create(
          kuisId       : widget.kuisId,
          pertanyaan   : _pertanyaanCtrl.text.trim(),
          poin         : int.parse(_poinCtrl.text.trim()),
          correctAnswer: _correctIndex,
          options      : options,
        );
      }
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
        title: Text(
          _isEdit ? 'Edit Soal' : 'Buat Soal',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _submit,
              child: const Text('Simpan',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // Error
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],

            // ── PERTANYAAN ──────────────────────────────────────────────
            _SectionCard(
              title   : 'Pertanyaan',
              icon    : Icons.help_outline,
              children: [
                TextFormField(
                  controller: _pertanyaanCtrl,
                  maxLines  : 4,
                  style     : const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan pertanyaan di sini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.all(14),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Pertanyaan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Poin:',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _poinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '10',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return (n == null || n < 1) ? 'Min 1' : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── PILIHAN JAWABAN ─────────────────────────────────────────
            _SectionCard(
              title   : 'Pilihan Jawaban',
              icon    : Icons.format_list_bulleted,
              subtitle: 'Tekan ○ untuk memilih jawaban yang benar. Tekan 💡 untuk isi penjelasan.',
              children: List.generate(4, (i) => _WayAnswerCard(
                label     : String.fromCharCode(65 + i),
                index     : i,
                isCorrect : i == _correctIndex,
                isiCtrl   : _isiCtrl[i],
                penCtrl   : _penCtrl[i],
                onCorrect : () => setState(() => _correctIndex = i),
              )),
            ),

            // Indicator jawaban terpilih
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Jawaban benar: Pilihan ${String.fromCharCode(65 + _correctIndex)}',
                    style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Tombol simpan
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _isEdit ? 'Update Soal' : 'Simpan Soal',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Wayground-style Answer Card ─────────────────────────────────────────────
/// Baris kompak dengan label, field isi, ikon penjelasan collapsible, radio benar.

class _WayAnswerCard extends StatefulWidget {
  final String label;
  final int    index;
  final bool   isCorrect;
  final TextEditingController isiCtrl;
  final TextEditingController penCtrl;
  final VoidCallback onCorrect;

  const _WayAnswerCard({
    required this.label,
    required this.index,
    required this.isCorrect,
    required this.isiCtrl,
    required this.penCtrl,
    required this.onCorrect,
  });

  @override
  State<_WayAnswerCard> createState() => _WayAnswerCardState();
}

class _WayAnswerCardState extends State<_WayAnswerCard> {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris utama ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Label lingkaran
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF2E7D32) : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(width: 12),

                // Field isi jawaban
                Expanded(
                  child: TextField(
                    controller: widget.isiCtrl,
                    style: TextStyle(
                      color: isCorrect
                          ? const Color(0xFF1B5E20)
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jawaban ${widget.label}...',
                      hintStyle: const TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 10),

                // Ikon penjelasan (toggle)
                GestureDetector(
                  onTap: () => setState(() => _showPen = !_showPen),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _showPen ? Icons.lightbulb : Icons.lightbulb_outline,
                      key: ValueKey(_showPen),
                      size: 20,
                      color: _showPen
                          ? const Color(0xFFF9A825)
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Radio jawaban benar
                GestureDetector(
                  onTap: widget.onCorrect,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isCorrect
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      key: ValueKey(isCorrect),
                      size: 24,
                      color: isCorrect
                          ? const Color(0xFF2E7D32)
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Penjelasan (collapsible) ───────────────────────────────────
          if (_showPen) ...[
            Divider(
              height: 1,
              color: isCorrect
                  ? const Color(0xFFA5D6A7)
                  : AppColors.divider,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: widget.penCtrl,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText:
                            'Penjelasan jawaban ${widget.label} (opsional)...',
                        hintStyle: const TextStyle(
                            color: AppColors.textHint, fontSize: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
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
  final String  title;
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

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
                style: const TextStyle(
                    color: Color(0xFFB00020), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
