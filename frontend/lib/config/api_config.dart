import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Gunakan 10.0.2.2 untuk Android Emulator, localhost untuk iOS/Web
String get baseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

