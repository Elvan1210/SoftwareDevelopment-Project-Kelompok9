import os
import re

file_path = 'lib/screens/dashboard/guru/guru_pending_requests_view.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildRequestCard
content = re.sub(
    r'return Container\(\s*decoration: BoxDecoration\(\s*color:.*?borderRadius: BorderRadius\.circular\(24\).*?padding: const EdgeInsets\.all\(4\),\s*child: Container\(\s*padding: const EdgeInsets\.all\(16\),\s*decoration: BoxDecoration\(\s*color:.*?borderRadius: BorderRadius\.circular\(20\),\s*\),\s*child: Row\(',
    r'''return NeoCard(
      color: Theme.of(context).colorScheme.surface,
      borderColor: Theme.of(context).colorScheme.onSurface,
      padding: const EdgeInsets.all(16),
      child: Row(''',
    content,
    flags=re.DOTALL
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated guru_pending_requests_view.dart")
