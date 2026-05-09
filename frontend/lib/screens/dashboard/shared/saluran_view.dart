import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;
  String? _replyingToId; // ID postingan yang sedang dibalas

  String get _kelasId => widget.teamData['id']?.toString() ?? '';
  String get _myId => widget.userData['id']?.toString() ?? widget.userData['uid']?.toString() ?? '';
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
      final resPesan = await http.get(Uri.parse('$baseUrl/api/saluran?kelas_id=$_kelasId'), headers: headers);
      
      if (resPesan.statusCode == 200) {
        final decoded = jsonDecode(resPesan.body) as List;
        setState(() {
          _allData = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postMessage({String? parentId, required String text}) async {
    if (text.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/api/saluran'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({
          'kelas_id': _kelasId,
          'channel_id': widget.channelId,
          'pengirim_id': _myId,
          'pengirim_nama': _myNama,
          'role': _myRole,
          'pesan': text,
          'parentId': parentId, // Penting untuk sistem reply
          'waktu': DateTime.now().toIso8601String(),
        }),
      );
      _fetchData();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter pesan utama (bukan reply)
    final mainPosts = _allData.where((m) => 
      (m['channel_id']?.toString() ?? 'general') == widget.channelId && 
      m['parentId'] == null
    ).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F2F1),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : mainPosts.isEmpty 
              ? const Center(child: Text("No posts yet. Start a conversation!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: mainPosts.length,
                  itemBuilder: (context, i) => _buildPostThread(mainPosts[i], isDark, theme),
                ),
          ),
          _buildNewPostButton(theme, isDark),
        ],
      ),
    );
  }

  // ── UNIT POSTINGAN UTAMA + BALASANNYA ──
  Widget _buildPostThread(Map<String, dynamic> post, bool isDark, ThemeData theme) {
    final postId = post['id']?.toString() ?? post['_id']?.toString() ?? '';
    final replies = _allData.where((m) => m['parentId'] == postId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Utama
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(radius: 16, child: Text(post['pengirim_nama']?[0].toUpperCase() ?? '?')),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post['pengirim_nama'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post['waktu']?.toString().split('T')[0] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])
                ]),
                const SizedBox(height: 12),
                Text(post['pesan'] ?? '', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // List Balasan (Replies)
          if (replies.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.white.withAlpha(5) : Colors.grey.withAlpha(10),
              child: Column(
                children: replies.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 12, child: Text(r['pengirim_nama']?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 10))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['pengirim_nama'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(r['pesan'] ?? '', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

          // Tombol Reply / Input Balasan
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _replyingToId == postId
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: "Reply...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.send, size: 20),
                      onPressed: () {
                        _postMessage(parentId: postId, text: _replyCtrl.text.trim());
                        _replyCtrl.clear();
                        setState(() => _replyingToId = null);
                      },
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _replyingToId = null)),
                  ],
                )
              : TextButton.icon(
                  onPressed: () => setState(() {
                    _replyingToId = postId;
                    _replyCtrl.clear();
                  }),
                  icon: const Icon(LucideIcons.messageSquare, size: 16),
                  label: const Text("Reply"),
                ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ── TOMBOL POSTINGAN BARU DI BAWAH ──
  Widget _buildNewPostButton(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showNewPostDialog(theme),
        icon: const Icon(Icons.add),
        label: const Text("Start a new conversation", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showNewPostDialog(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("New Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _pesanCtrl,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(hintText: "What's on your mind?", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _postMessage(text: _pesanCtrl.text.trim());
                  _pesanCtrl.clear();
                  Navigator.pop(context);
                }, 
                child: const Text("Post")
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}