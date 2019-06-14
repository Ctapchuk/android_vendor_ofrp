#!/sbin/sh
#
# - /sbin/findmiui.sh
# - Custom script for OrangeFox TWRP Recovery
# - Copyright (C) 2018-2019 OrangeFox Recovery Project
#
# - Author: DarthJabba9
# - Date:   14 June 2019
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
SYS_ROOT="0"	  # device with system_root?
DEBUG="0"  	  # enable for more debug messages
ADJUST_VENDOR="0" # enable to remove /vendor from fstab if not needed
ADJUST_CUST="0"   # enable to remove /cust from fstab if not needed
ROM=""
FOX_DEVICE=$(getprop "ro.product.device")
SETPROP=/sbin/setprop

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

   if [ -d $A/miui/ ] &&  [ -d $A/miuisystem/ ] &&  [ -d $A/MiuiBluetooth/ ]; then
      DebugMsg "Second round of miui checks succeeded."
      if [ -d $E/cust/ ] &&  [ -d $E/miui_feature/ ] &&  [ -d $E/precust_theme/ ]; then
         DebugMsg "Third round of miui checks succeeded. Definitely MIUI!"
         M="1"
      fi
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
   OPS=$(uname -r)
   SYS_ROOT=$(has_system_root)
   echo "KERNEL=$OPS" >> $CFG
   echo "SYSTEM_ROOT=$SYS_ROOT" >> $CFG
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

# get display panel name
pname=$(cat /sys/class/graphics/fb0/msm_fb_panel_info | grep panel_name)
if [ -n "$pname" ]; then
   echo $pname >> $CFG
else
   pname=$(cat /tmp/dmesg.log | grep "Panel Name")
   if [ -n "$pname" ]; then
      echo -n "panel_name=" >> $CFG
      echo "${pname#*= }" >> $CFG
   fi
fi

# post-init
flashlight_Leds_config

exit 0
### end main ###
