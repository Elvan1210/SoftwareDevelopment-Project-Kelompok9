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
                      'Masukkan kode akses 8 karakter yang diberikan oleh Admin.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt)),
                  const SizedBox(height: 4),
                  Text(
                      '⚠ Kode akses BERBEDA dengan kode kelas yang tertera di kartu.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600)),
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
                        hintText: 'AB3X9KL2',
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
class _GuruTeamCard extends StatefulWidget {
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
  State<_GuruTeamCard> createState() => _GuruTeamCardState();
}

class _GuruTeamCardState extends State<_GuruTeamCard> {
  bool _isHovered = false;

  static const _subjectIcons = [
    LucideIcons.calculator,
    LucideIcons.beaker,
    LucideIcons.bookOpen,
    LucideIcons.pen,
    LucideIcons.globe,
    LucideIcons.music,
  ];

  @override
  Widget build(BuildContext context) {
    final namaKelas = widget.tim['nama_kelas']?.toString() ?? '-';
    final siswaCount = (widget.tim['siswa_ids'] as List?)?.length ?? 0;
    final kodeKelas  = widget.tim['kode_kelas']?.toString() ?? '';
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    // Stable index from kodeKelas or namaKelas for icon cycling
    final stableIdx  = (widget.tim['id']?.hashCode ?? namaKelas.hashCode).abs();
    final subjectIcon = _subjectIcons[stableIdx % _subjectIcons.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2230) : Colors.white,
            border: Border.all(
              color: _isHovered ? widget.accentColor : (isDark ? const Color(0xFF2D3748) : const Color(0xFF001E2B)),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withAlpha(100)
                    : (isDark ? const Color(0xFF000000) : const Color(0xFF001E2B)),
                offset: _isHovered ? const Offset(6, 6) : const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base color
                    Container(color: widget.headerColor),

                    // Decorative circles
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withAlpha(25),
                          border: Border.all(color: widget.accentColor.withAlpha(40), width: 2),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30, bottom: -30,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withAlpha(15),
                        ),
                      ),
                    ),

                    // Large background icon
                    Positioned(
                      left: 16, bottom: -8,
                      child: Icon(
                        subjectIcon,
                        size: 80,
                        color: widget.accentColor.withAlpha(30),
                      ),
                    ),

                    // Foreground icon badge (top-left)
                    Positioned(
                      left: 16, top: 16,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.accentColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withAlpha(80),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(subjectIcon, size: 20, color: widget.accentColor),
                      ),
                    ),

                    // Kode kelas badge (bottom-right)
                    if (kodeKelas.isNotEmpty)
                      Positioned(
                        bottom: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: widget.accentColor, width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withAlpha(60),
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            kodeKelas,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: widget.accentColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Left accent strip ───────────────────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.accentColor, widget.accentColor.withAlpha(80)],
                  ),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama kelas
                    Text(
                      namaKelas,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textLight,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Siswa count pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.headerColor.withAlpha(120),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.accentColor.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.users, size: 12, color: widget.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '$siswaCount Siswa',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: widget.accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Button MASUK KELAS
                    NeoButton(
                      text: 'MASUK KELAS',
                      color: widget.accentColor,
                      onTap: widget.onTap,
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
