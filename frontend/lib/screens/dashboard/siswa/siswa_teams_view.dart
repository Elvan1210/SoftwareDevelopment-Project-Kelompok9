import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'siswa_team_detail_layout.dart';
import '../../../widgets/app_shell.dart';

class SiswaTeamsView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaTeamsView({super.key, required this.userData, required this.token});

  @override
  State<SiswaTeamsView> createState() => _SiswaTeamsViewState();
}

class _SiswaTeamsViewState extends State<SiswaTeamsView> {
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
        Uri.parse('$baseUrl/api/kelas?siswa_id=$userId'),
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text('Gabung ke Kelas',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18,
                              color: isDark ? Colors.white : AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Minta kode akses kepada guru Anda, lalu masukkan di sini.',
                      style: GoogleFonts.poppins(fontSize: 13,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                  const SizedBox(height: 20),
                  // Code input
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg : const Color(0xFFF5F5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.indigoPrimary.withAlpha(60)),
                    ),
                    child: TextField(
                      controller: codeCtrl,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: isDark ? Colors.white : AppTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'XXXXXXXX',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: isDark ? AppTheme.textMutedDk.withAlpha(100) : AppTheme.textMutedLt.withAlpha(100),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Batal', style: GoogleFonts.poppins(
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : () async {
                              if (codeCtrl.text.trim().isEmpty) return;
                              setDialogState(() => isSubmitting = true);
                              try {
                                final response = await http.post(
                                  Uri.parse('$baseUrl/api/kelas/join'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer ${widget.token}'
                                  },
                                  body: jsonEncode({'kode_akses': codeCtrl.text.trim().toUpperCase()}),
                                );
                                final resBody = jsonDecode(response.body);
                                if (response.statusCode == 200) {
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    final status = resBody['status'] ?? 'pending';
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(status == 'accepted'
                                          ? 'Berhasil bergabung ke kelas!'
                                          : resBody['message'] ?? 'Menunggu persetujuan guru.'),
                                      backgroundColor: status == 'accepted' ? AppTheme.emerald : AppTheme.amber,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ));
                                    if (status == 'accepted') _fetchMyTeams();
                                  }
                                } else {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(resBody['message'] ?? 'Gagal bergabung'),
                                      backgroundColor: AppTheme.rose,
                                    ));
                                  }
                                  setDialogState(() => isSubmitting = false);
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Terjadi kesalahan jaringan'),
                                    backgroundColor: AppTheme.rose,
                                  ));
                                }
                                setDialogState(() => isSubmitting = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              foregroundColor: Colors.white, elevation: 0,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Gabung', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _skeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.indigoPrimary.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showJoinDialog,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: Text('Gabung Kelas', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
      body: _myTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.indigoPrimary.withAlpha(isDark ? 30 : 15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.backpack, size: 48,
                        color: AppTheme.indigoPrimary.withAlpha(180)),
                  ),
                  const SizedBox(height: 20),
                  Text('Belum bergabung kelas',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 8),
                  Text('Gunakan kode dari guru untuk masuk ke kelas.',
                      style: GoogleFonts.poppins(fontSize: 13,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMyTeams,
              color: AppTheme.indigoPrimary,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final crossCount = w > 1100 ? 4 : (w > 750 ? 3 : (w > 500 ? 2 : 1));

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: _myTeams.length,
                    itemBuilder: (ctx, i) {
                      final tim   = _myTeams[i];
                      final color = Color(int.parse(tim['warna_card'] ?? '0xFF6366F1'));
                      final nama  = (tim['nama_kelas'] as String? ?? '').trim();
                      String initials = nama.isEmpty ? '??' : (() {
                        final parts = nama.split(' ');
                        return parts.length >= 2
                            ? (parts[0][0] + parts[1][0]).toUpperCase()
                            : nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
                      })();

                      return _TeamCard(
                        tim: tim,
                        color: color,
                        initials: initials,
                        isDark: isDark,
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => SiswaTeamDetailLayout(
                            userData: widget.userData,
                            token: widget.token,
                            teamData: tim,
                          ),
                        )),
                      )
                          .animate(delay: (i * 60).ms)
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack, duration: 600.ms);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _skeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(4, (_) => const SkeletonLoader(radius: 20)),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final dynamic tim;
  final Color color;
  final String initials;
  final bool isDark;
  final VoidCallback onTap;

  const _TeamCard({
    required this.tim, required this.color, required this.initials,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withAlpha(isDark ? 70 : 50),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 40 : 20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top colored header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withAlpha(isDark ? 200 : 180)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tim['kode_kelas'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tim['kode_kelas'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 9, fontWeight: FontWeight.w800,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          tim['nama_kelas'] ?? '-',
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: Colors.white, height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withAlpha(isDark ? 35 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.user, size: 14, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tim['guru_nama'] ?? 'Guru belum ditugaskan',
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 14,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
