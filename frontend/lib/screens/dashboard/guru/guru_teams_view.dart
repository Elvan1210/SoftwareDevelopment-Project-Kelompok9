import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_team_detail_layout.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../widgets/neo_brutalism.dart';

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
      barrierColor: Colors.black.withAlpha(130),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface,
                      offset: const Offset(4, 4))
                ],
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
                      child: Icon(LucideIcons.x,
                          size: 20,
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Gabung Kelas',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 6),
                  Text(
                      'Masukkan kode akses kelas yang diberikan oleh Admin.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt)),
                  const SizedBox(height: 24),

                  // Label
                  Text('KODE AKSES',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  // Input kode
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface,
                            offset: const Offset(3, 3),
                            blurRadius: 0)
                      ],
                    ),
                    child: TextField(
                      controller: codeCtrl,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textLight,
                          letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'X7KL9M',
                        hintStyle:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.textMutedDk
                                    : AppTheme.textMutedLt,
                                letterSpacing: 2),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                                  'kode_akses':
                                      codeCtrl.text.trim().toUpperCase()
                                }),
                              );
                              final resBody = jsonDecode(response.body);
                              if (response.statusCode == 200) {
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        resBody['message'] ?? 'Berhasil!'),
                                    backgroundColor: AppTheme.primary,
                                  ));
                                }
                                _fetchMyTeams();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text(resBody['message'] ?? 'Gagal'),
                                    backgroundColor: AppTheme.error,
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
                      decoration: BoxDecoration(
                        color: isSubmitting
                            ? AppTheme.primary.withAlpha(150)
                            : AppTheme.primary,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface,
                              offset: const Offset(3, 3),
                              blurRadius: 0)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSubmitting) ...[
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Icon(LucideIcons.logIn,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                          ],
                          Text('GABUNG SEKARANG',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Batal
                  NeoButton(
                    text: 'BATAL',
                    color: Theme.of(context).colorScheme.surface,
                    textColor: isDark ? Colors.white : AppTheme.textLight,
                    onTap: () => Navigator.pop(ctx),
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
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: SkeletonLoader(height: 280),
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
              const Icon(LucideIcons.plus, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('GABUNG KELAS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final pad = w >= 900 ? 40.0 : 24.0;
                  final isWide = w >= 900;
                  final crossAxisCount = w >= 1200 ? 3 : (w >= 750 ? 2 : 1);
                  final maxW = isWide ? 1100.0 : double.infinity;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 120),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: List.generate(_myTeams.length, (index) {
                            final tim = _myTeams[index];
                            final headerColor =
                                _headerColors[index % _headerColors.length];
                            final accentColor =
                                _accentColors[index % _accentColors.length];

                            final cardW = crossAxisCount == 1
                                ? (w - pad * 2)
                                : (isWide && w >= 1200
                                    ? (1100 - (20 * 2)) / 3
                                    : (w - pad * 2 - 20) / 2);

                            return SizedBox(
                              width: cardW,
                              child: _GuruTeamCard(
                                tim: tim,
                                headerColor: headerColor,
                                accentColor: accentColor,
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
                              ),
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
}

// ── Team Card ──────────────────────────────────────────────────────────────
class _GuruTeamCard extends StatelessWidget {
  final dynamic tim;
  final Color headerColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _GuruTeamCard({
    required this.tim,
    required this.headerColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final namaKelas = tim['nama_kelas']?.toString() ?? '-';
    final mapel = tim['mapel']?.toString() ?? '';
    final siswaCount = (tim['siswa_ids'] as List?)?.length ?? 0;
    final kodeKelas = tim['kode_kelas']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        padding: EdgeInsets.zero,
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
                          color: accentColor,
                          border: Border.all(
                              color: accentColor,
                              width: 1),
                        ),
                        child: Text(
                          mapel.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8),
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
                          color: Colors.white,
                          border: Border.all(
                              color: accentColor,
                              width: 1.5),
                        ),
                        child: Text(
                          kodeKelas,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  letterSpacing: 1),
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
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppTheme.textLight,
                              letterSpacing: -0.5,
                              height: 1.2)),
                  const SizedBox(height: 8),

                  // Siswa count
                  Row(children: [
                    Icon(LucideIcons.users,
                        size: 14,
                        color: isDark
                            ? AppTheme.textMutedDk
                            : AppTheme.textMutedLt),
                    const SizedBox(width: 6),
                    Text('$siswaCount Siswa',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppTheme.textMutedDk
                                : AppTheme.textMutedLt)),
                  ]),

                  const SizedBox(height: 16),

                  // Button MASUK KELAS
                  NeoButton(
                    text: 'MASUK KELAS',
                    color: accentColor,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
