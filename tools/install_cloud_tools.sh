#!/usr/bin/env bash
set -euo pipefail
# Debian 13 cloud convenience tools, extracted without modifying the host.
# Apt validates repository signatures and package checksums. No SDK terms accepted.
base=/workspace/.hexbound
mkdir -p "$base/apt/lists/partial" "$base/apt/cache/archives/partial" "$base/apt/downloads"
if [[ -x "$base/jdk/usr/lib/jvm/java-21-openjdk-amd64/bin/javac" && -x "$base/xvfb/usr/bin/Xvfb" ]]; then
 "$base/jdk/usr/lib/jvm/java-21-openjdk-amd64/bin/javac" -version
 exit 0
fi
source /etc/os-release
[[ "$ID" == debian && "$VERSION_ID" == 13 ]] || { echo 'This helper targets Debian 13; provision JDK 21 and Xvfb for your OS.' >&2; exit 1; }
cat > "$base/apt/sources.list" <<'SOURCES'
deb https://deb.debian.org/debian trixie main
SOURCES
apt_opts=(-o "Dir::State::lists=$base/apt/lists" -o "Dir::Cache=$base/apt/cache" -o "Dir::Etc::sourcelist=$base/apt/sources.list" -o Dir::Etc::sourceparts=-)
apt-get "${apt_opts[@]}" update
cd "$base/apt/downloads"
apt-get "${apt_opts[@]}" download openjdk-21-jdk-headless=21.0.12.1+1-1~deb13u1 xvfb=2:21.1.16-1.3+deb13u3 xserver-common=2:21.1.16-1.3+deb13u3 libxfont2 libxkbfile1 x11-xkb-utils
mkdir -p "$base/jdk" "$base/xvfb"
for deb in ./*.deb; do
 if [[ "$deb" == *openjdk* ]]; then dpkg-deb -x "$deb" "$base/jdk"
 else dpkg-deb -x "$deb" "$base/xvfb"; fi
done
# The matching cloud JRE supplies java/lib/modules for locally extracted JDK tools.
cp -a /usr/lib/jvm/java-21-openjdk-amd64/. "$base/jdk/usr/lib/jvm/java-21-openjdk-amd64/"
"$base/jdk/usr/lib/jvm/java-21-openjdk-amd64/bin/javac" -version
