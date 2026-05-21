/// Model untuk mencatat setiap pelanggaran selama ujian.
/// Violation types:
///   - focus_lost: User pindah aplikasi / Alt+Tab
///   - fullscreen_exit: User keluar dari fullscreen
///   - shortcut_attempt: User mencoba shortcut terlarang
///   - copy_paste: User mencoba copy/paste/cut
///   - right_click: User mencoba klik kanan

class ViolationRecord {
  final String type;
  final String description;
  final DateTime timestamp;

  ViolationRecord({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ViolationRecord.fromJson(Map<String, dynamic> json) {
    return ViolationRecord(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// Helper: Icon label berdasarkan tipe
  String get typeLabel {
    switch (type) {
      case 'focus_lost': return 'Aplikasi Kehilangan Fokus';
      case 'fullscreen_exit': return 'Keluar Fullscreen';
      case 'shortcut_attempt': return 'Shortcut Terlarang';
      case 'copy_paste': return 'Copy/Paste/Cut';
      case 'right_click': return 'Klik Kanan';
      default: return 'Pelanggaran Lain';
    }
  }
}
