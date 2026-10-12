#!/usr/bin/env python3
"""Assemble current release documents/captures with an already validated offline AAB."""
from pathlib import Path
import hashlib,json,shutil,sys,zipfile
root=Path(sys.argv[1]);audits=list(root.rglob('manifest-audit.json'))
if len(audits)!=1: raise SystemExit('Expected one unambiguous final manifest audit')
audit=json.loads(audits[0].read_text())
if audit.get('bundletool_validation')!='passed' or audit.get('test_ads') or audit.get('permissions'):
 raise SystemExit('This package requires a validated offline no-permission bundle')
if audit.get('target_sdk')!=36 or audit.get('min_sdk')!=26: raise SystemExit('Unexpected SDK levels')
bundles=list(root.rglob('hexbound-unsigned.aab'))
if not bundles: raise SystemExit('Validated unsigned AAB not found')
digests={hashlib.file_digest(p.open('rb'),'sha256').hexdigest() for p in bundles}
if len(digests)!=1: raise SystemExit('Ambiguous AAB copies differ')
dest=Path('google-play-release');shutil.copyfile(bundles[0],dest/'hexbound-unsigned.aab')
(dest/'bundle-provenance.json').write_text(json.dumps({'sha256':next(iter(digests)),'signing':'unsigned; not uploadable to Play','source_manifest_audit':audit},indent=2))
for filename in ['bundle-check.json','manifest-audit.json','AndroidManifest.xml']:
 files=list(root.rglob(filename))
 if len(files)==1: shutil.copyfile(files[0],dest/filename)
Path('build').mkdir(exist_ok=True)
with zipfile.ZipFile('build/google-play-release.zip','w',zipfile.ZIP_DEFLATED) as archive:
 for p in sorted(dest.rglob('*')):
  if p.is_file() and p.suffix!='.import': archive.write(p,p.as_posix())
print('Complete current release package assembled, with unsigned AAB and clean Android capture.')
