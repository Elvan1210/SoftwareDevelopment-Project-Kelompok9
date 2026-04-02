import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Kehadiran',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.teamData['nama_kelas'] ?? 'Kelas'} · ${_riwayat.length} catatan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: _fetchRiwayat,
                  child: Icon(Icons.refresh_rounded, color: theme.primaryColor, size: 24),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),

          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // ── Visual Progress & Stats Dashboard ──
            _buildVisualDashboard(theme, isDark).animate().fadeIn(delay: 100.ms).scale(),

            const SizedBox(height: 28),
            Text(
              'Detail Riwayat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: theme.colorScheme.onSurface),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            // ── Riwayat List ──
            Expanded(
              child: _riwayat.isEmpty
                  ? const EmptyState(
                      icon: Icons.event_available_outlined,
                      message: 'Belum ada catatan presensi.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _riwayat.length,
                      itemBuilder: (context, index) {
                        return _buildRiwayatCard(_riwayat[index], theme, isDark)
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

  Widget _buildVisualDashboard(ThemeData theme, bool isDark) {
    final total = _riwayat.length;
    final pct = total > 0 ? (_hadir / total) : 0.0;
    
    // Gradasi progres bar berdasarkan persentase
    Color pctColor = const Color(0xFF22C55E); // Hijau
    if (pct < 0.75) pctColor = const Color(0xFFF59E0B); // Kuning/Orange
    if (pct < 0.50) pctColor = const Color(0xFFEF4444); // Merah

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(24),
      overrideColor: theme.primaryColor.withAlpha(isDark ? 30 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Persentase Kehadiran',
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: pctColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: pctColor, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 20 : 60),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuart,
                  width: MediaQuery.of(context).size.width * pct,
                  decoration: BoxDecoration(
                    color: pctColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: pctColor.withAlpha(100), blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            children: [
              _buildStatDetail('Hadir', _hadir, const Color(0xFF22C55E)),
              _buildStatDetail('Izin', _izin, const Color(0xFF3B82F6)),
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
          Text(count.toString(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.withAlpha(200))),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> record, ThemeData theme, bool isDark) {
    final status = record['status'] ?? 'Alpa';
    final tanggal = DateTime.tryParse(record['tanggal'] ?? '');
    final tanggalStr = tanggal != null
        ? DateFormat('EEEE, d MMMM yyyy').format(tanggal)
        : record['tanggal'] ?? '-';
    final waktu = record['waktu'] ?? '-';

    final statusConfig = _getStatusConfig(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(16),
        overrideColor: statusConfig.color.withAlpha(isDark ? 15 : 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusConfig.color.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(statusConfig.icon, color: statusConfig.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggalStr,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(120)),
                      const SizedBox(width: 4),
                      Text(
                        'Pukul $waktu',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(120), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusConfig.color.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: statusConfig.color.withAlpha(60)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
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
      case 'hadir': return const _StatusConfig(Color(0xFF22C55E), Icons.check_circle_rounded);
      case 'izin': return const _StatusConfig(Color(0xFF3B82F6), Icons.insert_drive_file_rounded);
      case 'sakit': return const _StatusConfig(Color(0xFFF59E0B), Icons.medical_services_rounded);
      default: return const _StatusConfig(Color(0xFFEF4444), Icons.cancel_rounded);
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  const _StatusConfig(this.color, this.icon);
}
