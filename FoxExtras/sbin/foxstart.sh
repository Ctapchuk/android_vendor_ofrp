#!/sbin/sh
#
# 	/sbin/foxstart.sh
# 	Custom script for OrangeFox Recovery
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2018-2021 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#
#
# * Author: DarthJabba9
# * Date:   20211223
# * Identify some ROM features and hardware components
# * Do some other sundry stuff
#
#
SCRIPT_LASTMOD_DATE="20211223"
C="/tmp_cust"
LOG="/tmp/recovery.log"
LOG2="/sdcard/foxstart.log"
DEBUG="0"  	  # enable for more debug messages
VERBOSE_DEBUG="0" # enable for really verbose debug messages
SYS_ROOT="0"	  # do we have system_root?
SAR="0"	  	  # SAR set up properly in recovery?
ADJUST_VENDOR="0" # enable to remove /vendor from fstab if not needed
ADJUST_CUST="0"   # enable to remove /cust from fstab if not needed
ANDROID_SDK="21"  # assume at least (and no more than) Lollipop in sdk checks
MOUNT_CMD="mount -r" # only mount in readonly mode
SUPER="0" # whether the rdevice has a "super" partition
OUR_TMP="/FFiles/temp" # our "safe" temp directory

# etc dir
if [ -h /etc ]; then 
   ETC_DIR=$(readlink /etc)
else
   ETC_DIR=/etc
   [ ! -e $ETC_DIR ] && ETC_DIR=/system/etc
   [ ! -e $ETC_DIR ] && ETC_DIR=/etc
fi
CFG="$ETC_DIR/orangefox.cfg"

# fstab
FS="$ETC_DIR/twrp.fstab"
[ ! -f $FS ] && FS="$ETC_DIR/recovery.fstab"

FOX_DEVICE=$(getprop "ro.product.device")
SETPROP=/sbin/setprop
[ ! -e "$SETPROP" ] && SETPROP=/system/bin/setprop

T=0
M=0
ROM=""

# verbose logging?
if [ "$VERBOSE_DEBUG" = "1" ]; then
   DEBUG=1
   set -o xtrace
fi

# extra logs to /sdcard/foxstart.log
extralog() {
 [ "$VERBOSE_DEBUG" != "1" ] && return
 local D=$(date)
 [ ! -f $LOG2 ] && {
    echo "---- extra logs for foxstart.sh ----" > $LOG2
 }
 echo "[$D]:= $@" >> $LOG2

 # copy also the main logs
 cp $LOG /sdcard/
 [ ! -f /sdcard/dmesg.log ] && cp -a /tmp/dmesg.log /sdcard/
}

# partition mountpoints
SYSTEM_BLOCK=/dev/block/bootdevice/by-name/system
VENDOR_BLOCK=/dev/block/bootdevice/by-name/vendor
if [ "$(getprop ro.boot.dynamic_partitions)" = "true" -o "$(getprop orangefox.super.partition)" = "true" ]; then
   SUPER="1"
   tmp01=$(getprop orangefox.system.block_device)
   [ -z "$tmp01" ] && tmp01=$(cat /etc/fstab | grep "/system" | cut -f1 -d" ")
   [ -n "$tmp01" ] && SYSTEM_BLOCK="$tmp01"
   tmp01=$(getprop orangefox.vendor.block_device)
   [ -z "$tmp01" ] && tmp01=$(cat /etc/fstab | grep "/vendor" | cut -f1 -d" ")
   [ -n "$tmp01" ] && VENDOR_BLOCK="$tmp01"
fi

# file_getprop <file> <property>
file_getprop() 
{ 
  local F=$(grep -m1 "^$2=" "$1" | cut -d= -f2)
  echo $F | sed 's/ *$//g'
}

#  some optional debug message stuff
DebugDirList() {
   [ ! "$DEBUG" = "1" ] && return
   echo "DEBUG: OrangeFox: directory list of $1" >> $LOG
   ls -all $1 >> $LOG
}

# optional debug message
DebugMsg() {
   [ ! "$DEBUG" = "1" ] && return
   echo "DEBUG: OrangeFox: $@" >> $LOG
   extralog "$@"
}

# is the directory mounted?
is_mounted() {
  grep -q " `readlink -f $1` " /proc/mounts 2>/dev/null
  return $?
}

# is it a treble ROM ?
Has_Treble_Dirs() {
local D="$1"
  if [ -d $D/app ] && [ -d $D/bin ] && [ -d $D/etc ] && [ -d $D/firmware ] && [ -d $D/lib64 ]; then
    echo "1"
  else
    echo "0"
  fi	
}

realTreble() {
local CC=/tmp_vendor
local V=$VENDOR_BLOCK
  [ ! -e $V ] && {
    echo "0"
    return
  }
  mkdir -p $CC > /dev/null 2>&1
  $MOUNT_CMD -t ext4 $V $CC > /dev/null 2>&1
  local R=$(Has_Treble_Dirs $CC)
  umount $CC > /dev/null 2>&1
  rmdir $CC > /dev/null 2>&1
  echo $R
}

isTreble() {
local TT=$(realTreble)
  echo "REALTREBLE=$TT" >> $CFG
  echo "" >> $LOG
  echo "DEBUG: OrangeFox: REALTREBLE=$TT" >> $LOG
  [ "$TT" = "1" ] && {
     $SETPROP orangefox.realtreble.rom 1 > /dev/null 2>&1
     echo "1"
     return
  }
  $SETPROP orangefox.realtreble.rom 0  > /dev/null 2>&1

  # try /cust
local C="/tmp_cust"
  mkdir -p $C > /dev/null 2>&1
  $MOUNT_CMD -t ext4 /dev/block/bootdevice/by-name/cust $C > /dev/null 2>&1 
  T=$(Has_Treble_Dirs $C)
  DebugDirList "$C/"
  DebugDirList "$C/app/"
  umount $C > /dev/null 2>&1
  rmdir $C > /dev/null 2>&1
  echo "$T"
}

# do we have system_root?
has_system_root() {
  local F=$(getprop "ro.build.system_root_image" 2>/dev/null)
  local F2=$(getprop "ro.twrp.sar" 2>/dev/null)
  local F3=$(cat $ETC_DIR/fstab | grep "/system_root" | cut -f2 -d" " 2>/dev/null)
  [ "$F" = "true" -o "$F2" = "true" -o "$F3" = "/system_root" ] && echo "1" || echo "0"
}

# Is this set up properly as SAR?
is_SAR() {
  local F=$(getprop "ro.build.system_root_image")
  [ "$F" = "true" ] && {
    echo "1"
    return  
  }

  F=$(grep -s "/system_root" "$ETC_DIR/fstab")
  [ -n "$F" ] && {
     echo "1"
     return
  }
  
  [ -L "/system" -a -d "/system_root" ] && {
    echo "1"
    return
  }

  F=$(grep -s "/system_root" "/proc/mounts")
  [ -n "$F" ] && {
     echo "1"
     return
  }
  
  F=$(getprop ro.twrp.sar)
  [ "$F" = "true" ] && echo "1" || echo "0"
}

# try to identify the installed ROM, and some ROM information
get_ROM() {
local S="/tmp_system_rom"
local PROP="$S/build.prop"
local V="/vendor"
local V_PROP="$V/build.prop"
local found_vendor_prop="0"
local slot=$(getprop "ro.boot.slot_suffix")

   # if not there already
   mkdir -p $OUR_TMP
   
   # mount /system and check
   if [ -d "$S" ]; then
      DebugMsg "$S already exists"
      umount $S > /dev/null 2>&1
   else
      DebugMsg "Creating $S"
      mkdir -p $S
   fi
   
   # mount
   $MOUNT_CMD -t ext4 $SYSTEM_BLOCK"$slot" $S > /dev/null 2>&1
   
   # look for build.prop
   [ ! -e "$PROP" ] && PROP="$S/system/build.prop" # test for SAR
   
   # have we found a proper build.prop ?
   [ ! -e $PROP ] && {
      umount $S > /dev/null 2>&1
      rmdir $S > /dev/null 2>&1
      echo "DEBUG: OrangeFox: error - I cannot find the system build.prop" >> $LOG
      echo ""
      return
   }
   
   # - make a copy of the system build.prop
   cp $PROP "$OUR_TMP/system_build_prop" > /dev/null 2>&1
   PROP="$OUR_TMP/system_build_prop"
   umount $S > /dev/null 2>&1
   rmdir $S > /dev/null 2>&1
   
   # now look for vendor prop
   local mv1="0"
   [ ! -d "$V" ] && mkdir -p $V > /dev/null 2>&1
   if [ -d "$V" ]; then
      ! is_mounted $V && {
         $MOUNT_CMD $V > /dev/null 2>&1
         is_mounted $V && mv1="1"
      }
      is_mounted $V && {
         [ -f $V_PROP ] && {
           found_vendor_prop=1
           # make a copy of the vendor build.prop
           cp $V_PROP "$OUR_TMP/vendor_build_prop" > /dev/null 2>&1
           V_PROP="$OUR_TMP/vendor_build_prop"
           [ "$mv1" = "1" ] && umount $V > /dev/null 2>&1
         }
      }
   fi
   
   # use the vendor prop if found
   [ "$found_vendor_prop" != "1" ] && V_PROP=""

   # query the build.prop
   local tmp2=""
   tmp2=$(file_getprop "$PROP" "ro.build.display.id")
   [ -n "$V_PROP" -a  -z "$tmp2" ] && tmp2=$(file_getprop "$V_PROP" "ro.vendor.build.id")
   [ -z "$tmp2" ] && tmp2=$(file_getprop "$PROP" "ro.build.id")
   [ -z "$tmp2" ] && tmp2=$(file_getprop "$PROP" "ro.system.build.id")
   
   # ROM not found?
   if [ -z "$tmp2" ]; then
      echo "DEBUG: OrangeFox: I cannot find the ROM information!" >> $LOG
      echo ""
      return
   fi
   
   # we have a ROM - get SDK, etc
   local tmp3=""
   if [ -n "$tmp2" ]; then
      [ -n "$V_PROP" ] && tmp3=$(file_getprop "$V_PROP" "ro.vendor.build.version.sdk") 
      [ -z "$tmp3" ] && ttmp3=$(file_getprop "$PROP" "ro.build.version.sdk")
      [ -z "$tmp3" ] && tmp3=$(file_getprop "$PROP" "ro.system.build.version.sdk")
      [ -n "$tmp3" ] && {
         ANDROID_SDK="$tmp3"
         $SETPROP orangefox.rom.sdk "$tmp3" > /dev/null 2>&1
         echo "DEBUG: OrangeFox: ANDROID_SDK=$ANDROID_SDK" >> $LOG
         echo "ANDROID_SDK=$ANDROID_SDK" >> $CFG
      }

      # get incremental version
      [ -n "$V_PROP" ] && tmp3=$(file_getprop "$V_PROP" "ro.vendor.build.version.incremental")
      [ -z "$tmp3" ] && tmp3=$(file_getprop "$PROP" "ro.build.version.incremental")
      [ -z "$tmp3" ] && tmp3=$(file_getprop "$PROP" "ro.system.build.version.incremental")
      [ -n "$tmp3" ] && {
        echo "DEBUG: OrangeFox: INCREMENTAL_VERSION=$tmp3" >> $LOG
        echo "INCREMENTAL_VERSION=$tmp3" >> $CFG
        [ -x "$SETPROP" ] && {
              $SETPROP "ro.build.version.incremental" "$tmp3" > /dev/null 2>&1
              $SETPROP "orangefox.system.incremental" "$tmp3" > /dev/null 2>&1
        }
      }

      # get "release" version
      [ -n "$V_PROP" ] && tmp3=$(file_getprop "$V_PROP" "ro.vendor.build.version.release")
      [ -z "$tmp3" ] && tmp3=$(file_getprop "$PROP" "ro.build.version.release")
      [ -z "$tmp3" ] && tmp3=$(file_getprop "$PROP" "ro.system.build.version.release")
      [ -n "$tmp3" ] && {
        echo "DEBUG: OrangeFox: RELEASE_VERSION=$tmp3" >> $LOG
        echo "RELEASE_VERSION=$tmp3" >> $CFG
        [ -x "$SETPROP" ] && {
              $SETPROP "ro.build.version.release" "$tmp3" > /dev/null 2>&1
              $SETPROP "orangefox.system.release" "$tmp3" > /dev/null 2>&1
        }
      }
      
      # and other stuff
      tmp3=$(file_getprop "$PROP" "ro.build.flavor")
      [ -n "$tmp3" ] && {
           echo "DEBUG: OrangeFox: BUILD_FLAVOR=$tmp3" >> $LOG
           echo "BUILD_FLAVOR=$tmp3" >> $CFG
      }
   fi

   # check for ROM fingerprints
   local FP=""
   if [ -n "$tmp2" ]; then
      [ -n "$V_PROP" ] && FP=$(file_getprop "$V_PROP" "ro.vendor.build.fingerprint")
      [ -z "$FP" ] && FP=$(file_getprop "$PROP" "ro.build.version.base_os")
      [ -z "$FP" ] && FP=$(file_getprop "$PROP" "ro.build.fingerprint")
      [ -z "$FP" ] && FP=$(file_getprop "$PROP" "ro.system.build.fingerprint")
      [ -n "$FP" ] && {
           echo "ROM_FINGERPRINT=$FP" >> $CFG
           echo "DEBUG: OrangeFox: ROM_FINGERPRINT=$FP" >> $LOG
           [ -x "$SETPROP" ] && {
              $SETPROP "ro.build.fingerprint" "$FP" > /dev/null 2>&1
              $SETPROP "orangefox.system.fingerprint" "$FP" > /dev/null 2>&1
            }
      }
   fi # check for ROM fingerprints
   
   # return
   echo "$tmp2"
}

# is it miui ?
isMIUI() {
   local M="0"
   local S="/tmp_system"
   local A="$S/app"
   local E="$S/etc"
   local S_SAR="$S/system"
   local slot=$(getprop "ro.boot.slot_suffix")
   
   # mount /system and check
   if [ -d "$S" ]; then
      DebugMsg "$S already exists"
      umount $S > /dev/null 2>&1
   else
      DebugMsg "Creating $S"
      mkdir -p $S
   fi

   $MOUNT_CMD -t ext4 $SYSTEM_BLOCK"$slot" $S > /dev/null 2>&1
   
   DebugDirList "$S/"
   DebugDirList "$S/vendor"

   DebugDirList "$A/"
   DebugDirList "$E/"
   
   if [ -f $S/init.miui.cust.rc ] && [ -f $S/init.miui.rc ]; then
      DebugMsg "First round of miui checks succeeded."
      M="1"
   else
      DebugMsg "First round of miui checks returned negative."
   fi

   [ "$M" != "1" ] && {
      if [ -d $A/miui ] && [ -d $A/miuisystem ]; then
         DebugMsg "Second round of miui checks succeeded."
         M="1"
     else
         DebugMsg "Second round of miui checks returned negative."
     fi
   }

   [ "$M" != "1" ] && {
      if [ -d $E/cust ] && [ -d $E/miui_feature ] && [ -d $E/precust_theme ]; then
      	 DebugMsg "Third round of miui checks succeeded."
      	 M="1"
      else
      	 DebugMsg "Third round of miui checks returned negative."
      	 E="$S_SAR/etc"
      	 if [ -d $E/cust ] && [ -d $E/miui_feature ] && [ -d $E/precust_theme ]; then
           DebugMsg "Fourth round of miui checks succeeded."
           M="1"
      	 else
           DebugMsg "Fourth round of miui checks returned negative."
      	 fi
      fi
   }
   
   # unmount
   umount $S > /dev/null 2>&1
   rmdir $S
   
   echo "$M"
}

# probe the installed ROM
Get_Details() {
   # check for Treble
   T=$(isTreble)

   # check for MIUI
   M=$(isMIUI)

   # look for installed ROM
   ROM=$(get_ROM)
}

# remove /cust or /vendor from fstab
mod_cust_vendor() {
  if [ "$1" = "1" ]; then # treble - remove /cust
     [ "$ADJUST_CUST" = "1" ] && {
     	D="$D Removing \"/cust\" from $FS"
     	sed -i -e 's|^/cust|##/cust|' $FS
     }
  else # non-treble -remove /vendor
     [ "$ADJUST_VENDOR" = "1" ] && {
     	D="$D  Removing \"/vendor\" from $FS"
     	sed -i -e "s|^/vendor|##/vendor|g" $FS
     }
  fi
}

# report on Treble
Treble_Action() {
   echo "DEBUG: OrangeFox: check for Treble." >> $LOG
   if [ -z "$ROM" ]; then
      echo "DEBUG: OrangeFox: detected no ROM" >> $LOG
      echo "TREBLE=0" >> $CFG
      return
   fi   
   if [ "$T" = "1" ]; then
      D="DEBUG: OrangeFox: detected a Treble ROM."
   else
      D="DEBUG: OrangeFox: detected a Non-Treble ROM."
   fi
   mod_cust_vendor "$T"
   echo $D >> $LOG
   echo "TREBLE=$T" >> $CFG
   echo "ROM=$ROM" >> $CFG
}

# report on MIUI and take action
MIUI_Action() {
   echo "DEBUG: OrangeFox: check for MIUI." >> $LOG
   if [ -z "$ROM" ]; then
      echo "MIUI=0" >> $CFG
      return
   fi
   D="DEBUG: OrangeFox: detected a Custom ROM."
   if [ "$M" = "1" ]; then
      D="DEBUG: OrangeFox: detected a MIUI ROM"
      if [ "$T" = "1" ]; then
         D="$D (Treble)"
      fi
      D=$D"."
   fi
  echo $D >> $LOG
  echo "MIUI=$M" >> $CFG
  $SETPROP orangefox.miui.rom "$M" > /dev/null 2>&1
}

# backup (or restore) fstab
backup_restore_FS() {
   if [ ! -f "$FS.org" ]; then
      cp -a "$FS" "$FS.org"
   else   
      cp -a "$FS.org" "$FS"
   fi
}

# fix yellow flashlight on mido/vince/kenzo and configure Leds on others
flashlight_Leds_config() {
   case "$FOX_DEVICE" in
       vince)
   		echo "0" > /sys/devices/soc/qpnp-flash-led-24/leds/led:torch_1/max_brightness;
       	;;
       riva)
            	echo 1 > /sys/class/leds/flashlight/max_brightness;
            	echo 0 > /sys/class/leds/flashlight/brightness;
         ;;
       *)
       		return;
       	;;
   esac

   echo "0" > /sys/class/leds/led:torch_1/max_brightness
   echo "0" > /sys/class/leds/torch-light1/max_brightness
   echo "0" > /sys/class/leds/led:flash_1/max_brightness
}

# start, and mark that we have started
start_script()
{
local OPS=$(getprop "orangefox.postinit.status")
local fox_cfg="$ETC_DIR/fox.cfg"
   [ -f "$CFG" ] || [ "$OPS" = "1" ] && exit 0
   echo "# OrangeFox live cfg" > $CFG
   [ ! -e $fox_cfg ] && {
      fox_cfg="/system/etc/fox.cfg"
      [ ! -e $fox_cfg ] && fox_cfg="/etc/fox.cfg"
   }
   local D=$(file_getprop "$fox_cfg" "FOX_BUILD_DATE")
   [ -z "$D" ] && D=$(getprop "ro.bootimage.build.date")
   [ -z "$D" ] && D=$(getprop "ro.build.date")
   OPS=$(uname -r)
   SYS_ROOT=$(has_system_root)
   [ "$SYS_ROOT" = "1" ] && SAR=$(is_SAR)
   echo "KERNEL=$OPS" >> $CFG
   echo "SYSTEM_ROOT=$SYS_ROOT" >> $CFG
   echo "PROPER_SAR=$SAR" >> $CFG
   echo "FOX_BUILD_DATE=$D" >> $CFG
   echo "FOX_BUILD_DATE=$D" >> $LOG
   echo "DEBUG: OrangeFox: FOX_DEVICE=$FOX_DEVICE" >> $LOG
   echo "DEBUG: OrangeFox: FOX_KERNEL=$OPS" >> $LOG
   echo "DEBUG: OrangeFox: SYSTEM_ROOT=$SYS_ROOT" >> $LOG
   echo "DEBUG: OrangeFox: PROPER_SAR=$SAR" >> $LOG
   echo "DEBUG: OrangeFox: FOX_SCRIPT_DATE=$SCRIPT_LASTMOD_DATE" >> $LOG
   $SETPROP orangefox.postinit.status 1
   $SETPROP ro.orangefox.sar "$SAR"
   $SETPROP ro.orangefox.kernel "$OPS"
   
   # if someone is still using old recovery sources
   ln -s $CFG /tmp/orangefox.cfg
}

# cater for situations where setprop is a dead symlinked applet
get_setprop() {
local TPROP=""
  $SETPROP > /dev/null 2>&1
  [ $? == 0 ] && return
  TPROP=/sbin/resetprop
  [ ! -x "$TPROP" ] && TPROP=/system/bin/resetprop
  [ -x "$TPROP" ] && {
    rm -f $SETPROP
    ln -sf $TPROP $SETPROP
    return
  }
}

# try to get display panel information
Get_Display_Panel() {
local F1="Panel Name = "
local F2="Successfully bind display panel "
local GREP="grep -m 1"
local pname=""
local F3=""
local KLOG="/tmp/dmesg.log"

   if [ -e "/sys/class/graphics/fb0/msm_fb_panel_info" ]; then
      pname=$(cat "/sys/class/graphics/fb0/msm_fb_panel_info" | grep "panel_name") > /dev/null 2>&1
   fi
   
   if [ -n "$pname" ]; then
      echo $pname >> $CFG
      return
   fi
   pname=$(cat $KLOG | $GREP "$F1") > /dev/null 2>&1
   if [ -n "$pname" ]; then
      echo -n "panel_name=" >> $CFG
      echo "${pname#*= }" >> $CFG
   else
      pname=$(cat $KLOG | $GREP "$F2") > /dev/null 2>&1
      if [ -n "$pname" ]; then
      	 F3=$(echo "$pname" | sed "s|^.*$F2||")
      	 echo -n "panel_name=" >> $CFG
      	 echo $F3 | sed "s/_/ /g" | sed "s/'//g" >> $CFG
      fi
   fi
}

# whether there is file-based encryption
isFB_Encrypted() {
  [ -e "/data/unencrypted/key/version" ] && echo "1" || echo "0"
}

# whether there is full-disk encryption
isFD_Encrypted() {
  local F=$(mount | grep "dm-")
  [ -n "$F" ] && echo "1" || echo "0"
}

# post-init stuff
post_init() {
  local M="/FFiles/magiskboot_new"
  [ -f $M ] && chmod 0755 $M
  M="/FFiles/fox_fix_date"
  [ -f $M ] && chmod 0755 $M

  # FBE - remove the "del_pass" addon, but keep a copy in /FFiles/Tools/
  M=$(isFB_Encrypted)
  [ "$M" = "1" ] && {
    local F=/FFiles/OF_DelPass/OF_DelPass.zip
    if [ -f $F ]; then
    	mkdir -p /FFiles/Tools
    	cp -f $F /FFiles/Tools/
    	rm -rf "/FFiles/OF_DelPass/"
    fi
  }
  
  # write OrangeFox props to the log
  echo "DEBUG: OrangeFox: Fox properties:" >> $LOG
  getprop | grep 'orangefox' >> $LOG
}

# kludge for issues with mounting system/vendor logical partitions
# TODO: one day, this will not be needed; can be moved to device tree
fix_dynamic() {
  if [ "$SUPER" = "1" ]; then
     sleep 1
     mount /product > /dev/null 2>&1
     sleep 1
     mount /vendor > /dev/null 2>&1
     sleep 1
     mount /system_root > /dev/null 2>&1
     sleep 1
     umount /product > /dev/null 2>&1
     umount /vendor > /dev/null 2>&1
     umount /system_root > /dev/null 2>&1
  fi
}

### main() ###
extralog "foxstart: about to start"

get_setprop
extralog "foxstart: completed get_setprop()"

# have we executed once before/are we running now?
start_script
extralog "foxstart: completed start_script()"

# if not, continue
backup_restore_FS
extralog "foxstart: completed backup_restore_FS()"

# get kernel logs right now
dmesg &> /tmp/dmesg.log
extralog "foxstart: completed dmesg()"

# get logcat right now
if [ -f "/system/bin/logcat" ]; then
   logcat -d &> /tmp/logcat.log
   extralog "foxstart: completed logcat()"
fi

#
Get_Details
extralog "foxstart: completed Get_Details()"

Treble_Action
extralog "foxstart: completed Treble_Action()"

MIUI_Action
extralog "foxstart: completed MIUI_Action()"

Get_Display_Panel
extralog "foxstart: completed Get_Display_Panel()"

# post-init
post_init
extralog "foxstart: completed post_init()"

# Leds
flashlight_Leds_config
extralog "foxstart: completed flashlight_Leds_config()"

# dynamic
# fix_dynamic

# end
exit 0
### end main ###
