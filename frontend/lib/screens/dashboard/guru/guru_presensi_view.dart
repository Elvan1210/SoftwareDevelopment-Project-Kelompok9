import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../widgets/app_shell.dart';
import '../../../services/presensi_service.dart';

class GuruPresensiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final dynamic teamData;

  const GuruPresensiView({
    super.key, 
    required this.userData, 
    required this.token,
    this.teamData,
  });

  @override
  State<GuruPresensiView> createState() => _GuruPresensiViewState();
}

class _GuruPresensiViewState extends State<GuruPresensiView> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _attendanceRecords = {}; // studentId -> record
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final kelasId = widget.teamData != null ? widget.teamData['id'] : (widget.userData['kelas_id'] ?? '-');
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final students = await PresensiService.getStudentsByKelas(widget.token, kelasId);
      final records = await PresensiService.getPresensiByDate(widget.token, kelasId, dateStr);
      
      final Map<String, dynamic> recordMap = {for (var r in records) r['user_id'].toString(): r};

      setState(() {
        _students = students;
        _attendanceRecords = recordMap;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Memuat: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  void _updateStatus(String studentId, String status) async {
    final existing = _attendanceRecords[studentId];
    final student = _students.firstWhere((s) => s['id'] == studentId);
    
    // Optimistic Update
    setState(() {
      _attendanceRecords[studentId] = {
        'status': status,
        'waktu': 'Baru saja',
      };
    });

    final payload = {
      if (existing != null) 'id': existing['id'],
      'user_id': studentId,
      'nama_siswa': student['nama'],
      'status': status,
      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'waktu': DateFormat('HH:mm').format(DateTime.now()),
      'kelas_id': widget.teamData != null ? widget.teamData['id'] : widget.userData['kelas_id'],
    };

    try {
      await PresensiService.upsertPresensi(widget.token, payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan'), backgroundColor: Colors.red));
        _loadData(); // Revert on failure
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // ── Dashboard Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jurnal Kehadiran',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  Text(
                    'Update status presensi siswa secara real-time',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              GlassCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, size: 20),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2026),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                          _loadData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),

          const SizedBox(height: 24),

          // ── Student List ──
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                ? const Center(child: Text('Tidak ada siswa di kelas ini'))
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      final record = _attendanceRecords[s['id']];
                      final currentStatus = record?['status'] ?? 'Belum Absen';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withAlpha(20),
                                child: Text(s['nama'].substring(0, 1), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['nama'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    Text(
                                      currentStatus == 'Belum Absen' ? 'Belum dicatat' : 'Pukul: ${record?['waktu']}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildModernStatusSelector(s['id'], currentStatus),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusSelector(String studentId, String currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusBtn(studentId, 'Hadir', 'H', Colors.green, currentStatus == 'Hadir'),
        const SizedBox(width: 6),
        _buildStatusBtn(studentId, 'Izin', 'I', Colors.blue, currentStatus == 'Izin'),
        const SizedBox(width: 6),
        _buildStatusBtn(studentId, 'Sakit', 'S', Colors.orange, currentStatus == 'Sakit'),
        const SizedBox(width: 6),
        _buildStatusBtn(studentId, 'Alpa', 'A', Colors.red, currentStatus == 'Alpa'),
      ],
    );
  }

  Widget _buildStatusBtn(String studentId, String status, String short, Color color, bool isSelected) {
    return InkWell(
      onTap: () => _updateStatus(studentId, status),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Text(
            short,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

