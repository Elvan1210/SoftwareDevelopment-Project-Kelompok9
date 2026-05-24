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
            GestureDetector(
              onTap: () => joinJitsiMeeting(
                context: context, meetingId: _currentMeetingId!,
                serverUrl: 'https://meet.ffmuc.net',
                userName: widget.userData['nama'] ?? 'Siswa',
                userEmail: widget.userData['email'] ?? '',
                subject: 'Kelas Live: $namaKelas',
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.rose, Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppTheme.rose.withAlpha(60), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.video, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kelas Sedang Live!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('Ketuk untuk bergabung sekarang', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]
                  )),
                  const Icon(LucideIcons.chevronRight, color: Colors.white),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Welcome Banner Premium
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.indigoPrimary, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(100)),
                  child: const Text('SELAMAT DATANG KEMBALI 👋', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 16),
                Text(nama, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(namaKelas, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stat cards
          Row(children: [
            Expanded(child: _buildStatCard('Presensi', '—/—', LucideIcons.userCheck, AppTheme.primary, 'presensi')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Tugas', 'Lihat', LucideIcons.clipboardList, AppTheme.success, 'tugas')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Nilai', '—', LucideIcons.award, AppTheme.warning, 'nilai')),
          ]),

          const SizedBox(height: 28),
          const Text('Menu Kelas', style: TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildMenuCard('Presensi', LucideIcons.userCheck, AppTheme.primary, 'presensi'),
              _buildMenuCard('Tugas', LucideIcons.clipboardList, AppTheme.success, 'tugas'),
              _buildMenuCard('Kuis & Ujian', LucideIcons.helpCircle, AppTheme.error, 'kuis'),
              _buildMenuCard('Materi', LucideIcons.bookOpen, AppTheme.info, 'materi'),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String tabId) {
    return GestureDetector(
      onTap: () => setState(() { _activeTabID = tabId; _activeTitle = label; }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMutedLt, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(String label, IconData icon, Color color, String tabId) {
    return GestureDetector(
      onTap: () => setState(() { _activeTabID = tabId; _activeTitle = label; }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return AppShell(
      fullWidth: true,
      child: Row(
        children: [
          // ── Premium Light Sidebar ──
          SizedBox(
            width: 260,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppTheme.lightBorder)),
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
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.graduationCap, color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('MyPSKD', style: TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ]),
                        const SizedBox(height: 20),
                        Text(widget.teamData['nama_kelas'] ?? 'Mata Pelajaran',
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(widget.teamData['kode_kelas'] ?? '', style: const TextStyle(color: AppTheme.textMutedLt, fontSize: 12, fontWeight: FontWeight.w500)),
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
                            child: Text('CHANNELS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMutedLt.withAlpha(160), letterSpacing: 1.5))),
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
                    // User info footer
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.lightBorder, width: 1.0),
                      ),
                      child: Row(children: [
                        CircleAvatar(radius: 16,
                          backgroundColor: AppTheme.primary.withAlpha(25),
                          child: Text((widget.userData['nama'] ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.userData['nama'] ?? 'Siswa',
                            style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                          const Text('Siswa', style: TextStyle(color: AppTheme.textMutedLt, fontSize: 11)),
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
                  // Topbar — light surface
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppTheme.lightBorder)),
                    ),
                    child: Row(children: [
                      IconButton(onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, 
                          color: AppTheme.textMutedLt, 
                          size: 18)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_activeTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700, 
                          fontSize: 17, 
                          color: AppTheme.textLight, 
                          letterSpacing: -0.3))
                        .animate(key: ValueKey(_activeTabID)).fade(duration: 250.ms).slideX(begin: -0.03)),
                      NotificationBell(
                        userData: widget.userData, 
                        token: widget.token, 
                        iconColor: AppTheme.textMutedLt
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
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Mobile header — premium light
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.lightBorder)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
                            color: AppTheme.textMutedLt, 
                            size: 20),
                          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                        ),
                        const Spacer(),
                        NotificationBell(
                          userData: widget.userData, 
                          token: widget.token, 
                          iconColor: AppTheme.textMutedLt
                        ),
                        const SizedBox(width: 8),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.indigoPrimary.withAlpha(20),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.indigoPrimary.withAlpha(60)),
                          ),
                          child: Center(child: Text(nama[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.indigoPrimary, fontWeight: FontWeight.w900, fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Halo, $nama',
                            style: const TextStyle(
                              color: AppTheme.textLight, 
                              fontWeight: FontWeight.w800, 
                              fontSize: 16)),
                          Text(namaKelas,
                            style: const TextStyle(
                              color: AppTheme.textMutedLt, 
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
                    child: _getActiveView(),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppTheme.lightBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(15), 
                      blurRadius: 20, 
                      spreadRadius: 2, 
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(LucideIcons.layoutDashboard, 'Home', 'dashboard'),
                    _buildNavItem(LucideIcons.clipboardList, 'Tugas', 'tugas'),
                    _buildNavItem(LucideIcons.helpCircle, 'Kuis', 'kuis'),
                    _buildNavItem(LucideIcons.bookOpen, 'Materi', 'materi'),
                    _buildNavItem(LucideIcons.award, 'Nilai', 'nilai'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String tabId) {
    final isSelected = _activeTabID == tabId;
    return GestureDetector(
      onTap: () => setState(() {
        _activeTabID = tabId;
        _activeTitle = label;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 14 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.textMutedLt, size: 18),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ],
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: overrideColor ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withAlpha(15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
