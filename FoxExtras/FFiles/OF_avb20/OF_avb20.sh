#!/sbin/sh
#
# Patch AVB 2.0 to prevent overwriting the custom recovery
# Version: 0.4, 20200420
# Author : DarthJabba9
# Credits: wzsx150
#

OUTFD=$2
MAGISKBOOT=/sbin/magiskboot

ui_print() {
  if [ -z "$OUTFD" ]; then
    echo "$@"
  else
    echo -n -e "ui_print $1\n" > /proc/self/fd/$OUTFD
    echo -n -e "ui_print\n" > /proc/self/fd/$OUTFD
  fi
}

abort() {
  [ "$1" ] && [ "$AVB_REPORT_PROGRESS" = "1" ] && {
	ui_print "# Error: $1"
	ui_print "# Quitting ..."
	ui_print " "
   }
   exit 1
}

# Locate the boot block
OF_locate_boot() {
	bootpart=$(find /dev/block -name boot | grep "by-name/boot" -m 1 2>/dev/null)
	if [ -z "$bootpart" ];then
		slot_suffix=$(getprop ro.boot.slot_suffix)
		bootpart=`find /dev/block -name boot_a | grep "by-name/boot_a" -m 1 2>/dev/null`
		if [ -z "$bootpart" -o "$slot_suffix"s = "_b"s ];then
			bootpart=$(find /dev/block -name boot_b | grep "by-name/boot_b" -m 1 2>/dev/null)
    
			if [ -z "$bootpart" ];then
				bootpart=$(find /dev/block -name ramdisk | grep "by-name/ramdisk" -m 1 2>/dev/null)
			fi

			if [ -z "$bootpart" ];then
				bootpart=$(find /dev/block -name ramdisk_a | grep "by-name/ramdisk_a" -m 1 2>/dev/null)
			fi
		
			if [ -z "$bootpart" ];then
				abort "- Unable to locate the boot block"
			fi
		fi
	fi
	[ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Boot partition: $bootpart"
}

# patch for AVB 2.0
OF_patch_avb20() {
  local F="$bootpart"
  local has_avb=$(tail -c 2k "$F" | grep "AVBf" 2>/dev/null)
  [ -z "$has_avb" ] && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Nothing to patch for AVB 2.0"
     return
  }
  local patched_avb=$(tail -c 2k "$F" | grep "pReAVBf" 2>/dev/null)
  [ -n "$patched_avb" ] && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Nothing to patch for AVB 2.0"
     return
  }
  $MAGISKBOOT hexpatch "$F" 0000000041564266000000 0070526541564266000000 && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- AVB 2.0 has been patched"
  }
}

# Start
 [ ! -x "$MAGISKBOOT" ] && abort "- $MAGISKBOOT not found."
 [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Patching AVB 2.0 ..."
 OF_locate_boot
 OF_patch_avb20
 exit 0
#
