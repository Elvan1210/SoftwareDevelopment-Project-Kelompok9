import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_detail_screen.dart';
import '../../../services/notifikasi_service.dart';
import 'package:intl/intl.dart';

class GuruTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData; // TAMBAHAN: Menerima konteks kelas saat ini

  const GuruTugasView({
    super.key, 
    required this.userData, 
    required this.token,
    required this.teamData, // Wajib diisi
  });

  @override
  State<GuruTugasView> createState() => _GuruTugasViewState();
}

class _GuruTugasViewState extends State<GuruTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      // UBAHAN: Fetch hanya tugas yang memiliki kelas_id sesuai dengan tim ini
      final kelasId = widget.teamData['id'];
      final response = await http.get(
        Uri.parse('$baseUrl/api/tugas?kelas_id=$kelasId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final dec = jsonDecode(response.body);
        setState(() {
          _tugasList = dec is List ? dec : [];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteTugas(String id) async {
    if (await confirmDelete(context, pesan: 'Yakin ingin hapus tugas ini?')) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/tugas/$id'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchTugas();
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  void _showTugasForm([Map<String, dynamic>? tugas]) {
    final isEditing = tugas != null;
    final judulCtrl = TextEditingController(text: isEditing ? tugas['judul'] : '');
    final deskripsiCtrl = TextEditingController(text: isEditing ? (tugas['deskripsi'] ?? '') : '');
    final linkCtrl = TextEditingController(text: isEditing ? (tugas['link'] ?? '') : '');

    DateTime? selectedDeadline;
    if (isEditing && tugas['deadline'] != null) {
      selectedDeadline = DateTime.tryParse(tugas['deadline']);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deadlineStr = selectedDeadline != null 
              ? DateFormat('dd MMM yyyy, HH:mm').format(selectedDeadline!)
              : (isEditing ? (tugas['deadline'] ?? 'Pilih Deadline') : 'Pilih Deadline');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(isEditing ? 'Edit Tugas' : 'Buat Tugas Baru', style: const TextStyle(fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info Kelas Otomatis
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.class_, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Tugas ini akan diterbitkan di kelas: ${widget.teamData['nama_kelas']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AntigravityTextField(controller: judulCtrl, labelText: 'Judul Tugas', prefixIcon: Icons.title_rounded),
                    const SizedBox(height: 16),
                    AntigravityTextField(controller: deskripsiCtrl, labelText: 'Deskripsi Detail', prefixIcon: Icons.description_outlined, keyboardType: TextInputType.multiline),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDeadline ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          if (!ctx.mounted) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDeadline ?? DateTime.now()),
                            initialEntryMode: TimePickerEntryMode.input,
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 12),
                            Text(deadlineStr, style: TextStyle(color: selectedDeadline != null ? Colors.black : Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AntigravityTextField(controller: linkCtrl, labelText: 'Link Pendukung (Opsional)', prefixIcon: Icons.link_rounded),
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
                  // UBAHAN: Sisipkan ID dan Nama Kelas secara otomatis
                  final body = {
                    'judul': judulCtrl.text,
                    'deskripsi': deskripsiCtrl.text,
                    'deadline': selectedDeadline?.toIso8601String() ?? (isEditing ? tugas['deadline'] : null),
                    'link': linkCtrl.text,
                    'mapel': widget.teamData['mapel'] ?? widget.userData['kelas'] ?? '-',
                    'kelas': widget.teamData['nama_kelas'], // Nama kelas otomatis
                    'kelas_id': widget.teamData['id'], // ID kelas otomatis
                    'guru_id': widget.userData['id'],
                  };

                  final url = isEditing ? '$baseUrl/api/tugas/${tugas['id']}' : '$baseUrl/api/tugas';
                  final response = await (isEditing
                      ? http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body))
                      : http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode(body)));

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    if (!isEditing) {
                      NotifikasiService.kirimNotifikasi(
                        judul: 'Tugas Baru', 
                        pesan: 'Tugas baru: ${judulCtrl.text} ditambahkan di kelas ${widget.teamData['nama_kelas']}',
                        token: widget.token,
                        targetKelas: widget.teamData['nama_kelas'],
                        targetRole: 'Siswa',
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchTugas();
                  }
                },
                child: Text(isEditing ? 'Simpan' : 'Terbitkan', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
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
        floatingActionButton: AntigravityFAB(
          onPressed: () => _showTugasForm(),
          icon: Icons.add_task_rounded,
          label: 'Buat Tugas',
        ),
        body: _tugasList.isEmpty
            ? const EmptyState(icon: Icons.assignment_outlined, message: 'Belum ada tugas di kelas ini.', color: Color(0xFF3B82F6))
            : RefreshIndicator(
                onRefresh: _fetchTugas,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.tablet ? 2 : 1;

                    final sortedTasks = List<dynamic>.from(_tugasList);
                    sortedTasks.sort((a, b) {
                      final dA = a['deadline'];
                      final dB = b['deadline'];
                      if (dA == null && dB == null) return 0;
                      if (dA == null) return 1;
                      if (dB == null) return -1;
                      final dtA = DateTime.tryParse(dA);
                      final dtB = DateTime.tryParse(dB);
                      if (dtA != null && dtB != null) return dtA.compareTo(dtB);
                      return dA.toString().compareTo(dB.toString());
                    });

                    final Map<String, List<dynamic>> groups = {};
                    for (final t in sortedTasks) {
                      String dateLabel = 'Tanpa Tenggat Waktu';
                      if (t['deadline'] != null && t['deadline'].toString().isNotEmpty) {
                        final dt = DateTime.tryParse(t['deadline']);
                        if (dt != null) {
                          dateLabel = DateFormat('MMM d, EEEE').format(dt);
                        } else {
                          dateLabel = t['deadline'];
                        }
                      }
                      groups.putIfAbsent(dateLabel, () => []).add(t);
                    }
                    final groupKeys = groups.keys.toList();

                    return RepaintBoundary(
                      child: ListView.builder(
                        padding: padding,
                        itemCount: groupKeys.length,
                        itemBuilder: (_, i) {
                          final key = groupKeys[i];
                          final items = groups[key]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
                                child: Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.grey)),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: crossCount == 1 ? 3.5 : 2.2,
                                ),
                                itemCount: items.length,
                                itemBuilder: (_, j) {
                                  final t = items[j];
                                  return _GuruTugasCard(
                                    tugas: t,
                                    onEdit: () => _showTugasForm(t),
                                    onDelete: () => _deleteTugas(t['id'].toString()),
                                    onDetail: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GuruTugasDetailScreen(tugas: t, token: widget.token),
                                      ),
                                    ),
                                  ).animate(delay: (j * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                                },
                              ),
                              const SizedBox(height: 20),
                              if (i < groupKeys.length - 1) const Divider(color: Colors.white24, height: 1),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonLoader(height: 90, radius: 24),
      ),
    );
  }
}

class _GuruTugasCard extends StatelessWidget {
  final dynamic tugas;
  final VoidCallback onEdit, onDelete, onDetail;

  const _GuruTugasCard({required this.tugas, required this.onEdit, required this.onDelete, required this.onDetail});

  String _formatDeadline(String? dl) {
    if (dl == null || dl.isEmpty) return '-';
    final parsed = DateTime.tryParse(dl);
    if (parsed != null) {
      return DateFormat('dd MMM yyyyy, HH:mm').format(parsed);
    }
    return dl; 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF3B82F6);

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      onTap: onDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tugas['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Kelas: ${tugas['kelas'] ?? '-'}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
                  ],
                ),
              ),
              PopupMenuButton(
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface.withAlpha(100)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (tugas['deadline'] != null)
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: const Color(0xFFF59E0B).withAlpha(180)),
                    const SizedBox(width: 6),
                    Text(_formatDeadline(tugas['deadline']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                  ],
                ),
              Text('Detail >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent.withAlpha(200))),
            ],
          ),
        ],
      ),
    );
  }
}