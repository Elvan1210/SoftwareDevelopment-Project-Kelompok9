import os
import re

lib_dir = r"d:\PROJECT SOFTDEV\softdev\frontend\lib"

pattern_grey = re.compile(r'Colors\.grey(\.shade\d+|\[\d+\])?')
pattern_black_opacity = re.compile(r'Colors\.black\d*')
pattern_white_opacity = re.compile(r'Colors\.white\d*')

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Check if we have isDark or context
    has_is_dark = 'isDark' in content
    has_context = 'context' in content

    # We will replace Colors.grey with a context-aware or isDark-aware expression
    # If isDark is available, use (isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)
    # If context is available, use Theme.of(context).colorScheme.onSurface.withOpacity(0.65)
    # If neither, we might not be able to fix easily, but we'll try to find if we can just use a slightly darker grey if it's mostly light mode, or skip.

    replacement = None
    if has_is_dark and 'AppTheme' in content:
        replacement = '(isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)'
    elif has_context:
        replacement = 'Theme.of(context).colorScheme.onSurface.withOpacity(0.65)'
        
    if replacement:
        # We only want to replace it when it's used as a color, like `color: Colors.grey...`
        # Let's use a regex that matches `color: Colors.grey...`
        content = re.sub(r'color:\s*Colors\.grey(?:\.shade\d+|\[\d+\])?(?:\.with(?:Alpha|Opacity)\([^)]+\))?', f'color: {replacement}', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Strict contrast fix complete.")
