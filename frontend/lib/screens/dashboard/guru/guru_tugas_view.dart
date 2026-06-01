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
  static const _ink = Color(0xFF001E2B);
  static const _primary = Color(0xFF3D6754);
  static const _outline = Color(0xFF717974);

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
      debugPrint('Error channel: $e');
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
        setState(() => _tugasList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
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
        debugPrint('Error: $e');
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
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deadlineStr = selectedDeadline != null
              ? DateFormat('dd MMM yyyy, HH:mm').format(selectedDeadline!)
              : 'Pilih Deadline';

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
                linkCtrl.text = url;
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
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Modal container ──
                Container(
                  constraints:
                      const BoxConstraints(maxWidth: 560, maxHeight: 680),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _outline, width: 1),
                    boxShadow: const [
                      BoxShadow(
                          color: _ink, offset: Offset(6, 6), blurRadius: 0),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── HEADER ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB7E5CD).withAlpha(80),
                            border: const Border(
                              bottom: BorderSide(color: _outline, width: 1),
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_task_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Tugas' : 'Buat Tugas Baru',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _outline),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: _outline),
                              ),
                            ),
                          ]),
                        ),

                        // ── SCROLLABLE CONTENT ──
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // MODULE 1: Identity
                                _FormModule(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FormLabel('JUDUL TUGAS'),
                                      const SizedBox(height: 8),
                                      _NeoInput(
                                        controller: judulCtrl,
                                        hint: 'Contoh: Analisis Struktur Atom',
                                        icon: Icons.title_rounded,
                                      ),
                                      const SizedBox(height: 16),
                                      const _FormLabel('DESKRIPSI DETAIL'),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: _outline),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: TextField(
                                          controller: deskripsiCtrl,
                                          maxLines: 4,
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Tuliskan instruksi pengerjaan...',
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // MODULE 2: Channel + Deadline (2 kolom)
                                Row(children: [
                                  // Channel
                                  Expanded(
                                      child: _FormModule(
                                    bg: const Color(0xFFE8F6FF),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FormLabel('CHANNEL'),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: _outline),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedChannelId,
                                              isExpanded: true,
                                              style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  color: _ink),
                                              items: [
                                                const DropdownMenuItem(
                                                    value: 'general',
                                                    child: Text(
                                                        'General (Seluruh Kelas)',
                                                        overflow: TextOverflow
                                                            .ellipsis)),
                                                for (var c in _channels)
                                                  DropdownMenuItem(
                                                      value: c['id'].toString(),
                                                      child: Text(
                                                          c['nama_channel'] ??
                                                              '-',
                                                          overflow: TextOverflow
                                                              .ellipsis)),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setDialogState(() =>
                                                      selectedChannelId = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(width: 12),
                                  // Deadline
                                  Expanded(
                                      child: _FormModule(
                                    bg: const Color(0xFFE8F6FF),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FormLabel('DEADLINE'),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                                context: ctx,
                                                initialDate: selectedDeadline ??
                                                    DateTime.now(),
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime(2100));
                                            if (date != null && ctx.mounted) {
                                              final time = await showTimePicker(
                                                  context: ctx,
                                                  initialTime:
                                                      TimeOfDay.fromDateTime(
                                                          selectedDeadline ??
                                                              DateTime.now()));
                                              if (time != null) {
                                                setDialogState(() =>
                                                    selectedDeadline = DateTime(
                                                        date.year,
                                                        date.month,
                                                        date.day,
                                                        time.hour,
                                                        time.minute));
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 13),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border:
                                                  Border.all(color: _outline),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(children: [
                                              const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 15,
                                                  color: _outline),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                deadlineStr,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      selectedDeadline != null
                                                          ? _ink
                                                          : _outline,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ]),

                                const SizedBox(height: 16),

                                // MODULE 3: Lampiran
                                _FormModule(
                                  bg: const Color(0xFFB7EDE7).withAlpha(40),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FormLabel('LAMPIRAN & TAUTAN'),
                                      const SizedBox(height: 12),
                                      // Dashed upload area
                                      GestureDetector(
                                        onTap: isUploading
                                            ? null
                                            : handleUploadFile,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(180),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _outline.withAlpha(100),
                                              width: 2,
                                              strokeAlign:
                                                  BorderSide.strokeAlignInside,
                                            ),
                                          ),
                                          child: Column(children: [
                                            isUploading
                                                ? const SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: _primary,
                                                            strokeWidth: 2))
                                                : const Icon(
                                                    Icons.cloud_upload_outlined,
                                                    size: 32,
                                                    color: _outline),
                                            const SizedBox(height: 8),
                                            Text(
                                              isUploading
                                                  ? 'Mengunggah...'
                                                  : 'Unggah PDF atau Foto',
                                              style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _outline),
                                            ),
                                            const Text('Maksimal 10MB',
                                                style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11,
                                                    color: _outline)),
                                          ]),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Link input
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: _outline),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: TextField(
                                          controller: linkCtrl,
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Tautan Link File (Google Drive/YouTube)',
                                            prefixIcon: Icon(Icons.link_rounded,
                                                size: 18, color: _outline),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 14),
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

                        // ── FOOTER ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: const Border(
                                top: BorderSide(color: _outline, width: 1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Batalkan ghost
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _outline),
                                  ),
                                  child: const Text('BATALKAN',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _ink)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Simpan neo-button
                              GestureDetector(
                                onTap: () async {
                                  final body = {
                                    'judul': judulCtrl.text,
                                    'deskripsi': deskripsiCtrl.text,
                                    'deadline': selectedDeadline
                                            ?.toIso8601String() ??
                                        (isEditing ? tugas['deadline'] : null),
                                    'link': linkCtrl.text,
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
                                            'Authorization':
                                                'Bearer ${widget.token}'
                                          },
                                          body: jsonEncode(body))
                                      : http.post(Uri.parse(url),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'Authorization':
                                                'Bearer ${widget.token}'
                                          },
                                          body: jsonEncode(body)));
                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _fetchTugas();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _ink),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: _ink,
                                          offset: Offset(2, 2),
                                          blurRadius: 0),
                                    ],
                                  ),
                                  child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.publish_rounded,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('SIMPAN & PUBLIKASIKAN',
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white)),
                                      ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();

    final sorted = List<dynamic>.from(_tugasList);
    sorted.sort((a, b) {
      final dA = a['deadline'];
      final dB = b['deadline'];
      if (dA == null && dB == null) return 0;
      if (dA == null) return 1;
      if (dB == null) return -1;
      final dtA = DateTime.tryParse(dA.toString());
      final dtB = DateTime.tryParse(dB.toString());
      if (dtA != null && dtB != null) return dtA.compareTo(dtB);
      return 0;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showTugasForm,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ).animate().fadeIn().slideY(begin: 0.5),
      body: sorted.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchTugas,
              color: _primary,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final crossCount = constraints.maxWidth >= 640 ? 2 : 1;
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      // Section header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                          child: Row(
                            children: [
                              const Text(
                                'Tugas Aktif',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              if (constraints.maxWidth >= 640)
                                _NeoButton(
                                  label: 'BUAT TUGAS BARU',
                                  icon: Icons.add_rounded,
                                  onTap: _showTugasForm,
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Bento grid
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 28,
                            mainAxisExtent: crossCount == 1 ? 220 : 260,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _BentoTugasCard(
                              tugas: sorted[i],
                              onEdit: () => _showTugasForm(sorted[i]),
                              onDelete: () =>
                                  _deleteTugas(sorted[i]['id'].toString()),
                              onDetail: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuruTugasDetailScreen(
                                      tugas: sorted[i], token: widget.token),
                                ),
                              ),
                            )
                                .animate(delay: (i * 50).ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                    begin: 0.08, curve: Curves.easeOutQuart),
                            childCount: sorted.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFB7E5CD),
              border: Border.fromBorderSide(BorderSide(color: _ink, width: 2)),
              boxShadow: [BoxShadow(color: _ink, offset: Offset(4, 4))],
            ),
            child:
                const Icon(Icons.assignment_rounded, size: 52, color: _primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + untuk membuat tugas baru.',
            style:
                TextStyle(fontFamily: 'Inter', fontSize: 14, color: _outline),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: SkeletonLoader(height: 160, radius: 4),
      ),
    );
  }
}

class _FormModule extends StatelessWidget {
  final Widget child;
  final Color? bg;
  const _FormModule({required this.child, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        border: Border.all(color: const Color(0xFF717974), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF717974),
            letterSpacing: 0.8));
  }
}

class _NeoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _NeoInput(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF717974)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF717974)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}

// ── Bento Card ────────────────────────────────────────────────────────────────
class _BentoTugasCard extends StatefulWidget {
  final dynamic tugas;
  final VoidCallback onEdit, onDelete, onDetail;

  const _BentoTugasCard({
    required this.tugas,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  @override
  State<_BentoTugasCard> createState() => _BentoTugasCardState();
}

class _BentoTugasCardState extends State<_BentoTugasCard> {
  bool _pressed = false;

  static const _ink = Color(0xFF001E2B);
  static const _primary = Color(0xFF3D6754);
  static const _outline = Color(0xFF717974);
  static const _tertiary = Color(0xFF8D4D33);
  static const _error = Color(0xFFBA1A1A);

  bool get _isDeadlineSoon {
    final dl = widget.tugas['deadline'];
    if (dl == null) return false;
    final dt = DateTime.tryParse(dl.toString());
    if (dt == null) return false;
    final diff = dt.difference(DateTime.now());
    return diff.inDays <= 3 && diff.inSeconds > 0;
  }

  bool get _isOverdue {
    final dl = widget.tugas['deadline'];
    if (dl == null) return false;
    final dt = DateTime.tryParse(dl.toString());
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  String _formatDeadline(String? dl) {
    if (dl == null || dl.isEmpty) return 'Tanpa Deadline';
    final parsed = DateTime.tryParse(dl);
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return dl;
  }

  @override
  Widget build(BuildContext context) {
    final showBadge = _isOverdue || _isDeadlineSoon;
    final badgeColor = _isOverdue ? _error : _tertiary;
    final badgeLabel = _isOverdue ? 'TERLAMBAT' : 'DEADLINE DEKAT';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onDetail();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: Transform.translate(
            offset: _pressed ? const Offset(2, 2) : const Offset(-2, -2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _outline, width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: _pressed
                    ? []
                    : const [
                        BoxShadow(
                            color: _outline,
                            offset: Offset(6, 6),
                            blurRadius: 0),
                      ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 10, color: _primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.tugas['judul'] ?? '-',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') widget.onEdit();
                                  if (val == 'delete') widget.onDelete();
                                },
                                icon: const Icon(Icons.more_vert_rounded,
                                    color: _outline, size: 18),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_rounded, size: 16),
                                        SizedBox(width: 10),
                                        Text('Edit',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ])),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_rounded,
                                            color: _error, size: 16),
                                        SizedBox(width: 10),
                                        Text('Hapus',
                                            style: TextStyle(
                                                color: _error,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: _InfoTile(
                              icon: Icons.calendar_today_rounded,
                              iconBg: const Color(0xFFB7E5CD),
                              iconColor: _primary,
                              label: 'BATAS WAKTU',
                              value: _formatDeadline(
                                  widget.tugas['deadline']?.toString()),
                            )),
                          ]),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: const BoxDecoration(
                                color: _primary,
                                border: Border.fromBorderSide(
                                    BorderSide(color: _ink, width: 1)),
                                boxShadow: [
                                  BoxShadow(
                                      color: _ink,
                                      offset: Offset(3, 3),
                                      blurRadius: 0)
                                ],
                              ),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Lihat Detail',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white, size: 13),
                                  ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Punch-out badge with fire icon
        if (showBadge)
          Positioned(
            top: -1,
            right: 24,
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  border: Border.all(color: _ink, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Neo Button (desktop header) ───────────────────────────────────────────────
class _NeoButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NeoButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton> {
  bool _pressed = false;
  static const _ink = Color(0xFF001E2B);
  static const _primary = Color(0xFF3D6754);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform:
            _pressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _primary,
          border: Border.all(color: _ink, width: 1),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(color: _ink, offset: Offset(2, 2), blurRadius: 0)
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  static const _outline = Color(0xFF717974);
  static const _ink = Color(0xFF001E2B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outline.withAlpha(80), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _outline,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
