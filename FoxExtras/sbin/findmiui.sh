#!/sbin/sh
#
# - /sbin/findmiui.sh
# - Custom script for OrangeFox TWRP Recovery
# - Author: DarthJabba9
# - Date: 26 December 2018
#
# * Detect whether the device has a MIUI ROM
# * Detect whether the device has a Treble ROM
# * Identify some hardware components
# * Do some other sundry stuff
#
# Copyright (C) 2018 OrangeFox Recovery Project
#

C="/tmp_cust"
L="/tmp/recovery.log"
CFG="/tmp/orangefox.cfg"
FS="/etc/recovery.fstab"
T=0
M=0
DEBUG="0"  	  # enable for more debug messages
ADJUST_VENDOR="0" # enable to remove /vendor from fstab if not needed
ADJUST_CUST="0"   # enable to remove /cust from fstab if not needed

# is it a treble ROM ?
isTreble() {
  if [ -d $C/etc/ ] && [ -d $C/firmware/ ] && [ -d $C/framework/ ] && [ -d $C/usr/ ] && [ -d $C/lib64/ ]; then
     echo "1"
  else 
     echo "0"   
  fi
}

# is it miui ?
isMIUI() {
  if [ -d $C/cust/ ] && [ -d $C/app/ ] && [ -d $C/prebuilts/ ]; then
     echo "1"
  else 
     echo "0"   
  fi
}

#  some optional debug message stuff
DebugDirList() {
   [ ! "$DEBUG" = "1" ] && return
   echo "DEBUG: OrangeFox: directory list of $1" >> $L
   ls -all $1 >> $L
}

# optional debug message
DebugMsg() {
   [ ! "$DEBUG" = "1" ] && return
   echo "DEBUG: OrangeFox: $@" >> $L
}

# probe the installed ROM
Get_Details() {
   # mount /cust
   mkdir -p $C
   mount -t ext4 /dev/block/bootdevice/by-name/cust $C > /dev/null 2>&1

   # check for Treble
   T=$(isTreble)

   # check for MIUI
   M=$(isMIUI)

   DebugDirList "$C/"
   DebugDirList "$C/app/"

   # unmount
   umount $C > /dev/null 2>&1
   rmdir $C
   
   # clearly not miui - return
   [ "$M" = "0" ] && return

   # further checks for miui (if it thinks we have miui)
   local S="/tmp_system"
   local A="$S/app"
   local E="$S/etc"
   M="0"
   
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
   echo "DEBUG: OrangeFox: check for Treble." >> $L
   if [ "$T" = "1" ]; then
      D="DEBUG: OrangeFox: detected a Treble ROM."
   else
      D="DEBUG: OrangeFox: detected a Non-Treble ROM."
   fi
   mod_cust_vendor "$T"
   echo $D >> $L
   echo "TREBLE=$T" >> $CFG
}

# report on MIUI and take action
MIUI_Action() {
   echo "DEBUG: OrangeFox: check for MIUI." >> $L
   D="DEBUG: OrangeFox: detected a Custom ROM."
   if [ "$M" = "1" ]; then
      D="DEBUG: OrangeFox: detected a non-Treble MIUI ROM."
   fi
  echo $D >> $L
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

# fix yellow flashlight on mido/vince
fix_yellow_flashlight() {
   DEV=$(getprop "ro.product.device")
   if [ "$DEV" = "mido" ] || [ "$DEV" = "vince" ]; then
   	echo "0" > /sys/devices/soc/qpnp-flash-led-25/leds/led:torch_1/max_brightness
   	echo "0" > /sys/class/leds/led:torch_1/max_brightness
   	echo "0" > /sys/class/leds/torch-light1/max_brightness 
   	echo "0" > /sys/class/leds/led:flash_1/max_brightness
   fi
}

# start, and mark that we have started
start_script()
{
local OPS=$(getprop "orangefox.postinit.status")
   [ -f "$CFG" ] || [ "$OPS" = "1" ] && exit 0
   echo "# OrangeFox live cfg" > $CFG
   setprop orangefox.postinit.status 1
}

### main() ###

# have we executed once before/are we running now?
start_script

# if not, continue
backup_restore_FS

Get_Details

Treble_Action

MIUI_Action

# get kernel logs right now
dmesg &> /tmp/dmesg.log

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
fix_yellow_flashlight

exit 0
### end main ###
