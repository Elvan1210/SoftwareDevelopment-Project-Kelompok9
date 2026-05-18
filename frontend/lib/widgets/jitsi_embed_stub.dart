import 'package:flutter/material.dart';

Future<void> joinJitsiMeeting({
  required BuildContext context,
  required String meetingId,
  required String serverUrl,
  required String userName,
  required String userEmail,
  required String subject,
  VoidCallback? onClosed,
}) async {
  throw UnsupportedError('Jitsi is not supported on this platform.');
}
