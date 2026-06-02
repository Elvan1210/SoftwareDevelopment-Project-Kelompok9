import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
// import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// --- NEO-BRUTALIST CONSTANTS ---
const Color _kPrimary = Color(0xFF2E5343); // Dark Green
const Color _kPastelBlue = Color(0xFFC4D7ED);
const Color _kPastelPeach = Color(0xFFF4C7B5); // Delete red/peach
const Color _kBgColor = Color(0xFFF4F7F6); // Very light ice-blue/white
const Color _kMint = Color(0xFFB7E0D2); // Light mint for refresh button
const BorderSide _kBorder2 = BorderSide(color: Colors.black, width: 2.0);
const BorderSide _kBorder15 = BorderSide(color: Colors.black, width: 1.5);
const BoxShadow _kHardShadow = BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0);
// Removed unused shadow

class KelasManagementView extends StatefulWidget {
  final String token;
  const KelasManagementView({super.key, required this.token});

  @override
  State<KelasManagementView> createState() => _KelasManagementViewState();
}

class _KelasManagementViewState extends State<KelasManagementView> {
  List<dynamic> _kelasList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await _fetchKelas();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchKelas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        _kelasList = dec is List ? dec : [];
      }
    } catch (e) {
      debugPrint('Error fetching kelas: $e');
    }
  }

  Future<void> _deleteKelas(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin ingin menghapus kelas ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/kelas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchKelas();
        setState(() {});
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showKelasForm([Map<String, dynamic>? kelas]) {
    final isEditing = kelas != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // In dark mode, we'll keep colors flat, but maybe invert text colors if needed.
    // The design is very bright/retro so we stick to absolute colors for the cards.
    final textCol = isDark ? Colors.white : Colors.black;
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    String generateRandomCode(int length) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = math.Random();
      return String.fromCharCodes(Iterable.generate(
          length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    }

    String initialNama = '';
    String initialMapel = '';
    
    if (isEditing && kelas['nama_kelas'] != null) {
      String fullName = kelas['nama_kelas'];
      if (fullName.contains(' - ')) {
        final parts = fullName.split(' - ');
        initialNama = parts[0];
        initialMapel = parts.sublist(1).join(' - ');
      } else {
        initialNama = fullName;
      }
    }

    final namaCtrl = TextEditingController(text: initialNama);
    final mapelCtrl = TextEditingController(text: initialMapel);
    final kodeCtrl = TextEditingController(
        text: isEditing ? (kelas['kode_kelas'] ?? '') : generateRandomCode(6));
    final tahunAjaranCtrl = TextEditingController(
        text: isEditing ? (kelas['tahun_ajaran'] ?? '') : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: bgCol,
              border: const Border.fromBorderSide(_kBorder2),
              boxShadow: const [_kHardShadow],
              borderRadius: BorderRadius.zero, // Sharp corners
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: _kPrimary,
                      border: Border(bottom: _kBorder2),
                    ),
                    child: Text(
                      isEditing ? 'EDIT KELAS' : 'BUAT KELAS BARU',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  
                  // FORM BODY
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KODE AKSES
                        _neoLabel('KODE AKSES', textCol),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black54 : _kBgColor,
                                  border: const Border.fromBorderSide(_kBorder2),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  kodeCtrl.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: textCol,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  kodeCtrl.text = generateRandomCode(6);
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: _kMint,
                                  border: Border.fromBorderSide(_kBorder2),
                                ),
                                child: const Icon(LucideIcons.refreshCw, color: Colors.black, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // NAMA KELAS
                        _neoLabel('NAMA KELAS', textCol),
                        _NeoTextField(
                          controller: namaCtrl,
                          hint: 'Contoh: XII - RPL 1',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // MATA PELAJARAN
                        _neoLabel('MATA PELAJARAN', textCol),
                        _NeoTextField(
                          controller: mapelCtrl,
                          hint: 'Contoh: Pemrograman Web',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // TAHUN AJARAN
                        _neoLabel('TAHUN AJARAN', textCol),
                        _NeoTextField(
                          controller: tahunAjaranCtrl,
                          hint: 'Contoh: 2023/2024 Genap',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // FOOTER BUTTONS
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black, width: 2.0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(right: BorderSide(color: Colors.black, width: 2.0)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Batal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (namaCtrl.text.isEmpty) return;

                              String combinedName = namaCtrl.text;
                              if (mapelCtrl.text.isNotEmpty) {
                                combinedName += ' - ${mapelCtrl.text}';
                              }

                              final Map<String, dynamic> body = {
                                'nama_kelas': combinedName,
                                'kode_kelas': kodeCtrl.text,
                                'tahun_ajaran': tahunAjaranCtrl.text,
                                'warna_card': '0xFF2E5343', // Default flat color for all cards
                              };

                              if (!isEditing) {
                                body['siswa_ids'] = [];
                              }

                              final headers = {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer ${widget.token}'
                              };
                              try {
                                if (isEditing) {
                                  await http.put(
                                      Uri.parse('$baseUrl/api/kelas/${kelas['id']}'),
                                      headers: headers,
                                      body: jsonEncode(body));
                                } else {
                                  await http.post(Uri.parse('$baseUrl/api/kelas'),
                                      headers: headers, body: jsonEncode(body));
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchKelas().then((_) => setState(() {}));
                              } catch (e) {
                                debugPrint('Error saving: $e');
                              }
                            },
                            child: Container(
                              height: 60,
                              decoration: const BoxDecoration(
                                color: _kPrimary,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Simpan Kelas',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF121212) : _kBgColor;
    final textCol = isDark ? Colors.white : Colors.black;

    final filteredList = _kelasList.where((k) {
      final query = _searchQuery.toLowerCase();
      final nama = (k['nama_kelas'] ?? '').toLowerCase();
      final kode = (k['kode_kelas'] ?? '').toLowerCase();
      return nama.contains(query) || kode.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchKelas();
                setState(() {});
              },
              color: _kPrimary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Text(
                            'Daftar Kelas Aktif',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // BUAT KELAS BARU BUTTON
                          GestureDetector(
                            onTap: () => _showKelasForm(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: const BoxDecoration(
                                color: _kPrimary,
                                border: Border.fromBorderSide(_kBorder2),
                                boxShadow: [_kHardShadow],
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.0),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Buat Kelas Baru',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 24),
                          
                          // SEARCH BAR
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black54 : Colors.white,
                              border: const Border.fromBorderSide(_kBorder2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textCol,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari Kelas (Nama / Kode)...',
                                hintStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black38,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(LucideIcons.search, color: textCol),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: Icon(LucideIcons.x, color: textCol),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ) 
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms),
                        ],
                      ),
                    ),
                  ),
                  
                  // CLASS CARDS LIST
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'Pencarian tidak ditemukan.' : 'Belum ada kelas aktif.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textCol.withAlpha(150),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final k = filteredList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _ClassCard(
                                kelas: k,
                                isDark: isDark,
                                onEdit: () => _showKelasForm(k),
                                onDelete: () => _deleteKelas(k['id'].toString()),
                              ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
                            );
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ── Widget: Label Form ──
Widget _neoLabel(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color.withAlpha(180),
        letterSpacing: 1.0,
      ),
    ),
  );
}

// ── Widget: Text Field Neo Brutalist ──
class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  const _NeoTextField({
    required this.controller,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : Colors.white,
        border: const Border.fromBorderSide(_kBorder15),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black38,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

// ── Widget: Class Card ──
class _ClassCard extends StatelessWidget {
  final dynamic kelas;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.kelas,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.white : Colors.black;
    final bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final namaLengkap = kelas['nama_kelas'] ?? '-';
    final guru = kelas['guru_nama'] ?? 'Belum ada';
    final totalSiswa = (kelas['siswa_ids'] as List?)?.length ?? 0;
    final ta = kelas['tahun_ajaran'] ?? '-';
    final kode = kelas['kode_kelas'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        border: const Border.fromBorderSide(_kBorder2),
        boxShadow: const [_kHardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD BODY
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  namaLengkap,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // KODE TAG
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    color: _kBgColor,
                    border: Border.fromBorderSide(_kBorder15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'KODE:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kode,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: kode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kode $kode disalin!', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white)),
                              backgroundColor: Colors.black,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Icon(LucideIcons.copy, size: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GURU INFO
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 18, color: textCol.withAlpha(200)),
                    const SizedBox(width: 12),
                    Text(
                      'Guru: ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textCol,
                      ),
                    ),
                    Text(
                      guru,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // TOTAL SISWA INFO
                Row(
                  children: [
                    Icon(LucideIcons.users, size: 18, color: textCol.withAlpha(200)),
                    const SizedBox(width: 12),
                    Text(
                      'Total: ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textCol,
                      ),
                    ),
                    Text(
                      '$totalSiswa Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // CARD FOOTER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 2.0)),
            ),
            child: Row(
              children: [
                Text(
                  'TA $ta',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textCol.withAlpha(150),
                  ),
                ),
                const Spacer(),
                // EDIT BTN
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _kPastelBlue,
                      border: Border.fromBorderSide(_kBorder2),
                    ),
                    child: const Icon(LucideIcons.edit2, size: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                // DELETE BTN
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _kPastelPeach,
                      border: Border.fromBorderSide(_kBorder2),
                    ),
                    child: const Icon(LucideIcons.trash, size: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
