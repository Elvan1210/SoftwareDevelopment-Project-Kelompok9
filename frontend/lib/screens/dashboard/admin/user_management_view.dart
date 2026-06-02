import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';

import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

// ─── Neo-Brutalist / Retro-Pop Academic Design Token ─────────────────────────
const Color _kPrimary     = Color(0xFF2E5343); // Dark forest green (primary)
const Color _kBgPage      = Color(0xFFF0F4F0); // Light ice-blue off-white
const Color _kBgPageDark  = Color(0xFF0D1A14); // Dark mode page bg

// Icon box backgrounds (inside stat cards)
const Color _kIconBgUsers = Color(0xFFB7D8CE); // Pastel teal
const Color _kIconBgGuru  = Color(0xFFB5C4E0); // Pastel indigo
const Color _kIconBgSiswa = Color(0xFFEEC9A3); // Pastel peach

// Icon colours
const Color _kIconUsers = Color(0xFF2E7D6A);
const Color _kIconGuru  = Color(0xFF3D5A80);
const Color _kIconSiswa = Color(0xFF8B5E3C);

// Avatar backgrounds per role
const Color _kAvGuru  = Color(0xFF6B9BAA); // Slate blue-teal
const Color _kAvSiswa = Color(0xFF5F9E84); // Forest green
const Color _kAvAdmin = Color(0xFFB87070); // Muted red

// Badge backgrounds
const Color _kBadgeRoleBg  = Color(0xFF3D7A5E);
const Color _kBadgeKelasBg = Color(0xFFD4894A);

// Neo border + shadow helpers
const _kBorder2 = BorderSide(color: Colors.black, width: 2.0);
const _kBorder15 = BorderSide(color: Colors.black, width: 1.5);
const _kHardShadow = [
  BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
];
const _kSmallShadow = [
  BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
];

// ─────────────────────────────────────────────────────────────────────────────

class UserManagementView extends StatefulWidget {
  final String token;
  const UserManagementView({super.key, required this.token});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'Semua';
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() => _users = d is List ? d : []);
      }
    } catch (e) {
      debugPrint('fetchUsers error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus akun ini secara permanen?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/users/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchUsers();
      } catch (e) {
        debugPrint('deleteUser error: $e');
      }
    }
  }

  // ── Add / Edit User Dialog (Neo-Brutalist bottom sheet) ───────────────────
  void _showUserForm([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    final namaCtrl  = TextEditingController(text: isEditing ? user['nama']  ?? '' : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] ?? '' : '');
    final passCtrl  = TextEditingController();

    String role = isEditing ? (user['role'] ?? 'Siswa') : 'Siswa';
    bool obscurePass = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final bgSheet = isDark ? const Color(0xFF1A2E24) : _kBgPage;
          final bgField = isDark ? const Color(0xFF243D2D) : Colors.white;
          final textCol = isDark ? Colors.white : Colors.black;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              color: bgSheet,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Title bar ──
                    Container(
                      color: bgSheet,
                      padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'EDIT USER' : 'TAMBAH USER',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textCol,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          // X close button — sharp square
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: bgField,
                                border: const Border.fromBorderSide(_kBorder2),
                              ),
                              child: Icon(Icons.close,
                                  size: 20, color: textCol),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider line
                    Container(height: 2, color: Colors.black),

                    // ── Form body ──
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NAMA LENGKAP
                          _NeoLabel('NAMA LENGKAP', textCol),
                          const SizedBox(height: 6),
                          _NeoTextField(
                            controller: namaCtrl,
                            hint: 'Contoh: Budi Santoso',
                            bg: bgField,
                            textColor: textCol,
                          ),
                          const SizedBox(height: 16),

                          // EMAIL
                          _NeoLabel('EMAIL', textCol),
                          const SizedBox(height: 6),
                          _NeoTextField(
                            controller: emailCtrl,
                            hint: 'user@mypskd.edu',
                            bg: bgField,
                            textColor: textCol,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // ROLE dropdown
                          _NeoLabel('ROLE', textCol),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: bgField,
                              border:
                                  const Border.fromBorderSide(_kBorder2),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: role,
                                isExpanded: true,
                                dropdownColor: bgField,
                                icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textCol),
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: textCol,
                                    fontWeight: FontWeight.w600),
                                items: ['Siswa', 'Guru', 'Admin']
                                    .map((r) => DropdownMenuItem(
                                        value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (v) =>
                                    setS(() => role = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PASSWORD
                          _NeoLabel('PASSWORD', textCol),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: bgField,
                              border:
                                  const Border.fromBorderSide(_kBorder2),
                            ),
                            child: TextField(
                              controller: passCtrl,
                              obscureText: obscurePass,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: textCol,
                                  fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: isEditing
                                    ? '(kosongkan jika tidak diubah)'
                                    : '••••••••',
                                hintStyle: GoogleFonts.inter(
                                    color: Colors.grey.shade400),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                suffixIcon: GestureDetector(
                                  onTap: () => setS(
                                      () => obscurePass = !obscurePass),
                                  child: Icon(
                                    obscurePass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 28),

                          // SIMPAN USER button
                          GestureDetector(
                            onTap: () async {
                              final body = {
                                'nama': namaCtrl.text,
                                'email': emailCtrl.text,
                                'role': role,
                              };
                              if (!isEditing ||
                                  passCtrl.text.isNotEmpty) {
                                body['password'] = passCtrl.text;
                              }
                              final url = isEditing
                                  ? Uri.parse(
                                      '$baseUrl/api/users/${user['id']}')
                                  : Uri.parse('$baseUrl/api/users');
                              final resp = await (isEditing
                                  ? http.put(url,
                                      headers: {
                                        'Content-Type':
                                            'application/json',
                                        'Authorization':
                                            'Bearer ${widget.token}',
                                      },
                                      body: jsonEncode(body))
                                  : http.post(url,
                                      headers: {
                                        'Content-Type':
                                            'application/json',
                                        'Authorization':
                                            'Bearer ${widget.token}',
                                      },
                                      body: jsonEncode(body)));
                              if (resp.statusCode == 200 ||
                                  resp.statusCode == 201) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchUsers();
                              } else {
                                final d = jsonDecode(resp.body);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx)
                                      .showSnackBar(SnackBar(
                                    content: Text(d['message'] ??
                                        'Gagal menyimpan'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              color: _kPrimary,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons
                                          .person_add_alt_1_rounded,
                                      color: Colors.white,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'SIMPAN USER',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Caption
                          Center(
                            child: Text(
                              'PASTIKAN DATA YANG DIINPUT SUDAH SESUAI\nDENGAN DATABASE AKADEMIK.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.3,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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

  // ── Filtered & paginated lists ────────────────────────────────────────────
  List<dynamic> get _filteredUsers {
    return _users.where((u) {
      final rm = _selectedRole == 'Semua' ||
          (u['role'] ?? '') == _selectedRole;
      if (!rm) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q) ||
          (u['role'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  List<dynamic> get _paginatedUsers {
    final list = _filteredUsers;
    final s = (_currentPage - 1) * _pageSize;
    final e = (s + _pageSize).clamp(0, list.length);
    if (s >= list.length) return [];
    return list.sublist(s, e);
  }

  int get _totalPages =>
      (_filteredUsers.length / _pageSize).ceil().clamp(1, 9999);

  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton(context);

    final tu = _users.length;
    final tg = _users.where((u) => u['role'] == 'Guru').length;
    final ts = _users.where((u) => u['role'] == 'Siswa').length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (ctx, c) => Scaffold(
        backgroundColor: isDark ? _kBgPageDark : _kBgPage,
        body: c.maxWidth >= 900
            ? _buildDesktop(tu, tg, ts, isDark)
            : _buildMobile(tu, tg, ts, isDark),
      ),
    );
  }

  // ══ DESKTOP layout ═══════════════════════════════════════════════════════
  Widget _buildDesktop(int tu, int tg, int ts, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column — stat cards
        SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
            child: Column(
              children: [
                _NeoStatCard(
                  label: 'TOTAL USERS',
                  value: '$tu',
                  icon: Icons.people_alt_rounded,
                  iconBg: _kIconBgUsers,
                  iconColor: _kIconUsers,
                  isDark: isDark,
                ).animate().fadeIn().slideX(begin: -0.08),
                const SizedBox(height: 12),
                _NeoStatCard(
                  label: 'TOTAL GURU',
                  value: '$tg',
                  icon: Icons.school_rounded,
                  iconBg: _kIconBgGuru,
                  iconColor: _kIconGuru,
                  isDark: isDark,
                ).animate(delay: 60.ms).fadeIn().slideX(begin: -0.08),
                const SizedBox(height: 12),
                _NeoStatCard(
                  label: 'TOTAL SISWA',
                  value: '$ts',
                  icon: Icons.person_rounded,
                  iconBg: _kIconBgSiswa,
                  iconColor: _kIconSiswa,
                  isDark: isDark,
                ).animate(delay: 120.ms).fadeIn().slideX(begin: -0.08),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Right column — controls + list + pagination
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
            child: Column(
              children: [
                _buildControls(isDark: isDark, isDesktop: true),
                const SizedBox(height: 12),
                Expanded(child: _buildDesktopList(isDark)),
                _buildPagination(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══ MOBILE layout ════════════════════════════════════════════════════════
  Widget _buildMobile(int tu, int tg, int ts, bool isDark) {
    final users = _paginatedUsers;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Stat cards (stacked)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _NeoStatCard(
                      label: 'TOTAL USERS',
                      value: '$tu',
                      icon: Icons.people_alt_rounded,
                      iconBg: _kIconBgUsers,
                      iconColor: _kIconUsers,
                      isDark: isDark,
                    ).animate().fadeIn().slideY(begin: -0.08),
                    const SizedBox(height: 10),
                    _NeoStatCard(
                      label: 'TOTAL GURU',
                      value: '$tg',
                      icon: Icons.school_rounded,
                      iconBg: _kIconBgGuru,
                      iconColor: _kIconGuru,
                      isDark: isDark,
                    ).animate(delay: 55.ms).fadeIn().slideY(begin: -0.08),
                    const SizedBox(height: 10),
                    _NeoStatCard(
                      label: 'TOTAL SISWA',
                      value: '$ts',
                      icon: Icons.person_rounded,
                      iconBg: _kIconBgSiswa,
                      iconColor: _kIconSiswa,
                      isDark: isDark,
                    ).animate(delay: 110.ms).fadeIn().slideY(begin: -0.08),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search + Add User + Filter (in white bordered box)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2E24) : Colors.white,
                    border: const Border.fromBorderSide(_kBorder2),
                    boxShadow: _kHardShadow,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: _buildControls(isDark: isDark, isDesktop: false),
                ),
              ),
              const SizedBox(height: 14),

              // User cards
              if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 40),
                  child: Center(
                    child: Text(
                      'Tidak ada user ditemukan.',
                      style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                ...users.asMap().entries.map((e) {
                  final idx = e.key;
                  final u = e.value;
                  return Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _NeoUserCard(
                      user: u,
                      isDark: isDark,
                      onEdit: () => _showUserForm(u),
                      onDelete: () =>
                          _deleteUser(u['id'].toString()),
                    )
                        .animate(delay: (idx * 40).ms)
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.05),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildPagination(isDark),
      ],
    );
  }

  // ── Search / Add User / Filter bar ───────────────────────────────────────
  Widget _buildControls({required bool isDark, required bool isDesktop}) {
    final bg = isDark ? const Color(0xFF243D2D) : Colors.white;
    final textMuted = isDark ? Colors.white54 : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: bg,
            border: const Border.fromBorderSide(_kBorder2),
            boxShadow: isDesktop ? _kHardShadow : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 20, color: textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _currentPage = 1;
                  }),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or NIS/I',
                    hintStyle: GoogleFonts.inter(
                        color: textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Add User button — solid dark-green, no radius
        GestureDetector(
          onTap: () => _showUserForm(),
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: const BoxDecoration(
              color: _kPrimary,
              boxShadow: _kSmallShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Add User',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips — sharp corners, active = _kPrimary
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ['Semua', 'Guru', 'Siswa', 'Admin'].map((r) {
            final sel = _selectedRole == r;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedRole = r;
                _currentPage = 1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel
                      ? _kPrimary
                      : (isDark
                          ? const Color(0xFF243D2D)
                          : Colors.white),
                  border: const Border.fromBorderSide(_kBorder2),
                ),
                child: Text(
                  r,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sel
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Desktop list (white container with dividers) ──────────────────────────
  Widget _buildDesktopList(bool isDark) {
    final users = _paginatedUsers;
    if (users.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E24) : Colors.white,
          border: const Border.fromBorderSide(_kBorder2),
          boxShadow: _kHardShadow,
        ),
        child: Center(
          child: Text(
            'Tidak ada user ditemukan.',
            style: GoogleFonts.inter(
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E24) : Colors.white,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kHardShadow,
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: users.length,
        separatorBuilder: (_, __) =>
            Container(height: 1.5, color: Colors.black),
        itemBuilder: (ctx, i) {
          final u = users[i];
          return _NeoUserRow(
            user: u,
            isDark: isDark,
            onEdit: () => _showUserForm(u),
            onDelete: () => _deleteUser(u['id'].toString()),
          ).animate(delay: (i * 35).ms).fadeIn(duration: 260.ms);
        },
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _buildPagination(bool isDark) {
    final total = _totalPages;
    if (total <= 1) return const SizedBox.shrink();

    final List<int?> pages = [];
    for (int p = 1; p <= total; p++) {
      if (p == 1 ||
          p == total ||
          (p >= _currentPage - 1 && p <= _currentPage + 1)) {
        pages.add(p);
      } else if (pages.isNotEmpty &&
          pages.last != null &&
          pages.last != p - 1) {
        pages.add(null); // ellipsis
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NeoPagBtn(
            label: '<',
            selected: false,
            enabled: _currentPage > 1,
            isDark: isDark,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 4),
          ...pages.map((p) {
            if (p == null) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                child: Text('...',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _NeoPagBtn(
                label: '$p',
                selected: p == _currentPage,
                enabled: true,
                isDark: isDark,
                onTap: () => setState(() => _currentPage = p),
              ),
            );
          }),
          const SizedBox(width: 4),
          _NeoPagBtn(
            label: '>',
            selected: false,
            enabled: _currentPage < total,
            isDark: isDark,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────
  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? _kBgPageDark : _kBgPage,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonBox(height: 80, isDark: isDark),
          const SizedBox(height: 10),
          _SkeletonBox(height: 80, isDark: isDark),
          const SizedBox(height: 10),
          _SkeletonBox(height: 80, isDark: isDark),
          const SizedBox(height: 14),
          _SkeletonBox(height: 160, isDark: isDark),
          const SizedBox(height: 10),
          _SkeletonBox(height: 70, isDark: isDark),
          const SizedBox(height: 10),
          _SkeletonBox(height: 70, isDark: isDark),
          const SizedBox(height: 10),
          _SkeletonBox(height: 70, isDark: isDark),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEO STAT CARD
// ═══════════════════════════════════════════════════════════════════════════
class _NeoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isDark;

  const _NeoStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2E24) : Colors.white;
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kHardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF777777),
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          // Icon square — no border, soft coloured bg
          Container(
            width: 52,
            height: 52,
            color: iconBg,
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEO USER CARD  (Mobile — individual card with hard shadow)
// ═══════════════════════════════════════════════════════════════════════════
class _NeoUserCard extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NeoUserCard({
    required this.user,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _avatarBg(String role) {
    switch (role) {
      case 'Guru':
        return _kAvGuru;
      case 'Admin':
        return _kAvAdmin;
      default:
        return _kAvSiswa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role  = user['role']  ?? 'Siswa';
    final name  = user['nama']  ?? '-';
    final email = user['email'] ?? '-';
    final kelas = (user['kelas'] ?? '').toString();
    final bg    = isDark ? const Color(0xFF1A2E24) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: _kHardShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar — SQUARE with black border
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _avatarBg(role),
              border: const Border.fromBorderSide(_kBorder2),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + badges + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _NeoBadge(
                        label: role.toUpperCase(),
                        bg: _kBadgeRoleBg,
                        textColor: Colors.white),
                    if (kelas.isNotEmpty)
                      _NeoBadge(
                          label: kelas.toUpperCase(),
                          bg: _kBadgeKelasBg,
                          textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF555555),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Edit + Delete — small sharp-square buttons
          Column(
            children: [
              _NeoIconBtn(
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                  isDark: isDark),
              const SizedBox(height: 6),
              _NeoIconBtn(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                  isDark: isDark,
                  isDelete: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEO USER ROW  (Desktop — inside white panel with dividers)
// ═══════════════════════════════════════════════════════════════════════════
class _NeoUserRow extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NeoUserRow({
    required this.user,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _avatarBg(String role) {
    switch (role) {
      case 'Guru':
        return _kAvGuru;
      case 'Admin':
        return _kAvAdmin;
      default:
        return _kAvSiswa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role  = user['role']  ?? 'Siswa';
    final name  = user['nama']  ?? '-';
    final email = user['email'] ?? '-';
    final kelas = (user['kelas'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Avatar — SQUARE with black border
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _avatarBg(role),
              border: const Border.fromBorderSide(_kBorder2),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white54
                        : const Color(0xFF555555),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Role + kelas badges
          Wrap(
            spacing: 6,
            children: [
              _NeoBadge(
                  label: role.toUpperCase(),
                  bg: _kBadgeRoleBg,
                  textColor: Colors.white),
              if (kelas.isNotEmpty)
                _NeoBadge(
                    label: kelas,
                    bg: _kBadgeKelasBg,
                    textColor: Colors.white),
            ],
          ),
          const SizedBox(width: 12),

          // Edit + Delete buttons
          _NeoIconBtn(
              icon: Icons.edit_outlined,
              onTap: onEdit,
              isDark: isDark),
          const SizedBox(width: 6),
          _NeoIconBtn(
              icon: Icons.delete_outline_rounded,
              onTap: onDelete,
              isDark: isDark,
              isDelete: true),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Role / kelas badge — solid colour, sharp rectangular
class _NeoBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _NeoBadge(
      {required this.label,
      required this.bg,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Small icon button — sharp square with black border
class _NeoIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDelete;

  const _NeoIconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF243D2D) : Colors.white,
          border: const Border.fromBorderSide(_kBorder15),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isDelete
              ? Colors.red.shade700
              : (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

/// Pagination button — sharp square, active = dark green
class _NeoPagBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _NeoPagBtn({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary
              : (isDark ? const Color(0xFF1A2E24) : Colors.white),
          border: const Border.fromBorderSide(_kBorder15),
          boxShadow:
              selected ? _kSmallShadow : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : (enabled
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey),
          ),
        ),
      ),
    );
  }
}

/// ALL-CAPS form label
class _NeoLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _NeoLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Text field with black border, sharp corners
class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color bg;
  final Color textColor;
  final TextInputType keyboardType;

  const _NeoTextField({
    required this.controller,
    required this.hint,
    required this.bg,
    required this.textColor,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: const Border.fromBorderSide(_kBorder2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

/// Static skeleton placeholder box
class _SkeletonBox extends StatelessWidget {
  final double height;
  final bool isDark;

  const _SkeletonBox({required this.height, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2E24)
            : Colors.grey.shade200,
        border: const Border.fromBorderSide(_kBorder2),
      ),
    );
  }
}
