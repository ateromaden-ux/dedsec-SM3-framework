import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/kuis_list_screen.dart';
import 'screens/kuis_detail_screen.dart';
import 'models/kuis_model.dart';
import 'services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Paksa portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Status bar transparan agar terlihat bersih di dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const KuisGuruApp());
}

class KuisGuruApp extends StatelessWidget {
  const KuisGuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuis Guru',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Mulai dari splash yang cek token
      home: const _SplashGate(),
      onGenerateRoute: _generateRoute,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      useMaterial3: true,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _slide(const LoginScreen());

      case '/kuis':
        return _slide(const KuisListScreen());

      case '/kuis/detail':
        final kuis = settings.arguments as KuisModel;
        return _slide(KuisDetailScreen(kuis: kuis));

      default:
        return _slide(const _SplashGate());
    }
  }

  PageRoute<T> _slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

/// Splash sederhana: cek token lalu arahkan ke login atau home.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Beri waktu splash sebentar agar tidak langsung flash
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final loggedIn = await ApiClient.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      loggedIn ? '/kuis' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.quiz_rounded,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kuis Guru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Platform manajemen kuis interaktif',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
