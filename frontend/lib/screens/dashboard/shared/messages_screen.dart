import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../widgets/premium_ui.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MessagesScreen({super.key, required this.userData});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  io.Socket? socket;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> messages = [];

  String? activeConversationId;
  String? activeChatName;
  String? activeConversationType;
  Map<String, dynamic> activeParticipantNames = {};

  bool isLoading = true;

  String get myId =>
      widget.userData['id']?.toString() ??
      widget.userData['uid']?.toString() ??
      widget.userData['_id']?.toString() ??
      'admin';
  String get myName => widget.userData['nama']?.toString() ?? 'User';

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchConversations();
  }

  void initSocket() {
    socket = io.io(
      'http://localhost:3000',
      io.OptionBuilder().setTransports(['websocket']).build(),
    );

    if (socket != null) {
      socket!.connect();

      socket!.onConnect((_) {
        socket!.emit('user_connected', myId);
        if (activeConversationId != null) {
          socket!.emit('join_chat', activeConversationId);
        }
      });

      socket!.on('update_conversation_list', (_) {
        if (mounted) fetchConversations();
      });

      socket!.on('load_messages', (data) {
        if (mounted) {
          setState(() => messages = List<Map<String, dynamic>>.from(data));
        }
      });

      socket!.on('receive_message', (data) {
        if (mounted && data['conversationId'] == activeConversationId) {
          setState(() => messages.add(Map<String, dynamic>.from(data)));
          fetchConversations();
        }
      });
    }
  }

  Future<void> fetchConversations() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:3000/api/chat/conversations/$myId'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          conversations =
              List<Map<String, dynamic>>.from(json.decode(res.body));
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchConversations error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _displayChatName(Map<String, dynamic> conv) {
    if (conv['type'] == 'group') return conv['name'] ?? 'Grup Tanpa Nama';
    if (conv['participantNames'] != null) {
      Map<String, dynamic> pNames =
          Map<String, dynamic>.from(conv['participantNames']);
      for (var key in pNames.keys) {
        if (key.toString() != myId.toString()) return pNames[key] ?? 'User';
      }
    }
    return 'Private Chat';
  }

  // ✅ FIX: Bandingkan sebagai String supaya tidak mismatch tipe
  String? _getTargetUserId(Map<String, dynamic> conv) {
    if (conv['type'] == 'group') return null;
    if (conv['participantNames'] != null) {
      Map<String, dynamic> pNames =
          Map<String, dynamic>.from(conv['participantNames']);
      for (var key in pNames.keys) {
        if (key.toString() != myId.toString()) return key.toString();
      }
    }
    return null;
  }

  void selectConversation(Map<String, dynamic> conv, String name) {
    setState(() {
      activeConversationId = conv['id'];
      activeChatName = name;
      activeConversationType = conv['type'];
      activeParticipantNames =
          Map<String, dynamic>.from(conv['participantNames'] ?? {});
      messages = [];
    });
    if (socket != null) socket!.emit('join_chat', conv['id']);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty &&
        activeConversationId != null &&
        socket != null) {
      socket!.emit('send_message', {
        'conversationId': activeConversationId,
        'senderId': myId,
        'senderName': myName,
        'text': _messageController.text.trim(),
      });
      _messageController.clear();
    }
  }

  void _showGroupInfo() {
    if (activeConversationType != 'group') return;

    showDialog(
      context: context,
      builder: (context) {
        final entries = activeParticipantNames.entries.toList();
        return AlertDialog(
          title: Text(
            "Info: $activeChatName",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: entries.isEmpty
                ? const Center(child: Text("Data anggota tidak tersedia."))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final id = entries[i].key;
                      final name = entries[i].value.toString();
                      final inisial =
                          name.isNotEmpty ? name[0].toUpperCase() : '?';
                      return ListTile(
                        leading: _buildAvatar(id, inisial),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(id == myId ? "Anda" : "Anggota"),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
            ),
          ],
        );
      },
    );
  }

  void _showNewChatMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withAlpha(40),
                child: Icon(Icons.person,
                    color: Theme.of(context).primaryColor),
              ),
              title: const Text("Chat Pribadi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Mulai obrolan dengan satu orang"),
              onTap: () {
                Navigator.pop(context);
                _showUserList(isGroup: false);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withAlpha(40),
                child:
                    Icon(Icons.group, color: Theme.of(context).primaryColor),
              ),
              title: const Text("Buat Grup Baru",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Mulai obrolan dengan banyak orang"),
              onTap: () {
                Navigator.pop(context);
                _showUserList(isGroup: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserList({required bool isGroup}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res =
          await http.get(Uri.parse('http://localhost:3000/api/chat/users'));
      if (mounted) Navigator.pop(context);
      if (res.statusCode == 200) {
        List<dynamic> users = json.decode(res.body);
        users = users
            .where((u) =>
                (u['id'] ?? u['uid'] ?? u['_id']).toString() !=
                myId.toString())
            .toList();
        if (!isGroup) {
          _openPrivateChatPicker(users);
        } else {
          _showCreateGroupDialog(users);
        }
      }
    } catch (e) {
      debugPrint('showUserList error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _openPrivateChatPicker(List<dynamic> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Kontak"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              final namaUser = user['nama'] ?? 'User';
              final userId = (user['id'] ?? user['uid'] ?? user['_id']).toString();
              return ListTile(
                leading: _buildAvatar(userId, namaUser[0].toUpperCase()),
                title: Text(namaUser),
                subtitle: Text(user['role'] ?? 'Member'),
                onTap: () {
                  Navigator.pop(context);
                  _startConv(
                    [myId, userId],
                    {myId: myName, userId: namaUser},
                    'private',
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(List<dynamic> users) {
    String groupName = "";
    List<String> selectedIds = [];
    List<dynamic> selectedUsers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Buat Grup Baru"),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => groupName = v,
                    decoration: const InputDecoration(
                      hintText: "Masukkan Nama Grup",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Pilih Anggota:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        final uId = (user['id'] ?? user['uid'] ?? user['_id']).toString();
                        final isSelected = selectedIds.contains(uId);
                        return CheckboxListTile(
                          title: Text(user['nama'] ?? 'User'),
                          value: isSelected,
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedIds.add(uId);
                                selectedUsers.add(user);
                              } else {
                                selectedIds.remove(uId);
                                selectedUsers.removeWhere((u) =>
                                    (u['id'] ?? u['uid'] ?? u['_id'])
                                        .toString() ==
                                    uId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Batal", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(160))),
              ),
              PremiumElevatedButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 12,
                onPressed: () {
                  if (groupName.isEmpty || selectedIds.isEmpty) return;
                  Navigator.pop(context);
                  Map<String, String> pNames = {myId: myName};
                  for (var u in selectedUsers) {
                    final uid = (u['id'] ?? u['uid'] ?? u['_id']).toString();
                    pNames[uid] = u['nama'] ?? 'User';
                  }
                  _startConv(
                    [myId, ...selectedIds],
                    pNames,
                    'group',
                    groupName: groupName,
                  );
                },
                child: const Text("Buat Grup"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startConv(
    List<String> parts,
    Map<String, dynamic> names,
    String type, {
    String? groupName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/chat/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'participants': parts,
          'participantNames': names,
          'type': type,
          'groupName': groupName,
        }),
      );
      if (res.statusCode == 200) {
        final conv = json.decode(res.body);
        if (mounted) {
          fetchConversations();
          String finalName = type == 'group'
              ? groupName!
              : names.entries
                  .firstWhere((e) => e.key != myId)
                  .value;
          selectConversation(conv, finalName);
        }
      }
    } catch (e) {
      debugPrint("_startConv error: $e");
    }
  }

  // ✅ FIX: _buildAvatar lebih robust, handle null/empty userId
  Widget _buildAvatar(String? userId, String initial) {
    if (userId == null || userId.isEmpty || userId == 'null') {
      return CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
        child: Text(
          initial,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String currentStatus = 'Appear Offline';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          currentStatus = data?['status'] ?? 'Appear Offline';
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
              child: Text(
                initial,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.getStatusColor(currentStatus),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (socket != null && socket!.connected) {
      socket!.disconnect();
      socket!.dispose();
    }
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;

    final chatList = Container(
      width: isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: const Text(
              "Messages",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            trailing: IconButton(
              icon: Icon(Icons.add_comment,
                  color: Theme.of(context).primaryColor),
              onPressed: _showNewChatMenu,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada obrolan.\nKlik ikon + untuk mulai.",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          final convName = _displayChatName(conv);
                          final inisial = convName.isNotEmpty
                              ? convName[0].toUpperCase()
                              : '?';
                          final targetId = _getTargetUserId(conv);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            leading: conv['type'] == 'group'
                                ? CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withAlpha(40),
                                    child: Text(
                                      inisial,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor),
                                    ),
                                  )
                                : _buildAvatar(targetId, inisial),
                            title: Text(
                              convName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              conv['lastMessage'] ?? '...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: activeConversationId == conv['id'],
                            selectedTileColor:
                                Theme.of(context).primaryColor.withAlpha(20),
                            onTap: () => selectConversation(conv, convName),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    final chatWindow = activeConversationId == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.messageSquare,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
                const SizedBox(height: 16),
                Text(
                  "Pilih obrolan dari kiri atau mulai chat baru",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              AppBar(
                leading: isMobile
                    ? IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () =>
                            setState(() => activeConversationId = null),
                      )
                    : null,
                title: InkWell(
                  onTap: activeConversationType == 'group'
                      ? _showGroupInfo
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeChatName ?? 'Chat',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (activeConversationType == 'group')
                          Text(
                            "Ketuk untuk info grup",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                elevation: 1,
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
              ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text("Kirim pesan pertama!"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == myId;
                          final isGroup = activeConversationType == 'group';

                          String timeStr = "";
                          if (msg['timestamp'] != null) {
                            try {
                              final dt =
                                  DateTime.parse(msg['timestamp']).toLocal();
                              timeStr =
                                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                            } catch (e) {
                              debugPrint('timestamp parse error: $e');
                            }
                          }

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints:
                                  const BoxConstraints(maxWidth: 400),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : (isDark
                                        ? const Color(0xFF1C2230)
                                        : const Color(0xFFF0F3FF)),
                                border: isMe
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? const Color(0xFF2E384E)
                                            : const Color(0xFFC7D2FE),
                                        width: 1.0,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                  bottomLeft: !isMe
                                      ? const Radius.circular(4)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isGroup && !isMe) ...[
                                    Text(
                                      msg['senderName'] ?? 'User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.blue[300]
                                            : Colors.blue[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.black54),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Ketik pesan...",
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF101420)
                              : const Color(0xFFF1F3FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF2E384E) : const Color(0xFFC7D2FE),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF2E384E) : const Color(0xFFC7D2FE),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(LucideIcons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isMobile
          ? (activeConversationId == null ? chatList : chatWindow)
          : Row(
              children: [
                chatList,
                Expanded(child: chatWindow),
              ],
            ),
    );
  }
}