import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';





class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MessagesScreen({super.key, required this.userData});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  io.Socket? socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
      'https://mypskd-backend.vercel.app',
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
        Uri.parse('https://mypskd-backend.vercel.app/api/chat/conversations/$myId'),
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: entries.isEmpty
                ? Center(child: Text("Data anggota tidak tersedia.", style: Theme.of(context).textTheme.titleMedium))
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(id == myId ? "Anda" : "Anggota", style: Theme.of(context).textTheme.bodyMedium),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withAlpha(160), fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showNewChatMenu() {
    showDialog(
      context: context,
      barrierColor: AppTheme.textLight.withAlpha(100), // bg-on-surface/40
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // backdrop-blur-[2px]
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400), // max-w-sm
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, // surface
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(40),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: AppTheme.textLight, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(8, 8))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Text(
                        "Mulai Pesan Baru",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24, // headline-lg-mobile roughly
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textLight,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pilih cara kamu ingin berkomunikasi hari ini.",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textMutedLt,
                        ),
                      ),
                      const SizedBox(height: 32),
                  
                  // OPTION 1: PESAN PRIBADI
                  _buildChatOptionCard(
                    title: "Pesan Pribadi",
                    subtitle: "Chat langsung dengan teman atau guru",
                    icon: LucideIcons.user,
                    iconColor: Colors.white,
                    iconBgColor: AppTheme.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showUserList(isGroup: false);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // OPTION 2: BUAT GRUP
                  _buildChatOptionCard(
                    title: "Buat Grup",
                    subtitle: "Mulai diskusi komunitas atau kelompok",
                    icon: LucideIcons.users,
                    iconColor: Colors.white,
                    iconBgColor: AppTheme.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showUserList(isGroup: true);
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // FOOTER ACTION: BATAL
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: AppTheme.textLight, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Batal",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMutedLt,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // DECORATIVE ELEMENTS
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AppTheme.textLight.withAlpha(40))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "MYPSKD ACADEMIC",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.textLight.withAlpha(80),
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: AppTheme.textLight.withAlpha(40))),
                    ],
                  )
                ],
              ),
            ),
            Positioned(
              top: -12,
              right: -8, // Perfectly sticking out slightly
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8D4D33), // tertiary from HTML
                  border: Border.all(color: AppTheme.textLight, width: 1.5),
                ),
                child: Text(
                  "NEW",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildChatOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAFF), // surface-container-low from HTML
          border: Border.all(color: AppTheme.textLight, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                border: Border.all(color: AppTheme.textLight, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMutedLt,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight, color: AppTheme.textMutedLt, size: 20),
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
          await http.get(Uri.parse('https://mypskd-backend.vercel.app/api/chat/users'));
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
    String searchQuery = "";

    showDialog(
      context: context,
      barrierColor: AppTheme.textLight.withAlpha(100),
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredUsers = users.where((u) {
            final name = (u['nama'] ?? 'User').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 795),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAFF),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppTheme.textLight, width: 4),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pilih Kontak",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textLight,
                              letterSpacing: -1,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFCEEDFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, color: AppTheme.textLight, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // SEARCH
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.textLight, width: 2),
                        ),
                        child: TextField(
                          onChanged: (v) {
                            setDialogState(() {
                              searchQuery = v;
                            });
                          },
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                          decoration: InputDecoration(
                            hintText: "Cari nama atau kelas...",
                            hintStyle: GoogleFonts.inter(color: AppTheme.textMutedLt),
                            border: InputBorder.none,
                            prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textMutedLt),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // CONTACT LIST
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, i) {
                          final user = filteredUsers[i];
                          final uId = (user['id'] ?? user['uid'] ?? user['_id']).toString();
                          final namaUser = user['nama'] ?? 'User';
                          final role = (user['role'] ?? 'MEMBER').toString().toUpperCase();
                          final isGuru = role == 'GURU';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _startConv(
                                    [myId, uId],
                                    {myId: myName, uId: namaUser},
                                    'private',
                                  );
                                },
                                splashColor: AppTheme.primaryContainer.withAlpha(100),
                                highlightColor: AppTheme.primaryContainer.withAlpha(50),
                                borderRadius: BorderRadius.circular(16), // So splash matches bounds roughly
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(color: AppTheme.textLight, width: 1),
                                      left: BorderSide(color: AppTheme.textLight, width: 1),
                                      right: BorderSide(color: AppTheme.textLight, width: 1),
                                      bottom: BorderSide(color: AppTheme.textLight, width: 4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildAvatar(uId, namaUser[0].toUpperCase()),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              namaUser,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textLight,
                                                height: 1.1,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isGuru ? "Guru • Staf" : "Siswa",
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: isGuru ? AppTheme.secondary : AppTheme.textMutedLt,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGuru ? const Color(0xFFBFEDD5) : const Color(0xFFFFDBCE),
                                          border: Border.all(color: AppTheme.textLight, width: 1),
                                        ),
                                        child: Text(
                                          role,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isGuru ? const Color(0xFF244F3D) : const Color(0xFF70371E),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // FOOTER
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            border: Border.all(color: AppTheme.textLight, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Batal",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog(List<dynamic> users) {
    String groupName = "";
    List<String> selectedIds = [];
    List<dynamic> selectedUsers = [];
    String searchQuery = "";

    showDialog(
      context: context,
      barrierColor: AppTheme.textLight.withAlpha(100),
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredUsers = users.where((u) {
            final name = (u['nama'] ?? 'User').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: AppTheme.textLight, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Buat Grup Baru",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mulai kolaborasi dengan tim belajar Anda.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textMutedLt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 2, color: AppTheme.textLight.withAlpha(20)),
                    
                    // CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAMA GRUP
                            Text(
                              "NAMA GRUP",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLight, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.textLight, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                              ),
                              child: TextField(
                                onChanged: (v) => groupName = v,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                                decoration: InputDecoration(
                                  hintText: "Contoh: Projek Biologi 12-A",
                                  hintStyle: GoogleFonts.inter(color: AppTheme.textMutedLt.withAlpha(150)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // CARI ANGGOTA
                            Text(
                              "CARI ANGGOTA",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLight, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.textLight, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                              ),
                              child: TextField(
                                onChanged: (v) {
                                  setDialogState(() {
                                    searchQuery = v;
                                  });
                                },
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                                decoration: InputDecoration(
                                  hintText: "Cari berdasarkan nama...",
                                  hintStyle: GoogleFonts.inter(color: AppTheme.textMutedLt.withAlpha(150)),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textLight),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // KONTAK TERSEDIA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "KONTAK TERSEDIA",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textLight, letterSpacing: 1.2),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      if (selectedIds.length == filteredUsers.length) {
                                        selectedIds.clear();
                                        selectedUsers.clear();
                                      } else {
                                        selectedIds = filteredUsers.map((u) => (u['id'] ?? u['uid'] ?? u['_id']).toString()).toList();
                                        selectedUsers = List.from(filteredUsers);
                                      }
                                    });
                                  },
                                  child: Text(
                                    selectedIds.length == filteredUsers.length ? "Batal Semua" : "Pilih Semua",
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.secondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // LIST ANGGOTA
                            ...filteredUsers.map((user) {
                              final uId = (user['id'] ?? user['uid'] ?? user['_id']).toString();
                              final namaUser = user['nama'] ?? 'User';
                              final isSelected = selectedIds.contains(uId);
                              
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      selectedIds.remove(uId);
                                      selectedUsers.removeWhere((u) => (u['id'] ?? u['uid'] ?? u['_id']).toString() == uId);
                                    } else {
                                      selectedIds.add(uId);
                                      selectedUsers.add(user);
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE8F6FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.textLight, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      _buildAvatar(uId, namaUser[0].toUpperCase()),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              namaUser,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textLight),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (user['role']?.toString().toLowerCase() == 'guru') ? AppTheme.secondary.withAlpha(25) : AppTheme.textLight.withAlpha(15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (user['role'] ?? 'MEMBER').toString().toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: (user['role']?.toString().toLowerCase() == 'guru') ? AppTheme.secondary : AppTheme.textMutedLt,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.secondary : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.textLight, width: 2),
                                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                                        ),
                                        alignment: Alignment.center,
                                        child: isSelected 
                                          ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                                          : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            
                          ],
                        ),
                      ),
                    ),
                    
                    // FOOTER
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6FF).withAlpha(80),
                        border: Border(top: BorderSide(color: AppTheme.textLight.withAlpha(30), width: 2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.textLight, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
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
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.textLight, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Buat Grup",
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.textLight, fontSize: 16),
                                ),
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
        Uri.parse('https://mypskd-backend.vercel.app/api/chat/conversations'),
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

  Widget _buildAvatar(String? userId, String initial, {bool isGroup = false}) {
    if (isGroup) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF), // Sangat bersih, Light Indigo
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(color: AppTheme.textLight, width: 2),
        ),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.users, color: Color(0xFF3730A3), size: 28),
      );
    }

    if (userId == null || userId.isEmpty || userId == 'null') {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textLight, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(color: Color(0xFF244F3D), fontWeight: FontWeight.w800, fontSize: 24),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {


        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.textLight, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(color: Color(0xFF244F3D), fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
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
  }  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;

    final chatList = Stack(
      children: [
        Container(
          width: isMobile ? double.infinity : 350,
          color: AppTheme.lightBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightBorder),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari pesan...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMutedLt, fontSize: 14),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.textMutedLt),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Chat List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : conversations.isEmpty
                        ? Center(
                            child: Text(
                              "Belum ada obrolan.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final conv = conversations[index];
                              final convName = _displayChatName(conv);
                              final isActive = activeConversationId == conv['id'];
                              final initial = convName.isNotEmpty ? convName[0].toUpperCase() : '?';
                              final isGroup = conv['type'] == 'group';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.primaryContainer.withAlpha(80) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isActive ? AppTheme.primary.withAlpha(50) : Colors.transparent),
                                  boxShadow: isActive ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => selectConversation(conv, convName),
                                    splashColor: AppTheme.primaryContainer.withAlpha(100),
                                    highlightColor: AppTheme.primaryContainer.withAlpha(50),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          _buildAvatar(null, initial, isGroup: isGroup),
                                          const SizedBox(width: 16),
                                          // Text Area
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        convName,
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 15,
                                                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                                          color: isActive ? AppTheme.primaryFixedVariant : AppTheme.textLight,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '12:45',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                                        color: isActive ? AppTheme.primary : AppTheme.textMutedLt,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  conv['lastMessage'] ?? 'Mulai obrolan...',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w400,
                                                    color: AppTheme.textMutedLt,
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
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: GestureDetector(
            onTap: _showNewChatMenu,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.textLight, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.textLight,
                    offset: Offset(4, 4),
                  )
                ],
              ),
              child: const Icon(
                LucideIcons.messageSquarePlus,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );

    final chatWindow = activeConversationId == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.textLight, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.textLight, offset: Offset(4, 4))
                    ],
                  ),
                  child: const Icon(LucideIcons.messageSquare, size: 40, color: AppTheme.textLight),
                ),
                const SizedBox(height: 24),
                Text(
                  "Pilih obrolan dari kiri\natau mulai chat baru",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // ── Bento Header ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                color: AppTheme.lightBg,
                child: Row(
                  children: [
                    if (isMobile)
                      GestureDetector(
                        onTap: () => setState(() => activeConversationId = null),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.textLight, width: 2),
                            boxShadow: const [BoxShadow(color: AppTheme.textLight, offset: Offset(2, 2))],
                          ),
                          child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textLight),
                        ),
                      ),
                    _buildAvatar(
                      null, 
                      activeChatName?.isNotEmpty == true ? activeChatName![0].toUpperCase() : '?',
                      isGroup: activeConversationType == 'group',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeChatName ?? 'Chat',
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textLight, height: 1.1),
                          ),
                          if (activeConversationType == 'group')
                            GestureDetector(
                              onTap: _showGroupInfo,
                              child: Text(
                                "Ketuk untuk info grup",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                            )
                          else 
                            Text(
                              "MEMBER", // Ganti dengan role asli jika tersedia
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                            )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {}, // Optional action
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.textLight, width: 2),
                          boxShadow: const [BoxShadow(color: AppTheme.textLight, offset: Offset(2, 2))],
                        ),
                        child: const Icon(LucideIcons.moreVertical, color: AppTheme.textLight),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Chat Area ──
              Expanded(
                child: Container(
                  color: AppTheme.lightBg,
                  child: messages.isEmpty
                      ? Center(
                          child: Text("Kirim pesan pertama!", 
                                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textMutedLt)))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[messages.length - 1 - index];
                            final isMe = msg['senderId'].toString() == myId.toString();
                            final isGroup = activeConversationType == 'group';

                            String timeStr = "";
                            if (msg['timestamp'] != null) {
                              try {
                                final dt = DateTime.parse(msg['timestamp']).toLocal();
                                timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                              } catch (e) {
                                debugPrint('timestamp error: $e');
                              }
                            }

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 320),
                                margin: const EdgeInsets.only(top: 24), // Margin at top since it's reversed
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isMe ? AppTheme.primaryContainer : Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: AppTheme.textLight, width: 2),
                                            boxShadow: const [
                                              BoxShadow(color: AppTheme.textLight, offset: Offset(4, 4))
                                            ],
                                          ),
                                          child: Text(
                                            msg['text'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: isMe ? AppTheme.primaryFixedVariant : AppTheme.textLight,
                                            ),
                                          ),
                                        ),
                                        if (isGroup && !isMe)
                                          Positioned(
                                            top: -12,
                                            left: -8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondary,
                                                border: Border.all(color: AppTheme.textLight, width: 2),
                                              ),
                                              child: Text(
                                                (msg['senderName'] ?? 'User').toUpperCase(),
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMutedLt),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(LucideIcons.checkCheck, size: 16, color: AppTheme.primary),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              // ── Input Area ──
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                color: AppTheme.lightBg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.textLight, width: 2),
                        ),
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textLight),
                          decoration: InputDecoration(
                            hintText: "Tulis pesan...",
                            hintStyle: GoogleFonts.inter(color: AppTheme.textMutedLt),
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(bottom: 2), // Align with textfield bottom
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.textLight, width: 2),
                          boxShadow: const [BoxShadow(color: AppTheme.textLight, offset: Offset(2, 2))],
                        ),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 24),
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
