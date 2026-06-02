import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_screen.dart';
// import '../../../config/theme.dart';

// --- NEO-BRUTALIST CONSTANTS ---
const Color _kPrimary = Color(0xFF2E5343); // Dark Green
const Color _kPastelGreen = Color(0xFFB7D8CE); // Header
const Color _kPastelBlue = Color(0xFFC4D7ED); // Info
const Color _kPastelRed = Color(0xFFF4C7B5); // Logout
const Color _kIceBlue = Color(0xFFF0F4F0); // Background
const BorderSide _kBorder2 = BorderSide(color: Colors.black, width: 2.0);
const BoxShadow _kHardShadow = BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0);
final BorderRadius _kRadius12 = BorderRadius.circular(12.0);

class AdminProfilView extends StatefulWidget {
  final String token;
  const AdminProfilView({super.key, required this.token});

  @override
  State<AdminProfilView> createState() => _AdminProfilViewState();
}

class _AdminProfilViewState extends State<AdminProfilView> {
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
        _userData = data ?? {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF121212) : _kIceBlue;

    final String userId = _userData['id'] ?? _userData['uid'] ?? _userData['_id'] ?? '';
    final String nama = _userData['nama'] ?? 'Admin';
    final String email = _userData['email'] ?? '-';
    final String role = _userData['role'] ?? 'Admin';
    final String currentStatus = _userData['status'] ?? 'Available';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'AD';

    return Scaffold(
      backgroundColor: bgCol,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Max width for clean profile
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PROFILE HEADER CARD
                _HeaderCard(
                  initials: initials,
                  nama: nama,
                  role: role,
                  isDark: isDark,
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 16),

                // 2. INFORMASI AKUN CARD
                _InfoCard(
                  email: email,
                  role: role,
                  isDark: isDark,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // 3. STATUS CHAT CARD
                _StatusCard(
                  userId: userId,
                  currentStatus: currentStatus,
                  onStatusChanged: _loadUserData,
                  isDark: isDark,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // 4. KELUAR DARI AKUN BUTTON
                _LogoutCard(
                  isDark: isDark,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── WIDGETS ──

class _HeaderCard extends StatelessWidget {
  final String initials, nama, role;
  final bool isDark;

  const _HeaderCard({
    required this.initials,
    required this.nama,
    required this.role,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.black : _kPrimary; // Keep it dark for contrast on pastel
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: _kPastelGreen,
        borderRadius: _kRadius12,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: const [_kHardShadow],
      ),
      child: Column(
        children: [
          // AVATAR
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3.0),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              // EDIT PEN ICON
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: const Icon(LucideIcons.edit2, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // NAME
          Text(
            nama,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textCol,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // ROLE
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shield, size: 16, color: textCol),
              const SizedBox(width: 6),
              Text(
                role,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String email, role;
  final bool isDark;

  const _InfoCard({
    required this.email,
    required this.role,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPastelBlue,
        borderRadius: _kRadius12,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: const [_kHardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMASI AKUN',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Email',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatefulWidget {
  final String userId, currentStatus;
  final VoidCallback onStatusChanged;
  final bool isDark;

  const _StatusCard({
    required this.userId,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.isDark,
  });

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  late String selectedStatus;
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
    selectedStatus = statusOptions.contains(widget.currentStatus)
        ? widget.currentStatus
        : 'Available';
  }

  @override
  void didUpdateWidget(_StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      setState(() => selectedStatus = widget.currentStatus);
    }
  }

  Future<void> updateStatus(String newStatus) async {
    setState(() => selectedStatus = newStatus);
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
            content: Text('Status chat diperbarui!', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white)),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgCol = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = widget.isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: _kRadius12,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: const [_kHardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status Chat',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // NEO DROPDOWN
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border.fromBorderSide(_kBorder2),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              icon: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(LucideIcons.chevronDown, color: Colors.black, size: 24),
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: InputBorder.none,
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) updateStatus(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final bool isDark;

  const _LogoutCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Colors.black, width: 2.0),
            ),
            title: Text(
              'KELUAR?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.black),
            ),
            content: Text(
              'Kamu yakin ingin logout dari akun ini?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'BATAL',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPastelRed,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'KELUAR',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
        if (ok == true) {
          await AuthService.logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _kPastelRed,
          borderRadius: _kRadius12,
          border: const Border.fromBorderSide(_kBorder2),
          boxShadow: const [_kHardShadow],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, size: 20, color: Color(0xFF8B0000)),
            const SizedBox(width: 12),
            Text(
              'Keluar dari Akun',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8B0000), // Dark red text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
