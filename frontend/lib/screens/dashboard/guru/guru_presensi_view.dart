import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_shell.dart';
import '../../../services/presensi_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  bool _isRecapMode = false;

  // Mode Harian
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _attendanceRecords = {}; // studentId -> record
  bool _isLoading = true;

  // Mode Rekap
  DateTimeRange? _recapDateRange;
  List<Map<String, dynamic>> _recapRecords = [];
  bool _isLoadingRecap = false;
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final kelasId = widget.teamData != null
          ? widget.teamData['id']
          : (widget.userData['kelas_id'] ?? '-');
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final students =
          await PresensiService.getStudentsByKelas(widget.token, kelasId);
      final records = await PresensiService.getPresensiByDate(
          widget.token, kelasId, dateStr);

      final Map<String, dynamic> recordMap = {
        for (var r in records) r['user_id'].toString(): r
      };

      setState(() {
        _students = students;
        _attendanceRecords = recordMap;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal Memuat: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecapData() async {
    if (_recapDateRange == null) return;
    setState(() => _isLoadingRecap = true);
    try {
      final kelasId = widget.teamData != null
          ? widget.teamData['id']
          : (widget.userData['kelas_id'] ?? '-');
      final dateAStr = DateFormat('yyyy-MM-dd').format(_recapDateRange!.start);
      final dateBStr = DateFormat('yyyy-MM-dd').format(_recapDateRange!.end);

      final records = await PresensiService.getPresensiByRange(
          widget.token, kelasId, dateAStr, dateBStr);

      setState(() {
        _recapRecords = records;
        _isLoadingRecap = false;
        _expandedState.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal Memuat Rekap: $e'),
            backgroundColor: Colors.red));
      }
      setState(() => _isLoadingRecap = false);
    }
  }

  void _updateStatus(String studentId, String status) async {
    final existing = _attendanceRecords[studentId];
    final student = _students.firstWhere((s) => s['id'] == studentId);
    final nowTime = DateFormat('HH:mm').format(DateTime.now());

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
      'kelas_id': widget.teamData != null
          ? widget.teamData['id']
          : widget.userData['kelas_id'],
    };

    try {
      await PresensiService.upsertPresensi(widget.token, payload);
      if (_recapDateRange != null &&
          !_selectedDate.isBefore(_recapDateRange!.start) &&
          !_selectedDate.isAfter(_recapDateRange!.end)) {
        _loadRecapData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menyimpan'), backgroundColor: Colors.red));
        _loadData();
      }
    }
  }

  Map<String, int> _getStats() {
    int hadir = 0, izin = 0, sakit = 0, alpa = 0;
    for (var s in _students) {
      final status = _attendanceRecords[s['id']]?['status'] ?? 'Belum Absen';
      if (status == 'Hadir') {
        hadir++;
      } else if (status == 'Izin') {
        izin++;
      } else if (status == 'Sakit') {
        sakit++;
      } else if (status == 'Alpa') {
        alpa++;
      }
    }
    return {'Hadir': hadir, 'Izin': izin, 'Sakit': sakit, 'Alpa': alpa};
  }

  Map<String, int> _getRecapStatsForStudent(String studentId) {
    int hadir = 0, izin = 0, sakit = 0, alpa = 0;
    for (var r in _recapRecords) {
      if (r['user_id'] == studentId) {
        final status = r['status'] ?? '';
        if (status == 'Hadir') {
          hadir++;
        } else if (status == 'Izin') {
          izin++;
        } else if (status == 'Sakit') {
          sakit++;
        } else {
          alpa++;
        }
      }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecapMode ? 'Rekap Kehadiran' : 'Jurnal Kehadiran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pantau kehadiran kelas ${widget.teamData != null ? widget.teamData['nama_kelas'] : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2538) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildModeBtn('Harian', LucideIcons.calendar, !_isRecapMode, theme, isDark),
                    _buildModeBtn('Rekap', LucideIcons.barChart2, _isRecapMode, theme, isDark),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),

          const SizedBox(height: 24),

          if (!_isRecapMode)
            _buildDailyHeader(theme, isDark)
          else
            _buildRecapHeader(theme, isDark),

          const SizedBox(height: 24),

          if (!_isRecapMode) ...[
            if (!_isLoading && _students.isNotEmpty)
              _buildStatsDashboard(theme)
                  .animate()
                  .fadeIn(delay: 50.ms)
                  .scale(curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.users,
                          message: 'Belum ada siswa di kelas ini.')
                      : ListView.builder(
                          itemCount: _students.length,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            final record = _attendanceRecords[s['id']];
                            final currentStatus =
                                record?['status'] ?? 'Belum Absen';

                            return _buildStudentCard(s, currentStatus,
                                    record?['waktu'], theme, isDark)
                                .animate(delay: (index * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.05, curve: Curves.easeOutQuart);
                          },
                        ),
            ),
          ] else ...[
            Expanded(
              child: _isLoadingRecap || _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recapDateRange == null
                      ? const EmptyState(
                          icon: LucideIcons.calendar,
                          message: 'Pilih rentang tanggal terlebih dahulu.')
                      : _students.isEmpty
                          ? const EmptyState(
                              icon: LucideIcons.users,
                              message: 'Belum ada siswa di kelas ini.')
                          : ListView.builder(
                              itemCount: _students.length,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemBuilder: (context, index) {
                                final s = _students[index];
                                return _buildRecapStudentCard(s, theme, isDark)
                                    .animate(delay: (index * 40).ms)
                                    .fadeIn()
                                    .slideX(begin: 0.05, curve: Curves.easeOutQuart);
                              },
                            ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildModeBtn(String label, IconData icon, bool isSelected,
      ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _isRecapMode = !_isRecapMode;
            if (_isRecapMode && _recapDateRange == null) {
              _recapDateRange = DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now());
              _loadRecapData();
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.indigoPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 12,
                color: isSelected ? Colors.white : (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Text(
          'Pencatatan Harian',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            color: isDark ? Colors.white : AppTheme.textLight,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2538) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
          ),
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadData();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, color: AppTheme.tealDeep, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textLight,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildRecapHeader(ThemeData theme, bool isDark) {
    final startStr = _recapDateRange != null
        ? DateFormat('dd MMM').format(_recapDateRange!.start)
        : 'Pilih';
    final endStr = _recapDateRange != null
        ? DateFormat('dd MMM yyyy').format(_recapDateRange!.end)
        : 'Tanggal';

    return Row(
      children: [
        Text(
          'Rentang Waktu Rekap',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            color: isDark ? Colors.white : AppTheme.textLight,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2538) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB), width: 1.2),
          ),
          child: InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                initialDateRange: _recapDateRange,
              );
              if (range != null) {
                setState(() => _recapDateRange = range);
                _loadRecapData();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, color: AppTheme.tealDeep, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$startStr - $endStr',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textLight,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildStatsDashboard(ThemeData theme) {
    final stats = _getStats();
    return Row(
      children: [
        Expanded(child: _buildStatCard('Hadir', stats['Hadir']!, const Color(0xFF10B981))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Izin', stats['Izin']!, const Color(0xFF76AFB8))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Sakit', stats['Sakit']!, const Color(0xFFF59E0B))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Alpa', stats['Alpa']!, const Color(0xFFEF4444))),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(isDark ? 55 : 30),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(15)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Text(
                label[0],
                style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic s, String currentStatus, String? time,
      ThemeData theme, bool isDark) {
    final bool isRecorded = currentStatus != 'Belum Absen';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2538) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.indigoPrimary,
                      AppTheme.indigoPrimary.withAlpha(120),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    s['nama'].substring(0, 1).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['nama'],
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppTheme.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRecorded ? 'Tercatat: $time' : 'Belum dicatat',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildModernStatusSelector(s['id'], currentStatus, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapStudentCard(dynamic s, ThemeData theme, bool isDark) {
    final stats = _getRecapStatsForStudent(s['id']);
    final total =
        stats['Hadir']! + stats['Izin']! + stats['Sakit']! + stats['Alpa']!;
    final pct = total > 0 ? (stats['Hadir']! / total) : 0.0;
    final isExpanded = _expandedState[s['id']] ?? false;

    Color pctColor = const Color(0xFF22C55E);
    if (pct < 0.8) pctColor = const Color(0xFFF59E0B);
    if (pct < 0.6) pctColor = const Color(0xFFEF4444);
    if (total == 0) pctColor = Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2538) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161D2B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedState[s['id']] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pctColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            s['nama'].substring(0, 1).toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: pctColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s['nama'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : AppTheme.textLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  total > 0
                                      ? '${(pct * 100).toStringAsFixed(0)}%'
                                      : 'Belum ada data',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: pctColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutQuart,
                                    width: total > 0
                                        ? (MediaQuery.of(context).size.width * 0.4) * pct
                                        : 0,
                                    decoration: BoxDecoration(
                                      color: pctColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2538) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRecapMiniStat('Hadir', stats['Hadir']!, const Color(0xFF10B981)),
                        _buildRecapMiniStat('Izin', stats['Izin']!, const Color(0xFF76AFB8)),
                        _buildRecapMiniStat('Sakit', stats['Sakit']!, const Color(0xFFF59E0B)),
                        _buildRecapMiniStat('Alpa', stats['Alpa']!, const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapMiniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color.withAlpha(200)),
        ),
      ],
    );
  }

  Widget _buildModernStatusSelector(String studentId, String currentStatus, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D3A54) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBtn(studentId, 'Hadir', 'H', const Color(0xFF10B981), currentStatus == 'Hadir'),
          _buildStatusBtn(studentId, 'Izin', 'I', const Color(0xFF76AFB8), currentStatus == 'Izin'),
          _buildStatusBtn(studentId, 'Sakit', 'S', const Color(0xFFF59E0B), currentStatus == 'Sakit'),
          _buildStatusBtn(studentId, 'Alpa', 'A', const Color(0xFFEF4444), currentStatus == 'Alpa'),
        ],
      ),
    );
  }

  Widget _buildStatusBtn(String studentId, String status, String short,
      Color color, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateStatus(studentId, status),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              short,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : color.withAlpha(180),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
