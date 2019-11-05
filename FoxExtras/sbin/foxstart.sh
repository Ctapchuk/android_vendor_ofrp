#!/sbin/sh
#
# - /sbin/foxstart.sh
# - Custom script for OrangeFox TWRP Recovery
# - Copyright (C) 2018-2019 OrangeFox Recovery Project
#
# - Author: DarthJabba9
# - Date:   5 November 2019
#
# * Detect whether the device has a MIUI ROM
# * Detect whether the device has a Treble ROM
# * Identify some hardware components
# * Do some other sundry stuff
#
#

C="/tmp_cust"
LOG="/tmp/recovery.log"
CFG="/tmp/orangefox.cfg"
FS="/etc/recovery.fstab"
T=0
M=0
DEBUG="0"  	  # enable for more debug messages
VERBOSE_DEBUG="0" # enable for really verbose debug messages
SYS_ROOT="0"	  # device with system_root?
ADJUST_VENDOR="0" # enable to remove /vendor from fstab if not needed
ADJUST_CUST="0"   # enable to remove /cust from fstab if not needed
ROM=""
FOX_DEVICE=$(getprop "ro.product.device")
SETPROP=/sbin/setprop

# verbose logging?
if [ "$VERBOSE_DEBUG" = "1" ]; then
   DEBUG=1
   set -o xtrace
fi

# file_getprop <file> <property>
file_getprop() 
{ 
   grep "^$2=" "$1" | cut -d= -f2
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
local V=/dev/block/bootdevice/by-name/vendor
  [ ! -e $V ] && {
    echo "0"
    return
  }
  mkdir -p $CC > /dev/null 2>&1
  mount -t ext4 $V $CC > /dev/null 2>&1
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
  mount -t ext4 /dev/block/bootdevice/by-name/cust $C > /dev/null 2>&1 
  T=$(Has_Treble_Dirs $C)
  DebugDirList "$C/"
  DebugDirList "$C/app/"
  umount $C > /dev/null 2>&1
  rmdir $C > /dev/null 2>&1
  echo "$T"
}

# does this device have system_root?
has_system_root() {
  local F=$(getprop "ro.build.system_root_image" 2>/dev/null)
  [ "$F" = "true" ] && echo "1" || echo "0"
}

get_ROM() {
local S="/tmp_system_rom"
   # mount /system and check
   if [ -d "$S" ]; then
      DebugMsg "$S already exists"
      umount $S > /dev/null 2>&1
   else
      DebugMsg "Creating $S"
      mkdir -p $S
   fi
   
   mount -t ext4 /dev/block/bootdevice/by-name/system $S > /dev/null 2>&1
   local tmp1="$S/build.prop"
   [ ! -e "$tmp1" ] && tmp1="$S/system/build.prop"
   local tmp2=""

   if [ -e "$tmp1" ]; then 
      tmp2=$(file_getprop "$tmp1" "ro.build.display.id")
   fi
   
   if [ -z "$tmp2" ]; then
      tmp1="/system/build.prop"
      [ -e "$tmp1" ] && tmp2=$(file_getprop "$tmp1" "ro.build.display.id")
   fi
   
   if [ -n "$tmp2" ]; then
      local tmp3=$(file_getprop "$tmp1" "ro.build.version.incremental")
      [ -n "$tmp3" ] && echo "DEBUG: OrangeFox: INCREMENTAL_VERSION=$tmp3" >> $LOG
   fi

   # unmount
   umount $S > /dev/null 2>&1
   rmdir $S

   echo "$tmp2"
}

# is it miui ?
isMIUI() {
   local M="0"
   local S="/tmp_system"
   local A="$S/app"
   local E="$S/etc"
   
   # mount /system and check
   if [ -d "$S" ]; then
      DebugMsg "$S already exists"
      umount $S > /dev/null 2>&1
   else
      DebugMsg "Creating $S"
      mkdir -p $S
   fi

   mount -t ext4 /dev/block/bootdevice/by-name/system $S > /dev/null 2>&1
   
   DebugDirList "$S/"
   DebugDirList "$S/vendor"

   DebugDirList "$A/"
   DebugDirList "$E/"
   
   if [ -f $S/init.miui.cust.rc ] && [ -f $S/init.miui.rc ]; then
      DebugMsg "First round of miui checks succeeded."
      M="1"
   fi

   if [ "$M" != "1" ] && [ -d $A/miui ] && [ -d $A/miuisystem ]; then
      DebugMsg "Second round of miui checks succeeded."
      if [ -d $E/cust ] && [ -d $E/miui_feature ] && [ -d $E/precust_theme ]; then
         DebugMsg "Third round of miui checks succeeded."
         M="1"
      else
         DebugMsg "Third round of miui checks returned negative."
      fi
   else
      DebugMsg "Second round of miui checks returned negative."
   fi
   
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
   #   
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
}

# backup (or restore) fstab
backup_restore_FS() {
   if [ ! -f "$FS.org" ]; then
      cp -a "$FS" "$FS.org"
   else   
      cp -a "$FS.org" "$FS"
   fi
}

# set up Leds for charging 
charging_Leds() {
  echo battery-charging > /sys/class/leds/blue/trigger
  echo battery-full > /sys/class/leds/green/trigger
}

# fix yellow flashlight on mido/vince/kenzo and configure Leds on others
flashlight_Leds_config() {
local LED=""
   case "$FOX_DEVICE" in
       kenzo | kate)
       		LED="/sys/devices/soc.0/qpnp-flash-led-23";
       		charging_Leds;
       	;;
       	mido)
       		LED="/sys/devices/soc/qpnp-flash-led-25";
       		echo 0 > /proc/touchpanel/capacitive_keys_disable;
       		charging_Leds;
       		echo bkl-trigger > /sys/class/leds/button-backlight/trigger;
            	echo 5 > /sys/class/leds/button-backlight/brightness; # Enable keys by default.
       	;;
       vince)
       		LED="/sys/devices/soc/qpnp-flash-led-24";
       	;;
       riva)
            	echo 1 > /sys/class/leds/flashlight/max_brightness;
            	echo 0 > /sys/class/leds/flashlight/brightness;
         ;;
       *)
       		return;
       	;;
   esac

   echo "0" > /$LED/leds/led:torch_1/max_brightness
   echo "0" > /sys/class/leds/led:torch_1/max_brightness
   echo "0" > /sys/class/leds/torch-light1/max_brightness
   echo "0" > /sys/class/leds/led:flash_1/max_brightness
}

# start, and mark that we have started
start_script()
{
local OPS=$(getprop "orangefox.postinit.status")
   [ -f "$CFG" ] || [ "$OPS" = "1" ] && exit 0
   echo "# OrangeFox live cfg" > $CFG
   local D=$(file_getprop "/etc/fox.cfg" "FOX_BUILD_DATE")
   [ -z "$D" ] && D=$(getprop "ro.bootimage.build.date")
   [ -z "$D" ] && D=$(getprop "ro.build.date")
   OPS=$(uname -r)
   SYS_ROOT=$(has_system_root)
   echo "KERNEL=$OPS" >> $CFG
   echo "SYSTEM_ROOT=$SYS_ROOT" >> $CFG
   echo "FOX_BUILD_DATE=$D" >> $CFG
   echo "FOX_BUILD_DATE=$D" >> $LOG
   echo "DEBUG: OrangeFox: FOX_DEVICE=$FOX_DEVICE" >> $LOG
   echo "DEBUG: OrangeFox: FOX_KERNEL=$OPS" >> $LOG
   echo "DEBUG: OrangeFox: SYSTEM_ROOT=$SYS_ROOT" >> $LOG
   $SETPROP orangefox.postinit.status 1
}

# cater for situations where setprop is a dead symlinked applet
get_setprop() {
  $SETPROP > /dev/null 2>&1
  [ $? == 0 ] && return
  SETPROP=/sbin/resetprop
  [ -x $SETPROP ] && {
    rm -f /sbin/setprop
    ln -sf $SETPROP /sbin/setprop
    return
  }
  SETPROP=/sbin/setprop
}

# try to get display panel information
Get_Display_Panel() {
local F1="Panel Name = "
local F2="Successfully bind display panel "
local GREP="grep -m 1"
local pname=""
local F3=""
local KLOG="/tmp/dmesg.log"
   pname=$(cat /sys/class/graphics/fb0/msm_fb_panel_info | grep panel_name) > /dev/null 2>&1
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

### main() ###
get_setprop

# have we executed once before/are we running now?
start_script

# if not, continue
backup_restore_FS

# get kernel logs right now
dmesg &> /tmp/dmesg.log

#
Get_Details

Treble_Action

MIUI_Action

Get_Display_Panel

# post-init
flashlight_Leds_config

exit 0
### end main ###