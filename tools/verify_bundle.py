#!/usr/bin/env python3
"""Structural and native ELF 16-KiB alignment check; not a substitute for bundletool."""
import json, pathlib, struct, sys, zipfile
def check(path):
 with zipfile.ZipFile(path) as z:
  names=z.namelist()
  for entry in ['BundleConfig.pb','base/manifest/AndroidManifest.xml','base/assets/project.binary']:
   if entry not in names: raise ValueError('Missing AAB entry: '+entry)
  libs=[n for n in names if n.startswith('base/lib/') and n.endswith('.so')]
  if not any('/arm64-v8a/' in n for n in libs): raise ValueError('No ARM64 native library')
  for name in libs:
   data=z.read(name)
   if data[:4]!=b'\x7fELF' or data[4]!=2 or data[5]!=1: raise ValueError('Expected little-endian ELF64: '+name)
   phoff=struct.unpack_from('<Q',data,32)[0]; phsize,phnum=struct.unpack_from('<HH',data,54)
   for offset in range(phoff,phoff+phsize*phnum,phsize):
    if struct.unpack_from('<I',data,offset)[0]==1:
     align=struct.unpack_from('<Q',data,offset+48)[0]
     if align<16384: raise ValueError('Native LOAD segment is not 16-KiB aligned: '+name)
  report={'bundle':str(path),'structural_check':'passed','native_libraries':libs,'elf_16k_alignment':'passed','manifest_policy_review':'requires bundletool dump and device testing'}
 pathlib.Path('build/bundle-check.json').write_text(json.dumps(report,indent=2))
 print(json.dumps(report,indent=2))
if __name__=='__main__': check(pathlib.Path(sys.argv[1]))
