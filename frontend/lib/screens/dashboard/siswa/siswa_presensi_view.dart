import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- Tailwind Neo-Brutalist Tokens ---
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surface = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);

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
    if (_isLoading) return _buildSkeleton();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return RefreshIndicator(
          onRefresh: _fetchRiwayat,
          color: _primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: isDesktop ? 40 : 16,
              right: isDesktop ? 40 : 16,
              top: 32,
              bottom: 100,
            ),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Kehadiran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isDesktop ? 48 : 36,
                              fontWeight: FontWeight.w800,
                              color: _onBackground,
                              letterSpacing: -1.92,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.teamData['nama_kelas'] ?? 'Kelas'} · ${_riwayat.length} catatan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NeoIconButton(
                      icon: LucideIcons.refreshCw,
                      onTap: _fetchRiwayat,
                      color: _secondaryContainer,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),

              // Visual Dashboard
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: _buildVisualDashboardNeo(),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

              // Riwayat List
              if (_riwayat.isEmpty)
                _buildEmpty()
              else ...[
                Text(
                  'Detail Riwayat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: _onBackground,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _riwayat.length,
                  itemBuilder: (context, index) {
                    return _buildRiwayatCardNeo(_riwayat[index])
                        .animate(delay: (index * 40 + 200).ms)
                        .fadeIn()
                        .slideX(begin: 0.05, curve: Curves.easeOutQuart);
                  },
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildVisualDashboardNeo() {
    final total = _riwayat.length;
    final pct = total > 0 ? (_hadir / total) : 0.0;

    Color pctColor = const Color(0xFF10B981); // Green
    if (pct < 0.75) pctColor = const Color(0xFFF59E0B); // Orange
    if (pct < 0.50) pctColor = const Color(0xFFEF4444); // Red

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _onSurface, width: 2),
        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Persentase Kehadiran',
                style: GoogleFonts.plusJakartaSans(
                  color: _onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _onSurface, width: 2),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    color: pctColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _onSurface, width: 1.5),
                borderRadius: BorderRadius.circular(100),
              ),
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
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatDetailNeo('Hadir', _hadir, _primaryContainer),
              const SizedBox(width: 12),
              _buildStatDetailNeo('Izin', _izin, _secondaryContainer),
              const SizedBox(width: 12),
              _buildStatDetailNeo('Sakit', _sakit, _tertiaryContainer),
              const SizedBox(width: 12),
              _buildStatDetailNeo('Alpa', _alpha, _surfaceContainerHighest),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetailNeo(String label, int count, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: _onBackground,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatCardNeo(Map<String, dynamic> record) {
    final status = record['status'] ?? 'Alpa';
    final tanggal = DateTime.tryParse(record['tanggal'] ?? '');
    final tanggalStr = tanggal != null
        ? DateFormat('EEEE, d MMMM yyyy').format(tanggal)
        : record['tanggal'] ?? '-';
    final waktu = record['waktu'] ?? '-';

    final statusConfig = _getStatusConfig(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusConfig.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _onSurface, width: 1.5),
              ),
              child: Icon(statusConfig.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggalStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: _onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Pukul $waktu',
                        style: GoogleFonts.inter(
                          color: _onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusConfig.color,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: _onSurface, width: 2),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.white,
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
      case 'hadir': return _StatusConfig(_primary, LucideIcons.checkSquare);
      case 'izin': return _StatusConfig(_onSecondaryContainer, LucideIcons.fileText);
      case 'sakit': return _StatusConfig(const Color(0xFFF59E0B), LucideIcons.activity); // Orange
      default: return _StatusConfig(const Color(0xFFEF4444), LucideIcons.xSquare); // Red
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: _onSurface, width: 2),
            ),
            child: const Icon(LucideIcons.calendarCheck, color: _onSurface, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada catatan presensi',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 24, color: _onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu belum memiliki riwayat presensi di kelas ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 60, width: 200),
          const SizedBox(height: 40),
          const SkeletonLoader(height: 250, radius: 16),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: SkeletonLoader(height: 100, radius: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  _StatusConfig(this.color, this.icon);
}

class _NeoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _NeoIconButton({required this.icon, required this.onTap, required this.color});

  @override
  State<_NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<_NeoIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(12),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: _isPressed ? [] : const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
        ),
        child: Icon(widget.icon, color: _onSurface, size: 24),
      ),
    );
  }
}
