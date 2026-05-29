import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/api_config.dart';
import 'siswa_team_detail_layout.dart' hide GlassCard;

// Tailwind Colors Mapping for Neo-brutalism
const Color _bgBackground = Color(0xFFF4FAFF);
const Color _onBackground = Color(0xFF001E2B);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _primary = Color(0xFF3D6754);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _outlineVariant = Color(0xFFC1C8C2);
const Color _secondary = Color(0xFF336763);
const Color _tertiary = Color(0xFF8D4D33);
const Color _surfaceContainer = Color(0xFFDBF1FF);
const Color _error = Color(0xFFBA1A1A);
const Color _emerald = Color(0xFF10B981); // for success snackbar

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
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _onBackground, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: _onBackground, offset: Offset(4, 4), blurRadius: 0),
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
                          color: _surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _onBackground, width: 2),
                        ),
                        child: const Icon(Icons.person_add_outlined, color: _primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Gabung Kelas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masukkan kode akses dari guru Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _onBackground, width: 2),
                    ),
                    child: TextField(
                      controller: codeCtrl,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: _onBackground,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'XXXXXXXX',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: _outlineVariant,
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
                      _NeoButton(
                        label: 'Batal',
                        onTap: () => Navigator.pop(ctx),
                        backgroundColor: Colors.white,
                        textColor: _onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      _NeoButton(
                        label: 'Gabung',
                        isLoading: isSubmitting,
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
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                  backgroundColor: status == 'accepted' ? _emerald : _primary,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                if (status == 'accepted') _fetchMyTeams();
                              }
                            } else {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(resBody['message'] ?? 'Gagal bergabung', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                  backgroundColor: _error,
                                ));
                              }
                              setDialogState(() => isSubmitting = false);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Terjadi kesalahan jaringan', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                backgroundColor: _error,
                              ));
                            }
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                        backgroundColor: _primary,
                        textColor: _onPrimary,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    return Scaffold(
      backgroundColor: _bgBackground,
      body: RefreshIndicator(
        onRefresh: _fetchMyTeams,
        color: _primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelas Saya',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                      color: _onSurface,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kelola perjalanan belajarmu dan akses materi pembelajaran dalam satu tempat.',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      color: _onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            _NeoButton(
                              label: 'Gabung Kelas Baru',
                              icon: Icons.add_circle,
                              onTap: _showJoinDialog,
                              backgroundColor: _secondaryContainer,
                              textColor: _onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              fontSize: 20,
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelas Saya',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: _onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kelola perjalanan belajarmu dan akses materi pembelajaran dalam satu tempat.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: _onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _NeoButton(
                              label: 'Gabung Kelas Baru',
                              icon: Icons.add_circle,
                              onTap: _showJoinDialog,
                              backgroundColor: _secondaryContainer,
                              textColor: _onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              fontSize: 16,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),

                  // Classes List
                  if (_myTeams.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _onBackground, width: 2),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: _onBackground, offset: Offset(4, 4), blurRadius: 0),
                              ],
                            ),
                            child: const Icon(Icons.backpack_outlined, size: 48, color: _primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum bergabung kelas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gunakan tombol di atas untuk masuk ke kelas.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: List.generate(_myTeams.length, (index) {
                        final tim = _myTeams[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _TeamCardNeo(
                            tim: tim,
                            index: index,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SiswaTeamDetailLayout(
                                userData: widget.userData,
                                token: widget.token,
                                teamData: tim,
                              ),
                            )),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool isLoading;

  const _NeoButton({
    required this.label,
    this.icon,
    this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.fontSize = 16,
    this.isLoading = false,
  });

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null && !widget.isLoading ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null && !widget.isLoading ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _onBackground, width: 2),
          boxShadow: [
            if (!_isPressed)
              const BoxShadow(
                color: _onBackground,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: widget.fontSize,
                height: widget.fontSize,
                child: CircularProgressIndicator(color: widget.textColor, strokeWidth: 2),
              )
            else if (widget.icon != null)
              Icon(widget.icon, color: widget.textColor, size: widget.fontSize * 1.2),
            if (widget.icon != null || widget.isLoading) const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCardNeo extends StatefulWidget {
  final dynamic tim;
  final VoidCallback onTap;
  final int index;

  const _TeamCardNeo({
    required this.tim,
    required this.onTap,
    required this.index,
  });

  @override
  State<_TeamCardNeo> createState() => _TeamCardNeoState();
}

class _TeamCardNeoState extends State<_TeamCardNeo> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Cycle through accent colors
    final colors = [_primary, _secondary, _tertiary, const Color(0xFF8E4F34)];
    final icons = [Icons.calculate_outlined, Icons.science_outlined, Icons.menu_book_outlined, Icons.palette_outlined];
    
    final color = colors[widget.index % colors.length];
    final icon = icons[widget.index % icons.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovering ? color : _onBackground,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: _onBackground,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              
              final content = Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _onBackground, width: 2),
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tim['nama_kelas'] ?? 'Kelas Tanpa Nama',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: _onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Guru: ${widget.tim['guru_nama'] ?? 'Belum Ditugaskan'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.tim['kode_kelas'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _outlineVariant),
                                ),
                                child: Text(
                                  'Kode: ${widget.tim['kode_kelas']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    _NeoButton(
                      label: 'Akses Kelas',
                      icon: Icons.arrow_forward,
                      onTap: widget.onTap,
                      backgroundColor: _primary,
                      textColor: _onPrimary,
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 24),
                    _NeoButton(
                      label: 'Akses Kelas',
                      icon: Icons.arrow_forward,
                      onTap: widget.onTap,
                      backgroundColor: _primary,
                      textColor: _onPrimary,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
