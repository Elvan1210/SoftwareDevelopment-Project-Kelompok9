import os, re

replacements = [
    (r'Color\(0xFF3B82F6\)', 'Color(0xFF76AFB8)'),
    (r'Colors\.blue(?!\.shade)', 'Color(0xFF76AFB8)'),
    (r'Colors\.blue\.shade\d+', 'Color(0xFF76AFB8)'),
    (r'Color\(0xFF8B5CF6\)', 'Color(0xFF075864)'),
    (r'Color\(0xFF0F172A\)', 'Color(0xFF011113)'),
    (r'Color\(0xFF020617\)', 'Color(0xFF011113)'),
    (r'Color\(0xFFF8FAFC\)', 'Color(0xFFE3EFF0)'),
    (r'Color\(0xFFE2E8F0\)', 'Color(0xFFE3EFF0)'),
    (r'Color\(0xFF595959\)', 'Color(0xFF26494F)'),
    (r'Colors\.grey\.shade700', 'Color(0xFF26494F)'),
    (r'Colors\.grey\.shade400', 'Color(0xFF8DBCC3)'),
]

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = content
            for pattern, repl in replacements:
                new_content = re.sub(pattern, repl, new_content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f'Updated {path}')
