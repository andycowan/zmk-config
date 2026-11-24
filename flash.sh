#!/bin/bash
# Flash both Corne halves on macOS: run `bash flash.sh` from the firmware
# download folder, then double-tap reset on each half (any order).
# Halves are identified by their nice!nano USB serial number, so the
# identical "NICENANO" drive names don't matter.
set -u
cd "$(dirname "$0")"

LEFT_SERIAL=9545D68796F9030F
RIGHT_SERIAL=D150D2CCB40B890F
LEFT_FW="corne_left nice_view_adapter nice_view-nice_nano__zmk-zmk.uf2"
RIGHT_FW="corne_right nice_view_adapter nice_view-nice_nano__zmk-zmk.uf2"

for f in "$LEFT_FW" "$RIGHT_FW"; do
  [ -f "$f" ] || { echo "Missing firmware: $f"; exit 1; }
done

left_done= right_done= warned=
echo "Double-tap reset on each half to flash it (Ctrl-C to stop)."
until [ -n "$left_done" ] && [ -n "$right_done" ]; do
  # "serial disk" for every nice!nano currently in bootloader mode.
  while read -r serial disk; do
    case $serial in
      "$LEFT_SERIAL") side=left fw=$LEFT_FW ;;
      "$RIGHT_SERIAL") side=right fw=$RIGHT_FW ;;
      *)
        case $warned in *"$serial"*) ;; *) echo "Unknown nice!nano $serial - skipping"; warned="$warned $serial" ;; esac
        continue ;;
    esac
    mnt=$(diskutil info "$disk" 2>/dev/null | sed -n 's/^ *Mount Point: *//p')
    [ -d "$mnt" ] || continue # not mounted yet

    echo "Flashing $side half..."
    # The board reboots as soon as the copy lands, so cp often reports an error.
    cp -X "$fw" "$mnt/" 2>/dev/null
    for _ in $(seq 20); do [ -e "/dev/$disk" ] || break; sleep 0.5; done
    if [ -e "/dev/$disk" ]; then
      echo "  $side half did not restart - flash may have failed."
    else
      echo "  $side half done."
      eval "${side}_done=1"
    fi
  done < <(ioreg -r -l -w0 -n 'nice!nano v2' |
    awk -F'"' '$2 == "USB Serial Number" { s = $4 } $2 == "BSD Name" && $4 ~ /^disk[0-9]+$/ { print s, $4 }' | sort -u)
  sleep 1
done
echo "Both halves flashed."
