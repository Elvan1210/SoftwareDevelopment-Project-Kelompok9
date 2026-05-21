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
                      backgroundColor: AppTheme.success));
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Gagal upload!'),
                      backgroundColor: AppTheme.error));
                }
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(6, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'EDIT TUGAS' : 'BUAT TUGAS BARU',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: deskripsiCtrl,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Detail',
                          prefixIcon: Icon(LucideIcons.fileText, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedChannelId,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Bagikan ke Channel...',
                        prefixIcon: const Icon(LucideIcons.messageSquare, size: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(children: [
                          Icon(LucideIcons.calendar,
                              color: Theme.of(context).textTheme.bodyMedium!.color!,
                              size: 18),
                          const SizedBox(width: 12),
                          Text(
                            deadlineStr,
                            style: GoogleFonts.poppins(
                              color: selectedDeadline != null
                                  ? Theme.of(context).textTheme.bodyLarge!.color!
                                  : Theme.of(context).textTheme.bodyMedium!.color!,
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
                          child: GestureDetector(
                            onTap: isUploading ? null : handleUploadFile,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(3, 3))],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isUploading) ...[
                                    const Icon(LucideIcons.uploadCloud, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                  ],
                                  isUploading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : Text('Upload File',
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                                ],
                              ),
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
                  // Actions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                            ),
                            child: Text('BATAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface,
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
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
                                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
                                    body: jsonEncode(body))
                                : http.post(Uri.parse(url),
                                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
                                    body: jsonEncode(body)));
                            if (response.statusCode == 200 || response.statusCode == 201) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetchTugas();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2))],
                            ),
                            child: Text('SIMPAN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900, color: Colors.white,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      floatingActionButton: GestureDetector(
        onTap: () => _showTugasForm(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.plusSquare, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('BUAT TUGAS', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5,
            )),
          ]),
        ),
      ).animate().fadeIn().slideY(begin: 0.5),
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

                      slivers.add(SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padding.left + 4, 24, padding.right + 4, 12),
                          child: Row(
                            children: [
                              Text(
                                key.toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Divider(
                                  color: Theme.of(context).dividerColor,
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
        child: SkeletonLoader(height: 90, radius: 4),
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

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(4, 4), blurRadius: 0)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                  ),
                  child: const Icon(LucideIcons.clipboardList, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tugas['judul'] ?? '-',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge!.color!,
                          letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kelas: ${tugas['kelas'] ?? '-'}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyMedium!.color!),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  icon: Icon(LucideIcons.moreVertical,
                    color: Theme.of(context).textTheme.bodyMedium!.color!, size: 18),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(LucideIcons.edit2, size: 16),
                      SizedBox(width: 10),
                      Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(LucideIcons.trash, color: AppTheme.error, size: 16),
                      SizedBox(width: 10),
                      Text('Hapus', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (tugas['deadline'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.clock, size: 11, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 5),
                      Text(_formatDeadline(tugas['deadline']),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                    ]),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onDetail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface, offset: const Offset(2, 2), blurRadius: 0)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('DETAIL', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronRight, color: Colors.white, size: 12),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
