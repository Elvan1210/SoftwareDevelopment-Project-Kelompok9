// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../config/api_config.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class SiswaTeamsView extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   final String token;
//   const SiswaTeamsView({super.key, required this.userData, required this.token});

//   @override
//   State<SiswaTeamsView> createState() => _SiswaTeamsViewState();
// }

// class _SiswaTeamsViewState extends State<SiswaTeamsView> {
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
//       // Fetch kelas yang mana array siswa_ids memuat id siswa ini
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/kelas?siswa_id=$userId'),
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
//             title: const Text('Gabung ke Kelas Baru', style: TextStyle(fontWeight: FontWeight.w900)),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text('Minta kode akses kepada guru Anda, lalu masukkan di sini.'),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: codeCtrl,
//                   maxLength: 8,
//                   textCapitalization: TextCapitalization.characters,
//                   decoration: InputDecoration(
//                     labelText: 'Kode Akses (8 Karakter)',
//                     prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
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
//                     : const Text('Gabung', style: TextStyle(fontWeight: FontWeight.w800)),
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
//         icon: const Icon(Icons.group_add_rounded),
//         label: const Text('Gabung Kelas'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//       ).animate().fadeIn().slideY(begin: 0.5),
//       body: _myTeams.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.backpack_rounded, size: 80, color: Colors.grey.shade400),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Kamu belum tergabung di kelas mana pun.',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Gunakan kode dari gurumu untuk masuk ke dalam kelas.',
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
//                                 Icon(Icons.menu_book_rounded, color: Colors.white.withAlpha(200)),
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
//                                 CircleAvatar(
//                                   radius: 12,
//                                   backgroundColor: Colors.grey.shade200,
//                                   child: Icon(Icons.person, size: 16, color: Colors.grey.shade600),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     tim['guru_nama'] ?? 'Guru Belum Ditugaskan', 
//                                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
//                                     maxLines: 1, overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
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
import 'siswa_team_detail_layout.dart'; // <-- Import layout detail tim

class SiswaTeamsView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaTeamsView({super.key, required this.userData, required this.token});

  @override
  State<SiswaTeamsView> createState() => _SiswaTeamsViewState();
}

class _SiswaTeamsViewState extends State<SiswaTeamsView> {
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
      // Fetch kelas yang mana array siswa_ids memuat id siswa ini
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas?siswa_id=$userId'),
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
            title: const Text('Gabung ke Kelas Baru', style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Minta kode akses kepada guru Anda, lalu masukkan di sini.'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  maxLength: 8,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode Akses (8 Karakter)',
                    prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
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
                    : const Text('Gabung', style: TextStyle(fontWeight: FontWeight.w800)),
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
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Gabung Kelas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ).animate().fadeIn().slideY(begin: 0.5),
      body: _myTeams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backpack_rounded, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Kamu belum tergabung di kelas mana pun.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan kode dari gurumu untuk masuk ke dalam kelas.',
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
                          builder: (context) => SiswaTeamDetailLayout(
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
                                Icon(Icons.menu_book_rounded, color: Colors.white.withAlpha(200)),
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
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tim['guru_nama'] ?? 'Guru Belum Ditugaskan', 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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