import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../widgets/app_shell.dart';

class GuruPresensiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruPresensiView({super.key, required this.userData, required this.token});

  @override
  State<GuruPresensiView> createState() => _GuruPresensiViewState();
}

class _GuruPresensiViewState extends State<GuruPresensiView> {
  // Kelas
  List<dynamic> _kelasList = [];
  Map<String, dynamic>? _selectedKelas;
  bool _loadingKelas = true;

  // Session
  DateTime _selectedDate = DateTime.now();
  List<String> _siswaIds = [];
  List<String> _siswaNamaList = [];
  Map<String, String> _records = {};
  bool _loadingSession = false;
  bool _isSaving = false;

  static const _statuses = ['hadir', 'izin', 'sakit', 'alpha'];

  String get _tanggalStr =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    setState(() => _loadingKelas = true);
    try {
      final gid = Uri.encodeComponent(widget.userData['id'].toString());
      final resp = await http.get(
        Uri.parse('$baseUrl/api/kelas?guru_id=$gid'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final dec = jsonDecode(resp.body);
        final list = dec is List ? dec : [];
        setState(() {
          _kelasList = list;
          if (list.isNotEmpty) {
            _selectedKelas = list[0] as Map<String, dynamic>;
            _loadSiswaAndSession();
          }
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetch kelas: $e');
    }
    if (mounted) setState(() => _loadingKelas = false);
  }

  Future<void> _loadSiswaAndSession() async {
    if (_selectedKelas == null) return;
    setState(() => _loadingSession = true);
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final kelasId = _selectedKelas!['id']?.toString() ?? '';
      final kode = _selectedKelas!['kode_kelas']?.toString() ?? '';

      // Fetch kelas doc for siswa_ids
      final kelasResp = await http.get(
        Uri.parse('$baseUrl/api/kelas/$kelasId'),
        headers: headers,
      );

      List<String> ids = [];
      if (kelasResp.statusCode == 200) {
        final k = jsonDecode(kelasResp.body) as Map<String, dynamic>;
        ids = List<String>.from(
            (k['siswa_ids'] as List? ?? []).map((e) => e.toString()));
      }
      setState(() => _siswaIds = ids);

      // Fetch siswa names
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

      // Load existing session
      final sessResp = await http.get(
        Uri.parse(
            '$baseUrl/api/absensi?kode_kelas=${Uri.encodeComponent(kode)}&tanggal=$_tanggalStr'),
        headers: headers,
      );

      if (sessResp.statusCode == 200 && sessResp.body != 'null') {
        final data = jsonDecode(sessResp.body);
        if (data != null && data['records'] != null) {
          setState(() {
            _records = Map<String, String>.from(
                (data['records'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
          });
        } else {
          setState(() => _records = {for (final id in ids) id: 'hadir'});
        }
      } else {
        setState(() => _records = {for (final id in ids) id: 'hadir'});
      }
    } catch (e) {
      debugPrint('Error load session: $e');
    }
    if (mounted) {
      setState(() {
        _loadingKelas = false;
        _loadingSession = false;
      });
    }
  }

  void _cycleStatus(String siswaId) {
    final current = _records[siswaId] ?? 'hadir';
    final idx = _statuses.indexOf(current);
    final next = _statuses[(idx + 1) % _statuses.length];
    setState(() => _records[siswaId] = next);
  }

  Future<void> _simpanAbsensi() async {
    if (_selectedKelas == null) return;
    setState(() => _isSaving = true);
    try {
      final body = {
        'kode_kelas': _selectedKelas!['kode_kelas'],
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp.statusCode == 200
              ? 'Absensi berhasil disimpan!'
              : 'Gagal menyimpan: ${resp.statusCode}'),
          backgroundColor: resp.statusCode == 200 ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return Colors.green;
      case 'izin':  return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpha': return Colors.red;
      default:      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: (!_loadingSession && _siswaIds.isNotEmpty)
            ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _simpanAbsensi,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Absensi',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                backgroundColor: const Color(0xFF10B981),
              )
            : null,
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final padding = Breakpoints.screenPadding(w);

            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Presensi Digital',
                    subtitle: 'Rekap kehadiran siswa per sesi',
                  ),
                  const SizedBox(height: 24),

                  // ── Kelas selector ─────────────────────────────────────
                  if (_loadingKelas)
                    const SkeletonLoader(height: 56, radius: 12)
                  else if (_kelasList.isEmpty)
                    const EmptyState(
                      icon: Icons.class_outlined,
                      message: 'Kamu belum ditugaskan ke kelas manapun.',
                      color: Color(0xFF10B981),
                    )
                  else ...[
                    _buildKelasDropdown(),
                    const SizedBox(height: 16),

                    // ── Date picker ──────────────────────────────────────
                    InkWell(
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
                          await _loadSiswaAndSession();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Summary chips ────────────────────────────────────
                    if (!_loadingSession)
                      _buildSummaryRow(),
                    const SizedBox(height: 16),

                    // ── Student list ─────────────────────────────────────
                    if (_loadingSession)
                      ...List.generate(5, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SkeletonLoader(height: 72, radius: 14),
                      ))
                    else if (_siswaIds.isEmpty)
                      const EmptyState(
                        icon: Icons.group_outlined,
                        message: 'Belum ada siswa di kelas ini.',
                        color: Colors.blueGrey,
                      )
                    else
                      ...List.generate(_siswaIds.length, (i) {
                        final id = _siswaIds[i];
                        final nama = i < _siswaNamaList.length ? _siswaNamaList[i] : id;
                        final status = _records[id] ?? 'hadir';
                        final color = _statusColor(status);
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
                              child: Text(initials,
                                  style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
                            ),
                            title: Text(nama,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text('No. ${i + 1}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                                  style: TextStyle(
                                      color: color, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: (i * 30).ms).fadeIn(duration: 300.ms).slideX(begin: -0.03);
                      }),
                    const SizedBox(height: 100), // FAB padding
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKelasDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedKelas,
      decoration: InputDecoration(
        labelText: 'Pilih Kelas',
        prefixIcon: const Icon(Icons.school_outlined, size: 20),
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
      items: _kelasList.map((k) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: k as Map<String, dynamic>,
          child: Text(
            '${k['nama_kelas'] ?? '-'}  •  ${k['kode_kelas'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          _selectedKelas = val;
          _siswaIds = [];
          _siswaNamaList = [];
          _records = {};
        });
        _loadSiswaAndSession();
      },
    );
  }

  Widget _buildSummaryRow() {
    int hadir = _records.values.where((s) => s == 'hadir').length;
    int izin  = _records.values.where((s) => s == 'izin').length;
    int sakit = _records.values.where((s) => s == 'sakit').length;
    int alpha = _records.values.where((s) => s == 'alpha').length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip('Hadir', hadir, Colors.green),
        _SummaryChip('Izin', izin, Colors.orange),
        _SummaryChip('Sakit', sakit, Colors.blue),
        _SummaryChip('Alpha', alpha, Colors.red),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(100)),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
