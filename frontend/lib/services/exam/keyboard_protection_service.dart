import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'violation_service.dart';

/// Service untuk mendeteksi dan memblok shortcut keyboard terlarang.
///
/// Shortcut yang diproteksi:
/// - Alt + Tab     → detect + violation (Flutter TIDAK bisa block OS-level)
/// - Alt + F4      → intercept di Flutter level
/// - Windows Key   → detect only (OS-level, tidak bisa diblok)
/// - Ctrl + Esc    → detect only
/// - F11           → intercept (prevent browser fullscreen toggle)
/// - Ctrl + Shift + I → intercept (prevent dev tools)
/// - Ctrl + W      → intercept (prevent close tab)
/// - Ctrl + C/V/X  → intercept (prevent copy/paste/cut)
/// - PrintScreen   → detect only
///
/// SECURITY LEVEL: ⚠️ Deterrent (campuran)
/// - Flutter hanya bisa intercept keyboard events di dalam app focus
/// - Shortcut OS-level (Win key, Alt+Tab) hanya bisa dideteksi, TIDAK diblok
/// - Tapi kita bisa MENGHUKUM user yang mencoba via violation system

class KeyboardProtectionService {
  final ViolationService violationService;
  bool _isActive = false;

  KeyboardProtectionService({required this.violationService});

  bool get isActive => _isActive;

  void activate() {
    _isActive = true;
    debugPrint('⌨️ [KeyboardProtection] Activated');
  }

  void deactivate() {
    _isActive = false;
    debugPrint('⌨️ [KeyboardProtection] Deactivated');
  }

  /// Handle keyboard event. Returns true jika shortcut diblok.
  /// Panggil ini dari RawKeyboardListener / KeyboardListener di exam screen.
  bool handleKeyEvent(KeyEvent event) {
    if (!_isActive) return false;
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // ── Alt + Tab ──
    if (isAlt && key == LogicalKeyboardKey.tab) {
      violationService.recordShortcutAttempt('Alt + Tab');
      debugPrint('🚫 [KeyboardProtection] Alt+Tab detected!');
      return true;
    }

    // ── Alt + F4 ──
    if (isAlt && key == LogicalKeyboardKey.f4) {
      violationService.recordShortcutAttempt('Alt + F4');
      debugPrint('🚫 [KeyboardProtection] Alt+F4 blocked!');
      return true;
    }

    // ── Windows Key (Meta) ──
    if (key == LogicalKeyboardKey.metaLeft || key == LogicalKeyboardKey.metaRight) {
      violationService.recordShortcutAttempt('Windows Key');
      debugPrint('🚫 [KeyboardProtection] Windows Key detected!');
      return true;
    }

    // ── Ctrl + Esc ──
    if (isCtrl && key == LogicalKeyboardKey.escape) {
      violationService.recordShortcutAttempt('Ctrl + Esc');
      debugPrint('🚫 [KeyboardProtection] Ctrl+Esc detected!');
      return true;
    }

    // ── F11 (Fullscreen toggle) ──
    if (key == LogicalKeyboardKey.f11) {
      violationService.recordShortcutAttempt('F11');
      debugPrint('🚫 [KeyboardProtection] F11 blocked!');
      return true;
    }

    // ── Ctrl + Shift + I (Dev Tools) ──
    if (isCtrl && isShift && key == LogicalKeyboardKey.keyI) {
      violationService.recordShortcutAttempt('Ctrl + Shift + I');
      debugPrint('🚫 [KeyboardProtection] DevTools shortcut blocked!');
      return true;
    }

    // ── Ctrl + W (Close tab/window) ──
    if (isCtrl && key == LogicalKeyboardKey.keyW) {
      violationService.recordShortcutAttempt('Ctrl + W');
      debugPrint('🚫 [KeyboardProtection] Ctrl+W blocked!');
      return true;
    }

    // ── Ctrl + C (Copy) ──
    if (isCtrl && key == LogicalKeyboardKey.keyC) {
      violationService.recordCopyPaste('Copy (Ctrl+C)');
      debugPrint('🚫 [KeyboardProtection] Copy blocked!');
      return true;
    }

    // ── Ctrl + V (Paste) ──
    if (isCtrl && key == LogicalKeyboardKey.keyV) {
      violationService.recordCopyPaste('Paste (Ctrl+V)');
      debugPrint('🚫 [KeyboardProtection] Paste blocked!');
      return true;
    }

    // ── Ctrl + X (Cut) ──
    if (isCtrl && key == LogicalKeyboardKey.keyX) {
      violationService.recordCopyPaste('Cut (Ctrl+X)');
      debugPrint('🚫 [KeyboardProtection] Cut blocked!');
      return true;
    }


    // ── Print Screen ──
    if (key == LogicalKeyboardKey.printScreen) {
      violationService.recordShortcutAttempt('Print Screen');
      debugPrint('🚫 [KeyboardProtection] PrintScreen detected!');
      return true;
    }

    // ── Escape ──
    if (key == LogicalKeyboardKey.escape) {
      violationService.recordShortcutAttempt('Escape');
      debugPrint('🚫 [KeyboardProtection] Escape blocked!');
      return true;
    }

    return false;
  }
}
