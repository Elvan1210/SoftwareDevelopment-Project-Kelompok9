import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';

class GuruProfilView extends StatelessWidget {
  final Map<String, dynamic> userData;
  const GuruProfilView({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF10B981); // Emerald for Guru
    final String nama = userData['nama'] ?? '-';
    final String email = userData['email'] ?? '-';
    final String mapel = userData['kelas'] ?? '-';
    final String role = userData['role'] ?? 'Guru';
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
            child: Column(
              children: [
                _ProfileHeroHeader(
                  initials: initials,
                  nama: nama,
                  role: role,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: padding,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _InfoSection(email: email, extra: mapel, extraLabel: 'Mata Pelajaran')),
                            const SizedBox(width: 16),
                            Expanded(child: _LogoutSection(context: context)),
                          ],
                        )
                      : Column(children: [
                          _InfoSection(email: email, extra: mapel, extraLabel: 'Mata Pelajaran'),
                          const SizedBox(height: 16),
                          _LogoutSection(context: context),
                        ]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  final String initials, nama, role;
  final Color primaryColor;
  const _ProfileHeroHeader({required this.initials, required this.nama, required this.role, required this.primaryColor});

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
        boxShadow: [BoxShadow(color: primaryColor.withAlpha(100), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(child: Text(initials, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: primaryColor))),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text(nama, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withAlpha(80))),
          child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email, extra, extraLabel;
  const _InfoSection({required this.email, required this.extra, required this.extraLabel});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Informasi Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        _row(context, Icons.email_outlined, 'Email', email, primary),
        const SizedBox(height: 16),
        _row(context, Icons.book_outlined, extraLabel, extra, primary),
      ]),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _row(BuildContext ctx, IconData icon, String label, String value, Color primary) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primary.withAlpha(15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primary, size: 20)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface.withAlpha(130), letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ])),
    ]);
  }
}

class _LogoutSection extends StatelessWidget {
  final BuildContext context;
  const _LogoutSection({required this.context});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.w900)),
                  content: const Text('Kamu yakin ingin logout dari akun ini?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
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
      ]),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}

