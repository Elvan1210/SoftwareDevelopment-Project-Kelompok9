import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/login_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../shared/crop_screen.dart';
import '../../../widgets/avatar_widget.dart';

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
    final String role = _userData['role'] ?? 'Guru';
    final String currentStatus = _userData['status'] ?? 'Available';
    final String photoUrl = _userData['photoUrl'] ?? '';
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
              _ProfileHeroHeader(initials: initials, nama: nama, role: role, primaryColor: primaryColor, isDark: isDark, photoUrl: photoUrl, onUpdated: _loadUserData),
              const SizedBox(height: 32),
              Padding(
                padding: padding,
                child: isWide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _InfoSection(
                          email: email, 
                          userId: userId, initialStatus: currentStatus,
                          onStatusChanged: _loadUserData, isDark: isDark,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _LogoutSection(isDark: isDark)),
                      ])
                    : Column(children: [
                        _InfoSection(
                          email: email, 
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

class _ProfileHeroHeader extends StatefulWidget {
  final String initials, nama, role;
  final Color primaryColor;
  final bool isDark;
  final String photoUrl;
  final VoidCallback onUpdated;

  const _ProfileHeroHeader({
    required this.initials, required this.nama, required this.role,
    required this.primaryColor, required this.isDark,
    required this.photoUrl, required this.onUpdated,
  });

  @override
  State<_ProfileHeroHeader> createState() => _ProfileHeroHeaderState();
}

class _ProfileHeroHeaderState extends State<_ProfileHeroHeader> {
  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 40, left: 32, right: 32),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        border: Border(
          bottom: BorderSide(color: Colors.black.withAlpha(160), width: 2),
        ),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: _pickAndCropImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(
                initial: widget.initials,
                photoUrl: widget.photoUrl,
                size: 96,
                bgColor: Colors.white,
                textColor: widget.primaryColor,
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.nama,
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
            widget.role.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String email, userId, initialStatus;
  final VoidCallback onStatusChanged;
  final bool isDark;

  const _InfoSection({
    required this.email, 
    required this.userId, required this.initialStatus, required this.onStatusChanged,
    required this.isDark,
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: AppTheme.primary,
          child: Text('INFORMASI AKUN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0,
          )),
        ),
        const SizedBox(height: 20),
        _row(context, LucideIcons.mail, 'Email', email),
        const SizedBox(height: 20),
        Container(
          height: 2,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
        ),
        const SizedBox(height: 16),
        Text(
          'Pengaturan Status Chat',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.bodyLarge!.color!),
        ),
        const SizedBox(height: 12),
        _StatusDropdown(userId: userId, currentStatus: initialStatus, onStatusChanged: onStatusChanged, isDark: isDark),
      ]),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _row(BuildContext ctx, IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          border: Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 1.5),
          boxShadow: [BoxShadow(color: Theme.of(ctx).colorScheme.onSurface, offset: const Offset(2, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800,
            color: Theme.of(ctx).textTheme.bodyMedium!.color!,
            letterSpacing: 0.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800,
            color: Theme.of(ctx).textTheme.bodyLarge!.color!),
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
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
        color: widget.isDark ? Colors.white : AppTheme.textLight),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.indigoPrimary, width: 2),
        ),
      ),
      items: statusOptions.map((status) => DropdownMenuItem(
        value: status,
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.getStatusColor(status), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(status, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            final ok = await showDialog<bool>(
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
                        fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge!.color!,
                      )),
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
                              boxShadow: [BoxShadow(color: Theme.of(ctx).colorScheme.onSurface, offset: const Offset(2, 2))],
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
                              boxShadow: [BoxShadow(color: Theme.of(ctx).colorScheme.onSurface, offset: const Offset(2, 2))],
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
            if (ok == true) {
              await AuthService.logout();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
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
      ]),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
