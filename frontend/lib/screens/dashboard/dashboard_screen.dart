import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard MyPSKD'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan tombol 'Back'
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logika Logout sementara: Kembali ke layar Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Selamat Datang di Halaman Utama! 🚀\n(Fitur Absensi & Tugas akan ada di sini)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}