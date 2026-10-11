#!/usr/bin/env bash
set -euo pipefail
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
"$ANDROID_HOME/emulator/emulator" -avd HexboundQA -no-window -noaudio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -memory 2048 -accel on > build/emulator-qa/emulator.log 2>&1 &
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
# Disposable, known-password test key only, never a release/upload credential.
"$JAVA_HOME/bin/keytool" -genkeypair -keystore "$RUNNER_TEMP/qa-debug.jks" -alias androiddebugkey -storepass android -keypass android -dname 'CN=Disposable Test Key' -keyalg RSA -keysize 2048 -validity 2 -noprompt
bundletool="$XDG_CACHE_HOME/bundletool-all-1.18.3.jar"
"$JAVA_HOME/bin/java" -jar "$bundletool" build-apks --bundle=build/hexbound-unsigned.aab --output=build/emulator-qa/test.apks --mode=universal --ks="$RUNNER_TEMP/qa-debug.jks" --ks-key-alias=androiddebugkey --ks-pass=pass:android --key-pass=pass:android
"$JAVA_HOME/bin/java" -jar "$bundletool" install-apks --apks=build/emulator-qa/test.apks --adb="$adb"
"$adb" shell wm size 1920x1080
"$adb" logcat -c
"$adb" shell monkey -p com.hexboundkingdoms.game -c android.intent.category.LAUNCHER 1
ready=false
for attempt in {1..60}; do
 "$adb" logcat -d > build/emulator-qa/logcat.txt
 if rg -q 'ANDROID_QA_GAMEPLAY_READY' build/emulator-qa/logcat.txt; then ready=true; break; fi
 sleep 2
done
[[ "$ready" == true ]] || { echo 'Android gameplay did not report a successful roll and mounted board.' >&2; exit 1; }
app_pid=$("$adb" shell pidof com.hexboundkingdoms.game | tr -d '\r')
test -n "$app_pid"
"$adb" logcat -d --pid "$app_pid" > build/emulator-qa/app-logcat.txt
if rg -q 'SCRIPT ERROR|FATAL EXCEPTION|Fatal signal' build/emulator-qa/app-logcat.txt; then echo 'Android app reported a runtime failure.' >&2; exit 1; fi
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
rm -f build/emulator-qa/test.apks
