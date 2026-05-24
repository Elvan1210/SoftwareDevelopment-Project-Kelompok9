import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'siswa_team_detail_layout.dart' hide GlassCard;
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
      final userId = Uri.encodeComponent((widget.userData['id'] ?? widget.userData['uid']).toString());
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
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.userPlus,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Gabung ke Kelas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Minta kode akses kepada guru Anda, lalu masukkan di sini.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMutedLt,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Code input
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                    ),
                    child: TextField(
                      controller: codeCtrl,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: AppTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'XXXXXXXX',
                        hintStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: AppTheme.textMutedLt.withAlpha(80),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.lightBorder, width: 1.2),
                          ),
                          child: Text(
                            'Batal',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMutedLt,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Submit button
                      GestureDetector(
                        onTap: isSubmitting ? null : () async {
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
                                      : resBody['message'] ?? 'Menunggu persetujuan guru.',
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                  backgroundColor: status == 'accepted' ? AppTheme.emerald : AppTheme.amber,
                                  behavior: SnackBarBehavior.floating,
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(50),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Gabung Kelas',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
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
      floatingActionButton: GestureDetector(
        onTap: _showJoinDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(80),
                offset: const Offset(0, 4),
                blurRadius: 12,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Gabung Kelas', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 8),
                  Text('Gunakan kode dari guru untuk masuk ke kelas.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMyTeams,
              color: AppTheme.indigoPrimary,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final pad = w >= 950 ? 24.0 : 16.0;
                  final isWide = w >= 950;
                  final crossAxisCount = w >= 1200 ? 3 : (w >= 750 ? 2 : 1);
                  final maxW = isWide ? 1100.0 : double.infinity;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(16, 24, pad, 120),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: List.generate(_myTeams.length, (index) {
                            final tim   = _myTeams[index];
                            Color color;
                            try {
                              String wc = tim['warna_card']?.toString() ?? '4284705521';
                              if (wc.startsWith('#')) wc = '0xFF${wc.substring(1)}';
                              color = Color(int.parse(wc));
                            } catch (e) {
                              color = const Color(0xFF6366F1);
                            }
                            final nama  = (tim['nama_kelas'] as String? ?? '').trim();
                            String initials = nama.isEmpty ? '??' : (() {
                              final parts = nama.split(' ');
                              return parts.length >= 2
                                  ? (parts[0][0] + parts[1][0]).toUpperCase()
                                  : nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
                            })();

                            final cardW = crossAxisCount == 1
                                ? double.infinity
                                : (isWide && w >= 1200
                                    ? (1100 - (20 * 2)) / 3
                                    : (w - pad * 2 - 20) / 2);

                            return SizedBox(
                              width: cardW,
                              child: _TeamCard(
                                tim: tim,
                                color: color,
                                initials: initials,
                                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                                  builder: (_) => SiswaTeamDetailLayout(
                                    userData: widget.userData,
                                    token: widget.token,
                                    teamData: tim,
                                  ),
                                )),
                              )
                              .animate(delay: (index * 60).ms)
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack, duration: 600.ms),
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _skeleton() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final pad = w >= 950 ? 24.0 : 16.0;
      final isWide = w >= 950;
      final crossAxisCount = w >= 1200 ? 3 : (w >= 750 ? 2 : 1);
      final maxW = isWide ? 1100.0 : double.infinity;

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 24, pad, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(4, (index) {
                final cardW = crossAxisCount == 1
                    ? double.infinity
                    : (isWide && w >= 1200
                        ? (1100 - (20 * 2)) / 3
                        : (w - pad * 2 - 20) / 2);
                return SkeletonLoader(width: cardW, height: 180, radius: 16);
              }),
            ),
          ),
        ),
      );
    });
  }
}

class _TeamCard extends StatelessWidget {
  final dynamic tim;
  final Color color;
  final String initials;
  final VoidCallback onTap;

  const _TeamCard({
    required this.tim, required this.color, required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        // Colored accent strip at top
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top color accent strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color.withAlpha(200),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern rounded icon box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.book, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tim['kode_kelas'] != null)
                                // Pill-shaped code badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    'KODE: ${tim['kode_kelas']}',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              if (tim['kode_kelas'] != null) const SizedBox(height: 6),
                              Text(
                                tim['nama_kelas'] ?? '-',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textLight,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.lightBorder, height: 1, thickness: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 15, color: AppTheme.textMutedLt),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tim['guru_nama'] ?? 'Guru belum ditugaskan',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMutedLt,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Modern rounded MASUK button
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(60),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'MASUK',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.arrowRight, size: 13, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

