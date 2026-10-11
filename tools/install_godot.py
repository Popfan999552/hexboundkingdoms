#!/usr/bin/env python3
"""Pinned Godot binaries/templates. No SDK licenses are accepted here."""
import hashlib, os, pathlib, urllib.request, zipfile, argparse
VERSION='4.6.3'
ENGINE_SHA256='d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3'
FILES={
 'Godot_v4.6.3-stable_export_templates.tpz':'3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8',
}
def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--engine',action='store_true'); parser.add_argument('--cache',default='/tmp/hexbound-downloads'); args=parser.parse_args()
    cache=pathlib.Path(args.cache); cache.mkdir(parents=True,exist_ok=True)
    files=dict(FILES)
    if args.engine: files['Godot_v4.6.3-stable_linux.x86_64.zip']=ENGINE_SHA256
    for name,digest in files.items():
        path=cache/name
        if not path.exists():
            urllib.request.urlretrieve(f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/{name}',path)
        if hashlib.file_digest(path.open('rb'),'sha256').hexdigest()!=digest: raise SystemExit('Checksum mismatch: '+name)
        with zipfile.ZipFile(path) as z:
            if name.endswith('.tpz'):
                dest=pathlib.Path(os.environ.get('XDG_DATA_HOME',str(pathlib.Path.home()/'.local/share')))/'godot/export_templates/4.6.3.stable'; dest.mkdir(parents=True,exist_ok=True)
                for item in ['android_source.zip','android_debug.apk','android_release.apk','linux_debug.x86_64','linux_release.x86_64','version.txt']:
                    (dest/item).write_bytes(z.read('templates/'+item))
            else:
                dest=cache/'bin'; dest.mkdir(exist_ok=True)
                exe=dest/'godot'; exe.write_bytes(z.read('Godot_v4.6.3-stable_linux.x86_64')); exe.chmod(0o755)
                print('Godot executable:',exe)
    print('Godot 4.6.3 templates verified and installed')
if __name__=='__main__': main()
