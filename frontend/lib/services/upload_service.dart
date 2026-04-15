import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

class UploadService {
  static Future<String?> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String token,
  }) async {
    try {
      // Endpoint ini harus bisa menerima file dari mana saja (Tugas/Materi/Profil)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/pengumpulan/upload'), 
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      var streamedResponse = await request.send().timeout(const Duration(minutes: 5)); // Tambahkan durasi
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['file_url']; // URL Cloudinary
      }
      return null;
    } catch (e) {
      debugPrint('Error Upload Service: $e');
      return null;
    }
  }
}