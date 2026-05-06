import os
import re

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Remove blurSigma: [number], or blurSigma: [number]
            # Match blurSigma:\s*[^,)]+,?
            new_content = re.sub(r'blurSigma:\s*[^,)]+,?\s*', '', content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {path}")
