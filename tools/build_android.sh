#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${ANDROID_HOME:?Set ANDROID_HOME to an installed, licensed Android SDK}"
: "${JAVA_HOME:?Set JAVA_HOME to JDK 17 or newer (21 recommended)}"
test -x "$JAVA_HOME/bin/javac" || { echo 'A full JDK is required, not just a Java runtime.' >&2; exit 1; }
for item in platforms/android-36/android.jar build-tools/36.1.0/aapt2 platform-tools/adb; do
  test -f "$ANDROID_HOME/$item" || { echo "Missing SDK component: $item. Owner must accept Android SDK terms before installation." >&2; exit 1; }
done
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-/workspace/.hexbound/android-user}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-/workspace/.hexbound/gradle}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.hexbound/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.hexbound/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.hexbound/cache}"
mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME" build/logs
if [[ "${HEXBOUND_TEST_ADS:-0}" == 1 ]]; then python3 tools/install_native_ads.py; fi
./tools/check.sh
# CI calls this on a fresh disposable checkout. Restore the tracked preset and remove
# only our local override on exit; never store signing secrets in either file.
export_preset_backup=$(mktemp)
cp export_presets.cfg "$export_preset_backup"
if [[ -e override.cfg ]]; then echo 'Existing override.cfg found; preserve it and use a clean checkout for release.' >&2; rm "$export_preset_backup"; exit 1; fi
trap 'cp "$export_preset_backup" export_presets.cfg; rm -f "$export_preset_backup" override.cfg' EXIT
./tools/godot.sh --headless --editor --path . --script tools/configure_export.gd 2>&1 | tee build/logs/configure.log
python3 - <<'PY'
import os,pathlib,zipfile
base=pathlib.Path(os.environ['XDG_DATA_HOME'])/'godot/export_templates/4.6.3.stable/android_source.zip'
if not base.is_file(): raise SystemExit('Godot Android source template missing: run tools/install_godot.py')
target=pathlib.Path('android/build'); target.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(base) as archive:
 for entry in archive.infolist():
  path=target/entry.filename
  if target.resolve() not in path.resolve().parents: raise SystemExit('Unsafe template path')
  if entry.is_dir(): path.mkdir(parents=True,exist_ok=True)
  else: path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(archive.read(entry))
(target/'gradlew').chmod(0o755)
pathlib.Path('android/.build_version').write_text('4.6.3.stable')
PY
output="build/hexbound-unsigned.aab"
if [[ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]]; then output="build/hexbound-signed.aab"; fi
./tools/godot.sh --headless --path . --export-release Android "$output" 2>&1 | tee build/logs/android.log
if rg -q '^(SCRIPT ERROR|ERROR):' build/logs/android.log; then echo 'Android export reported errors.' >&2; exit 1; fi
test -s "$output"
python3 tools/verify_bundle.py "$output"
if [[ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]]; then
 "$JAVA_HOME/bin/jarsigner" -verify "$output" > build/logs/signature.log
 rg -q 'jar verified' build/logs/signature.log || { echo 'Bundle signature verification failed.' >&2; exit 1; }
fi
cp "$output" google-play-release/
echo "Built $output. Unsigned builds cannot be uploaded to Play. No publishing performed."
