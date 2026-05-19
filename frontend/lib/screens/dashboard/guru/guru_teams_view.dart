import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_team_detail_layout.dart';
import '../../../widgets/app_shell.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';

class GuruTeamsView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruTeamsView({super.key, required this.userData, required this.token});

  @override
  State<GuruTeamsView> createState() => _GuruTeamsViewState();
}

class _GuruTeamsViewState extends State<GuruTeamsView> {
  List<dynamic> _myTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTeams();
  }

  Future<void> _fetchMyTeams() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'] ?? widget.userData['uid'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas?guru_id=$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        _myTeams = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Gabung ke Tim/Kelas',
                style: GoogleFonts.notoSerif(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Masukkan kode akses kelas untuk bergabung.',
                    style: GoogleFonts.inter(fontSize: 13)),
                const SizedBox(height: 16),
                AppTextField(
                  controller: codeCtrl,
                  labelText: 'Kode Akses',
                  prefixIcon: Icons.vpn_key_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.inter()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (codeCtrl.text.trim().isEmpty) return;
                        setDialogState(() => isSubmitting = true);
                        try {
                          final response = await http.post(
                            Uri.parse('$baseUrl/api/kelas/join'),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer ${widget.token}'
                            },
                            body: jsonEncode({
                              'kode_akses':
                                  codeCtrl.text.trim().toUpperCase()
                            }),
                          );
                          final resBody = jsonDecode(response.body);
                          if (response.statusCode == 200) {
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      resBody['message'] ?? 'Berhasil bergabung!'),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                            }
                            _fetchMyTeams();
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      resBody['message'] ?? 'Gagal bergabung'),
                                  backgroundColor: AppTheme.rose,
                                ),
                              );
                            }
                            setDialogState(() => isSubmitting = false);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terjadi kesalahan jaringan'),
                                backgroundColor: AppTheme.rose,
                              ),
                            );
                          }
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Gabung',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(height: 160, radius: 20),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? const EmptyState(
              icon: LucideIcons.layoutGrid,
              message: 'Belum ada kelas ampuan.',
              subtitle: 'Hubungi admin untuk ditugaskan ke kelas.',
              color: AppTheme.primary,
            )
          : RefreshIndicator(
              onRefresh: _fetchMyTeams,
              color: AppTheme.primary,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: _myTeams.length,
                itemBuilder: (context, index) {
                  final tim = _myTeams[index];
                  return _GuruTeamCard(
                    tim: tim,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuruTeamDetailLayout(
                          userData: widget.userData,
                          token: widget.token,
                          teamData: tim,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: (index * 60).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, curve: Curves.easeOutQuart);
                },
              ),
            ),
    );
  }
}

// ── Team Card ─────────────────────────────────────────────────────────────────
class _GuruTeamCard extends StatelessWidget {
  final dynamic tim;
  final bool isDark;
  final VoidCallback onTap;

  const _GuruTeamCard({
    required this.tim,
    required this.isDark,
    required this.onTap,
  });

  String _getMapelLabel(String mapel) {
    final parts = mapel.trim().split(' ');
    if (parts.isEmpty) return '???';
    return parts[0]
        .substring(0, parts[0].length >= 3 ? 3 : parts[0].length)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.primary;
    final namaKelas = tim['nama_kelas']?.toString() ?? '-';
    final mapel = tim['mapel']?.toString() ?? namaKelas;
    final guruNama = tim['guru_nama']?.toString();
    final siswaCount = (tim['siswa_ids'] as List?)?.length ?? 0;
    final kodeKelas = tim['kode_kelas']?.toString();
    final mapelLabel = _getMapelLabel(mapel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // ── Card utama ──
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Top row: mapel label + siswa chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mapelLabel,
                        style: GoogleFonts.notoSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(isDark ? 40 : 20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.users, size: 11, color: color),
                            const SizedBox(width: 4),
                            Text(
                              '$siswaCount Siswa',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Nama kelas
                  Text(
                    namaKelas,
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Guru nama
                  if (guruNama != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      guruNama,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.textMutedDk
                            : AppTheme.textMutedLt,
                      ),
                    ),
                  ],

                  // Kode kelas
                  if (kodeKelas != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.key,
                          size: 11,
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Kode: $kodeKelas',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textMutedDk
                                : AppTheme.textMutedLt,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Divider + LIHAT DETAIL
                  Divider(
                    height: 1,
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'LIHAT DETAIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 13, color: color),
                    ],
                  ),
                ],
              ),
            ),

            // ── Left accent bar ──
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}