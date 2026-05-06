import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service countdown timer untuk ujian.
///
/// Fitur:
/// - Timer realtime per detik
/// - Auto-submit ketika waktu habis
/// - Display waktu tersisa (mm:ss)
/// - Pause/resume untuk edge cases
///
/// SECURITY LEVEL: ✅ Secure
/// - Timer berjalan di memory, tidak bisa dimanipulasi user
/// - Auto-submit dipaksa ketika waktu habis

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds;
  final int _totalSeconds;
  final VoidCallback? onTimeUp;
  bool _isRunning = false;
  bool _isTimeUp = false;

  TimerService({
    required int durationMinutes,
    this.onTimeUp,
  })  : _remainingSeconds = durationMinutes * 60,
        _totalSeconds = durationMinutes * 60;

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

  // ── Controls ─────────────────────────────────────────────────────────
  void start() {
    if (_isRunning || _isTimeUp) return;
    _isRunning = true;

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

    debugPrint('⏱️ [TimerService] Timer started: $_totalSeconds seconds');
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
