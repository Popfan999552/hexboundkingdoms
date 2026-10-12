#!/usr/bin/env python3
"""Import a real screenshot only from a passing, authorized repository QA artifact."""
import json,pathlib,shutil,struct,sys
root=pathlib.Path(sys.argv[1]); reports=list(root.rglob('result.json'))
if len(reports)!=1: raise SystemExit('Expected one unambiguous QA result')
report=json.loads(reports[0].read_text())
if report.get('install_launch_and_functional_roll')!='passed' or report.get('runtime_script_errors')!=0:
 raise SystemExit('Refusing screenshot from failed or unverified QA')
image=reports[0].parent/'android-gameplay.png'; data=image.read_bytes()
if data[:8]!=bytes([137,80,78,71,13,10,26,10]): raise SystemExit('Invalid PNG')
width,height=struct.unpack('>II',data[16:24])
if width<=height or height<400: raise SystemExit('Expected a landscape gameplay capture')
dest=pathlib.Path('google-play-release/screenshots'); dest.mkdir(parents=True,exist_ok=True)
shutil.copyfile(image,dest/'android-emulator-api35.png')
(dest/'android-emulator-api35-qa.json').write_text(json.dumps(report,indent=2))
print('Imported actual Android gameplay screenshot:',width,height)
