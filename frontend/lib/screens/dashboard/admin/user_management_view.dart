import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        setState(() => _users = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint("Error: $e");
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
        debugPrint("Error: $e");
      }
    }
  }

  void _showUserForm([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    final namaCtrl = TextEditingController(text: isEditing ? user['nama'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] : '');
    final passCtrl = TextEditingController();
    final kelasCtrl = TextEditingController(text: isEditing ? (user['kelas'] ?? '') : '');
    String role = isEditing ? (user['role'] ?? 'Siswa') : 'Siswa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'Edit User' : 'Tambah User Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  AppTextField(controller: namaCtrl, labelText: 'Nama Lengkap', prefixIcon: Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  AppTextField(controller: emailCtrl, labelText: 'Email Address', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  AppTextField(controller: passCtrl, labelText: isEditing ? 'Password Baru (Opsional)' : 'Password', prefixIcon: Icons.lock_outline_rounded, obscureText: true),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withAlpha(50),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: ['Siswa', 'Guru', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setDialogState(() => role = val!),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(controller: kelasCtrl, labelText: 'Kelas / Mapel', prefixIcon: Icons.class_outlined),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getAdaptiveTeal(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final body = {
                  'nama': namaCtrl.text,
                  'email': emailCtrl.text,
                  'role': role,
                  'kelas': kelasCtrl.text,
                };
                if (!isEditing || passCtrl.text.isNotEmpty) {
                  body['password'] = passCtrl.text;
                }

                final url = isEditing ? Uri.parse('$baseUrl/api/users/${user['id']}') : Uri.parse('$baseUrl/api/users');
                final response = await (isEditing
                    ? http.put(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body))
                    : http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body)));

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchUsers();
                  
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('User berhasil disimpan!'),
                        backgroundColor: AppTheme.getAdaptiveTeal(ctx),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } else {
                  final data = jsonDecode(response.body);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(data['message'] ?? 'Gagal menyimpan user'),
                        backgroundColor: const Color(0xFFF27F33),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan User', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _filteredUsers {
    return _users.where((user) {
      final roleMatches = _selectedRole == 'Semua' || (user['role'] ?? '') == _selectedRole;
      if (!roleMatches) return false;

      if (_searchQuery.isEmpty) return true;
      final searchStr = _searchQuery.toLowerCase();
      final nama = (user['nama'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return nama.contains(searchStr) || role.contains(searchStr) || email.contains(searchStr);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    final totalUsers = _users.length;
    final totalTeachers = _users.where((u) => u['role'] == 'Guru').length;
    final totalStudents = _users.where((u) => u['role'] == 'Siswa').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
        floatingActionButton: AppFAB(
          onPressed: () => _showUserForm(),
          icon: Icons.person_add_rounded,
          label: 'Tambah User',
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  _buildStatCard('Total User', totalUsers.toString(), AppTheme.getAdaptiveTeal(context)),
                  const SizedBox(width: 16),
                  _buildStatCard('Guru', totalTeachers.toString(), const Color(0xFFF27F33)),
                  const SizedBox(width: 16),
                  _buildStatCard('Siswa', totalStudents.toString(), const Color(0xFF76AFB8)),
                ],
              ).animate().fadeIn().slideY(begin: -0.1),
            ),

            RepaintBoundary(child: _buildHeader()),

            Expanded(
              child: _filteredUsers.isEmpty
                  ? EmptyState(icon: Icons.person_search_rounded, message: 'Tidak ada user ditemukan.', color: AppTheme.getAdaptiveTeal(context))
                  : RepaintBoundary(
                      child: RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: LayoutBuilder(
                          builder: (ctx, c) {
                            final w = c.maxWidth;
                            final padding = Breakpoints.screenPadding(w);
                            final crossCount = w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1);

                            return CustomScrollView(
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              slivers: [
                                SliverPadding(
                                  padding: padding,
                                  sliver: SliverGrid(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: crossCount == 1 ? 2.2 : 1.4,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final u = _filteredUsers[index];
                                          return _UserCard(
                                            user: u,
                                            onEdit: () => _showUserForm(u),
                                            onDelete: () => _deleteUser(u['id'].toString()),
                                          ).animate(delay: (index * 40).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack).slideY(begin: 0.1, curve: Curves.easeOutCubic);
                                      },
                                      childCount: _filteredUsers.length,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: PremiumCard(
        accentColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.withAlpha(180))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          AppTextField(
            hintText: 'Cari nama, email, role...',
            prefixIcon: Icons.search_rounded,
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Siswa', 'Guru', 'Admin'].map((r) {
                final isSelected = _selectedRole == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    child: ChoiceChip(
                      label: Text(r),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedRole = r),
                      backgroundColor: Colors.transparent,
                      selectedColor: AppTheme.getAdaptiveTeal(context).withAlpha(isSelected ? 40 : 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: isSelected ? AppTheme.getAdaptiveTeal(context) : Colors.grey.withAlpha(50))),
                      labelStyle: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppTheme.getAdaptiveTeal(context) : Colors.grey),
                      showCheckmark: false,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(24), child: SkeletonLoader(height: 80, radius: 24)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: SkeletonLoader(height: 56, radius: 16)),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEdit, onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String role = user['role'] ?? 'Siswa';
    final roleColor = role == 'Guru' ? const Color(0xFFF27F33) : (role == 'Admin' ? AppTheme.getAdaptiveTeal(context) : const Color(0xFF76AFB8));

    return PremiumCard(
      accentColor: roleColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [roleColor, roleColor.withAlpha(80)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(role == 'Guru' ? Icons.history_edu_rounded : (role == 'Admin' ? Icons.vpn_key_rounded : Icons.face_6_rounded), color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: roleColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                icon: Icon(Icons.more_horiz_rounded, size: 20, color: theme.colorScheme.onSurface.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.alternate_email_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(80)),
              const SizedBox(width: 8),
              Expanded(child: Text(user['email'] ?? '-', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          if ((user['kelas'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.class_outlined, size: 14, color: theme.colorScheme.onSurface.withAlpha(80)),
                const SizedBox(width: 8),
                Text(user['kelas'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(180))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
