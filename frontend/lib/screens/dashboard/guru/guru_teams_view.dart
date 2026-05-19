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
            title: const Text('Gabung ke Tim/Kelas', style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan 8 karakter kode akses kelas untuk bergabung.'),
                const SizedBox(height: 16),
                AppTextField(
                  controller: codeCtrl,
                  labelText: 'Kode Akses',
                  prefixIcon: Icons.vpn_key_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              PremiumElevatedButton(
                color: const Color(0xFFF27F33),
                textColor: const Color(0xFF121212),
                radius: 12,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resBody['message'] ?? 'Berhasil bergabung!'), backgroundColor: Theme.of(context).colorScheme.secondary),
                        );
                      }
                      _fetchMyTeams();
                    } else {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resBody['message'] ?? 'Gagal bergabung'), backgroundColor: const Color(0xFFF27F33)),
                        );
                      }
                      setDialogState(() => isSubmitting = false);
                    }
                  } catch (e) {
                     if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Terjadi kesalahan jaringan'), backgroundColor: Color(0xFFF27F33)),
                        );
                      }
                      setDialogState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gabung Tim', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AppFAB(
        onPressed: _showJoinDialog,
        icon: Icons.add_moderator_rounded,
        label: 'Gabung dengan Kode',
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 80, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'Anda belum memiliki/masuk ke tim atau kelas.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klik tombol di bawah untuk bergabung menggunakan kode akses.',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            )
          : RepaintBoundary(
              child: RefreshIndicator(
                onRefresh: _fetchMyTeams,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.32,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tim = _myTeams[index];
                            final color = Color(int.parse(tim['warna_card'] ?? '0xFF075864'));
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            
                            String initials = "??";
                            final nama = (tim['nama_kelas'] as String? ?? "").trim();
                            if (nama.isNotEmpty) {
                              final parts = nama.split(' ');
                              if (parts.length >= 2) {
                                initials = (parts[0][0] + parts[1][0]).toUpperCase();
                              } else {
                                initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
                              }
                            }

                            void onTap() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GuruTeamDetailLayout(
                                    userData: widget.userData,
                                    token: widget.token,
                                    teamData: tim,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2538) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: color.withAlpha(isDark ? 55 : 30),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 80 : 12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: color.withAlpha(isDark ? 30 : 15),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Initials Orb with Gradient
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  color,
                                                  color.withAlpha(160),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: color.withAlpha(80),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                initials,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (tim['kode_kelas'] != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: color.withAlpha(isDark ? 30 : 20),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: color.withAlpha(isDark ? 80 : 50),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'CLASS CODE: ${tim['kode_kelas']}',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.8,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  tim['nama_kelas'] ?? '-',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: isDark ? Colors.white : AppTheme.textLight,
                                                    height: 1.25,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Divider
                                      Container(
                                        height: 1,
                                        width: double.infinity,
                                        color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                                      ),
                                      const SizedBox(height: 10),
                                      // Bottom Row with Info & Concentric Button-in-Button
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.users,
                                            size: 13,
                                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${(tim['siswa_ids'] as List?)?.length ?? 0} Siswa',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Premium Button-in-Button design
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: onTap,
                                              borderRadius: BorderRadius.circular(30),
                                              child: Container(
                                                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius: BorderRadius.circular(30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: color.withAlpha(90),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Kelola',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white24,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          LucideIcons.arrowUpRight,
                                                          size: 10,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                          },
                          childCount: _myTeams.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
