#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

# --- CONFIG ---
INPUT_JSON = "manifest.json"
README_MD = "README.md"
START_MARKER = "<!-- Supported Version Table -->"
END_MARKER = "<!-- End Supported Version Table -->"

# --- Load JSON ---
with open(INPUT_JSON) as f:
    data = json.load(f)

# --- Determine PHP versions (descending) ---
php_versions = sorted(data.keys(), key=lambda x: float(x), reverse=True)

# --- Build Magento version -> supported PHP versions map ---
magento_map = {}
for php, value in data.items():
    for version in value.get("magento", []):
        magento_map.setdefault(version, set()).add(php)

# --- Helper to sort Magento versions properly (newest first) ---
def magento_sort_key(v):
    main, *patch = v.split("-p")
    major, minor, patch_main = map(int, main.split("."))
    patch_num = int(patch[0]) if patch else 0
    return (major, minor, patch_main, patch_num)

magento_versions = sorted(magento_map.keys(), key=magento_sort_key, reverse=True)

# --- Build Markdown table ---
header = ["Magento Version"] + php_versions
lines = ["| " + " | ".join(header) + " |",
         "|" + "|".join(["---"] * len(header)) + "|"]

for mver in magento_versions:
    row = [mver] + ["✅" if php in magento_map[mver] else "❌" for php in php_versions]
    lines.append("| " + " | ".join(row) + " |")

table_md = "\n".join(lines)

# --- Replace table in README.md ---
readme_path = Path(README_MD)
content = readme_path.read_text()

pattern = re.compile(
    rf"({re.escape(START_MARKER)}\n)(.*?)(\n{re.escape(END_MARKER)})",
    re.DOTALL
)

new_content, count = pattern.subn(rf"\1{table_md}\3", content)

# --- Write back only if changed ---
if count > 0 and new_content != content:
    readme_path.write_text(new_content)
    sys.exit(1)  # indicate file changed for pre-commit
else:
    sys.exit(0)  # no change
