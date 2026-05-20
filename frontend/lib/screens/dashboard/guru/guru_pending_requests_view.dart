import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
              content: Text('$nama berhasil diterima!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              content: Text(resBody['message'] ?? 'Gagal menerima siswa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              backgroundColor: AppTheme.rose,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan jaringan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _rejectStudent(String userId, String nama) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.rose.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.rose.withAlpha(40), width: 1.2),
                  ),
                  child: const Icon(LucideIcons.userX, color: AppTheme.rose, size: 20),
                ),
                const SizedBox(width: 14),
                Text('Tolak Permintaan?',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16.5, color: isDark ? Colors.white : AppTheme.textLight)),
              ]),
              const SizedBox(height: 18),
              Text('Apakah Anda yakin ingin menolak permintaan bergabung dari $nama?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  PremiumElevatedButton(
                    color: AppTheme.rose,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    radius: 12,
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Tolak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              content: Text('$nama telah ditolak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              backgroundColor: AppTheme.rose,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2538) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoPrimary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.indigoPrimary.withAlpha(40), width: 1.2),
                  ),
                  child: const Icon(LucideIcons.userCheck, color: AppTheme.indigoPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                Text('Terima Semua?',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16.5, color: isDark ? Colors.white : AppTheme.textLight)),
              ]),
              const SizedBox(height: 18),
              Text('Apakah Anda yakin ingin menerima semua ${_pendingRequests.length} permintaan bergabung sekaligus?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  PremiumElevatedButton(
                    color: AppTheme.indigoPrimary,
                    textColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    radius: 12,
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Terima Semua', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              content: Text(resBody['message'] ?? 'Semua siswa diterima!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              content: Text(value ? 'Auto-accept diaktifkan — siswa langsung diterima' : 'Auto-accept dinonaktifkan — siswa perlu persetujuan',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              backgroundColor: AppTheme.indigoPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.indigoPrimary));
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      color: AppTheme.indigoPrimary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAutoAcceptCard(isDark),
                const SizedBox(height: 20),

                _buildHeader(isDark),
                const SizedBox(height: 16),

                if (_pendingRequests.isEmpty)
                  _buildEmptyState()
                else
                  ..._pendingRequests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestCard(request, isDark)
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

  Widget _buildAutoAcceptCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.indigoPrimary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.indigoPrimary.withAlpha(40), width: 1.2),
              ),
              child: const Icon(
                LucideIcons.shieldAlert,
                color: AppTheme.indigoPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penerimaan Otomatis',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.textLight),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _autoAccept
                        ? 'Siswa langsung diterima saat bergabung'
                        : 'Siswa memerlukan persetujuan manual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _autoAccept,
              onChanged: _toggleAutoAccept,
              activeTrackColor: AppTheme.indigoPrimary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF27F33).withAlpha(20),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFF27F33).withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.hourglass, size: 12, color: Color(0xFFF27F33)),
              const SizedBox(width: 6),
              Text(
                '${_pendingRequests.length} Menunggu Persetujuan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF27F33),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (_pendingRequests.isNotEmpty)
          PremiumElevatedButton(
            onPressed: _isProcessing ? null : _acceptAll,
            color: AppTheme.indigoPrimary,
            textColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            radius: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.checkCheck, size: 14),
                const SizedBox(width: 6),
                Text('Terima Semua', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.indigoPrimary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.inbox,
                size: 52,
                color: AppTheme.indigoPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak Ada Permintaan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Permintaan bergabung dari siswa akan muncul di sini.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRequestCard(dynamic request, bool isDark) {
    final nama = request['nama'] ?? 'Siswa';
    final email = request['email'] ?? '';
    final requestedAt = request['requested_at'] ?? '';
    final userId = request['user_id'] ?? '';

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
    final namaTrimmed = nama.trim();
    if (namaTrimmed.isNotEmpty) {
      final parts = namaTrimmed.split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials = namaTrimmed.substring(0, namaTrimmed.length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.indigoPrimary, AppTheme.purpleSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.indigoPrimary.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
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
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                      const SizedBox(width: 5),
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isProcessing ? null : () => _rejectStudent(userId, nama),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.rose.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.rose.withAlpha(40), width: 1.2),
                    ),
                    child: const Icon(LucideIcons.userX, color: AppTheme.rose, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isProcessing ? null : () => _acceptStudent(userId, nama),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emerald.withAlpha(40), width: 1.2),
                    ),
                    child: const Icon(LucideIcons.userCheck, color: AppTheme.emerald, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
