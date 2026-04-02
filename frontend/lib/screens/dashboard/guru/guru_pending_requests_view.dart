import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/app_shell.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$nama berhasil diterima! ✅'),
              backgroundColor: AppTheme.getAdaptiveTeal(context),
            ),
          );
        }
        _fetchPendingRequests();
        widget.onRequestsChanged?.call();
      } else {
        final resBody = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resBody['message'] ?? 'Gagal menerima siswa'),
              backgroundColor: const Color(0xFFF27F33),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan'),
            backgroundColor: Color(0xFFF27F33),
          ),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _rejectStudent(String userId, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Permintaan?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Yakin ingin menolak permintaan bergabung dari $nama?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$nama telah ditolak'),
              backgroundColor: Colors.red.shade600,
            ),
          );
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terima Semua?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Terima semua ${_pendingRequests.length} permintaan bergabung sekaligus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terima Semua', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resBody['message'] ?? 'Semua siswa diterima! ✅'),
              backgroundColor: AppTheme.getAdaptiveTeal(context),
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'Auto-accept diaktifkan — siswa langsung diterima' : 'Auto-accept dinonaktifkan — siswa perlu persetujuan'),
              backgroundColor: AppTheme.getAdaptiveTeal(context),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling auto-accept: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Auto-accept toggle card
                _buildAutoAcceptCard(theme),
                const SizedBox(height: 20),

                // Header with Accept All button
                _buildHeader(theme),
                const SizedBox(height: 16),

                // Pending requests list
                if (_pendingRequests.isEmpty)
                  _buildEmptyState()
                else
                  ..._pendingRequests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestCard(request, theme)
                          .animate(delay: (index * 60).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOutQuart),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoAcceptCard(ThemeData theme) {
    return PremiumCard(
      accentColor: AppTheme.getAdaptiveTeal(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.getAdaptiveTeal(context).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: AppTheme.getAdaptiveTeal(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Accept',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _autoAccept
                      ? 'Siswa langsung diterima saat bergabung'
                      : 'Siswa memerlukan persetujuan Anda',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _autoAccept,
            onChanged: _toggleAutoAccept,
            activeTrackColor: AppTheme.getAdaptiveTeal(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF27F33).withAlpha(20),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFF27F33).withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFF27F33)),
              const SizedBox(width: 6),
              Text(
                '${_pendingRequests.length} Menunggu',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF27F33),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (_pendingRequests.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _acceptAll,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Terima Semua', style: TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.getAdaptiveTeal(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
      ],
    ).animate(delay: 100.ms).fadeIn().slideY(begin: -0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 72,
              color: AppTheme.getAdaptiveTeal(context).withAlpha(80),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada permintaan baru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permintaan bergabung dari siswa akan muncul di sini.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRequestCard(dynamic request, ThemeData theme) {
    final nama = request['nama'] ?? 'Siswa';
    final email = request['email'] ?? '';
    final requestedAt = request['requested_at'] ?? '';
    final userId = request['user_id'] ?? '';

    // Parse time
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

    // Get initials
    String initials = '??';
    final namaTrimmed = nama.trim();
    if (namaTrimmed.isNotEmpty) {
      final parts = namaTrimmed.split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials = namaTrimmed.substring(0, namaTrimmed.length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return PremiumCard(
      accentColor: const Color(0xFFF27F33),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF27F33), Color(0xFFE65C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF27F33).withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reject button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessing ? null : () => _rejectStudent(userId, nama),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(40)),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Accept button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessing ? null : () => _acceptStudent(userId, nama),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.getAdaptiveTeal(context).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.getAdaptiveTeal(context).withAlpha(40)),
                    ),
                    child: Icon(Icons.check_rounded, color: AppTheme.getAdaptiveTeal(context), size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
