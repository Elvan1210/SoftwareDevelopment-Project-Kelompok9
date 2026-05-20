import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../widgets/app_shell.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'guru_tugas_detail_screen.dart';
import '../../../services/upload_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class GuruTugasView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const GuruTugasView({
    super.key,
    required this.userData,
    required this.token,
    required this.teamData,
  });

  @override
  State<GuruTugasView> createState() => _GuruTugasViewState();
}

class _GuruTugasViewState extends State<GuruTugasView> {
  List<dynamic> _tugasList = [];
  List<dynamic> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChannels();
    _fetchTugas();
  }

  Future<void> _fetchChannels() async {
    try {
      final kelasId = widget.teamData['id'];
      final res = await http.get(
        Uri.parse('$baseUrl/api/channels?kelas_id=$kelasId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        if (mounted) setState(() => _channels = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint("Error channel: $e");
    }
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
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
    final judulCtrl =
        TextEditingController(text: isEditing ? tugas['judul'] : '');
    final deskripsiCtrl = TextEditingController(
        text: isEditing ? (tugas['deskripsi'] ?? '') : '');
    final linkCtrl =
        TextEditingController(text: isEditing ? (tugas['link'] ?? '') : '');

    DateTime? selectedDeadline;
    if (isEditing && tugas['deadline'] != null) {
      selectedDeadline = DateTime.tryParse(tugas['deadline']);
    }

    String selectedChannelId =
        isEditing ? (tugas['channel_id'] ?? 'general') : 'general';
    bool isUploading = false; // State untuk loading upload

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deadlineStr = selectedDeadline != null
              ? DateFormat('dd MMM yyyy, HH:mm').format(selectedDeadline!)
              : (isEditing
                  ? (tugas['deadline'] ?? 'Pilih Deadline')
                  : 'Pilih Deadline');

          Future<void> handleUploadFile() async {
            fp.FilePickerResult? result =
                await fp.FilePicker.platform.pickFiles(
              type: fp.FileType.custom,
              allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
              withData: true,
            );

            if (result != null && result.files.single.bytes != null) {
              setDialogState(() => isUploading = true);

              String? url = await UploadService.uploadFile(
                fileBytes: result.files.single.bytes!,
                fileName: result.files.single.name,
                token: widget.token,
              );

              setDialogState(() => isUploading = false);

              if (url != null) {
                linkCtrl.text = url; // Isi kolom link secara otomatis!
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('File terunggah!'),
                      backgroundColor: Colors.green));
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Gagal upload!'),
                      backgroundColor: Colors.red));
                }
              }
            }
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161B27) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB), width: 1.2),
            ),
            title: Text(isEditing ? 'Edit Tugas' : 'Buat Tugas Baru',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppTheme.textLight)),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.9, 
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                        controller: judulCtrl,
                        labelText: 'Judul Tugas',
                        prefixIcon: LucideIcons.type),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                        border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: deskripsiCtrl,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white : AppTheme.textLight),
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Detail',
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                          prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedChannelId,
                      dropdownColor: isDark ? const Color(0xFF161B27) : Colors.white,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white : AppTheme.textLight, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Bagikan ke Channel...',
                        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600),
                        prefixIcon: const Icon(LucideIcons.messageSquare, size: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: 'general',
                            child: Text('General (Seluruh Kelas)',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis)),
                        for (var c in _channels)
                          DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(
                                c['nama_channel'] ?? '-',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedChannelId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // TOMBOL DEADLINE...
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDeadline ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100));
                        if (date != null) {
                          if (!ctx.mounted) return;
                          final time = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(
                                  selectedDeadline ?? DateTime.now()));
                          if (time != null) {
                            setDialogState(() => selectedDeadline = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
                          border: Border.all(color: isDark ? const Color(0xFF252D3D) : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(LucideIcons.calendar,
                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                              size: 18),
                          const SizedBox(width: 12),
                          Text(
                            deadlineStr,
                            style: GoogleFonts.plusJakartaSans(
                              color: selectedDeadline != null
                                  ? (isDark ? Colors.white : AppTheme.textLight)
                                  : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TOMBOL UPLOAD FILE
                    Row(
                      children: [
                        Expanded(
                          child: PremiumElevatedButton(
                            onPressed: isUploading ? null : handleUploadFile,
                            icon: isUploading ? null : LucideIcons.uploadCloud,
                            iconSize: 14,
                            color: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            radius: 10,
                            child: isUploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'Upload Lampiran Soal',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: linkCtrl,
                        labelText: 'Link File (Terisi Otomatis/Manual)',
                        prefixIcon: LucideIcons.link),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Batal', style: TextStyle(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, fontWeight: FontWeight.w600))),
              PremiumElevatedButton(
                onPressed: () async {
                  final body = {
                    'judul': judulCtrl.text,
                    'deskripsi': deskripsiCtrl.text,
                    'deadline': selectedDeadline?.toIso8601String() ??
                        (isEditing ? tugas['deadline'] : null),
                    'link': linkCtrl.text,
                    'mapel': widget.teamData['mapel'] ?? widget.userData['kelas'] ?? '-',
                    'kelas': widget.teamData['nama_kelas'],
                    'kelas_id': widget.teamData['id'],
                    'guru_id': widget.userData['id'],
                    'guru_nama': widget.userData['nama'],
                    'channel_id': selectedChannelId,
                    'waktu': DateTime.now().toIso8601String(),
                  };
                  final url = isEditing
                      ? '$baseUrl/api/tugas/${tugas['id']}'
                      : '$baseUrl/api/tugas';
                  final response = await (isEditing
                      ? http.put(Uri.parse(url),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode(body))
                      : http.post(Uri.parse(url),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}'
                          },
                          body: jsonEncode(body)));

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchTugas();
                  }
                },
                color: Theme.of(context).colorScheme.secondary,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
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
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AppFAB(
        onPressed: () => _showTugasForm(),
        icon: LucideIcons.plusSquare,
        label: 'Buat Tugas',
      ),
      body: _tugasList.isEmpty
          ? EmptyState(
              icon: LucideIcons.clipboardList,
              message: 'Belum ada tugas di kelas ini.',
              color: Theme.of(context).colorScheme.secondary)
          : RepaintBoundary(
              child: RefreshIndicator(
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
                      if (t['deadline'] != null &&
                          t['deadline'].toString().isNotEmpty) {
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

                    List<Widget> slivers = [];
                    for (int i = 0; i < groupKeys.length; i++) {
                      final key = groupKeys[i];
                      final items = groups[key]!;

                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      slivers.add(SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padding.left + 4, 24, padding.right + 4, 12),
                          child: Row(
                            children: [
                              Text(
                                key.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFF9EAAFF) : const Color(0xFF4C51BF),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Divider(
                                  color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ));

                      slivers.add(SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            padding.left,
                            0,
                            padding.right,
                            i < groupKeys.length - 1 ? 24 : padding.bottom),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: crossCount == 1 ? 2.5 : 2.2,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, j) {
                              final t = items[j];
                              return _GuruTugasCard(
                                tugas: t,
                                onEdit: () => _showTugasForm(t),
                                onDelete: () =>
                                    _deleteTugas(t['id'].toString()),
                                onDetail: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GuruTugasDetailScreen(
                                        tugas: t, token: widget.token),
                                  ),
                                ),
                              )
                                  .animate(delay: (j * 40).ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(
                                      begin: 0.1, curve: Curves.easeOutQuart);
                            },
                            childCount: items.length,
                          ),
                        ),
                      ));
                    }

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      slivers: slivers,
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

  const _GuruTugasCard({
    required this.tugas,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  String _formatDeadline(String? dl) {
    if (dl == null || dl.isEmpty) return '-';
    final parsed = DateTime.tryParse(dl);
    if (parsed != null) {
      return DateFormat('dd MMM yyyy, HH:mm').format(parsed);
    }
    return dl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2538) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withAlpha(isDark ? 55 : 30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 8),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(isDark ? 25 : 15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withAlpha(isDark ? 60 : 40),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(LucideIcons.clipboardList, color: accent, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tugas['judul'] ?? '-',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: isDark ? Colors.white : AppTheme.textLight,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Kelas: ${tugas['kelas'] ?? '-'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      icon: Icon(
                        LucideIcons.moreVertical,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        size: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.edit2, size: 16),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash, color: Colors.red, size: 16),
                              SizedBox(width: 10),
                              Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
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
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: const Color(0xFFF59E0B).withAlpha(180),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDeadline(tugas['deadline']),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(isDark ? 20 : 12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withAlpha(isDark ? 55 : 35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, color: accent, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
