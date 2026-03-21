import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/siswa/siswa_main_layout.dart';
import 'screens/dashboard/guru/guru_main_layout.dart';
import 'screens/dashboard/admin/admin_main_layout.dart';
import 'services/auth_service.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 72, color: Colors.blue),
            SizedBox(height: 16),
            Text('MyPSKD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}