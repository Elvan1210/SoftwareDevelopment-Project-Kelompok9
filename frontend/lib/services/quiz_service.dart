import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/quiz_model.dart';

class QuizService {
  static Future<Map<String, dynamic>> createQuiz({
    required String token,
    required Map<String, dynamic> quizData,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(quizData),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': jsonDecode(res.body)['message'] ?? 'Gagal membuat kuis'};
    } catch (e) {
      debugPrint('createQuiz error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<List<Quiz>> getQuizzesByKelas({
    required String token,
    required String kelasId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz?kelasId=$kelasId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] ?? body) as List<dynamic>;
        return list.map((q) => Quiz.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getQuizzesByKelas error: $e');
      return [];
    }
  }

  static Future<List<Quiz>> getQuizzesByGuru({
    required String token,
    required String guruId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz?createdBy=$guruId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] ?? body) as List<dynamic>;
        return list.map((q) => Quiz.fromJson(q)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getQuizzesByGuru error: $e');
      return [];
    }
  }

  static Future<Quiz?> getQuizDetail({
    required String token,
    required String quizId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz/$quizId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return Quiz.fromJson(body['data'] ?? body);
      }
      return null;
    } catch (e) {
      debugPrint('getQuizDetail error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateQuiz({
    required String token,
    required String quizId,
    required Map<String, dynamic> quizData,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/quiz/$quizId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(quizData),
      );

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': jsonDecode(res.body)['message'] ?? 'Gagal update kuis'};
    } catch (e) {
      debugPrint('updateQuiz error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<bool> deleteQuiz({
    required String token,
    required String quizId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/quiz/$quizId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('deleteQuiz error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitAnswers({
    required String token,
    required String quizId,
    required Map<String, dynamic> answers,
    required int violations,
    required bool autoSubmitted,
    required List<Map<String, dynamic>> violationLog,
    String kelasId = '',
    Map<String, String> essayAnswers = const {},
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz/$quizId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'answers': answers,
          'violations': violations,
          'autoSubmitted': autoSubmitted,
          'violationLog': violationLog,
          'kelasId': kelasId,
          'essayAnswers': essayAnswers,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': jsonDecode(res.body)['message'] ?? 'Gagal submit jawaban'};
    } catch (e) {
      debugPrint('submitAnswers error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<List<QuizSubmission>> getSubmissions({
    required String token,
    required String quizId,
    String? kelasId,
  }) async {
    try {
      String url = '$baseUrl/api/quiz/$quizId/submissions';
      if (kelasId != null && kelasId.isNotEmpty) {
        url += '?kelasId=$kelasId';
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] ?? body) as List<dynamic>;
        return list.map((s) => QuizSubmission.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('getSubmissions error: $e');
      return [];
    }
  }

  static Future<bool> hasSubmitted({
    required String token,
    required String quizId,
    required String studentId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz/$quizId/check?studentId=$studentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['hasSubmitted'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('hasSubmitted error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> shareQuiz({
    required String token,
    required String quizId,
    required List<String> kelasIds,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz/$quizId/share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'kelasIds': kelasIds}),
      );

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': 'Gagal share kuis'};
    } catch (e) {
      debugPrint('shareQuiz error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  static Future<Quiz?> joinByCode({
    required String token,
    required String shareCode,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz/join/$shareCode'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return Quiz.fromJson(body['data'] ?? body);
      }
      return null;
    } catch (e) {
      debugPrint('joinByCode error: $e');
      return null;
    }
  }

  static Future<String?> getExportUrl({
    required String token,
    required String quizId,
    String? kelasId,
  }) async {
    String url = '$baseUrl/api/quiz/$quizId/export';
    if (kelasId != null && kelasId.isNotEmpty) {
      url += '?kelasId=$kelasId';
    }
    return url;
  }

  static Future<Map<String, dynamic>> activateScheduled({
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz/activate-scheduled'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false};
    } catch (e) {
      debugPrint('activateScheduled error: $e');
      return {'success': false};
    }
  }
}
