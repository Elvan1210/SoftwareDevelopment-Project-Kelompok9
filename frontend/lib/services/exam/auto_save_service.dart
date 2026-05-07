import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service auto-save jawaban ujian secara periodik.
///
/// Fitur:
/// - Simpan jawaban otomatis tiap N detik
/// - Gunakan SharedPreferences (local storage)
/// - Restore jawaban jika app crash/restart
/// - Clear setelah submit
///
/// SECURITY LEVEL: ✅ Secure
/// - Data tersimpan lokal, survive app crash
/// - Jawaban tidak hilang jika koneksi terputus

class AutoSaveService {
  Timer? _timer;
  final int intervalSeconds;
  final String _storageKey;
  Map<String, dynamic> _currentAnswers = {};
  bool _isDirty = false; // track if there are unsaved changes

  AutoSaveService({
    required String quizId,
    required String studentId,
    this.intervalSeconds = 10,
  }) : _storageKey = 'exam_autosave_${quizId}_$studentId';

  // ── Start auto-save loop ──────────────────────────────────────────────
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (_isDirty) {
        _saveToStorage();
      }
    });
    debugPrint('💾 [AutoSaveService] Started (interval: ${intervalSeconds}s)');
  }

  // ── Update answer ─────────────────────────────────────────────────────
  void updateAnswer(String questionId, dynamic selectedOption) {
    _currentAnswers[questionId] = selectedOption;
    _isDirty = true;
  }

  // ── Bulk update ───────────────────────────────────────────────────────
  void updateAllAnswers(Map<String, dynamic> answers) {
    _currentAnswers = Map.from(answers);
    _isDirty = true;
  }

  // ── Get current answers ───────────────────────────────────────────────
  Map<String, dynamic> get currentAnswers => Map.unmodifiable(_currentAnswers);

  // ── Save to local storage ─────────────────────────────────────────────
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'answers': _currentAnswers,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_storageKey, data);
      _isDirty = false;
      debugPrint('💾 [AutoSaveService] Saved ${_currentAnswers.length} answers');
    } catch (e) {
      debugPrint('❌ [AutoSaveService] Save failed: $e');
    }
  }

  // ── Force save (call before submit) ───────────────────────────────────
  Future<void> forceSave() async {
    await _saveToStorage();
  }

  // ── Restore from local storage ────────────────────────────────────────
  Future<Map<String, dynamic>> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return {};

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final answers = (data['answers'] as Map<String, dynamic>?) ?? {};
      
      _currentAnswers = Map.from(answers);
      debugPrint('🔄 [AutoSaveService] Restored ${answers.length} answers');
      return answers;
    } catch (e) {
      debugPrint('❌ [AutoSaveService] Restore failed: $e');
      return {};
    }
  }

  // ── Clear saved data (call after successful submit) ────────────────────
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _currentAnswers.clear();
      debugPrint('🧹 [AutoSaveService] Cleared saved data');
    } catch (e) {
      debugPrint('❌ [AutoSaveService] Clear failed: $e');
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────
  void dispose() {
    _timer?.cancel();
  }
}
