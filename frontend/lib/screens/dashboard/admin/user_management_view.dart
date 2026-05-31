import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/neo_brutalism.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final namaCtrl = TextEditingController(text: isEditing ? user['nama'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] : '');
    final passCtrl = TextEditingController();
    final kelasCtrl = TextEditingController(text: isEditing ? (user['kelas'] ?? '') : '');
    String role = isEditing ? (user['role'] ?? 'Siswa') : 'Siswa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.indigoPrimary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.userPlus, color: AppTheme.indigoPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEditing ? 'Edit User' : 'Tambah User Baru',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppTextField(controller: namaCtrl, labelText: 'Nama Lengkap', prefixIcon: LucideIcons.user),
                    const SizedBox(height: 16),
                    AppTextField(controller: emailCtrl, labelText: 'Email Address', prefixIcon: LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    AppTextField(controller: passCtrl, labelText: isEditing ? 'Password Baru (Opsional)' : 'Password', prefixIcon: LucideIcons.lock, obscureText: true),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textLight),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        labelText: 'Role',
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        prefixIcon: Icon(LucideIcons.shieldCheck, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 2),
                        ),
                      ),
                      items: ['Siswa', 'Guru', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) => setDialogState(() => role = val!),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(controller: kelasCtrl, labelText: 'Kelas', prefixIcon: LucideIcons.library),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Batal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                        ),
                        const SizedBox(width: 12),
                        PremiumElevatedButton(
                          color: AppTheme.indigoPrimary,
                          textColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          radius: 12,
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
                                    content: Text('User berhasil disimpan!', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                                    backgroundColor: AppTheme.indigoPrimary,
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
                                    content: Text(data['message'] ?? 'Gagal menyimpan user', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                                    backgroundColor: AppTheme.rose,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text('Simpan User', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        icon: LucideIcons.userPlus,
        label: 'Tambah User',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                _buildStatCard('Total User', totalUsers.toString(), AppTheme.indigoPrimary, isDark),
                const SizedBox(width: 16),
                _buildStatCard('Guru', totalTeachers.toString(), AppTheme.success, isDark),
                const SizedBox(width: 16),
                _buildStatCard('Siswa', totalStudents.toString(), AppTheme.amber, isDark),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
          ),

          RepaintBoundary(child: _buildHeader(isDark)),

          Expanded(
            child: _filteredUsers.isEmpty
                ? const EmptyState(icon: LucideIcons.users, message: 'Tidak ada user ditemukan.', color: AppTheme.indigoPrimary)
                : RepaintBoundary(
                    child: RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: AppTheme.indigoPrimary,
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
                                        isDark: isDark,
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

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    IconData icon = LucideIcons.users;
    if (label == 'Guru') icon = LucideIcons.penTool;
    if (label == 'Siswa') icon = LucideIcons.graduationCap;

    return Expanded(
      child: NeoStatCard(
        label: label,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          AppTextField(
            hintText: 'Cari nama, email, role...',
            prefixIcon: LucideIcons.search,
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
                  child: ChoiceChip(
                    label: Text(r),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedRole = r),
                    backgroundColor: Colors.transparent,
                    selectedColor: AppTheme.indigoPrimary.withAlpha(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: isSelected ? AppTheme.indigoPrimary : (Theme.of(context).dividerColor), width: 1.2)),
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? AppTheme.indigoPrimary : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
                    showCheckmark: false,
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
  final bool isDark;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final String role = user['role'] ?? 'Siswa';
    final roleColor = role == 'Guru' ? AppTheme.success : (role == 'Admin' ? AppTheme.rose : AppTheme.indigoPrimary);

    return NeoCard(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surface,
      borderColor: Theme.of(context).dividerColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeoIconBox(
                icon: role == 'Guru' ? LucideIcons.penTool : (role == 'Admin' ? LucideIcons.key : LucideIcons.user),
                iconColor: Colors.white,
                backgroundColor: roleColor,
                borderColor: Theme.of(context).dividerColor,
                size: 24,
              ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['nama'] ?? '-', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: roleColor.withAlpha(20), borderRadius: BorderRadius.circular(6), border: Border.all(color: roleColor.withAlpha(40), width: 1.2)),
                        child: Text(role.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  icon: Icon(LucideIcons.moreHorizontal, size: 20, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [const Icon(LucideIcons.edit2, size: 16), const SizedBox(width: 12), Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))])),
                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(LucideIcons.trash, color: AppTheme.rose, size: 16), const SizedBox(width: 12), Text('Hapus', style: GoogleFonts.poppins(color: AppTheme.rose, fontWeight: FontWeight.bold))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.atSign, size: 13, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                const SizedBox(width: 8),
                Expanded(child: Text(user['email'] ?? '-', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            if ((user['kelas'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.library, size: 13, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                  const SizedBox(width: 8),
                  Text(user['kelas'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white.withAlpha(220) : AppTheme.textLight)),
                ],
              ),
            ],
          ],
        ),
    );
  }
}
