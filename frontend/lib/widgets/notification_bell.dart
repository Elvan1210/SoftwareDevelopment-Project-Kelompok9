import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/api_config.dart';
import '../config/theme.dart';

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
          bool roleMatch = n['target_role'] == null || n['target_role'] == 'Semua' || n['target_role'] == widget.userData['role'];
          bool kelasMatch = n['target_kelas'] == null || n['target_kelas'] == widget.userData['kelas'];
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

  // Get icon based on notification title/content
  _NotifMeta _getNotifMeta(Map<String, dynamic> notif) {
    final judul = (notif['judul'] ?? '').toString().toLowerCase();
    
    if (judul.contains('diterima') || judul.contains('accepted') || judul.contains('✅')) {
      return const _NotifMeta(Icons.check_circle_rounded, Color(0xFF22C55E));
    }
    if (judul.contains('ditolak') || judul.contains('rejected') || judul.conta
    ins('❌')) {
      return const _NotifMeta(Icons.cancel_rounded, Color(0xFFEF4444));
    }
    if (judul.contains('bergabung') || judul.contains('permintaan') || judul.contains('join')) {
      return const _NotifMeta(Icons.person_add_alt_rounded, Color(0xFFF27F33));
    }
    if (judul.contains('tugas') || judul.contains('assignment')) {
      return const _NotifMeta(Icons.assignment_rounded, Color(0xFF3B82F6));
    }
    if (judul.contains('nilai') || judul.contains('grade')) {
      return const _NotifMeta(Icons.military_tech_rounded, Color(0xFF8B5CF6));
    }
    if (judul.contains('materi') || judul.contains('material')) {
      return const _NotifMeta(Icons.auto_stories_rounded, Color(0xFF0891B2));
    }
    if (judul.contains('pengumuman') || judul.contains('broadcast')) {
      return const _NotifMeta(Icons.campaign_rounded, Color(0xFFEC4899));
    }
    if (judul.contains('presensi') || judul.contains('hadir')) {
      return const _NotifMeta(Icons.how_to_reg_rounded, Color(0xFF22C55E));
    }
    return const _NotifMeta(Icons.notifications_rounded, AppTheme.primaryTeal);
  }

  // Group notifications by date
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
        key = 'Minggu Ini';
      } else {
        key = DateFormat('d MMMM yyyy').format(dt);
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
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final grouped = _groupByDate();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 30),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Handle Bar ──
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(40),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.getAdaptiveTeal(context).withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: AppTheme.getAdaptiveTeal(context),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifikasi',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (_unreadCount > 0)
                                Text(
                                  '$_unreadCount belum dibaca',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getAdaptiveTeal(context),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_unreadCount > 0)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _markAllAsRead();
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getAdaptiveTeal(context).withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.getAdaptiveTeal(context).withAlpha(40)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.done_all_rounded, size: 14, color: AppTheme.getAdaptiveTeal(context)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Baca Semua',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.getAdaptiveTeal(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_notifikasi.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _hideAllNotifs();
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.withAlpha(40)),
                                    ),
                                    child: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      color: theme.colorScheme.onSurface.withAlpha(20),
                      height: 16,
                    ),
                  ),

                  // ── Notification List ──
                  Expanded(
                    child: _notifikasi.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: grouped.keys.length,
                            itemBuilder: (context, groupIndex) {
                              final groupKey = grouped.keys.elementAt(groupIndex);
                              final items = grouped[groupKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date group header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                                    child: Text(
                                      groupKey,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface.withAlpha(100),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ...items.asMap().entries.map((entry) {
                                    final n = entry.value;
                                    return _buildNotifCard(n, theme, isDark, setModalState)
                                        .animate(delay: (entry.key * 30).ms)
                                        .fadeIn(duration: 300.ms)
                                        .slideX(begin: 0.03, curve: Curves.easeOutQuart);
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => _fetchNotifikasi());
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getAdaptiveTeal(context).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppTheme.getAdaptiveTeal(context).withAlpha(80),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi baru akan muncul di sini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotifCard(dynamic n, ThemeData theme, bool isDark, StateSetter setModalState) {
    List dibaca = n['dibaca_oleh'] ?? [];
    bool isRead = dibaca.contains(widget.userData['id']);
    final meta = _getNotifMeta(n);
    final timeAgo = _getTimeAgo(n['waktu']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(n);
              setModalState(() {});
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.transparent
                  : meta.color.withAlpha(isDark ? 15 : 8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? Colors.transparent
                    : meta.color.withAlpha(isDark ? 30 : 20),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isRead
                        ? theme.colorScheme.onSurface.withAlpha(isDark ? 20 : 10)
                        : meta.color.withAlpha(isDark ? 30 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meta.icon,
                    color: isRead
                        ? theme.colorScheme.onSurface.withAlpha(80)
                        : meta.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n['judul'] ?? 'Notifikasi',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 13,
                                color: isRead
                                    ? theme.colorScheme.onSurface.withAlpha(150)
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isRead
                                  ? theme.colorScheme.onSurface.withAlpha(60)
                                  : meta.color.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['pesan'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withAlpha(isRead ? 80 : 120),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Actions Column
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (!isRead)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _markAsRead(n);
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: meta.color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: meta.color.withAlpha(50)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, size: 12, color: meta.color),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tandai dibaca',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: meta.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _hideNotif(n);
                                  setModalState(() {});
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface.withAlpha(isDark ? 10 : 5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withAlpha(120),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed dependency on AppShell just in case, AppTheme is there
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
                _unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
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
  final Color color;
  const _NotifMeta(this.icon, this.color);
}
