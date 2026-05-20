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

// ── Palette ────────────────────────────────────────────────────────────────
class _P {
  static const ink = Color(0xFF001E2B);
  static const primary = Color(0xFF3D6754);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF414944);
  static const outline = Color(0xFF717974);
}
// Warna header per kelas (cycling)
const _headerColors = [
  Color(0xFFB7E5CD), // primary container - hijau mint
  Color(0xFFB7EDE7), // secondary container - teal
  Color(0xFFFFD1C0), // tertiary container - peach
  Color(0xFFCEEDFF), // surface container high - biru muda
  Color(0xFFDDE1FF), // lavender
  Color(0xFFFFEFD5), // warm yellow
];

const _accentColors = [
  Color(0xFF3D6754), // primary
  Color(0xFF336763), // secondary
  Color(0xFF8D4D33), // tertiary
  Color(0xFF305669), // deep slate
  Color(0xFF4A5490), // indigo
  Color(0xFF7A5C00), // amber dark
];

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
      barrierColor: _P.ink.withAlpha(130),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: const BoxDecoration(
              color: _P.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border:
                  Border.fromBorderSide(BorderSide(color: _P.ink, width: 2)),
              boxShadow: [BoxShadow(color: _P.ink, offset: Offset(4, 4))],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child:
                        const Icon(LucideIcons.x, size: 20, color: _P.outline),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Gabung Kelas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _P.ink,
                    )),
                const SizedBox(height: 6),
                Text('Masukkan kode akses kelas yang diberikan oleh Admin.',
                    style: GoogleFonts.inter(fontSize: 13, color: _P.muted)),
                const SizedBox(height: 24),

                // Label
                Text('KODE AKSES',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _P.muted,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 8),

                // Input kode
                TextField(
                  controller: codeCtrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _P.ink,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: '______',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 24,
                      color: _P.outline,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFDBF1FF),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: _P.ink, width: 2),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: _P.ink, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: _P.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Gabung
                GestureDetector(
                  onTap: isSubmitting
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
                                'kode_akses': codeCtrl.text.trim().toUpperCase()
                              }),
                            );
                            final resBody = jsonDecode(response.body);
                            if (response.statusCode == 200) {
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text(resBody['message'] ?? 'Berhasil!'),
                                  backgroundColor: _P.primary,
                                ));
                              }
                              _fetchMyTeams();
                            } else {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(resBody['message'] ?? 'Gagal'),
                                  backgroundColor: AppTheme.rose,
                                ));
                              }
                              setDialogState(() => isSubmitting = false);
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: _P.primary,
                      border: Border.fromBorderSide(
                          BorderSide(color: _P.ink, width: 2)),
                      boxShadow: [
                        BoxShadow(color: _P.ink, offset: Offset(4, 4))
                      ],
                    ),
                    child: isSubmitting
                        ? const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: _P.white, strokeWidth: 2)))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text('GABUNG SEKARANG',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _P.white,
                                      letterSpacing: 0.5,
                                    )),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.logIn,
                                    size: 16, color: _P.white),
                              ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Batal
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCEEDFF),
                      border: Border.all(color: _P.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(color: _P.ink, offset: Offset(4, 4))
                      ],
                    ),
                    child: Center(
                      child: Text('BATAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _P.ink,
                            letterSpacing: 0.5,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: SkeletonLoader(height: 280, radius: 4),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: GestureDetector(
        onTap: _showJoinDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _P.primary,
            border: Border.all(color: _P.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: _P.ink, offset: Offset(4, 4)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.plus, color: _P.white, size: 18),
            const SizedBox(width: 8),
            Text('GABUNG KELAS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _P.white,
                  letterSpacing: 0.5,
                )),
          ]),
        ),
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? const EmptyState(
              icon: LucideIcons.layoutGrid,
              message: 'Belum ada kelas ampuan.',
              subtitle: 'Hubungi admin untuk ditugaskan ke kelas.',
              color: _P.primary,
            )
          : RefreshIndicator(
              onRefresh: _fetchMyTeams,
              color: _P.primary,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                itemCount: _myTeams.length,
                itemBuilder: (context, index) {
                  final tim = _myTeams[index];
                  final headerColor =
                      _headerColors[index % _headerColors.length];
                  final accentColor =
                      _accentColors[index % _accentColors.length];
                  // Asymmetric per card cycling
                  final radii = [
                    const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(8),
                    ),
                    const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(32),
                    ),
                  ];
                  final radius = radii[index % radii.length];

                  return _GuruTeamCard(
                    tim: tim,
                    headerColor: headerColor,
                    accentColor: accentColor,
                    radius: radius,
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
                      .animate(delay: (index * 80).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, curve: Curves.easeOutQuart);
                },
              ),
            ),
    );
  }
}

// ── Team Card ──────────────────────────────────────────────────────────────
class _GuruTeamCard extends StatelessWidget {
  final dynamic tim;
  final Color headerColor;
  final Color accentColor;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _GuruTeamCard({
    required this.tim,
    required this.headerColor,
    required this.accentColor,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final namaKelas = tim['nama_kelas']?.toString() ?? '-';
    final mapel = tim['mapel']?.toString() ?? '';
    final siswaCount = (tim['siswa_ids'] as List?)?.length ?? 0;
    final kodeKelas = tim['kode_kelas']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _P.white,
          borderRadius: radius,
          border: Border.all(color: _P.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: _P.ink, offset: Offset(4, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header color block ──────────────────────────────
              Container(
                width: double.infinity,
                height: 100,
                color: headerColor,
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Mapel label
                    if (mapel.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _P.ink,
                            border: Border.all(color: _P.ink),
                          ),
                          child: Text(
                            mapel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _P.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    // Kode kelas
                    if (kodeKelas.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _P.white,
                            border: Border.all(color: _P.ink),
                          ),
                          child: Text(
                            kodeKelas,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _P.ink,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama kelas
                    Text(namaKelas,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _P.ink,
                          letterSpacing: -0.5,
                          height: 1.2,
                        )),
                    const SizedBox(height: 8),

                    // Siswa count
                    Row(children: [
                      const Icon(LucideIcons.users,
                          size: 14, color: _P.outline),
                      const SizedBox(width: 6),
                      Text('$siswaCount Siswa',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _P.muted,
                          )),
                    ]),

                    const SizedBox(height: 16),

                    // Button MASUK KELAS
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: accentColor,
                          border: Border.all(color: _P.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(color: _P.ink, offset: Offset(3, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('MASUK KELAS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _P.white,
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight,
                                size: 16, color: _P.white),
                          ],
                        ),
                      ),
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
