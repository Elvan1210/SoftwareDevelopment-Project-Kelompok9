class AppDateUtils {
  static DateTime parseIndonesianDate(String raw) {
    if (raw.isEmpty) return DateTime(2000);
    
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    
    const bulan = {
      // Singkatan Indonesia
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'Mei': 5, 'Jun': 6, 'Jul': 7, 'Agu': 8,
      'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12,
      // Singkatan English
      'May': 5, 'June': 6, 'July': 7, 'Aug': 8,
      'Oct': 10,
      // Nama panjang Indonesia
      'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4,
      'Juni': 6, 'Juli': 7, 'Agustus': 8,
      'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12,
    };
    
    try {
      final parts = raw.trim().split(' ');
      return DateTime(int.parse(parts[2]), bulan[parts[1]] ?? 1, int.parse(parts[0]));
    } catch (_) { return DateTime(2000); }
  }
}