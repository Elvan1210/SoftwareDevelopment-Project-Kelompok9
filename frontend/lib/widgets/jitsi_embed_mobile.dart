import 'package:flutter/material.dart';
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';

Future<void> joinJitsiMeeting({
  required BuildContext context,
  required String meetingId,
  required String serverUrl,
  required String userName,
  required String userEmail,
  required String subject,
  VoidCallback? onClosed,
}) async {
  try {
    var options = JitsiMeetingOptions(
      roomNameOrUrl: meetingId,
      serverUrl: serverUrl,
      subject: subject,
      isAudioMuted: true,
      isVideoMuted: true,
      userDisplayName: userName,
      userEmail: userEmail,
    );

    await JitsiMeetWrapper.joinMeeting(
      options: options,
      listener: JitsiMeetingListener(
        onOpened: () => debugPrint("onOpened"),
        onClosed: () {
          debugPrint("onClosed");
          if (onClosed != null) onClosed();
        },
      ),
    );
  } catch (e) {
    debugPrint("Error joining Jitsi meeting: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka Jitsi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
