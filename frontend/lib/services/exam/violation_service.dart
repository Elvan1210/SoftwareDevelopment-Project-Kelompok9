import 'package:flutter/foundation.dart';
import '../../models/violation_model.dart';

/// Service untuk mengelola pelanggaran selama ujian berlangsung.
///
/// Fitur:
/// - Counter violation dengan threshold auto-submit
/// - Log aktivitas pelanggaran dengan timestamp
/// - Warning popup trigger
/// - Auto submit ketika violation melewati batas
///
/// SECURITY LEVEL: ✅ Secure
/// - Semua violation tercatat dengan timestamp akurat
/// - Counter tidak bisa di-reset oleh user
/// - Auto-submit memaksa pengiriman jawaban

class ViolationService extends ChangeNotifier {
  final int maxViolations;
  final List<ViolationRecord> _violations = [];
  final VoidCallback? onMaxViolationsReached;
  bool _isLocked = false;

  ViolationService({
    this.maxViolations = 5,
    this.onMaxViolationsReached,
  });

  // ── Getters ──────────────────────────────────────────────────────────
  List<ViolationRecord> get violations => List.unmodifiable(_violations);
  int get violationCount => _violations.length;
  bool get isLocked => _isLocked;
  int get remainingViolations => (maxViolations - _violations.length).clamp(0, maxViolations);
  double get violationPercentage => _violations.length / maxViolations;

  /// Cek apakah sudah melewati batas
  bool get hasExceededLimit => _violations.length >= maxViolations;

  // ── Record Violation ─────────────────────────────────────────────────
  /// Catat pelanggaran baru. Returns true jika sudah melewati batas.
  bool addViolation(String type, String description) {
    if (_isLocked) return true;

    final record = ViolationRecord(
      type: type,
      description: description,
      timestamp: DateTime.now(),
    );

    _violations.add(record);
    debugPrint('🚨 [ViolationService] Violation #$violationCount: $type - $description');
    notifyListeners();

    if (hasExceededLimit) {
      _isLocked = true;
      debugPrint('🔒 [ViolationService] MAX VIOLATIONS REACHED! Auto-submitting...');
      onMaxViolationsReached?.call();
      return true;
    }

    return false;
  }

  // ── Specific violation helpers ────────────────────────────────────────
  bool recordFocusLost() => addViolation(
    'focus_lost',
    'Siswa pindah ke aplikasi/jendela lain (Alt+Tab atau ganti window)',
  );

  bool recordFullscreenExit() => addViolation(
    'fullscreen_exit',
    'Siswa keluar dari mode layar penuh (Fullscreen)',
  );

  bool recordShortcutAttempt(String shortcut) => addViolation(
    'shortcut_attempt',
    'Siswa memencet $shortcut',
  );

  bool recordCopyPaste(String action) => addViolation(
    'copy_paste',
    'Siswa mencoba $action pada area soal',
  );

  bool recordRightClick() => addViolation(
    'right_click',
    'Siswa memencet klik kanan (Right Click) pada mouse',
  );

  // ── Export log ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> exportLog() {
    return _violations.map((v) => v.toJson()).toList();
  }

  /// Reset — hanya untuk testing, bukan untuk production
  void reset() {
    _violations.clear();
    _isLocked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _violations.clear();
    super.dispose();
  }
}
