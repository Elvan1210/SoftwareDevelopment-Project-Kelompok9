import os
import re

analyze_file = r"d:\PROJECT SOFTDEV\softdev\frontend\scratch\analyze2.txt"

def run():
    # We will run flutter analyze and parse the output
    import subprocess
    result = subprocess.run(['flutter', 'analyze'], cwd=r"d:\PROJECT SOFTDEV\softdev\frontend", capture_output=True, text=True, shell=True)
    
    lines = result.stdout.split('\n')
    
    file_fixes = {}
    
    for line in lines:
        if 'const_eval_method_invocation' in line or 'invalid_constant' in line or 'non_constant_default_value' in line or 'must_be_a_constant_expression' in line:
            # error - Methods can't be invoked in constant expressions - lib\screens\dashboard\admin\admin_nilai_view.dart:158:145 - const_eval_method_invocation
            m = re.search(r'(lib[/\\][^:]+):(\d+):(\d+)', line)
            if m:
                filepath = os.path.join(r"d:\PROJECT SOFTDEV\softdev\frontend", m.group(1))
                line_num = int(m.group(2)) - 1
                
                if filepath not in file_fixes:
                    file_fixes[filepath] = set()
                file_fixes[filepath].add(line_num)
                
    for filepath, lines_to_fix in file_fixes.items():
        with open(filepath, 'r', encoding='utf-8') as f:
            content_lines = f.readlines()
            
        for l in lines_to_fix:
            # Remove 'const ' from the line
            content_lines[l] = re.sub(r'\bconst\s+', '', content_lines[l])
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(content_lines)
            
        print(f"Removed const in {filepath} on lines {lines_to_fix}")

if __name__ == '__main__':
    run()
