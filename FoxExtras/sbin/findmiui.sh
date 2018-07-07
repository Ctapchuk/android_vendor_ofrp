#!/sbin/sh
#
# - /sbin/findmiui.sh
# - Custom script for OrangeFox Recovery
# - Author: DarthJabba9
# - Date: 4 July 2018
#
# * Detect whether the device has a MIUI ROM, and, if so, don't mount "/vendor" 
#
#

C="/cust"
L=/tmp/recovery.log

isMIUI() {
local F=0
  if [ -d "$C""$C" ] && [ -d $C/app ] && [ -d $C/prebuilts ]; then
     F=1
  fi
  echo $F
}

mkdir -p $C
mount -t ext4 /dev/block/bootdevice/by-name/cust $C
sleep 1

##
echo "DEBUG: OrangeFox: check for MIUI (non-Treble)." >> $L
dir $C >> $L
##

m=$(isMIUI)
umount $C
D="DEBUG: OrangeFox detects a Custom ROM."
if [ "$m" = "1" ]; then
   D="DEBUG: OrangeFox detects a MIUI ROM. Removing /vendor from fstab."
   sed -i -e "s|/vendor|#/vendor|g" /etc/recovery.fstab
fi

echo $D >> $L

