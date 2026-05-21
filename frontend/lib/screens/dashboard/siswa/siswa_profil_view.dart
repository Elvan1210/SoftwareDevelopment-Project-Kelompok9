import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../config/theme.dart';

class SiswaProfilView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SiswaProfilView({super.key, required this.userData});

  @override
  State<SiswaProfilView> createState() => _SiswaProfilViewState();
}

class _SiswaProfilViewState extends State<SiswaProfilView> {
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
    const Color primaryColor = Color(0xFF76AFB8);
    final String userId = _userData['id'] ?? _userData['uid'] ?? _userData['_id'] ?? '';
    final String nama = _userData['nama'] ?? '-';
    final String email = _userData['email'] ?? '-';
    final String kelas = _userData['kelas'] ?? '-';
    final String role = _userData['role'] ?? 'Siswa';
    final String currentStatus = _userData['status'] ?? 'Available';
    final String initials = nama.isNotEmpty
        ? nama.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'SW';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final padding = Breakpoints.screenPadding(w);
          final isWide = w >= Breakpoints.tablet;
          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeroHeader(
                  initials: initials, nama: nama, role: role,
                  primaryColor: primaryColor, isDark: isDark,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: padding,
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _InfoSection(
                              email: email, kelas: kelas, role: role,
                              isDark: isDark, userId: userId,
                              initialStatus: currentStatus,
                              onStatusChanged: _loadUserData,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _ActionSection(isDark: isDark)),
                          ],
                        )
                      : Column(children: [
                          _InfoSection(
                            email: email, kelas: kelas, role: role,
                            isDark: isDark, userId: userId,
                            initialStatus: currentStatus,
                            onStatusChanged: _loadUserData,
                          ),
                          const SizedBox(height: 16),
                          _ActionSection(isDark: isDark),
                        ]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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
      padding: const EdgeInsets.only(top: 56, bottom: 40, left: 32, right: 32),
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(160), width: 2),
        ),
        boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withAlpha(160), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(4, 4))],
          ),
          child: Center(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: primaryColor),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text(
          nama,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(60),
            border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
          ),
          child: Text(
            role.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email, kelas, role, userId, initialStatus;
  final bool isDark;
  final VoidCallback onStatusChanged;

  const _InfoSection({
    required this.email, required this.kelas, required this.role,
    required this.isDark, required this.userId, required this.initialStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: AppTheme.primary,
            child: Text('INFORMASI AKUN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0,
            )),
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: LucideIcons.mail, label: 'Email', value: email, isDark: isDark),
          const SizedBox(height: 16),
          _InfoRow(icon: LucideIcons.graduationCap, label: 'Kelas', value: kelas, isDark: isDark),
          const SizedBox(height: 16),
          _InfoRow(icon: LucideIcons.user, label: 'Role', value: role, isDark: isDark),
          const SizedBox(height: 20),
          Container(height: 2, color: Theme.of(context).colorScheme.onSurface.withAlpha(30)),
          const SizedBox(height: 16),
          Text(
            'Pengaturan Status Chat',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyLarge!.color!),
          ),
          const SizedBox(height: 12),
          _StatusDropdown(userId: userId, currentStatus: initialStatus, onStatusChanged: onStatusChanged, isDark: isDark),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyMedium!.color!,
            letterSpacing: 0.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge!.color!),
        ),
      ])),
    ]);
  }
}

class _StatusDropdown extends StatefulWidget {
  final String userId;
  final String currentStatus;
  final VoidCallback onStatusChanged;
  final bool isDark;

  const _StatusDropdown({
    required this.userId,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.isDark,
  });

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late String selectedStatus;
  final List<String> statusOptions = [
    'Available', 'Busy', 'Do Not Disturb', 'Be Right Back', 'Appear Away', 'Appear Offline'
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = statusOptions.contains(widget.currentStatus) ? widget.currentStatus : 'Available';
  }

  @override
  void didUpdateWidget(_StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      selectedStatus = statusOptions.contains(widget.currentStatus) ? widget.currentStatus : 'Available';
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
          const SnackBar(content: Text('Status chat berhasil diperbarui!')));
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
        color: widget.isDark ? Colors.white : AppTheme.textLight),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
        ),
      ),
      items: statusOptions.map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.getStatusColor(status), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(status, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        );
      }).toList(),
      onChanged: (val) { if (val != null) updateStatus(val); },
    );
  }
}

class _ActionSection extends StatelessWidget {
  final bool isDark;
  const _ActionSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: AppTheme.rose,
            child: Text('PENGATURAN KEAMANAN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0,
            )),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black54,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(6, 6))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KELUAR?', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge!.color!)),
                        const SizedBox(height: 8),
                        Text('Kamu yakin ingin logout dari akun ini?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium!.color!)),
                        const SizedBox(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                              ),
                              child: Text('BATAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge!.color!)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.rose,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                              ),
                              child: Text('KELUAR', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
              if (confirm == true) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
                  );
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.rose,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(LucideIcons.logOut, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('KELUAR DARI AKUN', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              ]),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
