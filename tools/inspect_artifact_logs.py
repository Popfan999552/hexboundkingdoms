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
import xml.etree.ElementTree as ET,json
for p in root.rglob('AndroidManifest.xml'):
 try:
  m=ET.parse(p).getroot(); app=m.find('application')
  detail={'permissions':[e.attrib for e in m.findall('permission')],'services':[e.attrib for e in app.findall('service')],'providers':[e.attrib for e in app.findall('provider')]}
  print('::notice title=SDK manifest components::'+json.dumps(detail)[:6000])
 except Exception as exc: print('Manifest inspection failed:',type(exc).__name__)
import re
for p in root.rglob('*logcat.txt'):
 lines=p.read_text(errors='replace').splitlines()
 relevant=[s for s in lines if re.search(r'\s[VDIWEF]\s+godot\s*:|SCRIPT ERROR|FATAL EXCEPTION|Fatal signal',s,re.I)]
 print('::notice title=Android runtime log::'+'\n'.join(relevant[-45:]).replace('%','%25').replace('\n','%0A')[:10000])
