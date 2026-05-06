import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/quiz_model.dart';

/// Service untuk CRUD kuis dan submit jawaban via API backend.

class QuizService {
  // ── Create Quiz (Guru) ──────────────────────────────────────────────
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
      debugPrint('❌ [QuizService] createQuiz error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── Get Quizzes by Kelas ────────────────────────────────────────────
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
      debugPrint('❌ [QuizService] getQuizzesByKelas error: $e');
      return [];
    }
  }

  // ── Get All Quizzes for Guru ────────────────────────────────────────
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
      debugPrint('❌ [QuizService] getQuizzesByGuru error: $e');
      return [];
    }
  }

  // ── Get Quiz Detail ─────────────────────────────────────────────────
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
      debugPrint('❌ [QuizService] getQuizDetail error: $e');
      return null;
    }
  }

  // ── Update Quiz (Guru) ──────────────────────────────────────────────
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
      debugPrint('❌ [QuizService] updateQuiz error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── Delete Quiz (Guru) ──────────────────────────────────────────────
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
      debugPrint('❌ [QuizService] deleteQuiz error: $e');
      return false;
    }
  }

  // ── Submit Answers (Siswa) ──────────────────────────────────────────
  static Future<Map<String, dynamic>> submitAnswers({
    required String token,
    required String quizId,
    required Map<String, int> answers,
    required int violations,
    required bool autoSubmitted,
    required List<Map<String, dynamic>> violationLog,
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
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'message': jsonDecode(res.body)['message'] ?? 'Gagal submit jawaban'};
    } catch (e) {
      debugPrint('❌ [QuizService] submitAnswers error: $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ── Get Submissions for a Quiz ──────────────────────────────────────
  static Future<List<QuizSubmission>> getSubmissions({
    required String token,
    required String quizId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/quiz/$quizId/submissions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] ?? body) as List<dynamic>;
        return list.map((s) => QuizSubmission.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [QuizService] getSubmissions error: $e');
      return [];
    }
  }

  // ── Check if student already submitted ──────────────────────────────
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
      debugPrint('❌ [QuizService] hasSubmitted error: $e');
      return false;
    }
  }
}
