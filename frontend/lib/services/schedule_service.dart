import 'dart:async';
import 'package:flutter/foundation.dart';
import 'quiz_service.dart';

class ScheduleService {
  static Timer? _timer;

  static void startChecking(String token) {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        await QuizService.activateScheduled(token: token);
      } catch (e) {
        debugPrint('Schedule check error: $e');
      }
    });
  }

  static void stopChecking() {
    _timer?.cancel();
    _timer = null;
  }
}
