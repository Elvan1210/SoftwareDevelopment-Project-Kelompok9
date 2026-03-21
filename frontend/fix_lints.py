import os
import re

def replace_in_file(path, old, new):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# Fix empty catches (guru_materi_view.dart, guru_tugas_view.dart)
replace_in_file('lib/screens/dashboard/guru/guru_materi_view.dart', 'catch (e) {}', "catch (e) { debugPrint('Error: $e'); }")
replace_in_file('lib/screens/dashboard/guru/guru_tugas_view.dart', 'catch (e) {}', "catch (e) { debugPrint('Error: $e'); }")

# Fix unused isDark
replace_in_file('lib/screens/dashboard/guru/guru_materi_view.dart', 'final isDark = theme.brightness == Brightness.dark;\n', '')
replace_in_file('lib/screens/dashboard/siswa/siswa_materi_view.dart', 'final isDark = theme.brightness == Brightness.dark;\n', '')
replace_in_file('lib/screens/dashboard/siswa/siswa_nilai_view.dart', 'final isDark = theme.brightness == Brightness.dark;\n', '')

# Fix withOpacity globally
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            # replace .withOpacity(x) with .withAlpha(int(x*255))
            def replacer(match):
                op = float(match.group(1))
                return f'.withAlpha({int(op*255)})'
            new_content = re.sub(r'\.withOpacity\(([\d.]+)\)', replacer, content)
            
            # also replace any remaining withOpacity with withValues
            new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withAlpha((\1 * 255).toInt())', new_content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
