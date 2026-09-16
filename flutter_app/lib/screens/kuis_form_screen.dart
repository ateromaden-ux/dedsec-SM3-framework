import 'package:flutter/material.dart';
import '../models/materi_model.dart';
import '../services/kuis_service.dart';
import '../services/api_client.dart';

/// Form untuk membuat kuis baru (beserta minimal 1 soal awal).
/// Setelah kuis dibuat, guru bisa tambah soal lebih lanjut dari halaman detail.
class KuisFormScreen extends StatefulWidget {
  const KuisFormScreen({super.key});

  @override
  State<KuisFormScreen> createState() => _KuisFormScreenState();
}

class _KuisFormScreenState extends State<KuisFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Kuis fields ──────────────────────────────────────────────────────────
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _batasLulusCtrl = TextEditingController(text: '70');
  String _status = 'draft';
  MateriModel? _selectedMateri;

  // ── Materi list ──────────────────────────────────────────────────────────
  List<MateriModel> _materiList = [];
  bool _loadingMateri = true;

  // ── State ────────────────────────────────────────────────────────────────
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
    _batasLulusCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMateri() async {
    try {
      final list = await KuisService.getMateri();
      if (mounted) {
        setState(() {
          _materiList = list;
          _loadingMateri = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMateri = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMateri == null) {
      setState(() => _error = 'Pilih materi terlebih dahulu.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Kuis dibuat dengan 1 soal placeholder — guru edit soal dari detail page
      await KuisService.create(
        judulKuis: _judulCtrl.text.trim(),
        deskripsi: _deskripsiCtrl.text.trim().isEmpty
            ? null
            : _deskripsiCtrl.text.trim(),
        idMateri: _selectedMateri!.idMateri,
        batasLulus: int.parse(_batasLulusCtrl.text),
        status: _status,
        questions: [
          {
            'pertanyaan': 'Soal pertama (edit via detail kuis)',
            'poin': 10,
            'correct_answer': 0,
            'options': [
              {'isi_pilihan': 'Pilihan A', 'penjelasan': '-'},
              {'isi_pilihan': 'Pilihan B', 'penjelasan': '-'},
              {'isi_pilihan': 'Pilihan C', 'penjelasan': '-'},
              {'isi_pilihan': 'Pilihan D', 'penjelasan': '-'},
            ],
          },
        ],
      );

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan kuis.');
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
        title: const Text('Buat Kuis Baru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                _ErrorBox(message: _error!),
                const SizedBox(height: 16),
              ],

              _SectionCard(
                title: 'Informasi Kuis',
                children: [
                  _fieldLabel('Judul Kuis'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _judulCtrl,
                    hint: 'contoh: Kuis HTML Dasar',
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Judul tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Deskripsi (opsional)'),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _deskripsiCtrl,
                    hint: 'Deskripsi singkat kuis...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Materi'),
                  const SizedBox(height: 6),
                  _loadingMateri
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6366F1)))
                      : DropdownButtonFormField<MateriModel>(
                          // ignore: deprecated_member_use
                          value: _selectedMateri,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Pilih materi'),
                          items: _materiList
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.judulMateri,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (m) =>
                              setState(() => _selectedMateri = m),
                          validator: (v) =>
                              v == null ? 'Pilih materi' : null,
                        ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('KKM / Batas Lulus (%)'),
                            const SizedBox(height: 6),
                            _textField(
                              controller: _batasLulusCtrl,
                              hint: '70',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 0 || n > 100) {
                                  return '0–100';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Status'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _status,
                              dropdownColor: const Color(0xFF1E293B),
                              decoration: _inputDeco(''),
                              style:
                                  const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('Draft',
                                        style: TextStyle(
                                            color: Colors.orangeAccent))),
                                DropdownMenuItem(
                                    value: 'published',
                                    child: Text('Published',
                                        style: TextStyle(
                                            color: Colors.greenAccent))),
                              ],
                              onChanged: (v) =>
                                  setState(() => _status = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        color: Color(0xFF6366F1), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kuis akan dibuat dengan 1 soal placeholder. '
                        'Tambah & edit soal dari halaman detail kuis.',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
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
                      : const Text('Buat Kuis',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      );

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDeco(hint ?? ''),
        validator: validator,
      );

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
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      );
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

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
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Text(message,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}
