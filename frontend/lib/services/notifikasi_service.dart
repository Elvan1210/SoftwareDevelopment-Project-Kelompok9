import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotifikasiService {
  /// Mengirim notifikasi ke API. 
  /// Anda bisa spesifikkan `targetKelas`, `targetRole`, atau `targetUserId` 
  /// untuk memfilter siapa saja yang akan melihat notifikasi ini.
  static Future<void> kirimNotifikasi({
    required String judul,
    required String pesan,
    required String token,
    String? targetKelas,
    String? targetRole,
    String? targetUserId,
  }) async {
    final body = {
      'judul': judul,
      'pesan': pesan,
      'target_kelas': targetKelas,
      'target_role': targetRole,
      'target_user_id': targetUserId,
      'waktu': DateTime.now().toIso8601String(),
      'dibaca_oleh': [], // Array ID user yang sudah membaca
    };

    try {
      await http.post(
        Uri.parse('$baseUrl/api/notifikasi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      // Kita abaikan error notifikasi agar tidak merusak flow utama (silent fail)
    }
  }
}
