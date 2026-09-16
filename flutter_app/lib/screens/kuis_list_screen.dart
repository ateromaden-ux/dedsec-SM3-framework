import 'package:flutter/material.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin keluar?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _deleteKuis(KuisModel k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Kuis', style: TextStyle(color: Colors.white)),
        content: Text(
          'Hapus "${k.judulKuis}"? Semua soal di dalamnya juga akan terhapus.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await KuisService.delete(k.idKuis);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kuis berhasil dihapus.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _openCreateKuis() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const KuisFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Daftar Kuis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateKuis,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Kuis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
    if (_kuis.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Belum ada kuis.',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tekan tombol + untuk membuat kuis baru.',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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

// ─── Card widget ─────────────────────────────────────────────────────────────

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
    final isPublished = kuis.isPublished;

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kuis.judulKuis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(isPublished: isPublished),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    tooltip: 'Hapus kuis',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (kuis.materi != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      kuis.materi!.judulMateri,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.help_outline,
                    label: '${kuis.jumlahSoal} soal',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.check_circle_outline,
                    label: 'KKM ${kuis.batasLulus}%',
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

class _StatusChip extends StatelessWidget {
  final bool isPublished;
  const _StatusChip({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished
            ? Colors.green.shade800.withValues(alpha: 0.4)
            : Colors.orange.shade800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPublished ? Colors.green.shade600 : Colors.orange.shade600,
        ),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          color: isPublished ? Colors.greenAccent : Colors.orangeAccent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
