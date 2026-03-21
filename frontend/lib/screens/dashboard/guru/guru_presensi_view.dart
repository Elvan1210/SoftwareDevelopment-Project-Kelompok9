import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/app_shell.dart';

class GuruPresensiView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const GuruPresensiView({super.key, required this.userData, required this.token});

  @override
  State<GuruPresensiView> createState() => _GuruPresensiViewState();
}

class _GuruPresensiViewState extends State<GuruPresensiView> {
  final _AttendanceDataSource _dataSource = _AttendanceDataSource();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AntigravityFAB(
          onPressed: () {},
          icon: Icons.qr_code_scanner_rounded,
          label: 'Mulai Sesi',
        ),
        body: LayoutBuilder(
          builder: (ctx, c) {
            final w = c.maxWidth;
            final padding = Breakpoints.screenPadding(w);

            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Presensi Digital',
                    subtitle: 'Pantau kehadiran siswa kelas ${widget.userData['kelas'] ?? '-'} secara real-time',
                  ),
                  const SizedBox(height: 32),
                  
                  // ── Premium Table Card ──────────────────────────────────
                  RepaintBoundary(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(isDark ? 100 : 255),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 100), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 5), blurRadius: 30, offset: const Offset(0, 15))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Theme(
                          data: theme.copyWith(
                            cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
                            dividerColor: theme.colorScheme.onSurface.withAlpha(20),
                          ),
                          child: PaginatedDataTable(
                            header: const Text('Log Kehadiran Hari Ini', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                            columns: const [
                              DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w800))),
                            ],
                            source: _dataSource,
                            rowsPerPage: 8,
                            availableRowsPerPage: const [8, 15, 30],
                            showCheckboxColumn: false,
                            dataRowMaxHeight: 72,
                            dataRowMinHeight: 72,
                            headingRowHeight: 60,
                            horizontalMargin: 24,
                            columnSpacing: 20,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
                  
                  const SizedBox(height: 100), // Padding for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data = [
    {'nama': 'Arya Rava Pradana', 'status': 'Hadir', 'waktu': '07:12', 'valid': true},
    {'nama': 'Budi Santoso', 'status': 'Sakit', 'waktu': '-', 'valid': false},
    {'nama': 'Citra Lestari', 'status': 'Hadir', 'waktu': '07:05', 'valid': true},
    {'nama': 'Dedi Kurniawan', 'status': 'Izin', 'waktu': '-', 'valid': false},
    {'nama': 'Endang Wijaya', 'status': 'Hadir', 'waktu': '07:22', 'valid': true},
  ];

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final row = _data[index];
    final color = row['status'] == 'Hadir' ? const Color(0xFF10B981) : (row['status'] == 'Sakit' ? Colors.orange : Colors.red);

    return DataRow(cells: [
      DataCell(Text(row['nama'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(100)),
          child: Text(row['status'], style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ),
      DataCell(Text(row['waktu'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
      DataCell(
        Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red)),
          ],
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _data.length;
  @override
  int get selectedRowCount => 0;
}
