#!/bin/bash
#
# Custom build script for OrangeFox Recovery Project
#
# Copyright (C) 2018-2019 OrangeFox Recovery Project
# Date: 15 April 2019
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
#    - set to 1 to use magisboot for all patching of boot images *and* recovery images
#    - this means that mkbootimg/unpackbootimg/lzma will be deleted
#    - if this is set, this script will also automatically set OF_USE_MAGISKBOOT to 1
#    - default = 0
#
# ******************************************************************************

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}=====================================================================${NC}"
echo -e ""
echo -e "${RED} .d88888b.                                             8888888888                ${NC}"
echo -e "${RED}d88P\" \"Y88b                                            888                       ${NC}"
echo -e "${RED}888     888                                            888                       ${NC}"
echo -e "${RED}888     888 888d888 8888b.  88888b.   .d88b.   .d88b.  8888888  .d88b.  888  888 ${NC}"
echo -e "${RED}888     888 888P\"      \"88b 888 \"88b d88P\"88b d8P  Y8b 888     d88\"\"88b \`Y8bd8P' ${NC}"
echo -e "${RED}888     888 888    .d888888 888  888 888  888 88888888 888     888  888   X88K   ${NC}"
echo -e "${RED}Y88b. .d88P 888    888  888 888  888 Y88b 888 Y8b.     888     Y88..88P .d8\"\"8b. ${NC}"
echo -e "${RED} \"Y88888P\"  888    \"Y888888 888  888  \"Y88888  \"Y8888  888      \"Y88P\"  888  888 ${NC}"
echo -e "${RED}                                          888                                    ${NC}"
echo -e "${RED}                                     Y8b d88P                                    ${NC}"
echo -e "${RED}                                      \"Y88P\"                                     ${NC}"
echo -e ""
echo -e "${RED}----------------------------Building OrangeFox-----------------------${NC}"

echo -e "${BLUE}-- Setting up environment variables${NC}"

if [ -z "$TW_DEVICE_VERSION" ]; then
   FOX_BUILD=Unofficial
else
   FOX_BUILD=$TW_DEVICE_VERSION
fi

RECOVERY_DIR="recovery"
FOX_VENDOR=vendor/$RECOVERY_DIR
FOX_WORK=$OUT/FOX_AIK
FOX_RAMDISK="$FOX_WORK/ramdisk"
FOX_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)
FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$FOX_DEVICE
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
echo -e "${BLUE}-- Making update.zip${NC}"
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
  
  # copy splash logo to sdcard/Fox/
  cp -a $FOX_RAMDISK/twres/images/splash.png sdcard/Fox/
  
  # any local changes to a port's installer directory?
  if [ -n "$FOX_PORTS_INSTALLER" ] && [ -d "$FOX_PORTS_INSTALLER" ]; then
     cp -ar $FOX_PORTS_INSTALLER/* . 
  fi
  
  # patch update-binary (which is a script) to run only for the current device 
  # (mido is the default)
  local F="$WORK_DIR/META-INF/com/google/android/update-binary"
  sed -i -e "s/mido/$FOX_DEVICE/g" $F     

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
     echo -e "${RED}- Changing the recovery install partiition to \"$FOX_RECOVERY_INSTALL_PARTITION\" ${NC}"
     sed -i -e "s|^RECOVERY_PARTITION=.*|RECOVERY_PARTITION=\"$FOX_RECOVERY_INSTALL_PARTITION\"|" $F
     # sed -i -e "s|$DEFAULT_INSTALL_PARTITION|$FOX_RECOVERY_INSTALL_PARTITION|" $F
  fi

  # A/B devices
  if [ "$OF_AB_DEVICE" = "1" ]; then
     echo -e "${RED}-- A/B device - copying magiskboot to zip installer ... ${NC}"
     cp -a $FOX_RAMDISK/sbin/magiskboot .
     sed -i -e "s|^OF_AB_DEVICE=.*|OF_AB_DEVICE=\"1\"|" $F
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
bash "$FOX_VENDOR/tools/mkboot" "$OUT/recovery.img" "$FOX_WORK" > /dev/null 2>&1

# copy stuff to the ramdisk
echo -e "${BLUE}-- Copying mkbootimg, unpackbootimg binaries to sbin${NC}"

if [ -z "$TARGET_ARCH" ]; then
  echo "Arch not detected, use arm64"
  TARGET_ARCH="arm64"
fi

case "$TARGET_ARCH" in
 "arm")
      echo -e "${GREEN}-- ARM arch detected. Copying ARM binaries${NC}"
      cp "$FOX_VENDOR/prebuilt/arm/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR/prebuilt/arm/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
 "arm64")
      echo -e "${GREEN}-- ARM64 arch detected. Copying ARM64 binaries${NC}"
      cp "$FOX_VENDOR/prebuilt/arm64/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR/prebuilt/arm64/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
 "x86")
      echo -e "${GREEN}-- x86 arch detected. Copying x86 binaries${NC}"
      cp "$FOX_VENDOR/prebuilt/x86/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR/prebuilt/x86/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
 "x86_64")
      echo -e "${GREEN}-- x86_64 arch detected. Copying x86_64 binaries${NC}"
      cp "$FOX_VENDOR/prebuilt/x86_64/mkbootimg" "$FOX_RAMDISK/sbin"
      cp "$FOX_VENDOR/prebuilt/x86_64/unpackbootimg" "$FOX_RAMDISK/sbin"
      ;;
    *) echo -e "${RED}-- Couldn't detect current device architecture or it is not supported${NC}" ;;
esac

# build standard (3GB) version
  # copy over vendor FFiles/ and vendor sbin/ stuff before creating the boot image
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Copying: $FOX_VENDOR_PATH/FoxExtras/* to $FOX_RAMDISK/"
  cp -ar $FOX_VENDOR_PATH/FoxExtras/* $FOX_RAMDISK/

  # Change splash image for 18:9 phones
  if [ "$FOX_18_9_DISPLAY" = "1" ]; then
      echo -e "${GREEN}-- Changing splash for 18:9 display${NC}";
      cp -a $FOX_VENDOR/Files/OrangeFoxSplashScreen.png $FOX_RAMDISK/twres/images/splash.png;
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
     cp -a $FOX_VENDOR/Files/xz $FOX_RAMDISK/sbin/lzma
     ln -s lzma $FOX_RAMDISK/sbin/xz
  fi
    
  # Include bash shell ?
  if [ "$FOX_REMOVE_BASH" = "1" ]; then
     export FOX_USE_BASH_SHELL="0"
  else
     echo -e "${GREEN}-- Copying bash ...${NC}"
     cp -a $FOX_VENDOR/Files/bash $FOX_RAMDISK/sbin/bash
     cp -a $FOX_VENDOR/Files/fox.bashrc $FOX_RAMDISK/etc/bash.bashrc
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
      cp -af $FOX_VENDOR/Files/nano/ $FOX_RAMDISK/FFiles/
      cp -af $FOX_VENDOR/Files/nano/sbin/nano $FOX_RAMDISK/sbin/
  fi

  # Include mmgui
  cp -a $FOX_VENDOR/Files/mmgui $FOX_RAMDISK/sbin/mmgui
  chmod 0755 $FOX_RAMDISK/sbin/mmgui

  # Include aapt
  cp -a $FOX_VENDOR/Files/aapt $FOX_RAMDISK/sbin/aapt
  chmod 0755 $FOX_RAMDISK/sbin/aapt

  # if a local callback script is declared, run it, passing to it the ramdisk directory (first call)
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$FOX_RAMDISK" "--first-call"
  fi
  #
  # repack
  echo -e "${BLUE}-- Repacking and copying recovery${NC}"
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Running command: bash $FOX_VENDOR/tools/mkboot $FOX_WORK $RECOVERY_IMAGE ***"
  bash "$FOX_VENDOR/tools/mkboot" "$FOX_WORK" "$RECOVERY_IMAGE" > /dev/null 2>&1
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
        rm -f $FOX_RAMDISK/sbin/mmgui
	rm -f $FOX_RAMDISK/sbin/aapt
	rm -f $FOX_RAMDISK/etc/bash.bashrc
  	if [ "$FOX_USE_BASH_SHELL" = "1" ]; then
     	   if [ -h "$FOX_RAMDISK/sbin/sh" ]; then
              echo -e "${GREEN}-- Replacing bash 'sh' with busybox 'sh' ...${NC}"
  	      rm -f $FOX_RAMDISK/sbin/sh
  	      ln -s busybox $FOX_RAMDISK/sbin/sh
     	   fi
 	fi
	[ "$DEBUG" = "1" ] && echo "*** Running command: bash $FOX_VENDOR/tools/mkboot $FOX_WORK $RECOVERY_IMAGE_2GB ***"
	bash "$FOX_VENDOR/tools/mkboot" "$FOX_WORK" "$RECOVERY_IMAGE_2GB" > /dev/null 2>&1
	cd "$OUT" && md5sum "$RECOVERY_IMAGE_2GB" > "$RECOVERY_IMAGE_2GB.md5" && cd - > /dev/null 2>&1
fi
# end: "GO" version

# create update zip installer
do_create_update_zip

#Info
echo -e ""
echo -e ""
echo -e "${RED}--------------------Finished building OrangeFox---------------------${NC}"
echo -e "${GREEN}Recovery image: $RECOVERY_IMAGE"
echo -e "          MD5: $RECOVERY_IMAGE.md5${NC}"
echo -e ""
echo -e "${GREEN}Recovery zip: $OUT/$FOX_OUT_NAME.zip"
echo -e "          MD5: $ZIP_FILE.md5${NC}"
echo -e "${RED}==================================================================${NC}"

if [ "$BUILD_2GB_VERSION" = "1" ]; then
echo -e ""
echo -e ""
echo -e "${RED}---------------Finished building OrangeFox Go Edition---------------${NC}"
echo -e "${GREEN}Recovery image: $RECOVERY_IMAGE_2GB"
echo -e "          MD5: $RECOVERY_IMAGE_2GB.md5${NC}"
echo -e ""
echo -e "${GREEN}Recovery zip: $OUT/$ZIP_FILE_GO.zip"
echo -e "          MD5: $ZIP_FILE_GO.md5${NC}"
echo -e "${RED}==================================================================${NC}"
fi
# end!
