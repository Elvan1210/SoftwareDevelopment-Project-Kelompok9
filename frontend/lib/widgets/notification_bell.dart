import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/api_config.dart';

// Neo-Brutalism Colors from Tailwind config
const Color _bgSurface = Color(0xFFF4FAFF);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _primary = Color(0xFF3D6754);
const Color _onPrimary = Color(0xFFFFFFFF);
const Color _primaryContainer = Color(0xFFB7E5CD);
const Color _onPrimaryContainer = Color(0xFF3E6855);
const Color _secondary = Color(0xFF336763);
const Color _onSecondary = Color(0xFFFFFFFF);
const Color _tertiary = Color(0xFF8D4D33);
const Color _onTertiary = Color(0xFFFFFFFF);
const Color _tertiaryContainer = Color(0xFFFFD1C0);
const Color _onTertiaryContainer = Color(0xFF8E4F34);
const Color _tertiaryFixedDim = Color(0xFFFFB598);
const Color _surfaceVariant = Color(0xFFC1E8FF);
const Color _surfaceContainerHigh = Color(0xFFCEEDFF);
const Color _outlineVariant = Color(0xFFC1C8C2);

class NotificationBell extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final Color iconColor;

  const NotificationBell({
    super.key,
    required this.userData,
    required this.token,
    required this.iconColor,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with SingleTickerProviderStateMixin {
  List<dynamic> _notifikasi = [];
  int _unreadCount = 0;
  late AnimationController _bellController;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchNotifikasi();
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifikasi'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final decAllData = jsonDecode(response.body);
        List allData = decAllData is List ? decAllData : [];

        List myNotifs = allData.where((n) {
          if (n['target_user_id'] != null) {
            return n['target_user_id'] == widget.userData['id'];
          }
          bool roleMatch = n['target_role'] == null ||
              n['target_role'] == 'Semua' ||
              n['target_role'] == widget.userData['role'];
          bool kelasMatch = n['target_kelas'] == null ||
              n['target_kelas'] == widget.userData['kelas'];
          return roleMatch && kelasMatch;
        }).toList();

        myNotifs.sort((a, b) {
          DateTime timeA = DateTime.tryParse(a['waktu'] ?? '') ?? DateTime.now();
          DateTime timeB = DateTime.tryParse(b['waktu'] ?? '') ?? DateTime.now();
          return timeB.compareTo(timeA);
        });

        int unread = myNotifs.where((n) {
          List dibaca = n['dibaca_oleh'] ?? [];
          return !dibaca.contains(widget.userData['id']);
        }).length;

        if (mounted) {
          setState(() {
            _notifikasi = myNotifs;
            _unreadCount = unread;
          });
          if (unread > 0) {
            _bellController.forward(from: 0);
          }
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

    setState(() {
      notif['dibaca_oleh'] = dibaca;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    });

    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifikasi/${notif['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
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

  Future<void> _hideNotif(Map<String, dynamic> notif) async {
    setState(() {
      _notifikasi.removeWhere((n) => n['id'] == notif['id']);
    });
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifikasi/${notif['id']}/hide'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
    } catch (e) {
      debugPrint('Error hide notif: $e');
    }
  }

  Future<void> _hideAllNotifs() async {
    setState(() {
      _notifikasi.clear();
      _unreadCount = 0;
    });
    try {
      await http.put(
        Uri.parse('$baseUrl/api/notifikasi/user/hide-all'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
    } catch (e) {
      debugPrint('Error hide all notifs: $e');
    }
  }

  _NotifMeta _getNotifMeta(Map<String, dynamic> notif) {
    final judul = (notif['judul'] ?? '').toString().toLowerCase();

    if (judul.contains('pengumuman') || judul.contains('jadwal')) {
      return _NotifMeta(Icons.campaign, _secondary, _onSecondary);
    }
    if (judul.contains('nilai') || judul.contains('grade')) {
      return _NotifMeta(Icons.school, _tertiary, _onTertiary);
    }
    if (judul.contains('tugas') || judul.contains('assignment')) {
      return _NotifMeta(Icons.assignment, _primary, _onPrimary);
    }
    if (judul.contains('diskusi') || judul.contains('pesan')) {
      return _NotifMeta(Icons.chat, _onSurfaceVariant, _bgSurface);
    }
    return _NotifMeta(Icons.archive, _bgSurface, _onSurfaceVariant);
  }

  Map<String, List<dynamic>> _groupByDate() {
    final Map<String, List<dynamic>> grouped = {};
    for (var n in _notifikasi) {
      final dt = DateTime.tryParse(n['waktu'] ?? '') ?? DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(dt);

      String key;
      if (diff.inDays == 0 && dt.day == now.day) {
        key = 'Hari Ini';
      } else if (diff.inDays <= 1 && dt.day == now.day - 1) {
        key = 'Kemarin';
      } else if (diff.inDays < 7) {
        key = 'Minggu lalu';
      } else {
        key = 'Bulan lalu';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(n);
    }
    return grouped;
  }

  String _getTimeAgo(String? waktu) {
    if (waktu == null) return '';
    try {
      final dt = DateTime.parse(waktu);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${DateFormat('HH:mm').format(dt)} WIB';
      if (diff.inDays < 7) return 'Kemarin';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  void _showNotificationPanel() {
    showGeneralDialog(
      context: context,
      barrierColor: _onSurface.withAlpha(100),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final grouped = _groupByDate();

            return SafeArea(
              child: Align(
                alignment: MediaQuery.of(context).size.width < 600 ? Alignment.bottomCenter : Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 512, maxHeight: 800),
                      decoration: BoxDecoration(
                        color: _bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _onSurface, width: 2),
                        boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: _onSurface, width: 2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Notifikasi',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: _onSurface,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: _onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Scrollable Content
                          Flexible(
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              shrinkWrap: true,
                              children: [
                                // Actions
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildNeoActionBtn(
                                        icon: Icons.done_all,
                                        label: 'Tandai Semua Dibaca',
                                        bgColor: _primaryContainer,
                                        textColor: _onPrimaryContainer,
                                        onTap: () {
                                          _markAllAsRead();
                                          setModalState(() {});
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _buildNeoActionBtn(
                                        icon: Icons.delete_sweep,
                                        label: 'Hapus Semua',
                                        bgColor: _tertiaryContainer,
                                        textColor: _onTertiaryContainer,
                                        onTap: () {
                                          _hideAllNotifs();
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                if (_notifikasi.isEmpty) _buildEmptyState(),
                                
                                ...grouped.entries.map((entry) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 24),
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      ...entry.value.map((n) => _buildNotifCard(n, setModalState)),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _fetchNotifikasi());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.notifications_off, size: 48, color: _onSurfaceVariant.withAlpha(150)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNeoActionBtn({required IconData icon, required String label, required Color bgColor, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _onSurface, width: 2),
          boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(dynamic n, StateSetter setModalState) {
    List dibaca = n['dibaca_oleh'] ?? [];
    bool isRead = dibaca.contains(widget.userData['id']);
    final meta = _getNotifMeta(n);
    final timeAgo = _getTimeAgo(n['waktu']);
    final bool isPengumuman = n['judul'].toString().toLowerCase().contains('pengumuman');
    final bool isPesan = n['judul'].toString().toLowerCase().contains('diskusi') || n['judul'].toString().toLowerCase().contains('pesan');

    Color bgColor = _bgSurface;
    if (!isRead) {
      if (isPengumuman) bgColor = _surfaceContainerHigh;
      if (isPesan) bgColor = _surfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Opacity(
        opacity: isRead ? 0.75 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _onSurface, width: 2),
                boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(4, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n['judul'] ?? 'Notifikasi',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            color: _onSurface,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n['pesan'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: isRead ? null : () {
                          _markAsRead(n);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isRead ? _outlineVariant : _surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _onSurface, width: 2),
                            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                          ),
                          child: Icon(isRead ? Icons.check_circle : Icons.check, size: 20, color: isRead ? _onSurfaceVariant : _onSurface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          _hideNotif(n);
                          setModalState(() {});
                        },
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _tertiaryFixedDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _onSurface, width: 2),
                            boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(2, 2))],
                          ),
                          child: const Icon(Icons.delete, size: 20, color: _onSurface),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Positioned(
              top: 0,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.bgColor,
                  border: Border.all(color: _onSurface, width: 2),
                ),
                child: Icon(meta.icon, size: 16, color: meta.iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _fetchNotifikasi();
              _showNotificationPanel();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _unreadCount > 0 ? Icons.notifications_active : Icons.notifications,
                color: widget.iconColor,
                size: 24,
              ),
            ),
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF27F33), Color(0xFFE65C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF27F33).withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().scale(curve: Curves.easeOutBack),
          ),
      ],
    );
  }
}

class _NotifMeta {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  _NotifMeta(this.icon, this.bgColor, this.iconColor);
}
