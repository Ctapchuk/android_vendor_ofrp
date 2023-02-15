#!/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2023 The OrangeFox Recovery Project
#
#	SPDX-License-Identifier: GPL-3.0-or-later
#

echo "Run this script at the bootloader prompt"
echo "Please reboot to the bootloader now!"
echo "This script will flash recovery.img to /vendor_boot"
echo "This will replace the *entire* /vendor_boot partition!"
echo "Press CTRL-C to stop - or press ENTER to continue ..."
read

fastboot devices
fastboot flash vendor_boot recovery.img
fastboot reboot recovery

echo "Finished!"
