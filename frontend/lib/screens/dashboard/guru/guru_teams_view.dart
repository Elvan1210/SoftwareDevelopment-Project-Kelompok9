import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_team_detail_layout.dart';
import '../../../widgets/app_shell.dart';

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
                AntigravityTextField(
                  controller: codeCtrl,
                  labelText: 'Kode Akses',
                  prefixIcon: Icons.vpn_key_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27F33),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                          SnackBar(content: Text(resBody['message'] ?? 'Berhasil bergabung!'), backgroundColor: AppTheme.getAdaptiveTeal(context)),
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
      floatingActionButton: AntigravityFAB(
        onPressed: _showJoinDialog,
        icon: Icons.add_moderator_rounded,
        label: 'Gabung dengan Kode',
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 80, color: AppTheme.getAdaptiveTeal(context)),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda belum memiliki/masuk ke tim atau kelas.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klik tombol di bawah untuk bergabung menggunakan kode akses.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
                          maxCrossAxisExtent: 350,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tim = _myTeams[index];
                            final color = Color(int.parse(tim['warna_card'] ?? '0xFF075864'));
                            
                            return PremiumCard(
                              accentColor: color,
                              padding: EdgeInsets.zero,
                              onTap: () {
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
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      color: color,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Icon(Icons.class_rounded, color: Colors.white.withAlpha(200)),
                                              const Icon(Icons.more_vert, color: Colors.white),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            tim['nama_kelas'] ?? '-',
                                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            tim['mapel'] ?? '-',
                                            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Bottom section
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      color: Theme.of(context).colorScheme.surface,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF76AFB8).withAlpha(20),
                                              border: Border.all(color: const Color(0xFF76AFB8).withAlpha(50)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('Kode: ${tim['kode_akses']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF76AFB8))),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text('${(tim['siswa_ids'] as List?)?.length ?? 0} Siswa', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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