import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PresensiService {
  static String get _baseUrl => '$baseUrl/api/presensi';

  static Future<List<Map<String, dynamic>>> getPresensiByDate(String token, String kelasId, String date) async {
    final url = Uri.parse('$_baseUrl?kelas_id=$kelasId&tanggal=$date');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Gagal memuat data presensi');
    }
  }

  static Future<void> upsertPresensi(String token, Map<String, dynamic> data) async {
    final url = data.containsKey('id') 
        ? Uri.parse('$_baseUrl/${data['id']}') 
        : Uri.parse(_baseUrl);

    final response = await (data.containsKey('id') 
      ? http.put(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(data))
      : http.post(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(data))
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menyimpan presensi');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentsByKelas(String token, String kelasId) async {
    final url = Uri.parse('$baseUrl/api/kelas/$kelasId/members');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Gagal memuat daftar siswa');
    }
  }
}

