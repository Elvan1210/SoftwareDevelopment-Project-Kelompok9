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

    final mainPosts = _allData
        .where((m) =>
            (m['channel_id']?.toString() ?? 'general') == widget.channelId &&
            m['parentId'] == null)
        .toList();

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    itemCount: mainPosts.length,
                    itemBuilder: (context, i) =>
                        _buildPostThread(mainPosts[i], isDark, theme),
                  ),
          ),
          _buildNewPostButton(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildPostThread(
      Map<String, dynamic> post, bool isDark, ThemeData theme) {
    final postId = post['id']?.toString() ?? post['_id']?.toString() ?? '';
    final replies = _allData.where((m) => m['parentId'] == postId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // POSTINGAN UTAMA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                      radius: 18,
                      child:
                          Text(post['pengirim_nama']?[0].toUpperCase() ?? '?')),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['pengirim_nama'] ?? 'User',
                            style:
                                GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Text(post['waktu']?.toString().split('T')[0] ?? '',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.65))),
                      ])
                ]),
                const SizedBox(height: 12),
                // Cek apakah ini post tugas
                if (post['tipe'] == 'tugas') ...[
                  GestureDetector(
                    onTap: () async {
                      final tugasId = post['tugas_id'];
                      if (tugasId == null) return;

                      // Fetch data tugas
                      try {
                        final res = await http.get(
                          Uri.parse('$baseUrl/api/tugas/$tugasId'),
                          headers: {'Authorization': 'Bearer ${widget.token}'},
                        );
                        if (res.statusCode == 200 && mounted) {
                          final tugas = jsonDecode(res.body);
                          if (_myRole == 'Guru') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuruTugasDetailScreen(
                                      tugas: tugas, token: widget.token),
                                ));
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SiswaTugasDetailScreen(
                                    tugas: tugas,
                                    userData: widget.userData,
                                    token: widget.token,
                                    // hapus teamData
                                  ),
                                ));
                          }
                        }
                      } catch (e) {
                        debugPrint('Error fetch tugas: $e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.secondary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(LucideIcons.clipboardList,
                                color: theme.colorScheme.secondary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['judul_tugas'] ?? post['pesan'] ?? '-',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (post['deadline_tugas'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.clock,
                                          size: 12,
                                          color: theme.colorScheme.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Deadline: ${post['deadline_tugas'].toString().split('T')[0]}',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight,
                              size: 16, color: theme.colorScheme.secondary),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Text(post['pesan'] ?? '',
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // DAFTAR BALASAN (REPLIES)
          if (replies.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark
                  ? Colors.white.withAlpha(5)
                  : Colors.grey.withAlpha(10),
              child: Column(
                children: replies
                    .map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                      r['pengirim_nama']?[0].toUpperCase() ??
                                          '?',
                                      style: Theme.of(context).textTheme.labelMedium)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['pengirim_nama'] ?? 'User',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    Text(r['pesan'] ?? '',
                                        style: Theme.of(context).textTheme.titleMedium),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
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
