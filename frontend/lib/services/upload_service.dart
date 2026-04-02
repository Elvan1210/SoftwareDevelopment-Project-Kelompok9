import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UploadService {
  static Future<String?> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/pengumpulan/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes, 
        filename: fileName,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['file_url']; // Akan mengembalikan URL valid dari Cloudinary
      }
      return null;
    } catch (e) {
      print('Error Upload: $e');
      return null;
    }
  }
}