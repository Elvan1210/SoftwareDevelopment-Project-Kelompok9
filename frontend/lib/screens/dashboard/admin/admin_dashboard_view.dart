import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../widgets/stat_card.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  StatCard(title: 'Total Siswa', value: '450', icon: Icons.school, color: Colors.blue.shade600),
                  StatCard(title: 'Total Guru', value: '42', icon: Icons.person, color: Colors.purple.shade600),
                  StatCard(title: 'Total Kelas', value: '18', icon: Icons.class_, color: Colors.orange.shade600),
                  StatCard(title: 'Total Mapel', value: '24', icon: Icons.book, color: Colors.green.shade600),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text('Aktivitas Sistem', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][val.toInt()]),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 300, color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 400, color: Colors.purple)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 350, color: Colors.blue)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 450, color: Colors.purple)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 400, color: Colors.blue)]),
                      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 100, color: Colors.grey)]),
                      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 50, color: Colors.grey)]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}