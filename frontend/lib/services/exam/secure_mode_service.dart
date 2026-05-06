import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'violation_service.dart';

/// Service untuk mengelola Secure Exam Mode.
///
/// Fitur:
/// - Fullscreen enforcement (auto-recover jika keluar)
/// - Always on top (window selalu di depan)
/// - Prevent resize
/// - Prevent close (intercept close request)
/// - Prevent minimize
/// - Semi-kiosk mode
///
/// Platform behavior:
/// ┌──────────┬──────────────────────────────────────────┐
/// │ Platform │ Behavior                                 │
/// ├──────────┼──────────────────────────────────────────┤
/// │ Windows  │ Full window_manager: fullscreen, AOT,    │
/// │          │ no-resize, close intercept               │
/// │ Mobile   │ Immersive mode (system UI hidden)        │
/// │ Web      │ Fullscreen API via dart:html             │
/// └──────────┴──────────────────────────────────────────┘
///
/// SECURITY LEVEL:
/// - Fullscreen enforcement: ✅ Secure (auto-recovers)
/// - Always on top: ✅ Secure (Desktop only)
/// - Close prevention: ⚠️ Semi-secure (can be killed via Task Manager)
/// - Kiosk mode: ⚠️ Semi-kiosk (true kiosk needs OS-level config)

class SecureModeService with WindowListener {
  final ViolationService? violationService;
  bool _isActive = false;
  bool _isFullscreen = false;
  Timer? _fullscreenWatchdog;

  SecureModeService({this.violationService});

  bool get isActive => _isActive;
  bool get isFullscreen => _isFullscreen;

  /// Cek apakah platform mendukung window management
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Aktifkan secure mode — panggil saat exam dimulai
  Future<void> activate() async {
    if (_isActive) return;
    _isActive = true;

    if (_isDesktop) {
      await _activateDesktop();
    }
    // Mobile & Web: fullscreen ditangani oleh SystemChrome di exam_screen.dart

    debugPrint('🔒 [SecureMode] Activated');
  }

  /// Desktop-specific activation via window_manager
  Future<void> _activateDesktop() async {
    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      // Set fullscreen
      await windowManager.setFullScreen(true);
      _isFullscreen = true;

      // Always on top
      await windowManager.setAlwaysOnTop(true);

      // Prevent resize
      await windowManager.setResizable(false);

      // Prevent minimize (skip close prevention — handled by onWindowClose)
      await windowManager.setMinimizable(false);

      // Hide title bar for cleaner look (optional)
      // await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

      // Prevent close — intercept via listener
      await windowManager.setPreventClose(true);

      // Start fullscreen watchdog — re-enforce every 2 seconds
      _startFullscreenWatchdog();

      debugPrint('🖥️ [SecureMode] Desktop: fullscreen + AOT + no-resize + no-close');
    } catch (e) {
      debugPrint('❌ [SecureMode] Desktop activation failed: $e');
    }
  }

  /// Watchdog timer yang memastikan fullscreen tetap aktif
  void _startFullscreenWatchdog() {
    _fullscreenWatchdog?.cancel();
    _fullscreenWatchdog = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_isActive) return;
      try {
        final isFs = await windowManager.isFullScreen();
        if (!isFs && _isActive) {
          debugPrint('⚠️ [SecureMode] Fullscreen lost! Recovering...');
          violationService?.recordFullscreenExit();
          await windowManager.setFullScreen(true);
          _isFullscreen = true;
        }
      } catch (_) {}
    });
  }

  /// Deactivate secure mode — panggil saat exam selesai
  Future<void> deactivate() async {
    if (!_isActive) return;
    _isActive = false;
    _fullscreenWatchdog?.cancel();

    if (_isDesktop) {
      await _deactivateDesktop();
    }

    debugPrint('🔓 [SecureMode] Deactivated');
  }

  Future<void> _deactivateDesktop() async {
    try {
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setResizable(true);
      await windowManager.setMinimizable(true);
      await windowManager.setFullScreen(false);
      _isFullscreen = false;
    } catch (e) {
      debugPrint('❌ [SecureMode] Desktop deactivation error: $e');
    }
  }

  // ── WindowListener overrides ──────────────────────────────────────────

  @override
  void onWindowClose() {
    // Intercept close — jangan biarkan user menutup window saat exam
    if (_isActive) {
      debugPrint('🚫 [SecureMode] Close attempt blocked!');
      violationService?.addViolation(
        'shortcut_attempt',
        'Mencoba menutup window saat ujian berlangsung',
      );
      // Jangan panggil windowManager.destroy() — block close
    }
  }

  @override
  void onWindowFocus() {
    // Window mendapat fokus kembali
    if (_isActive) {
      debugPrint('✅ [SecureMode] Window focused');
    }
  }

  @override
  void onWindowBlur() {
    // Window kehilangan fokus
    if (_isActive) {
      debugPrint('⚠️ [SecureMode] Window lost focus');
      // Focus detection ditangani oleh FocusDetectionService
    }
  }

  @override
  void onWindowMinimize() {
    // Window di-minimize — coba restore
    if (_isActive && _isDesktop) {
      debugPrint('⚠️ [SecureMode] Minimize detected! Restoring...');
      violationService?.addViolation(
        'fullscreen_exit',
        'Mencoba minimize window saat ujian',
      );
      windowManager.restore();
      windowManager.setFullScreen(true);
    }
  }

  @override
  void onWindowUnmaximize() {
    // Window di-unmaximize
    if (_isActive && _isDesktop) {
      windowManager.setFullScreen(true);
    }
  }

  @override
  void onWindowResize() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowEnterFullScreen() {
    _isFullscreen = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    _isFullscreen = false;
    if (_isActive && _isDesktop) {
      debugPrint('⚠️ [SecureMode] Left fullscreen! Recovering...');
      violationService?.recordFullscreenExit();
      windowManager.setFullScreen(true);
    }
  }

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowMoved() {}

  @override
  void onWindowResized() {}

  void dispose() {
    _fullscreenWatchdog?.cancel();
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
  }
}
