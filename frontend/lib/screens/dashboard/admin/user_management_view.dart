import 'package:flutter/material.dart';
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
  bool _isLoading = false;
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
        setState(() => _users = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(String id) async {
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
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Edit User' : 'Tambah User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                TextField(
                  controller: passCtrl, 
                  decoration: InputDecoration(labelText: isEditing ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password'),
                  obscureText: true,
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['Siswa', 'Guru', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setStateDialog(() => role = val!),
                ),
                TextField(controller: kelasCtrl, decoration: const InputDecoration(labelText: 'Kelas / Mapel')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final url = isEditing 
                    ? Uri.parse('$baseUrl/api/users/${user['id']}')
                    : Uri.parse('$baseUrl/api/users');
                
                final body = {
                  'nama': namaCtrl.text,
                  'email': emailCtrl.text,
                  'role': role,
                  'kelas': kelasCtrl.text,
                };
                if (!isEditing || passCtrl.text.isNotEmpty) {
                  body['password'] = passCtrl.text;
                }

                try {
                  if (isEditing) {
                    await http.put(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body));
                  } else {
                    await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchUsers();
                } catch (e) {
                  debugPrint("Error saving: $e");
                }
              },
              child: const Text('Simpan'),
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
      final kelas = (user['kelas'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return nama.contains(searchStr) || role.contains(searchStr) || kelas.contains(searchStr) || email.contains(searchStr);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah User', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, email, kelas...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedRole,
                        icon: Icon(Icons.filter_list, color: Colors.blue.shade700),
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        items: ['Semua', 'Siswa', 'Guru', 'Admin']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r == 'Semua' ? 'Filter Role' : r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Tidak ada user yang ditemukan.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (_, index) {
                            final user = _filteredUsers[index];
                            final role = user['role'] ?? 'Siswa';
                            final isSiswa = role == 'Siswa';
                            final isGuru = role == 'Guru';
                            final roleColor = isGuru ? Colors.purple : (isSiswa ? Colors.blue : Colors.orange);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: roleColor.withOpacity(0.1),
                                      child: Icon(
                                        isGuru ? Icons.history_edu : (isSiswa ? Icons.face : Icons.admin_panel_settings),
                                        color: roleColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['nama'] ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? '-',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                                child: Text(roleStr(role), style: TextStyle(color: roleColor.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              if ((user['kelas'] ?? '').toString().isNotEmpty && user['kelas'] != '-') 
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                                  child: Text(
                                                    '${isGuru ? "Mapel" : "Kelas"}: ${user['kelas']}',
                                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, color: Colors.blue.shade400),
                                          onPressed: () => _showUserForm(user),
                                          tooltip: 'Edit User',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                          onPressed: () => _deleteUser(user['id']),
                                          tooltip: 'Hapus User',
                                        ),
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
        ],
      ),
    );
  }

  String roleStr(String role) {
    if (role == 'Siswa') return 'Siswa';
    if (role == 'Guru') return 'Guru';
    if (role == 'Admin') return 'Admin';
    return role;
  }
}