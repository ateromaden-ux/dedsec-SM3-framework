import 'package:flutter/material.dart';
import '../models/soal_model.dart';
import '../services/soal_service.dart';
import '../services/api_client.dart';

/// Digunakan untuk create (soal == null) maupun edit (soal != null).
class SoalFormScreen extends StatefulWidget {
  final int kuisId;
  final SoalModel? soal;

  const SoalFormScreen({super.key, required this.kuisId, this.soal});

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pertanyaanCtrl = TextEditingController();
  final _poinCtrl = TextEditingController(text: '10');

  // Pilihan jawaban: minimal 2, maksimal 6
  final List<_OptionEntry> _options = [];
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
      _poinCtrl.text = s.poin.toString();
      _correctIndex = s.correctAnswerIndex.clamp(0, s.pilihanJawaban.length - 1);
      for (final p in s.pilihanJawaban) {
        _options.add(_OptionEntry(
          isiCtrl: TextEditingController(text: p.isiPilihan),
          penjelasanCtrl: TextEditingController(text: p.penjelasan),
        ));
      }
    } else {
      // Default 4 pilihan kosong
      for (int i = 0; i < 4; i++) {
        _options.add(_OptionEntry(
          isiCtrl: TextEditingController(),
          penjelasanCtrl: TextEditingController(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _poinCtrl.dispose();
    for (final o in _options) {
      o.isiCtrl.dispose();
      o.penjelasanCtrl.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 6) return;
    setState(() {
      _options.add(_OptionEntry(
        isiCtrl: TextEditingController(),
        penjelasanCtrl: TextEditingController(),
      ));
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options[index].isiCtrl.dispose();
      _options[index].penjelasanCtrl.dispose();
      _options.removeAt(index);
      if (_correctIndex >= _options.length) {
        _correctIndex = _options.length - 1;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi minimal semua pilihan terisi
    for (int i = 0; i < _options.length; i++) {
      if (_options[i].isiCtrl.text.trim().isEmpty) {
        setState(
            () => _error = 'Pilihan ${String.fromCharCode(65 + i)} tidak boleh kosong.');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final options = _options
        .map((o) => {
              'isi_pilihan': o.isiCtrl.text.trim(),
              'penjelasan': o.penjelasanCtrl.text.trim(),
            })
        .toList();

    try {
      if (_isEdit) {
        await SoalService.update(
          kuisId: widget.kuisId,
          soalId: widget.soal!.idSoal!,
          pertanyaan: _pertanyaanCtrl.text.trim(),
          poin: int.parse(_poinCtrl.text),
          correctAnswer: _correctIndex,
          options: options,
        );
      } else {
        await SoalService.create(
          kuisId: widget.kuisId,
          pertanyaan: _pertanyaanCtrl.text.trim(),
          poin: int.parse(_poinCtrl.text),
          correctAnswer: _correctIndex,
          options: options,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan soal.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? 'Edit Soal' : 'Tambah Soal',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _submit,
              child: const Text('Simpan',
                  style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6366F1)),
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
            // Error banner
            if (_error != null) ...[
              _ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],

            // ── Pertanyaan ────────────────────────────────────────────────
            _SectionCard(
              title: 'Pertanyaan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _pertanyaanCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDeco(
                        'Tulis pertanyaan di sini...'),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Pertanyaan tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Poin:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _poinCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: _inputDeco('10'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return (n == null || n < 1)
                                ? 'Min 1'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Pilihan Jawaban ───────────────────────────────────────────
            _SectionCard(
              title: 'Pilihan Jawaban',
              headerTrailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_options.length}/6',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  if (_options.length < 6)
                    GestureDetector(
                      onTap: _addOption,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 14, color: Color(0xFF6366F1)),
                            SizedBox(width: 3),
                            Text('Tambah',
                                style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              child: Column(
                children: _options.asMap().entries.map((e) {
                  final i = e.key;
                  final o = e.value;
                  final label = String.fromCharCode(65 + i);
                  final isCorrect = i == _correctIndex;

                  return _OptionTile(
                    key: ValueKey(i),
                    label: label,
                    isCorrect: isCorrect,
                    isiCtrl: o.isiCtrl,
                    penjelasanCtrl: o.penjelasanCtrl,
                    canRemove: _options.length > 2,
                    onMarkCorrect: () =>
                        setState(() => _correctIndex = i),
                    onRemove: () => _removeOption(i),
                  );
                }).toList(),
              ),
            ),

            // Keterangan jawaban benar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.green.shade700.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jawaban benar: Pilihan '
                      '${String.fromCharCode(65 + _correctIndex)}. '
                      'Tekan radio pada pilihan untuk mengubahnya.',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Tombol simpan bawah
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Tambah Soal',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorStyle:
            const TextStyle(color: Colors.redAccent, fontSize: 11),
      );
}

// ─── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatefulWidget {
  final String label;
  final bool isCorrect;
  final TextEditingController isiCtrl;
  final TextEditingController penjelasanCtrl;
  final bool canRemove;
  final VoidCallback onMarkCorrect;
  final VoidCallback onRemove;

  const _OptionTile({
    super.key,
    required this.label,
    required this.isCorrect,
    required this.isiCtrl,
    required this.penjelasanCtrl,
    required this.canRemove,
    required this.onMarkCorrect,
    required this.onRemove,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _showPenjelasan = false;

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.shade900.withValues(alpha: 0.2)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.shade700 : Colors.white12,
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Isi pilihan
          Padding(
            padding:
                const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio jawaban benar
                GestureDetector(
                  onTap: widget.onMarkCorrect,
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? Colors.green.shade700
                          : const Color(0xFF1E293B),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade400
                            : Colors.white30,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color:
                            isCorrect ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // Field isi pilihan
                Expanded(
                  child: TextFormField(
                    controller: widget.isiCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Isi pilihan ${widget.label}...',
                      hintStyle:
                          const TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    maxLines: null,
                  ),
                ),

                // Actions kanan
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showPenjelasan
                            ? Icons.comment
                            : Icons.comment_outlined,
                        size: 18,
                        color: _showPenjelasan
                            ? const Color(0xFF6366F1)
                            : Colors.white30,
                      ),
                      tooltip: 'Penjelasan',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => setState(
                          () => _showPenjelasan = !_showPenjelasan),
                    ),
                    if (widget.canRemove)
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.white30),
                        tooltip: 'Hapus pilihan',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: widget.onRemove,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Penjelasan (opsional, collapsible)
          if (_showPenjelasan) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: widget.penjelasanCtrl,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Penjelasan jawaban (opsional)...',
                        hintStyle: TextStyle(
                            color: Colors.white24, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 6),
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
  }
}

// ─── Helper classes & widgets ─────────────────────────────────────────────────

class _OptionEntry {
  final TextEditingController isiCtrl;
  final TextEditingController penjelasanCtrl;
  _OptionEntry({required this.isiCtrl, required this.penjelasanCtrl});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
