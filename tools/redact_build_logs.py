#!/usr/bin/env python3
"""Remove signing credentials from persistent logs before artifact upload."""
from pathlib import Path
import os,shlex,urllib.parse
names=['GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD','ANDROID_UPLOAD_KEY_PASSWORD','ANDROID_UPLOAD_KEY_BASE64']
values=[os.environ[n] for n in names if os.environ.get(n)]
for path in Path('build/logs').rglob('*'):
 if not path.is_file(): continue
 text=path.read_text(errors='replace')
 for value in values:
  for representation in {value,shlex.quote(value),urllib.parse.quote(value,safe='')}:
   text=text.replace(representation,'[REDACTED]')
 path.write_text(text)
print('Diagnostic logs sanitized for artifact upload.')
