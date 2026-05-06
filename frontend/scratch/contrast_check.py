def get_luminance(hex_str):
    hex_str = hex_str.lstrip('#').replace('0xFF', '')
    if len(hex_str) == 6:
        r, g, b = tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    else:
        return 1.0 # fallback

    rs, gs, bs = r/255.0, g/255.0, b/255.0
    
    def adjust(c):
        if c <= 0.03928: return c / 12.92
        return ((c + 0.055) / 1.055) ** 2.4
        
    R, G, B = adjust(rs), adjust(gs), adjust(bs)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B

def get_contrast(hex1, hex2):
    l1 = get_luminance(hex1)
    l2 = get_luminance(hex2)
    l_max = max(l1, l2)
    l_min = min(l1, l2)
    return (l_max + 0.05) / (l_min + 0.05)

colors = {
    'Teal Deep': '#075864',
    'Teal Light': '#76AFB8',
    'Orange Vivid': '#F27F33',
    'White (Light BG)': '#FFFFFF',
    'Dark BG': '#121212',
    'Dark Surface': '#1E1E1E',
    'Muted Light': '#26494F',
    'Muted Dark': '#8DBCC3'
}

combinations = [
    ('White (Light BG)', 'Teal Deep'),     # Light theme button/header
    ('White (Light BG)', 'Teal Light'),    # Light theme secondary
    ('White (Light BG)', 'Orange Vivid'),  # Light theme accent
    ('White (Light BG)', 'Muted Light'),   # Light theme muted text
    ('Dark BG', 'Teal Deep'),              # Dark theme primary
    ('Dark BG', 'Teal Light'),             # Dark theme secondary
    ('Dark BG', 'Orange Vivid'),           # Dark theme accent
    ('Dark BG', 'White (Light BG)'),       # Dark theme text
    ('Dark BG', 'Muted Dark'),             # Dark theme muted text
    ('Dark Surface', 'Teal Deep'),         # Dark surface primary
    ('Dark Surface', 'Teal Light'),        # Dark surface secondary
    ('Dark Surface', 'Orange Vivid'),      # Dark surface accent
    ('Dark Surface', 'White (Light BG)'),  # Dark surface text
    ('Teal Deep', 'White (Light BG)'),     # Button text
    ('Teal Light', 'White (Light BG)'),    # Button text
    ('Orange Vivid', 'White (Light BG)'),  # Button text
    ('Teal Light', 'Dark BG'),             # Button text dark mode
    ('Orange Vivid', 'Dark BG'),           # Button text dark mode
]

print(f"{'Background':<20} | {'Foreground/Text':<20} | {'Ratio':<6} | {'WCAG AA (4.5)'}")
print("-" * 70)
for bg, fg in combinations:
    ratio = get_contrast(colors[bg], colors[fg])
    passed = "✅ PASS" if ratio >= 4.5 else ("⚠️ AA Large (3.0)" if ratio >= 3.0 else "❌ FAIL")
    print(f"{bg:<20} | {fg:<20} | {ratio:>5.2f} | {passed}")
