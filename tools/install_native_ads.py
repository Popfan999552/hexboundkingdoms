#!/usr/bin/env python3
"""Install pinned Android plugin binaries with TLS and SHA-256 verification."""
import hashlib, io, pathlib, urllib.request, zipfile
URL='https://github.com/poingstudios/godot-admob-plugin/releases/download/v5.1.0/android-template-v4.6.3.zip'
SHA256='f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee'
def main():
    data=urllib.request.urlopen(URL,timeout=90).read()
    if hashlib.sha256(data).hexdigest()!=SHA256:
        raise SystemExit('AdMob artifact checksum mismatch; refusing installation')
    root=pathlib.Path(__file__).resolve().parents[1]/'addons/admob/android/bin'
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for item in archive.infolist():
            # No mediation SDKs. Ads package contains the UMP bindings as well.
            if not (item.filename=='package.gd' or item.filename.startswith('ads/')): continue
            path=root/item.filename
            if root.resolve() not in path.resolve().parents: raise SystemExit('Unsafe archive path')
            if item.is_dir(): path.mkdir(parents=True,exist_ok=True)
            else: path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(archive.read(item))
    print('Verified Poing AdMob v5.1.0 Android 4.6.3 ads/UMP binaries installed')
if __name__=='__main__': main()
