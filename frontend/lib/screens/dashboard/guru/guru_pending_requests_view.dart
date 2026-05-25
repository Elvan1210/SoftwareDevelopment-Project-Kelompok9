import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuruPendingRequestsView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  final VoidCallback? onRequestsChanged;

  const GuruPendingRequestsView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
    this.onRequestsChanged,
  });

  @override
  State<GuruPendingRequestsView> createState() => _GuruPendingRequestsViewState();
}

class _GuruPendingRequestsViewState extends State<GuruPendingRequestsView> {
  static const _ink      = Color(0xFF001E2B);
  static const _primary  = Color(0xFF3D6754);
  static const _secondary = Color(0xFF336763);
  static const _outline  = Color(0xFF717974);
  static const _surface  = Color(0xFFF4FAFF);
  static const _tertiary = Color(0xFF8D4D33);
  static const _error    = Color(0xFFBA1A1A);

  static const List<Color> _avatarColors = [
    Color(0xFFB7EDE7), // secondary-container
    Color(0xFFB7E5CD), // primary-container
    Color(0xFFC1E8FF), // surface-variant
    Color(0xFFFFDBCE), // tertiary-fixed
  ];

  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;
  bool _autoAccept = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas/$kelasId/pending'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pendingRequests = data['pending_requests'] ?? [];
        _autoAccept = data['auto_accept'] ?? false;
      }
    } catch (e) {
      debugPrint('Error fetching pending requests: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acceptStudent(String userId, String nama) async {
    setState(() => _isProcessing = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.post(
        Uri.parse('$baseUrl/api/kelas/$kelasId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$nama berhasil diterima!',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
          ));
        }
        _fetchPendingRequests();
        widget.onRequestsChanged?.call();
      } else {
        final resBody = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resBody['message'] ?? 'Gagal menerima siswa',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: _error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Terjadi kesalahan jaringan',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _rejectStudent(String userId, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Tolak Permintaan?',
        content: 'Apakah Anda yakin ingin menolak permintaan bergabung dari $nama?',
        confirmLabel: 'TOLAK',
        confirmColor: _error,
        icon: Icons.person_remove_rounded,
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.post(
        Uri.parse('$baseUrl/api/kelas/$kelasId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$nama telah ditolak',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: _error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        _fetchPendingRequests();
        widget.onRequestsChanged?.call();
      }
    } catch (e) {
      debugPrint('Error rejecting: $e');
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _acceptAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Terima Semua?',
        content:
            'Apakah Anda yakin ingin menerima semua ${_pendingRequests.length} permintaan bergabung sekaligus?',
        confirmLabel: 'TERIMA SEMUA',
        confirmColor: _primary,
        icon: Icons.people_rounded,
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.post(
        Uri.parse('$baseUrl/api/kelas/$kelasId/accept-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resBody['message'] ?? 'Semua siswa diterima!',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
          ));
        }
        _fetchPendingRequests();
        widget.onRequestsChanged?.call();
      }
    } catch (e) {
      debugPrint('Error accept all: $e');
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _toggleAutoAccept(bool value) async {
    try {
      final kelasId = widget.teamData['id'];
      final response = await http.put(
        Uri.parse('$baseUrl/api/kelas/$kelasId/auto-accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'auto_accept': value}),
      );
      if (response.statusCode == 200) {
        setState(() => _autoAccept = value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              value
                  ? 'Auto-accept diaktifkan — siswa langsung diterima'
                  : 'Auto-accept dinonaktifkan — siswa perlu persetujuan',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error toggling auto-accept: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      color: _primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPageHeader(),
                const SizedBox(height: 20),
                _buildAutoAcceptCard(),
                const SizedBox(height: 20),
                if (_pendingRequests.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildCardGrid(),
                  const SizedBox(height: 20),
                  _buildAcceptAllButton(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permintaan Gabung',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Kelola permintaan siswa untuk bergabung ke kelas Anda',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _outline,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildAutoAcceptCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border.fromBorderSide(BorderSide(color: _ink, width: 2)),
        boxShadow: [BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Auto Terima Siswa',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          Switch.adaptive(
            value: _autoAccept,
            onChanged: _toggleAutoAccept,
            activeTrackColor: _primary,
            inactiveThumbColor: _ink,
            inactiveTrackColor: Colors.white,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildCardGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 2 : 1;
        if (crossCount == 1) {
          return Column(
            children: _pendingRequests.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildRequestCard(e.value, e.key)
                    .animate(delay: (e.key * 60).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOutQuart),
              );
            }).toList(),
          );
        }
        // Two-column grid
        final rows = <Widget>[];
        for (int i = 0; i < _pendingRequests.length; i += 2) {
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildRequestCard(_pendingRequests[i], i)
                        .animate(delay: (i * 60).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.05, curve: Curves.easeOutQuart),
                  ),
                  if (i + 1 < _pendingRequests.length) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRequestCard(_pendingRequests[i + 1], i + 1)
                          .animate(delay: ((i + 1) * 60).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, curve: Curves.easeOutQuart),
                    ),
                  ] else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ));
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildAcceptAllButton() {
    return _NeoButton(
      label: 'TERIMA SEMUA (${_pendingRequests.length})',
      icon: Icons.check_circle_outline_rounded,
      color: _primary,
      textColor: Colors.white,
      shadowOffset: const Offset(4, 4),
      onTap: _isProcessing ? null : _acceptAll,
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFB7E5CD),
                border: Border.fromBorderSide(BorderSide(color: _ink, width: 2)),
                boxShadow: [BoxShadow(color: _ink, offset: Offset(4, 4))],
              ),
              child: const Icon(Icons.school_rounded, size: 52, color: _primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tidak Ada Permintaan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Permintaan bergabung dari siswa akan muncul di sini.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRequestCard(dynamic request, int index) {
    final nama       = request['nama'] ?? 'Siswa';
    final email      = request['email'] ?? '';
    final requestedAt = request['requested_at'] ?? '';
    final userId     = request['user_id'] ?? '';
    final namaKelas  = widget.teamData['nama_kelas'] ?? '';
    final isNewest   = index == 0;
    final avatarBg   = _avatarColors[index % _avatarColors.length];

    String timeAgo = '';
    try {
      final dt = DateTime.parse(requestedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays} hari lalu';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours} jam lalu';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes} menit lalu';
      } else {
        timeAgo = 'Baru saja';
      }
    } catch (_) {
      timeAgo = '-';
    }

    String initials = '??';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      initials = (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (nama.trim().isNotEmpty) {
      initials = nama.trim().substring(0, nama.trim().length >= 2 ? 2 : 1).toUpperCase();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, isNewest ? 28 : 20, 20, 20),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border.fromBorderSide(BorderSide(color: _ink, width: 2)),
            boxShadow: [BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if (namaKelas.isNotEmpty)
                          Text(
                            namaKelas,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _secondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: _outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _NeoButton(
                      label: 'TERIMA',
                      icon: Icons.check_rounded,
                      color: _primary,
                      textColor: Colors.white,
                      onTap: _isProcessing ? null : () => _acceptStudent(userId, nama),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NeoButton(
                      label: 'TOLAK',
                      icon: Icons.close_rounded,
                      color: Colors.white,
                      textColor: _ink,
                      onTap: _isProcessing ? null : () => _rejectStudent(userId, nama),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isNewest)
          Positioned(
            top: -14,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: _tertiary,
                border: Border.fromBorderSide(BorderSide(color: _ink, width: 1.5)),
                boxShadow: [BoxShadow(color: _ink, offset: Offset(2, 2))],
              ),
              child: const Text(
                'TERBARU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;

  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
  });

  static const _ink = Color(0xFF001E2B);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: confirmColor.withAlpha(25),
            border: Border.all(color: _ink, width: 1.5),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
          ),
          child: Icon(icon, color: confirmColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : _ink,
            ),
          ),
        ),
      ]),
      content: Text(
        content,
        style: TextStyle(
          fontFamily: 'Inter',
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFB0B8B4) : const Color(0xFF414944),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Batal',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? const Color(0xFFB0B8B4) : const Color(0xFF414944),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _NeoButton(
          label: confirmLabel,
          color: confirmColor,
          textColor: Colors.white,
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

// ── Neo Button ────────────────────────────────────────────────────────────────
class _NeoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Offset shadowOffset;
  final VoidCallback? onTap;

  const _NeoButton({
    required this.label,
    this.icon,
    required this.color,
    required this.textColor,
    this.shadowOffset = const Offset(2, 2),
    this.onTap,
  });

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
  bool _pressed = false;
  static const _ink = Color(0xFF001E2B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(
                widget.shadowOffset.dx, widget.shadowOffset.dy, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.onTap == null ? Colors.grey.shade300 : widget.color,
          border: Border.all(color: _ink, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                      color: _ink,
                      offset: widget.shadowOffset,
                      blurRadius: 0)
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: widget.onTap == null ? Colors.grey : widget.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
