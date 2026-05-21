import os

# 1. admin_pengumuman_view.dart
file1 = 'lib/screens/dashboard/admin/admin_pengumuman_view.dart'
with open(file1, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace('AppTheme.primaryLight', 'AppTheme.indigoLight')
with open(file1, 'w', encoding='utf-8') as f: f.write(content)

# 2. guru_team_detail_layout.dart
file2 = 'lib/screens/dashboard/guru/guru_team_detail_layout.dart'
with open(file2, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace('const BorderRadius.zero(', 'BorderRadius.zero')
content = content.replace("import '../../../widgets/neo_brutalism.dart';\n", "")
with open(file2, 'w', encoding='utf-8') as f: f.write(content)

# 3. siswa_tugas_detail_screen.dart
file3 = 'lib/screens/dashboard/siswa/siswa_tugas_detail_screen.dart'
with open(file3, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace("import 'dart:ui';\n", "")
with open(file3, 'w', encoding='utf-8') as f: f.write(content)

print("Fixed!")
