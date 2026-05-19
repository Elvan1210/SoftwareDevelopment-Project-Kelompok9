import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF10B981);
    final String userId = _userData['id'] ?? _userData['uid'] ?? _userData['_id'] ?? '';
    final String nama = _userData['nama'] ?? '-';
    final String email = _userData['email'] ?? '-';
    final String mapel = _userData['kelas'] ?? '-';
    final String role = _userData['role'] ?? 'Guru';
    final String currentStatus = _userData['status'] ?? 'Available';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'GR';

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final isWide = w >= Breakpoints.tablet;
          return SingleChildScrollView(
            child: Column(children: [
              _ProfileHeroHeader(initials: initials, nama: nama, role: role, primaryColor: primaryColor, isDark: isDark),
              const SizedBox(height: 32),
              Padding(
                padding: padding,
                child: isWide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _InfoSection(
                          email: email, extra: mapel, extraLabel: 'Mata Pelajaran',
                          userId: userId, initialStatus: currentStatus,
                          onStatusChanged: _loadUserData, isDark: isDark,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _LogoutSection(isDark: isDark)),
                      ])
                    : Column(children: [
                        _InfoSection(
                          email: email, extra: mapel, extraLabel: 'Mata Pelajaran',
                          userId: userId, initialStatus: currentStatus,
                          onStatusChanged: _loadUserData, isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _LogoutSection(isDark: isDark),
                      ]),
              ),
              const SizedBox(height: 32),
            ]),
          );
        }),
      ),
    );
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  final String initials, nama, role;
  final Color primaryColor;
  final bool isDark;

  const _ProfileHeroHeader({
    required this.initials, required this.nama, required this.role,
    required this.primaryColor, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 72, bottom: 56, left: 32, right: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, primaryColor.withAlpha(160)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withAlpha(80), shape: BoxShape.circle),
            child: Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w900, color: primaryColor),
                ),
              ),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text(
          nama,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(60), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withAlpha(80))),
          child: Text(
            role.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email, extra, extraLabel, userId, initialStatus;
  final VoidCallback onStatusChanged;
  final bool isDark;

  const _InfoSection({
    required this.email, required this.extra, required this.extraLabel,
    required this.userId, required this.initialStatus, required this.onStatusChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Informasi Akun',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 20),
          _row(context, LucideIcons.mail, 'Email', email),
          const SizedBox(height: 16),
          _row(context, LucideIcons.bookOpen, extraLabel, extra),
          const SizedBox(height: 20),
          Divider(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Text(
            'Pengaturan Status Chat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 12),
          _StatusDropdown(userId: userId, currentStatus: initialStatus, onStatusChanged: onStatusChanged, isDark: isDark),
        ]),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _row(BuildContext ctx, IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.indigoPrimary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.indigoPrimary.withAlpha(30)),
        ),
        child: Icon(icon, color: AppTheme.indigoPrimary, size: 18),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.textLight,
          ),
        ),
      ])),
    ]);
  }
}

class _StatusDropdown extends StatefulWidget {
  final String userId, currentStatus;
  final VoidCallback onStatusChanged;
  final bool isDark;

  const _StatusDropdown({
    required this.userId, required this.currentStatus, required this.onStatusChanged,
    required this.isDark,
  });

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late String selectedStatus;
  final List<String> statusOptions = ['Available', 'Busy', 'Do Not Disturb', 'Be Right Back', 'Appear Away', 'Appear Offline'];

  @override
  void initState() {
    super.initState();
    selectedStatus = statusOptions.contains(widget.currentStatus) ? widget.currentStatus : 'Available';
  }

  @override
  void didUpdateWidget(_StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      setState(() => selectedStatus = widget.currentStatus);
    }
  }

  Future<void> updateStatus(String newStatus) async {
    setState(() => selectedStatus = newStatus);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'status': newStatus});
      final userData = await AuthService.getUserData();
      if (userData != null) {
        userData['status'] = newStatus;
        await AuthService.saveUserData(userData);
      }
      widget.onStatusChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status chat berhasil diperbarui!')));
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      dropdownColor: widget.isDark ? const Color(0xFF161B27) : Colors.white,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: widget.isDark ? Colors.white : AppTheme.textLight,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
        ),
      ),
      items: statusOptions.map((status) => DropdownMenuItem(
        value: status,
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.getStatusColor(status), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold)),
        ]),
      )).toList(),
      onChanged: (val) { if (val != null) updateStatus(val); },
    );
  }
}

class _LogoutSection extends StatelessWidget {
  final bool isDark;
  const _LogoutSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Pengaturan Keamanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
                    ),
                    title: Text(
                      'Keluar?',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                    ),
                    content: Text(
                      'Kamu yakin ingin logout dari akun ini?',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await AuthService.logout();
                  if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400.withAlpha(20),
                foregroundColor: Colors.red.shade400,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.red.shade400.withAlpha(40), width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(LucideIcons.logOut, size: 16),
              label: Text(
                'Keluar dari Akun',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}