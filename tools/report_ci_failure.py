#!/usr/bin/env python3
"""Expose concise build failure causes as GitHub annotations, without dumping logs."""
from pathlib import Path
import os,re
secret_values=[v for k,v in os.environ.items() if ('PASSWORD' in k or k.endswith('_BASE64')) and v]
for path in sorted(Path('build/logs').glob('*.log')):
    lines=path.read_text(errors='replace').splitlines()
    errors=[s for s in lines if re.search(r'^(SCRIPT ERROR|ERROR):|Missing SDK|FAIL:|Exception|not found|Unable to',s)]
    for line in (errors[-5:] if errors else lines[-3:]):
        for secret in secret_values: line=line.replace(secret,'[REDACTED]')
        line=line.replace('%','%25').replace('\r','%0D').replace('\n','%0A')
        print(f'::error title={path.name}::{line[:1800]}')
if not list(Path('build/logs').glob('*.log')):
    print('::error::Build failed before log creation; check SDK/JDK prerequisite step output.')
