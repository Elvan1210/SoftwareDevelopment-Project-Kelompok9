import 'package:flutter/widgets.dart';
import 'violation_service.dart';

/// Service untuk mendeteksi ketika aplikasi kehilangan fokus.
///
/// Fitur:
/// - Detect saat user Alt+Tab / pindah aplikasi
/// - Detect saat user minimize window
/// - Trigger warning + violation logging
///
/// Cross-platform:
/// - Desktop: Menggunakan WidgetsBindingObserver (AppLifecycleState)
/// - Mobile: Sama — lifecycle paused/inactive = focus lost
/// - Web: visibilitychange event ditangkap oleh WidgetsBindingObserver
///
/// SECURITY LEVEL: ✅ Secure
/// - Tidak bisa dihindari — OS selalu memberitahu lifecycle change
/// - Setiap focus loss tercatat dengan timestamp

class FocusDetectionService with WidgetsBindingObserver {
  final ViolationService violationService;
  final VoidCallback? onFocusLost;
  final VoidCallback? onFocusRegained;
  bool _isActive = false;
  bool _wasPaused = false;
  DateTime? _lastFocusLostTime;

  FocusDetectionService({
    required this.violationService,
    this.onFocusLost,
    this.onFocusRegained,
  });

  bool get isActive => _isActive;

  /// Aktifkan detection — panggil ini saat exam dimulai
  void activate() {
    if (_isActive) return;
    _isActive = true;
    WidgetsBinding.instance.addObserver(this);
    debugPrint('👁️ [FocusDetection] Activated');
  }

  /// Nonaktifkan detection — panggil saat exam selesai
  void deactivate() {
    _isActive = false;
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('👁️ [FocusDetection] Deactivated');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;

    debugPrint('👁️ [FocusDetection] Lifecycle: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (!_wasPaused) {
          _wasPaused = true;
          _lastFocusLostTime = DateTime.now();
          violationService.recordFocusLost();
          onFocusLost?.call();
          debugPrint('🚨 [FocusDetection] FOCUS LOST at $_lastFocusLostTime');
        }
        break;
      case AppLifecycleState.resumed:
        if (_wasPaused) {
          _wasPaused = false;
          final duration = _lastFocusLostTime != null
              ? DateTime.now().difference(_lastFocusLostTime!)
              : Duration.zero;
          debugPrint('🔄 [FocusDetection] FOCUS REGAINED after ${duration.inSeconds}s');
          onFocusRegained?.call();
        }
        break;
      case AppLifecycleState.detached:
        // App sedang ditutup — tidak perlu violation
        break;
    }
  }

  void dispose() {
    deactivate();
  }
}
