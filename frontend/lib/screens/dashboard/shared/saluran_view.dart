import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SaluranView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const SaluranView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<SaluranView> createState() => _SaluranViewState();
}

class _SaluranViewState extends State<SaluranView> {
  final TextEditingController _pesanCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _channelNameCtrl = TextEditingController();

  List<dynamic> _channels = [];
  List<dynamic> _pesan = [];
  
  String _selectedChannelId = 'general';
  String _selectedChannelName = 'General';
  
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
  void dispose() {
    _pesanCtrl.dispose();
    _scrollCtrl.dispose();
    _channelNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final resChannel = await http.get(Uri.parse('$baseUrl/api/channels?kelas_id=$_kelasId'), headers: headers);
      final resPesan = await http.get(Uri.parse('$baseUrl/api/saluran?kelas_id=$_kelasId'), headers: headers);
      
      if (resChannel.statusCode == 200) {
        final dec = jsonDecode(resChannel.body);
        _channels = dec is List ? dec : [];
      }
      
      if (resPesan.statusCode == 200) {
        final dec = jsonDecode(resPesan.body);
        final List<dynamic> raw = dec is List ? dec : [];
        raw.sort((a, b) {
          final ta = DateTime.tryParse(a['waktu'] ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b['waktu'] ?? '') ?? DateTime(2000);
          return ta.compareTo(tb);
        });
        _pesan = raw;
      }
    } catch (e) {
      debugPrint('Error fetch data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  List<dynamic> get _filteredPesan {
    return _pesan.where((msg) {
      final cId = msg['channel_id']?.toString();
      if (_selectedChannelId == 'general') {
        return cId == null || cId == 'general' || cId == '';
      }
      return cId == _selectedChannelId;
    }).toList();
  }

  Future<void> _buatChannel() async {
    final name = _channelNameCtrl.text.trim();
    if (name.isEmpty) return;

    final body = {
      'kelas_id': _kelasId,
      'nama_channel': name,
      'created_by_id': _myId,
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
          Navigator.pop(context); // Close dialog
          _fetchData();
        }
      }
    } catch (e) {
      debugPrint('Err buat channel: $e');
    }
  }

  Future<void> _kirimPesan() async {
    final text = _pesanCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _pesanCtrl.clear();

    final body = {
      'kelas_id': _kelasId,
      'channel_id': _selectedChannelId,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 800;

      if (isDesktop) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Channel List
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: theme.dividerColor.withAlpha(50))),
              ),
              child: _buildChannelList(theme),
            ),
            // Right Panel: Chat Room
            Expanded(
              child: _buildChatRoom(theme, isDark),
            ),
          ],
        );
      }

      // Mobile Layout
      return Column(
        children: [
          _buildMobileChannelDropdown(theme, isDark),
          Expanded(child: _buildChatRoom(theme, isDark)),
        ],
      );
    });
  }

  Widget _buildChannelList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Channels', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if (_canManage)
                IconButton(
                  onPressed: _showCreateChannelDialog,
                  icon: const Icon(Icons.add_box_rounded),
                  color: theme.primaryColor,
                  tooltip: 'Buat Channel Baru',
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildChannelItem('general', 'General', theme),
              for (var c in _channels) 
                _buildChannelItem(c['id'].toString(), c['nama_channel'] ?? 'Unnamed', theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelItem(String id, String name, ThemeData theme) {
    final isSelected = id == _selectedChannelId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedChannelId = id;
            _selectedChannelName = name;
          });
          _scrollToBottom();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.tag_rounded : Icons.numbers_rounded, 
                size: 18, 
                color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileChannelDropdown(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChannelId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: [
                  const DropdownMenuItem(value: 'general', child: Text('General', style: TextStyle(fontWeight: FontWeight.w800))),
                  for (var c in _channels)
                    DropdownMenuItem(value: c['id'].toString(), child: Text(c['nama_channel'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    final target = val == 'general' ? 'General' : _channels.firstWhere((e) => e['id'].toString() == val, orElse: () => {'nama_channel': 'Unknown'})['nama_channel'];
                    setState(() {
                      _selectedChannelId = val;
                      _selectedChannelName = target;
                    });
                    _scrollToBottom();
                  }
                },
              ),
            ),
          ),
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.add_box_rounded),
              color: theme.primaryColor,
              onPressed: _showCreateChannelDialog,
            )
        ],
      ),
    );
  }

  Widget _buildChatRoom(ThemeData theme, bool isDark) {
    final msgs = _filteredPesan;
    return Column(
      children: [
        // ── Header Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
            border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '# $_selectedChannelName',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
              ),
              IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh_rounded, size: 20), tooltip: 'Refresh'),
            ],
          ),
        ),

        // ── Pesan Area ──
        Expanded(
          child: _isLoading
              ? _buildSkeleton()
              : msgs.isEmpty
                  ? _buildEmpty(theme)
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: msgs.length,
                        itemBuilder: (context, i) {
                          final msg = msgs[i];
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
                          hintText: 'Tulis pesan di #$_selectedChannelName...',
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
          Text('Belum ada pesan di saluran ini.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withAlpha(120))),
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
}
