import sys

def remove_block(content, start_marker, is_var=False):
    start_idx = content.find(start_marker)
    if start_idx == -1: return content
    brace_start = content.find('{', start_idx)
    if brace_start == -1: return content
    count = 1
    idx = brace_start + 1
    while count > 0 and idx < len(content):
        if content[idx] == '{': count += 1
        elif content[idx] == '}': count -= 1
        idx += 1
    if is_var:
        while idx < len(content) and content[idx] in [';', ' ', '\n', '\t']:
            idx += 1
    return content[:start_idx] + content[idx:]

def remove_array_block(content, start_marker):
    start_idx = content.find(start_marker)
    if start_idx == -1: return content
    brace_start = content.find('[', start_idx)
    if brace_start == -1: return content
    count = 1
    idx = brace_start + 1
    while count > 0 and idx < len(content):
        if content[idx] == '[': count += 1
        elif content[idx] == ']': count -= 1
        idx += 1
    while idx < len(content) and content[idx] in [';', ' ', '\n', '\t']:
        idx += 1
    return content[:start_idx] + content[idx:]

# 1. mudir_dashboard.dart
path = 'lib/screens/dashboards/mudir_dashboard.dart'
with open(path, 'r') as f: content = f.read()
content = remove_block(content, 'class _ChartLegendRow')
content = content.replace('// Chart Legend Row helper\n', '')
with open(path, 'w') as f: f.write(content)

# 2. wali_dashboard.dart
path = 'lib/screens/dashboards/wali_dashboard.dart'
with open(path, 'r') as f: content = f.read()
content = remove_array_block(content, 'final List<Map<String, dynamic>> _chatSessions')
content = remove_block(content, 'Widget _buildMethodTile')
with open(path, 'w') as f: f.write(content)

# 3. akademik_screen.dart
path = 'lib/screens/modules/akademik_screen.dart'
with open(path, 'r') as f: content = f.read()
content = remove_block(content, 'Widget _buildRaportTab')
with open(path, 'w') as f: f.write(content)

# 4. musyrif_dashboard.dart
path = 'lib/screens/dashboards/musyrif_dashboard.dart'
with open(path, 'r') as f: content = f.read()
content = content.replace("else if (jenisRaw == 'murajaah' || jenisRaw.contains('muraja')) jenisLabel = \"Muraja'ah\";", "else if (jenisRaw == 'murajaah' || jenisRaw.contains('muraja')) { jenisLabel = \"Muraja'ah\"; }")
content = content.replace("else if (jenisRaw == 'tasmi') jenisLabel = \"Tasmi'\";", "else if (jenisRaw == 'tasmi') { jenisLabel = \"Tasmi'\"; }")
content = content.replace("else jenisLabel = jenisRaw;", "else { jenisLabel = jenisRaw; }")
with open(path, 'w') as f: f.write(content)

# 5. weekly_report_screen.dart
path = 'lib/screens/weekly_report_screen.dart'
with open(path, 'r') as f: content = f.read()
content = content.replace("final teacherName = user?['name']?.toString().toLowerCase() ?? '';", "")
with open(path, 'w') as f: f.write(content)

# 6. supabase_service.dart
path = 'lib/services/supabase_service.dart'
with open(path, 'r') as f: content = f.read()
content = remove_block(content, 'final Map<int, int> halaqohMusyrifMap', is_var=True)
with open(path, 'w') as f: f.write(content)

print("Done")
