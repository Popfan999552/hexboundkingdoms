#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Emulator QA failed at line $LINENO: $BASH_COMMAND" >&2' ERR
: "${ANDROID_HOME:?}"
: "${JAVA_HOME:?}"
mkdir -p build/emulator-qa
sdk_manager=$(find "$ANDROID_HOME/cmdline-tools" -type f -path '*/bin/sdkmanager' -print -quit)
avd_manager="$(dirname "$sdk_manager")/avdmanager"
# Use only existing, provider-authorized license acceptance. Never accept new terms.
"$sdk_manager" --sdk_root="$ANDROID_HOME" emulator 'system-images;android-35;default;x86_64' </dev/null
test -f "$ANDROID_HOME/system-images/android-35/default/x86_64/system.img" || { echo 'Emulator image unavailable or its license is not already accepted.' >&2; exit 1; }
export ANDROID_AVD_HOME="$RUNNER_TEMP/hexbound-avd"
mkdir -p "$ANDROID_AVD_HOME"
printf 'no\n' | "$avd_manager" create avd -n HexboundQA -k 'system-images;android-35;default;x86_64' --device pixel --force
if [[ ! -e /dev/kvm ]]; then echo 'Runner does not expose KVM; native emulator testing is unavailable.' >&2; exit 1; fi
sudo chmod a+rw /dev/kvm
"$ANDROID_HOME/emulator/emulator" -avd HexboundQA -no-window -noaudio -no-boot-anim -no-snapshot -gpu swangle -memory 2048 -accel on > build/emulator-qa/emulator.log 2>&1 &
emulator_pid=$!
trap 'kill "$emulator_pid" 2>/dev/null || true; rm -f "$RUNNER_TEMP/qa-debug.jks"' EXIT
adb="$ANDROID_HOME/platform-tools/adb"
"$adb" start-server
booted=false
for attempt in {1..90}; do
 if [[ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]; then booted=true; break; fi
 kill -0 "$emulator_pid" 2>/dev/null || { tail -20 build/emulator-qa/emulator.log >&2; exit 1; }
 sleep 4
done
[[ "$booted" == true ]] || { echo 'Emulator did not boot within the timeout.' >&2; exit 1; }
if [[ -n "${HEXBOUND_REUSE_APKS:-}" ]]; then
 python3 - <<'PY_APK'
import os,pathlib,zipfile
with zipfile.ZipFile(os.environ['HEXBOUND_REUSE_APKS']) as archive:
 pathlib.Path('build/emulator-qa/reused-universal.apk').write_bytes(archive.read('universal.apk'))
PY_APK
 "$adb" install -r build/emulator-qa/reused-universal.apk
else
# Disposable, known-password test key only, never a release/upload credential.
"$JAVA_HOME/bin/keytool" -genkeypair -keystore "$RUNNER_TEMP/qa-debug.jks" -alias androiddebugkey -storepass android -keypass android -dname 'CN=Disposable Test Key' -keyalg RSA -keysize 2048 -validity 2 -noprompt
bundletool="$XDG_CACHE_HOME/bundletool-all-1.18.3.jar"
"$JAVA_HOME/bin/java" -jar "$bundletool" build-apks --bundle=build/hexbound-unsigned.aab --output=build/emulator-qa/test.apks --mode=universal --ks="$RUNNER_TEMP/qa-debug.jks" --ks-key-alias=androiddebugkey --ks-pass=pass:android --key-pass=pass:android
"$JAVA_HOME/bin/java" -jar "$bundletool" install-apks --apks=build/emulator-qa/test.apks --adb="$adb"
fi
"$adb" shell wm size 1920x1080
"$adb" shell settings put secure immersive_mode_confirmations confirmed
"$adb" logcat -c
"$adb" shell monkey -p com.hexboundkingdoms.game -c android.intent.category.LAUNCHER 1
ready=false
for attempt in {1..60}; do
 "$adb" logcat -d > build/emulator-qa/logcat.txt
 if python3 tools/log_contains.py 'ANDROID_QA_GAMEPLAY_READY' build/emulator-qa/logcat.txt; then ready=true; break; fi
 sleep 2
done
[[ "$ready" == true ]] || { echo 'Android gameplay did not report a successful roll and mounted board.' >&2; exit 1; }
if [[ "${HEXBOUND_TEST_ADS:-0}" == 1 ]]; then python3 tools/log_contains.py 'native_ads=true' build/emulator-qa/logcat.txt || { echo 'Native ad plugin failed to register at runtime.' >&2; exit 1; }; fi
app_pid=$(python3 - <<'PY_PID'
from pathlib import Path
import re
lines=Path('build/emulator-qa/logcat.txt').read_text(errors='replace').splitlines()
for line in reversed(lines):
 if 'ANDROID_QA_GAMEPLAY_READY' in line:
  match=re.match(r'\S+\s+\S+\s+(\d+)\s+\d+\s+',line)
  if match: print(match.group(1)); break
PY_PID
)
test -n "$app_pid"
"$adb" shell ps -p "$app_pid" > build/emulator-qa/process.txt
"$adb" logcat -d --pid "$app_pid" > build/emulator-qa/app-logcat.txt
if python3 tools/log_contains.py 'godot.*ERROR:|SCRIPT ERROR|FATAL EXCEPTION|Fatal signal' build/emulator-qa/app-logcat.txt; then echo 'Android app reported a runtime failure.' >&2; exit 1; fi
# Dismiss only the OS fullscreen hint if this Android image still shows it.
"$adb" shell uiautomator dump /sdcard/hexbound-ui.xml >/dev/null
"$adb" pull /sdcard/hexbound-ui.xml build/emulator-qa/ui.xml >/dev/null
hint_point=$(python3 - <<'PY_HINT'
import pathlib,re,xml.etree.ElementTree as ET
for n in ET.parse('build/emulator-qa/ui.xml').getroot().iter('node'):
 if n.get('text')=='Got it' and n.get('package')=='com.android.systemui':
  values=[int(x) for x in re.findall(r'\d+',n.get('bounds',''))]
  if len(values)==4: print((values[0]+values[2])//2,(values[1]+values[3])//2); break
PY_HINT
)
if [[ -n "$hint_point" ]]; then read -r hint_x hint_y <<< "$hint_point"; "$adb" shell input tap "$hint_x" "$hint_y"; fi
sleep 2
"$adb" exec-out screencap -p > build/emulator-qa/android-gameplay.png
"$adb" shell dumpsys activity activities > build/emulator-qa/activity.txt
python3 - <<'PY'
import pathlib,struct,json
p=pathlib.Path('build/emulator-qa/android-gameplay.png'); d=p.read_bytes()
assert d[:8]==b'\x89PNG\r\n\x1a\n' and len(d)>10000
w,h=struct.unpack('>II',d[16:24]); assert w>h and h>=400
report={'android_api':35,'architecture':'x86_64','install_launch_and_functional_roll':'passed','screenshot':[w,h],'runtime_script_errors':0,'physical_device_and_live_ad_tests':'unrun','signing':'disposable debug key, not release'}
pathlib.Path('build/emulator-qa/result.json').write_text(json.dumps(report,indent=2)); print(json.dumps(report,indent=2))
PY
# Do not upload disposable keystores or APK sets signed only for this test.
rm -f build/emulator-qa/test.apks build/emulator-qa/reused-universal.apk
