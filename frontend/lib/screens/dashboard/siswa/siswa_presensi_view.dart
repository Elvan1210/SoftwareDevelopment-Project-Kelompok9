import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SiswaPresensiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const SiswaPresensiView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<SiswaPresensiView> createState() => _SiswaPresensiViewState();
}

class _SiswaPresensiViewState extends State<SiswaPresensiView> {
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = true;

  int _hadir = 0;
  int _izin = 0;
  int _sakit = 0;
  int _alpha = 0;

  String get _kelasId => widget.teamData['id']?.toString() ?? '';
  String get _siswaId => widget.userData['id']?.toString() ?? widget.userData['uid']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/presensi?kelas_id=$_kelasId&user_id=$_siswaId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<Map<String, dynamic>> raw = (decoded is List ? decoded : [])
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        raw.sort((a, b) {
          final ta = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
          return tb.compareTo(ta);
        });

        int h = 0, iz = 0, sk = 0, al = 0;
        for (final r in raw) {
          switch ((r['status'] ?? '').toLowerCase()) {
            case 'hadir': h++; break;
            case 'izin': iz++; break;
            case 'sakit': sk++; break;
            default: al++;
          }
        }

        if (mounted) {
          setState(() {
            _riwayat = raw;
            _hadir = h;
            _izin = iz;
            _sakit = sk;
            _alpha = al;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch presensi siswa: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Kehadiran',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.teamData['nama_kelas'] ?? 'Kelas'} · ${_riwayat.length} catatan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.textMutedLt,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _fetchRiwayat,
                  icon: const Icon(LucideIcons.refreshCw, color: AppTheme.success, size: 18),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),

          const SizedBox(height: 24),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
          else ...[
            _buildVisualDashboard().animate().fadeIn(delay: 100.ms).scale(),

            const SizedBox(height: 28),
            const Text(
              'Detail Riwayat',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textLight,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            Expanded(
              child: _riwayat.isEmpty
                  ? const EmptyState(
                      icon: LucideIcons.calendarCheck,
                      message: 'Belum ada catatan presensi.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _riwayat.length,
                      itemBuilder: (context, index) {
                        return _buildRiwayatCard(_riwayat[index])
                            .animate(delay: (index * 40).ms)
                            .fadeIn()
                            .slideX(begin: 0.05, curve: Curves.easeOutQuart);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualDashboard() {
    final total = _riwayat.length;
    final pct = total > 0 ? (_hadir / total) : 0.0;

    Color pctColor = const Color(0xFF22C55E);
    if (pct < 0.75) pctColor = const Color(0xFFF59E0B);
    if (pct < 0.50) pctColor = const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Persentase Kehadiran',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pctColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: pctColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 8,
              width: double.infinity,
              color: AppTheme.lightBorder,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  decoration: BoxDecoration(
                    color: pctColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatDetail('Hadir', _hadir, const Color(0xFF22C55E)),
              _buildStatDetail('Izin', _izin, AppTheme.info),
              _buildStatDetail('Sakit', _sakit, const Color(0xFFF59E0B)),
              _buildStatDetail('Alpa', _alpha, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> record) {
    final status = record['status'] ?? 'Alpa';
    final tanggal = DateTime.tryParse(record['tanggal'] ?? '');
    final tanggalStr = tanggal != null
        ? DateFormat('EEEE, d MMMM yyyy').format(tanggal)
        : record['tanggal'] ?? '-';
    final waktu = record['waktu'] ?? '-';

    final statusConfig = _getStatusConfig(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusConfig.color.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusConfig.icon, color: statusConfig.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggalStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 13, color: AppTheme.textMutedLt),
                      const SizedBox(width: 4),
                      Text(
                        'Pukul $waktu',
                        style: const TextStyle(
                          color: AppTheme.textMutedLt,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusConfig.color.withAlpha(22),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: statusConfig.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return _StatusConfig(const Color(0xFF22C55E), LucideIcons.checkSquare);
      case 'izin': return _StatusConfig(const Color(0xFF76AFB8), LucideIcons.fileText);
      case 'sakit': return _StatusConfig(const Color(0xFFF59E0B), LucideIcons.activity);
      default: return _StatusConfig(const Color(0xFFEF4444), LucideIcons.xSquare);
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  _StatusConfig(this.color, this.icon);
}
