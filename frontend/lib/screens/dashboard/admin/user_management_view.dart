import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/users'),
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
        Uri.parse('http://localhost:3000/api/users/$id'),
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
                    ? Uri.parse('http://localhost:3000/api/users/${user['id']}')
                    : Uri.parse('http://localhost:3000/api/users');
                
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Kelas/Mapel', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _users.map((user) {
                return DataRow(cells: [
                  DataCell(Text(user['nama'] ?? '-')),
                  DataCell(Chip(
                    label: Text(user['role'] ?? 'Siswa', style: const TextStyle(fontSize: 12)),
                    backgroundColor: user['role'] == 'Guru' ? Colors.purple.shade100 : Colors.blue.shade100,
                  )),
                  DataCell(Text(user['kelas'] ?? '-')),
                  DataCell(Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUserForm(user)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteUser(user['id'])),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}