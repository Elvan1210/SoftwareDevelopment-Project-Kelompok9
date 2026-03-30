import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';
import '../../dashboard/kelas_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Layar "Kelas Saya" untuk Siswa: menampilkan daftar kelas yang diikuti.
/// Klik kelas → buka KelasDetailScreen di tab Nilai (index 2) untuk lihat nilai,
/// atau tab Tugas (index 0) untuk mengerjakan tugas.
class SiswaNilaiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const SiswaNilaiView({super.key, required this.userData, required this.token});

  @override
  State<SiswaNilaiView> createState() => _SiswaNilaiViewState();
}

class _SiswaNilaiViewState extends State<SiswaNilaiView> {
  List<dynamic> _kelasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    setState(() => _isLoading = true);
    try {
      final sid = Uri.encodeComponent(widget.userData['id'].toString());
      final resp = await http.get(
        Uri.parse('$baseUrl/api/kelas?siswa_id=$sid'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        setState(() => _kelasList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error fetch kelas siswa: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: List.generate(4, (_) => const SkeletonLoader(radius: 20)),
        ),
      );
    }

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _kelasList.isEmpty
            ? const EmptyState(
                icon: Icons.school_outlined,
                message: 'Kamu belum terdaftar di kelas manapun.\nHubungi Admin untuk bergabung.',
                color: Color(0xFF3B82F6),
              )
            : RefreshIndicator(
                onRefresh: _fetchKelas,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final padding = Breakpoints.screenPadding(w);
                    final crossCount = w >= Breakpoints.desktop
                        ? 4
                        : (w >= Breakpoints.tablet ? 3 : (w >= Breakpoints.mobile ? 2 : 1));

                    return GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: _kelasList.length,
                      itemBuilder: (context, i) {
                        final k = _kelasList[i];
                        return _SiswaKelasCard(
                          kelas: k,
                          userData: widget.userData,
                          token: widget.token,
                        ).animate(delay: (i * 50).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _SiswaKelasCard extends StatelessWidget {
  final dynamic kelas;
  final Map<String, dynamic> userData;
  final String token;
  const _SiswaKelasCard({required this.kelas, required this.userData, required this.token});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(kelas['warna_card'] ?? '4282032886'));

    String initials = '??';
    final nama = (kelas['nama_kelas'] as String? ?? '').trim();
    if (nama.isNotEmpty) {
      final parts = nama.split(' ');
      initials = parts.length >= 2
          ? (parts[0][0] + parts[1][0]).toUpperCase()
          : nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
    }

    return PremiumCard(
      accentColor: color,
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KelasDetailScreen(
            kelas: kelas,
            userData: userData,
            token: token,
            initialTab: 0, // mulai dari tab Tugas
          ),
        ),
      ),
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          kelas['nama_kelas'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if ((kelas['mapel'] ?? '').toString().isNotEmpty)
                          Text(
                            kelas['mapel'],
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(130)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if ((kelas['tahun_ajaran'] ?? '').toString().isNotEmpty)
                          Text(
                            kelas['tahun_ajaran'],
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withAlpha(100)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(50))),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, size: 14, color: color),
                const SizedBox(width: 6),
                Text('Tugas & Materi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                const Spacer(),
                Icon(Icons.grade_outlined, size: 14, color: color.withAlpha(180)),
                const SizedBox(width: 4),
                Text('Nilai',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withAlpha(180))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
