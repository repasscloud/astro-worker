#!/usr/bin/env bash
set -euo pipefail
source_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ $# != 3 ]]; then
  echo "Usage: probe_android.sh ANDROID_SERIAL SWEPH_PACKAGE_ROOT NDK_CLANG" >&2
  exit 2
fi
serial=$1
package=$2
compiler=$3
source="$package/native/sweph/src"
python3 "$source_dir/probe_native.py" "$package" --verify-only
workspace=$(mktemp -d)
remote=''
cleanup() {
  rm -rf -- "$workspace"
  if [[ "$remote" == /data/local/tmp/astro-swiss.* ]]; then
    adb -s "$serial" shell rm -rf "$remote"
  fi
}
trap cleanup EXIT
sources=()
for name in swecl swedate swehel swehouse swejpl swemmoon swemplan sweph swephlib; do
  sources+=("$source/$name.c")
done
"$compiler" -O2 -fPIE -pie -I "$source" "$source_dir/android_probe.c" "${sources[@]}" -lm -o "$workspace/probe"
remote=$(adb -s "$serial" shell mktemp -d /data/local/tmp/astro-swiss.XXXXXX)
[[ "$remote" == /data/local/tmp/astro-swiss.* ]]
adb -s "$serial" shell mkdir "$remote/ephe" "$remote/empty"
adb -s "$serial" push "$workspace/probe" "$remote/probe" >/dev/null
adb -s "$serial" push "$package/assets/ephe"/{sepl_18,semo_18,seas_18}.se1 "$remote/ephe/" >/dev/null
adb -s "$serial" shell chmod 700 "$remote/probe"
adb -s "$serial" shell "$remote/probe" "$remote/ephe" "$remote/empty"
