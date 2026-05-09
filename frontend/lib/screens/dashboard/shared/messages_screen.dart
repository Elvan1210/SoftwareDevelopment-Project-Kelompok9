import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> userData; 
  const MessagesScreen({super.key, required this.userData});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  IO.Socket? socket;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> messages = [];
  
  // State untuk menyimpan data obrolan yang sedang aktif
  String? activeConversationId;
  String? activeChatName;
  String? activeConversationType; 
  Map<String, dynamic> activeParticipantNames = {}; // Menyimpan daftar anggota
  
  bool isLoading = true;

  String get myId => widget.userData['id'] ?? widget.userData['uid'] ?? widget.userData['_id'] ?? 'admin';
  String get myName => widget.userData['nama'] ?? 'User';

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchConversations();
  }

  void initSocket() {
    socket = IO.io('http://localhost:3000', IO.OptionBuilder().setTransports(['websocket']).build());
    
    if (socket != null) {
      socket!.connect();

      socket!.onConnect((_) {
        socket!.emit('user_connected', myId);
        if (activeConversationId != null) socket!.emit('join_chat', activeConversationId);
      });

      socket!.on('update_conversation_list', (_) {
        if (mounted) fetchConversations();
      });

      socket!.on('load_messages', (data) {
        if (mounted) setState(() => messages = List<Map<String, dynamic>>.from(data));
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
      final res = await http.get(Uri.parse('http://localhost:3000/api/chat/conversations/$myId'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          conversations = List<Map<String, dynamic>>.from(json.decode(res.body));
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _displayChatName(Map<String, dynamic> conv) {
    if (conv['type'] == 'group') return conv['name'] ?? 'Grup Tanpa Nama';
    if (conv['participantNames'] != null) {
      Map<String, dynamic> pNames = conv['participantNames'];
      for (var key in pNames.keys) {
        if (key != myId) return pNames[key] ?? 'User';
      }
    }
    return 'Private Chat';
  }

  // UPDATE: Memperbarui fungsi saat obrolan dipilih untuk menyimpan tipe dan anggota
  void selectConversation(Map<String, dynamic> conv, String name) {
    setState(() {
      activeConversationId = conv['id'];
      activeChatName = name;
      activeConversationType = conv['type'];
      activeParticipantNames = Map<String, dynamic>.from(conv['participantNames'] ?? {});
      messages = [];
    });
    if (socket != null) socket!.emit('join_chat', conv['id']);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && activeConversationId != null && socket != null) {
      socket!.emit('send_message', {
        'conversationId': activeConversationId,
        'senderId': myId,
        'senderName': myName,
        'text': _messageController.text.trim(),
      });
      _messageController.clear();
    }
  }

  // ─── FITUR BARU: MENAMPILKAN INFO GRUP (ANGGOTA) ───
  void _showGroupInfo() {
    if (activeConversationType != 'group') return;
    
    showDialog(
      context: context,
      builder: (context) {
        final entries = activeParticipantNames.entries.toList();
        return AlertDialog(
          title: Text("Info: $activeChatName", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: entries.isEmpty
                ? const Center(child: Text("Data anggota tidak tersedia (grup lama)."))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final id = entries[i].key;
                      final name = entries[i].value.toString();
                      final inisial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
                          child: Text(inisial, style: TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(id == myId ? "Anda" : "Anggota"),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
          ],
        );
      }
    );
  }

  void _showNewChatMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withAlpha(40), child: Icon(Icons.person, color: Theme.of(context).primaryColor)),
              title: const Text("Chat Pribadi", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Mulai obrolan dengan satu orang"),
              onTap: () { Navigator.pop(context); _showUserList(isGroup: false); },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withAlpha(40), child: Icon(Icons.group, color: Theme.of(context).primaryColor)),
              title: const Text("Buat Grup Baru", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Mulai obrolan dengan banyak orang"),
              onTap: () { Navigator.pop(context); _showUserList(isGroup: true); },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserList({required bool isGroup}) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/chat/users'));
      if (mounted) Navigator.pop(context); 
      if (res.statusCode == 200) {
        List<dynamic> users = json.decode(res.body);
        users = users.where((u) => (u['id'] ?? u['uid'] ?? u['_id']) != myId).toList();
        if (!isGroup) {
          _openPrivateChatPicker(users);
        } else {
          _showCreateGroupDialog(users);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _openPrivateChatPicker(List<dynamic> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Kontak"),
        content: SizedBox(
          width: double.maxFinite, height: 400,
          child: ListView.builder(
            shrinkWrap: true, itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              final namaUser = user['nama'] ?? 'User';
              return ListTile(
                leading: CircleAvatar(child: Text(namaUser[0].toUpperCase())),
                title: Text(namaUser), subtitle: Text(user['role'] ?? 'Member'),
                onTap: () {
                  Navigator.pop(context);
                  final targetId = user['id'] ?? user['uid'] ?? user['_id'];
                  _startConv([myId, targetId], {myId: myName, targetId: namaUser}, 'private');
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal"))],
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
              width: double.maxFinite, height: 400,
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => groupName = v,
                    decoration: const InputDecoration(hintText: "Masukkan Nama Grup", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  const Align(alignment: Alignment.centerLeft, child: Text("Pilih Anggota:", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        final uId = user['id'] ?? user['uid'] ?? user['_id'];
                        final isSelected = selectedIds.contains(uId);
                        
                        return CheckboxListTile(
                          title: Text(user['nama'] ?? 'User'),
                          value: isSelected,
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedIds.add(uId);
                                selectedUsers.add(user); // Simpan detail user
                              } else {
                                selectedIds.remove(uId);
                                selectedUsers.removeWhere((u) => (u['id'] ?? u['uid'] ?? u['_id']) == uId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  if (groupName.isEmpty || selectedIds.isEmpty) return;
                  Navigator.pop(context);
                  
                  // UPDATE: Menyusun map nama anggota agar bisa ditampilkan di fitur info grup
                  Map<String, String> pNames = {myId: myName};
                  for (var u in selectedUsers) {
                    final uid = u['id'] ?? u['uid'] ?? u['_id'];
                    pNames[uid] = u['nama'] ?? 'User';
                  }
                  
                  _startConv([myId, ...selectedIds], pNames, 'group', groupName: groupName);
                },
                child: const Text("Buat Grup"),
              )
            ],
          );
        }
      ),
    );
  }

  void _startConv(List<String> parts, Map<String, dynamic> names, String type, {String? groupName}) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/chat/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'participants': parts, 'participantNames': names, 'type': type, 'groupName': groupName})
      );
      if (res.statusCode == 200) {
        final conv = json.decode(res.body);
        if (mounted) {
          fetchConversations();
          String finalName = type == 'group' ? groupName! : names.entries.firstWhere((e) => e.key != myId).value;
          selectConversation(conv, finalName);
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
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
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // ─── KIRI: LIST CHAT ───
          Container(
            width: 300,
            decoration: BoxDecoration(border: Border(right: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                  trailing: IconButton(icon: Icon(Icons.add_comment, color: Theme.of(context).primaryColor), onPressed: _showNewChatMenu),
                ),
                Expanded(
                  child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : conversations.isEmpty 
                    ? const Center(child: Text("Belum ada obrolan.\nKlik ikon + untuk mulai.", textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          final convName = _displayChatName(conv); 
                          final inisial = convName.isNotEmpty ? convName[0].toUpperCase() : '?';
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(child: Text(inisial)),
                            title: Text(convName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(conv['lastMessage'] ?? '...', maxLines: 1, overflow: TextOverflow.ellipsis),
                            selected: activeConversationId == conv['id'],
                            selectedTileColor: Theme.of(context).primaryColor.withAlpha(20),
                            onTap: () => selectConversation(conv, convName), // Mengirim seluruh object conv
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          
          // ─── KANAN: JENDELA CHAT ───
          Expanded(
            child: activeConversationId == null 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                    const SizedBox(height: 16),
                    const Text("Pilih obrolan dari kiri atau mulai chat baru", style: TextStyle(color: Colors.grey)),
                  ],
                )
              )
            : Column(
                children: [
                  // UPDATE: AppBar bisa diklik untuk melihat Info Grup
                  AppBar(
                    title: InkWell(
                      onTap: activeConversationType == 'group' ? _showGroupInfo : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeChatName ?? 'Chat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            if (activeConversationType == 'group')
                              const Text("Ketuk untuk info grup", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    elevation: 1, backgroundColor: Colors.transparent, scrolledUnderElevation: 0,
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
                          
                          // Format Waktu (Contoh: 14:05)
                          String timeStr = "";
                          if (msg['timestamp'] != null) {
                            try {
                              final dt = DateTime.parse(msg['timestamp']).toLocal();
                              timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                            } catch(e) {}
                          }
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).primaryColor : (isDark ? Colors.white10 : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Munculkan nama pengirim hanya jika di grup & bukan pesan sendiri
                                  if (isGroup && !isMe) ...[
                                    Text(
                                      msg['senderName'] ?? 'User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isDark ? Colors.blue[300] : Colors.blue[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  
                                  Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 15)),
                                  
                                  const SizedBox(height: 4),
                                  // Menampilkan Waktu (Timestamp) di pojok bawah bubble
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54),
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
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController, 
                            decoration: InputDecoration(
                              hintText: "Ketik pesan...", filled: true, fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          )
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
}