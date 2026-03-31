import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';

/// SiswaPresensiView — View read-only untuk siswa melihat riwayat kehadiran mereka sendiri.
///
/// Siswa hanya bisa MELIHAT riwayat presensi (tidak bisa mengubah).
/// Data diambil dari `/api/presensi?kelas_id=<id>&user_id=<siswa_id>`.
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

  // Statistik ringkasan
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

        // Sort descending berdasarkan tanggal (terbaru di atas)
        raw.sort((a, b) {
          final ta = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
          return tb.compareTo(ta);
        });

        // Hitung statistik
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

    if (_isLoading) {
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Kehadiran',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.teamData['nama_kelas'] ?? 'Kelas'} · ${_riwayat.length} catatan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Summary Cards ──
                  _buildSummaryRow(theme),
                  const SizedBox(height: 24),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
            ),
          ),
          if (_riwayat.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available_outlined, size: 72, color: theme.colorScheme.onSurface.withAlpha(60)),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada catatan presensi.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final record = _riwayat[i];
                    return _buildRiwayatTile(record, theme, i)
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOutQuart);
                  },
                  childCount: _riwayat.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final total = _riwayat.length;
    final pct = total > 0 ? (_hadir / total * 100).toStringAsFixed(0) : '0';

    return Row(
      children: [
        _statChip(theme, 'Hadir', _hadir, const Color(0xFF22C55E)),
        const SizedBox(width: 10),
        _statChip(theme, 'Izin', _izin, const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _statChip(theme, 'Sakit', _sakit, const Color(0xFFF59E0B)),
        const SizedBox(width: 10),
        _statChip(theme, 'Alpha', _alpha, const Color(0xFFEF4444)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withAlpha(40)),
          ),
          child: Column(
            children: [
              Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF22C55E))),
              const Text('Kehadiran', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(ThemeData theme, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withAlpha(200))),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatTile(Map<String, dynamic> record, ThemeData theme, int index) {
    final status = record['status'] ?? 'Alpha';
    final tanggal = DateTime.tryParse(record['tanggal'] ?? '');
    final tanggalStr = tanggal != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id').format(tanggal)
        : record['tanggal'] ?? '-';
    final waktu = record['waktu'] ?? '-';

    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusConfig.color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusConfig.color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusConfig.color.withAlpha(20),
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
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pukul $waktu',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(120), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusConfig.color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusConfig.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return const _StatusConfig(Color(0xFF22C55E), Icons.check_circle_outline_rounded);
      case 'izin':
        return const _StatusConfig(Color(0xFF3B82F6), Icons.insert_drive_file_outlined);
      case 'sakit':
        return const _StatusConfig(Color(0xFFF59E0B), Icons.medical_services_outlined);
      default:
        return const _StatusConfig(Color(0xFFEF4444), Icons.cancel_outlined);
    }
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(5, (i) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SkeletonLoader(height: 70, radius: 16),
      )),
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  const _StatusConfig(this.color, this.icon);
}
