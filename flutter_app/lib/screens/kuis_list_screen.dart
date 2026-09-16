import 'package:flutter/material.dart';
import '../main.dart' show AppColors;
import '../models/kuis_model.dart';
import '../services/auth_service.dart';
import '../services/kuis_service.dart';
import '../services/api_client.dart';
import 'kuis_form_screen.dart';

class KuisListScreen extends StatefulWidget {
  const KuisListScreen({super.key});

  @override
  State<KuisListScreen> createState() => _KuisListScreenState();
}

class _KuisListScreenState extends State<KuisListScreen> {
  List<KuisModel> _kuis = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await KuisService.getAll();
      if (mounted) setState(() => _kuis = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data kuis.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await _showConfirm(
      title: 'Keluar',
      content: 'Yakin ingin keluar dari akun?',
      confirmLabel: 'Keluar',
      danger: true,
    );
    if (ok != true) return;
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _deleteKuis(KuisModel k) async {
    final ok = await _showConfirm(
      title: 'Hapus Kuis',
      content:
          'Hapus "${k.judulKuis}"?\nSemua soal di dalamnya juga akan terhapus.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (ok != true) return;
    try {
      await KuisService.delete(k.idKuis);
      _load();
      if (mounted) _snack('Kuis berhasil dihapus.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<bool?> _showConfirm({
    required String title,
    required String content,
    required String confirmLabel,
    bool danger = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
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
                backgroundColor: danger
                    ? const Color(0xFFB00020)
                    : AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const KuisFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kuis Saya',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Kuis',
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
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_kuis.isEmpty) {
      return _EmptyState(
        icon: Icons.quiz_outlined,
        title: 'Belum ada kuis',
        subtitle: 'Tekan tombol "Buat Kuis" untuk memulai.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: _kuis.length,
        itemBuilder: (_, i) => _KuisCard(
          kuis: _kuis[i],
          onTap: () async {
            await Navigator.pushNamed(
              context,
              '/kuis/detail',
              arguments: _kuis[i],
            );
            _load();
          },
          onDelete: () => _deleteKuis(_kuis[i]),
        ),
      ),
    );
  }
}

// ─── Kuis Card ────────────────────────────────────────────────────────────────

class _KuisCard extends StatelessWidget {
  final KuisModel kuis;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _KuisCard({
    required this.kuis,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: judul + status + delete
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      kuis.judulKuis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: kuis.status),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.delete_outline,
                          color: Color(0xFFB00020), size: 20),
                    ),
                  ),
                ],
              ),

              // Materi
              if (kuis.materi != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(kuis.materi!.judulMateri,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ],

              if (kuis.deskripsi != null &&
                  kuis.deskripsi!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  kuis.deskripsi!,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),

              // Info bawah
              Row(
                children: [
                  _InfoPill(
                    icon: Icons.help_outline,
                    label: '${kuis.jumlahSoal} Soal',
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: Icons.check_circle_outline,
                    label: 'KKM ${kuis.batasLulus}%',
                  ),
                  const Spacer(),
                  Text(
                    'Lihat soal →',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets pendukung ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPublished = status == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF81C784)
              : const Color(0xFFFFCC02),
        ),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          color: isPublished
              ? const Color(0xFF2E7D32)
              : const Color(0xFFF57F17),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── State widgets ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
