#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023-present Team CoreELEC (https://coreelec.org)

# get coreelec release information
source /etc/os-release

message() {
  >&2 echo "${@}"
}

# Return 1 if given kernel version is lower than current dovi.ko module version
check_dovi_version() {
    version_higher=$(modinfo $1 | awk '/vermagic:/ {split($2, ver, "-"); print ver[1]}' | awk -F '.' \
      -v ker_ver=$2 -v maj_ver=$3 -v min_ver=$4 '{
        if ($1 > ker_ver) { print "Y"; }
        else if ($1 < ker_ver) { print "N"; }
        else {
          if ($2 > maj_ver) { print "Y"; }
          else if ($2 < maj_ver) { print "N"; }
          else {
            if ($3 >= min_ver) { print "Y"; }
            else { print "N"; }
          }
        }
      }')

    if [ "$version_higher" = "Y" ]; then
      return 0
    else
      return 1
    fi
}

load_dovi_ne() {
  # if mounted from tee-loader don't mount/unmount from dovi-loader
  if ! ls /dev/mapper/dynpart-* &>/dev/null; then
    dmsetup create --concise "$(parse-android-dynparts /dev/super)"
    systemctl set-environment dmsetup_remove=yes
  fi

  local active_slot=$(fw_printenv active_slot 2>/dev/null | awk -F '=' '/active_slot=/ {print $2}')
  [ "${active_slot}" = "normal" ] && active_slot="" || active_slot="_a"

  if [ -b /dev/mapper/dynpart-odm${active_slot} ]; then
    mountpoint -q /android/odm || mount -o ro /dev/mapper/dynpart-odm${active_slot} /android/odm

    DOVI_KO_ANDROID="/android/odm/lib/modules/dovi.ko"
    DOVI_KO_STORAGE="/storage/dovi.ko"

    if [ -f ${DOVI_KO_ANDROID} ]; then
      modinfo ${DOVI_KO_ANDROID}

      if [ -f ${DOVI_KO_STORAGE} ]; then
        message "loading dovi module from ce storage partition"
        modinfo ${DOVI_KO_STORAGE}
        insmod ${DOVI_KO_STORAGE}
      elif check_dovi_version ${DOVI_KO_ANDROID} 5 4 210; then
        message "loading dovi module from android partition"
        insmod ${DOVI_KO_ANDROID}
      else
        cat > /tmp/dovi.message << 'EOF'
[TITLE]CoreELEC Dolby Vision Media Playback[/TITLE]
[B][COLOR red]Android Dolby Vision kernel module is not compatible[/COLOR][/B]
[COLOR red]No Dolby Vision media playback possible![/COLOR]

Please upgrade Android firmware of your device to minimum Linux kernel version '5.4.210'.
Dolby Vision media will be displayed in HDR instead Dolby Vision until the firmware fulfill the minimum requirements.
EOF
      fi

      return
    fi
  fi

  cleanup_dovi_ne
}

cleanup_dovi_ne() {
  rmmod dovi 2>/dev/null
  mountpoint -q /android/odm && umount /android/odm
  # unmount only if mounted from this script
  [ "${dmsetup_remove}" = "yes" ] && \
    ls /dev/mapper/dynpart-* &>/dev/null && dmsetup remove /dev/mapper/dynpart-*
}

load_dovi_ng() {
  mountpoint -q /android/vendor || mount -o ro /dev/vendor /android/vendor
  DOVI_KO="/android/vendor/lib/modules/dovi.ko"
  if [ -f ${DOVI_KO} ]; then
    message "loading dovi module"
    modinfo ${DOVI_KO}
    insmod  ${DOVI_KO}
    return
  fi

  cleanup_dovi_ng
}

cleanup_dovi_ng() {
  rmmod dovi 2>/dev/null
  mountpoint -q /android/vendor && umount /android/vendor
}

message "run dovi '${1}' for ${COREELEC_DEVICE:8:2}"

case "${1}" in
  start)
    load_dovi_${COREELEC_DEVICE:8:2}
    ;;
  stop)
    cleanup_dovi_${COREELEC_DEVICE:8:2}
    ;;
esac

exit 0
