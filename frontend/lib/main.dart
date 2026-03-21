import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/siswa/siswa_main_layout.dart';
import 'screens/dashboard/guru/guru_main_layout.dart';
import 'screens/dashboard/admin/admin_main_layout.dart';
import 'services/auth_service.dart';
import 'config/theme.dart';

void main() {
  runApp(const MyPSKDApp());
}

class MyPSKDApp extends StatelessWidget {
  const MyPSKDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyPSKD',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Supports automatic dark/light toggling
      home: const SplashScreen(),
    );
  }
}

/// Layar splash yang mengecek apakah user sudah login sebelumnya
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await AuthService.getToken();
    final userData = await AuthService.getUserData();

    if (!mounted) return;

    if (token != null && userData != null) {
      final role = userData['role'] ?? '';
      if (role == 'Admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AdminMainLayout(token: token)));
      } else if (role == 'Guru') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => GuruMainLayout(userData: userData, token: token)));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => SiswaMainLayout(userData: userData, token: token)));
      }
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(40),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withAlpha(60), blurRadius: 40)],
              ),
              child: const Icon(Icons.school_rounded, size: 80, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 32),
            const Text('MyPSKD', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 8),
            Text('Academic Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(150), letterSpacing: 2)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}