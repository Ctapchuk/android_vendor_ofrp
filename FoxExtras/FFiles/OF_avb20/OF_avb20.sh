#!/system/bin/sh
#
# Patch AVB 2.0 to prevent overwriting the custom recovery
# Version: 0.7, 20240905
# Author : DarthJabba9
# Credits: wzsx150
#

OUTFD=$2;
MAGISKBOOT=/sbin/magiskboot;
[ ! -x "$MAGISKBOOT" ] && MAGISKBOOT=/system/bin/magiskboot;

ui_print() {
  if [ -z "$OUTFD" ]; then
    echo "$@";
  else
    echo -n -e "ui_print $1\n" > /proc/self/fd/$OUTFD;
    echo -n -e "ui_print\n" > /proc/self/fd/$OUTFD;
  fi
}

abort() {
  [ "$1" ] && [ "$AVB_REPORT_PROGRESS" = "1" ] && {
	ui_print "# Error: $1";
	ui_print "# Quitting ...";
	ui_print " ";
   }
   exit 1;
}

# Locate the boot block
OF_locate_boot() {
	slot_suffix=$(getprop ro.boot.slot_suffix);
	if [ -n "$slot_suffix" ]; then
		abort "- AVB 2.0 patching is inappropriate for an A/B device.";
	fi

	bootpart=$(find /dev/block -name boot | grep "by-name/boot" -m 1 2>/dev/null);
	if [ -z "$bootpart" ]; then
		abort "- Unable to locate the boot block";
	fi

	[ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Boot partition: $bootpart";
}

# patch for AVB 2.0
OF_patch_avb20() {
  local F="$bootpart";
  local has_avb=$(tail -c 2k "$F" | grep "AVBf" | tr '\0' '\n' 2>/dev/null);
  [ -z "$has_avb" ] && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Nothing to patch for AVB 2.0";
     return;
  }
  local patched_avb=$(tail -c 2k "$F" | grep "pReAVBf" | tr '\0' '\n' 2>/dev/null);
  [ -n "$patched_avb" ] && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Nothing to patch for AVB 2.0";
     return;
  }
  $MAGISKBOOT hexpatch "$F" 0000000041564266000000 0070526541564266000000 && {
     [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- AVB 2.0 has been patched";
  }
}

# Start
 [ ! -x "$MAGISKBOOT" ] && abort "- $MAGISKBOOT not found.";
 [ "$AVB_REPORT_PROGRESS" = "1" ] && ui_print "- Patching AVB 2.0 ...";
 OF_locate_boot;
 OF_patch_avb20;
 exit 0;
#
