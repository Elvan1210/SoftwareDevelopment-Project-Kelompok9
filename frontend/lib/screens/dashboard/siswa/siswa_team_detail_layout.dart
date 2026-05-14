import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_view.dart';
import 'siswa_materi_view.dart';
import 'siswa_nilai_view.dart';
import 'siswa_presensi_view.dart';
import 'siswa_quiz_view.dart';
import '../shared/saluran_view.dart';
import '../../../config/api_config.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SiswaTeamDetailLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const SiswaTeamDetailLayout({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<SiswaTeamDetailLayout> createState() => _SiswaTeamDetailLayoutState();
}

class _SiswaTeamDetailLayoutState extends State<SiswaTeamDetailLayout> {
  String _activeTabID = 'dashboard'; 
  String _activeTitle = 'Dashboard Kelas';
  List<dynamic> _channels = [];

  String get _kelasId => widget.teamData['id']?.toString() ?? '';

  @override
void initState() {
  super.initState();
  _fetchChannels();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.panelLeftOpen, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Geser dari kiri untuk lihat menu kelas',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  });
}

  Future<void> _fetchChannels() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/channels?kelas_id=$_kelasId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        if (mounted) setState(() => _channels = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Err fetch channel: $e');
    }
  }

  Widget _getActiveView() {
    if (_activeTabID.startsWith('channel_')) {
      final cId = _activeTabID.replaceFirst('channel_', '');
      return SaluranView(
        userData: widget.userData,
        token: widget.token,
        teamData: widget.teamData,
        channelId: cId,
        channelName: _activeTitle,
      );
    }
    
    switch (_activeTabID) {
      case 'dashboard': return _buildDashboardView();
      case 'presensi': return SiswaPresensiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'tugas': return SiswaTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'kuis': return SiswaQuizView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'nilai': return SiswaNilaiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'materi': return SiswaMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      default: return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.layoutDashboard, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            Text(
              'Dashboard ${widget.teamData['nama_kelas']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Ringkasan aktivitas akan muncul di sini', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebarHeader(context, theme),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildSidebarItem('dashboard', LucideIcons.layoutDashboard, 'Dashboard'),
                          _buildSidebarItem('presensi', LucideIcons.userCheck, 'Presensi Saya'),
                          _buildSidebarItem('tugas', LucideIcons.clipboardList, 'Tugas Kelas'),
                          _buildSidebarItem('kuis', LucideIcons.helpCircle, 'Kuis & Ujian'),
                          _buildSidebarItem('nilai', LucideIcons.award, 'Nilai Saya'),
                          _buildSidebarItem('materi', LucideIcons.bookOpen, 'Materi Pelajaran'),
                          
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withAlpha(160), letterSpacing: 1.5)),
                          ),
                          _buildSidebarItem('channel_general', LucideIcons.hash, 'General', isChannel: true),
                          for (var c in _channels)
                            _buildSidebarItem('channel_${c['id']}', LucideIcons.hash, c['nama_channel'] ?? 'Unnamed', isChannel: true),
                            
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    _buildSidebarFooter(theme),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

            const SizedBox(width: 28),

            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.chevronLeft, size: 20),
                    ),
                    title: Text(
                      _activeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ).animate(key: ValueKey(_activeTabID)).fade(duration: 400.ms).slideX(begin: -0.05),
                    actions: [
                      const ThemeToggle(),
                      const SizedBox(width: 8),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token,
                        iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(_activeTabID),
                      child: _getActiveView(),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 150.ms).slideX(begin: 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
            child: Icon(LucideIcons.graduationCap, color: theme.primaryColor, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            widget.teamData['nama_kelas'] ?? 'Mata Pelajaran',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String id, IconData icon, String label, {bool isChannel = false}) {
    final theme = Theme.of(context);
    final isSelected = _activeTabID == id;
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(160);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() {
          _activeTabID = id;
          _activeTitle = label;
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: isChannel ? 18 : 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(ThemeData theme) {
    return Padding(padding: EdgeInsets.all(24.0), child: Text('Siswa Access', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))));
  }

 Widget _buildMobileLayout(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return AppShell(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _activeTitle,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          const ThemeToggle(),
          NotificationBell(
            userData: widget.userData,
            token: widget.token,
            iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _buildSidebarHeader(context, theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSidebarItem('dashboard', LucideIcons.layoutDashboard, 'Dashboard'),
                    _buildSidebarItem('presensi', LucideIcons.userCheck, 'Presensi Saya'),
                    _buildSidebarItem('tugas', LucideIcons.clipboardList, 'Tugas Kelas'),
                    _buildSidebarItem('kuis', LucideIcons.helpCircle, 'Kuis & Ujian'),
                    _buildSidebarItem('nilai', LucideIcons.award, 'Nilai Saya'),
                    _buildSidebarItem('materi', LucideIcons.bookOpen, 'Materi Pelajaran'),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text('CHANNELS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface.withAlpha(160), letterSpacing: 1.5)),
                    ),
                    _buildSidebarItem('channel_general', LucideIcons.hash, 'General', isChannel: true),
                    for (var c in _channels)
                      _buildSidebarItem('channel_${c['id']}', LucideIcons.hash,
                          c['nama_channel'] ?? 'Unnamed', isChannel: true),
                  ],
                ),
              ),
              _buildSidebarFooter(theme),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_activeTabID),
          child: _getActiveView(),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1100) return _buildWebLayout(context);
      return _buildMobileLayout(context);
    });
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? overrideColor;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24, this.overrideColor});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: overrideColor ?? (isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(180)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withAlpha(160)),
      ),
      child: child,
    );
  }
}