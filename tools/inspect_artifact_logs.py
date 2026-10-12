#!/usr/bin/env python3
"""Read-only inspection of the repository's build/QA artifacts via bounded notices."""
from pathlib import Path
import json,re,struct,sys,xml.etree.ElementTree as ET
root=Path(sys.argv[1])
def notice(title,value):
 text=value if isinstance(value,str) else json.dumps(value)
 text=text[:6000].replace('%','%25').replace('\r','%0D').replace('\n','%0A')
 print(f'::notice title={title}::{text}')
for p in root.rglob('logcat.txt'):
 data=p.read_text(errors='replace'); marks=[s for s in data.splitlines() if 'ANDROID_QA_GAMEPLAY_READY' in s]
 notice('Harness marker checks',{'ready':bool(marks),'native_true':'native_ads=true' in data,'pids':[m.group(1) for s in marks if (m:=re.match(r'\S+\s+\S+\s+(\d+)\s+\d+\s+',s))]})
 relevant=[s for s in data.splitlines() if re.search(r'\s[VDIWEF]\s+godot\s*:|SCRIPT ERROR|FATAL EXCEPTION|Fatal signal',s,re.I)]
 notice('Android runtime log','\n'.join(relevant[-20:]))
files=[p for p in root.rglob('*') if p.is_file() and 'emulator-qa' in str(p)]
if files: notice('Emulator output files',[(p.name,p.stat().st_size) for p in files])
for p in files:
 if p.name in ['process.txt','result.json']: notice(p.name,p.read_text(errors='replace'))
 if p.name=='android-gameplay.png': notice('Screenshot dimensions',struct.unpack('>II',p.read_bytes()[16:24]))
for name in ['emulator-run.log','manifest-validation.log','emulator.log']:
 for p in root.rglob(name): notice(name,'\n'.join(p.read_text(errors='replace').splitlines()[-12:]))
for p in root.rglob('manifest-audit.json'): notice('Manifest audit',json.loads(p.read_text()))
