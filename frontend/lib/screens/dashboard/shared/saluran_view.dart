import '../../../config/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../guru/guru_tugas_detail_screen.dart';
import '../siswa/siswa_tugas_detail_screen.dart';
import '../../../widgets/premium_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class SaluranView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  final String channelId;
  final String channelName;

  const SaluranView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
    this.channelId = 'general',
    this.channelName = 'General',
  });

  @override
  State<SaluranView> createState() => _SaluranViewState();
}

class _SaluranViewState extends State<SaluranView> {
  final TextEditingController _pesanCtrl = TextEditingController();
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _replyingToId;

  String get _kelasId => widget.teamData['id']?.toString() ?? '';
  String get _myId =>
      widget.userData['id']?.toString() ??
      widget.userData['uid']?.toString() ??
      '';
  String get _myNama => widget.userData['nama']?.toString() ?? 'Pengguna';
  String get _myRole => widget.userData['role']?.toString() ?? 'Siswa';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant SaluranView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final res = await http.get(
          Uri.parse('$baseUrl/api/saluran?kelas_id=$_kelasId'),
          headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _allData =
                decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // DIKEMBALIKAN KE POST JSON BIASA (TANPA FILE) AGAR TIDAK ERROR 500
  Future<void> _postMessage({String? parentId, required String text}) async {
    if (text.isEmpty) return;
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/saluran'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
        body: jsonEncode({
          'kelas_id': _kelasId,
          'channel_id': widget.channelId,
          'pengirim_id': _myId,
          'pengirim_nama': _myNama,
          'role': _myRole,
          'pesan': text,
          'parentId': parentId,
          'waktu': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _pesanCtrl.clear();
          _replyCtrl.clear();
          _replyingToId = null;
        });
        _fetchData(); // Refresh UI setelah sukses kirim
      } else {
        debugPrint("Error dari server: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error kirim: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF);

    final mainPosts = _allData
        .where((m) =>
            (m['channel_id']?.toString() ?? 'general') == widget.channelId &&
            m['parentId'] == null)
        .toList();
        
    final allReplies = _allData
        .where((m) =>
            (m['channel_id']?.toString() ?? 'general') == widget.channelId &&
            m['parentId'] != null)
        .toList();

    return Scaffold(
      backgroundColor: primaryBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final infoCard = _buildInfoCard(isDark, mainPosts.length, allReplies.length);
                        
                        final threads = ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mainPosts.length,
                          itemBuilder: (context, i) =>
                              _buildPostThread(mainPosts[i], isDark, theme),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            infoCard,
                            const SizedBox(height: 24),
                            threads,
                          ],
                        );
                      },
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNewPostButton(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, int topicCount, int replyCount) {
    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B27) : Colors.white,
        border: Border(
          top: BorderSide(color: onSurfaceVariant),
          right: BorderSide(color: onSurfaceVariant),
          bottom: BorderSide(color: onSurfaceVariant),
          left: const BorderSide(color: Color(0xFF3D6754), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INFO SALURAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D6754),
                letterSpacing: 0.5,
                fontFamily: 'Inter',
              )),
          const SizedBox(height: 8),
          Text(widget.channelName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: onSurface,
                fontFamily: 'Plus Jakarta Sans',
              )),
          const SizedBox(height: 16),
          Text('Tempat berbagi informasi, bertanya, dan berkolaborasi antar siswa dan pengajar.',
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceVariant,
                fontFamily: 'Inter',
              )),
          const SizedBox(height: 32),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$topicCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF336763), fontFamily: 'Plus Jakarta Sans')),
                  Text('TOPIK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurfaceVariant, fontFamily: 'Inter')),
                ],
              ),
              const SizedBox(width: 24),
              Container(width: 1, height: 40, color: isDark ? const Color(0xFF414944) : const Color(0xFFC1C8C2)),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$replyCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF336763), fontFamily: 'Plus Jakarta Sans')),
                  Text('BALASAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurfaceVariant, fontFamily: 'Inter')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostThread(
      Map<String, dynamic> post, bool isDark, ThemeData theme) {
    final postId = post['id']?.toString() ?? post['_id']?.toString() ?? '';
    final replies = _allData.where((m) => m['parentId'] == postId).toList();
    
    final onSurface = isDark ? Colors.white : const Color(0xFF001E2B);
    final onSurfaceVariant = isDark ? Colors.white70 : const Color(0xFF414944);

    final isTugas = post['tipe'] == 'tugas';
    final author = post['pengirim_nama'] ?? 'User';
    final timeAgo = post['waktu']?.toString().split('T')[0] ?? '';
    final repliesCount = replies.length;
    final lastActive = replies.isNotEmpty ? (replies.last['waktu']?.toString().split('T')[0] ?? timeAgo) : timeAgo;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24, top: 12, right: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B27) : Colors.white,
            border: Border.all(color: onSurfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // POSTINGAN UTAMA
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7EDE7),
                        border: Border.all(color: onSurfaceVariant),
                      ),
                      child: Center(
                        child: Text(author.isNotEmpty ? author[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF336763),
                            )),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(isTugas ? (post['judul_tugas'] ?? 'Tugas Baru') : (author + ' memulai diskusi'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      fontFamily: 'Plus Jakarta Sans',
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Text(timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onSurfaceVariant,
                                    fontFamily: 'Inter',
                                  )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Oleh $author',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF336763),
                                fontFamily: 'Inter',
                              )),
                          const SizedBox(height: 12),
                          
                          if (isTugas) ...[
                            GestureDetector(
                              onTap: () async {
                                final tugasId = post['tugas_id'];
                                if (tugasId == null) return;
                                try {
                                  final res = await http.get(
                                    Uri.parse('$baseUrl/api/tugas/$tugasId'),
                                    headers: {'Authorization': 'Bearer ${widget.token}'},
                                  );
                                  if (res.statusCode == 200 && mounted) {
                                    final tugas = jsonDecode(res.body);
                                    if (_myRole == 'Guru') {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => GuruTugasDetailScreen(tugas: tugas, token: widget.token)));
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => SiswaTugasDetailScreen(tugas: tugas, userData: widget.userData, token: widget.token)));
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error fetch tugas: $e');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withAlpha(15),
                                  border: Border.all(color: theme.colorScheme.secondary.withAlpha(60)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.clipboardList, color: theme.colorScheme.secondary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(post['pesan'] ?? 'Lihat detail tugas', style: TextStyle(color: onSurface, fontFamily: 'Inter')),
                                          if (post['deadline_tugas'] != null)
                                            Text('Deadline: ${post['deadline_tugas'].toString().split('T')[0]}',
                                                style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Icon(LucideIcons.chevronRight, size: 16, color: theme.colorScheme.secondary),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(post['pesan'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurfaceVariant,
                                  fontFamily: 'Inter',
                                  height: 1.5,
                                )),
                          ],

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: isDark ? const Color(0xFF414944) : const Color(0xFFC1C8C2))),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.forum, size: 16, color: onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('$repliesCount Balasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface, fontFamily: 'Inter')),
                                const SizedBox(width: 24),
                                Icon(Icons.history, size: 16, color: onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('Aktif $lastActive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // DAFTAR BALASAN (REPLIES)
              if (replies.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF4FAFF),
                    border: Border(top: BorderSide(color: isDark ? const Color(0xFF414944) : const Color(0xFFC1C8C2))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: replies
                        .map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                      radius: 12,
                                      backgroundColor: onSurfaceVariant.withAlpha(50),
                                      child: Text(
                                          r['pengirim_nama']?[0].toUpperCase() ?? '?',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: onSurface))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['pengirim_nama'] ?? 'User',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface, fontFamily: 'Inter')),
                                        const SizedBox(height: 2),
                                        Text(r['pesan'] ?? '',
                                            style: TextStyle(fontSize: 13, color: onSurfaceVariant, fontFamily: 'Inter')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),

              // INPUT BALASAN BAWAH (REPLY)
              _buildReplySection(postId, isDark),
            ],
          ),
        ),
        if (isTugas)
          Positioned(
            top: 11,
            right: 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8D4D33),
                border: Border.all(color: onSurfaceVariant),
              ),
              child: const Text('TUGAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    letterSpacing: 0.5,
                  )),
            ),
          ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildReplySection(String postId, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _replyingToId == postId
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: InputDecoration(
                        hintText: "Reply...",
                        hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.send, size: 20),
                  onPressed: _isSending
                      ? null
                      : () => _postMessage(
                          parentId: postId, text: _replyCtrl.text.trim()),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _replyingToId = null)),
              ],
            )
          : TextButton.icon(
              onPressed: () => setState(() {
                _replyingToId = postId;
                _replyCtrl.clear();
              }),
              icon: const Icon(LucideIcons.messageSquare, size: 16),
              label: Text("Reply", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildNewPostButton(ThemeData theme, bool isDark) {
    const accentColor = Color(0xFF76AFB8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: PremiumElevatedButton(
        onPressed: () => _showNewPostDialog(),
        color: accentColor,
        textColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        radius: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 20),
            const SizedBox(width: 8),
            Text("Start a new conversation",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showNewPostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("New Post",
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pesanCtrl,
                maxLines: 5,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black.withValues(alpha: 0.3)),
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PremiumElevatedButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _postMessage(text: _pesanCtrl.text.trim());
                            Navigator.pop(context);
                          },
                    color: AppTheme.info,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    radius: 12,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Post")),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}
