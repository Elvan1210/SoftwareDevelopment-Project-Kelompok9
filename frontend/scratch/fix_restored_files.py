import os

files = [
    'lib/screens/dashboard/admin/admin_pengumuman_view.dart',
    'lib/screens/dashboard/admin/admin_profil_view.dart',
    'lib/screens/dashboard/guru/guru_pending_requests_view.dart',
    'lib/screens/dashboard/guru/guru_team_detail_layout.dart'
]

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # Replace colors
        content = content.replace('AppTheme.purpleSecondary', 'AppTheme.primary')
        content = content.replace('AppTheme.purpleLight', 'AppTheme.primaryLight')
        content = content.replace('AppTheme.purplePrimary', 'AppTheme.primary')
        content = content.replace('AppTheme.purpleAccent', 'AppTheme.primary')
        
        # Fix const BorderRadius.zero
        content = content.replace('BorderRadius.zero', 'const BorderRadius.zero')
        content = content.replace('const const', 'const')
        
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Fixed {f}")
    except Exception as e:
        print(f"Error on {f}: {e}")
