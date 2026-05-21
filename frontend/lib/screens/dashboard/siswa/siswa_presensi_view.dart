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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    Text(
                      'Riwayat Kehadiran',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppTheme.textLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.teamData['nama_kelas'] ?? 'Kelas'} · ${_riwayat.length} catatan',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
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
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildVisualDashboard(theme, isDark).animate().fadeIn(delay: 100.ms).scale(),

            const SizedBox(height: 28),
            Text(
              'Detail Riwayat',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, 
                color: isDark ? Colors.white : AppTheme.textLight),
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
    
    Color pctColor = const Color(0xFF22C55E);
    if (pct < 0.75) pctColor = const Color(0xFFF59E0B);
    if (pct < 0.50) pctColor = const Color(0xFFEF4444);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Persentase Kehadiran',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color!, 
                  fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pctColor,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 8,
            width: double.infinity,
            color: Theme.of(context).dividerColor,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                color: pctColor,
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
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: color.withAlpha(200)),
          ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3), blurRadius: 0)],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusConfig.color,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
              ),
              child: Icon(statusConfig.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggalStr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, 
                      color: Theme.of(context).textTheme.bodyLarge!.color!),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 13, color: Theme.of(context).textTheme.bodyMedium!.color!),
                      const SizedBox(width: 4),
                      Text(
                        'Pukul $waktu',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium!.color!, 
                          fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusConfig.color,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
              ),
              child: Text(
                status.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900,
                  color: Colors.white),
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
