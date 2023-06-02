#!/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2023 The OrangeFox Recovery Project
#
#	SPDX-License-Identifier: GPL-3.0-or-later
#

echo "Run this script at the fastbootd prompt (on ROMs/recoveries that support this functionality; some bugged ROMs/recoveries don't)"
echo "Please reboot to fastbootd now!"
echo "This script will flash ramdisk.cpio.gz to vendor_boot:recovery"
echo "This will replace the recovery ramdisk in the vendor_boot partition"
echo "It requires a standards-compliant and fully functional fastbootd implementation in the current ROM or recovery"
echo "Press CTRL-C to stop - or press ENTER to continue ..."
read

fastboot devices
fastboot flash vendor_boot:recovery vendor_ramdisk_recovery.cpio
fastboot reboot recovery

echo "Finished!"
