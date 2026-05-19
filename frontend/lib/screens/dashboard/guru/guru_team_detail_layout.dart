import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_view.dart';
import 'guru_nilai_view.dart';
import 'guru_materi_view.dart';
import 'guru_presensi_view.dart';
import 'guru_pending_requests_view.dart';
import 'guru_quiz_view.dart';
import '../shared/saluran_view.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/theme_toggle.dart';
import '../../../widgets/jitsi_embed.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _liveStatus = 'inactive';
  String? _currentMeetingId;

  List<dynamic> _channels = [];
  final TextEditingController _channelNameCtrl = TextEditingController();

  String get _kelasId => widget.teamData['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
    _fetchChannels();
    _fetchLiveStatus();
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

  Future<void> _endLiveClass() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/kelas/$_kelasId/end-live'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() => _liveStatus = 'inactive');
        }
      }
    } catch (e) {
      debugPrint('Err end live class: $e');
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

  Future<void> _hapusChannel(String channelId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/channels/$channelId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        if (_activeTabID == 'channel_$channelId') {
          setState(() {
            _activeTabID = 'channel_general';
            _activeTitle = 'General';
          });
        }
        _fetchChannels();
      }
    } catch (e) {
      debugPrint('Err hapus channel: $e');
    }
  }

  void _confirmDeleteChannel(String channelId, String channelName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Channel', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Anda yakin ingin menghapus channel "$channelName"? Semua obrolan di dalamnya akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          PremiumElevatedButton(
            color: Colors.red,
            textColor: Colors.white,
            radius: 8,
            onPressed: () {
              Navigator.pop(ctx);
              _hapusChannel(channelId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
          PremiumElevatedButton(
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            radius: 12,
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
      case 'permintaan': return GuruPendingRequestsView(userData: widget.userData, token: widget.token, teamData: widget.teamData, onRequestsChanged: _fetchPendingCount);
      case 'presensi': return GuruPresensiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'tugas': return GuruTugasView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'kuis': return GuruQuizView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'nilai': return GuruNilaiView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      case 'materi': return GuruMateriView(userData: widget.userData, token: widget.token, teamData: widget.teamData);
      default: return _buildDashboardView();
    }
  }

  Future<void> _startLiveClass() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/kelas/$_kelasId/live-url'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meetingId = data['meetingId'];
        if (meetingId != null) {
          if (mounted) {
            setState(() {
              _liveStatus = 'active';
              _currentMeetingId = meetingId;
            });
          }
          if (!mounted) return;
          await joinJitsiMeeting(
            context: context,
            meetingId: meetingId,
            serverUrl: 'https://meet.ffmuc.net',
            userName: widget.userData['nama'] ?? 'Guru',
            userEmail: widget.userData['email'] ?? '',
            subject: 'Kelas Live: ${widget.teamData['nama_kelas']}',
            onClosed: _endLiveClass,
          );
        }
      }
    } catch (e) {
      debugPrint('Err start live class: $e');
    }
  }

  Widget _buildDashboardView() {
    final nama = widget.userData['nama'] ?? 'Guru';
    final namaKelas = widget.teamData['nama_kelas'] ?? 'Kelas';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kodeKelas = widget.teamData['kode_kelas']?.toString() ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CosmicWelcomeBanner(
            greeting: 'Mode Pengajar 🏫',
            name: nama,
            subtitle: namaKelas,
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            action: _liveStatus == 'inactive'
              ? PremiumElevatedButton(
                  onPressed: _startLiveClass,
                  icon: LucideIcons.video,
                  iconSize: 14,
                  fontSize: 12,
                  color: Colors.white,
                  textColor: const Color(0xFF4338CA),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  radius: 10,
                  child: const Text('Mulai Kelas Live'),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  PremiumElevatedButton(
                    onPressed: () { if (_currentMeetingId != null) joinJitsiMeeting(context: context, meetingId: _currentMeetingId!, serverUrl: 'https://meet.ffmuc.net', userName: nama, userEmail: widget.userData['email'] ?? '', subject: 'Kelas Live: $namaKelas', onClosed: _endLiveClass); },
                    icon: LucideIcons.video,
                    iconSize: 13,
                    fontSize: 11,
                    color: Colors.white,
                    textColor: const Color(0xFF4338CA),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    radius: 8,
                    child: const Text('Gabung'),
                  ),
                  const SizedBox(width: 8),
                  PremiumElevatedButton(
                    onPressed: _endLiveClass,
                    icon: LucideIcons.phoneOff,
                    iconSize: 13,
                    fontSize: 11,
                    color: const Color(0xFFEF4444),
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    radius: 8,
                    child: const Text('Akhiri'),
                  ),
                ]),
          ),

          const SizedBox(height: 24),

          // ─── RADICAL REDESIGNED METRICS SECTION ───
          const CosmicSectionLabel('Statistik & Akses'),
          const SizedBox(height: 10),

          // Row 1: Siswa & Permintaan
          Row(
            children: [
              Expanded(
                child: CosmicStatCard(
                  label: 'Siswa Terdaftar',
                  value: '${(widget.teamData['siswa_ids'] as List?)?.length ?? 0}',
                  icon: LucideIcons.users,
                  gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CosmicStatCard(
                  label: 'Permintaan Gabung',
                  value: '$_pendingCount',
                  icon: LucideIcons.userPlus,
                  gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
                  onTap: () => setState(() { _activeTabID = 'permintaan'; _activeTitle = 'Permintaan'; }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Full Width Interactive Class Code Panel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(isDark ? 80 : 120),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 80 : 40),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(30), // Frosted glass-like dark overlay
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE AKSES KELAS',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withAlpha(200),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                kodeKelas,
                                style: GoogleFonts.shareTechMono(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.copy,
                                color: Colors.white.withAlpha(180),
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PremiumElevatedButton(
                      onPressed: () {
                        if (kodeKelas.isNotEmpty && kodeKelas != '-') {
                          Clipboard.setData(ClipboardData(text: kodeKelas));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF10B981),
                              content: Row(
                                children: [
                                  const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Kode kelas $kodeKelas berhasil disalin!',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      color: Colors.white,
                      textColor: const Color(0xFF059669),
                      fontSize: 12,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: const Text('Salin'),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          const SizedBox(height: 28),

          // ─── SHIELD SECTION 1: AKTIVITAS PEMBELAJARAN ───
          Row(
            children: [
              Icon(LucideIcons.graduationCap, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9), size: 18),
              const SizedBox(width: 8),
              const CosmicSectionLabel('Aktivitas Pembelajaran'),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              CosmicMenuCard(
                label: 'Presensi Kelas',
                icon: LucideIcons.userCheck,
                gradient: const [Color(0xFF6366F1), Color(0xFF3B82F6)],
                onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi Kelas'; }),
              ),
              CosmicMenuCard(
                label: 'Penugasan Tugas',
                icon: LucideIcons.clipboardList,
                gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Penugasan Tugas'; }),
              ),
              CosmicMenuCard(
                label: 'Kuis & Ujian',
                icon: LucideIcons.helpCircle,
                gradient: const [Color(0xFFEC4899), Color(0xFFD946EF)],
                onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; }),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

          const SizedBox(height: 28),

          // ─── SHIELD SECTION 2: ADMINISTRASI KELAS ───
          Row(
            children: [
              Icon(LucideIcons.folderOpen, color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9), size: 18),
              const SizedBox(width: 8),
              const CosmicSectionLabel('Administrasi Kelas'),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              CosmicMenuCard(
                label: 'Nilai Siswa',
                icon: LucideIcons.award,
                gradient: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai Siswa'; }),
              ),
              CosmicMenuCard(
                label: 'Materi Ajar',
                icon: LucideIcons.folderOpen,
                gradient: const [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi Ajar'; }),
              ),
              CosmicMenuCard(
                label: 'Permintaan Gabung',
                icon: LucideIcons.userPlus,
                gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                onTap: () => setState(() { _activeTabID = 'permintaan'; _activeTitle = 'Permintaan Gabung'; }),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return AppShell(
      child: Row(
        children: [
          // ── Cosmic Sidebar ──
          SizedBox(
            width: 260,
            child: CosmicBackground(
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22)),
                          const SizedBox(width: 12),
                          const Text('MyPSKD', style: TextStyle(color: CosmicColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ]),
                        const SizedBox(height: 20),
                        Text(widget.teamData['nama_kelas'] ?? 'Ruang Kelas',
                          style: const TextStyle(color: CosmicColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(widget.teamData['kode_kelas'] ?? '',
                          style: const TextStyle(color: CosmicColors.textMuted, fontSize: 12)),
                      ]),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          CosmicSidebarItem(icon: Icons.hub_outlined, label: 'Dashboard',
                            isSelected: _activeTabID == 'dashboard', onTap: () => setState(() { _activeTabID = 'dashboard'; _activeTitle = 'Dashboard'; })),
                          CosmicSidebarItem(icon: Icons.person_add_alt_rounded, label: 'Permintaan',
                            isSelected: _activeTabID == 'permintaan', badgeCount: _pendingCount,
                            onTap: () => setState(() { _activeTabID = 'permintaan'; _activeTitle = 'Permintaan'; })),
                          CosmicSidebarItem(icon: Icons.how_to_reg_outlined, label: 'Presensi Kelas',
                            isSelected: _activeTabID == 'presensi', onTap: () => setState(() { _activeTabID = 'presensi'; _activeTitle = 'Presensi'; })),
                          CosmicSidebarItem(icon: Icons.assignment_outlined, label: 'Penugasan',
                            isSelected: _activeTabID == 'tugas', onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Penugasan'; })),
                          CosmicSidebarItem(icon: Icons.quiz_outlined, label: 'Kuis & Ujian',
                            isSelected: _activeTabID == 'kuis', onTap: () => setState(() { _activeTabID = 'kuis'; _activeTitle = 'Kuis & Ujian'; })),
                          CosmicSidebarItem(icon: Icons.military_tech_outlined, label: 'Nilai Siswa',
                            isSelected: _activeTabID == 'nilai', onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai Siswa'; })),
                          CosmicSidebarItem(icon: Icons.auto_stories_outlined, label: 'Materi Ajar',
                            isSelected: _activeTabID == 'materi', onTap: () => setState(() { _activeTabID = 'materi'; _activeTitle = 'Materi Ajar'; })),
                          const SizedBox(height: 20),
                          Padding(padding: const EdgeInsets.only(left: 12, bottom: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('CHANNELS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(100), letterSpacing: 1.5)),
                              InkWell(onTap: _showCreateChannelDialog, child: Icon(Icons.add, size: 16, color: Colors.white.withAlpha(150))),
                            ])),
                          CosmicSidebarItem(icon: Icons.tag_rounded, label: 'General',
                            isSelected: _activeTabID == 'channel_general', isChannel: true,
                            onTap: () => setState(() { _activeTabID = 'channel_general'; _activeTitle = 'General'; })),
                          for (var c in _channels)
                            CosmicSidebarItem(icon: Icons.tag_rounded, label: c['nama_channel'] ?? 'Unnamed',
                              isSelected: _activeTabID == 'channel_${c['id']}', isChannel: true,
                              onDelete: () => _confirmDeleteChannel(c['id'].toString(), c['nama_channel'] ?? ''),
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
                          child: Text((widget.userData['nama'] ?? 'G')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.userData['nama'] ?? 'Guru',
                            style: const TextStyle(color: CosmicColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                          const Text('Guru', style: TextStyle(color: CosmicColors.textMuted, fontSize: 11)),
                        ])),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.05),

          // ── Content Area ──
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
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nama = widget.userData['nama'] ?? 'Guru';
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
                  color: isDark ? const Color(0xFF161B27) : Colors.white,
                  border: Border(bottom: BorderSide(
                    color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB),
                  )),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        IconButton(onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, 
                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                            size: 20),
                          padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        const Spacer(),
                        NotificationBell(
                          userData: widget.userData, 
                          token: widget.token, 
                          iconColor: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt
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
                              color: isDark ? Colors.white : AppTheme.textLight, 
                              fontWeight: FontWeight.w800, 
                              fontSize: 16)),
                          Text(namaKelas, 
                            style: TextStyle(
                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500)),
                        ])),
                        if (_liveStatus == 'inactive')
                          PremiumElevatedButton(
                            onPressed: _startLiveClass,
                            icon: Icons.videocam_rounded,
                            iconSize: 14,
                            fontSize: 12,
                            color: AppTheme.indigoPrimary,
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            radius: 10,
                            child: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800)),
                          )
                        else
                          PremiumElevatedButton(
                            onPressed: _endLiveClass,
                            icon: Icons.stop_rounded,
                            iconSize: 14,
                            fontSize: 12,
                            color: Colors.red,
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            radius: 10,
                            child: const Text('Akhiri', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
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
                    child: Padding(padding: const EdgeInsets.only(bottom: 88), child: _getActiveView()),
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
                  color: isDark ? const Color(0xFF1E2060) : Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B83EB).withAlpha(isDark ? 40 : 15), 
                      blurRadius: 20, 
                      spreadRadius: 2, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CosmicPillNavItem(
                      icon: LucideIcons.layoutDashboard,
                      label: 'Home',
                      isSelected: _activeTabID == 'dashboard',
                      onTap: () => setState(() { _activeTabID = 'dashboard'; _activeTitle = 'Dashboard'; }),
                    ),
                    CosmicPillNavItem(
                      icon: LucideIcons.userPlus,
                      label: 'Akses',
                      isSelected: _activeTabID == 'permintaan',
                      badgeCount: _pendingCount,
                      onTap: () => setState(() { _activeTabID = 'permintaan'; _activeTitle = 'Permintaan'; }),
                    ),
                    CosmicPillNavItem(
                      icon: LucideIcons.clipboardList,
                      label: 'Tugas',
                      isSelected: _activeTabID == 'tugas',
                      onTap: () => setState(() { _activeTabID = 'tugas'; _activeTitle = 'Penugasan'; }),
                    ),
                    CosmicPillNavItem(
                      icon: LucideIcons.award,
                      label: 'Nilai',
                      isSelected: _activeTabID == 'nilai',
                      onTap: () => setState(() { _activeTabID = 'nilai'; _activeTitle = 'Nilai Siswa'; }),
                    ),
                    GestureDetector(
                      onTap: _showMobileMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: const Icon(LucideIcons.menu, color: Color(0xFF9BA3CC), size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B27) : Colors.white, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.0)
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 4, 
              margin: const EdgeInsets.only(bottom: 16), 
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE0E0E0), 
                borderRadius: BorderRadius.circular(2)
              )
            ),
            Text(
              'Menu Lainnya', 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 16, 
                color: isDark ? Colors.white : const Color(0xFF1A1A3E)
              )
            ),
            const SizedBox(height: 16),
            _buildMenuSheetItem(ctx, 'presensi', Icons.how_to_reg_outlined, 'Presensi Kelas', const Color(0xFF7B83EB), isDark),
            _buildMenuSheetItem(ctx, 'kuis', Icons.quiz_outlined, 'Kuis & Ujian', const Color(0xFFF27F33), isDark),
            _buildMenuSheetItem(ctx, 'materi', Icons.auto_stories_outlined, 'Materi Ajar', const Color(0xFF8B5CF6), isDark),
            _buildMenuSheetItem(ctx, 'channel_general', Icons.tag_rounded, 'Channel General', const Color(0xFF10B981), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSheetItem(BuildContext ctx, String id, IconData icon, String label, Color color, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)), 
        child: Icon(icon, color: color, size: 20)
      ),
      title: Text(
        label, 
        style: TextStyle(
          fontWeight: FontWeight.w700, 
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1A1A3E)
        )
      ),
      onTap: () { Navigator.pop(ctx); setState(() { _activeTabID = id; _activeTitle = label; }); },
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

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: overrideColor ?? (isDark ? const Color(0xFF1E2060) : Colors.white),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B83EB).withAlpha(isDark ? 15 : 20), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}