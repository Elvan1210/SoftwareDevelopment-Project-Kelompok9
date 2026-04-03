import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
    this.channelName = 'Saluran Utama', // Default nama untuk groupchat utama
  });

  @override
  State<SaluranView> createState() => _SaluranViewState();
}

class _SaluranViewState extends State<SaluranView> {
  final TextEditingController _pesanCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<dynamic> _pesan = [];
  bool _isLoading = true;
  bool _isSending = false;

  String get _kelasId => widget.teamData['id']?.toString() ?? '';
  String get _myId => widget.userData['id']?.toString() ?? widget.userData['uid']?.toString() ?? '';
  String get _myNama => widget.userData['nama']?.toString() ?? widget.userData['email']?.toString() ?? 'Pengguna';
  String get _myRole => widget.userData['role']?.toString() ?? 'Siswa';
  bool get _canManage => _myRole == 'Guru' || _myRole == 'Admin';

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

  @override
  void dispose() {
    _pesanCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resPesan = await http.get(Uri.parse('$baseUrl/api/saluran?kelas_id=$_kelasId'), headers: headers);
      
      if (resPesan.statusCode == 200) {
        final dec = jsonDecode(resPesan.body);
        final List<dynamic> raw = dec is List ? dec : [];
        raw.sort((a, b) {
          final ta = DateTime.tryParse(a['waktu'] ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b['waktu'] ?? '') ?? DateTime(2000);
          return ta.compareTo(tb);
        });
        
        // Filter by channel_id locally
        _pesan = raw.where((msg) {
          final cId = msg['channel_id']?.toString();
          if (widget.channelId == 'general') {
            return cId == null || cId == 'general' || cId == '';
          }
          return cId == widget.channelId;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetch data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _kirimPesan() async {
    final text = _pesanCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _pesanCtrl.clear();

    final body = {
      'kelas_id': _kelasId,
      'channel_id': widget.channelId,
      'pengirim_id': _myId,
      'pengirim_nama': _myNama,
      'role': _myRole,
      'pesan': text,
      'waktu': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/saluran'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        await _fetchData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan')));
      }
    } catch (e) {
      debugPrint('Err kirim: $e');
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _hapusPesan(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/saluran/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        await _fetchData();
      }
    } catch (e) {
      debugPrint('Error hapus pesan: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ── Header Status Bar (menunjukkan nama channel) ──
        if (widget.channelId != 'general')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
              border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
            ),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.channelName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

        // ── Pesan Area ──
        Expanded(
          child: _isLoading
              ? _buildSkeleton()
              : _pesan.isEmpty
                  ? _buildEmpty(theme)
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _pesan.length,
                        itemBuilder: (context, i) {
                          final msg = _pesan[i];
                          final isMe = msg['pengirim_id']?.toString() == _myId;
                          return _buildBubble(msg, isMe, isDark, theme)
                              .animate(delay: Duration(milliseconds: i > 10 ? 0 : i * 30))
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOutQuart);
                        },
                      ),
                    ),
        ),

        // ── Input Box ──
        _buildInputBar(theme, isDark),
      ],
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, bool isDark, ThemeData theme) {
    final time = DateTime.tryParse(msg['waktu'] ?? '');
    final timeStr = time != null ? DateFormat('HH:mm').format(time) : '';
    final role = msg['role']?.toString() ?? 'Siswa';
    final isGuru = role == 'Guru';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isGuru ? Colors.blue.withAlpha(40) : Colors.grey.withAlpha(40),
              child: Text(
                (msg['pengirim_nama'] ?? '?')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isGuru ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: _canManage
                  ? () => _confirmDelete(msg['id']?.toString() ?? '')
                  : null,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? theme.primaryColor : (isDark ? Colors.white.withAlpha(15) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(msg['pengirim_nama'] ?? 'Anonim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isGuru ? Colors.blue.shade400 : theme.primaryColor)),
                          if (isGuru) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Guru', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blue)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      msg['pesan'] ?? '',
                      style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withAlpha(170) : theme.colorScheme.onSurface.withAlpha(100)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(4),
        border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(50))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withAlpha(60)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _pesanCtrl,
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan di ${widget.channelId == 'general' ? 'saluran utama' : '#${widget.channelName}'}...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(100), fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        onSubmitted: (_) => _kirimPesan(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: _isSending ? null : _kirimPesan,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: theme.colorScheme.onSurface.withAlpha(60)),
          const SizedBox(height: 16),
          Text('Belum ada pesan di sini.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withAlpha(120))),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: i % 2 == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (i % 2 == 0) ...[const SkeletonLoader(height: 32, width: 32, radius: 16), const SizedBox(width: 8)],
            SkeletonLoader(height: 52, width: 180 + (i % 3 * 30).toDouble(), radius: 18),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pesan', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Hapus pesan ini dari saluran?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _hapusPesan(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Helper widget included locally
}

class SkeletonLoader extends StatelessWidget {
  final double width, height, radius;
  const SkeletonLoader({super.key, required this.width, required this.height, this.radius = 8});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withAlpha(20), borderRadius: BorderRadius.circular(radius)),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withAlpha(20));
  }
}
