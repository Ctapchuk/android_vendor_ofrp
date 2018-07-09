#!/sbin/sh
#
# - /sbin/findmiui.sh
# - Custom script for OrangeFox Recovery
# - Author: DarthJabba9
# - Date: 9 July 2018
#
# * Detect whether the device has a MIUI ROM, and, if so, don't mount "/vendor" 
# * Detect whether the device has a Treble ROM
#

C="/cust"
L=/tmp/recovery.log
T=0
M=0

# is it miui ?
isMIUI() {
  if [ -d "$C""$C" ] && [ -d $C/app/ ] && [ -d $C/prebuilts/ ]; then
     echo "1"
  else 
     echo "0"   
  fi
}

# is it a treble ROM ?
isTreble() {
  if [ -d $C/etc/ ] && [ -d $C/firmware/ ] && [ -d $C/framework/ ] && [ -d $C/usr/ ] && [ -d $C/lib64/ ]; then
     echo "1"
  else 
     echo "0"   
  fi
}

Get_Details() {
   # mount /cust
   mkdir -p $C
   mount -t ext4 /dev/block/bootdevice/by-name/cust $C
   sleep 1

   # check for MIUI
   M=$(isMIUI)

   # check for Treble
   T=$(isTreble)

   # unmount
   umount $C
}

# report on MIUI and take action
MIUI_Action() {
   echo "DEBUG: OrangeFox: check for MIUI." >> $L
   dir $C >> $L
   D="DEBUG: OrangeFox detects a Custom ROM."
   if [ "$M" = "1" ]; then
      D="DEBUG: OrangeFox detects a MIUI ROM. Removing /vendor from fstab."
      sed -i -e "s|/vendor|#/vendor|g" /etc/recovery.fstab
   fi
  echo $D >> $L
}

# report on Treble
Treble_Action() {
   echo "DEBUG: OrangeFox: check for Treble." >> $L
   dir $C >> $L
   if [ "$T" = "1" ]; then
      D="DEBUG: OrangeFox detects a Treble ROM."
   else
      D="DEBUG: OrangeFox detects a Non-Treble ROM."
   fi
   echo $D >> $L
}

### main() ###
Get_Details
MIUI_Action
Treble_Action
### end main ###

