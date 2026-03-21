import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';

class GuruProfilView extends StatelessWidget {
  final Map<String, dynamic> userData;
  const GuruProfilView({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.purple.shade700;
    final String nama = userData['nama'] ?? '-';
    final String email = userData['email'] ?? '-';
    final String mapel = userData['kelas'] ?? '-';
    final String role = userData['role'] ?? 'Guru';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'GR';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade800, Colors.purple.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nama,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informasi Akun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 12),
                _infoCard(Icons.person_outline, 'Nama Lengkap', nama, primaryColor),
                _infoCard(Icons.email_outlined, 'Email', email, primaryColor),
                _infoCard(Icons.school_outlined, 'Mata Pelajaran / Kelas', mapel, primaryColor),
                _infoCard(Icons.badge_outlined, 'Role', role, primaryColor),

                const SizedBox(height: 32),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Keluar', style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }
}
