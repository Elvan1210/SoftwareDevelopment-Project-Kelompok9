import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuruNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;
  const GuruNilaiView({super.key, required this.userData, required this.token, required this.teamData});

  @override
  State<GuruNilaiView> createState() => _GuruNilaiViewState();
}

class _GuruNilaiViewState extends State<GuruNilaiView> {
  List<dynamic> _nilaiList = [];
  List<dynamic> _userList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/nilai'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/users'), headers: headers),
      ]);

      if (responses[0].statusCode == 200) {
        final dec = jsonDecode(responses[0].body);
        List data = dec is List ? dec : [];
        _nilaiList = data.where((n) {
          final bool isMyClass = widget.teamData['id'] != null 
              ? n['kelas_id'].toString() == widget.teamData['id'].toString() 
              : true;
          return n['guru_id'].toString() == widget.userData['id'].toString() && isMyClass;
        }).toList();
      }
      if (responses[1].statusCode == 200) {
        final dec = jsonDecode(responses[1].body);
        List users = dec is List ? dec : [];
        _userList = users.where((u) {
          // Hanya siswa yang ada di kelas ini
          final kelasId = widget.teamData['id']?.toString() ?? '';
          if (u['role'] != 'Siswa') return false;
          if (u['kelas_id'] != null && u['kelas_id'].toString() == kelasId) return true;
          // Cek array siswa_ids di kelas jika user belum set kelas_id
          List sIds = widget.teamData['siswa_ids'] ?? [];
          return sIds.contains(u['id']);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteNilai(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus data nilai ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/nilai/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchData();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _showNilaiForm([Map<String, dynamic>? nilai]) {
    final isEditing = nilai != null;
    String? selectedSiswaId = isEditing ? nilai['siswa_id'].toString() : null;
    final mapelCtrl = TextEditingController(text: isEditing ? nilai['mapel'] : widget.userData['kelas'] ?? '');
    final nilaiCtrl = TextEditingController(text: isEditing ? nilai['nilai']?.toString() : '');
    final keteranganCtrl = TextEditingController(text: isEditing ? nilai['keterangan'] : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'Edit Nilai' : 'Input Nilai Siswa', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSiswaId,
                    decoration: InputDecoration(
                      labelText: 'Pilih Siswa',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withAlpha(50),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: _userList.map<DropdownMenuItem<String>>((u) {
                      return DropdownMenuItem<String>(value: u['id'].toString(), child: Text(u['nama'] ?? '-'));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSiswaId = val),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(controller: mapelCtrl, labelText: 'Mata Pelajaran', prefixIcon: Icons.book_outlined),
                  const SizedBox(height: 16),
                  AppTextField(controller: nilaiCtrl, labelText: 'Nilai (0-100)', prefixIcon: Icons.grade_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  AppTextField(controller: keteranganCtrl, labelText: 'Keterangan / Catatan', prefixIcon: Icons.speaker_notes_outlined, keyboardType: TextInputType.multiline),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (selectedSiswaId == null || nilaiCtrl.text.isEmpty) return;
                final siswa = _userList.firstWhere((u) => u['id'].toString() == selectedSiswaId);
                final body = {
                  'siswa_id': selectedSiswaId,
                  'siswa_nama': siswa['nama'],
                  'mapel': mapelCtrl.text,
                  'nilai': double.tryParse(nilaiCtrl.text) ?? 0,
                  'keterangan': keteranganCtrl.text,
                  'guru_id': widget.userData['id'],
                  'kelas_id': widget.teamData['id'],
                };

                final url = isEditing ? '$baseUrl/api/nilai/${nilai['id']}' : '$baseUrl/api/nilai';
                final response = await (isEditing
                    ? http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body))
                    : http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body)));

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchData();
                }
              },
              child: Text(isEditing ? 'Simpan' : 'Simpan Nilai', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(child: _buildSkeleton());
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AppFAB(
          onPressed: () => _showNilaiForm(),
          icon: Icons.add_chart_rounded,
          label: 'Input Nilai',
        ),
        body: _nilaiList.isEmpty
            ? const EmptyState(icon: Icons.workspace_premium_rounded, message: 'Belum ada data nilai\nyang diinput.', color: Color(0xFF10B981))
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1);

                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossCount == 1 ? 3.0 : 1.5,
                      ),
                      itemCount: _nilaiList.length,
                      itemBuilder: (_, i) {
                        final n = _nilaiList[i];
                        return _GuruNilaiCard(
                          nilai: n,
                          onEdit: () => _showNilaiForm(n),
                          onDelete: () => _deleteNilai(n['id'].toString()),
                        ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
    );
  }
}

class _GuruNilaiCard extends StatelessWidget {
  final dynamic nilai;
  final VoidCallback onEdit, onDelete;

  const _GuruNilaiCard({required this.nilai, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final val = double.tryParse(nilai['nilai'].toString()) ?? 0;
    final color = val >= 80 ? const Color(0xFF10B981) : (val >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return PremiumCard(
      accentColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle), child: Icon(Icons.person_rounded, color: color, size: 16)),
              const SizedBox(width: 10),
              Expanded(child: Text(nilai['siswa_nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(
                onPressed: () {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(offset.dx + renderBox.size.width - 40, offset.dy, offset.dx + renderBox.size.width, offset.dy + 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    items: [
                      PopupMenuItem(onTap: onEdit, child: const Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 12), Text('Edit')])),
                      PopupMenuItem(onTap: onDelete, child: const Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Hapus', style: TextStyle(color: Colors.red))])),
                    ],
                  );
                },
                icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.colorScheme.onSurface.withAlpha(100)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val.toStringAsFixed(0), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
                  const Padding(padding: EdgeInsets.only(bottom: 6, left: 4), child: Text('pts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 2),
              Text(nilai['mapel'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(150))),
            ],
          ),
        ],
      ),
    );
  }
}

