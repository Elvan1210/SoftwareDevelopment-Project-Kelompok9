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
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/notification_bell.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/jitsi_embed.dart';


class GuruTeamDetailLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  final String? initialTab;

  const GuruTeamDetailLayout({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
    this.initialTab,
  });

  @override
  State<GuruTeamDetailLayout> createState() => _GuruTeamDetailLayoutState();
}

class _GuruTeamDetailLayoutState extends State<GuruTeamDetailLayout> {
  static const _ink = Color(0xFF001E2B);
  static const _primary = Color(0xFF3D6754);
  static const _primCon = Color(0xFFB7E5CD);
  static const _tertiary = Color(0xFF8D4D33);
  static const _tertCon = Color(0xFFFFD1C0);
  static const _surfHigh = Color(0xFFCEEDFF);
  static const _secCon = Color(0xFFB7EDE7);
  static const _surface = Color(0xFFF4FAFF);
  static const _white = Color(0xFFFFFFFF);
  static const _muted = Color(0xFF414944);

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
    if (widget.initialTab != null) {
      _activeTabID = widget.initialTab!;
      _activeTitle = _getTitleFromTab(widget.initialTab!);
    }
    _fetchPendingCount();
    _fetchChannels();
    _fetchLiveStatus();
  }

  String _getTitleFromTab(String tab) {
    switch (tab) {
      case 'presensi':
        return 'Presensi Kelas';
      case 'tugas':
        return 'Penugasan Tugas';
      case 'nilai':
        return 'Nilai Siswa';
      case 'materi':
        return 'Materi Ajar';
      case 'kuis':
        return 'Kuis & Ujian';
      default:
        return 'Dashboard';
    }
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
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
        title: const Text('Hapus Channel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Anda yakin ingin menghapus channel "$channelName"? Semua obrolan di dalamnya akan hilang.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
        title: const Text('Buat Channel Baru',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: _channelNameCtrl,
          decoration: InputDecoration(
            hintText: 'Misal: Praktikum 01',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withAlpha(50),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          PremiumElevatedButton(
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            radius: 12,
            onPressed: () => _buatChannel(),
            child: const Text('Buat',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _getActiveView() {
    if (_activeTabID.startsWith('channel_')) {
      return _buildChannelView();
    }

    switch (_activeTabID) {
      case 'dashboard':
        return _buildDashboardView();
      case 'permintaan':
        return GuruPendingRequestsView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData,
            onRequestsChanged: _fetchPendingCount);
      case 'presensi':
        return GuruPresensiView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData);
      case 'tugas':
        return GuruTugasView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData);
      case 'kuis':
        return GuruQuizView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData);
      case 'nilai':
        return GuruNilaiView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData);
      case 'materi':
        return GuruMateriView(
            userData: widget.userData,
            token: widget.token,
            teamData: widget.teamData);
      case 'menu':
        return _buildMenuHub();
      default:
        return _buildDashboardView();
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

  Widget _buildMenuHub() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF);
    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final shadowColor = isDark ? Colors.white.withAlpha(20) : const Color(0xFF001E2B);
    final nama = widget.userData['nama'] ?? 'Guru';
    final photoUrl = widget.userData['photoUrl'] ?? '';

    return Scaffold(
      backgroundColor: primaryBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBg,
                border: Border(bottom: BorderSide(color: onSurface, width: 1)),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB7E5CD),
                            border: Border.all(color: onSurface, width: 2),
                          ),
                          child: photoUrl.isNotEmpty
                              ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarInitials(nama))
                              : _buildAvatarInitials(nama),
                        ),
                        const SizedBox(width: 12),
                        Text('Menu Hub',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                              fontFamily: 'Plus Jakarta Sans',
                            )),
                      ],
                    ),
                    NotificationBell(
                      userData: widget.userData,
                      token: widget.token,
                      iconColor: const Color(0xFF3D6754),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      icon: Icons.how_to_reg,
                      label: 'Presensi Kelas',
                      bgColor: const Color(0xFFB7E5CD),
                      onSurface: onSurface,
                      shadowColor: shadowColor,
                      onTap: () => setState(() {
                        _activeTabID = 'presensi';
                        _activeTitle = 'Presensi';
                      }),
                    ),
                    _buildMenuCard(
                      icon: Icons.quiz,
                      label: 'Kuis & Ujian',
                      bgColor: const Color(0xFFCEEDFF),
                      onSurface: onSurface,
                      shadowColor: shadowColor,
                      onTap: () => setState(() {
                        _activeTabID = 'kuis';
                        _activeTitle = 'Kuis & Ujian';
                      }),
                    ),
                    _buildMenuCard(
                      icon: Icons.menu_book,
                      label: 'Materi Ajar',
                      bgColor: const Color(0xFFC1E8FF),
                      onSurface: onSurface,
                      shadowColor: shadowColor,
                      onTap: () => setState(() {
                        _activeTabID = 'materi';
                        _activeTitle = 'Materi Ajar';
                      }),
                    ),
                    _buildMenuCard(
                      icon: Icons.assessment,
                      label: 'Laporan Nilai',
                      bgColor: const Color(0xFFFFD1C0),
                      onSurface: onSurface,
                      shadowColor: shadowColor,
                      onTap: () => setState(() {
                        _activeTabID = 'nilai';
                        _activeTitle = 'Nilai Siswa';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daftar Channel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                          fontFamily: 'Plus Jakarta Sans',
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7EDE7),
                        border: Border.all(color: onSurface),
                      ),
                      child: Text('${_channels.length + 1} TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: onSurface,
                            fontFamily: 'Inter',
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B27) : Colors.white,
                    border: Border.all(color: onSurface, width: 2),
                    boxShadow: [
                      BoxShadow(color: shadowColor, offset: const Offset(2, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: onSurface,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('General',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF),
                                  fontFamily: 'Plus Jakarta Sans',
                                )),
                            Icon(Icons.expand_more, color: isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF)),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _channels.length + 1,
                        separatorBuilder: (_, __) => Divider(color: onSurface, height: 1),
                        itemBuilder: (context, index) {
                          final isGeneral = index == 0;
                          final channelName = isGeneral ? 'General' : (_channels[index - 1]['nama_channel'] ?? 'Unnamed');
                          final tabId = isGeneral ? 'channel_general' : 'channel_${_channels[index - 1]['id']}';
                          return ListTile(
                            onTap: () => setState(() {
                              _activeTabID = tabId;
                              _activeTitle = channelName;
                            }),
                            leading: Container(
                              width: 8,
                              height: 8,
                              color: const Color(0xFF3D6754),
                            ),
                            title: Text(channelName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: onSurface,
                                  fontFamily: 'Inter',
                                )),
                            trailing: Icon(Icons.chevron_right, color: onSurface.withAlpha(150)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showCreateChannelDialog,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B27) : const Color(0xFFF4FAFF),
                      border: Border.all(color: onSurface, width: 2),
                      boxShadow: [
                        BoxShadow(color: shadowColor, offset: const Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.forum, color: Color(0xFF336763)),
                            const SizedBox(width: 12),
                            Text('Buat Channel Baru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                  fontFamily: 'Inter',
                                )),
                          ],
                        ),
                        Container(
                          color: const Color(0xFFBA1A1A),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: const Text('NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Padding for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials(String nama) {
    return Center(
      child: Text(
        nama[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF3E6855),
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color onSurface,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: onSurface, width: 2),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(4, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: onSurface),
            Text(label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: onSurface,
                  fontFamily: 'Plus Jakarta Sans',
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF);
    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);
    
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      color: primaryBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel Tabs (Horizontal Scroll) - Hide on desktop
          if (!isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B27) : const Color(0xFFE8F6FF),
                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF414944) : const Color(0xFFC1C8C2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saluran Diskusi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        fontFamily: 'Plus Jakarta Sans',
                      )),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChannelTab('General', 'channel_general', isDark),
                        for (var c in _channels)
                          _buildChannelTab(c['nama_channel'] ?? 'Unnamed', 'channel_${c['id']}', isDark),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showCreateChannelDialog,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C2230) : const Color(0xFFCEEDFF),
                              border: Border.all(color: onSurfaceVariant),
                            ),
                            child: Icon(Icons.add, size: 20, color: onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Forum Content
          Expanded(
            child: SaluranView(
              userData: widget.userData,
              token: widget.token,
              teamData: widget.teamData,
              channelId: _activeTabID.replaceFirst('channel_', ''),
              channelName: _activeTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTab(String label, String tabId, bool isDark) {
    final isActive = _activeTabID == tabId;
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);
    const primary = Color(0xFF3D6754);

    return GestureDetector(
      onTap: () => setState(() {
        _activeTabID = tabId;
        _activeTitle = label;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: isActive ? const Border(bottom: BorderSide(color: primary, width: 3)) : null,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? primary : onSurfaceVariant,
              fontFamily: 'Inter',
            )),
      ),
    );
  }

   Widget _buildDashboardView() {
    final namaKelas  = widget.teamData['nama_kelas'] ?? 'Kelas';
    final kodeKelas  = widget.teamData['kode_kelas']?.toString() ?? '-';
    final tahunAjar  = widget.teamData['tahun_ajar']?.toString() ?? 'TA 2024/2025';
    final jumlahSiswa = (widget.teamData['siswa_ids'] as List?)?.length ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
 
          // ── HEADER: Badge + Nama Kelas + Tahun + Live Button ──────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge "KELAS AKTIF"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: _tertiary,
                      child: const Text('KELAS AKTIF',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: _white, letterSpacing: 0.8,
                          fontFamily: 'Inter',
                        )),
                    ),
                    const SizedBox(height: 8),
                    Text(namaKelas,
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : _ink,
                        letterSpacing: -1.5, height: 1.1,
                        fontFamily: 'Plus Jakarta Sans',
                      )),
                    Text(tahunAjar,
                      style: const TextStyle(
                        fontSize: 15, color: _muted,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      )),
                  ],
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 16),
 
          // Live Button — ghost border style
          _liveStatus == 'active'
              ? Row(children: [
                  Expanded(child: _ghostButton(
                    label: 'GABUNG LIVE',
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFFBA1A1A),
                    onTap: () {
                      if (_currentMeetingId != null) {
                        joinJitsiMeeting(
                          context: context,
                          meetingId: _currentMeetingId!,
                          serverUrl: 'https://meet.ffmuc.net',
                          userName: widget.userData['nama'] ?? 'Guru',
                          userEmail: widget.userData['email'] ?? '',
                          subject: 'Kelas Live: $namaKelas',
                          onClosed: _endLiveClass,
                        );
                      }
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ghostButton(
                    label: 'AKHIRI SESI',
                    icon: Icons.stop_rounded,
                    color: _ink,
                    onTap: _endLiveClass,
                  )),
                ])
              : _ghostButton(
                  label: 'BUAT SESI LIVE',
                  icon: Icons.videocam_rounded,
                  color: _primary,
                  onTap: _startLiveClass,
                ),
 
          const SizedBox(height: 20),
 
          // ── BENTO GRID: Kode Kelas (4) + Statistik (8) ───────────
          LayoutBuilder(builder: (ctx, c) {
            final isWide = c.maxWidth > 480;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildKodeKelasCard(kodeKelas, isDark)),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: _buildStatistikCard(jumlahSiswa, isDark)),
                ],
              );
            }
            return Column(children: [
              _buildKodeKelasCard(kodeKelas, isDark),
              const SizedBox(height: 12),
              _buildStatistikCard(jumlahSiswa, isDark),
            ]);
          }),
 
          const SizedBox(height: 20),
 
          // ── MANAJEMEN KELAS ────────────────────────────────────────
          Row(children: [
            const Icon(Icons.grid_view_rounded, size: 18, color: _primary),
            const SizedBox(width: 8),
            Text('Manajemen Kelas',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _ink,
                fontFamily: 'Plus Jakarta Sans',
              )),
          ]),
          const SizedBox(height: 12),
 
          // 2x2 grid + materi full width (col-span-2 di mobile)
          Column(children: [
            Row(children: [
              Expanded(child: _buildMenuBtn(
                icon: Icons.how_to_reg_outlined,
                label: 'PRESENSI\nKELAS',
                isDark: isDark,
                onTap: () => setState(() {
                  _activeTabID = 'presensi';
                  _activeTitle = 'Presensi Kelas';
                }),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildMenuBtn(
                icon: Icons.assignment_outlined,
                label: 'PENUGASAN\nTUGAS',
                isDark: isDark,
                onTap: () => setState(() {
                  _activeTabID = 'tugas';
                  _activeTitle = 'Penugasan Tugas';
                }),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildMenuBtn(
                icon: Icons.quiz_outlined,
                label: 'KUIS &\nUJIAN',
                isDark: isDark,
                onTap: () => setState(() {
                  _activeTabID = 'kuis';
                  _activeTitle = 'Kuis & Ujian';
                }),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildMenuBtn(
                icon: Icons.grade_outlined,
                label: 'NILAI\nSISWA',
                isDark: isDark,
                onTap: () => setState(() {
                  _activeTabID = 'nilai';
                  _activeTitle = 'Nilai Siswa';
                }),
              )),
            ]),
            const SizedBox(height: 10),
            // Materi full width (col-span-2)
            _buildMenuBtn(
              icon: Icons.library_books_outlined,
              label: 'MATERI AJAR',
              isDark: isDark,
              fullWidth: true,
              onTap: () => setState(() {
                _activeTabID = 'materi';
                _activeTitle = 'Materi Ajar';
              }),
            ),
          ]),
 
          const SizedBox(height: 20),
 
          // ── DISKUSI TAMBAHAN BANNER ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfHigh,
              border: Border.all(color: _ink),
              boxShadow: const [
                BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diskusi Tambahan?',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _ink,
                      fontFamily: 'Plus Jakarta Sans',
                    )),
                  const SizedBox(height: 4),
                  const Text('Jadwalkan sesi tutorial interaktif untuk materi yang sulit.',
                    style: TextStyle(
                      fontSize: 13, color: _muted,
                      fontFamily: 'Inter', height: 1.4,
                    )),
                ],
              )),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() {
                  _activeTabID = 'channel_general';
                  _activeTitle = 'General';
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: _tertiary,
                    boxShadow: [
                      BoxShadow(color: _ink, offset: Offset(2, 2)),
                    ],
                  ),
                  child: const Text('MULAI SESI',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: _white, letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    )),
                ),
              ),
            ]),
          ),
 
        ],
      ),
    );
  }
 
  // ── Ghost Border Button (BUAT SESI LIVE style) ────────────────────────────
  Widget _ghostButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: _ink),
          boxShadow: const [
            BoxShadow(color: _ink, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _white, size: 18),
            const SizedBox(width: 8),
            Text(label,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: _white, letterSpacing: 0.5,
                fontFamily: 'Inter',
              )),
          ],
        ),
      ),
    );
  }
 
  // ── Kode Kelas Card ───────────────────────────────────────────────────────
  Widget _buildKodeKelasCard(String kodeKelas, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2230) : _white,
        border: Border.all(color: _ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('KODE KELAS',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: _muted, letterSpacing: 1.5,
                fontFamily: 'Inter',
              )),
            Icon(Icons.key_outlined, size: 18, color: _muted),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: _white,
              border: Border.fromBorderSide(BorderSide(color: _ink)),
              boxShadow: [
                BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(kodeKelas,
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: _ink, letterSpacing: 4,
                      fontFamily: 'Inter',
                    )),
                )),
                GestureDetector(
                  onTap: () {
                    if (kodeKelas != '-') {
                      Clipboard.setData(ClipboardData(text: kodeKelas));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _primary,
                          content: Text('Kode kelas disalin!',
                            style: TextStyle(
                              fontWeight: FontWeight.w800, color: _white)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      border: Border.fromBorderSide(BorderSide(color: _ink)),
                    ),
                    child: const Icon(Icons.content_copy_outlined,
                        size: 16, color: _ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // ── Statistik Siswa Card ──────────────────────────────────────────────────
  Widget _buildStatistikCard(int jumlahSiswa, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2230) : _secCon.withAlpha(80),
        border: Border.all(color: _ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Statistik Siswa',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _ink,
                fontFamily: 'Plus Jakarta Sans',
              )),
            const Icon(Icons.analytics_outlined, size: 18, color: _muted),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // Terdaftar
            Expanded(child: GestureDetector(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: _white,
                  border: Border.fromBorderSide(BorderSide(color: _ink)),
                  boxShadow: [
                    BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TERDAFTAR',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _muted, letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      )),
                    Text('$jumlahSiswa',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900,
                        color: _ink, height: 1.1,
                        fontFamily: 'Plus Jakarta Sans',
                      )),
                  ],
                ),
              ),
            )),
            const SizedBox(width: 10),
            // Permintaan
            Expanded(child: GestureDetector(
              onTap: () => setState(() {
                _activeTabID = 'permintaan';
                _activeTitle = 'Permintaan';
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tertCon.withAlpha(80),
                  border: Border.all(color: _ink),
                  boxShadow: const [
                    BoxShadow(color: Color.fromARGB(255, 247, 192, 180), offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERMINTAAN',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 79, 33, 16), letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      )),
                    Text('$_pendingCount',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900,
                        color: Color.fromARGB(255, 67, 21, 2), height: 1.1,
                        fontFamily: 'Plus Jakarta Sans',
                      )),
                  ],
                ),
              ),
            )),
          ]),
        ],
      ),
    );
  }
 
  // ── Menu Button (Manajemen Kelas) ─────────────────────────────────────────
  Widget _buildMenuBtn({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return _HoverMenuCard(
      icon: icon,
      label: label,
      isDark: isDark,
      fullWidth: fullWidth,
      onTap: onTap,
    );
  }
 
  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nama = widget.userData['nama'] ?? 'Guru';
    final namaKelas = widget.teamData['nama_kelas'] ?? 'Kelas';
 
    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1420) : _surface,
        body: Column(children: [
 
          // ── HEADER ──────────────────────────────────────────────────
          if (_activeTabID != 'menu')
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B27) : _white,
                border: Border(bottom: BorderSide(
                  color: isDark ? const Color(0xFF252D3D) : _ink,
                )),
              ),
              child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + toggle + notif
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C2230) : _white,
                            border: Border.all(color: isDark ? Colors.white24 : _ink),
                            boxShadow: [BoxShadow(
                              color: isDark ? Colors.white24 : _ink,
                              offset: const Offset(2, 2), blurRadius: 0,
                            )],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: isDark ? Colors.white : _ink),
                        ),
                      ),
                      const Spacer(),
                      NotificationBell(
                        userData: widget.userData,
                        token: widget.token,
                        iconColor: isDark ? Colors.white70 : _ink,
                      ),
                    ]),
                    const SizedBox(height: 14),
 
                    // Avatar + nama + kelas + live button
                    Row(children: [
                      // Avatar
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _primCon,
                          border: Border.all(
                              color: isDark ? Colors.white24 : _ink),
                          boxShadow: [BoxShadow(
                            color: isDark ? Colors.white24 : _ink,
                            offset: const Offset(2, 2), blurRadius: 0,
                          )],
                        ),
                        child: Center(child: Text(
                          nama[0].toUpperCase(),
                          style: TextStyle(
                            color: isDark ? Colors.white : _primary,
                            fontWeight: FontWeight.w900, fontSize: 18,
                          ),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $nama',
                            style: TextStyle(
                              color: isDark ? Colors.white : _ink,
                              fontWeight: FontWeight.w800, fontSize: 15,
                              fontFamily: 'Plus Jakarta Sans',
                            )),
                          Text(namaKelas,
                            style: const TextStyle(
                              color: _muted, fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )),
 
                      // Live button
                      GestureDetector(
                        onTap: _liveStatus == 'inactive'
                            ? _startLiveClass
                            : _endLiveClass,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _liveStatus == 'inactive'
                                ? _primary
                                : const Color(0xFFBA1A1A),
                            border: Border.all(
                                color: isDark ? Colors.white24 : _ink),
                            boxShadow: [BoxShadow(
                              color: isDark ? Colors.white24 : _ink,
                              offset: const Offset(2, 2), blurRadius: 0,
                            )],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              _liveStatus == 'inactive'
                                  ? Icons.videocam_rounded
                                  : Icons.stop_rounded,
                              color: _white, size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _liveStatus == 'inactive' ? 'LIVE' : 'STOP',
                              style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: _white, letterSpacing: 0.5,
                              )),
                          ]),
                        ),
                      ),
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
              color: isDark ? const Color(0xFF161B27) : _surface,
              border: Border(top: BorderSide(
                color: isDark ? const Color(0xFF252D3D) : _ink,
              )),
            ),
            child: Row(
              children: [
                _navItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  id: 'dashboard',
                  isDark: isDark,
                ),
                _navItem(
                  icon: Icons.person_add_outlined,
                  selectedIcon: Icons.person_add_rounded,
                  label: 'Akses',
                  id: 'permintaan',
                  isDark: isDark,
                  badge: _pendingCount,
                ),
                _navItem(
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Tugas',
                  id: 'tugas',
                  isDark: isDark,
                ),
                _navItem(
                  icon: Icons.grade_outlined,
                  selectedIcon: Icons.grade_rounded,
                  label: 'Nilai',
                  id: 'nilai',
                  isDark: isDark,
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
                          Icon(Icons.menu_rounded,
                            size: 22,
                            color: isDark ? Colors.white54 : _muted,
                          ),
                          const SizedBox(height: 3),
                          Text('Menu',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : _muted,
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
 
  // ── Nav Item ──────────────────────────────────────────────────────────────
  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String id,
    required bool isDark,
    int badge = 0,
  }) {
    final isSelected = _activeTabID == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTabID = id;
          _activeTitle = label;
        }),
        child: Container(
          color: isSelected
              ? (isDark ? _primary.withAlpha(40) : _primCon)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isSelected ? selectedIcon : icon,
                    size: 22,
                    color: isSelected
                        ? _primary
                        : (isDark ? Colors.white54 : _muted),
                  ),
                  const SizedBox(height: 3),
                  Text(label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected
                          ? _primary
                          : (isDark ? Colors.white54 : _muted),
                    )),
                ],
              ),
              if (badge > 0)
                Positioned(
                  top: 8, right: 12,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFBA1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('$badge',
                      style: const TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w900,
                        color: _white,
                      ))),
                  ),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cosmic Sidebar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
            child: Container(
              width: 270,
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAFF), // Light blue background for Teams
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF001E2B), width: 2),
                boxShadow: const [BoxShadow(color: Color(0xFF001E2B), offset: Offset(6, 6))],
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
                            child: const Icon(Icons.school, color: AppTheme.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('MyPSKD', style: TextStyle(color: AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        ]),
                        const SizedBox(height: 20),
                        Text(widget.teamData['nama_kelas'] ?? 'Ruang Kelas',
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(widget.teamData['kode_kelas'] ?? '', style: const TextStyle(color: AppTheme.textMutedLt, fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _TeamSidebarItemNeo(
                              icon: Icons.hub_outlined,
                              label: 'Dashboard',
                              isSelected: _activeTabID == 'dashboard',
                              onTap: () => setState(() {
                                    _activeTabID = 'dashboard';
                                    _activeTitle = 'Dashboard';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.person_add_alt_rounded,
                              label: 'Permintaan',
                              isSelected: _activeTabID == 'permintaan',
                              badgeCount: _pendingCount,
                              onTap: () => setState(() {
                                    _activeTabID = 'permintaan';
                                    _activeTitle = 'Permintaan';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.how_to_reg_outlined,
                              label: 'Presensi Kelas',
                              isSelected: _activeTabID == 'presensi',
                              onTap: () => setState(() {
                                    _activeTabID = 'presensi';
                                    _activeTitle = 'Presensi';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.assignment_outlined,
                              label: 'Penugasan',
                              isSelected: _activeTabID == 'tugas',
                              onTap: () => setState(() {
                                    _activeTabID = 'tugas';
                                    _activeTitle = 'Penugasan';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.quiz_outlined,
                              label: 'Kuis & Ujian',
                              isSelected: _activeTabID == 'kuis',
                              onTap: () => setState(() {
                                    _activeTabID = 'kuis';
                                    _activeTitle = 'Kuis & Ujian';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.military_tech_outlined,
                              label: 'Nilai Siswa',
                              isSelected: _activeTabID == 'nilai',
                              onTap: () => setState(() {
                                    _activeTabID = 'nilai';
                                    _activeTitle = 'Nilai Siswa';
                                  })),
                          _TeamSidebarItemNeo(
                              icon: Icons.auto_stories_outlined,
                              label: 'Materi Ajar',
                              isSelected: _activeTabID == 'materi',
                              onTap: () => setState(() {
                                    _activeTabID = 'materi';
                                    _activeTitle = 'Materi Ajar';
                                  })),
                          const SizedBox(height: 20),
                          Padding(
                              padding:
                                  const EdgeInsets.only(left: 12, right: 10, bottom: 8),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('CHANNELS',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textMutedLt.withAlpha(160),
                                            letterSpacing: 1.5)),
                                    Tooltip(
                                      message: 'Buat Channel Baru',
                                      child: InkWell(
                                        onTap: _showCreateChannelDialog,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withAlpha(15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppTheme.primary.withAlpha(60),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            size: 14,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ])),
                          _TeamSidebarItemNeo(
                              icon: Icons.tag_rounded,
                              label: 'General',
                              isSelected: _activeTabID == 'channel_general',
                              isChannel: true,
                              onTap: () => setState(() {
                                    _activeTabID = 'channel_general';
                                    _activeTitle = 'General';
                                  })),
                          for (var c in _channels)
                            _TeamSidebarItemNeo(
                                icon: Icons.tag_rounded,
                                label: c['nama_channel'] ?? 'Unnamed',
                                isSelected:
                                    _activeTabID == 'channel_${c['id']}',
                                isChannel: true,
                                onDelete: () => _confirmDeleteChannel(
                                    c['id'].toString(),
                                    c['nama_channel'] ?? ''),
                                onTap: () => setState(() {
                                      _activeTabID = 'channel_${c['id']}';
                                      _activeTitle = c['nama_channel'] ?? '';
                                    })),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
                          child: Text((widget.userData['nama'] ?? 'G')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.userData['nama'] ?? 'Guru',
                            style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                          const Text('Guru', style: TextStyle(color: AppTheme.textMutedLt, fontSize: 11)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF161B27)
                          : Colors.white,
                      border: Border(
                          bottom: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF252D3D)
                            : const Color(0xFFE5E7EB),
                      )),
                    ),
                    child: Row(children: [
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.textMutedDk
                                  : AppTheme.textMutedLt,
                              size: 18)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(_activeTitle,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : AppTheme.textLight,
                                      letterSpacing: -0.3))
                              .animate(key: ValueKey(_activeTabID))
                              .fade(duration: 250.ms)
                              .slideX(begin: -0.03)),
                      NotificationBell(
                          userData: widget.userData,
                          token: widget.token,
                          iconColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.textMutedDk
                                  : AppTheme.textMutedLt),
                      const SizedBox(width: 8),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: KeyedSubtree(
                          key: ValueKey(_activeTabID), child: _getActiveView()),
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



  void _showMobileMenu() {
    setState(() {
      _activeTabID = 'menu';
      _activeTitle = 'Menu Hub';
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1100) return _buildWebLayout(context);
      return _buildMobileLayout(context);
    });
  }
}

// ── Hover Menu Card ───────────────────────────────────────────────────────────
class _HoverMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool fullWidth;
  final VoidCallback onTap;

  const _HoverMenuCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<_HoverMenuCard> createState() => _HoverMenuCardState();
}

class _HoverMenuCardState extends State<_HoverMenuCard> {
  bool _hovered = false;

  static const _ink     = Color(0xFF001E2B);
  static const _primCon = Color(0xFFB7E5CD);
  static const _white   = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final bg = _hovered
        ? _primCon
        : (widget.isDark ? const Color(0xFF1C2230) : _white);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: _ink),
        boxShadow: const [
          BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: widget.fullWidth
          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, size: 26,
                  color: widget.isDark ? Colors.white : _ink),
              const SizedBox(width: 12),
              Text(widget.label,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : _ink,
                  letterSpacing: 0.3,
                  fontFamily: 'Inter',
                )),
            ])
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 28,
                    color: widget.isDark ? Colors.white : _ink),
                const SizedBox(height: 10),
                Text(widget.label,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : _ink,
                    height: 1.3, letterSpacing: 0.2,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center),
              ]),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _hovered = true),
        onTapUp: (_) => setState(() => _hovered = false),
        onTapCancel: () => setState(() => _hovered = false),
        child: content,
      ),
    );
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
        color:
            overrideColor ?? (isDark ? const Color(0xFF1E2060) : Colors.white),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7B83EB).withAlpha(isDark ? 15 : 20),
              blurRadius: 16,
              offset: const Offset(0, 4)),
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
  final int? badgeCount;
  final VoidCallback? onDelete;

  const _TeamSidebarItemNeo({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isChannel = false,
    this.badgeCount,
    this.onDelete,
  });

  @override
  State<_TeamSidebarItemNeo> createState() => _TeamSidebarItemNeoState();
}

class _TeamSidebarItemNeoState extends State<_TeamSidebarItemNeo> {
  bool _hovered = false;
  static const Color _background = Color(0xFFE8F1F5);
  static const Color _primaryContainer = Color(0xFFB7E5CD);
  static const Color _onSurface = Colors.black;
  static const Color _onSurfaceVariant = Colors.black87;
  static const Color _primary = Color(0xFF001E2B);
  static const Color _onBackground = Colors.black;
  static const Color _error = Color(0xFFEF4444);

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
          margin: const EdgeInsets.only(bottom: 6),
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
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _error,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _onSurface, width: 1.5),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (widget.onDelete != null && _hovered)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _onSurface, width: 1.5),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              if (widget.isSelected && widget.badgeCount == null && widget.onDelete == null)
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


