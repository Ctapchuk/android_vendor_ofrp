#!/bin/bash
#
# Custom build script for OrangeFox Recovery Project
#
# Copyright (C) 2018-2019 OrangeFox Recovery Project
# Date: 19 July 2019
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it
#
#
# ******************************************************************************
# Optional (new) environment variables - to be declared before building
#
# It is best to declare these in a script that you will use for building 
#
# "OF_AB_DEVICE"
#    - whether the device is an A/B device
#    - set to 1 if your device is an A/B device (** make sure that it really is **)
#    - if you enable this (by setting to 1), you must also (before building):
#         set "OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1" and
#         set "OF_USE_MAGISKBOOT=1"
#    - default = 0
#
# "FOX_PORTS_TMP" 
#    - point to a custom temp directory for creating the zip installer
#
# "FOX_PORTS_INSTALLER" 
#    - point to a custom directory for amended/additional installer files 
#    - the contents will simply be copied over before creating the zip installer
#
# "FOX_LOCAL_CALLBACK_SCRIPT"
#    - point to a custom "callback" script that will be executed just before creating the final recovery image
#    - eg, a script to delete some files, or add some files to the ramdisk
#
# "BUILD_2GB_VERSION"
#    - whether to build a stripped down "lite" version for 2GB devices
#    - default = 0
#
# "FOX_REPLACE_BUSYBOX_PS"
#    - set to 1 to replace the (stripped down) busybox version of the "ps" command
#    - if this is defined, the busybox "ps" command will be replaced by a fuller (arm64) version
#    - default = 0
#    - this should NOT be enabled for arm32 devices
#
# "FOX_RECOVERY_INSTALL_PARTITION"
#    - !!! this should normally BE LEFT WELL ALONE !!!
#    - set this ONLY if your device's recovery partition is in a location that is
#      different from the default "/dev/block/bootdevice/by-name/recovery"
#    - default = "/dev/block/bootdevice/by-name/recovery"
#
# "FOX_18_9_DISPLAY"
#    - Deprecated
#    - set this to 1 if your device has an 18:9 display (eg, vince, chiron, whyred)
#    - default = 0
#
# "FOX_USE_LZMA_COMPRESSION"
#    - set this to 1 if you want to use (slow but better compression) lzma compression for your ramdisk; 
#    - if set to 1, it will replace the busybox "lzma" and "xz" applets with a full version
#    - * this requires you to have an up-to-date lzma binary in your build system, and 
#    - * set these in your BoardConfig: 
#    -     LZMA_RAMDISK_TARGETS := [boot,recovery]
#    -     BOARD_NEEDS_LZMA_MINIGZIP := true
#    - * your kernel must also have built-in lzma compression support
#    - default = 0 (meaning use standard gzip compression (fast, but doesn't compress as well))
#
# "FOX_USE_NANO_EDITOR"
#    - set this to 1 if you want the nano editor to be added
#    - this must be set in a shell script, or at the command line, before building
#    - this will add about 300kb to the size of the recovery image
#    - default = 0
#
# "FOX_USE_BASH_SHELL"
#    - set this to 1 if you the bash shell to replace the busybox "sh"
#    - default = 0
#    - if not set, bash will still be copied, but it will not replace "sh"
#
# "FOX_REMOVE_BASH"
#    - set this to 1 if you want to remove bash completely from the recovery
#    - default = 0
#
# "OF_DONT_PATCH_ON_FRESH_INSTALLATION"
#    - set to 1 to prevent patching dm-verity and forced-encryption when the OrangeFox zip is flashed
#    - default = 0
#    - if dm-verity is enabled in the ROM, and this is turned on, there will be a bootloop
#
#  "OF_TWRP_COMPATIBILITY_MODE" ; "OF_DISABLE_MIUI_SPECIFIC_FEATURES"
#    - set either of them to 1 to enable stock TWRP-compatibility mode 
#    - in this mode, MIUI OTA, and dm-verity/forced-encryption patching will be disabled
#    - default = 0
#    - ** this is quite experimental at the moment *** - use at your own risk!!!
# 
# "OF_DONT_PATCH_ENCRYPTED_DEVICE"
#    - set to 1 to avoid patching forced-encryption on encrypted devices
#    - default = 0
#    - this should NOT be used unless the default is causing issues on your device
#
# "OF_USE_MAGISKBOOT"
#    - set to 1 to use magiskboot for patching the ROM's boot image
#    - else, mkbootimg/unpackbootimg will be used
#    - magiskboot does a better job of patching boot images, but is slow
#    - default = 0
#
# "OF_USE_MAGISKBOOT_FOR_ALL_PATCHES"
#    - set to 1 to use magiskboot for all patching of boot images *and* recovery images
#    - this means that mkbootimg/unpackbootimg/lzma will be deleted
#    - if this is set, this script will also automatically set OF_USE_MAGISKBOOT to 1
#    - default = 0
#
# "OF_DISABLE_UPDATEZIP"
#    - set to 1 to disable recovery zip creation
#    - default = 0
#
# "OF_SUPPORT_PRE_FLASH_SCRIPT"
#    - set to 1 to support running a script before flashing zips (other than ROMs)
#    - the script must be called /sbin/fox_pre_flash - and you need to copy it there yourself
#    - default = 0 (in lavender, default=1)
#
# "OF_KEEP_DM_VERITY_FORCED_ENCRYPTION"; 
#    - set to 1 to turn OrangeFox dm-verity forced-encryption settings off by default 
#    - default = 0 (in lavender, default=1)
#
# "OF_CLASSIC_LEDS_FUNCTION"
#    - set to 1 to use the old R9.x Leds function
#    - default = 0 (in polaris, oxygen, dipper and dipper, default=1)
#
# "OF_SKIP_FBE_DECRYPTION" 
#    - set to 1 to skip the FBE decryption routines (prevents hangng at the Fox logo or Redmi/Mi logo)
#    - default = 0 (in dipper, default=1)
#
# "OF_OTA_RES_DECRYPT"
#    - set to 1 to try and decrypt internal storage (instead baling out with an error) during MIUI OTA restore
#    - default = 0
#
# "OF_NO_TREBLE_COMPATIBILITY_CHECK"
#    - set to 1 to disable checking for compatibility.zip in ROMs
#    - default = 0

# "FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER"
#    - set to 1 to use the TWRP build system's tools to build the recovery image
#    - default = 0
#
# "FOX_BUILD_NO_ENCRYPTION"
#    -  set to 1 to avoid building in any encryption support at all
#    - default = 0
#
# "FOX_RESET_SETTINGS"
#    - set to 1 to reset OrangeFox settings to defaults, after installation
#    - default = 0
#
# "FOX_DELETE_AROMAFM"
#    - set to 1 delete AromaFM from the zip installer (for devices where it doesn't work)
#    - default = 0
#
# ******************************************************************************

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}Building OrangeFox...${NC}"

echo -e "${BLUE}-- Setting up environment variables${NC}"

RECOVERY_DIR="recovery"
FOX_VENDOR_PATH=vendor/$RECOVERY_DIR
FOX_WORK=$OUT/FOX_AIK
FOX_RAMDISK="$FOX_WORK/ramdisk"
FOX_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

# build_type
if [ -z "$BUILD_TYPE" ]; then 
   export BUILD_TYPE=Unofficial
fi

# tw_device_version && fox_build
if [ -z "$TW_DEVICE_VERSION" ]; then
   FOX_BUILD=Unofficial
else
   FOX_BUILD=$TW_DEVICE_VERSION
fi

# sort out the out_name
if [ "$BUILD_TYPE" = "Unofficial" ] && [ "$FOX_BUILD" = "Unofficial" ]; then
   FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$FOX_DEVICE
else
   FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$BUILD_TYPE-$FOX_DEVICE
fi

RECOVERY_IMAGE="$OUT/$FOX_OUT_NAME.img"
TMP_VENDOR_PATH="$OUT/../../../../vendor/$RECOVERY_DIR"
DEFAULT_INSTALL_PARTITION="/dev/block/bootdevice/by-name/recovery" # !! DON'T change!!!

# whether to print extra debug messages
DEBUG="0"

# FOX_REPLACE_BUSYBOX_PS: default to 0
if [ -z "$FOX_REPLACE_BUSYBOX_PS" ]; then
   export FOX_REPLACE_BUSYBOX_PS="0"
fi

# magiskboot
if [ "$OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" = "1" ]; then
   export OF_USE_MAGISKBOOT=1
fi

# A/B devices
if [ "$OF_AB_DEVICE" = "1" ]; then
   if [ "$OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" != "1" ] || [ "$OF_USE_MAGISKBOOT" != "1" ]; then
      echo -e "${RED}-- ************************************************************************************************${NC}"
      echo -e "${RED}-- OrangeFox.sh FATAL ERROR - A/B device - but other necessary vars not set. Quitting now ... ${NC}"
      echo -e "${RED}-- ************************************************************************************************${NC}"
      exit 200
   fi
fi

# exports
export FOX_DEVICE TMP_VENDOR_PATH FOX_OUT_NAME FOX_RAMDISK FOX_WORK

# copy recovery.img
cp -r $OUT/recovery.img $RECOVERY_IMAGE

# 2GB version
RECOVERY_IMAGE_2GB=$OUT/$FOX_OUT_NAME"_lite.img"
[ -z "$BUILD_2GB_VERSION" ] && BUILD_2GB_VERSION="0" # by default, build only the full version
#

# expand a directory path
fullpath() {
local T1=$PWD
  [ -z "$1" ] && return
  [ ! -d "$1" ] && {
    echo "$1"
    return
  }
  cd "$1"
  local T2=$PWD
  cd $T1
  echo "$T2"    
}

# expand
expand_vendor_path() {
  FOX_VENDOR_PATH=$(fullpath "$TMP_VENDOR_PATH")
  [ ! -d $FOX_VENDOR_PATH/installer ] && {
     local T="${BASH_SOURCE%/*}"
     T=$(fullpath $T)
     [ -x $T/OrangeFox.sh ] && FOX_VENDOR_PATH=$T
  }
}

# create zip file
do_create_update_zip() {
local WORK_DIR=""
local TDT=$(date "+%d %B %Y")
  echo -e "${BLUE}-- Creating update.zip${NC}"
  FILES_DIR=$FOX_VENDOR_PATH/FoxFiles
  INST_DIR=$FOX_VENDOR_PATH/installer
  
  # did we export tmp directory for OrangeFox ports?
  [ -n "$FOX_PORTS_TMP" ] && WORK_DIR="$FOX_PORTS_TMP" || WORK_DIR="$FOX_VENDOR_PATH/tmp"

  # names of output zip file(s)
  ZIP_FILE=$OUT/$FOX_OUT_NAME.zip
  ZIP_FILE_GO=$OUT/$FOX_OUT_NAME"_lite.zip"
  echo "- Creating $ZIP_FILE for deployment ..."
  
  # clean any existing files
  rm -rf $WORK_DIR
  rm -f $ZIP_FILE_GO $ZIP_FILE

  # recreate dir
  mkdir -p $WORK_DIR
  cd $WORK_DIR

  # copy recovery image
  cp -a $RECOVERY_IMAGE ./recovery.img
   
  # copy installer bins and script 
  cp -ar $INST_DIR/* .

  # copy FoxFiles/ to sdcard/Fox/
  cp -a $FILES_DIR/ sdcard/Fox
  
  # any local changes to a port's installer directory?
  if [ -n "$FOX_PORTS_INSTALLER" ] && [ -d "$FOX_PORTS_INSTALLER" ]; then
     cp -ar $FOX_PORTS_INSTALLER/* . 
  fi
  
  # patch update-binary (which is a script) to run only for the current device 
  # (mido is the default)
  local F="$WORK_DIR/META-INF/com/google/android/update-binary"
  sed -i -e "s/mido/$FOX_DEVICE/g" $F     
  sed -i -e "s/ALT_DEVICE/$FOX_DEVICE_ALT/g" $F     

  # embed the release version
  sed -i -e "s/RELEASE_VER/$FOX_BUILD/" $F

  # embed the build date
  sed -i -e "s/TODAY/$TDT/" $F

  # if a local callback script is declared, run it, passing to it the temporary working directory (Last call)
  # "--last-call" = just before creating the OrangeFox update zip file
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$WORK_DIR" "--last-call"
  fi

  # embed the recovery partition
  if [ -n "$FOX_RECOVERY_INSTALL_PARTITION" ]; then
     echo -e "${RED}- Changing the recovery install partition to \"$FOX_RECOVERY_INSTALL_PARTITION\" ${NC}"
     sed -i -e "s|^RECOVERY_PARTITION=.*|RECOVERY_PARTITION=\"$FOX_RECOVERY_INSTALL_PARTITION\"|" $F
     # sed -i -e "s|$DEFAULT_INSTALL_PARTITION|$FOX_RECOVERY_INSTALL_PARTITION|" $F
  fi

  # A/B devices
  if [ "$OF_AB_DEVICE" = "1" ]; then
     echo -e "${RED}-- A/B device - copying magiskboot to zip installer ... ${NC}"
     cp -a $FOX_RAMDISK/sbin/magiskboot .
     sed -i -e "s|^OF_AB_DEVICE=.*|OF_AB_DEVICE=\"1\"|" $F
  fi

  # Reset Settings
  if [ "$FOX_RESET_SETTINGS" = "1" ]; then
     echo -e "${RED}-- Instructing zip installer to reset OrangeFox settings ... ${NC}"
     sed -i -e "s|^FOX_RESET_SETTINGS=.*|FOX_RESET_SETTINGS=\"1\"|" $F
  fi

  # omit AromaFM ?
  if [ "$FOX_DELETE_AROMAFM" = "1" ]; then
     echo -e "${GREEN}-- Deleting AromaFM ...${NC}"
     rm -rf $WORK_DIR/sdcard/Fox/FoxFiles/AromaFM
  fi

  # create update zip
  ZIP_CMD="zip --exclude=*.git* -r9 $ZIP_FILE ."
  echo "- Running ZIP command: $ZIP_CMD"
  $ZIP_CMD
   
  #  sign zip installer
  #if [ -f $ZIP_FILE ]; then
  #   ZIP_CMD="$FOX_VENDOR_PATH/signature/sign_zip.sh -z $ZIP_FILE"
  #   echo "- Running ZIP command: $ZIP_CMD"
  #   $ZIP_CMD
  #fi

  #Creating ZIP md5
  echo -e "${BLUE}-- Creating md5 for $ZIP_FILE${NC}"
  cd "$OUT" && md5sum "$ZIP_FILE" > "$ZIP_FILE.md5" && cd - > /dev/null 2>&1

  # create update zip for "lite" version
  if [ "$BUILD_2GB_VERSION" = "1" ]; then
  	rm -f ./recovery.img
  	cp -a $RECOVERY_IMAGE_2GB ./recovery.img
  	ZIP_CMD="zip --exclude=*.git* --exclude=OrangeFox*.zip* -r9 $ZIP_FILE_GO ."
  	echo "- Running ZIP command: $ZIP_CMD"
  	$ZIP_CMD
  	#  sign zip installer ("lite" version)
  	# if [ -f $ZIP_FILE_GO ]; then
   #  	   ZIP_CMD="$FOX_VENDOR_PATH/signature/sign_zip.sh -z $ZIP_FILE_GO"
   #  	   echo "- Running ZIP command: $ZIP_CMD"
   #  	   $ZIP_CMD
   #  	fi
    #md5 Go zip
    echo -e "${BLUE}-- Creating md5 for $ZIP_FILE_GO${NC}"
    cd "$OUT" && md5sum "$ZIP_FILE_GO" > "$ZIP_FILE_GO.md5" && cd - > /dev/null 2>&1
  fi
 
  # list files
  echo "- Finished:"
  echo "---------------------------------"
  echo " $(/bin/ls -laFt $ZIP_FILE)"
  if [ "$BUILD_2GB_VERSION" = "1" ]; then
  	echo " $(/bin/ls -laFt $ZIP_FILE_GO)"
  fi
  echo "---------------------------------"
  
  # export the filenames
  echo "ZIP_FILE=$ZIP_FILE">/tmp/oFox00.tmp
  echo "RECOVERY_IMAGE=$RECOVERY_IMAGE">>/tmp/oFox00.tmp
  if [ "$BUILD_2GB_VERSION" = "1" ]; then  
	echo "ZIP_FILE_GO=$ZIP_FILE_GO">>/tmp/oFox00.tmp
  	echo "RECOVERY_IMAGE_GO=$RECOVERY_IMAGE_2GB">>/tmp/oFox00.tmp
  fi	
  
  rm -rf $WORK_DIR # delete OF Working dir 
} # function


# create old_theme zip
do_create_old_theme_zip() {
local INST_DIR=$FOX_VENDOR_PATH/theme_installer
local F=$INST_DIR/pa.zip
local ZIP_FILE=$OUT/ClassicTheme.zip
local ZIP_CMD="zip --exclude=*.git* -r9 $ZIP_FILE ."
   cd $FOX_VENDOR_PATH/Files/classic_theme/
   rm -f $F
   zip -r0 $F * > /dev/null 2>&1
   cd $INST_DIR
   echo "- Running ZIP command: $ZIP_CMD"
   rm -f $ZIP_FILE
   $ZIP_CMD
   echo " $(/bin/ls -laFt $ZIP_FILE)"
   rm -f $F
} # function

# file_getprop <file> <property>
file_getprop() { 
  grep "^$2=" "$1" | cut -d= -f2
}

# ****************************************************
# *** now the real work starts!
# ****************************************************

# get the full FOX_VENDOR_PATH
expand_vendor_path

# is the working directory still there from a previous build? If so, remove it
if [ -d "$FOX_WORK" ]; then
  echo -e "${BLUE}-- Working folder found in OUT. Cleaning up${NC}"
  rm -rf "$FOX_WORK"
fi

# unpack recovery image into working directory
echo -e "${BLUE}-- Unpacking recovery image${NC}"
bash "$FOX_VENDOR_PATH/tools/mkboot" "$OUT/recovery.img" "$FOX_WORK" > /dev/null 2>&1

# copy stuff to the ramdisk
echo -e "${BLUE}-- Copying mkbootimg, unpackbootimg binaries to sbin${NC}"

if [ -z "$TARGET_ARCH" ]; then
  echo "Arch not detected, use arm64"
  TARGET_ARCH="arm64"
fi

case "$TARGET_ARCH" in
 "arm")
      echo -e "${GREEN}-- ARM arch detected. Copying ARM binaries${NC}"
      cp "$FOX_VENDOR_PATH/prebuilt/arm/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR_PATH/prebuilt/arm/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
 "arm64")
      echo -e "${GREEN}-- ARM64 arch detected. Copying ARM64 binaries${NC}"
      cp "$FOX_VENDOR_PATH/prebuilt/arm64/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR_PATH/prebuilt/arm64/unpackbootimg" "$FOX_RAMDISK/sbin"
      cp -a "$FOX_VENDOR_PATH/prebuilt/arm64/resetprop" "$FOX_RAMDISK/sbin"
      ;;
 "x86")
      echo -e "${GREEN}-- x86 arch detected. Copying x86 binaries${NC}"
      cp "$FOX_VENDOR_PATH/prebuilt/x86/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR_PATH/prebuilt/x86/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
 "x86_64")
      echo -e "${GREEN}-- x86_64 arch detected. Copying x86_64 binaries${NC}"
      cp "$FOX_VENDOR_PATH/prebuilt/x86_64/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR_PATH/prebuilt/x86_64/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
    *) echo -e "${RED}-- Couldn't detect current device architecture or it is not supported${NC}" ;;
esac

# build standard (3GB) version
  # copy over vendor FFiles/ and vendor sbin/ stuff before creating the boot image
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Copying: $FOX_VENDOR_PATH/FoxExtras/* to $FOX_RAMDISK/"
  cp -ar $FOX_VENDOR_PATH/FoxExtras/* $FOX_RAMDISK/

  if [ "$FOX_18_9_DISPLAY" = "1" ]; then
      echo -e "${RED}! FOX_18_9_DISPLAY is DEPRECATED${NC}";
  fi
  
  # deal with magiskboot/mkbootimg/unpackbootimg
  if [ "$OF_USE_MAGISKBOOT" != "1" ]; then
      echo -e "${GREEN}-- Not using magiskboot - deleting $FOX_RAMDISK/sbin/magiskboot ...${NC}"
      rm -f "$FOX_RAMDISK/sbin/magiskboot"
  else
     echo -e "${GREEN}-- This build will use magiskboot for patching boot images ...${NC}"
     if [ "$OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" = "1" ]; then
        echo -e "${GREEN}-- Using magiskboot [$FOX_RAMDISK/sbin/magiskboot] - deleting mkbootimg/unpackbootimg ...${NC}"
        rm -f $FOX_RAMDISK/sbin/mkbootimg
        rm -f $FOX_RAMDISK/sbin/unpackbootimg
     fi
  fi

  # replace busybox ps with our own ?
  if [ "$TW_USE_TOOLBOX" = "true" ]; then # if using toybox, then we don't need this
     rm -f "$FOX_RAMDISK/FFiles/ps"
  else
     if [ "$FOX_REPLACE_BUSYBOX_PS" = "1" ]; then
        if [ -f "$FOX_RAMDISK/FFiles/ps" ]; then
           echo -e "${GREEN}-- Replacing the busybox \"ps\" command with our own full version ...${NC}"
  	   rm -f $FOX_RAMDISK/sbin/ps
  	   ln -s /FFiles/ps $FOX_RAMDISK/sbin/ps
        fi
     fi
  fi

  # replace busybox lzma (and "xz") with our own 
  # use the full "xz" binary for lzma, and for xz - smaller in size, and does the same job
  #if [ "$FOX_USE_LZMA_COMPRESSION" = "1" ]; then
  if [ "$OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" != "1" ]; then
     echo -e "${GREEN}-- Replacing the busybox \"lzma\" command with our own full version ...${NC}"
     rm -f $FOX_RAMDISK/sbin/lzma
     rm -f $FOX_RAMDISK/sbin/xz
     cp -a $FOX_VENDOR_PATH/Files/xz $FOX_RAMDISK/sbin/lzma
     ln -s lzma $FOX_RAMDISK/sbin/xz
  fi
    
  # Include bash shell ?
  if [ "$FOX_REMOVE_BASH" = "1" ]; then
     export FOX_USE_BASH_SHELL="0"
  else
     echo -e "${GREEN}-- Copying bash ...${NC}"
     cp -a $FOX_VENDOR_PATH/Files/bash $FOX_RAMDISK/sbin/bash
     cp -a $FOX_VENDOR_PATH/Files/fox.bashrc $FOX_RAMDISK/etc/bash.bashrc
     chmod 0755 $FOX_RAMDISK/sbin/bash
  fi
  
  # replace busybox "sh" with bash ?
  if [ "$FOX_USE_BASH_SHELL" = "1" ]; then
     if [ -f "$FOX_RAMDISK/sbin/sh" ]; then
        echo -e "${GREEN}-- Replacing the busybox \"sh\" command with bash ...${NC}"
  	rm -f $FOX_RAMDISK/sbin/sh
  	ln -s bash $FOX_RAMDISK/sbin/sh
     fi
  fi

  # Include nano editor ?
  if [ "$FOX_USE_NANO_EDITOR" = "1" ]; then
      echo -e "${GREEN}-- Copying nano editor ...${NC}"
      cp -af $FOX_VENDOR_PATH/Files/nano/ $FOX_RAMDISK/FFiles/
      cp -af $FOX_VENDOR_PATH/Files/nano/sbin/nano $FOX_RAMDISK/sbin/
  fi

  # Include mmgui
  cp -a $FOX_VENDOR_PATH/Files/mmgui $FOX_RAMDISK/sbin/mmgui
  chmod 0755 $FOX_RAMDISK/sbin/mmgui

  # Include aapt
  cp -a $FOX_VENDOR_PATH/Files/aapt $FOX_RAMDISK/sbin/aapt
  chmod 0755 $FOX_RAMDISK/sbin/aapt

  # Include text files
  cp -a $FOX_VENDOR_PATH/Files/credits.txt $FOX_RAMDISK/twres/credits.txt
  cp -a $FOX_VENDOR_PATH/Files/translators.txt $FOX_RAMDISK/twres/translators.txt
  cp -a $FOX_VENDOR_PATH/Files/changelog.txt $FOX_RAMDISK/twres/changelog.txt

  # if a local callback script is declared, run it, passing to it the ramdisk directory (first call)
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$FOX_RAMDISK" "--first-call"
  fi
  #
  # repack
  echo -e "${BLUE}-- Repacking and copying recovery${NC}"
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Running command: bash $FOX_VENDOR_PATH/tools/mkboot $FOX_WORK $RECOVERY_IMAGE ***"
  SAMSUNG_DEVICE=$(file_getprop "$FOX_WORK/ramdisk/prop.default" "ro.product.manufacturer")
  if [ "$SAMSUNG_DEVICE" = "samsung" ]; then
     echo -e "${RED}-- Appending SEANDROIDENFORCE to $FOX_WORK/kernel ${NC}"
     [ -e "$FOX_WORK/kernel" ] && echo -n "SEANDROIDENFORCE" >> "$FOX_WORK/kernel"
  fi
  bash "$FOX_VENDOR_PATH/tools/mkboot" "$FOX_WORK" "$RECOVERY_IMAGE" > /dev/null 2>&1
  if [ "$SAMSUNG_DEVICE" = "samsung" ]; then
     echo -e "${RED}-- Appending SEANDROIDENFORCE to $RECOVERY_IMAGE ${NC}"
     echo -n "SEANDROIDENFORCE" >> $RECOVERY_IMAGE
  fi
  cd "$OUT" && md5sum "$RECOVERY_IMAGE" > "$RECOVERY_IMAGE.md5" && cd - > /dev/null 2>&1
# end: standard version

#: build "lite" (2GB) version (virtually obsolete now) #
if [ "$BUILD_2GB_VERSION" = "1" ]; then
	echo -e "${BLUE}-- Repacking and copying the \"lite\" version of recovery${NC}"
	FFil="$FOX_RAMDISK/FFiles"
	rm -rf $FFil/OF_initd
	rm -rf $FFil/AromaFM
	rm -rf $FFil/nano
	rm -f $FOX_RAMDISK/sbin/nano
	rm -f $FOX_RAMDISK/sbin/bash
	rm -f $FOX_RAMDISK/sbin/aapt
	rm -f $FOX_RAMDISK/etc/bash.bashrc
  	if [ "$FOX_USE_BASH_SHELL" = "1" ]; then
     	   if [ -h "$FOX_RAMDISK/sbin/sh" ]; then
              echo -e "${GREEN}-- Replacing bash 'sh' with busybox 'sh' ...${NC}"
  	      rm -f $FOX_RAMDISK/sbin/sh
  	      ln -s busybox $FOX_RAMDISK/sbin/sh
     	   fi
 	fi
	[ "$DEBUG" = "1" ] && echo "*** Running command: bash $FOX_VENDOR_PATH/tools/mkboot $FOX_WORK $RECOVERY_IMAGE_2GB ***"
	bash "$FOX_VENDOR_PATH/tools/mkboot" "$FOX_WORK" "$RECOVERY_IMAGE_2GB" > /dev/null 2>&1
  	if [ "$SAMSUNG_DEVICE" = "samsung" ]; then
     	   echo -e "${RED}-- Appending SEANDROIDENFORCE to $RECOVERY_IMAGE_2GB ${NC}"
     	   echo -n "SEANDROIDENFORCE" >> $RECOVERY_IMAGE_2GB
  	fi
	cd "$OUT" && md5sum "$RECOVERY_IMAGE_2GB" > "$RECOVERY_IMAGE_2GB.md5" && cd - > /dev/null 2>&1
fi
# end: "GO" version

# create update zip installer
if [ "$OF_DISABLE_UPDATEZIP" != "1" ]; then
	do_create_update_zip
else
	echo -e "${RED}-- Skip creating recovery zip${NC}"
fi

# create old theme zip file
do_create_old_theme_zip

#Info
echo -e ""
echo -e ""
cat $FOX_VENDOR_PATH/Files/FoxBanner
echo -e ""
echo -e ""
echo -e "===================${BLUE}Finished building OrangeFox${NC}==================="
echo -e ""
echo -e "${GREEN}Recovery image:${NC} $RECOVERY_IMAGE"
echo -e "          MD5: $RECOVERY_IMAGE.md5"
if [ "$OF_DISABLE_UPDATEZIP" != "1" ]; then
	echo -e ""
	echo -e "${GREEN}Recovery zip:${NC} $ZIP_FILE"
	echo -e "          MD5: $ZIP_FILE.md5"
echo -e ""
fi
echo -e "=================================================================="

# OrangeFox Lite
if [ "$BUILD_2GB_VERSION" = "1" ]; then
echo -e ""
echo -e ""
echo -e "---------------${BLUE}Finished building OrangeFox Lite Edition${NC}---------------"
echo -e ""
echo -e "${GREEN}Recovery image:${NC} $RECOVERY_IMAGE_2GB"
echo -e "          MD5: $RECOVERY_IMAGE_2GB.md5"
if [ "$OF_DISABLE_UPDATEZIP" != "1" ]; then
echo -e ""
echo -e "${GREEN}Recovery zip:${NC} $ZIP_FILE_GO"
echo -e "          MD5: $ZIP_FILE_GO.md5"
echo -e ""
fi
echo -e "=================================================================="
fi
#

echo -e ""
echo -e ""
echo -e "===========================${BLUE}Classic theme${NC}=========================="
echo -e ""
echo -e "${GREEN}ZIP File:${NC} $OUT/ClassicTheme.zip"
echo -e ""
echo -e "=================================================================="

# end!
