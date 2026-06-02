import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
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
import '../../../widgets/jitsi_embed.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- Tailwind Tokens ---------------------------------------------------------
const Color _tertiary = Color(0xFF8D4D33);
const Color _onSecondaryContainer = Color(0xFF3A6D69);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _outline = Color(0xFF717974);
const Color _onBackground = Color(0xFF001E2B);
const Color _background = Color(0xFFF4FAFF);
const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primaryFixedDim = Color(0xFFA3D1B9);
const Color _onSurface = Color(0xFF001E2B);
const Color _primary = Color(0xFF3D6754);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondary = Color(0xFF336763);
const Color _secondaryContainer = Color(0xFFB7EDE7);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _surfaceContainerHighest = Color(0xFFC1E8FF);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _rose = Color(0xFFE11D48);
const Color _error = Color(0xFFEF4444);

BoxDecoration _neoCardDecoration({Color color = _surfaceContainerLowest}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: _onBackground, width: 2),
  boxShadow: const [
    BoxShadow(
      color: _onBackground,
      offset: Offset(4, 4),
      blurRadius: 0,
    ),
  ],
);

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
    final nama = widget.userData['nama']?.split(' ')[0] ?? 'Siswa';
    final namaKelas = widget.teamData['nama_kelas'] ?? 'Kelas';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_liveStatus == 'active' && _currentMeetingId != null) ...[        
                _NeoButtonCard(
                  onTap: () => joinJitsiMeeting(
                    context: context, meetingId: _currentMeetingId!,
                    serverUrl: 'https://meet.ffmuc.net',
                    userName: widget.userData['nama'] ?? 'Siswa',
                    userEmail: widget.userData['email'] ?? '',
                    subject: 'Kelas Live: $namaKelas',
                  ),
                  color: _rose,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _onBackground, width: 2)),
                        child: const Icon(LucideIcons.video, color: _rose, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kelas Sedang Live!', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Ketuk untuk bergabung sekarang', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.arrowRight, color: Colors.white, size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- Header Greeting & Class Name ---------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $nama!', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: _onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Positioned(
                        bottom: -4,
                        left: 0,
                        right: 0,
                        child: Container(height: 12, color: _primaryFixedDim.withAlpha(127)),
                      ),
                      Text(
                        namaKelas.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Attendance Bento Card ---------------------------------------
              Container(
                decoration: _neoCardDecoration(color: _surfaceContainerLowest),
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL KEHADIRAN',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _outline),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('24', style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w900, color: _primary, height: 1.0)),
                            const SizedBox(width: 8),
                            Text('Hari Hadir', style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                    Transform.rotate(
                      angle: 0.785398, // 45 degrees in radians
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primary, width: 4),
                        ),
                        child: Transform.rotate(
                          angle: -0.785398,
                          child: const Icon(Icons.check_circle, color: _primary, size: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Action Menu Grid ---------------------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.0 : 1.1,
                    children: [
                      _MenuCardNeo(
                        label: 'Lihat Tugas',
                        icon: Icons.assignment_outlined,
                        color: _primaryContainer,
                        textColor: _onPrimaryContainer,
                        iconColor: _primary,
                        onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; }),
                      ),
                      _MenuCardNeo(
                        label: 'Riwayat Presensi',
                        icon: Icons.history_outlined,
                        color: _secondaryContainer,
                        textColor: _onSecondaryContainer,
                        iconColor: _secondary,
                        onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; }),
                      ),
                      _MenuCardNeo(
                        label: 'Daftar Kuis & Ujian',
                        icon: Icons.quiz_outlined,
                        color: _tertiaryContainer,
                        textColor: _onTertiaryContainer,
                        iconColor: _tertiary,
                        onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; }),
                      ),
                      _MenuCardNeo(
                        label: 'Materi Ajar',
                        icon: Icons.menu_book_outlined,
                        color: _surfaceContainerHighest,
                        textColor: _onSurface,
                        iconColor: _onSurface,
                        onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi'; }),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return AppShell(
      fullWidth: true,
      child: Row(
        children: [
          // -- Premium Light Sidebar --
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
            child: Container(
              width: 270,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _onSurface, width: 2),
                boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(6, 6))],
              ),
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brand Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _onSurface, width: 2),
                              boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MyPSKD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: _onBackground,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  widget.teamData['nama_kelas'] ?? 'Academic Portal',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 1, color: _onSurface.withAlpha(50), thickness: 2),
                    ),
                    const SizedBox(height: 16),
                    // ── Profile Chip ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _onSurface, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: _primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (widget.userData['nama'] ?? 'S').trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(color: _onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userData['nama'] ?? 'Siswa',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _onBackground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primary,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _onSurface, width: 1),
                                    ),
                                    child: Text(
                                      'SISWA',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 1, color: _onSurface.withAlpha(50), thickness: 2),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'MENU KELAS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _TeamSidebarItemNeo(icon: LucideIcons.layoutDashboard, label: 'Dashboard',
                            isSelected: _activeTabID == 'dashboard', onTap: () => setState(() { _activeTabID = 'dashboard'; _activeTitle = 'Dashboard'; })),
                          const SizedBox(height: 8),
                          _TeamSidebarItemNeo(icon: LucideIcons.userCheck, label: 'Presensi Saya',
                            isSelected: _activeTabID == 'presensi', onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; })),
                          const SizedBox(height: 8),
                          _TeamSidebarItemNeo(icon: LucideIcons.clipboardList, label: 'Tugas Kelas',
                            isSelected: _activeTabID == 'tugas', onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Tugas'; })),
                          const SizedBox(height: 8),
                          _TeamSidebarItemNeo(icon: LucideIcons.helpCircle, label: 'Kuis & Ujian',
                            isSelected: _activeTabID == 'kuis', onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; })),
                          const SizedBox(height: 8),
                          _TeamSidebarItemNeo(icon: LucideIcons.award, label: 'Nilai Saya',
                            isSelected: _activeTabID == 'nilai', onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai'; })),
                          const SizedBox(height: 8),
                          _TeamSidebarItemNeo(icon: LucideIcons.bookOpen, label: 'Materi Pelajaran',
                            isSelected: _activeTabID == 'materi', onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi'; })),
                          const SizedBox(height: 20),
                          Padding(padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text('CHANNELS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _onSurfaceVariant, letterSpacing: 2.0))),
                          _TeamSidebarItemNeo(icon: LucideIcons.hash, label: 'General',
                            isSelected: _activeTabID == 'channel_general', isChannel: true,
                            onTap: () => setState(() { _activeTabID = 'channel_general'; _activeTitle = 'General'; })),
                          for (var c in _channels) ...[
                            const SizedBox(height: 8),
                            _TeamSidebarItemNeo(icon: LucideIcons.hash, label: c['nama_channel'] ?? 'Unnamed',
                              isSelected: _activeTabID == 'channel_${c['id']}', isChannel: true,
                              onTap: () => setState(() { _activeTabID = 'channel_${c['id']}'; _activeTitle = c['nama_channel'] ?? ''; })),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    _TeamLogoutButtonNeo(
                      onLogout: () => Navigator.pop(context),
                      label: 'Kembali',
                      icon: Icons.arrow_back_rounded,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

          Expanded(
            child: ContentSurface(
              child: Column(
                children: [
                  // Topbar � light surface
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

    return Scaffold(
        backgroundColor: _background,
        body: Column(children: [

          // ── HEADER ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _onBackground.withAlpha(40))),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + notif
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _onBackground),
                            boxShadow: const [BoxShadow(
                              color: _onBackground,
                              offset: Offset(2, 2), blurRadius: 0,
                            )],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _onBackground),
                        ),
                      ),
                      const Spacer(),
                      NotificationBell(
                        userData: widget.userData,
                        token: widget.token,
                        iconColor: _onBackground,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Avatar + nama + kelas
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _primaryContainer,
                          border: Border.all(color: _onBackground),
                          boxShadow: const [BoxShadow(
                            color: _onBackground,
                            offset: Offset(2, 2), blurRadius: 0,
                          )],
                        ),
                        child: Center(child: Text(
                          nama[0].toUpperCase(),
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w900, fontSize: 18,
                          ),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $nama',
                            style: GoogleFonts.plusJakartaSans(
                              color: _onSurface,
                              fontWeight: FontWeight.w800, fontSize: 15,
                            )),
                          Text(namaKelas,
                            style: GoogleFonts.inter(
                              color: _onSurfaceVariant, fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // ── CONTENT ─────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_activeTabID),
                child: _getActiveView(),
              ),
            ),
          ),
        ]),

        // ── BOTTOM NAV ────────────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _onBackground.withAlpha(60))),
            ),
            child: Row(
              children: [
                _navItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  id: 'dashboard',
                ),
                _navItem(
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  label: 'Materi',
                  id: 'materi',
                ),
                _navItem(
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Tugas',
                  id: 'tugas',
                ),
                _navItem(
                  icon: Icons.grade_outlined,
                  selectedIcon: Icons.grade_rounded,
                  label: 'Nilai',
                  id: 'nilai',
                ),
                // Menu button
                Expanded(
                  child: GestureDetector(
                    onTap: _showMobileMenu,
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_rounded,
                            size: 22,
                            color: _onSurfaceVariant,
                          ),
                          const SizedBox(height: 3),
                          Text('Menu',
                            style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w600,
                              color: _onSurfaceVariant,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String id,
  }) {
    final isSelected = _activeTabID == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTabID = id;
          _activeTitle = label;
        }),
        child: Container(
          color: isSelected ? _primaryContainer : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? selectedIcon : icon,
                size: 22,
                color: isSelected ? _onPrimaryContainer : _onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? _onPrimaryContainer : _onSurfaceVariant,
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Menu Lainnya',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: _onSurface,
              )),
            const SizedBox(height: 16),
            _buildMenuSheetItem(ctx, 'kuis', Icons.quiz_outlined,
                'Kuis & Ujian', const Color(0xFFF27F33)),
            _buildMenuSheetItem(ctx, 'presensi', Icons.how_to_reg_outlined,
                'Presensi Saya', const Color(0xFF7B83EB)),
            _buildMenuSheetItem(ctx, 'channel_general', Icons.tag_rounded,
                'Channel General', const Color(0xFF10B981)),
            for (var c in _channels)
              _buildMenuSheetItem(ctx, 'channel_${c['id']}', Icons.tag_rounded,
                  c['nama_channel'] ?? 'Channel', const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSheetItem(BuildContext ctx, String id, IconData icon,
      String label, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _onSurface,
        )),
      onTap: () {
        Navigator.pop(ctx);
        setState(() {
          _activeTabID = id;
          _activeTitle = label;
        });
      },
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

class _NeoButtonCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final EdgeInsets padding;

  const _NeoButtonCard({
    required this.child,
    required this.onTap,
    required this.color,
    required this.padding,
  });

  @override
  State<_NeoButtonCard> createState() => _NeoButtonCardState();
}

class _NeoButtonCardState extends State<_NeoButtonCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: _neoCardDecoration(color: widget.color).copyWith(
          boxShadow: _isPressed ? [] : const [BoxShadow(color: _onBackground, offset: Offset(4, 4), blurRadius: 0)],
        ),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

class _MenuCardNeo extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuCardNeo({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _NeoButtonCard(
      onTap: onTap,
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _onBackground, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

class _TeamSidebarItemNeo extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isChannel;

  const _TeamSidebarItemNeo({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isChannel = false,
  });

  @override
  State<_TeamSidebarItemNeo> createState() => _TeamSidebarItemNeoState();
}

class _TeamSidebarItemNeoState extends State<_TeamSidebarItemNeo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? _primaryContainer : (_hovered ? _background : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected || _hovered ? _onSurface : Colors.transparent,
              width: 2,
            ),
            boxShadow: widget.isSelected || _hovered ? const [BoxShadow(color: _onSurface, offset: Offset(2, 2))] : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.isSelected ? _onSurface : (_hovered ? _onSurface : Colors.transparent), width: 1.5),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? Colors.white : _onSurfaceVariant,
                  size: widget.isChannel ? 16 : 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isSelected ? _onBackground : _onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _onSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _onSurface, width: 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLogoutButtonNeo extends StatefulWidget {
  final VoidCallback onLogout;
  final String label;
  final IconData icon;

  const _TeamLogoutButtonNeo({required this.onLogout, required this.label, required this.icon});

  @override
  State<_TeamLogoutButtonNeo> createState() => _TeamLogoutButtonNeoState();
}

class _TeamLogoutButtonNeoState extends State<_TeamLogoutButtonNeo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onLogout,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            transform: Matrix4.translationValues(
              _hovered ? 2 : 0,
              _hovered ? 2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              color: _error,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _onSurface, width: 2),
              boxShadow: _hovered ? [] : const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
