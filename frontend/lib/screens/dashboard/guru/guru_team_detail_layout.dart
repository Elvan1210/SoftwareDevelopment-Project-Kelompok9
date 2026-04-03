import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_view.dart';
import 'guru_nilai_view.dart';
import 'guru_materi_view.dart';
import 'guru_presensi_view.dart';
import 'guru_pending_requests_view.dart';
import '../shared/saluran_view.dart';
import '../../../config/api_config.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';

class GuruTeamDetailLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const GuruTeamDetailLayout({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruTeamDetailLayout> createState() => _GuruTeamDetailLayoutState();
}

class _GuruTeamDetailLayoutState extends State<GuruTeamDetailLayout> {
  String _activeTabID = 'dashboard'; 
  String _activeTitle = 'Dashboard Tim';
  int _pendingCount = 0;

  List<dynamic> _channels = [];
  final TextEditingController _channelNameCtrl = TextEditingController();

  String get _kelasId => widget.teamData['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
    _fetchChannels();
  }

  @override
  void dispose() {
    _channelNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas/$_kelasId/pending'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pending = data['pending_requests'] as List? ?? [];
        if (mounted) {
          setState(() => _pendingCount = pending.length);
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending count: $e');
    }
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

  Future<void> _buatChannel() async {
    final name = _channelNameCtrl.text.trim();
    if (name.isEmpty) return;

    final body = {
      'kelas_id': _kelasId,
      'nama_channel': name,
      'created_by_id': widget.userData['id'] ?? widget.userData['uid'] ?? '',
      'waktu': DateTime.now().toIso8601String(),
    };

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/channels'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        if (mounted) {
          _channelNameCtrl.clear();
          Navigator.pop(context);
          _fetchChannels();
        }
      }
    } catch (e) {
      debugPrint('Err buat channel: $e');
    }
  }

  void _showCreateChannelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buat Channel Baru', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: _channelNameCtrl,
          decoration: InputDecoration(
            hintText: 'Misal: Praktikum 01',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withAlpha(50),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _buatChannel(),
            child: const Text('Buat', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
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
      case 'permintaan': return GuruPendingRequestsView(userData: widget.userData, token: widget.token, teamData: widget.teamData, onRequestsChanged: _fetchPendingCount);
      case 'presensi': return GuruPresensiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'tugas': return GuruTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'nilai': return GuruNilaiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'materi': return GuruMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
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
            Icon(Icons.hub_rounded, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            Text(
              'Ruang Guru: ${widget.teamData['nama_kelas']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola materi, tugas, dan kehadiran siswa di sini.',
              textAlign: TextAlign.center,
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
                          _buildSidebarItem('dashboard', Icons.hub_outlined, 'Dashboard'),
                          _buildSidebarItem('saluran', Icons.forum_outlined, 'Saluran'),
                          _buildSidebarItem('permintaan', Icons.person_add_alt_rounded, 'Permintaan', badgeCount: _pendingCount),
                          _buildSidebarItem('presensi', Icons.how_to_reg_outlined, 'Presensi Kelas'),
                          _buildSidebarItem('tugas', Icons.assignment_outlined, 'Penugasan'),
                          _buildSidebarItem('nilai', Icons.military_tech_outlined, 'Nilai Siswa'),
                          _buildSidebarItem('materi', Icons.auto_stories_outlined, 'Materi Ajar'),
                          
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withAlpha(100), letterSpacing: 1.5)),
                                InkWell(
                                  onTap: _showCreateChannelDialog,
                                  child: Icon(Icons.add, size: 16, color: theme.colorScheme.onSurface.withAlpha(150)),
                                )
                              ],
                            ),
                          ),
                          // List sub channels (Saluran is already at the top)
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
            child: Icon(Icons.psychology_rounded, color: theme.primaryColor, size: 28),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            widget.teamData['nama_kelas'] ?? 'Ruang Kelas',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            widget.teamData['kode_kelas'] ?? 'GURU-CORE',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String id, IconData icon, String label, {int badgeCount = 0, bool isChannel = false}) {
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
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF27F33), borderRadius: BorderRadius.circular(100)),
                  child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ).animate().scale(curve: Curves.easeOutBack)
              else if (isSelected && !isChannel)
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
            Icon(Icons.workspace_premium_rounded, color: theme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Text('Guru Premium', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
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
                  _buildMobileNavItem('dashboard', Icons.hub_outlined, 'Home'),
                  _buildMobileNavItem('saluran', Icons.forum_outlined, 'Saluran'),
                  _buildMobileNavItem('permintaan', Icons.person_add_alt_rounded, 'Permintaan', badgeCount: _pendingCount),
                  _buildMobileNavItem('tugas', Icons.assignment_outlined, 'Tugas'),
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
              _buildSidebarItem('presensi', Icons.how_to_reg_outlined, 'Presensi Kelas'),
              _buildSidebarItem('nilai', Icons.military_tech_outlined, 'Nilai Siswa'),
              _buildSidebarItem('materi', Icons.auto_stories_outlined, 'Materi Ajar'),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withAlpha(100), letterSpacing: 1.5)),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCreateChannelDialog();
                    },
                    child: Icon(Icons.add, size: 16, color: theme.colorScheme.onSurface.withAlpha(150)),
                  )
                ],
              ),
              const SizedBox(height: 8),
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

  Widget _buildMobileNavItem(String id, IconData icon, String fallbackLabel, {int badgeCount = 0}) {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 24),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFF27F33), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                ).animate().scale(),
              ),
          ],
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
