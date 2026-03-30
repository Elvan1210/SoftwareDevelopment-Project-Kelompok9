import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../services/notifikasi_service.dart';
import 'guru/guru_tugas_detail_screen.dart';
import 'siswa/siswa_tugas_detail_screen.dart';

/// Layar detail per-kelas, mirip Microsoft Teams.
/// Menampilkan 4 tab: Tugas | Materi | Nilai | Absensi
/// Digunakan oleh Guru dan Siswa dengan konten yang disesuaikan per role.
class KelasDetailScreen extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final Map<String, dynamic> userData;
  final String token;
  final int initialTab; // 0=Tugas, 1=Materi, 2=Nilai, 3=Absensi

  const KelasDetailScreen({
    super.key,
    required this.kelas,
    required this.userData,
    required this.token,
    this.initialTab = 0,
  });

  @override
  State<KelasDetailScreen> createState() => _KelasDetailScreenState();
}

class _KelasDetailScreenState extends State<KelasDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get isGuru => (widget.userData['role'] ?? '') == 'Guru';
  Color get kelasColor =>
      Color(int.parse(widget.kelas['warna_card'] ?? '4282032886'));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = kelasColor;
    final tahunAjaran = widget.kelas['tahun_ajaran'] as String?;
    final kode = widget.kelas['kode_kelas'] as String? ?? '-';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            // 60px top + nama(22) + 6 + chips(22) + 52 bottom (TabBar ~48px) = 162 → pakai 185
            expandedHeight: 185,
            floating: false,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                // bottom 52 agar konten tidak tertimpa TabBar (~48px)
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.kelas['nama_kelas'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Wrap agar tidak overflow di layar sempit
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if ((widget.kelas['mapel'] ?? '').isNotEmpty)
                          _Chip(widget.kelas['mapel'], Icons.subject_rounded),
                        if (tahunAjaran != null)
                          _Chip(tahunAjaran, Icons.calendar_today_rounded),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: kode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kode kelas disalin!'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: _Chip(kode, Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Tugas'),
                Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Materi'),
                Tab(icon: Icon(Icons.grade_outlined, size: 18), text: 'Nilai'),
                Tab(icon: Icon(Icons.how_to_reg_outlined, size: 18), text: 'Absensi'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TugasTab(
              kelas: widget.kelas,
              userData: widget.userData,
              token: widget.token,
            ),
            _MateriTab(
              kelas: widget.kelas,
              userData: widget.userData,
              token: widget.token,
            ),
            _NilaiTab(
              kelas: widget.kelas,
              userData: widget.userData,
              token: widget.token,
            ),
            _AbsensiTab(
              kelas: widget.kelas,
              userData: widget.userData,
              token: widget.token,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── TAB 1: TUGAS ────────────────────────────────────────────────────────────

class _TugasTab extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final Map<String, dynamic> userData;
  final String token;
  const _TugasTab(
      {required this.kelas, required this.userData, required this.token});

  @override
  State<_TugasTab> createState() => _TugasTabState();
}

class _TugasTabState extends State<_TugasTab> {
  List<dynamic> _tugasList = [];
  bool _isLoading = true;
  bool get isGuru => (widget.userData['role'] ?? '') == 'Guru';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final kode = Uri.encodeComponent(widget.kelas['kode_kelas'] ?? '');
      final resp = await http.get(
        Uri.parse('$baseUrl/api/tugas?kode_kelas=$kode'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        final list = dec is List ? List<dynamic>.from(dec) : <dynamic>[];
        list.sort((a, b) {
          final dA = a['deadline'] as String?;
          final dB = b['deadline'] as String?;
          if (dA == null && dB == null) return 0;
          if (dA == null) return 1;
          if (dB == null) return -1;
          final dtA = DateTime.tryParse(dA);
          final dtB = DateTime.tryParse(dB);
          if (dtA != null && dtB != null) return dtA.compareTo(dtB);
          return dA.compareTo(dB);
        });
        setState(() => _tugasList = list);
      }
    } catch (e) {
      debugPrint('Error fetch tugas kelas: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showCreateForm() {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Buat Tugas', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _field(judulCtrl, 'Judul Tugas', Icons.title_rounded),
                  const SizedBox(height: 12),
                  _field(deskripsiCtrl, 'Deskripsi', Icons.description_outlined,
                      multiline: true),
                  const SizedBox(height: 12),
                  _field(linkCtrl, 'Link Pendukung (opsional)', Icons.link_rounded),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null && ctx.mounted) {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                          builder: (c, child) => MediaQuery(
                            data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          ),
                        );
                        if (t != null) {
                          setDs(() => deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 10),
                          Text(
                            deadline != null
                                ? DateFormat('dd MMM yyyy, HH:mm').format(deadline!)
                                : 'Pilih Deadline',
                            style: TextStyle(
                              color: deadline != null ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              ),
              onPressed: () async {
                if (judulCtrl.text.trim().isEmpty) return;
                final body = {
                  'judul': judulCtrl.text.trim(),
                  'deskripsi': deskripsiCtrl.text.trim(),
                  'link': linkCtrl.text.trim(),
                  'kode_kelas': widget.kelas['kode_kelas'],
                  'guru_id': widget.userData['id'],
                  'deadline': deadline?.toIso8601String(),
                };
                final resp = await http.post(
                  Uri.parse('$baseUrl/api/tugas'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${widget.token}',
                  },
                  body: jsonEncode(body),
                );
                if (resp.statusCode == 201) {
                  NotifikasiService.kirimNotifikasi(
                    judul: 'Tugas Baru',
                    pesan:
                        '${widget.userData['nama']} membuat tugas: ${judulCtrl.text.trim()} di kelas ${widget.kelas['nama_kelas']}',
                    token: widget.token,
                    targetKelas: widget.kelas['kode_kelas'],
                    targetRole: 'Siswa',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetch();
                }
              },
              child: const Text('Terbitkan', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
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
      floatingActionButton: isGuru
          ? FloatingActionButton.extended(
              onPressed: _showCreateForm,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Buat Tugas', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: _tugasList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada tugas untuk kelas ini.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _tugasList.length,
                itemBuilder: (_, i) {
                  final t = _tugasList[i];
                  final dl = t['deadline'] != null
                      ? DateTime.tryParse(t['deadline'])
                      : null;
                  final isPast = dl != null && dl.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6).withAlpha(20),
                        child: const Icon(Icons.assignment_outlined,
                            color: Color(0xFF3B82F6), size: 20),
                      ),
                      title: Text(t['judul'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: dl != null
                          ? Text(
                              'Deadline: ${DateFormat('dd MMM yyyy, HH:mm').format(dl)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isPast ? Colors.red : Colors.grey.shade600),
                            )
                          : const Text('Tanpa deadline',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isGuru
                              ? GuruTugasDetailScreen(
                                  tugas: t, token: widget.token)
                              : SiswaTugasDetailScreen(
                                  tugas: t,
                                  userData: widget.userData,
                                  token: widget.token),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── TAB 2: MATERI ───────────────────────────────────────────────────────────

class _MateriTab extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final Map<String, dynamic> userData;
  final String token;
  const _MateriTab(
      {required this.kelas, required this.userData, required this.token});

  @override
  State<_MateriTab> createState() => _MateriTabState();
}

class _MateriTabState extends State<_MateriTab> {
  List<dynamic> _materiList = [];
  bool _isLoading = true;
  bool get isGuru => (widget.userData['role'] ?? '') == 'Guru';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final kode = Uri.encodeComponent(widget.kelas['kode_kelas'] ?? '');
      final resp = await http.get(
        Uri.parse('$baseUrl/api/materi?kode_kelas=$kode'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        final list = dec is List ? List<dynamic>.from(dec) : <dynamic>[];
        list.sort((a, b) {
          final tA = a['tanggal'] as String?;
          final tB = b['tanggal'] as String?;
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA); // descending: newest first
        });
        setState(() => _materiList = list);
      }
    } catch (e) {
      debugPrint('Error fetch materi kelas: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showCreateForm() {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Upload Materi', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _field(judulCtrl, 'Judul Materi', Icons.title_rounded),
              const SizedBox(height: 12),
              _field(deskripsiCtrl, 'Deskripsi', Icons.description_outlined, multiline: true),
              const SizedBox(height: 12),
              _field(linkCtrl, 'Link Materi / Drive / YouTube', Icons.link_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (judulCtrl.text.trim().isEmpty) return;
              final body = {
                'judul': judulCtrl.text.trim(),
                'deskripsi': deskripsiCtrl.text.trim(),
                'link': linkCtrl.text.trim(),
                'kode_kelas': widget.kelas['kode_kelas'],
                'guru_id': widget.userData['id'],
                'tanggal': DateTime.now().toIso8601String(),
              };
              final resp = await http.post(
                Uri.parse('$baseUrl/api/materi'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.token}',
                },
                body: jsonEncode(body),
              );
              if (resp.statusCode == 201) {
                if (ctx.mounted) Navigator.pop(ctx);
                _fetch();
              }
            },
            child: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isGuru
          ? FloatingActionButton.extended(
              onPressed: _showCreateForm,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Materi', style: TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: const Color(0xFF10B981),
            )
          : null,
      body: _materiList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada materi untuk kelas ini.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _materiList.length,
                itemBuilder: (_, i) {
                  final m = _materiList[i];
                  final hasLink = (m['link'] ?? '').toString().isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF10B981).withAlpha(20),
                        child: const Icon(Icons.menu_book_outlined,
                            color: Color(0xFF10B981), size: 20),
                      ),
                      title: Text(m['judul'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((m['deskripsi'] ?? '').isNotEmpty)
                            Text(m['deskripsi'],
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          if (hasLink)
                            Text(m['link'],
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: hasLink
                          ? const Icon(Icons.open_in_new_rounded,
                              size: 18, color: Colors.blue)
                          : null,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── TAB 3: NILAI ────────────────────────────────────────────────────────────

class _NilaiTab extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final Map<String, dynamic> userData;
  final String token;
  const _NilaiTab(
      {required this.kelas, required this.userData, required this.token});

  @override
  State<_NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<_NilaiTab> {
  List<dynamic> _tugasList = [];
  List<dynamic> _pengumpulanList = []; // hanya untuk siswa
  bool _isLoading = true;
  bool get isGuru => (widget.userData['role'] ?? '') == 'Guru';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final kode = Uri.encodeComponent(widget.kelas['kode_kelas'] ?? '');

      if (isGuru) {
        // Guru: tampilkan semua tugas → klik → buka GuruTugasDetailScreen untuk menilai
        final resp = await http.get(
          Uri.parse('$baseUrl/api/tugas?kode_kelas=$kode'),
          headers: headers,
        );
        if (resp.statusCode == 200) {
          final dec = jsonDecode(resp.body);
          setState(() => _tugasList = dec is List ? dec : []);
        }
      } else {
        // Siswa: ambil tugas kelas + pengumpulan sendiri, tampilkan yang sudah dinilai
        final sid = Uri.encodeComponent(widget.userData['id'].toString());
        final results = await Future.wait([
          http.get(Uri.parse('$baseUrl/api/tugas?kode_kelas=$kode'), headers: headers),
          http.get(Uri.parse('$baseUrl/api/pengumpulan?siswa_id=$sid'), headers: headers),
        ]);

        List tugasList = [];
        List pengumpulanList = [];

        if (results[0].statusCode == 200) {
          final dec = jsonDecode(results[0].body);
          tugasList = dec is List ? dec : [];
        }
        if (results[1].statusCode == 200) {
          final dec = jsonDecode(results[1].body);
          pengumpulanList = dec is List ? dec : [];
        }

        // Cross-filter: hanya pengumpulan yang tugasnya milik kelas ini & sudah dinilai
        final tugasIds = tugasList.map((t) => t['id']).toSet();
        final graded = pengumpulanList
            .where((p) => tugasIds.contains(p['tugas_id']) && p['nilai'] != null)
            .toList();

        // Tambahkan judul tugas ke tiap pengumpulan untuk display
        final tugasMap = {for (var t in tugasList) t['id']: t};
        for (var p in graded) {
          p['_tugas_judul'] = tugasMap[p['tugas_id']]?['judul'] ?? '-';
        }

        setState(() {
          _tugasList = tugasList;
          _pengumpulanList = graded;
        });
      }
    } catch (e) {
      debugPrint('Error fetch nilai kelas: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (isGuru) {
      return _buildGuruNilaiView();
    } else {
      return _buildSiswaNilaiView();
    }
  }

  // Guru: list tugas → klik untuk grade di GuruTugasDetailScreen
  Widget _buildGuruNilaiView() {
    if (_tugasList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada tugas untuk dinilai.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tugasList.length,
        itemBuilder: (_, i) {
          final t = _tugasList[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grade_outlined,
                    color: Color(0xFF8B5CF6), size: 20),
              ),
              title: Text(t['judul'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: const Text('Ketuk untuk lihat dan nilai pengumpulan',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Grade',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w800)),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GuruTugasDetailScreen(tugas: t, token: widget.token),
                ),
              ).then((_) => _fetch()),
            ),
          );
        },
      ),
    );
  }

  // Siswa: list pengumpulan yang sudah dinilai (nilai + feedback)
  Widget _buildSiswaNilaiView() {
    if (_pengumpulanList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada nilai yang masuk.',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            SizedBox(height: 4),
            Text('Nilai akan muncul setelah guru menilai tugasmu.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pengumpulanList.length,
        itemBuilder: (_, i) {
          final p = _pengumpulanList[i];
          final nilaiVal = (p['nilai'] as num?)?.toDouble() ?? 0;
          final color = nilaiVal >= 80
              ? const Color(0xFF10B981)
              : (nilaiVal >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
          final predikat = nilaiVal >= 80
              ? 'A'
              : (nilaiVal >= 70
                  ? 'B'
                  : (nilaiVal >= 60 ? 'C' : (nilaiVal >= 50 ? 'D' : 'E')));

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withAlpha(60)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Nilai circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withAlpha(80), width: 2),
                    ),
                    child: Center(
                      child: Text(predikat,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: color)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['_tugas_judul'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Nilai: ${nilaiVal.toStringAsFixed(0)} / 100',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color)),
                        if ((p['feedback'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('"${p['feedback']}"',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
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
}

// ─── TAB 4: ABSENSI ──────────────────────────────────────────────────────────

class _AbsensiTab extends StatefulWidget {
  final Map<String, dynamic> kelas;
  final Map<String, dynamic> userData;
  final String token;
  const _AbsensiTab(
      {required this.kelas, required this.userData, required this.token});

  @override
  State<_AbsensiTab> createState() => _AbsensiTabState();
}

class _AbsensiTabState extends State<_AbsensiTab> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool get isGuru => (widget.userData['role'] ?? '') == 'Guru';

  // Guru state
  DateTime _selectedDate = DateTime.now();
  List<String> _siswaIds = [];
  List<String> _siswaNamaList = [];
  Map<String, String> _records = {}; // siswa_id → status
  static const _statuses = ['hadir', 'izin', 'sakit', 'alpha'];

  // Siswa state
  List<dynamic> _riwayatList = [];

  String get _tanggalStr =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    if (isGuru) {
      _loadSiswaAndSession();
    } else {
      _loadSiswaRiwayat();
    }
  }

  // ── GURU ─────────────────────────────────────────────────────────────────

  Future<void> _loadSiswaAndSession() async {
    setState(() => _isLoading = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final kode = widget.kelas['kode_kelas'] as String? ?? '';

      // Fetch kelas doc to get siswa_ids
      final kelasSnap = await http.get(
        Uri.parse('$baseUrl/api/kelas/${widget.kelas['id']}'),
        headers: headers,
      );

      if (kelasSnap.statusCode == 200) {
        final k = jsonDecode(kelasSnap.body) as Map<String, dynamic>;
        final ids = List<String>.from(
            (k['siswa_ids'] as List? ?? []).map((e) => e.toString()));
        setState(() => _siswaIds = ids);

        // Fetch each siswa name
        final names = <String>[];
        for (final id in ids) {
          final r = await http.get(
            Uri.parse('$baseUrl/api/users/$id'),
            headers: headers,
          );
          if (r.statusCode == 200) {
            final u = jsonDecode(r.body);
            names.add(u['nama']?.toString() ?? id);
          } else {
            names.add(id);
          }
        }
        setState(() => _siswaNamaList = names);
      }

      // Load existing session for selected date
      await _loadSession(kode);
    } catch (e) {
      debugPrint('Error load siswa absensi: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSession(String kode) async {
    try {
      final resp = await http.get(
        Uri.parse(
            '$baseUrl/api/absensi?kode_kelas=${Uri.encodeComponent(kode)}&tanggal=$_tanggalStr'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200 && resp.body != 'null') {
        final data = jsonDecode(resp.body);
        if (data != null && data['records'] != null) {
          setState(() {
            _records = Map<String, String>.from(
                (data['records'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
          });
          return;
        }
      }
      // No existing session — default all to 'hadir'
      setState(() {
        _records = {for (final id in _siswaIds) id: 'hadir'};
      });
    } catch (e) {
      debugPrint('Error load session: $e');
    }
  }

  void _cycleStatus(String siswaId) {
    final current = _records[siswaId] ?? 'hadir';
    final idx = _statuses.indexOf(current);
    final next = _statuses[(idx + 1) % _statuses.length];
    setState(() => _records[siswaId] = next);
  }

  Future<void> _simpanAbsensi() async {
    setState(() => _isSaving = true);
    try {
      final body = {
        'kode_kelas': widget.kelas['kode_kelas'],
        'tanggal': _tanggalStr,
        'guru_id': widget.userData['id'],
        'records': _records,
      };
      final resp = await http.post(
        Uri.parse('$baseUrl/api/absensi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Absensi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal simpan: ${resp.statusCode}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  // ── SISWA ─────────────────────────────────────────────────────────────────

  Future<void> _loadSiswaRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final kode = Uri.encodeComponent(widget.kelas['kode_kelas'] ?? '');
      final resp = await http.get(
        Uri.parse('$baseUrl/api/absensi?kode_kelas=$kode'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        setState(() => _riwayatList = dec is List ? dec : []);
      }
    } catch (e) {
      debugPrint('Error load riwayat absensi: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return isGuru ? _buildGuruView() : _buildSiswaView();
  }

  Widget _buildGuruView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Date picker row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() {
                    _selectedDate = d;
                    _records = {for (final id in _siswaIds) id: 'hadir'};
                  });
                  await _loadSession(widget.kelas['kode_kelas'] ?? '');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          if (_siswaIds.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada siswa di kelas ini.',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                itemCount: _siswaIds.length,
                itemBuilder: (_, i) {
                  final id = _siswaIds[i];
                  final nama = i < _siswaNamaList.length ? _siswaNamaList[i] : id;
                  final status = _records[id] ?? 'hadir';
                  return _buildStatusTile(id, nama, status, i);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _siswaIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _simpanAbsensi,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Absensi',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              backgroundColor: Colors.deepPurple.shade700,
            ),
    );
  }

  Widget _buildStatusTile(String id, String nama, String status, int index) {
    final colorMap = {
      'hadir': Colors.green,
      'izin': Colors.orange,
      'sakit': Colors.blue,
      'alpha': Colors.red,
    };
    final color = colorMap[status] ?? Colors.grey;
    final initials = nama.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withAlpha(60)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Text(initials, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
        ),
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text('No. ${index + 1}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        trailing: GestureDetector(
          onTap: () => _cycleStatus(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiswaView() {
    final siswaId = widget.userData['id'].toString();

    if (_riwayatList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada data absensi.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSiswaRiwayat,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _riwayatList.length,
        itemBuilder: (_, i) {
          final session = _riwayatList[i];
          final records = session['records'] as Map? ?? {};
          final status = records[siswaId]?.toString() ?? '-';
          final colorMap = {
            'hadir': Colors.green,
            'izin': Colors.orange,
            'sakit': Colors.blue,
            'alpha': Colors.red,
          };
          final color = colorMap[status] ?? Colors.grey;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: color.withAlpha(20),
                child: Icon(Icons.calendar_today_rounded, color: color, size: 18),
              ),
              title: Text(session['tanggal'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(
                  status == '-' ? 'Tidak Ada Data' : status.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _field(TextEditingController ctrl, String label, IconData icon,
    {bool multiline = false}) {
  return TextField(
    controller: ctrl,
    maxLines: multiline ? 3 : 1,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
    ),
  );
}
