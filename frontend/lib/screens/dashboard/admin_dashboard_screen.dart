import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/users'));
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _filteredUsers = _users;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final nama = user['nama']?.toLowerCase() ?? '';
        final email = user['email']?.toLowerCase() ?? '';
        final role = user['role']?.toLowerCase() ?? '';
        return nama.contains(query) || email.contains(query) || role.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('http://localhost:3000/api/users/$id'));
      if (response.statusCode == 200) {
        _fetchUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showUserForm([Map<String, dynamic>? user]) {
    final isEditing = user != null;
    final namaController = TextEditingController(text: isEditing ? user['nama'] : '');
    final emailController = TextEditingController(text: isEditing ? user['email'] : '');
    final passwordController = TextEditingController();
    String selectedRole = isEditing ? user['role'] : 'Siswa';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'Tambah User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'Password Baru (Opsional)' : 'Password',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: ['Siswa', 'Guru', 'Admin'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() {
                          selectedRole = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = isEditing 
                        ? Uri.parse('http://localhost:3000/api/users/${user['id']}')
                        : Uri.parse('http://localhost:3000/api/users');
                        
                    final body = {
                      'nama': namaController.text,
                      'email': emailController.text,
                      'role': selectedRole,
                    };

                    if (!isEditing || passwordController.text.isNotEmpty) {
                      body['password'] = passwordController.text;
                    }
                    
                    try {
                      final response = isEditing 
                          ? await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
                          : await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
                      
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        _fetchUsers();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan data')));
                      }
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari Nama, Email, atau Role',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(user['nama'] ?? 'Tanpa Nama'),
                          subtitle: Text('${user['email']} • ${user['role']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showUserForm(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}