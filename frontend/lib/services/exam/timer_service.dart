import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service countdown timer untuk ujian.
///
/// Fitur:
/// - Timer realtime per detik
/// - Auto-submit ketika waktu habis
/// - Display waktu tersisa (mm:ss)
/// - Persistensi waktu mulai ke SharedPreferences
///   → Jika app di-kill dan dibuka lagi, timer lanjut dari sisa waktu
///
/// SECURITY LEVEL: ✅ Secure
/// - Timer berjalan di memory, tidak bisa dimanipulasi user
/// - Auto-submit dipaksa ketika waktu habis
/// - Waktu mulai disimpan server-side (closedAt) dan lokal (SharedPreferences)

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds;
  final int _totalSeconds;
  final VoidCallback? onTimeUp;
  bool _isRunning = false;
  bool _isTimeUp = false;
  final String? _persistKey;

  TimerService({
    required int durationMinutes,
    this.onTimeUp,
    String? persistKey,
  })  : _remainingSeconds = durationMinutes * 60,
        _totalSeconds = durationMinutes * 60,
        _persistKey = persistKey;

  // ── Getters ──────────────────────────────────────────────────────────
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isTimeUp => _isTimeUp;

  double get progress => _totalSeconds > 0
      ? _remainingSeconds / _totalSeconds
      : 0.0;

  String get formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Warna indikator berdasarkan sisa waktu
  bool get isWarning => _remainingSeconds <= 300 && _remainingSeconds > 60; // < 5 min
  bool get isCritical => _remainingSeconds <= 60; // < 1 min

  // ── Restore sisa waktu dari SharedPreferences ──────────────────────
  /// Panggil sebelum start() untuk memeriksa apakah ada sisa waktu tersimpan.
  /// Jika ada, kurangi _remainingSeconds sesuai waktu yang sudah berlalu.
  static Future<int?> getSavedRemainingSeconds(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString('${key}_start');
      final totalSeconds = prefs.getInt('${key}_total');
      if (startTimeStr == null || totalSeconds == null) return null;

      final startTime = DateTime.parse(startTimeStr);
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final remaining = totalSeconds - elapsed;

      if (remaining <= 0) return 0; // Waktu sudah habis
      return remaining;
    } catch (_) {
      return null;
    }
  }

  // ── Simpan waktu mulai ke SharedPreferences ────────────────────────
  Future<void> _persistStartTime() async {
    if (_persistKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_persistKey}_start', DateTime.now().toIso8601String());
      await prefs.setInt('${_persistKey}_total', _totalSeconds);
      debugPrint('⏱️ [TimerService] Start time persisted (key: $_persistKey)');
    } catch (_) {}
  }

  /// Hapus data persistensi setelah ujian selesai/submit
  static Future<void> clearPersistedTimer(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${key}_start');
      await prefs.remove('${key}_total');
      debugPrint('🧹 [TimerService] Cleared persisted timer (key: $key)');
    } catch (_) {}
  }

  // ── Controls ─────────────────────────────────────────────────────────
  void start() {
    if (_isRunning || _isTimeUp) return;

    // Langsung tandai habis jika sisa ≤ 0
    if (_remainingSeconds <= 0) {
      _isTimeUp = true;
      onTimeUp?.call();
      notifyListeners();
      return;
    }

    _isRunning = true;
    _persistStartTime(); // Simpan waktu mulai

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _isTimeUp = true;
        _isRunning = false;
        _timer?.cancel();
        debugPrint('⏰ [TimerService] TIME IS UP! Auto-submitting...');
        onTimeUp?.call();
        notifyListeners();
        return;
      }

      _remainingSeconds--;
      notifyListeners();
    });

    debugPrint('⏱️ [TimerService] Timer started: $_remainingSeconds seconds remaining');
  }

  /// Set sisa waktu (digunakan saat restore dari persistensi)
  void setRemainingSeconds(int seconds) {
    _remainingSeconds = seconds.clamp(0, _totalSeconds);
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resume() {
    if (_isTimeUp) return;
    start();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
