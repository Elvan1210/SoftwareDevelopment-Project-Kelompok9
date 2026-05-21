import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'siswa_tugas_view.dart';
import 'siswa_materi_view.dart';
import 'siswa_nilai_view.dart';
import 'siswa_presensi_view.dart';
import 'siswa_quiz_view.dart';
import '../shared/saluran_view.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';
import '../../../widgets/neo_brutalism.dart';
import '../../../widgets/jitsi_embed.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  String _liveStatus = 'inactive';
  String? _currentMeetingId;
  Timer? _pollTimer;

  String get _kelasId => widget.teamData['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchChannels();
    _fetchLiveStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchLiveStatus());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final isM = MediaQuery.of(context).size.width <= 600;
        if (isM){
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
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/kelas/$_kelasId/live-status'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _liveStatus = data['live_status'] ?? 'inactive';
            _currentMeetingId = data['meeting_id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Err fetch live status: $e');
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
    final nama = widget.userData['nama'] ?? 'Siswa';
    final namaKelas = widget.teamData['nama_kelas'] ?? 'Kelas';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_liveStatus == 'active' && _currentMeetingId != null) ...[        
            NeoLiveBanner(onJoin: () => joinJitsiMeeting(
              context: context, meetingId: _currentMeetingId!,
              serverUrl: 'https://meet.ffmuc.net',
              userName: widget.userData['nama'] ?? 'Siswa',
              userEmail: widget.userData['email'] ?? '',
              subject: 'Kelas Live: $namaKelas',
            )),
            const SizedBox(height: 16),
          ],

          NeoWelcomeBanner(
            greeting: 'Selamat datang kembali 👋',
            name: nama,
            subtitle: namaKelas,
            
          ),

          const SizedBox(height: 20),

          // Stat cards
          Row(children: [
            Expanded(child: NeoStatCard(
              label: 'Presensi', value: '—/—', icon: LucideIcons.userCheck,
              color: AppTheme.primary,
              onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; }),
            )),
            const SizedBox(width: 10),
            Expanded(child: NeoStatCard(
              label: 'Tugas', value: 'Lihat', icon: LucideIcons.clipboardList,
              color: AppTheme.success,
              onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; }),
            )),
            const SizedBox(width: 10),
            Expanded(child: NeoStatCard(
              label: 'Nilai', value: '—', icon: LucideIcons.award,
              color: AppTheme.warning,
              onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai'; }),
            )),
          ]),

          const SizedBox(height: 24),
          const NeoSectionHeader(title: 'Menu Kelas'),

          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            children: [
              NeoMenuCard(label: 'Presensi', icon: LucideIcons.userCheck,
                color: AppTheme.primary,
                onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; })),
              NeoMenuCard(label: 'Tugas', icon: LucideIcons.clipboardList,
                color: AppTheme.success,
                onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; })),
              NeoMenuCard(label: 'Kuis & Ujian', icon: LucideIcons.helpCircle,
                color: AppTheme.error,
                onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; })),
              NeoMenuCard(label: 'Materi', icon: LucideIcons.bookOpen,
                color: AppTheme.info,
                onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi'; })),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return AppShell(
      fullWidth: true,
      child: Row(
        children: [
          // ── Cosmic Sidebar ──
          SizedBox(
            width: 260,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B27) : const Color(0xFFF9FAFB),
                border: Border(right: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB))),
              ),
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('MyPSKD', style: TextStyle(color: CosmicColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ]),
                        const SizedBox(height: 20),
                        Text(widget.teamData['nama_kelas'] ?? 'Mata Pelajaran',
                          style: const TextStyle(color: CosmicColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(widget.teamData['kode_kelas'] ?? '', style: const TextStyle(color: CosmicColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          NeoSidebarItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard',
                            isSelected: _activeTabID == 'dashboard', onTap: () => setState(() { _activeTabID = 'dashboard'; _activeTitle = 'Dashboard'; })),
                          NeoSidebarItem(icon: LucideIcons.userCheck, label: 'Presensi Saya',
                            isSelected: _activeTabID == 'presensi', onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; })),
                          NeoSidebarItem(icon: LucideIcons.clipboardList, label: 'Tugas Kelas',
                            isSelected: _activeTabID == 'tugas', onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; })),
                          NeoSidebarItem(icon: LucideIcons.helpCircle, label: 'Kuis & Ujian',
                            isSelected: _activeTabID == 'kuis', onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; })),
                          NeoSidebarItem(icon: LucideIcons.award, label: 'Nilai Saya',
                            isSelected: _activeTabID == 'nilai', onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai'; })),
                          NeoSidebarItem(icon: LucideIcons.bookOpen, label: 'Materi Pelajaran',
                            isSelected: _activeTabID == 'materi', onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi'; })),
                          const SizedBox(height: 20),
                          Padding(padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Text('CHANNELS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(100), letterSpacing: 1.5))),
                          NeoSidebarItem(icon: LucideIcons.hash, label: 'General',
                            isSelected: _activeTabID == 'channel_general', isChannel: true,
                            onTap: () => setState(() { _activeTabID = 'channel_general'; _activeTitle = 'General'; })),
                          for (var c in _channels)
                            NeoSidebarItem(icon: LucideIcons.hash, label: c['nama_channel'] ?? 'Unnamed',
                              isSelected: _activeTabID == 'channel_${c['id']}', isChannel: true,
                              onTap: () => setState(() { _activeTabID = 'channel_${c['id']}'; _activeTitle = c['nama_channel'] ?? ''; })),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 16,
                          backgroundColor: CosmicColors.violet.withAlpha(80),
                          child: Text((widget.userData['nama'] ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.userData['nama'] ?? 'Siswa',
                            style: const TextStyle(color: CosmicColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                          const Text('Siswa', style: TextStyle(color: CosmicColors.textMuted, fontSize: 11)),
                        ])),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

          Expanded(
            child: ContentSurface(
              child: Column(
                children: [
                  // Topbar — adaptive surface
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B27) : Colors.white,
                      border: Border(bottom: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                      )),
                    ),
                    child: Row(children: [
                      IconButton(onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, 
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                          size: 18)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_activeTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 17, 
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textLight, 
                          letterSpacing: -0.3))
                        .animate(key: ValueKey(_activeTabID)).fade(duration: 250.ms).slideX(begin: -0.03)),
                      const ThemeToggle(),
                      const SizedBox(width: 8),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token, 
                        iconColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt
                      ),
                      const SizedBox(width: 8),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(key: ValueKey(_activeTabID), child: _getActiveView()),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 150.ms),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final nama = widget.userData['nama'] ?? 'Siswa';
    final namaKelas = widget.teamData['nama_kelas'] ?? 'Kelas';

    return AppShell(
      child: ContentSurface(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Mobile header — adaptive
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B27) : Colors.white,
                  border: Border(bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                  )),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, 
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                            size: 20),
                          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        NotificationBell(
                          userData: widget.userData, 
                          token: widget.token, 
                          iconColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt
                        ),
                        const SizedBox(width: 8),
                        const ThemeToggle(),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.indigoPrimary.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.indigoPrimary.withAlpha(80)),
                          ),
                          child: Center(child: Text(nama[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.indigoPrimary, fontWeight: FontWeight.w900, fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Halo, $nama',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textLight, 
                              fontWeight: FontWeight.w800, 
                              fontSize: 16)),
                          Text(namaKelas,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500)),
                        ])),
                      ]),
                    ]),
                  ),
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey(_activeTabID),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 88),
                      child: _getActiveView(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2060) : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 15), 
                      blurRadius: 20, 
                      spreadRadius: 2, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NeoPillNavItem(icon: LucideIcons.layoutDashboard, label: 'Home',
                      isSelected: _activeTabID == 'dashboard', onTap: () => setState(() { _activeTabID = 'dashboard'; _activeTitle = 'Dashboard'; })),
                    NeoPillNavItem(icon: LucideIcons.clipboardList, label: 'Tugas',
                      isSelected: _activeTabID == 'tugas', onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; })),
                    NeoPillNavItem(icon: LucideIcons.helpCircle, label: 'Kuis',
                      isSelected: _activeTabID == 'kuis', onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; })),
                    NeoPillNavItem(icon: LucideIcons.bookOpen, label: 'Materi',
                      isSelected: _activeTabID == 'materi', onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi'; })),
                    NeoPillNavItem(icon: LucideIcons.award, label: 'Nilai',
                      isSelected: _activeTabID == 'nilai', onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai'; })),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) return _buildWebLayout(context);
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
        color: overrideColor ?? (Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withAlpha(isDark ? 15 : 20), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
