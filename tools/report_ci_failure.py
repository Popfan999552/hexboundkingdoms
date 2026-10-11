#!/usr/bin/env python3
"""Expose concise build failure causes as GitHub annotations, without dumping logs."""
from pathlib import Path
import os,re
secret_values=[v for k,v in os.environ.items() if ('PASSWORD' in k or k.endswith('_BASE64')) and v]
paths=sorted(Path('build/logs').glob('*.log'),key=lambda p: (p.name!='manifest-validation.log',p.name!='template-install.log',p.name!='android.log',p.name))
reported=0
for path in paths:
    lines=path.read_text(errors='replace').splitlines()
    errors=[s for s in lines if re.search(r'^(SCRIPT ERROR|ERROR):|Missing SDK|FAIL:|Exception|not found|Unable to|Unexpected|missing|checksum|FAILED|Error:|Traceback|No such file',s) and 'RID allocations' not in s and 'leaked at exit' not in s]
    for line in (errors[-4:] if errors else lines[-3:] if path.name=='manifest-validation.log' else []):
        if reported>=8: break
        reported+=1
        for secret in secret_values: line=line.replace(secret,'[REDACTED]')
        line=line.replace('%','%25').replace('\r','%0D').replace('\n','%0A')
        print(f'::error title={path.name}::{line[:1800]}')
if not list(Path('build/logs').glob('*.log')):
    print('::error::Build failed before log creation; check SDK/JDK prerequisite step output.')
