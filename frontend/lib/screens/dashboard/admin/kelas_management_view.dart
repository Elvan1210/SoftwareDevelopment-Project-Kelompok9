import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import '../../../config/api_config.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/neo_brutalism.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class KelasManagementView extends StatefulWidget {
  final String token;
  const KelasManagementView({super.key, required this.token});

  @override
  State<KelasManagementView> createState() => _KelasManagementViewState();
}

class _KelasManagementViewState extends State<KelasManagementView> {
  List<dynamic> _kelasList = [];
  bool _isLoading = true;

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
    if (await confirmDelete(context,
        pesan: 'Yakin ingin menghapus kelas ini?')) {
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

    String generateRandomCode(int length) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = math.Random();
      return String.fromCharCodes(Iterable.generate(
          length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    }

    final namaCtrl =
        TextEditingController(text: isEditing ? kelas['nama_kelas'] : '');
    final kodeCtrl = TextEditingController(
        text: isEditing ? (kelas['kode_kelas'] ?? '') : generateRandomCode(6));
    final mapelCtrl =
        TextEditingController(text: isEditing ? (kelas['mapel'] ?? '') : '');
    final tahunAjaranCtrl = TextEditingController(
        text: isEditing ? (kelas['tahun_ajaran'] ?? '') : '');

    final List<Color> cardColors = [
      AppTheme.indigoPrimary,
      AppTheme.success,
      AppTheme.amber,
      AppTheme.rose,
    ];
    Color selectedColor = isEditing && kelas['warna_card'] != null
        ? Color(int.parse(kelas['warna_card']))
        : cardColors[(_kelasList.length) % cardColors.length];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.indigoPrimary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.library,
                              color: AppTheme.indigoPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEditing ? 'Edit Kelas Virtual' : 'Buat Kelas Baru',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoPrimary.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.indigoPrimary.withAlpha(30),
                            width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.info,
                              color: AppTheme.indigoPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kode Akses untuk bergabung (join code) akan digenerate secara otomatis setelah tim ini disimpan.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: isDark
                                          ? Colors.white.withAlpha(220)
                                          : AppTheme.textLight,
                                      fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: IgnorePointer(
                            child: AppTextField(
                              controller: kodeCtrl,
                              labelText: 'Kode Kelas (Auto-Generated)',
                              prefixIcon: LucideIcons.qrCode,
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.2),
                            ),
                            child: Icon(LucideIcons.refreshCw,
                                color:
                                    isDark ? Colors.white : AppTheme.textLight,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: namaCtrl,
                        labelText: 'Nama Kelas (cth: Sistem Operasi (A))',
                        prefixIcon: LucideIcons.library),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: mapelCtrl,
                        labelText: 'Mata Pelajaran',
                        prefixIcon: LucideIcons.bookOpen),
                    const SizedBox(height: 16),
                    AppTextField(
                        controller: tahunAjaranCtrl,
                        labelText: 'Tahun Ajaran (cth: 2024/2025 Ganjil)',
                        prefixIcon: LucideIcons.calendar),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Batal',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.textMutedDk
                                      : AppTheme.textMutedLt)),
                        ),
                        const SizedBox(width: 12),
                        PremiumElevatedButton(
                          color: AppTheme.indigoPrimary,
                          textColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          radius: 12,
                          onPressed: () async {
                            if (namaCtrl.text.isEmpty) return;

                            final Map<String, dynamic> body = {
                              'nama_kelas': namaCtrl.text,
                              'kode_kelas': kodeCtrl.text,
                              'mapel': mapelCtrl.text,
                              'tahun_ajaran': tahunAjaranCtrl.text,
                              'warna_card': selectedColor.toARGB32().toString(),
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
                                    Uri.parse(
                                        '$baseUrl/api/kelas/${kelas['id']}'),
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
                          child: Text('Simpan & Aktifkan',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
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

    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: AppFAB(
        onPressed: () => _showKelasForm(),
        icon: LucideIcons.plus,
        label: 'Buat Kelas',
      ),
      body: _kelasList.isEmpty
          ? const EmptyState(
              icon: LucideIcons.layoutGrid,
              message: 'Belum ada tim/kelas virtual.',
              color: AppTheme.indigoPrimary)
          : RepaintBoundary(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchKelas();
                  setState(() {});
                },
                color: AppTheme.indigoPrimary,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.desktop
                        ? 4
                        : (w >= Breakpoints.tablet
                            ? 3
                            : (w >= Breakpoints.mobile ? 2 : 1));

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SliverPadding(
                          padding: padding,
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.45,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final k = _kelasList[index];
                                return _TeamsClassCard(
                                  kelas: k,
                                  onEdit: () => _showKelasForm(k),
                                  onDelete: () =>
                                      _deleteKelas(k['id'].toString()),
                                  isDark: isDark,
                                )
                                    .animate(delay: (index * 40).ms)
                                    .fadeIn(duration: 400.ms)
                                    .slideY(
                                        begin: 0.1, curve: Curves.easeOutQuart);
                              },
                              childCount: _kelasList.length,
                            ),
                          ),
                        ),
                      ],
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
      children: List.generate(6, (_) => const SkeletonLoader(radius: 20)),
    );
  }
}

class _TeamsClassCard extends StatelessWidget {
  final dynamic kelas;
  final VoidCallback onEdit, onDelete;
  final bool isDark;

  const _TeamsClassCard(
      {required this.kelas,
      required this.onEdit,
      required this.onDelete,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(kelas['warna_card'] ?? '0xFF4F46E5'));

    String initials = "??";
    final nama = (kelas['nama_kelas'] as String? ?? "").trim();
    if (nama.isNotEmpty) {
      final parts = nama.split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials =
            parts[0].substring(0, parts.length > 1 ? 2 : 1).toUpperCase();
      }
    }

    if (initials == "??" && nama.isNotEmpty) {
      initials = nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
    }

    return NeoCard(
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      borderColor: Theme.of(context).dividerColor,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                      boxShadow: [BoxShadow(color: Theme.of(context).dividerColor, offset: const Offset(3, 3))],
                    ),
                    child: Center(
                      child: Text(initials,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                    ),
                  ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${kelas['kode_kelas'] ?? ''} - ${kelas['nama_kelas'] ?? '-'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.indigoPrimary.withAlpha(20),
                                  border: Border.all(
                                      color:
                                          AppTheme.indigoPrimary.withAlpha(40)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.key,
                                        size: 12,
                                        color: AppTheme.indigoPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      kelas['kode_kelas'] ?? 'Generating...',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                              color: AppTheme.indigoPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (kelas['kode_kelas'] != null)
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: kelas['kode_kelas']));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Kode akses "${kelas['kode_kelas']}" berhasil disalin!',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w800)),
                                        backgroundColor: AppTheme.indigoPrimary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      LucideIcons.copy,
                                      size: 13,
                                      color:
                                          AppTheme.indigoPrimary.withAlpha(180),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.clock,
                                  size: 11,
                                  color: isDark
                                      ? AppTheme.textMutedDk
                                      : AppTheme.textMutedLt),
                              const SizedBox(width: 5),
                              Text(
                                'TA: ${kelas['tahun_ajaran'] ?? '-'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.textMutedDk
                                            : AppTheme.textMutedLt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Guru: ${kelas['guru_nama'] ?? 'Belum ada'}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.textMutedDk
                                        : AppTheme.textMutedLt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(LucideIcons.moreHorizontal,
                          size: 20,
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt),
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            onTap: onEdit,
                            child: Row(children: [
                              const Icon(LucideIcons.edit2, size: 16),
                              const SizedBox(width: 12),
                              Text('Edit Kelas',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold))
                            ])),
                        PopupMenuItem(
                            onTap: onDelete,
                            child: Row(children: [
                              const Icon(LucideIcons.trash,
                                  color: AppTheme.rose, size: 16),
                              const SizedBox(width: 12),
                              Text('Hapus',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.rose,
                                      fontWeight: FontWeight.bold))
                            ])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context).dividerColor, width: 1.2)),
              ),
              child: Row(
                children: [
                  _buildMiniIcon(LucideIcons.clipboardList, isDark),
                  const SizedBox(width: 16),
                  _buildMiniIcon(LucideIcons.briefcase, isDark),
                  const SizedBox(width: 16),
                  _buildMiniIcon(LucideIcons.userCheck, isDark),
                  const Spacer(),
                  Text('${(kelas['siswa_ids'] as List?)?.length ?? 0} Siswa',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.textMutedDk
                              : AppTheme.textMutedLt)),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMiniIcon(IconData icon, bool isDark) {
    return Icon(icon,
        size: 14, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt);
  }
}
