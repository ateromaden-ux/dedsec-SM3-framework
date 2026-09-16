import 'package:flutter/material.dart';
import '../main.dart' show AppColors;
import '../services/auth_service.dart';
import '../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/kuis');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Gagal terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // ── Panel kiri (dekorasi) hanya muncul di layar lebar ──────────
            if (MediaQuery.of(context).size.width > 700)
              Expanded(
                child: Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: _BrandPanel(),
                  ),
                ),
              ),

            // ── Form login ─────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo kecil (mobile only)
                        if (MediaQuery.of(context).size.width <= 700) ...[
                          const _BrandPanel(dark: false),
                          const SizedBox(height: 40),
                        ],

                        const Text(
                          'Masuk ke Akun',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Masukkan email dan password guru kamu.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error
                        if (_error != null) ...[
                          _ErrorBox(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              // Email
                              const _FieldLabel('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType:
                                    TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'guru@sekolah.id',
                                  prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: AppColors.textHint,
                                      size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              const _FieldLabel('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.textHint,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textHint,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Password tidak boleh kosong'
                                    : null,
                              ),
                              const SizedBox(height: 28),

                              // Tombol masuk
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brand panel ──────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  final bool dark;
  const _BrandPanel({this.dark = true});

  @override
  Widget build(BuildContext context) {
    final iconBg = dark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.1);
    final titleColor = dark ? Colors.white : AppColors.primary;
    final subColor = dark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.quiz_rounded,
              size: 44, color: dark ? Colors.white : AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('Kuis Guru',
            style: TextStyle(
              color: titleColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 6),
        Text('Platform manajemen kuis interaktif',
            style: TextStyle(color: subColor, fontSize: 13)),
      ],
    );
  }
}

// ─── Reusable ─────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

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
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFB00020), size: 18),
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
