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
    final nowTime = DateFormat('HH:mm').format(DateTime.now());
    
    // Optimistic Update
    setState(() {
      _attendanceRecords[studentId] = {
        if (existing != null) ...existing,
        'status': status,
        'waktu': nowTime,
      };
    });

    final payload = {
      if (existing != null) 'id': existing['id'],
      'user_id': studentId,
      'nama_siswa': student['nama'],
      'status': status,
      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'waktu': nowTime,
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

  Map<String, int> _getStats() {
    int hadir = 0, izin = 0, sakit = 0, alpa = 0;
    for (var s in _students) {
      final status = _attendanceRecords[s['id']]?['status'] ?? 'Belum Absen';
      if (status == 'Hadir') hadir++;
      else if (status == 'Izin') izin++;
      else if (status == 'Sakit') sakit++;
      else if (status == 'Alpa') alpa++;
    }
    return {'Hadir': hadir, 'Izin': izin, 'Sakit': sakit, 'Alpa': alpa};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Date Picker ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jurnal Kehadiran',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900, 
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau kehadiran kelas ${widget.teamData != null ? widget.teamData['nama_kelas'] : ''}',
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark 
                                ? ColorScheme.dark(primary: theme.primaryColor)
                                : ColorScheme.light(primary: theme.primaryColor),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadData();
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),

          const SizedBox(height: 24),

          // ── Dashboard Stats ──
          if (!_isLoading && _students.isNotEmpty)
            _buildStatsDashboard(theme).animate().fadeIn(delay: 100.ms).scale(curve: Curves.easeOutBack),

          const SizedBox(height: 24),

          // ── Student List ──
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : _students.isEmpty
                ? const EmptyState(
                    icon: Icons.people_alt_outlined,
                    message: 'Belum ada siswa di kelas ini.',
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      final record = _attendanceRecords[s['id']];
                      final currentStatus = record?['status'] ?? 'Belum Absen';

                      return _buildStudentCard(s, currentStatus, record?['waktu'], theme, isDark)
                          .animate(delay: (index * 40).ms)
                          .fadeIn()
                          .slideX(begin: 0.05, curve: Curves.easeOutQuart);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(ThemeData theme) {
    final stats = _getStats();
    return Row(
      children: [
        Expanded(child: _buildStatCard('Hadir', stats['Hadir']!, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Izin', stats['Izin']!, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Sakit', stats['Sakit']!, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Alpa', stats['Alpa']!, const Color(0xFFEF4444))),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassCard(
      radius: 16,
      blurSigma: 10,
      overrideColor: color.withAlpha(isDark ? 30 : 15),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(isDark ? 40 : 30), shape: BoxShape.circle),
            child: Text(
              label[0],
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(dynamic s, String currentStatus, String? time, ThemeData theme, bool isDark) {
    final bool isRecorded = currentStatus != 'Belum Absen';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 16,
        overrideColor: isRecorded 
            ? theme.colorScheme.surface.withAlpha(isDark ? 150 : 255)
            : theme.colorScheme.surface.withAlpha(isDark ? 50 : 100),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor.withAlpha(180), theme.primaryColor.withAlpha(80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  s['nama'].substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['nama'],
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16,
                      color: isRecorded ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isRecorded ? Icons.access_time_filled_rounded : Icons.access_time_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRecorded ? 'Tercatat: $time' : 'Belum dicatat',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Toggles
            _buildModernStatusSelector(s['id'], currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatusSelector(String studentId, String currentStatus) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBtn(studentId, 'Hadir', 'H', const Color(0xFF10B981), currentStatus == 'Hadir'),
          _buildStatusBtn(studentId, 'Izin', 'I', const Color(0xFF3B82F6), currentStatus == 'Izin'),
          _buildStatusBtn(studentId, 'Sakit', 'S', const Color(0xFFF59E0B), currentStatus == 'Sakit'),
          _buildStatusBtn(studentId, 'Alpa', 'A', const Color(0xFFEF4444), currentStatus == 'Alpa'),
        ],
      ),
    );
  }

  Widget _buildStatusBtn(String studentId, String status, String short, Color color, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateStatus(studentId, status),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(color: color.withAlpha(100), blurRadius: 8, offset: const Offset(0, 2))
            ] : [],
          ),
          child: Center(
            child: Text(
              short,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(100),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
