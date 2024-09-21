# ------------------------------------
#
# Custom build VARs for the OrangeFox Recovery, fox_12.1 branch
#
# These build vars should be declared - in a shell script (eg, in "vendorsetup.sh"), or at the command line - before building
#
# Copyright (C) 2019-2024 OrangeFox Recovery Project
# Date: 21 September 2024
#
# -----------------------------------
#
#
"TARGET_ARCH"
  - set this to "arm" or "arm64", depending on whether your device is 32-bit or 64-bit
  - eg., "export TARGET_ARCH=arm"
  - default = arm64
#
"FOX_AB_DEVICE" (renamed from "OF_AB_DEVICE")
   - whether the device is an A/B device
   - set to 1 if your device is an A/B device (** make sure that it really is **)
   - default = 0
#
"OF_AB_DEVICE_WITH_RECOVERY_PARTITION" [NEW]
   - set to 1 if the device is an A/B device that has a dedicated recovery partition (** make sure that it really is **)
   - if this is enabled, the following features will automatically be removed
   	* Changing the OrangeFox splash image/logo
   	* "Flash Current OrangeFox"
   	* "Reflash OrangeFox after flashing a ROM"
   - default = 0
#
"OF_RECOVERY_AB_FULL_REFLASH_RAMDISK" [NEW]
   - set to 1 to trigger flashing the live recovery ramdisk (instead of the recovery partition) to both slots
   - this is only useful if "OF_AB_DEVICE_WITH_RECOVERY_PARTITION" is also enabled.
   - use with caution!
   - if this is enabled, it applies to "Flash current OrangeFox" and "Reflash OrangeFox after flashing a ROM"
     (the process will take much more time, but less vulnerable to non-standard ROM installers overwriting the recovery partition)
   - default = 0
#
"FOX_PORTS_TMP"
   - point to a custom temp directory for creating the zip installer
   - ensure that this is a directory that you have write access to
   - there is no default
#
"FOX_PORTS_INSTALLER" 
   - point to a custom directory for amended/additional installer files 
   - the contents will simply be copied over before creating the zip installer
#
"FOX_LOCAL_CALLBACK_SCRIPT"
   - point to a custom "callback" script that will be executed just before creating the final recovery image
   - eg, a script to delete some files, or add some files to the ramdisk
   - ensure that you set the executable bit of the script (eg, "chmod 0755 my-callback-script.sh")
   - there is no default
#
"FOX_REPLACE_TOOLBOX_GETPROP"
   - set to 1 to replace the (stripped down) toolbox version of the "getprop" command
   - if this is defined, the toolbox "getprop" command will be replaced by a fuller version (resetprop)
   - default = 0
#
"FOX_RECOVERY_INSTALL_PARTITION"
   - !!! this should normally BE LEFT WELL ALONE !!!
   - set this ONLY if your device's recovery partition is in a location that is
     different from the default "/dev/block/by-name/recovery"
   - default = "/dev/block/by-name/recovery"
#
"FOX_RECOVERY_SYSTEM_PARTITION"
   - !!! this should normally BE LEFT WELL ALONE !!!
   - set this ONLY if your device's system partition is in a location that is
     different from the default "/dev/block/by-name/system"
     (eg, some Samsung devices have a different location for system)
   - default = "/dev/block/by-name/system"
#
"FOX_RECOVERY_VENDOR_PARTITION"
   - !!! this should normally BE LEFT WELL ALONE !!!
   - set this ONLY if your device's vendor partition is in a location that is
     different from the default "/dev/block/by-name/vendor"
     (eg, some Samsung devices have a different location for vendor)
   - default = "/dev/block/by-name/vendor"
#
"FOX_RECOVERY_VENDOR_BOOT_PARTITION" [NEW]
   - this is for vendor_boot builds only; it shoul normally BE LEFT WELL ALONE !!!
   - set this ONLY if your device's vendor_boot partition is in a location that is
     different from the default "/dev/block/by-name/vendor_boot"
   - default = "/dev/block/by-name/vendor_boot"
#
"FOX_RECOVERY_BOOT_PARTITION" [R11.1 only]
   - !!! this should normally BE LEFT WELL ALONE !!!
   - set this ONLY if your device's boot partition is in a location that is
     different from the default "/dev/block/by-name/boot"
     (eg, some devices have a different location for boot)
   - default = "/dev/block/by-name/boot"
#
"OF_USE_LZMA_COMPRESSION" (renamed from "FOX_USE_LZMA_COMPRESSION")
   - set this to 1 if you want to use (slow but better compression) lzma compression for your ramdisk; 
   - * this requires you to have an up-to-date lzma binary in your build system, and 
   - * set this in your BoardConfig (it will be set automatically if you don't set it yourself):
   -     BOARD_RAMDISK_USE_LZMA := true
   - * your kernel must also have built-in lzma compression support
   - default = 0 (meaning use standard gzip compression (fast, but doesn't compress as well))
#
"OF_USE_LZ4_COMPRESSION" (renamed from "FOX_USE_LZ4_COMPRESSION")
   - set this to 1 if (for whatever reason) you want to use lz4 compression for your ramdisk;
   - * this requires you to have an up-to-date lz4 binary in your build system, and
   - * set this in your BoardConfig (it will be set automatically if you don't set it yourself):
   -     BOARD_RAMDISK_USE_LZ4 := true
   - * your kernel must also have built-in lz4 compression support
   - default = 0 (meaning use standard gzip compression, which provides better compression anyway)
#
"FOX_USE_TAR_BINARY"
   - set this to 1 if you want the gnu tar binary to be added (/sbin/gnutar)
   - this must be set in a shell script, or at the command line, before building
   - this will add about 420kb to the size of the recovery image
   - default = 0
#
"FOX_USE_SED_BINARY"
   - set this to 1 if you want the gnu sed binary to be added (/sbin/gnused)
   - this must be set in a shell script, or at the command line, before building
   - this will add about 200kb to the size of the recovery image
   - default = 0
#
"FOX_USE_LZ4_BINARY" [NEW]
   - set this to 1 if you want the prebuilt lz4 binary to be added (/sbin/lz4)
   - this must be set in a shell script, or at the command line, before building
   - default = 0
#
"FOX_USE_ZSTD_BINARY" [NEW]
   - set this to 1 if you want the zstd binary to be added (/sbin/zstd)
   - this must be set in a shell script, or at the command line, before building
   - default = 0
#
"FOX_USE_RESETPROP_BINARY" [OBSOLETE]
#
"FOX_USE_BASH_SHELL"
   - set this to 1 if you want bash to be the default shell, instead of "sh"
   - default = 0
   - if not set, bash will still be copied, but it will not replace "sh"
#
"FOX_ASH_IS_BASH"
   - set this to 1 if you bash to also be available as "ash"
   - default = 0
   - if not set, bash will still be copied, but there will be no "ash" symlink
#
"FOX_REMOVE_BASH"
   - set this to 1 if you want to remove bash completely from the recovery
   - default = 0
#
"OF_USE_MAGISKBOOT" [!NOW ENABLED AUTOMATICALLY IN ALL CASES!]
   - set to 1 to use magiskboot for patching the ROM's boot image
#
"OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" [!NOW ENABLED AUTOMATICALLY IN ALL CASES!]
   - set to 1 to use magiskboot for all patching of boot images *and* recovery images
#
"OF_FORCE_MAGISKBOOT_BOOT_PATCH_MIUI" [LEGACY]
   - set to 1 to force the use magiskboot for patching the ROM's boot image when
   - installing a MIUI ROM, or the OrangeFox zip on a MIUI ROM - this is for the purpose of stopping MIUI from
   - overwriting OrangeFox with its own stock recovery
   - default = 0
#
"FOX_DISABLE_UPDATEZIP" (renamed from "OF_DISABLE_UPDATEZIP")
   - set to 1 to disable recovery zip creation
   - default = 0
#
"OF_DONT_PATCH_ON_FRESH_INSTALLATION" [LEGACY]
   - set to 1 to prevent patching dm-verity and forced-encryption when the OrangeFox zip is flashed
   - default = 0
   - if dm-verity is enabled in the ROM, and this is turned on, there will be a bootloop
#
 "OF_TWRP_COMPATIBILITY_MODE" ; "OF_DISABLE_MIUI_SPECIFIC_FEATURES"
   - set either of them to 1 to enable stock TWRP-compatibility mode 
   - in this mode, MIUI OTA will be disabled
   - default = 0
#
"OF_DONT_PATCH_ENCRYPTED_DEVICE" [Always enabled now]
#
"OF_KEEP_DM_VERITY"; [Always enabled now]
#
"OF_KEEP_FORCED_ENCRYPTION"; [Always enabled now]
#
"OF_KEEP_DM_VERITY_FORCED_ENCRYPTION"; [Always enabled now]
#
"OF_FORCE_DISABLE_DM_VERITY"; [OBSOLETE]
#
"OF_FORCE_DISABLE_FORCED_ENCRYPTION"; [OBSOLETE]
#
"OF_FORCE_DISABLE_DM_VERITY_FORCED_ENCRYPTION"; [OBSOLETE]
#
"OF_DISABLE_DM_VERITY"; [OBSOLETE]
#
"OF_DISABLE_FORCED_ENCRYPTION"; [OBSOLETE]
#
"OF_DISABLE_DM_VERITY_FORCED_ENCRYPTION"; [OBSOLETE]
#
"OF_CLASSIC_LEDS_FUNCTION"
   - set to 1 to use the old R9.x Leds function
   - default = 0
#
"OF_SKIP_FBE_DECRYPTION" 
   - set to 1 to skip the FBE decryption routines (prevents hanging at the Fox logo or Redmi/Mi logo)
   - default = 0
#
"OF_SKIP_FBE_DECRYPTION_SDKVERSION"
   - This allows you to instruct OrangeFox to avoid trying to decrypt ROMs with a specific Android SDK/API number (and higher)
   - set to the Android SDK/API level which should be skipped. It is up to you to ensure that the value supplied makes sense and is correct
   - a warning will be printed on the log screen whenever the skip code is triggered, and no attempt will be made to decrypt data the partition
   - eg, "export OF_SKIP_FBE_DECRYPTION_SDKVERSION=31" (ie, don't try to decrypt Android 12 (SDK/API 31) or higher)
   - the valid SDK/API level numbers can be found at: "https://source.android.com/setup/start/build-numbers"
   - NOTE: do NOT use "OF_SKIP_FBE_DECRYPTION" if you are using this variable, because it will supersede this variable
   - default = nothing (ie, try to decrypt all Android API levels)
#
"OF_OTA_RES_DECRYPT" [OBSOLETE]
   - set to 1 to try and decrypt internal storage (instead bailing out with an error) during MIUI OTA restore
   - default = 0
#
"OF_NO_MIUI_OTA_VENDOR_BACKUP" [LEGACY]
   - set to 1 to prevent backing up of vendor_image when preparing for incremental MIUI OTA (upon flashing a MIUI ROM)
   - such a backup is required for new (2019+) Xiaomi devices (eg, lavender, violet, raphael, ginkgo, etc)
   - default = 0
#
"OF_NO_RELOAD_AFTER_DECRYPTION"
   - set to 1 to prevent OrangeFox from re-running the startup process after decryption
   - default = 0
#
"OF_NO_TREBLE_COMPATIBILITY_CHECK"
   - set to 1 to disable checking for compatibility.zip in ROMs
   - default = 0
#
"FOX_RESET_SETTINGS"
   - set to "disabled" to NOT reset OrangeFox settings to defaults, after installation of the OrangeFox zip
   - it is NOT recommended to disable this
   - default = 1
#
"FOX_DELETE_AROMAFM"
   - set to 1 to delete AromaFM from the zip installer (for devices where it doesn't work)
   - default = 0
#
"OF_USE_HEXDUMP" [OBSOLETE]
   - set to 1 to use an external hexdump utility to get file header information (instead of internal code)
   - default = 0
#
"OF_USE_GREEN_LED"
   - set to 0 to remove the "green led" setting
   - default = 1
#
"OF_FLASHLIGHT_ENABLE"
  - whether the enable the flashlight feature
  - default is "1"
#
"OF_FL_PATH1" and "OF_FL_PATH2"
  - set custom flashlight path (if flashlight isn't working)
  - eg. OF_FL_PATH1="/sys/class/leds/led_torch_2"
#
"FOX_VERSION"
  - the version number of the release
#
"OF_MAINTAINER"
  - the maintainer's name
#
"OF_SCREEN_H"
  - Use this if your screen's aspect ratio is not 16:9
  - to calculate OF_SCREEN_H, if your screen width is not 1080, use this formula: <aspect ratio height>*120
  - e.g. if the aspect ratio is 19:9 then use 19*120 (=2280)
  - use "export OF_SCREEN_H=2280" to resize recovery to 19:9 screen
  - default = 1920
#
"OF_STATUS_H"
  - use this only when the device has a cutout
  - you do not need to add or subtract OF_STATUS_H from OF_SCREEN_H
  - use "export OF_STATUS_H=144" to change statusbar size to 144
  - Tip: take screenshot in android and count status bar height using any graphics editor (eg. MSPaint)
  - default = 72
#
"OF_STATUS_INDENT_LEFT" and "OF_STATUS_INDENT_RIGHT"
  - use OF_STATUS_INDENT_LEFT and OF_STATUS_INDENT_RIGHT when device has rounded corners
  - the recommended setting of these vars is 48 (when device has rounded corners)
  - default = 20
# 
"OF_HIDE_NOTCH"
  - add option to settings that makes status bar black (hides notch)
  - default = 0
# 
"OF_CLOCK_POS"
  - var to control clock position option for devices that has cutout
  - 0 => left, center and right clock positions available
  - 1 => left and right clock positions available
  - 2 => only left clock position available
  - default = 0
# 
"OF_ALLOW_DISABLE_NAVBAR"
  - set to 0 if device doesn't have hardware navigation buttons
  - if OF_ALLOW_DISABLE_NAVBAR is set to 0 user can't hide on-screen navbar
  - default = 1
# 
"OF_DONT_KEEP_LOG_HISTORY"
  - Time-stamped copies of the recovery.log (in .zip format) will now be kept (in /sdcard/Fox/logs/)
  - this means that the previously saved recovery logs will not be overwritten
  - these will be in .zip format; users might need to clear them out periodically
  - enable this to turn off this feature (meaning that lastrecoverylog.log will be overwritten each time the recovery is rebooted)
  - default = 0
#
"FOX_BUGGED_AOSP_ARB_WORKAROUND" [OBSOLESCENT]
 - Use this to set an old UTC time for the build, to work around bugged alleged anti-rollback protection in some ROMs
 - eg, export FOX_BUGGED_AOSP_ARB_WORKAROUND="1546300800" [Tue Jan 1 2019 00:00:00 GMT]
 -     export FOX_BUGGED_AOSP_ARB_WORKAROUND="1420041600" [Wed Dec 31 2014 16:00:00 GMT]
 - Unless you have a very specific need to set a specific date/time, consider this flag to be obsolescent
 - default = 0 (ie, automatically zeroed on bootup by default)
#
"TARGET_DEVICE_ALT"
 - Use this if the device has more than one code name, so that the OrangeFox zip
 - installer can support the alternative code name without just bombing out
 - eg, export TARGET_DEVICE_ALT="kate" (for kenzo/kate)
 -     export TARGET_DEVICE_ALT="willow" (for ginkgo/willow)
 -     export TARGET_DEVICE_ALT="blue, green, yellow, orange" (for multiple alt devices)
 - default = nothing
#
"FOX_TARGET_DEVICES" (renamed from "OF_TARGET_DEVICES")
- Use this if the device has more than one code name, but ROMs and other zip installers
- never check for all code names, therefore always causing "E3004 error 7" problems (eg, raphael/raphaelin)
- What this does is to cause OrangeFox to temporarily switch devices names to prevent error 7 from happening
- Note that this is temporary work-around that lasts until the recovery is rebooted.
- You should list all the valid code names for the device.
- eg, export FOX_TARGET_DEVICES="raphaelin,raphael"
-
- NOTE: the purpose of this is quite different from TARGET_DEVICE_ALT (which only impacts on the creation of
- the OrangeFox zip installer). This variable actually impacts on the operation of OrangeFox while flashing
- a zip with OrangeFox. This is why it is mapped out to a separate build variable. It is deliberate done,
- so that it can trigger all these impacts in the live recovery session. You should only deploy a
- build using this variable after plenty of testing in all possible scenarios
#
"OF_SKIP_ORANGEFOX_PROCESS" [LEGACY]
 - Use this to 1 to skip the dm-verity/forced-encryption/boot images patches
 - If this is enabled, then "OF_DONT_PATCH_ON_FRESH_INSTALLATION" is also enabled automatically
 - default = 0
#
"FOX_VANILLA_BUILD" (renamed from "OF_VANILLA_BUILD")
 - Set this to 1 to make a plain build that skips all the OrangeFox (mostly MIUI-related) patches
 - You should probably enable it for A/B devices, for non-Xiaomi devices (and for all builds for Xiaomi devices, if you are not supporting MIUI)
 - If this is enabled, a whole lot of other variables are also enabled automatically to disable various 
   OrangeFox extras, including "OF_SKIP_ORANGEFOX_PROCESS" above (see bootable/recovery/orangefox.mk for details)
 - On older A-only Xiaomi devices, if this is enabled, it is very possible (even likely) that OrangeFox will be 
   overwritten by MIUI stock recovery, so the user may well need to flash some kind of "fcrypt" zip and/or magisk
 - default = 0
#
"OF_SUPPORT_OZIP_DECRYPTION"
 - Set this to 1 to enable support for Realme oZip decryption
 - do not use this unless you know what you are doing (see below)
 - if this is enabled, you must also set "TW_OZIP_DECRYPT_KEY"
 - default = 0
#
"FOX_REMOVE_AAPT"
 - Set this to 1 to remove the aapt binary from the build
 - This binary is 1.7mb in size, and using this variable is useful for reducing the size of the recovery
 - default = 0
#
"OF_CHECK_OVERWRITE_ATTEMPTS" [LEGACY]
 - Set this to 1 to check for attempts by a ROM's installer to overwrite OrangeFox with another recovery
 - If this is enabled, then OrangeFox will give users a 40-second countdown, to enable
 - them to reboot OrangeFox to stop the ROM installation, if they want
 - default = 0
#
"OF_FBE_METADATA_MOUNT_IGNORE"
 - Set this to 1 if you are supporting FBE metadata encryption in your fstab, but don't want the user to be
 - spammed with metadata mount errors in ROMs that don't use metadata encryption
 - default = 0
#
"OF_IGNORE_LOGICAL_MOUNT_ERRORS"
- Set to 1 to record some errors in mounting logical partitions as log entries only
- default = 0
#
"OF_FIX_OTA_UPDATE_MANUAL_FLASH_ERROR" [LEGACY]
- Set this to 1 to try to recover from error situations where people flash incremental block-based OTA zips manually
- An error will still be displayed, but OrangeFox will reboot itself into "Ors" mode and attempt to apply the OTA update (this is not guaranteed to always work)
- default = 0
#
"OF_PATCH_AVB20"
- Set this to 1 to try patch AVB 2.0 so that OrangeFox is not replaced by stock recovery
- This works by patching the boot image
- This is useful only for A-only devices, else it is ignored
- It is also ignored when using OF_SKIP_ORANGEFOX_PROCESS or FOX_VANILLA_BUILD
- default = 0
#
"OF_SUPPORT_VBMETA_AVB2_PATCHING" [NEW] [EXPERIMENTAL!!]
- Set this to support disabling AVB2.0 by patching vbmeta/vbmeta_system (instead of patching the boot image) after flashing a ROM
- This is an experimental feature; test very carefully, and handle with great care!!
- This feature is not needed on most devices (and certainly not on pre-2021 devices)
- default = 0
#
"OF_OTA_BACKUP_STOCK_BOOT_IMAGE" [LEGACY]
- Set this to 1 to create a backup of the boot.img from the ROM's zip during the OTA_BAK process when installing a ROM
- default = 0
#
"OF_SUPPORT_ALL_BLOCK_OTA_UPDATES" [LEGACY]
- Set this to 1 to enable support for block-based incremental OTA on custom ROMs that have this feature
- If enabled, flashing a custom ROM will run the same OTA_BAK/OTA_RES processes as with MIUI
- This setting is incompatible with OF_DISABLE_MIUI_SPECIFIC_FEATURES/OF_TWRP_COMPATIBILITY_MODE/FOX_VANILLA_BUILD
- The default position is to support block-based incremental OTA in MIUI ROMs only
- default = 0
#
"OF_NO_MIUI_PATCH_WARNING" [LEGACY]
- Set this to 1 to suppress warnings that not patching MIUI may cause MIUI to not boot, or to overwrite the recovery with stock recovery
- default = 0
#
"OF_DISABLE_MIUI_OTA_BY_DEFAULT"
- Set this to 1 to disable the OTA settings by default, meaning that users have to enable OTA manually
- default = 0
#
"OF_QUICK_BACKUP_LIST"
- Use this to specify the desired default list of partitions selected for "Quick Backup"
- Note: only specify a partition if you mount it in your fstab, else an error will be generated
- The partitions should be separated by a semi-colon, and the list should end with a semi-colon
- Example: export OF_QUICK_BACKUP_LIST="/data;/storage;/persist;"
#
"OF_USE_LOCKSCREEN_BUTTON"
- Set this to 1 to replace the "Swipe up" lockscreen screen with a button
- This is especially useful (for the time being) for 720p screens
- default = 0
#
"FOX_REMOVE_ZIP_BINARY"
- set this to 1 if you do NOT want the InfoZip zip binary to be added (to create zip archives)
- this must be set in a shell script, or at the command line, before building
- the binary will add about 275kb to the size of the recovery image
- default = 0
#
"OF_ADVANCED_SECURITY" (renamed from "FOX_ADVANCED_SECURITY")
- set this to 1 to enable the advanced security features
- this forces ADB and MTP to be disabled until after you enter the recovery (ie, until after
- all decryption/recovery passwords are successfully entered)
- default = 0
#
"FOX_NO_SAMSUNG_SPECIAL" (renamed from "OF_NO_SAMSUNG_SPECIAL")  [LEGACY]
- set this to 1 to disable some operations relating only to Samsung devices - these are:
-   1) appending "SEANDROIDENFORCE" to the recovery image of a Samsung device
-   2) creating an Odin flashable tar file of the recovery image
- all decryption/recovery passwords are successfully entered)
- default = 0
#
"OF_DEVICE_WITHOUT_PERSIST"
- set this to 1 if your device does not have a /persist partition
- default = 0
#
"OF_DISABLE_EXTRA_ABOUT_PAGE"
- set this to 1 to disable display of the extra information under the "About" page
- you only need to do this if trying to display it causes problems
- default = 0
#
"OF_NO_SPLASH_CHANGE"
- set this to 1 to disable changing the splash image
- you only need to do this if trying to change the splash image causes problems
- default = 0
#
"FOX_DELETE_MAGISK_ADDON" [Experimental!!!]
- set this to 1 to remove/disable the magisk addon
- If set, the magisk addon zips will be removed from the OrangeFox installer, and
- the relevant menu will be disabled so that magisk cannot be installed from the "Fox Addons" menu
- this feature is experimental - test very carefully!
- default = 0
#
"OF_REPORT_HARMLESS_MOUNT_ISSUES"
- set this to 1 to preserve the old behaviour of reporting harmless mount issues as errors
- the default setting is either not to report them at all, or to report them for information, rather than as errors
- default = 0
#
"FOX_DELETE_INITD_ADDON"
- set this to 1 to delete the initd addon
- default = 0
#
"FOX_INSTALLER_DEBUG_MODE"
- set this to 1 to put the OrangeFox zip installer in debug mode
- in the debug mode, when the zip is flashed, a large amount of information is written into the install.log file
- this is for developer testing only - you must disable this before release
- default = 0
#
"FOX_ENABLE_APP_MANAGER"
- set this to 1 to enable the OrangeFox App Manager (now disabled by default)
- sometimes there are issues with the App Manager, especially with Android 11 and higher - if you don't care, then use this variable to enable it
- default = 0
#
"FOX_USE_GREP_BINARY"
- set this to 1 to replace the toybox "grep" with a full standalone GNU grep
- this is useful in cases where the original grep is causing problems
- default = 0
#
"FOX_REMOVE_BUSYBOX_BINARY" [OBSOLETE]
- this is obsolete - see "FOX_USE_BUSYBOX_BINARY" below
#
"FOX_USE_BUSYBOX_BINARY" [NEW] [ARM64 only]
- set this to 1 to add a standalone /sbin/busybox binary to the build
- default = 0
#
"FOX_JAVA8_PATH"
- use this to point to the installed java-8 binary
- eg, export FOX_JAVA8_PATH="/usr/lib/jvm/java-8-openjdk/jre/bin/java"
- default = "/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
#
"OF_SPLASH_MAX_SIZE"
- use this to specify the maximum size (in kilobytes) of image files that can safely be used for splash images
- on some devices, the maximum safe size is 65 Kb; on others, the images can be very big (eg, megabytes)
- Note: verify that the maximum value you set is not too big (ie, test it yourself)
- if the splash image chosen by the user is too big, this can easily cause a "System is destroyed" scenario
- in that case, the user will need to flash the recovery image again, via fastboot
- eg, "export OF_SPLASH_MAX_SIZE=128" (ie, 128 Kb maximum)
- default = 4096 (ie, 4mb maximum)
#
"FOX_USE_XZ_UTILS"
- set this to 1 if you want the XZ Utils (lzma, xz) to be added to the build (the binary is about 260kb in size)
- default = 0
#
"FOX_DYNAMIC_SAMSUNG_FIX" [LEGACY]
- set this to 1 to provide a workaround for bug in Samsung exynos dynamic partition devices, which causes a bootloop on encountering some binaries
- when enabled, certain binaries (eg, bash, nano, aapt, etc) are removed from (or not added to) the build 
- use this only if the recovery doesn't boot on your Samsung dynamic partition exynos device
- default = 0
#
"FOX_USE_NANO_EDITOR"
   - set this to 1 if you want the OrangeFox prebuilt nano editor to be added
   - this must be set in a shell script, or at the command line, before building
   - this will add about 400kb to the size of the recovery image
   - if this is not set, and "FOX_EXCLUDE_NANO_EDITOR" is not set, then there will be an attempt to compile 
   - nano from source; if this attempt fails, then you might need to clone the nano sources from upstream
   - default = 0
#
"FOX_EXCLUDE_NANO_EDITOR"
- set this to 1 to exclude every specie of nano from the build
- default = 0
#
"FOX_BUILD_BASH" [Use with caution]
- set this to 1 to build bash from source during the build process; this will replace the standard OrangeFox bash binary
- this might require cloning the bash sources from upstream (or updating them if the current version generates build errors)
- use this with caution; in particular, your shell scripts should use "/system/bin/sh", instead of "/sbin/sh", in the shebang
#
"FOX_USE_SPECIFIC_MAGISK_ZIP"
- use this to point to an alternative Magisk addon installer zip, if the default one does not work well for your device (eg, if it causes bootloops)
-
- eg, "export FOX_USE_SPECIFIC_MAGISK_ZIP=~/Magisk/Magisk-v24.3.zip"
-
-     this will replace (at compile time) the default magisk addon with the one that you specified
- it is the maintainers' responsibility to ensure that the replacement magisk zip is not corrupt, and that it works well with their device
- do not replace the default Magisk zip installer without first having tested the one you want to use on a full
- range of stock and custom ROMs across all Android versions available for your device
- default = the version that is currently in the vendor tree
#
"FOX_VARIANT"
- Use this if building a specific variant for your device (eg, for MIUI, or FBE, or whatever variant for which the build is specific)
- eg, export FOX_VARIANT=MIUI
- default = default
#
"FOX_CUSTOM_BINS_TO_SDCARD" [EXPERIMENTAL WiP]
- This is *highly experimental* and should be considered as work-in-progress. It is very fiddly to use, and must be used with *extreme caution*
- You should only use this if it is ABSOLUTELY NECESSARY. It has too many potential issues
- This can be used to move some big binaries to the internal storage, instead of being located in the recovery ramdisk. This will reduce
- the size of the recovery ramdisk, and those binaries will be made available at runtime. 
- How the binaries are made available to the recovery at runtine depends on the value given to this variable
- Possible values:
- 	"1" = copy the files to the ramdisk at runtime
-	"2" = create symlinks at runtime to the files in the internal storage; 
- 	"3" = create symlinks at build time to the files in the internal storage;
-
- Additional required steps:
-	You must insert the code on the next line into your device tree's postrecoveryboot.sh
		[ -f /sbin/from_fox_sd.sh ] && source /sbin/from_fox_sd.sh
-
- Notes:
- * Some build vars are not compatible with this one (eg, FOX_USE_BASH_SHELL; FOX_ASH_IS_BASH; FOX_DYNAMIC_SAMSUNG_FIX; FOX_USE_GREP_BINARY)
- * When using this build variable, you MUST ALWAYS do a CLEAN BUILD - everytime you build
- * Users MUST flash the OrangeFox zip, *not* the img - otherwise the binaries will not be available to the recovery
- * If a user formats /data or deletes the /sdcard/Fox/FoxFiles/ folder, then the binaries will not be available to the recovery; the OrangeFox zip must be flashed again
- * If decryption does not work, then the binaries will not be available to the recovery
#
"OF_FORCE_PREBUILT_KERNEL" [NEW]
- Set this to 1 to avoid the new 'NO KERNEL CONFIG' error, when using a prebuilt kernel
- default = 0
#
"OF_SKIP_DECRYPTED_ADOPTED_STORAGE"
- Set to 1 to skip adopted storage decryption (only kicks in if the installed ROM is higher than Android 11 and can prevent certain A12 bootloops)
- default = 0
#
"OF_ENABLE_LPTOOLS"
- Set to 1 to add phhusson's lptools to the build.
- This requires syncing the lptools sources (just run "repo sync" from the usual place, or follow the instructions in the error message that will be generated if the sources are missing)
- default = 0
#
"FOX_PATCH_VBMETA_FLAG" (renamed from "OF_PATCH_VBMETA_FLAG") [EXPERIMENTAL WiP]
- Set to 1 to instruct magiskboot v24+ to always patch the vbmeta header when patching the recovery/boot image
- It should not be necessary to use this variable under normal circumstances
- Do *NOT* use this variable unless you are sure of what you are doing (and only if you are getting bootloops after flashing OrangeFox or Magisk or after changing the splash image)
- This is *experimental* and should be considered as work-in-progress. You should test your builds thoroughly to make sure that everything works as expected
- default = 0
#
"OF_FIX_DECRYPTION_ON_DATA_MEDIA" [NEW]
- Set to 1 if decryption fails on your device, despite all efforts. This may solve the problem - and it may not solve it at all
- Most devices should NOT need this at all. But some devices (eg, violet, and some Realme devices) need this setting
- default = 0
#
"FOX_VIRTUAL_AB_DEVICE" (renamed from "OF_VIRTUAL_AB_DEVICE")
- Set to 1 to signify that the device is definitely a native Android 11+ Virtual A/B ("VAB") device
- If this is set, some other relevant variables are enabled automatically (eg, "FOX_AB_DEVICE" "FOX_VANILLA_BUILD", etc)
- default = 0
#
"OF_DYNAMIC_FULL_SIZE" [NEW]
- This is for Virtual A/B devices only
- Use this to specify the actual space of the "super" partition for ROM installations (instead of using update_engine's calculated allocatable space)
- It is only useful if flashing a stock ROM fails, with an error "The maximum size of all groups for the target slot ... has exceeded allocatable space for dynamic partitions..."
- The exact size of "super" partition (in kb) should be used
- The size *must* be ascertained correctly (possibly, by running "fastboot getvar partition-size:super", and then converting the result from hex to decimal)
- Do *NOT* use this var unless you are absolutely sure of what you are doing; it is your responsibility to ensure that the value supplied is correct
- For most devices, it should not be needed at all
-
- 	eg, "export OF_DYNAMIC_FULL_SIZE=9126805504"
-
- default = none
#
"OF_NO_REFLASH_CURRENT_ORANGEFOX" [NEW]
- This is for Virtual A/B devices only
- if this is enabled, the following features will automatically be removed
   	* "Flash Current OrangeFox"
   	* "Reflash OrangeFox after flashing a ROM"
- default = 0
#
"FOX_VENDOR_BOOT_RECOVERY" (renamed from "OF_VENDOR_BOOT_RECOVERY") [NEW - Experimental]
- Do *NOT* use this variable unless you know what you are doing! Bootloops and bricks are *very* possible!
- Set to 1 to build a recovery for a vendor_boot-as-recovery (hdr4) device (normally, hdr4 devices are also Virtual A/B devices)
- There are currently *many* problems with vendor_boot-as-recovery, and custom recoveries are at a very early stage of development
- If this is enabled, the following features will automatically be removed
   	* Changing the OrangeFox splash image/logo
   	* "Flash Current OrangeFox"
   	* "Reflash OrangeFox after flashing a ROM"
- the zip installer that is created will also include the recovery ramdisk image ("vendor_ramdisk_recovery.cpio")
- if this is enabled, the proper way to flash the built recovery is to reboot an installed working recovery to "fastbootd" mode,
- and extract and flash the recovery ramdisk image by running the command: "fastboot flash vendor_boot:recovery vendor_ramdisk_recovery.cpio"
- Do NOT flash the zip installer itself, unless you have both of you ROM's original boot.img and vendor_boot.img, *and* know how to recover the device from bootloops or bricks
- This is because the outcome of flashing the recovery.img is *unpredictable* - it might be fine, or brick the device, or make the ROM unbootable; any of these is equally possible
- You really SHOULD stay away from using this variable unless you are a *highly technical risk-taker*, and you can fix any problem *on your own*. You have been warned!
- default = 0
#
"OF_NO_ADDITIONAL_MIUI_PROPS_CHECK" [NEW]
- Set to 1 to disable additional checks for MIUI ROMs
- This is useful for non-Xiaomi devices, and older Xiaomi devices that do not have Android 12+ MIUI
- This might shave about half a second off the bootup times (not much, but every half-second counts!)
#
"OF_DEFAULT_TIMEZONE" [NEW]
- Use this to change the default time zone
- eg, export OF_DEFAULT_TIMEZONE="CET-1"
- It is your responsibility to supply a valid timezone (see gui/theme/common/watch.xml for examples)
- default = "CET-1;CEST,M3.5.0,M10.5.0"
#
"OF_ENABLE_FS_COMPRESSION" [NEW - Experimental]
- Set this to 1 to enable f2fs filesystem compression
- This requires support in your kernel, and the appropriate fstab flags
- Do not use - unless you know what you are doing, and you also know that every ROM that you will use supports fscompression
- default = 0
#
"FOX_INSTALLER_DISABLE_AUTOREBOOT" [NEW]
- Set this to 1 to prevent the OrangeFox installer from rebooting to recovery automatically after installing OrangeFox
- Do NOT use in release builds!
- This should only be used for pre-release testing purposes, and even then, only if absolutely necessary
- The installer already does not perform an autoreboot when appropriate (eg, vAB/AB devices) if flashing from OrangeFox, so it should not be necessary to use this setting
- default = 0
#
"OF_MANUAL_ROOT_VENDOR_ERROR_FIX" [NEW]
- Set this to 1 to work around "cannot delete non-empty directory: root/vendor" build errors
- This should not be used unless absolutely necessary, because that build error shows that something is wrong with the device tree, and that really should be fixed
- This is only a work-around, not a fix
- default = 0
#
"OF_LOOP_DEVICE_ERRORS_TO_LOG" [NEW]
- Set this 1 to prevent spamming the recovery console with noisy loop device mount errors (instead it will just write the errors to the log file)
- This is only a work-around, not a fix; the errors show that something is wrong with the device tree, and that really should be fixed
- default = 0
#
"FOX_USE_DATA_RECOVERY_FOR_SETTINGS" [NEW] [EXPERIMENTAL]
- Set this to 1 to use /data/recovery/Fox/ for storage, instead of /sdcard/Fox/
- This has only one advantage - because /data/recovery/ is always available, settings can be saved and used even when decryption fails
- The big disadvantage is that /data/recovery/ is erased every time you wipe the data partition - and so the settings will be lost even if don't format data
- This feature is HIGHLY EXPERIMENTAL! - do NOT use it without prolonged and deep testing in every possible scenario!
- default = 0
#
"OF_DISPLAY_FORMAT_FILESYSTEMS_DEBUG_INFO" [NEW]
- Set this to 1 to display debug information about the target partition when formatting data
- This is mainly for use during testing; do not use for release builds
- default = 0
#
"OF_FORCE_USE_RECOVERY_FSTAB" [NEW] (renamed from OF_LEGACY_PROCESS_FSTAB")
- If decryption fails on an Mtk device when it was working before, try setting this to 1 to bypass processing of ROM fstabs, and only use the recovery's fstab
- This var is equivalent to setting "TW_SKIP_ADDITIONAL_FSTAB := true" in BoardConfig.mk or device.mk
- This should not be used unless absolutely necessary
- default = 0
#
"OF_DEFAULT_KEYMASTER_VERSION" [NEW]
- Use this to specify the default version for the keymaster services used for decryption
- The value given to this will be used if the keymaster version cannot be determined automatically
- If you use this, you should make sure that you are specifying the correct keymaster version provided by your device tree
- eg, "export OF_DEFAULT_KEYMASTER_VERSION=4.0" (meaning using keymaster version 4.0 by default)
- This var is equivalent to setting a value for the "keymaster_ver" prop in system.prop or device.mk
- If the installed ROM uses a different keymaster version, that will be used instead and will override whatever is specified here
- If you do not want your specified value to be overridden, then set "TW_FORCE_KEYMASTER_VER := true" in your BoardConfig.mk or device.mk
- default = empty
#
"OF_NO_KEYMASTER_VER_4X" [NEW]
- Set this to 1 to disable the merging at runtime of keymaster 4.0 and 4.1 props to "4.x"
- Only use this as a last resort
- There is no reason to use it if your build system is up-to-date (ie, if you have run a "repo sync" after 10 October 2023)
- Do not use this unless your recovery build is hanging at the OrangeFox logo (and even then, you should first run a "repo sync" to update your build system before trying this)
- default = 0
#
"FOX_SETTINGS_ROOT_DIRECTORY" [NEW] [EXPERIMENTAL!!]
- This allows specifying a custom settings directory for the recovery (ie, instead of the default "/sdcard/Fox/")
- If used, you should specify the directory on the device that OrangeFox should use for its settings/configuration stuff
- The specified directory name should ALWAYS be terminated with a front-slash (ie, "/"); and it must ALWAYS be available on the device whenever the recovery is running
- OrangeFox will automatically append "Fox" to the end of the directory that is specified
-
- Examples:
-
-  "export FOX_SETTINGS_ROOT_DIRECTORY=/sdcard/PRIVATE/"
-
-  "export FOX_SETTINGS_ROOT_DIRECTORY=/sdcard1/MyDev/"
-
- This is a HIGHLY EXPERIMENTAL feature, which may have bugs; use with GREAT caution, and with lots of testing
- It is essential for the programmer's convenience, at the development stages, to avoid the need for constant reconfigurations during testing
- Do NOT use this in a release build; and you CANNOT use it in a Stable build (the build process will simply terminate with an error)
-
- default = none
#
"FOX_BASH_TO_SYSTEM_BIN" [NEW]
- Set this to 1 to install the prebuilt bash binary in /system/bin/, instead of the standard /sbin/ (at build time)
- If this is used, a symlink is created in /sbin/ to the binary in /system/bin/
- default = 0
#
"OF_OPTIONS_LIST_NUM" [NEW]
- This can be used to override the default number of items on the "options" listbox (when flashing a zip) before a scrollbar is created
- This should NOT be used on devices with a 16:9 screen
- It is your responsibility to test the results of any value you use
- The new number must be between 5 and 8, else the default will be used
- Example:
-   "export OF_OPTIONS_LIST_NUM=6"
- default = 4
#
"OF_USE_LEGACY_BATTERY_SERVICES" [NEW]
- Set to 1 if the battery percentage in the status bar is not working properly (eg, if it shows 100% at all times)
- default = 0
#
"OF_WIPE_METADATA_AFTER_DATAFORMAT" [NEW] [EXPERIMENTAL!!]
- Set to 1 to automatically wipe /metadata after formatting the data partition
- Use with care: use only if the device/ROM has a metadata partition - and - formatting /data doesn't automatically wipe it
- It is up to you to verify for yourself that this is needed in the first place, and if used, that it works as expected
- default = 0
#
"OF_BIND_MOUNT_SDCARD_ON_FORMAT" [NEW] [HIGHLY EXPERIMENTAL!!]
- Set to 1 to automatically bind-mount /sdcard to /data/media/0 after formatting data, to resolve MTP issues
- Note that such bind-mounting can break encryption; so only use this if it is absolutely necessary
- This is a HIGHLY EXPERIMENTAL feature, which may have bugs; use with EXTREME caution, and with lots of testing, especially with lockscreen PINs/passwords
- default = 0
#
"OF_UNMOUNT_SDCARDS_BEFORE_REBOOT" [NEW]
- Set to 1 to attempt to unmount the SD cards before rebooting
- default = 0
#
"FOX_USE_UPDATED_MAGISKBOOT" [NEW]
- Set to 1 to use a newer (2024+) magiskboot binary. This may be required for very new devices.
- This should be tested vigorously, because the updated magiskboot binaries can cause issues (eg, with changing the slash screen).
- If using this is required on a device, but it causes issues with changing the splash screen, then you might need to
- disable changing the splash screen with "OF_NO_SPLASH_CHANGE".
- default = 0
#
"FOX_EXCLUDE_ZIP" [NEW]
- Set to 1 to skip building the InfoZip zip binary from source and use the prebuilt version instead
- If this is used, "TW_EXCLUDE_ZIP := true" will also be set automatically
- default = 0
#
"FOX_COMPRESS_EXECUTABLES" [NEW] [EXPERIMENTAL!!]
- Set to 1 to compress (with upx) executable binaries (in /sbin/ and /system/bin/ by default) if they are bigger than 128kb
- This feature is experimental. Use with great care; subject every build to extensive testing to ensure that nothing is broken
- If set to "1", qualifying binaries in /sbin/ and /system/bin/ will be compressed
- If you want to choose manually the directories to be processed, then specify them, instead of using "1" (eg, export FOX_COMPRESS_EXECUTABLES="/sbin /system/bin /vendor/bin")
- default = 0
#
"OF_FORCE_DATA_FORMAT_F2FS" [NEW]
- Set this to 1 to force the selection of f2fs when formatting data; this is only needed when f2fs is never selected by default
- Use with care! Do NOT use unless you are sure that all targeted ROMs on the device will support f2fs!
- default = 0
# -----------------------------------
