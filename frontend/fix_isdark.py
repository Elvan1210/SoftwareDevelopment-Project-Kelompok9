import os
import re

files = [
    'lib/screens/dashboard/guru/guru_materi_view.dart',
    'lib/screens/dashboard/siswa/siswa_materi_view.dart',
    'lib/screens/dashboard/siswa/siswa_nilai_view.dart'
]

for filepath in files:
    if not os.path.exists(filepath): continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove existing definitions
    content = content.replace('final isDark = theme.brightness == Brightness.dark;', '')
    content = content.replace('final (Theme.of(context).brightness == Brightness.dark) = theme.brightness == Brightness.dark;', '')
    
    # Replace usages safely
    content = re.sub(r'\bisDark\b', '(Theme.of(context).brightness == Brightness.dark)', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
