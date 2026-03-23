import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';

class SiswaProfilView extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SiswaProfilView({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF3B82F6);
    final String nama = userData['nama'] ?? '-';
    final String email = userData['email'] ?? '-';
    final String kelas = userData['kelas'] ?? '-';
    final String role = userData['role'] ?? 'Siswa';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'SW';

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final padding = Breakpoints.screenPadding(w);
            final isWide = w >= Breakpoints.tablet;
            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero Header ──────────────────────────────────
                  _ProfileHeroHeader(
                    initials: initials,
                    nama: nama,
                    role: role,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),

                  // ── Info Cards ───────────────────────────────────
                  Padding(
                    padding: padding,
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _InfoSection(email: email, kelas: kelas, role: role, isDark: isDark)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _ActionSection(context: context, isDark: isDark)),
                            ],
                          )
                        : Column(
                            children: [
                              _InfoSection(email: email, kelas: kelas, role: role, isDark: isDark),
                              const SizedBox(height: 16),
                              _ActionSection(context: context, isDark: isDark),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  final String initials, nama, role;
  final Color primaryColor;
  final bool isDark;

  const _ProfileHeroHeader({
    required this.initials,
    required this.nama,
    required this.role,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 72, bottom: 56, left: 32, right: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withAlpha(160)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(color: primaryColor.withAlpha(100), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Text(initials,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: primaryColor)),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(nama,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5))
              .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withAlpha(80)),
            ),
            child: Text(role.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email, kelas, role;
  final bool isDark;

  const _InfoSection({required this.email, required this.kelas, required this.role, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Akun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.class_outlined, label: 'Kelas', value: kelas),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.badge_outlined, label: 'Role', value: role),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(130), letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  final BuildContext context;
  final bool isDark;
  const _ActionSection({required this.context, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.w900)),
                    content: const Text('Kamu yakin ingin logout dari akun ini?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
