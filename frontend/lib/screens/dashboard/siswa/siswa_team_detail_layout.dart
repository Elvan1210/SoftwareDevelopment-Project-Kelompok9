import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'siswa_tugas_view.dart';
import 'siswa_materi_view.dart';
import 'siswa_nilai_view.dart';
import 'siswa_presensi_view.dart';
import '../shared/saluran_view.dart';
import '../../../config/api_config.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';

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
      final name = _activeTitle;
      return SaluranView(
        userData: widget.userData,
        token: widget.token,
        teamData: widget.teamData,
        channelId: cId,
        channelName: name,
      );
    }
    
    switch (_activeTabID) {
      case 'dashboard': return _buildDashboardView();
      case 'saluran': return SaluranView(userData: widget.userData, token: widget.token, teamData: widget.teamData, channelId: 'general', channelName: 'Groupchat Kelas');
      case 'presensi': return SiswaPresensiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'tugas': return SiswaTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'nilai': return SiswaNilaiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'materi': return SiswaMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      default: return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Center(
      child: GlassCard(
        blurSigma: 24,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            Text(
              'Dashboard ${widget.teamData['nama_kelas']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Ringkasan aktivitas akan muncul di sini',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
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
            // ── Sidebar ──
            SizedBox(
              width: 280,
              child: GlassCard(
                blurSigma: 24,
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
                          _buildSidebarItem('dashboard', Icons.dashboard_customize_outlined, 'Dashboard'),
                          _buildSidebarItem('saluran', Icons.forum_outlined, 'Saluran'),
                          _buildSidebarItem('presensi', Icons.how_to_reg_outlined, 'Presensi Saya'),
                          _buildSidebarItem('tugas', Icons.assignment_outlined, 'Tugas Kelas'),
                          _buildSidebarItem('nilai', Icons.military_tech_outlined, 'Nilai Saya'),
                          _buildSidebarItem('materi', Icons.auto_stories_outlined, 'Materi Pelajaran'),
                          
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withAlpha(100), letterSpacing: 1.5)),
                          ),
                          if (_channels.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 14, top: 4),
                              child: Text('Belum ada channel', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(100))),
                            ),
                          for (var c in _channels)
                            _buildSidebarItem('channel_${c['id']}', Icons.tag_rounded, c['nama_channel'] ?? 'Unnamed', isChannel: true),
                            
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

            // ── Main Content Area ──
            Expanded(
              child: GlassCard(
                blurSigma: 16,
                padding: EdgeInsets.zero,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInQuart,
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
            child: Icon(Icons.school_rounded, color: theme.primaryColor, size: 28),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            widget.teamData['nama_kelas'] ?? 'Mata Pelajaran',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            widget.teamData['guru_nama'] ?? 'Pengajar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String id, IconData icon, String label, {bool isChannel = false}) {
    final theme = Theme.of(context);
    final isSelected = _activeTabID == id;
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(120);

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
            color: isSelected ? theme.primaryColor.withAlpha(isSelected ? 20 : 0) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? theme.primaryColor.withAlpha(40) : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: isChannel ? 18 : 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label, 
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color, 
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected && !isChannel) const Spacer(),
              if (isSelected && !isChannel) 
                Container(
                  width: 6, height: 6, 
                  decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                ).animate().scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassCard(
        radius: 16,
        blurSigma: 0, 
        padding: const EdgeInsets.all(12),
        overrideColor: theme.primaryColor.withAlpha(15),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Text('Premium Access', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Stack(
        children: [
          Column(
            children: [
              // Custom Floating AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GlassCard(
                  radius: 20,
                  blurSigma: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _activeTitle,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          overflow: TextOverflow.ellipsis,
                        ).animate(key: ValueKey(_activeTabID)).fade(),
                      ),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token,
                        iconColor: theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Animated Body Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_activeTabID),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: _getActiveView(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Nav / Action Sheet for Mobile ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassCard(
              radius: 24,
              blurSigma: 24,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMobileNavItem('dashboard', Icons.dashboard_customize_outlined, 'Home'),
                  _buildMobileNavItem('saluran', Icons.forum_outlined, 'Saluran'),
                  _buildMobileNavItem('tugas', Icons.assignment_outlined, 'Tugas'),
                  _buildMobileNavItem('materi', Icons.auto_stories_outlined, 'Materi'),
                  IconButton(
                    onPressed: () => _showMobileMenu(theme),
                    icon: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface.withAlpha(150)),
                  ),
                ],
              ),
            ),
          ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }

  void _showMobileMenu(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Menu Lainnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _buildSidebarItem('presensi', Icons.how_to_reg_outlined, 'Presensi Saya'),
              _buildSidebarItem('nilai', Icons.military_tech_outlined, 'Nilai Saya'),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withAlpha(100), letterSpacing: 1.5)),
              ),
              if (_channels.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 4),
                  child: Text('Belum ada channel', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(100))),
                ),
              for (var c in _channels)
                _buildSidebarItem('channel_${c['id']}', Icons.tag_rounded, c['nama_channel'] ?? 'Unnamed', isChannel: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(String id, IconData icon, String fallbackLabel) {
    final theme = Theme.of(context);
    final isSelected = _activeTabID == id;
    final color = isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(100);

    return InkWell(
      onTap: () => setState(() {
        _activeTabID = id;
        _activeTitle = fallbackLabel;
      }),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 24),
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
