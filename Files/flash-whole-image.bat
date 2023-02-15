@echo off

REM - #
REM - #	This file is part of the OrangeFox Recovery Project
REM - # Copyright (C) 2023 The OrangeFox Recovery Project
REM - #
REM - #	SPDX-License-Identifier: GPL-3.0-or-later
REM - #

echo Run this script at the bootloader prompt
echo Please reboot to the bootloader now!
echo This script will flash recovery.img to /vendor_boot 
echo This will replace the *entire* /vendor_boot partition!
echo Press CTRL-C to stop - or -
pause
goto flash

:flash
fastboot devices
fastboot flash vendor_boot recovery.img
fastboot reboot recovery
goto end

:end
echo Finished!
