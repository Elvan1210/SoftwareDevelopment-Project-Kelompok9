import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

const String studentName = "Software Dev Pls IP 4";
const String studentProfileUrl = "https://i.pravatar.cc/150?u=ahmad_dhani";
const int pendingTasks = 5;
const int completedTasks = 10;
const int todayClasses = 3;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade800;
    final Color secondaryColor = Colors.purple.shade600;
    final Color cardBackgroundColor = Colors.white;
    final Color shadowColor = Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(primaryColor, context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(primaryColor, secondaryColor),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "Tugas Terbaru", Icons.assignment),
            const SizedBox(height: 12),
            _buildAssignmentsSection(cardBackgroundColor, shadowColor),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "Materi Terbaru", Icons.book),
            const SizedBox(height: 12),
            _buildMaterialsSection(cardBackgroundColor, shadowColor),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSectionTitle(context, "Nilai", Icons.grade),
                      const SizedBox(height: 12),
                      _buildGradesSection(cardBackgroundColor, shadowColor, secondaryColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildSectionTitle(context, "Jadwal Hari Ini", Icons.schedule),
                      const SizedBox(height: 12),
                      _buildScheduleSection(cardBackgroundColor, shadowColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "Pengumuman", Icons.announcement),
            const SizedBox(height: 12),
            _buildAnnouncementsSection(cardBackgroundColor, shadowColor),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(primaryColor),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage(studentProfileUrl),
            radius: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang,",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                studentName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge(
            label: const Text('3'),
            child: Icon(Icons.notifications, color: Colors.grey.shade700),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.logout, color: Colors.red.shade400),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOverviewSection(Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildOverviewCard("Tugas Belum Dikerjakan", pendingTasks.toString(), Icons.pending_actions, primaryColor),
        _buildOverviewCard("Tugas Selesai", completedTasks.toString(), Icons.check_circle, Colors.green.shade600),
        _buildOverviewCard("Jadwal Hari Ini", todayClasses.toString(), Icons.calendar_today, secondaryColor),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildAssignmentsSection(Color cardColor, Color shadowColor) {
    final assignments = [
      {"title": "Tugas Matematika Bab 5", "deadline": "Besok, 23:59", "status": "Belum"},
      {"title": "Makalah Sejarah Indonesia", "deadline": "25 Mar 2026", "status": "Belum"},
      {"title": "Projek Fisika", "deadline": "22 Mar 2026", "status": "Selesai"},
    ];

    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: assignments.map((task) {
          final isDone = task["status"] == "Selesai";
          return ListTile(
            leading: Icon(
              isDone ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : Colors.orange,
            ),
            title: Text(task["title"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Deadline: ${task['deadline']}"),
            trailing: ElevatedButton(
              onPressed: isDone ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Upload"),
            ),
            onTap: () {},
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaterialsSection(Color cardColor, Color shadowColor) {
    final materials = [
      {"title": "Modul Aljabar Linear", "subject": "Matematika"},
      {"title": "Presentasi Perang Dunia II", "subject": "Sejarah"},
    ];
    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: materials.map((material) {
          return ListTile(
            leading: const Icon(Icons.article_outlined, color: Colors.blue),
            title: Text(material["title"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(material["subject"]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradesSection(Color cardColor, Color shadowColor, Color secondaryColor) {
    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nilai Terbaru: Biologi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("A- (92.5)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryColor)),
            const SizedBox(height: 12),
            const Text("Rata-rata Nilai"),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: 0.88,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: Text("88.0 / 100.0", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(Color cardColor, Color shadowColor) {
    final schedule = [
      {"time": "08:00 - 09:30", "subject": "Fisika", "teacher": "Dr. Strange"},
      {"time": "10:00 - 11:30", "subject": "Kimia", "teacher": "Walter White"},
    ];
    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: schedule.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["subject"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${item['time']} - ${item['teacher']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(Color cardColor, Color shadowColor) {
    return Card(
      elevation: 2,
      color: cardColor,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.campaign_outlined, color: Colors.orange),
        title: const Text("Ujian Akhir Semester akan dilaksanakan minggu depan.", style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text("Dari: Akademik"),
        onTap: () {},
      ),
    );
  }

  Widget _buildBottomNavigationBar(Color primaryColor) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Materi'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas'),
        BottomNavigationBarItem(icon: Icon(Icons.grade), label: 'Nilai'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Jadwal'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      onTap: _onItemTapped,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    );
  }
}