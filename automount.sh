#! /bin/sh

# Copyright (c) 2011 Slawomir Wojciech Wojtczak (vermaden)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS 'AS IS' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

[ -f /usr/local/etc/automount.conf ] && . /usr/local/etc/automount.conf

: ${MNTPREFIX="/media"}
: ${LOG="/var/log/automount.log"}
: ${STATE="/var/run/automount.state"}
: ${ENCODING="en_US.ISO8859-1"}       # /* US/Canada */
: ${CODEPAGE="cp437"}                 # /* US/Canada */
: ${DATEFMT="%Y-%m-%d %H:%M:%S"}      # /* 2012-02-20 07:49:09 */
: ${USERUMOUNT="NO"}                  # /* when YES add suid bit to umount(8) */
: ${POPUP="NO"}                       # /* display file manager window */
: ${USER="0"}                         # /* which user to use for popup */
: ${FM="0"}                           # /* which file manager to use */

[ "${USERUMOUNT}" = "YES" ] && chmod u+s /sbin/umount # /* WHEEL group member */

__create_mount_point() { # /* 1=DEV */
  mkdir -p ${MNT}
  [ "${USER}" != 0 ] && chown ${USER} ${MNT}
}

__check_already_mounted() { # /* 1=MNT */
  mount | grep " ${1} " 1> /dev/null 2> /dev/null && {
    __log "${DEV}:already mounted (ntfs)"
    exit 0
  }
}

__state_add() { # /* 1=DEV 2=PROVIDER 3=MNT */
  grep -E "${3}$" ${STATE} 1> /dev/null 2> /dev/null && {
    __log "${1}:duplicated '${STATE}'"
    exit 0
  }
  echo "${1} ${2} ${3}" >> ${STATE}
}

__state_remove() { # /* 1=MNT 2=STATE */
  BSMNT=$( echo ${1} | sed 's/\//\\\//g' ) # /* backslash the slashes ;) */
  sed -i '' "/${BSMNT}\$/d" ${2}
}

__log() { # /* @=MESSAGE */
  echo $( date +"${DATEFMT}" ) ${@} >> ${LOG}
}

DEV=/dev/${1}

case ${2} in
  (attach)
    ADD=0
    MNT="${MNTPREFIX}/$( basename ${1} )"
    __check_already_mounted ${MNT}
    __create_mount_point ${DEV}
    case $( file -b -L -s ${DEV} | sed -E 's/label:\ \".*\"//g' ) in
      (*NTFS*)
        dd < ${DEV} count=1 2> /dev/null | strings | head -1 | grep -q "NTFS" && {
          which ntfsfix 1> /dev/null 2> /dev/null && {
            ntfsfix ${DEV} # /* sysutils/ntfsprogs */
          }
          which ntfs-3g 1> /dev/null 2> /dev/null && {
            ntfs-3g -o noatime ${DEV} ${MNT} && ADD=1 # /* sysutils/fusefs-ntfs */
          } || {
            mount_ntfs -o noatime ${DEV} ${MNT} && ADD=1
          }
          __log "${DEV}:mount (ntfs)"
        }
        ;;
      (*FAT*)
        dd < ${DEV} count=1 2> /dev/null | strings | grep -q "FAT32" && {
          fsck_msdosfs -y ${DEV}
          mount_msdosfs -o large -L ${ENCODING} -D ${CODEPAGE} ${DEV} ${MNT} && ADD=1
          __log "${DEV}:mount (fat)"
        }
        ;;
      (*ext2*)
        fsck.ext2 -y ${DEV}
        mount -t ext2fs -o noatime ${DEV} ${MNT} && ADD=1
        __log "${DEV}:mount (ext2)"
        ;;
      (*ext3*)
        fsck.ext3 -y ${DEV}
        mount -t ext2fs -o noatime ${DEV} ${MNT} && ADD=1
        __log "${DEV}:mount (ext3)"
        ;;
      (*ext4*)
        fsck.ext4 -y ${DEV}
        ext4fuse ${DEV} ${MNT} && ADD=1 # /* sysutils/fusefs-ext4fuse */
        __log "${DEV}:mount (ext4)"
        ;;
      (*Unix\ Fast\ File*)
        fsck_ufs -y ${DEV}
        mount -o noatime ${DEV} ${MNT} && ADD=1
        __log "${DEV}:mount (ufs)"
        ;;
      (*)
        case $( dd < ${DEV} count=1 2> /dev/null | strings | head -1 ) in
          (EXFAT)
            mount.exfat -o noatime ${DEV} ${MNT} && ADD=1 # /* sysutils/fusefs-exfat */
            __log "${DEV}:mount (ufs)"
            ;;
        esac
        ;;
    esac
    [ ${ADD} -eq 1 ] && {
      PROVIDER=$( mount | grep -m 1 " ${MNT} " | awk '{printf $1}' )
      __state_add ${DEV} ${PROVIDER} ${MNT}
      [ "${POPUP}" = YES ] && [ "${USER}" != 0 ] && [ "${FM}" != 0 ] \
        && su - ${USER} -c "env DISPLAY=:0 ${FM} ${MNT} &"
      ADD=0
    }
    ;;

  (detach)
    M=$( mount )
    grep -E "${PREFIX}/${1}$" ${STATE} \
      | while read DEV PROVIDER MNT
        do
          TARGET=$( echo "$M" | grep -E "^${PROVIDER} " | awk '{print $3}' )
          __state_remove ${MNT} ${STATE}
          [ -z ${TARGET} ] && continue
          umount -f ${TARGET} &
          unset TARGET
          __log "${DEV}:umount"
        done
    __log "${DEV}:detach"
    ;;

esac

find ${MNTPREFIX} -type d -empty -delete
