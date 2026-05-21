import os
import re

file_path = 'lib/screens/dashboard/guru/guru_team_detail_layout.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _BrutalStatCard with NeoCard
content = re.sub(
    r'class _BrutalStatCard extends StatelessWidget \{.*?\n\}',
    '',
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'_BrutalStatCard\(\s*label:\s*(.*?),\s*value:\s*(.*?),\s*icon:\s*(.*?),\s*color:\s*(.*?),\s*\)',
    r'''NeoCard(
      color: \4.withAlpha(20),
      borderColor: \4,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(\3, color: \4, size: 28),
          const SizedBox(height: 16),
          Text(\1, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(\2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        ],
      ),
    )''',
    content
)

content = content.replace("import '../../../widgets/app_shell.dart';", "import '../../../widgets/app_shell.dart';\nimport '../../../widgets/neo_brutalism.dart';")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated guru_team_detail_layout.dart")
