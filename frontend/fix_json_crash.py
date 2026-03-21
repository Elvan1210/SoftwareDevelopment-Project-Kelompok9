import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'): continue
        path = os.path.join(root, file)
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content

        # Fix 1: List name = jsonDecode(something);
        content = re.sub(r'List\s+(\w+)\s*=\s*jsonDecode\((.*?)\);', 
                         r'final _dec_\1 = jsonDecode(\2);\n        List \1 = _dec_\1 is List ? _dec_\1 : [];', 
                         content)

        # Fix 2: setState(() => _listName = jsonDecode(something));
        content = re.sub(r'setState\(\(\)\s*=>\s*(_\w+)\s*=\s*jsonDecode\((.*?)\)\);',
                         r'final _dec_\1 = jsonDecode(\2);\n        setState(() => \1 = _dec_\1 is List ? _dec_\1 : []);',
                         content)

        if content != original_content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
