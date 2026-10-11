#!/usr/bin/env python3
"""Read-only diagnostic helper for an authorized repository's build artifact."""
from pathlib import Path
import sys
root=Path(sys.argv[1])
logs=sorted(root.rglob('*.log'),key=lambda p:(p.name!='manifest-validation.log',p.name))
for p in logs[:8]:
 text='\n'.join(p.read_text(errors='replace').splitlines()[-15:])
 text=text.replace('%','%25').replace('\r','%0D').replace('\n','%0A')
 print(f'::notice title={p.name}::{text[:6000]}')
for p in root.rglob('manifest-audit.json'):
 print('::notice title=Manifest audit::'+p.read_text().replace('\n','%0A'))
