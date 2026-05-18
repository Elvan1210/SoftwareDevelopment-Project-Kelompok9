import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> joinJitsiMeeting({
  required BuildContext context,
  required String meetingId,
  required String serverUrl,
  required String userName,
  required String userEmail,
  required String subject,
  VoidCallback? onClosed,
}) async {
  final url = '$serverUrl/$meetingId#userInfo.displayName=${Uri.encodeComponent(userName)}&userInfo.email=${Uri.encodeComponent(userEmail)}';
  final uri = Uri.parse(url);
  
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication); // Membuka tab baru
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka kelas live di browser.'), backgroundColor: Colors.red),
      );
    }
  }
}
