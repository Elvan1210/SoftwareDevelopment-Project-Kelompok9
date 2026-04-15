import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/confirm_delete.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminTugasView extends StatefulWidget {
  final String token;
  const AdminTugasView({super.key, required this.token});

  @override
  State<AdminTugasView> createState() => _AdminTugasViewState();
}

class _AdminTugasViewState extends State<AdminTugasView> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTugas();
  }

  Future<void> _fetchTugas() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/tugas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final dec = jsonDecode(res.body);
        setState(() => _tugasList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteTugas(String id) async {
    if (await confirmDelete(context, pesan: 'Hapus tugas ini secara permanen?')) {
      try {
        await http.delete(Uri.parse('$baseUrl/api/tugas/$id'), headers: {'Authorization': 'Bearer ${widget.token}'});
        _fetchTugas();
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  List<dynamic> get _filtered => _searchQuery.isEmpty
      ? _tugasList
      : _tugasList.where((t) =>
          (t['judul'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t['guru_nama'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t['mapel'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: AppTextField(
                hintText: 'Cari tugas, guru, atau mapel...',
                prefixIcon: LucideIcons.search,
                onChanged: (val) => setState(() => _searchQuery = val),
              ).animate().fadeIn().slideY(begin: -0.1),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? EmptyState(icon: LucideIcons.clipboardList, message: 'Tidak ada tugas ditemukan.', color: Theme.of(context).primaryColor)
                  : RefreshIndicator(
                      onRefresh: _fetchTugas,
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
                              childAspectRatio: crossCount == 1 ? 2.0 : 1.3,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final t = _filtered[i];
                              return _AdminTugasCard(
                                tugas: t,
                                onDelete: () => _deleteTugas(t['id'].toString()),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(24), child: SkeletonLoader(height: 56, radius: 16)),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(6, (_) => const SkeletonLoader(radius: 24)),
          ),
        ),
      ],
    );
  }
}

class _AdminTugasCard extends StatelessWidget {
  final dynamic tugas;
  final VoidCallback onDelete;
  const _AdminTugasCard({required this.tugas, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return PremiumCard(
      accentColor: accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accent.withAlpha(20), shape: BoxShape.circle), child: Icon(LucideIcons.clipboardList, color: accent, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(tugas['mapel'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: onDelete, icon: const Icon(LucideIcons.trash, color: Colors.red, size: 20)),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(tugas['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Guru: ${tugas['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(150)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Deadline: ${tugas['deadline'] ?? '-'}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(120)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.onSurface.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.library, size: 12, color: theme.colorScheme.onSurface.withAlpha(150)),
                const SizedBox(width: 6),
                Text('Kelas: ${tugas['kelas'] ?? '-'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withAlpha(180))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

