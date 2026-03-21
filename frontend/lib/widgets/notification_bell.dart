import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config/api_config.dart';

class NotificationBell extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final Color iconColor;

  const NotificationBell({super.key, required this.userData, required this.token, this.iconColor = Colors.white});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  List<dynamic> _notifikasi = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifikasi();
  }

  Future<void> _fetchNotifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifikasi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        List allData = jsonDecode(response.body);
        
        // Filter notifikasi yang ditujukan untuk user ini
        List myNotifs = allData.where((n) {
          bool matchUser = n['target_user_id'] == widget.userData['id'];
          bool matchKelas = n['target_kelas'] == widget.userData['kelas'];
          bool matchRole = n['target_role'] == widget.userData['role'] || n['target_role'] == 'Semua';
          
          return matchUser || matchKelas || matchRole;
        }).toList();

        // Sort dari yang terbaru
        myNotifs.sort((a, b) {
          DateTime timeA = DateTime.tryParse(a['waktu'] ?? '') ?? DateTime.now();
          DateTime timeB = DateTime.tryParse(b['waktu'] ?? '') ?? DateTime.now();
          return timeB.compareTo(timeA);
        });

        // Hitung unread (yang dibaca_oleh tidak mengandung id user)
        int unread = myNotifs.where((n) {
          List dibaca = n['dibaca_oleh'] ?? [];
          return !dibaca.contains(widget.userData['id']);
        }).length;

        if (mounted) {
          setState(() {
            _notifikasi = myNotifs;
            _unreadCount = unread;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch notifikasi: $e');
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notif) async {
    List dibaca = List.from(notif['dibaca_oleh'] ?? []);
    if (dibaca.contains(widget.userData['id'])) return;

    dibaca.add(widget.userData['id']);
    
    // Update local state first for instant UI response
    setState(() {
      notif['dibaca_oleh'] = dibaca;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    });

    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifikasi/${notif['id']}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({'dibaca_oleh': dibaca}),
      );
    } catch (e) {
      debugPrint('Error mark as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    for (var n in _notifikasi) {
      List dibaca = List.from(n['dibaca_oleh'] ?? []);
      if (!dibaca.contains(widget.userData['id'])) {
        _markAsRead(n);
      }
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (_unreadCount > 0)
                          TextButton(
                            onPressed: () {
                              _markAllAsRead();
                              setModalState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Tandai semua dibaca'),
                          )
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _notifikasi.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _notifikasi.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final n = _notifikasi[index];
                              List dibaca = n['dibaca_oleh'] ?? [];
                              bool isRead = dibaca.contains(widget.userData['id']);
                              
                              DateTime t = DateTime.tryParse(n['waktu'] ?? '') ?? DateTime.now();
                              String formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(t);

                              return Container(
                                color: isRead ? Colors.transparent : Colors.blue.shade50.withOpacity(0.5),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                                    child: Icon(
                                      Icons.notifications,
                                      color: isRead ? Colors.grey.shade500 : Colors.blue.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    n['judul'] ?? 'Notifikasi',
                                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(n['pesan'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text(formattedTime, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                    ],
                                  ),
                                  onTap: () {
                                    if (!isRead) {
                                      _markAsRead(n);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }
        );
      },
    ).then((_) => _fetchNotifikasi()); // Refresh count after closing modal
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: widget.iconColor, size: 28),
          onPressed: () {
            _fetchNotifikasi(); // Refresh data sebelum buka
            _showNotificationPanel();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
