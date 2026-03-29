// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../config/api_config.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class GuruTeamsView extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   final String token;
//   const GuruTeamsView({super.key, required this.userData, required this.token});

//   @override
//   State<GuruTeamsView> createState() => _GuruTeamsViewState();
// }

// class _GuruTeamsViewState extends State<GuruTeamsView> {
//   List<dynamic> _myTeams = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchMyTeams();
//   }

//   Future<void> _fetchMyTeams() async {
//     setState(() => _isLoading = true);
//     try {
//       final userId = widget.userData['id'] ?? widget.userData['uid'];
//       // Fetch kelas yang memiliki guru_id sesuai dengan id guru ini
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/kelas?guru_id=$userId'),
//         headers: {'Authorization': 'Bearer ${widget.token}'},
//       );
      
//       if (response.statusCode == 200) {
//         final dec = jsonDecode(response.body);
//         _myTeams = dec is List ? dec : [];
//       }
//     } catch (e) {
//       debugPrint('Error fetching teams: $e');
//     }
//     if (mounted) setState(() => _isLoading = false);
//   }

//   void _showJoinDialog() {
//     final codeCtrl = TextEditingController();
//     bool isSubmitting = false;

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//             title: const Text('Gabung ke Tim/Kelas', style: TextStyle(fontWeight: FontWeight.w900)),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Masukkan 8 karakter kode akses kelas untuk bergabung.'),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: codeCtrl,
//                   maxLength: 8,
//                   textCapitalization: TextCapitalization.characters,
//                   decoration: InputDecoration(
//                     labelText: 'Kode Akses',
//                     prefixIcon: const Icon(Icons.vpn_key_rounded),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 onPressed: isSubmitting ? null : () async {
//                   if (codeCtrl.text.trim().isEmpty) return;
//                   setDialogState(() => isSubmitting = true);
                  
//                   try {
//                     final response = await http.post(
//                       Uri.parse('$baseUrl/api/kelas/join'),
//                       headers: {
//                         'Content-Type': 'application/json',
//                         'Authorization': 'Bearer ${widget.token}'
//                       },
//                       body: jsonEncode({'kode_akses': codeCtrl.text.trim().toUpperCase()}),
//                     );
                    
//                     final resBody = jsonDecode(response.body);
                    
//                     if (response.statusCode == 200) {
//                       if (ctx.mounted) {
//                         Navigator.pop(ctx);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text(resBody['message'] ?? 'Berhasil bergabung!'), backgroundColor: Colors.green),
//                         );
//                       }
//                       _fetchMyTeams(); // Refresh daftar tim
//                     } else {
//                       if (ctx.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text(resBody['message'] ?? 'Gagal bergabung'), backgroundColor: Colors.red),
//                         );
//                       }
//                       setDialogState(() => isSubmitting = false);
//                     }
//                   } catch (e) {
//                      if (ctx.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('Terjadi kesalahan jaringan'), backgroundColor: Colors.red),
//                         );
//                      }
//                      setDialogState(() => isSubmitting = false);
//                   }
//                 },
//                 child: isSubmitting 
//                     ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : const Text('Gabung Tim', style: TextStyle(fontWeight: FontWeight.w800)),
//               ),
//             ],
//           );
//         }
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showJoinDialog,
//         icon: const Icon(Icons.add_moderator_rounded),
//         label: const Text('Gabung dengan Kode'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//       ).animate().fadeIn().slideY(begin: 0.5),
//       body: _myTeams.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.groups_rounded, size: 80, color: Colors.grey.shade400),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Anda belum memiliki/masuk ke tim atau kelas.',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Klik tombol di bawah untuk bergabung menggunakan kode akses.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//                   ),
//                 ],
//               ),
//             )
//           : GridView.builder(
//               padding: const EdgeInsets.all(24),
//               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: 350,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 childAspectRatio: 1.5,
//               ),
//               itemCount: _myTeams.length,
//               itemBuilder: (context, index) {
//                 final tim = _myTeams[index];
//                 final color = Color(int.parse(tim['warna_card'] ?? '0xFF3B82F6'));
                
//                 return Card(
//                   elevation: 4,
//                   shadowColor: Colors.black.withAlpha(20),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                   clipBehavior: Clip.antiAlias,
//                   child: InkWell(
//                     onTap: () {
//                       // TODO: Navigasi masuk ke dalam ruang kelas/tim spesifik ini
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Akan membuka ruang kelas: ${tim['nama_kelas']}')),
//                       );
//                     },
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: Container(
//                             color: color,
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Icon(Icons.class_rounded, color: Colors.white.withAlpha(200)),
//                                     const Icon(Icons.more_vert, color: Colors.white),
//                                   ],
//                                 ),
//                                 const Spacer(),
//                                 Text(
//                                   tim['nama_kelas'] ?? '-',
//                                   style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                                   maxLines: 1, overflow: TextOverflow.ellipsis,
//                                 ),
//                                 Text(
//                                   tim['mapel'] ?? '-',
//                                   style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 2,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             color: Theme.of(context).colorScheme.surface,
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade200,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text('Kode: ${tim['kode_akses']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//                                 ),
//                                 const Spacer(),
//                                 Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey.shade600),
//                                 const SizedBox(width: 4),
//                                 Text('${(tim['siswa_ids'] as List?)?.length ?? 0} Siswa', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ).animate(delay: (index * 50).ms).fadeIn().scale();
//               },
//             ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'guru_team_detail_layout.dart'; // <-- Import layout detail tim

class GuruTeamsView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruTeamsView({super.key, required this.userData, required this.token});

  @override
  State<GuruTeamsView> createState() => _GuruTeamsViewState();
}

class _GuruTeamsViewState extends State<GuruTeamsView> {
  List<dynamic> _myTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTeams();
  }

  Future<void> _fetchMyTeams() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.userData['id'] ?? widget.userData['uid'];
      // Fetch kelas yang memiliki guru_id sesuai dengan id guru ini
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas?guru_id=$userId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        _myTeams = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Gabung ke Tim/Kelas', style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan 8 karakter kode akses kelas untuk bergabung.'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  maxLength: 8,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode Akses',
                    prefixIcon: const Icon(Icons.vpn_key_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSubmitting ? null : () async {
                  if (codeCtrl.text.trim().isEmpty) return;
                  setDialogState(() => isSubmitting = true);
                  
                  try {
                    final response = await http.post(
                      Uri.parse('$baseUrl/api/kelas/join'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${widget.token}'
                      },
                      body: jsonEncode({'kode_akses': codeCtrl.text.trim().toUpperCase()}),
                    );
                    
                    final resBody = jsonDecode(response.body);
                    
                    if (response.statusCode == 200) {
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resBody['message'] ?? 'Berhasil bergabung!'), backgroundColor: Colors.green),
                        );
                      }
                      _fetchMyTeams(); // Refresh daftar tim
                    } else {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resBody['message'] ?? 'Gagal bergabung'), backgroundColor: Colors.red),
                        );
                      }
                      setDialogState(() => isSubmitting = false);
                    }
                  } catch (e) {
                     if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Terjadi kesalahan jaringan'), backgroundColor: Colors.red),
                        );
                     }
                     setDialogState(() => isSubmitting = false);
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gabung Tim', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showJoinDialog,
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Gabung dengan Kode'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Anda belum memiliki/masuk ke tim atau kelas.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klik tombol di bawah untuk bergabung menggunakan kode akses.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _myTeams.length,
              itemBuilder: (context, index) {
                final tim = _myTeams[index];
                final color = Color(int.parse(tim['warna_card'] ?? '0xFF3B82F6'));
                
                return Card(
                  elevation: 4,
                  shadowColor: Colors.black.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // Buka halaman detail tim (ruang kelas)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GuruTeamDetailLayout(
                            userData: widget.userData,
                            token: widget.token,
                            teamData: tim, // Mengirim data tim spesifik
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: color,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.class_rounded, color: Colors.white.withAlpha(200)),
                                    const Icon(Icons.more_vert, color: Colors.white),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  tim['nama_kelas'] ?? '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  tim['mapel'] ?? '-',
                                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Theme.of(context).colorScheme.surface,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Kode: ${tim['kode_akses']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('${(tim['siswa_ids'] as List?)?.length ?? 0} Siswa', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 50).ms).fadeIn().scale();
              },
            ),
    );
  }
}