# ***********************************************************************
# 	Description: 	Helper routines for dynamic partition stuff on OrangeFox Recovery
# 	Author: 	DarthJabba9
# 	Date: 		02 October 2022
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2022 The OrangeFox Recovery Project
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

# the display screen
SCREEN=/proc/self/fd/$2;

# print message
ui_print() {
	until [ ! "$1" ]; do
		echo -e "ui_print $1\nui_print" >> $SCREEN;
		shift;
	done
}

# terminate with an error message
terminate() {
  [ "$1" ] && {
	ui_print "# Error: $1";
	ui_print "# Quitting ...";
	ui_print " ";
   }
   exit 1;
}

# other globals
SYSTEM_PARTITION="/dev/block/mapper/system";
VENDOR_PARTITION="/dev/block/mapper/vendor";
PRODUCT_PARTITION="/dev/block/mapper/product";
SYSTEM_EXT_PARTITION="/dev/block/mapper/system_ext";

SYSTEM_BLOCK=$(readlink $SYSTEM_PARTITION);
VENDOR_BLOCK=$(readlink $VENDOR_PARTITION);
SYSTEM_EXT_BLOCK=$(readlink $SYSTEM_EXT_PARTITION);
PRODUCT_BLOCK=$(readlink $PRODUCT_PARTITION);

SYS_ROOT_DIR=/system_root;
SYS_EXT_DIR=/system_ext;
VENDOR_DIR=/vendor;
PRODUCT_DIR=/product;

# any general initialisation stuff
initialise() {
	# find getprop
	GETPROP=$(which getprop);
	if [ -z "$GETPROP" ]; then
		GETPROP=/system/bin/getprop;
		[ ! -e "$GETPROP" ] && GETPROP=/sbin/getprop;
		[ ! -e "$GETPROP" ] && terminate "I cannot find any getprop command.";
	fi

	# dynamic partitions?
	DYNAMIC=$($GETPROP "ro.boot.dynamic_partitions");
	if [ "$DYNAMIC" != "true" ]; then
		terminate "This device does not have dynamic partitions.";
	fi
}

mount_system() {
	if [ -z "$SYSTEM_BLOCK" ]; then
		ui_print "There is no mountpoint for 'system'";
		has_system=0;
		return;
	fi
	mount -o ro -t auto $SYSTEM_PARTITION $SYS_ROOT_DIR;
	blockdev --setrw $SYSTEM_PARTITION;
	mount -o rw,remount -t auto $SYS_ROOT_DIR;
}

mount_vendor() {
	if [ -z "$VENDOR_BLOCK" ]; then
		ui_print "There is no mountpoint for 'vendor'";
		has_vendor=0;
		return;
	fi
	mount -o ro -t auto $VENDOR_PARTITION $VENDOR_DIR;
	blockdev --setrw $VENDOR_PARTITION;
	mount -o rw,remount -t auto $VENDOR_DIR;
}

mount_system_ext() {
	if [ -z "$SYSTEM_EXT_BLOCK" ]; then
		ui_print "There is no mountpoint for 'system_ext'";
		has_system_ext=0;
		return;
	fi
	mount -o ro -t auto $SYSTEM_EXT_PARTITION $SYS_EXT_DIR;
	blockdev --setrw $SYSTEM_EXT_PARTITION;
	mount -o rw,remount -t auto $SYS_EXT_DIR;
}

mount_product() {
	if [ -z "$PRODUCT_BLOCK" ]; then
		ui_print "There is no mountpoint for 'product'";
		has_product=0;
		return;
	fi
	mount -o ro -t auto $PRODUCT_PARTITION $PRODUCT_DIR;
	blockdev --setrw $PRODUCT_PARTITION;
	mount -o rw,remount -t auto $PRODUCT_DIR;
}

mount_all() {
	mount_system;
	mount_vendor;
	mount_system_ext;
	mount_product;
}

unmount_all() {
	umount $PRODUCT_DIR;
	umount $SYS_EXT_DIR;
	umount $VENDOR_DIR;
	umount $SYS_ROOT_DIR;
}

wipe_all() {
	wipe_system;
	wipe_system_ext;
	wipe_product;
	wipe_vendor;
}

wipe_system() {
	mount_system;
	[ "$has_system" = "0" ] && return;
	ls -all $SYS_ROOT_DIR/;
	rm -rf $SYS_ROOT_DIR/*;
	ls -all $SYS_ROOT_DIR/;
	umount $SYS_ROOT_DIR;
}

wipe_vendor() {
	mount_vendor;
	[ "$has_vendor" = "0" ] && return;
	ls -all $VENDOR_DIR/;
	rm -rf $VENDOR_DIR/*;
	ls -all $VENDOR_DIR/;
	umount $VENDOR_DIR;
}

wipe_system_ext() {
	mount_system_ext;
	[ "$has_system_ext" = "0" ] && return;
	rm -rf $SYS_EXT_DIR/*;
	umount $SYS_EXT_DIR;
}

wipe_product() {
	mount_product;
	[ "$has_product" = "0" ] && return;
	rm -rf $PRODUCT_DIR/*;
	umount $PRODUCT_DIR;
}

# start
initialise;
#
