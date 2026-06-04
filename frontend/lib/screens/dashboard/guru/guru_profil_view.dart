import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';
import 'package:image_picker/image_picker.dart';
import '../shared/crop_screen.dart';
import '../../../widgets/avatar_widget.dart';

// ─── Tailwind Neo-Brutalist Tokens (sama dengan siswa) ─────────────────────
const Color _primary = Color(0xFF3D6754);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondary = Color(0xFF336763);
const Color _onSecondary = Color(0xFFFFFFFF);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _surfaceBright = Color(0xFFF4FAFF);
const Color _surface = Color(0xFFF4FAFF);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _errorContainer = Color(0xFFFFDAD6);
const Color _onErrorContainer = Color(0xFF93000A);

class GuruProfilView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const GuruProfilView({super.key, required this.userData});

  @override
  State<GuruProfilView> createState() => _GuruProfilViewState();
}

class _GuruProfilViewState extends State<GuruProfilView> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data ?? widget.userData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _onSurface));
    }

    final String userId = _userData['id'] ?? _userData['uid'] ?? _userData['_id'] ?? '';
    final String nama = _userData['nama'] ?? '-';
    final String email = _userData['email'] ?? '-';
    final String role = _userData['role'] ?? 'Guru';
    final String currentStatus = _userData['status'] ?? 'Available';
    final String photoUrl = _userData['photoUrl'] ?? '';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'GR';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final isWide = w >= Breakpoints.tablet;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: 32,
              bottom: 100,
            ),
            child: isWide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LEFT — full height profile card
                            Expanded(
                              flex: 5,
                              child: _ProfileCard(
                                initials: initials,
                                nama: nama,
                                role: role,
                                photoUrl: photoUrl,
                                onUpdated: _loadUserData,
                                fullHeight: true,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // RIGHT — info + status + logout
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _InfoCard(email: email, role: role),
                                  const SizedBox(height: 16),
                                  _StatusCard(
                                    userId: userId,
                                    initialStatus: currentStatus,
                                    onStatusChanged: _loadUserData,
                                  ),
                                  const SizedBox(height: 16),
                                  const _ActionCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _ProfileCard(
                          initials: initials,
                          nama: nama,
                          role: role,
                          photoUrl: photoUrl,
                          onUpdated: _loadUserData),
                      const SizedBox(height: 16),
                      _InfoCard(email: email, role: role),
                      const SizedBox(height: 16),
                      _StatusCard(
                        userId: userId,
                        initialStatus: currentStatus,
                        onStatusChanged: _loadUserData,
                      ),
                      const SizedBox(height: 16),
                      const _ActionCard(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatefulWidget {
  final String initials;
  final String nama;
  final String role;
  final String photoUrl;
  final VoidCallback onUpdated;
  final bool fullHeight;

  const _ProfileCard({
    required this.initials,
    required this.nama,
    required this.role,
    required this.photoUrl,
    required this.onUpdated,
    this.fullHeight = false,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isHovered = false;

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      final newUrl = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropScreen(imageBytes: bytes),
        ),
      );
      if (newUrl != null) {
        widget.onUpdated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: widget.fullHeight ? double.infinity : null,
        padding: const EdgeInsets.all(32),
        transform: Matrix4.translationValues(
          _isHovered ? -2 : 0,
          _isHovered ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: _primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: _onSurface,
              offset: _isHovered ? const Offset(6, 6) : const Offset(4, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: widget.fullHeight
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickAndCropImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(
                    initial: widget.initials,
                    photoUrl: widget.photoUrl,
                    size: widget.fullHeight ? 160 : 128,
                    bgColor: _surface,
                    textColor: _primary,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _onSurface, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: _onSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.nama,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: widget.fullHeight ? 32 : 28,
                color: _onPrimaryContainer,
                letterSpacing: -0.56,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, color: _onSurfaceVariant, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.role,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatefulWidget {
  final String email;
  final String role;
  const _InfoCard({required this.email, required this.role});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.translationValues(
          _isHovered ? -2 : 0,
          _isHovered ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: _surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: _onSurface,
              offset: _isHovered ? const Offset(6, 6) : const Offset(4, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INFORMASI AKUN',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.email_outlined, 'Email', widget.email),
            const SizedBox(height: 12),
            _infoRow(Icons.school_outlined, 'Role', widget.role),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: _primary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: _onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatefulWidget {
  final String userId;
  final String initialStatus;
  final VoidCallback onStatusChanged;

  const _StatusCard({
    required this.userId,
    required this.initialStatus,
    required this.onStatusChanged,
  });

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  bool _isHovered = false;
  late String _selectedStatus;

  final List<String> statusOptions = [
    'Available',
    'Busy',
    'Do Not Disturb',
    'Be Right Back',
    'Appear Away',
    'Appear Offline'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = statusOptions.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'Available';
  }

  Future<void> updateStatus(String newStatus) async {
    setState(() => _selectedStatus = newStatus);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'status': newStatus});

      final userData = await AuthService.getUserData();
      if (userData != null) {
        userData['status'] = newStatus;
        await AuthService.saveUserData(userData);
      }

      widget.onStatusChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status chat diperbarui ke $newStatus',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: _onSurface,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        transform: Matrix4.translationValues(
          _isHovered ? -2 : 0,
          _isHovered ? -2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: _surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: [
            BoxShadow(
              color: _onSurface,
              offset: _isHovered ? const Offset(6, 6) : const Offset(4, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status Chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _onSurface, width: 2),
                  ),
                  child: Text(
                    'LIVE',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _onSurface, width: 2),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.expand_more, color: _onSurface),
                  ),
                  dropdownColor: Colors.white,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _onSurface,
                  ),
                  items: statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(status),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) updateStatus(val);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1);
  }
}

// ── Action Card (Logout) ──────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  const _ActionCard();

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _showLogoutModal(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99001E2B),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _onSurface, width: 3),
            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(8, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _onSurface, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.logout, color: _onErrorContainer, size: 32),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Keluar dari Akun?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: _onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu yakin ingin logout dari akun ini?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: _onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _onSurface, width: 2),
                        boxShadow: const [
                          BoxShadow(color: _onSurface, offset: Offset(4, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _onSurface, width: 2),
                        boxShadow: const [
                          BoxShadow(color: _onSurface, offset: Offset(4, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _onSurface,
                          ),
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
    ).then((confirm) async {
      if (confirm == true) {
        await AuthService.logout();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutModal(context),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          transform: Matrix4.translationValues(
            _isPressed || _isHovered ? 2 : 0,
            _isPressed || _isHovered ? 2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: _errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _onSurface, width: 2),
            boxShadow: _isPressed || _isHovered
                ? const [BoxShadow(color: _onSurface, offset: Offset(2, 2))]
                : const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: _onErrorContainer, size: 20),
              const SizedBox(width: 12),
              Text(
                'Keluar dari Akun',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1);
  }
}
