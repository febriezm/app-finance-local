import os
import shutil
import re

root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
web_dir = os.path.join(root_dir, 'web')
build_dir = os.path.join(root_dir, 'build', 'web')

# 1. Salin berkas WASM dan OCR
files_to_copy = ['sql-wasm.js', 'sql-wasm.wasm', 'tesseract.min.js']
for fname in files_to_copy:
    src = os.path.join(web_dir, fname)
    dst = os.path.join(build_dir, fname)
    if os.path.exists(src):
        shutil.copyfile(src, dst)
        print(f"Copied {fname} to build/web")

# 2. Patch flutter_bootstrap.js secara aman (baca dulu, tutup, baru tulis)
bootstrap_path = os.path.join(build_dir, 'flutter_bootstrap.js')
if os.path.exists(bootstrap_path):
    with open(bootstrap_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if len(content.strip()) > 0:
        new_content = re.sub(
            r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]*\}\s*\}\);',
            '_flutter.loader.load();',
            content
        )
        with open(bootstrap_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Patched flutter_bootstrap.js successfully ({len(new_content)} bytes)")
    else:
        print("Warning: flutter_bootstrap.js is empty, build may need to be re-run.")
