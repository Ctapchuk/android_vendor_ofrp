#!/bin/bash
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2018-2024 The OrangeFox Recovery Project
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
# ******************************************************************************
# 24 August 2024
#
# *** This script is for the OrangeFox Android 12.1 manifest ***
#
# For optional environment variables - to be declared before building,
# see "orangefox_build_vars.txt" for full details
#
# It is best to declare them in a script that you will use for building
#
#

# automatically use magiskboot - overrides anything to the contrary in device trees
# other methods for patching recovery/boot images are no longer supported
export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1
export OF_USE_MAGISKBOOT=1

# device name
FOX_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

# The name of this script
THIS_SCRIPT=$(basename $0)

# environment/build-var imports
FOXENV=/tmp/$FOX_DEVICE/fox_env.sh
if [ -f "$FOXENV" ]; then
   source "$FOXENV"
else
   echo "** WARNING: $FOXENV is not found. Your build vars will probably not be implemented. **"
   echo "** You need an up-to-date OrangeFox patch for the AOSP 12.1 manifest. **"
fi

# whether to print extra debug messages
if [ -z "$FOX_BUILD_DEBUG_MESSAGES" ]; then
   export FOX_BUILD_DEBUG_MESSAGES="0"
elif [ "$FOX_BUILD_DEBUG_MESSAGES" = "1" ]; then
   export FOX_BUILD_DEBUG_MESSAGES="1"
   set -o xtrace
fi

# should we use an updated magiskboot binary?
UPDATED=""
if [ "$FOX_USE_UPDATED_MAGISKBOOT" = "1" ]; then
   UPDATED="_updated"
fi

# some colour codes
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREY='\033[0;37m'
LIGHTGREY='\033[0;38m'
WHITEONBLACK='\033[0;40m'
WHITEONRED='\033[0;41m'
WHITEONGREEN='\033[0;42m'
WHITEONORANGE='\033[0;43m'
WHITEONBLUE='\033[0;44m'
WHITEONPURPLE='\033[0;46m'
NC='\033[0m'
TMP_SCRATCH=/tmp/fox_build_000tmp.txt
WORKING_TMP=/tmp/Fox_000_tmp

# make sure we know exactly which commands we are running
CP=/bin/cp
[ ! -x "$CP" ] && CP=cp

UUIDGEN=/usr/bin/uuidgen
[ ! -x "$UUIDGEN" ] && UUIDGEN=uuidgen

# exit function (cleanup first), and return status code
abort() {
  [ -d $WORKING_TMP ] && rm -rf $WORKING_TMP
  [ -f $TMP_SCRATCH ] && rm -f $TMP_SCRATCH
  [ -f $FOXENV ] && rm -f $FOXENV
  exit $1
}

# whether a build var is enabled (accepts "1" or greater, and "true")
# used in FOX_CUSTOM_BINS_TO_SDCARD
function enabled() {
local s="$1"
  if [ -z "$s" -o "$s" = "0" -o "$s" = "false" ]; then
     echo "0"
     return
  fi

  if [ "$s" = "true" ]; then
     echo "1"
     return
  fi
 
  # accept whole numbers only
  if [[ ! "$s" =~ ^[0-9]+$ ]]; then
     echo "0"
     return
  fi

  if [ "$s" -gt "0" ]; then
     echo "1"
  else
     echo "0"
  fi
}

# file_getprop <file> <property>
file_getprop() {
  local F=$(grep -m1 "^$2=" "$1" | cut -d= -f2)
  echo $F | sed 's/ *$//g'
}

# size of file
filesize() {
  [ -z "$1" -o -d "$1" ] && { echo "0"; return; }
  [ ! -e "$1" -a ! -h "$1" ] && { echo "0"; return; }
  stat -c %s "$1"
}

# generate a randomised build id
generate_build_id() {
local cmd="$UUIDGEN -r"
  [ -z "$(which $UUIDGEN)" ] && cmd="cat /proc/sys/kernel/random/uuid"
  $cmd
}

# check out some incompatible settings
if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" = "1" ]; then
   if [ "$FOX_USE_GREP_BINARY" = "1" ]; then
      export FOX_USE_GREP_BINARY=0
      echo -e "${WHITEONRED}-- 'FOX_CUSTOM_BINS_TO_SDCARD': ignoring incompatible build var 'FOX_USE_GREP_BINARY' ... ${NC}"
   fi

   if [ "$FOX_USE_BASH_SHELL" = "1" -o "$FOX_ASH_IS_BASH" = "1" -o "$FOX_DYNAMIC_SAMSUNG_FIX" = "1" ]; then
     	echo -e "${WHITEONRED}-- ERROR! 'FOX_CUSTOM_BINS_TO_SDCARD' is incompatible with FOX_USE_BASH_SHELL or FOX_ASH_IS_BASH or FOX_DYNAMIC_SAMSUNG_FIX !${NC}"
     	echo -e "${WHITEONRED}-- Sort out your build vars! Quitting ... ${NC}"
     	abort 97
   fi
fi

# export whatever has been passed on by build/core/Makefile (we expect at least 4 arguments)
if [ -n "$4" ]; then
   echo "#########################################################################"
   echo "Variables exported from build/core/Makefile:"
   echo "$@"
   export "$@"
   if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
      echo "# - save the vars that we might need later - " &> $TMP_SCRATCH
      echo "MKBOOTFS=\"$MKBOOTFS\"" >>  $TMP_SCRATCH
      echo "TARGET_OUT=\"$TARGET_OUT\"" >>  $TMP_SCRATCH
      echo "TARGET_RECOVERY_ROOT_OUT=\"$TARGET_RECOVERY_ROOT_OUT\"" >>  $TMP_SCRATCH
      echo "RECOVERY_RAMDISK_COMPRESSOR=\"$RECOVERY_RAMDISK_COMPRESSOR\"" >>  $TMP_SCRATCH
      echo "INTERNAL_KERNEL_CMDLINE=\"$INTERNAL_KERNEL_CMDLINE\"" >>  $TMP_SCRATCH
      echo "INTERNAL_RECOVERYIMAGE_ARGS='$INTERNAL_RECOVERYIMAGE_ARGS'" >>  $TMP_SCRATCH
      echo "INTERNAL_MKBOOTIMG_VERSION_ARGS=\"$INTERNAL_MKBOOTIMG_VERSION_ARGS\"" >>  $TMP_SCRATCH
      echo "BOARD_MKBOOTIMG_ARGS='$BOARD_MKBOOTIMG_ARGS'" >>  $TMP_SCRATCH
      echo "BOARD_USES_RECOVERY_AS_BOOT=\"$BOARD_USES_RECOVERY_AS_BOOT\"" >>  $TMP_SCRATCH
      echo "recovery_ramdisk=\"$recovery_ramdisk\"" >>  $TMP_SCRATCH
      echo "recovery_uncompressed_ramdisk=\"$recovery_uncompressed_ramdisk\"" >>  $TMP_SCRATCH
      echo "#" >>  $TMP_SCRATCH
   fi
   echo "#########################################################################"
else
   echo -e "${WHITEONRED}-- Build OrangeFox: FATAL ERROR! ${NC}"
   echo -e "${WHITEONRED}-- You cannot build OrangeFox without patching build/core/Makefile in the build system. Aborting! ${NC}"
   abort 100
fi

# extra check: do we have a properly patched build system?
if [ -z "$FOX_VENDOR_CMD" ]; then
   echo -e "${WHITEONRED}-- OrangeFox build: Fatal ERROR! ${NC}"
   echo -e "${WHITEONRED}-- Your build system is not properly patched for OrangeFox. Quitting ... ${NC}"
   abort 100
fi

# vendor_boot as recovery
IS_VENDOR_BOOT_RECOVERY=0
if [ "$FOX_VENDOR_BOOT_RECOVERY" = "1" -o "$BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT" = "true" -o "$BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT" = "true" -o -n "$INSTALLED_VENDOR_BOOTIMAGE_TARGET" ]; then
   IS_VENDOR_BOOT_RECOVERY=1
fi

# A/B
IS_AB_DEVICE=0
if [ "$FOX_AB_DEVICE" = "1" -o "$OF_AB_DEVICE" = "1" -o "$AB_OTA_UPDATER" = "true" -o "$BOARD_USES_RECOVERY_AS_BOOT" = "true" ]; then
   IS_AB_DEVICE=1
fi

# virtual A/B (VAB)
IS_VIRTUAL_AB_DEVICE=0
if [ "$FOX_VIRTUAL_AB_DEVICE" = "1" -o "$OF_VIRTUAL_AB_DEVICE" = "1" -o "$FOX_VENDOR_BOOT_RECOVERY" = "1" -o "$PRODUCT_VIRTUAL_AB_OTA" = "true" ]; then
   IS_VIRTUAL_AB_DEVICE=1
   IS_AB_DEVICE=1
fi

if [ "$IS_AB_DEVICE" = "1" ]; then
    if [ -n "$BOARD_BOOT_HEADER_VERSION" ]; then
       [ "$BOARD_BOOT_HEADER_VERSION" -gt 2 ] && IS_VIRTUAL_AB_DEVICE="1"
    fi
fi

# Disable the init.d addon for vAB devices
if [ "$IS_VIRTUAL_AB_DEVICE" = "1" ]; then
    echo -e "${GREEN}-- The device is a virtual A/B device  - disabling the init.d addon .... ${NC}"
    export FOX_DELETE_INITD_ADDON=1
fi

# Virtual A/B and vendor_boot recovery devices?
if  [ "$IS_VENDOR_BOOT_RECOVERY" = "1" ]; then
    COMPILED_IMAGE_FILE="vendor_boot.img"
elif [ "$BOARD_USES_RECOVERY_AS_BOOT" = "true" ]; then
    COMPILED_IMAGE_FILE="boot.img"
else
    COMPILED_IMAGE_FILE="recovery.img"
fi

# vanilla build
IS_VANILLA_BUILD=0
if [ "$FOX_VANILLA_BUILD" = "1" -o "$OF_VANILLA_BUILD" = "1" ]; then
   IS_VANILLA_BUILD=1
fi

RECOVERY_DIR="recovery"
FOX_VENDOR_PATH=vendor/$RECOVERY_DIR
#
if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
	echo -e "${RED}Building OrangeFox...${NC}"
	FOX_WORK="$TARGET_RECOVERY_ROOT_OUT"
	FOX_RAMDISK="$TARGET_RECOVERY_ROOT_OUT"
	DEFAULT_PROP_ROOT="$TARGET_RECOVERY_ROOT_OUT/../../root/default.prop"
else
	FOX_WORK=$OUT/FOX_AIK
	FOX_RAMDISK="$FOX_WORK/ramdisk"
	DEFAULT_PROP_ROOT="$FOX_WORK/../root/default.prop"
fi
echo -e "${BLUE}-- Setting up environment variables${NC}"

# transitional after renaming of build vars
if [ -n "$OF_NO_SAMSUNG_SPECIAL" -a -z "$FOX_NO_SAMSUNG_SPECIAL" ]; then
   export FOX_NO_SAMSUNG_SPECIAL=$OF_NO_SAMSUNG_SPECIAL
   echo -e "${RED}OF_NO_SAMSUNG_SPECIAL has been deprecated. Use FOX_NO_SAMSUNG_SPECIAL ${NC}"
fi

if [ -n "$OF_SAMSUNG_DEVICE" -a -z "$FOX_SAMSUNG_DEVICE" ]; then 
   export FOX_SAMSUNG_DEVICE=$OF_SAMSUNG_DEVICE
   echo -e "${RED}OF_SAMSUNG_DEVICE has been deprecated. Use FOX_SAMSUNG_DEVICE ${NC}"
fi

if [ -n "$OF_DISABLE_UPDATEZIP" -a -z "$FOX_DISABLE_UPDATEZIP" ]; then 
   export FOX_DISABLE_UPDATEZIP=$OF_DISABLE_UPDATEZIP
   echo -e "${RED}OF_DISABLE_UPDATEZIP has been deprecated. Use FOX_DISABLE_UPDATEZIP ${NC}"
fi

# default prop
if [ -n "$TARGET_RECOVERY_ROOT_OUT" -a -e "$TARGET_RECOVERY_ROOT_OUT/default.prop" ]; then
   DEFAULT_PROP="$TARGET_RECOVERY_ROOT_OUT/default.prop"
else
   [ -e "$FOX_RAMDISK/prop.default" ] && DEFAULT_PROP="$FOX_RAMDISK/prop.default" || DEFAULT_PROP="$FOX_RAMDISK/default.prop"
fi

# some things are changing in native Android 10.0 and higher devices
RAMDISK_SBIN=/sbin
RAMDISK_ETC=/etc
RAMDISK_SYSTEM_BIN=/system/bin
RAMDISK_SYSTEM_ETC=/system/etc
PROP_DEFAULT="$DEFAULT_PROP"

# identify the build SDK version (not used yet)
if [ -e "$FOX_RAMDISK/prop.default" ]; then
   BUILD_SDK=$(file_getprop "$FOX_RAMDISK/prop.default" "ro.build.version.sdk")
   PROP_DEFAULT="$FOX_RAMDISK/prop.default"
elif [ -e "$FOX_RAMDISK/default.prop" ]; then
   BUILD_SDK=$(file_getprop "$FOX_RAMDISK/default.prop" "ro.build.version.sdk")
   PROP_DEFAULT="$FOX_RAMDISK/default.prop"
else
   BUILD_SDK=$(file_getprop "$DEFAULT_PROP" "ro.build.version.sdk")
fi
[ -z "$BUILD_SDK" ] && BUILD_SDK=30

# there are too many prop files around!
if [ "$DEFAULT_PROP" != "$PROP_DEFAULT" ]; then
   if [ $(filesize $PROP_DEFAULT) -gt $(filesize $DEFAULT_PROP) ]; then
      DEFAULT_PROP=$PROP_DEFAULT
   fi
fi

# build_type
if [ -z "$FOX_BUILD_TYPE" ]; then
   export FOX_BUILD_TYPE=Unofficial
fi

# fox_version && fox_build
if [ -z "$FOX_VERSION" ]; then
   FOX_BUILD=Unofficial
else
   FOX_BUILD=$FOX_VERSION
fi

# variant
if [ -z "$FOX_VARIANT" ]; then
   export FOX_VARIANT="default"
fi

# sort out the out_name
if [ "$FOX_BUILD_TYPE" = "Unofficial" ] && [ "$FOX_BUILD" = "Unofficial" ]; then
   FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$FOX_DEVICE
else
   if [ "$FOX_VARIANT" = "default" ]; then
      FOX_OUT_NAME=OrangeFox-"$FOX_BUILD"-"$FOX_BUILD_TYPE"-"$FOX_DEVICE"
   else
      FOX_OUT_NAME=OrangeFox-"$FOX_BUILD"_"$FOX_VARIANT"-"$FOX_BUILD_TYPE"-"$FOX_DEVICE"
   fi
fi

RECOVERY_IMAGE="$OUT/$FOX_OUT_NAME.img"
TMP_VENDOR_PATH="$OUT/../../../../vendor/$RECOVERY_DIR"
DEFAULT_INSTALL_PARTITION="/dev/block/bootdevice/by-name/recovery" # !! DON'T change!!!

# target_arch - default to arm64
if [ -z "$TARGET_ARCH" ]; then
   echo "Arch not detected, using arm64"
   TARGET_ARCH="arm64"
fi

# tmp for "FOX_CUSTOM_BINS_TO_SDCARD"
FOX_BIN_tmp=$OUT/tmp_bin/FoxFiles

# alternative devices
if [ -z "$TARGET_DEVICE_ALT" ]; then
   if [ -n "$FOX_TARGET_DEVICES" ]; then
   	export TARGET_DEVICE_ALT="$FOX_TARGET_DEVICES"
   elif [ -n "$OF_TARGET_DEVICES" ]; then
   	export TARGET_DEVICE_ALT="$OF_TARGET_DEVICES"
   fi
fi

# copy recovery.img/boot.img
[ -f $OUT/$COMPILED_IMAGE_FILE ] && $CP $OUT/$COMPILED_IMAGE_FILE $RECOVERY_IMAGE

# extreme reduction
if [ "$FOX_EXTREME_SIZE_REDUCTION" = "1" ]; then
   export FOX_DRASTIC_SIZE_REDUCTION=1
fi

# remove all extras if FOX_DRASTIC_SIZE_REDUCTION is defined
if [ "$FOX_DRASTIC_SIZE_REDUCTION" = "1" -a "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" != "1" ]; then
   export FOX_USE_BASH_SHELL=0
   export FOX_ASH_IS_BASH=0
   export FOX_USE_TAR_BINARY=0
   export FOX_USE_SED_BINARY=0
   export FOX_USE_GREP_BINARY=0
   export FOX_USE_NANO_EDITOR=0
   export BUILD_2GB_VERSION=0
   export FOX_USE_XZ_UTILS=0
   export FOX_USE_ZSTD_BINARY=0
   export FOX_USE_LZ4_BINARY=0
   export FOX_REMOVE_BASH=1
   export FOX_REMOVE_AAPT=1
   export FOX_REMOVE_ZIP_BINARY=1
   export FOX_EXCLUDE_NANO_EDITOR=1
   export FOX_REMOVE_BUSYBOX_BINARY=1
fi

# exports
export FOX_DEVICE TMP_VENDOR_PATH FOX_OUT_NAME FOX_RAMDISK FOX_WORK

# create working tmp
if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
   rm -rf $WORKING_TMP
   mkdir -p $WORKING_TMP
fi

# check whether the /etc/ directory is a symlink to /system/etc/
if [ -h "$FOX_RAMDISK/$RAMDISK_ETC" -a -d "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC" ]; then
   RAMDISK_ETC=$RAMDISK_SYSTEM_ETC
fi

# workaround for some Samsung bugs
if [ "$FOX_DYNAMIC_SAMSUNG_FIX" = "1" ]; then
   if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
      echo -e "${WHITEONGREEN} - Dealing with bugged Samsung exynos dynamic stuff - removing stuff... ${NC}"
      echo -e "${WHITEONGREEN} - Make sure that you are doing a clean build. ${NC}"
   fi
   export FOX_REMOVE_BASH=1
   export FOX_REMOVE_AAPT=1
   unset FOX_USE_BASH_SHELL
   unset FOX_ASH_IS_BASH
   unset FOX_USE_NANO_EDITOR
   unset FOX_USE_XZ_UTILS
   unset FOX_USE_TAR_BINARY
   unset FOX_USE_GREP_BINARY
   unset FOX_USE_ZSTD_BINARY
   unset FOX_USE_LZ4_BINARY
fi

# disable all nano editor stuff
if [ "$FOX_EXCLUDE_NANO_EDITOR" = "1" ]; then
   unset FOX_USE_NANO_EDITOR
fi

# ****************************************************
# --- embedded functions
# ****************************************************

# to save the build date, and (if desired) patch bugged alleged anti-rollback on some ROMs
Save_Build_Date() {
local DT="$1"
local F="$DEFAULT_PROP"

   grep -q "ro.build.date.utc=" $F && \
   	sed -i -e "s/ro.build.date.utc=.*/ro.build.date.utc=$DT/g" $F || \
   	echo "ro.build.date.utc=$DT" >> $F

   [ -n "$2" ] && DT="$2" # don't change the true bootimage build date
   grep -q "ro.bootimage.build.date.utc=" $F && \
   	sed -i -e "s/ro.bootimage.build.date.utc=.*/ro.bootimage.build.date.utc=$DT/g" $F || \
   	echo "ro.bootimage.build.date.utc=$DT" >> $F

}

# if there is an ALT device, cater for it in update-binary
Add_Target_Alt() {
local D="$FOX_TMP_WORKING_DIR"
local F="$D/META-INF/com/google/android/update-binary"
   if [ -n "$TARGET_DEVICE_ALT" ]; then
      sed -i -e "s/TARGET_DEVICE_ALT=.*/TARGET_DEVICE_ALT=\"$TARGET_DEVICE_ALT\"/" $F
   fi
}

# whether this is a system-as-root build
SAR_BUILD() {
  local C=$(file_getprop "$DEFAULT_PROP" "ro.build.system_root_image")
  [ "$C" = "true" ] && { echo "1"; return; }

  C=$(file_getprop "$DEFAULT_PROP" "ro.boot.dynamic_partitions")
  [ "$C" = "true" ] && { echo "1"; return; }

  C=$(cat "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/twrp.fstab" 2>/dev/null | grep -s ^"/system_root")
  [ -n "$C" ] && { echo "1"; return; }

  C=$(cat "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/recovery.fstab" 2>/dev/null | grep -s ^"/system_root")
  [ -n "$C" ] && { echo "1"; return; }

  [ -d "$FOX_RAMDISK/system_root/" ] && echo "1" || echo "0"
}

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
     [ -x $T/$THIS_SCRIPT ] && FOX_VENDOR_PATH=$T
  }
}

# save build vars
save_build_vars() {
local F=$1
   export | grep "FOX_" > $F
   export | grep "OF_" >> $F
   sed -i '/FOX_BUILD_LOG_FILE/d' $F
   sed -i '/FOX_BUILD_DEVICE/d' $F
   sed -i '/FOX_LOCAL_CALLBACK_SCRIPT/d' $F
   sed -i '/FOX_USE_SPECIFIC_MAGISK_ZIP/d' $F
   sed -i '/FOX_MANIFEST_ROOT/d' $F
   sed -i '/FOX_PORTS_TMP/d' $F
   sed -i '/FOX_RAMDISK/d' $F
   sed -i '/FOX_WORK/d' $F
   sed -i '/FOX_VENDOR_DIR/d' $F
   sed -i '/FOX_VENDOR_CMD/d' $F
   sed -i '/FOX_VENDOR/d' $F
   sed -i '/OF_MAINTAINER/d' $F
   sed -i '/OLDPWD/d' $F
   sed -i "s/declare -x //g" $F
}


# create zip file
do_create_update_zip() {
local tmp=""
local F=""
local isVB_V3=0
local TDT=$(date "+%d %B %Y")
  echo -e "${BLUE}-- Creating the OrangeFox zip installer ...${NC}"
  FILES_DIR=$FOX_VENDOR_PATH/FoxFiles
  INST_DIR=$FOX_VENDOR_PATH/installer

  # names of output zip file(s)
  ZIP_FILE=$OUT/$FOX_OUT_NAME.zip
  ZIP_FILE_GO=$OUT/$FOX_OUT_NAME"_lite.zip"
  echo "- Creating $ZIP_FILE for deployment ..."

  # clean any existing files
  rm -rf $FOX_TMP_WORKING_DIR
  rm -f $ZIP_FILE_GO $ZIP_FILE

  # recreate dir
  mkdir -p $FOX_TMP_WORKING_DIR
  cd $FOX_TMP_WORKING_DIR

  # create some others
  mkdir -p $FOX_TMP_WORKING_DIR/sdcard/Fox
  mkdir -p $FOX_TMP_WORKING_DIR/META-INF/debug

  # copy busybox
#  $CP -p $FOX_VENDOR_PATH/Files/busybox .

  # copy documentation
  $CP -p $FOX_VENDOR_PATH/Files/INSTALL.txt .

  # copy recovery image/boot image to recovery.img in the zip
  $CP -p $RECOVERY_IMAGE ./recovery.img

  # vendor_boot as recovery - add the ramdisk image to the zip
  if [ "$IS_VENDOR_BOOT_RECOVERY" = "1" -a -x $FOX_VENDOR_PATH/tools/magiskboot ]; then
     local VBtmp=/tmp/VBOOT_stuff
     mkdir -p $VBtmp/
     $CP -p $RECOVERY_IMAGE $VBtmp/tmp.img
     $CP -p $FOX_VENDOR_PATH/Files/flash-* .
     cd $VBtmp/

     [ "$BOARD_BOOT_HEADER_VERSION" = "3" ] && isVB_V3=1

     $FOX_VENDOR_PATH/tools/magiskboot unpack -n tmp.img
     F="vendor_ramdisk_recovery.cpio"; #v4+ header
     [ ! -f $F ] && F="ramdisk.cpio"; #v3 or earlier header
     if [ -f $F ]; then
     	$CP -p $F $FOX_TMP_WORKING_DIR/$F
	# check for v3 header and compensate
     	if [ "$F" = "ramdisk.cpio" ]; then
	   isVB_V3=1
  	   sed -i -e "s/vendor_ramdisk_recovery.cpio/$F/" $FOX_TMP_WORKING_DIR/flash-*
     	fi
     fi

     cd $FOX_TMP_WORKING_DIR
     rm -rf $VBtmp/
  fi # vendor_boot

  # copy the Samsung .tar file if it exists
  if [ -f $RECOVERY_IMAGE".tar" ]; then
     $CP -p $RECOVERY_IMAGE".tar" .
  fi

  # copy installer bins and script
  $CP -pr $INST_DIR/* .

  # copy FoxFiles/ to sdcard/Fox/
  $CP -a $FILES_DIR/ sdcard/Fox/

  # copy any custom bin files to /sdcard/Fox/bin/ ?
  if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" = "1" -a -d "$FOX_BIN_tmp/bin" ]; then
     chmod +x $FOX_BIN_tmp/bin/*
     $CP -a $FOX_BIN_tmp/ sdcard/Fox/
     rm -rf $FOX_BIN_tmp
  fi

  # any local changes to a port's installer directory?
  if [ -n "$FOX_PORTS_INSTALLER" ] && [ -d "$FOX_PORTS_INSTALLER" ]; then
     $CP -pr $FOX_PORTS_INSTALLER/* .
  fi

  # patch update-binary (which is a script) to run only for the current device
  F="$FOX_TMP_WORKING_DIR/META-INF/com/google/android/update-binary"
  sed -i -e "s|^TARGET_DEVICE=.*|TARGET_DEVICE=\"$FOX_DEVICE\"|" $F

  # embed the release version
  sed -i -e "s/RELEASE_VER/$FOX_BUILD/" $F

  # embed the build date
  sed -i -e "s/TODAY/$TDT/" $F

  # embed the recovery partition
  if [ -n "$FOX_RECOVERY_INSTALL_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery install partition to \"$FOX_RECOVERY_INSTALL_PARTITION\" ${NC}"
     sed -i -e "s|^RECOVERY_PARTITION=.*|RECOVERY_PARTITION=\"$FOX_RECOVERY_INSTALL_PARTITION\"|" $F
  fi

  # embed the system partition
  if [ -n "$FOX_RECOVERY_SYSTEM_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery system partition to \"$FOX_RECOVERY_SYSTEM_PARTITION\" ${NC}"
     sed -i -e "s|^SYSTEM_PARTITION=.*|SYSTEM_PARTITION=\"$FOX_RECOVERY_SYSTEM_PARTITION\"|" $F
  fi

  # embed the VENDOR partition
  if [ -n "$FOX_RECOVERY_VENDOR_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery vendor partition to \"$FOX_RECOVERY_VENDOR_PARTITION\" ${NC}"
     sed -i -e "s|^VENDOR_PARTITION=.*|VENDOR_PARTITION=\"$FOX_RECOVERY_VENDOR_PARTITION\"|" $F
  fi

  # embed the BOOT partition
  if [ -n "$FOX_RECOVERY_BOOT_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery boot partition to \"$FOX_RECOVERY_BOOT_PARTITION\" ${NC}"
     sed -i -e "s|^BOOT_PARTITION=.*|BOOT_PARTITION=\"$FOX_RECOVERY_BOOT_PARTITION\"|" $F
  fi

  # embed the VENDOR_BOOT partition
  if [ -n "$FOX_RECOVERY_VENDOR_BOOT_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery vendor_boot partition to \"$FOX_RECOVERY_VENDOR_BOOT_PARTITION\" ${NC}"
     sed -i -e "s|^VENDOR_BOOT_PARTITION=.*|VENDOR_BOOT_PARTITION=\"$FOX_RECOVERY_VENDOR_BOOT_PARTITION\"|" $F
  fi

  # debug mode for the installer? (just for testing purposes - don't ship the recovery with this enabled)
  if [ "$FOX_INSTALLER_DEBUG_MODE" = "1" -o "$FOX_INSTALLER_DEBUG_MODE" = "true" ]; then
     echo -e "${WHITEONRED}-- Enabling debug mode in the zip installer! You must disable \"FOX_INSTALLER_DEBUG_MODE\" before release! ${NC}"
     sed -i -e "s|^FOX_INSTALLER_DEBUG_MODE=.*|FOX_INSTALLER_DEBUG_MODE=\"1\"|" $F
  fi

  # A/B devices
  if [ "$IS_AB_DEVICE" = "1" ]; then
     echo -e "${RED}-- A/B device - copying magiskboot to zip installer ... ${NC}"
     tmp=$FOX_RAMDISK/$RAMDISK_SBIN/magiskboot
     [ ! -e "$tmp" ] && tmp=$FOX_VENDOR_PATH/prebuilt/$TARGET_ARCH/magiskboot"$UPDATED"
     [ ! -e "$tmp" ] && tmp=/tmp/fox_build_tmp/magiskboot
     [ ! -e "$tmp" ] && {
       echo -e "${WHITEONRED}-- I cannot find magiskboot. Quitting! ${NC}"
       abort 200
     }
     $CP -pf $tmp ./magiskboot
     sed -i -e "s/^FOX_AB_DEVICE=.*/FOX_AB_DEVICE=\"1\"/" $F
  fi
  rm -rf /tmp/fox_build_tmp/

  # vendor_boot
  if [ "$IS_VENDOR_BOOT_RECOVERY" = "1" ]; then
     echo -e "${RED}-- Vendor_boot device - enabling vendor_boot mode for the installer ... ${NC}"
     sed -i -e "s/^FOX_VENDOR_BOOT_RECOVERY=.*/FOX_VENDOR_BOOT_RECOVERY=\"1\"/" $F
     sed -i -e "s/^FOX_VENDOR_BOOT_RECOVERY_V3_HDR=.*/FOX_VENDOR_BOOT_RECOVERY_V3_HDR=\"$isVB_V3\"/" $F

     if [ "$FOX_VENDOR_BOOT_FLASH_RAMDISK_ONLY" = "1" ] ; then
     	echo -e "${RED}-- Vendor_boot: - enabling vendor_boot ramdisk flash mode for the installer ... ${NC}"
     	sed -i -e "s/^FOX_VENDOR_BOOT_FLASH_RAMDISK_ONLY=.*/FOX_VENDOR_BOOT_FLASH_RAMDISK_ONLY=\"1\"/" $F
     fi
  fi

  # virtual A/B
  if [ "$IS_VIRTUAL_AB_DEVICE" = "1" ]; then
     echo -e "${RED}-- Saving the vAB flag ... ${NC}"
     sed -i -e "s/^FOX_VIRTUAL_AB_DEVICE=.*/FOX_VIRTUAL_AB_DEVICE=\"1\"/" $F
  fi

  # whether to enable magisk 24+ patching of vbmeta
  if [ "$FOX_PATCH_VBMETA_FLAG" = "1" -o "$OF_PATCH_VBMETA_FLAG" = "1" ]; then
     echo -e "${RED}-- Enabling PATCHVBMETAFLAG for the installation... ${NC}"
     sed -i -e "s/^FOX_PATCH_VBMETA_FLAG=.*/FOX_PATCH_VBMETA_FLAG=\"1\"/" $F
  fi

  # Reset Settings
  if [ "$FOX_RESET_SETTINGS" = "disabled" ]; then
     echo -e "${WHITEONRED}-- Instructing the zip installer to NOT reset OrangeFox settings (NOT recommended!) ... ${NC}"
     sed -i -e "s/^FOX_RESET_SETTINGS=.*/FOX_RESET_SETTINGS=\"disabled\"/" $F
  fi

  # skip all patches ?
  if [ "$IS_VANILLA_BUILD" = "1" ]; then
     echo -e "${RED}-- This build will skip all OrangeFox patches ... ${NC}"
     sed -i -e "s/^FOX_VANILLA_BUILD=.*/FOX_VANILLA_BUILD=\"1\"/" $F
  fi

  # use /data/recovery/Fox/ instead of /sdcard/Fox/ ?
  if [ -n "$FOX_SETTINGS_ROOT_DIRECTORY" ]; then
     echo -e "${RED}-- This build will use $FOX_SETTINGS_ROOT_DIRECTORY for its internal settings ... ${NC}"
     sed -i -e "s|^FOX_SETTINGS_ROOT_DIRECTORY=.*|FOX_SETTINGS_ROOT_DIRECTORY=\"$FOX_SETTINGS_ROOT_DIRECTORY\"|" $F
  elif [ "$FOX_USE_DATA_RECOVERY_FOR_SETTINGS" = "1" ]; then
     echo -e "${RED}-- This build will use /data/recovery/ for its internal settings ... ${NC}"
     sed -i -e "s/^FOX_USE_DATA_RECOVERY_FOR_SETTINGS=.*/FOX_USE_DATA_RECOVERY_FOR_SETTINGS=\"1\"/" $F
  fi

  # disable auto-reboot after installing OrangeFox?
  if [ "$FOX_INSTALLER_DISABLE_AUTOREBOOT" = "1" ]; then
     echo -e "${RED}-- This build will skip all OrangeFox patches ... ${NC}"
     sed -i -e "s/^FOX_INSTALLER_DISABLE_AUTOREBOOT=.*/FOX_INSTALLER_DISABLE_AUTOREBOOT=\"1\"/" $F
  fi

  # omit AromaFM ?
  if [ "$FOX_DELETE_AROMAFM" = "1" ]; then
     echo -e "${GREEN}-- Deleting AromaFM ...${NC}"
     rm -rf $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/AromaFM
  fi

  # delete the magisk addon zips ?
  if [ "$FOX_DELETE_MAGISK_ADDON" = "1" ]; then
     echo -e "${GREEN}-- Deleting the magisk addon zips ...${NC}"
     rm -f $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/Magisk.zip
     rm -f $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/unrootmagisk.zip
     rm -f $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/Magisk_uninstall.zip
  fi

  # are we using a specific magisk zip?
  if [ -n "$FOX_USE_SPECIFIC_MAGISK_ZIP" ]; then
     if [ -e $FOX_USE_SPECIFIC_MAGISK_ZIP ]; then
        echo -e "${WHITEONGREEN}-- Using magisk zip: \"$FOX_USE_SPECIFIC_MAGISK_ZIP\" ${NC}"
        $CP -pf $FOX_USE_SPECIFIC_MAGISK_ZIP $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/Magisk.zip
        $CP -pf $FOX_USE_SPECIFIC_MAGISK_ZIP $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/Magisk_uninstall.zip
     else
        echo -e "${WHITEONRED}-- I cannot find \"$FOX_USE_SPECIFIC_MAGISK_ZIP\"! Using the default.${NC}"
     fi
  fi

  # OF_initd
  if [ "$FOX_DELETE_INITD_ADDON" = "1" ]; then
     echo -e "${GREEN}-- Deleting the initd addon ...${NC}"
     rm -f $FOX_TMP_WORKING_DIR/sdcard/Fox/FoxFiles/OF_initd*.zip
  else
     echo -e "${GREEN}-- Copying the initd addon ...${NC}"
  fi
  
  # alternative/additional device codename?
  if [ -n "$TARGET_DEVICE_ALT" ]; then
     echo -e "${GREEN}-- Adding the alternative device codename(s): \"$TARGET_DEVICE_ALT\" ${NC}"
     Add_Target_Alt;
  fi

  # if a local callback script is declared, run it, passing to it the temporary working directory (Last call)
  # "--last-call" = just before creating the OrangeFox update zip file
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" -a -f "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
	bash $FOX_LOCAL_CALLBACK_SCRIPT "$FOX_TMP_WORKING_DIR" "--last-call"
  fi

  # save the build vars
  save_build_vars "$FOX_TMP_WORKING_DIR/META-INF/debug/fox_build_vars.txt"
  tmp="$FOX_RAMDISK/prop.default"
  [ ! -e "$tmp" ] && tmp="$DEFAULT_PROP"
  [ ! -e "$tmp" ] && tmp="$FOX_RAMDISK/default.prop"
  [ -e "$tmp" ] && $CP "$tmp" "$FOX_TMP_WORKING_DIR/META-INF/debug/default.prop"

  # create update zip
  ZIP_CMD="zip --exclude=*.git* -r9 $ZIP_FILE ."
  echo "- Running ZIP command: $ZIP_CMD"
  $ZIP_CMD -z < $FOX_VENDOR_PATH/Files/INSTALL.txt

  #  sign zip installer
  local JAVA8
  if [ -e "$FOX_VENDOR_PATH/signature/zipsigner-3.0.jar" ]; then
     JAVA8=$(which "java")
  else
     JAVA8="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
  fi
  [ -n "$FOX_JAVA8_PATH" ] && JAVA8="$FOX_JAVA8_PATH"
  if [ ! -x "$JAVA8" ]; then
     JAVA8="/usr/lib/jvm/java-8-openjdk/jre/bin/java"
     [ ! -x "$JAVA8" ] && JAVA8=""
  fi

  export JAVA8
  
  if [ -z "$JAVA8" ]; then
     echo -e "${WHITEONRED}-- java-8 cannot be found! The zip file will NOT be signed! ${NC}"
     echo -e "${WHITEONRED}-- This build CANNOT be released officially! ${NC}"
  elif [ -f $ZIP_FILE  ]; then
     ZIP_CMD="$FOX_VENDOR_PATH/signature/sign_zip.sh -z $ZIP_FILE"
     echo "- Running ZIP command: $ZIP_CMD"
     $ZIP_CMD
     # this breaks the signature
     #echo "- Adding comments (again):"
     #zip $ZIP_FILE -z <$FOX_VENDOR_PATH/Files/INSTALL.txt > /dev/null 2>&1
  fi

  # Creating ZIP md5
  echo -e "${BLUE}-- Creating md5 for $ZIP_FILE${NC}"
  cd "$OUT" && md5sum "$ZIP_FILE" > "$ZIP_FILE.md5" && cd - > /dev/null 2>&1

  # list files
  echo "- Finished:"
  echo "---------------------------------"
  echo " $(/bin/ls -laFt $ZIP_FILE)"
  echo "---------------------------------"

  # export the filenames
  echo "ZIP_FILE=$ZIP_FILE">/tmp/oFox00.tmp
  echo "RECOVERY_IMAGE=$RECOVERY_IMAGE">>/tmp/oFox00.tmp
  [ -f $RECOVERY_IMAGE".tar" ] && echo "RECOVERY_ODIN=$RECOVERY_IMAGE.tar" >>/tmp/oFox00.tmp

  # delete OF Working dir
  rm -rf $FOX_TMP_WORKING_DIR 
} # function

# are we using toolbox/toybox?
uses_toolbox() {
 [ "$TW_USE_TOOLBOX" = "true" ] && { echo "1"; return; }
 local T=$(filesize $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/toybox)
 [ "$T" = "0" ] && { echo "0"; return; }
 local B=$(filesize $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/busybox)
 [ $T -gt $B ] && { echo "1"; return; }
 T=$(readlink "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/yes")
 [ "$T" = "toybox" ] && echo "1" || echo "0"
}

# drastic size reduction
# This can reduce the recovery image size by up to 3 MB
reduce_ramdisk_size() {
local custom_xml=$FOX_RAMDISK/twres/pages/customization.xml
local image_xml=$FOX_RAMDISK/twres/resources/images.xml
local CURRDIR=$PWD
local TWRES_DIR=$FOX_RAMDISK/twres
local FFil="$FOX_RAMDISK/FFiles"
local C=""
local F=""

      echo -e "${GREEN}-- Pruning the ramdisk to reduce the size ... ${NC}"

      # remove some large files
      if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" != "1" ]; then
      	 rm -rf $FFil/nano
      	 rm -f $FOX_RAMDISK/sbin/aapt
      	 rm -f $FOX_RAMDISK/sbin/zip
      	 rm -f $FOX_RAMDISK/sbin/nano
      	 rm -f $FOX_RAMDISK/sbin/gnutar
	 rm -f $FOX_RAMDISK/sbin/zstd
	 rm -f $FOX_RAMDISK/sbin/lz4
      	 rm -f $FOX_RAMDISK/sbin/gnused
      	 rm -f $FOX_RAMDISK/sbin/bash
      	 rm -f $FOX_RAMDISK/sbin/busybox
      	 rm -f $FOX_RAMDISK/etc/bash.bashrc
      	 rm -rf $FOX_RAMDISK/$RAMDISK_ETC/terminfo
      	 rm -rf $FFil/Tools
      	 if [ "$IS_VANILLA_BUILD" = "1" ]; then
           rm -rf $FFil/OF_avb20
           rm -rf $FFil/OF_verity_crypt
      	 fi
      fi

      if [ "$FOX_EXTREME_SIZE_REDUCTION" != "1" ]; then
         return
      fi
      
      # fonts to be deleted      
      declare -a FontFiles=(
        "Amatic" 
	"Chococooky" 
	"Exo2-Medium"
	"Exo2-Regular"
	"EuclidFlex-Medium"
	"EuclidFlex-Regular"
	"GoogleSans-Medium"
	"GoogleSans-Regular"
        "FiraCode-Medium" 
	"MILanPro-Medium"
        "MILanPro-Regular")

	# first of all, substitute the fonts that will be deleted
	XML=$TWRES_DIR/themes/font.xml
	sed -i -e "s/GoogleSans/Roboto/g" $XML

	XML=$TWRES_DIR/resources/images.xml
	sed -i -e "s/EuclidFlex/Roboto/g" $XML
	sed -i -e "s/GoogleSans/Roboto/g" $XML

	XML=$TWRES_DIR/splash.xml
	sed -i -e "s/EuclidFlex/Roboto/g" $XML
	sed -i -e "s/GoogleSans/Roboto/g" $XML

	XML=$TWRES_DIR/themes/sed/splash.xml
	sed -i -e "s/EuclidFlex/Roboto/g" $XML

	XML=$TWRES_DIR/themes/sed/splash_orig.xml
	sed -i -e "s/EuclidFlex/Roboto/g" $XML

	if [ "$FOX_EXTREME_SIZE_REDUCTION" = "1" ]; then
     	   sed -i -e "s/FiraCode/Roboto/g" $TWRES_DIR/resources/images.xml
     	   sed -i -e "s/FiraCode/Roboto/g" $TWRES_DIR/splash.xml
     	fi

      	# delete the font files
      	for i in "${FontFiles[@]}"
      	do
     	   C=$i".ttf"
     	   F=$TWRES_DIR/fonts/$C
     	   rm -f $F
     	   # remove references to them in resources/images.xml 
     	   sed -i "/$C/d" $image_xml
      	done

      	# delete the matching line plus the next 2 lines
      	for i in {3..9}; do
    	   F="font"$i
     	   # remove references to them in customization.xml		   
     	   sed -i "/$F/I,+2 d" $custom_xml
      	done

	# return to where we started from
	cd $CURRDIR
}

# is this an executable arm binary?
is_arm() {
	local i=$(file $1 | grep "ARM" | grep "ELF");
	[ -n "$i" ] && echo "1" || echo "0";
}

# compress some binaries with upx
compress_some_executables() {
local upx_bin=$FOX_VENDOR_PATH/tools/upx;
    if [ -x "$upx_bin" ]; then
	local min=131072; # only process binaries bigger than 128kb
	local HERE=$PWD;
	local size;
	local bins;
	local dir;
	for bin_dirs in $FOX_COMPRESS_EXECUTABLES
	do
		dir=$FOX_RAMDISK/$bin_dirs;
		if [ -d $dir ]; then
			cd $dir;
			bins=$(ls ./);
			for i in $bins
			do
				size=$(filesize $i);
				if [ $size -gt $min -a "$(is_arm $i)" = "1" ]; then
					echo -e "${WHITEONRED}-- Compressing \"$i\" with upx ... ${NC}";
					chmod 0755 $i; # if the executable bit is not set, upx will reject it
					$upx_bin --lzma $i;
				fi
			done
		fi
	done # for bin_dirs
	cd $HERE;
    fi
}

# have some big binaries in /sdcard/Fox/FoxFiles/bin/ ?
process_custom_bins_to_sdcard() {
local tmp1
local tmp2
local ramdisk_sbindir=$FOX_RAMDISK/sbin
local ramdisk_sbindir_10=$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN
local sdcard_bin=/sdcard/Fox/FoxFiles/bin
local mksync="3"

  if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" != "1" ]; then
     return
  fi

  echo -e "${WHITEONRED}-- 'FOX_CUSTOM_BINS_TO_SDCARD' used; Ensure that you are doing a CLEAN BUILD, else, it *WILL* all go pear-shaped!!${NC}"

  [ -d $FOX_BIN_tmp/bin/ ] && rm -rf $FOX_BIN_tmp/bin/
  mkdir -p $FOX_BIN_tmp/bin/

  if [ -f $ramdisk_sbindir/bash -a ! -h $ramdisk_sbindir/bash ]; then
     	mv -f $ramdisk_sbindir/bash $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/bash $ramdisk_sbindir/bash
  elif [ "$FOX_BUILD_BASH" = "1" -a -f $ramdisk_sbindir_10/bash -a ! -h $ramdisk_sbindir_10/bash ]; then
     	mv -f $ramdisk_sbindir_10/bash $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/bash $ramdisk_sbindir_10/bash
  fi

  [ -f $ramdisk_sbindir/zip -a ! -h $ramdisk_sbindir/zip ] && {
     	mv -f $ramdisk_sbindir/zip $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/zip $ramdisk_sbindir/zip
  }

  [ -f $ramdisk_sbindir/gnutar ] && {
     	mv -f $ramdisk_sbindir/gnutar $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/gnutar $ramdisk_sbindir/gnutar
  }

  [ -f $ramdisk_sbindir/gnused ] && {
     	mv -f $ramdisk_sbindir/gnused $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/gnused $ramdisk_sbindir/gnused
  }

  [ -f $ramdisk_sbindir/aapt ] && {
     	mv -f $ramdisk_sbindir/aapt $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/aapt $ramdisk_sbindir/aapt
  }

  [ "$FOX_USE_XZ_UTILS" = "1" -a -f $FOX_VENDOR_PATH/Files/xz ] && {
     $CP -pf $FOX_VENDOR_PATH/Files/xz $FOX_BIN_tmp/bin/lzma
     [ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && {
     	 rm -f $ramdisk_sbindir_10/lzma $ramdisk_sbindir_10/xz $ramdisk_sbindir/lzma $ramdisk_sbindir/xz
     	 ln -sf $sdcard_bin/lzma $ramdisk_sbindir/lzma
     	 ln -sf lzma $ramdisk_sbindir/xz
     }
  }

  if [ "$FOX_USE_NANO_EDITOR" = "1" ]; then
     [ "$ramdisk_sbindir/nano" ] && {
     	tmp1=$ramdisk_sbindir/nano
     	$CP -af $FOX_VENDOR_PATH/Files/nano/ $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" != "1" ] && sed -i -e "s|^NANO_DIR=.*|NANO_DIR=$sdcard_bin/nano|" $tmp1
     }
  elif [ "$FOX_EXCLUDE_NANO_EDITOR" != "1" -a -f $ramdisk_sbindir_10/nano -a ! -h $ramdisk_sbindir_10/nano ]; then
     	mv -f $ramdisk_sbindir_10/nano $FOX_BIN_tmp/bin/
     	[ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ] && ln -sf $sdcard_bin/nano $ramdisk_sbindir_10/nano
  fi

 # 1=copy at runtime; 2=symlinks at runtime; 3=symlinks at build time ($mksync)
 if [ "$FOX_CUSTOM_BINS_TO_SDCARD" = "$mksync" ]; then
    return
 fi
 
 # create the helper scripts
 echo -e "${GREEN}-- FOX_CUSTOM_BINS_TO_SDCARD: creating script to process $sdcard_bin/* for the recovery ramdisk ... ${NC}"

 if [ "$FOX_CUSTOM_BINS_TO_SDCARD" = "1" ]; then
    tmp2="cp"
 else
    tmp2="sym"
 fi

# create the script
tmp1=$FOX_BIN_tmp/bin/sdcard_to_bin.sh
rm -f $tmp1
cat << EOF >> "$tmp1"
#!/sbin/sh -x
   	cmd="$tmp2"
   	chmod +x $sdcard_bin/*
   	if [ "\$cmd" = "cp" ]; then
           [ -d $sdcard_bin/nano/ ] && mv /sbin/nano /sbin/nano_script
           cp -af $sdcard_bin/* /sbin/
           [ -d $sdcard_bin/nano/ ] && { cp -af $sdcard_bin/nano/ /FFiles/nano/; rm -rf /sbin/nano/; mv -f /sbin/nano_script /sbin/nano; }
           [ -f $sdcard_bin/nano ] && cp -af $sdcard_bin/nano /system/bin/
   	else
	   files="aapt bash gnused gnutar lzma zip zstd lz4"
	   set -- \$files
	   while [ -n "\$1" ]
  	   do
     	      i="\$1"
     	      [ -f $sdcard_bin/"\$i" ] && { rm -f /sbin/\$i; ln -sf $sdcard_bin/\$i /sbin/\$i; }
     	      shift
  	   done
  	   [ -f $sdcard_bin/nano ] && { rm -f /system/bin/nano; ln -sf $sdcard_bin/nano /system/bin/nano; }
   	fi
   	[ -f $sdcard_bin/lzma ] && { rm -f /sbin/xz; ln -sf lzma /sbin/xz; }
	exit 0;
EOF
chmod 0755 $tmp1
 
# run the script to copy /sdcard/Fox/FoxFiles/bin/* to the ramdisk at runtime
# source this script in postecoveryboot.sh ("source /sbin/from_fox_sd.sh")
tmp1=$ramdisk_sbindir/from_fox_sd.sh
rm -f $tmp1
cat << EOF >> "$tmp1"
fxDIR=$sdcard_bin;
fxF=\$fxDIR/sdcard_to_bin.sh;
if [ -f \$fxF ]; then
   chmod +x \$fxDIR/*;
   echo "I: Running \$fxF !" >> /tmp/recovery.log;
   \$fxF;
fi
rm -f "/sbin/from_fox_sd.sh"
rm -f "/sbin/sdcard_to_bin.sh"
EOF
chmod 0755 $tmp1
} # end function process_custom_bins_to_sdcard()

# ****************************************************
# *** now the real work starts!
# ****************************************************

# get the full FOX_VENDOR_PATH
expand_vendor_path

# did we export tmp directory for OrangeFox ports?
[ -n "$FOX_PORTS_TMP" ] && FOX_TMP_WORKING_DIR="$FOX_PORTS_TMP" || FOX_TMP_WORKING_DIR="/tmp/fox_zip_tmp"

# is the working directory still there from a previous build? If so, remove it
if [ "$FOX_VENDOR_CMD" != "Fox_Before_Recovery_Image" ]; then
   if [ -d "$FOX_WORK" ]; then
      echo -e "${BLUE}-- Working folder found (\"$FOX_WORK\"). Cleaning up...${NC}"
      rm -rf "$FOX_WORK"
   fi

   mkdir -p "$FOX_WORK"

  # perhaps we don't need some "Tools" ?
  if [ "$(SAR_BUILD)" = "1" ]; then
     echo -e "${GREEN}-- This is a system-as-root build ...${NC}"
  else
     echo -e "${GREEN}-- This is NOT a system-as-root build - removing the system_sar_mount directory ...${NC}"
     rm -rf "$FOX_RAMDISK/FFiles/Tools/system_sar_mount/"
  fi
fi

###############################################################
# copy stuff to the ramdisk and do all necessary patches before the build system creates the recovery image
if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
  echo -e "${BLUE}-- Copying mkbootimg, unpackbootimg binaries to sbin${NC}"
  case "$TARGET_ARCH" in
  "arm")
      echo -e "${GREEN}-- ARM arch detected. Copying ARM binaries${NC}"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm/mkbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm/unpackbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm/magiskboot$UPDATED" "$FOX_RAMDISK/$RAMDISK_SBIN/magiskboot"
      ;;
  "arm64")
      echo -e "${GREEN}-- ARM64 arch detected. Copying ARM64 binaries${NC}"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm64/mkbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm64/unpackbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/arm64/magiskboot$UPDATED" "$FOX_RAMDISK/$RAMDISK_SBIN/magiskboot"
      ;;
  "x86")
      echo -e "${GREEN}-- x86 arch detected. Copying x86 binaries${NC}"
      $CP "$FOX_VENDOR_PATH/prebuilt/x86/mkbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/x86/unpackbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      ;;
  "x86_64")
      echo -e "${GREEN}-- x86_64 arch detected. Copying x86_64 binaries${NC}"
      $CP "$FOX_VENDOR_PATH/prebuilt/x86_64/mkbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      $CP "$FOX_VENDOR_PATH/prebuilt/x86_64/unpackbootimg" "$FOX_RAMDISK/$RAMDISK_SBIN/"
      ;;
    *) echo -e "${RED}-- Couldn't detect current device architecture or it is not supported${NC}" ;;
  esac

  # build standard (3GB) version
  # copy over vendor FFiles/ and vendor sbin/ stuff before creating the boot image
  #[ "$FOX_BUILD_DEBUG_MESSAGES" = "1" ] && echo "- FOX_BUILD_DEBUG_MESSAGES: Copying: $FOX_VENDOR_PATH/FoxExtras/* to $FOX_RAMDISK/"
  $CP -pr $FOX_VENDOR_PATH/FoxExtras/* $FOX_RAMDISK/

  # if these directories don't already exist
  mkdir -p $FOX_RAMDISK/$RAMDISK_ETC/
  mkdir -p $FOX_RAMDISK/$RAMDISK_SBIN/

  # copy resetprop (armeabi)
  $CP -p $FOX_VENDOR_PATH/Files/resetprop $FOX_RAMDISK/$RAMDISK_SBIN/

  # deal with magiskboot/mkbootimg/unpackbootimg
  echo -e "${GREEN}-- This build will use magiskboot for patching boot images ...${NC}"
  echo -e "${GREEN}-- Using magiskboot [$FOX_RAMDISK/$RAMDISK_SBIN/magiskboot] - deleting mkbootimg/unpackbootimg ...${NC}"
  rm -f $FOX_RAMDISK/$RAMDISK_SBIN/mkbootimg
  rm -f $FOX_RAMDISK/$RAMDISK_SBIN/unpackbootimg
  echo -e "${GREEN}-- Backing up $FOX_RAMDISK/$RAMDISK_SBIN/magiskboot to: /tmp/fox_build_tmp/ ...${NC}"
  mkdir -p /tmp/fox_build_tmp/
  $CP -pf $FOX_RAMDISK/$RAMDISK_SBIN/magiskboot /tmp/fox_build_tmp/magiskboot

  # symlink for openrecovery binary
  if [ -f "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/twrp" ]; then
     ln -sf /system/bin/twrp "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fox"
  fi

  # symlink for /sbin/magiskboot in /system/bin/
  if [ -f "$FOX_RAMDISK/$RAMDISK_SBIN/magiskboot" ]; then
     rm -f "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/magiskboot"
     ln -sf /sbin/magiskboot "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/magiskboot"
  fi

  # try to fix toolbox egrep/fgrep symlink bug
  if [ "$(uses_toolbox)" = "1" ]; then
     rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep
     ln -sf grep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep
     ln -sf grep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep
  fi

  # Replace the toolbox "getprop" with "resetprop" ?
  if [ "$FOX_REPLACE_TOOLBOX_GETPROP" = "1" -a -f $FOX_RAMDISK/$RAMDISK_SBIN/resetprop ]; then
     echo -e "${GREEN}-- Replacing the toolbox \"getprop\" command with a fuller version ...${NC}"
     rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/getprop
     ln -s $RAMDISK_SBIN/resetprop $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/getprop
  fi

  # replace any built-in lzma (and "xz") with our own
  # use the full "xz" binary for lzma, and for xz - smaller in size, and does the same job
  if [ "$FOX_USE_XZ_UTILS" = "1" ]; then
     if [ "$FOX_DYNAMIC_SAMSUNG_FIX" != "1" ]; then
     	echo -e "${GREEN}-- Replacing any built-in \"lzma\" command with our own full version ...${NC}"
     	rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/lzma
     	rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/xz
     	if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" != "1" ]; then
     	   $CP -p $FOX_VENDOR_PATH/Files/xz $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/lzma
           ln -s lzma $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/xz
     	else
     	   [ "$FOX_CUSTOM_BINS_TO_SDCARD" = "1" ] && ln -s lzma $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/xz
     	fi
     fi
  fi

  # remove the green LED setting?
  if [ "$OF_USE_GREEN_LED" = "0" ]; then
     echo -e "${GREEN}-- Removing the \"green LED\" setting ...${NC}"
  fi

  # remove extra "More..." link in the "About" screen?
  if [ "$OF_DISABLE_EXTRA_ABOUT_PAGE" = "1" ]; then
     echo -e "${GREEN}-- Disabling the \"More...\" link in the \"About\" page ...${NC}"
  fi

  # disable the magisk addon ui entries?
  if [ "$FOX_DELETE_MAGISK_ADDON" = "1" ]; then
     echo -e "${GREEN}-- Disabling the magisk addon entries in advanced.xml ...${NC}"
     Led_xml_File=$FOX_RAMDISK/twres/pages/advanced.xml
     sed -i "/>mod_magisk</I,+0 d" $Led_xml_File
     sed -i "/>mod_unmagisk</I,+0 d" $Led_xml_File
     sed -i "s/>Magisk</>Magisk ({@disabled})</" $Led_xml_File
  fi

  # Include bash shell ?
  if [ "$FOX_REMOVE_BASH" = "1" ]; then

     if [ "$FOX_BUILD_BASH" != "1" ]; then
         export FOX_USE_BASH_SHELL="0"
         rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/bash
     fi

     # remove the /sbin/ bash if it is there from a previous build
     rm -f $FOX_RAMDISK/$RAMDISK_SBIN/bash
     rm -f $FOX_RAMDISK/$RAMDISK_ETC/bash.bashrc
  else
     echo -e "${GREEN}-- Copying bash ...${NC}"
     $CP -p $FOX_VENDOR_PATH/Files/fox.bashrc $FOX_RAMDISK/$RAMDISK_ETC/bash.bashrc
     $CP -p $FOX_VENDOR_PATH/Files/fox.bashrc $FOX_RAMDISK/FFiles/fox.mkshrc
     
     if [ "$FOX_BUILD_BASH" = "1" ]; then
        if [ -z "$(cat $FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/bash/bashrc | grep OrangeFox)" ]; then
           echo " " >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/bash/bashrc"
           echo "# OrangeFox" >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/bash/bashrc"
           echo '[ -f /sdcard/Fox/fox.bashrc ] && source /sdcard/Fox/fox.bashrc' >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/bash/bashrc"
        fi
        echo '[ ! -f /sdcard/Fox/fox.bashrc -a -f /FFiles/fox.mkshrc ] && source /sdcard/Fox/fox.mkshrc' >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_ETC/bash/bashrc"
     else
	rm -f $FOX_RAMDISK/$RAMDISK_SBIN/bash
	rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/bash
	[ "$FOX_BASH_TO_SYSTEM_BIN" = "1" ] && F=$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/bash || F=$FOX_RAMDISK/$RAMDISK_SBIN/bash
	$CP -pf $FOX_VENDOR_PATH/Files/bash $F
	chmod 0775 $F
     fi

     if [ "$FOX_ASH_IS_BASH" = "1" ]; then
        export FOX_USE_BASH_SHELL="1"
     fi
  fi

  # replace busybox "sh" with bash ?
  if [ "$FOX_BUILD_BASH" = "1" ]; then
     BASH_BIN=$RAMDISK_SYSTEM_BIN/bash
  else
     BASH_BIN=$RAMDISK_SBIN/bash
  fi

  if [ "$FOX_USE_BASH_SHELL" = "1" ]; then
        echo -e "${GREEN}-- Replacing the \"sh\" applet with bash ...${NC}"
  	rm -f $FOX_RAMDISK/$RAMDISK_SBIN/sh
  	ln -s $BASH_BIN $FOX_RAMDISK/$RAMDISK_SBIN/sh
  else
        echo -e "${GREEN}-- Cleaning up any bash stragglers...${NC}"
	# cleanup any stragglers
	if [ -h $FOX_RAMDISK/$RAMDISK_SBIN/sh ]; then
	    T=$(readlink $FOX_RAMDISK/$RAMDISK_SBIN/sh)
	    [ "$(basename $T)" = "bash" ] && rm -f $FOX_RAMDISK/$RAMDISK_SBIN/sh
	fi

	# if there is no symlink for /sbin/sh create one
	if [ ! -e $FOX_RAMDISK/$RAMDISK_SBIN/sh -a ! -h $FOX_RAMDISK/$RAMDISK_SBIN/sh ]; then
	   ln -s $RAMDISK_SYSTEM_BIN/sh $FOX_RAMDISK/$RAMDISK_SBIN/sh
	fi
  fi

# do the same for "ash"?
  if [ "$FOX_ASH_IS_BASH" = "1" ]; then
     echo -e "${GREEN}-- Replacing the \"ash\" applet with bash ...${NC}"
     rm -f $FOX_RAMDISK/$RAMDISK_SBIN/ash
     ln -s $BASH_BIN $FOX_RAMDISK/$RAMDISK_SBIN/ash
     rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/ash
     ln -s $BASH_BIN $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/ash
  else
        echo -e "${GREEN}-- Cleaning up any ash stragglers...${NC}"
	# cleanup any stragglers
	if [ -h $FOX_RAMDISK/$RAMDISK_SBIN/ash ]; then
	    T=$(readlink $FOX_RAMDISK/$RAMDISK_SBIN/ash)
	    [ "$(basename $T)" = "bash" ] && rm -f $FOX_RAMDISK/$RAMDISK_SBIN/ash
	fi
  fi

  # create symlink for /sbin/bash of missing?
  if [ -f "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/bash" -a ! -e "$FOX_RAMDISK/$RAMDISK_SBIN/bash" ]; then
     echo -e "${GREEN}-- Creating a bash symbolic link: /sbin/bash -> /system/bin/bash ...${NC}"
     ln -sf $RAMDISK_SYSTEM_BIN/bash $FOX_RAMDISK/$RAMDISK_SBIN/bash
  fi

  # Include nano editor ?
  if [ "$FOX_USE_NANO_EDITOR" = "1" ]; then
      echo -e "${GREEN}-- Copying nano editor ...${NC}"
      mkdir -p $FOX_RAMDISK/FFiles/nano/
      $CP -af $FOX_VENDOR_PATH/Files/nano/sbin/nano $FOX_RAMDISK/$RAMDISK_SBIN/
      if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" != "1" ]; then
      	 $CP -af $FOX_VENDOR_PATH/Files/nano/ $FOX_RAMDISK/FFiles/
      fi
  else
      if [ -d $FOX_RAMDISK/FFiles/nano/ ]; then
         echo -e "${GREEN}-- Removing the dangling \"$FOX_RAMDISK/FFiles/nano/\" ...${NC}"
         rm -rf $FOX_RAMDISK/FFiles/nano/
      fi
  fi

  # exclude all species of nano?
  if [ "$FOX_EXCLUDE_NANO_EDITOR" = "1" ]; then
      echo -e "${RED}-- Removing the nano files from the build ...${NC}"
      [ -d $FOX_RAMDISK/FFiles/nano/ ] && rm -rf $FOX_RAMDISK/FFiles/nano/
      rm -f $FOX_RAMDISK/$RAMDISK_SBIN/nano
      rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/nano
      rm -f $FOX_RAMDISK/$RAMDISK_ETC/init/nano*
      rm -rf $FOX_RAMDISK/$RAMDISK_ETC/nano
      if [ -d $FOX_RAMDISK/$RAMDISK_ETC/terminfo -a "$FOX_DRASTIC_SIZE_REDUCTION" != "1" ]; then
         echo -e "${WHITEONRED}-- Do a clean build, or remove \"$FOX_RAMDISK/$RAMDISK_ETC/terminfo\" ...${NC}"
      fi
  fi

  # Include standalone "tar" binary ?
  if [ "$FOX_USE_TAR_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the GNU \"tar\" binary (gnutar) ...${NC}"
      $CP -p $FOX_VENDOR_PATH/Files/gnutar $FOX_RAMDISK/$RAMDISK_SBIN/
      chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/gnutar
  else
      rm -f $FOX_RAMDISK/$RAMDISK_SBIN/gnutar
  fi

  # Include standalone "sed" binary ?
  if [ "$FOX_USE_SED_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the GNU \"sed\" binary (gnused) ...${NC}"
      $CP -p $FOX_VENDOR_PATH/Files/gnused $FOX_RAMDISK/$RAMDISK_SBIN/
      chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/gnused
  else
      rm -f $FOX_RAMDISK/$RAMDISK_SBIN/gnused
  fi

  # Include standalone "grep" binary ?
  if [ "$FOX_USE_GREP_BINARY" = "1"  -a -x $FOX_VENDOR_PATH/Files/grep ]; then
      echo -e "${GREEN}-- Copying the GNU \"grep\" binary ...${NC}"
      rm -f $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/grep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep
      $CP -pf $FOX_VENDOR_PATH/Files/grep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/
      echo '#!/sbin/sh' &> "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep"
      echo '#!/sbin/sh' &> "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep"
      echo 'exec grep -F "$@"' >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep"
      echo 'exec grep -E "$@"' >> "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep"
      chmod 0755 $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/grep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/fgrep $FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/egrep
  fi

  # Include standalone "zstd" binary ?
  if [ "$FOX_USE_ZSTD_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the \"zstd\" binary ...${NC}"
      $CP -p $FOX_VENDOR_PATH/prebuilt/$TARGET_ARCH/zstd $FOX_RAMDISK/$RAMDISK_SBIN/
      chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/zstd
  else
      rm -f $FOX_RAMDISK/$RAMDISK_SBIN/zstd
  fi

  # Include standalone "lz4" binary ?
  if [ "$FOX_USE_LZ4_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the \"lz4\" binary ...${NC}"
      $CP -p $FOX_VENDOR_PATH/prebuilt/$TARGET_ARCH/lz4 $FOX_RAMDISK/$RAMDISK_SBIN/
      chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/lz4
  else
      rm -f $FOX_RAMDISK/$RAMDISK_SBIN/lz4
  fi

  # Include our own "zip" binary ?
  if [ -f "$FOX_VENDOR_PATH/../../external/zip/Android.mk" -a "$FOX_EXCLUDE_ZIP" != "1" ]; then
         echo -e "${RED}-- Using the InfoZip \"zip\" built from source ...${NC}"
  elif [ "$FOX_REMOVE_ZIP_BINARY" = "1" ]; then
      [ -e $FOX_RAMDISK/$RAMDISK_SBIN/zip ] && {
         echo -e "${RED}-- Removing the OrangeFox InfoZip \"zip\" binary ...${NC}"
         rm -f $FOX_RAMDISK/$RAMDISK_SBIN/zip
      }
  else
      if [ "$FOX_SKIP_ZIP_BINARY" != "1" ]; then
         echo -e "${GREEN}-- Copying the OrangeFox InfoZip \"zip\" binary ...${NC}"
         if [ -e $FOX_RAMDISK/$RAMDISK_SBIN/zip ]; then
            rm -f $FOX_RAMDISK/$RAMDISK_SBIN/zip
         fi
         $CP -pf $FOX_VENDOR_PATH/Files/zip $FOX_RAMDISK/$RAMDISK_SBIN/
         chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/zip
      fi
  fi

  # if zip is built from source (in /system/bin/) create a symlink to it if necessary
  if [ -x "$FOX_RAMDISK/$RAMDISK_SYSTEM_BIN/zip" ]; then
     [ ! -e "$FOX_RAMDISK/$RAMDISK_SBIN/zip" ] && ln -sf /system/bin/zip $FOX_RAMDISK/$RAMDISK_SBIN/zip
  fi

  # embed the system partition (in foxstart.sh)
  F=$FOX_RAMDISK/$RAMDISK_SBIN/foxstart.sh
  if [ -n "$FOX_RECOVERY_SYSTEM_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery system partition to \"$FOX_RECOVERY_SYSTEM_PARTITION\" ${NC}"
     sed -i -e "s|^SYSTEM_BLOCK=.*|SYSTEM_BLOCK=\"$FOX_RECOVERY_SYSTEM_PARTITION\"|" $F
  fi

  # embed the vendor partition (in foxstart.sh)
  F=$FOX_RAMDISK/$RAMDISK_SBIN/foxstart.sh
  if [ -n "$FOX_RECOVERY_VENDOR_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery vendor partition to \"$FOX_RECOVERY_VENDOR_PARTITION\" ${NC}"
     sed -i -e "s|^VENDOR_BLOCK=.*|VENDOR_BLOCK=\"$FOX_RECOVERY_VENDOR_PARTITION\"|" $F
  fi

  # embed the boot partition (in foxstart.sh)
  F=$FOX_RAMDISK/sbin/foxstart.sh
  if [ -n "$FOX_RECOVERY_BOOT_PARTITION" ]; then
     echo -e "${RED}-- Changing the recovery boot partition to \"$FOX_RECOVERY_BOOT_PARTITION\" ${NC}"
     sed -i -e "s|^BOOT_BLOCK=.*|BOOT_BLOCK=\"$FOX_RECOVERY_BOOT_PARTITION\"|" $F
  fi

  # embed the build var (in foxstart.sh) FOX_SETTINGS_ROOT_DIRECTORY
  F=$FOX_RAMDISK/sbin/foxstart.sh
  if [ -n "$FOX_SETTINGS_ROOT_DIRECTORY" ]; then
     echo -e "${RED}-- This build will use $FOX_SETTINGS_ROOT_DIRECTORY for its internal settings ... ${NC}"
     sed -i -e "s|^FOX_SETTINGS_ROOT_DIRECTORY=.*|FOX_SETTINGS_ROOT_DIRECTORY=\"$FOX_SETTINGS_ROOT_DIRECTORY\"|" $F
  elif [ "$FOX_USE_DATA_RECOVERY_FOR_SETTINGS" = "1" ]; then
     echo -e "${RED}-- This build will use /data/recovery/ for its internal settings ... ${NC}"
     sed -i -e "s/^FOX_USE_DATA_RECOVERY_FOR_SETTINGS=.*/FOX_USE_DATA_RECOVERY_FOR_SETTINGS=\"1\"/" $F
  fi

  # mark whether this is a vAB or vanilla build
  if [ "$IS_VIRTUAL_AB_DEVICE" = "1" -o "$IS_VANILLA_BUILD=1" = "1" ]; then
	F=$FOX_RAMDISK/sbin/foxstart.sh
	sed -i -e "s/^VIRTUAL_AB_OR_VANILLA=.*/VIRTUAL_AB_OR_VANILLA=\"1\"/" $F
  fi

  # Include mmgui
  $CP -p $FOX_VENDOR_PATH/Files/mmgui $FOX_RAMDISK/$RAMDISK_SBIN/mmgui
  chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/mmgui

  # Include aapt (1.7mb!) ?
  if [ "$FOX_REMOVE_AAPT" = "1" ]; then
     echo -e "${GREEN}-- Omitting the aapt binary ...${NC}"
     # remove aapt if it is there from a previous build
     rm -f $FOX_RAMDISK/$RAMDISK_SBIN/aapt
  else
	$CP -p $FOX_VENDOR_PATH/prebuilt/$TARGET_ARCH/aapt $FOX_RAMDISK/$RAMDISK_SBIN/aapt
	#$CP -p $FOX_VENDOR_PATH/Files/aapt $FOX_RAMDISK/$RAMDISK_SBIN/aapt
	chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/aapt
  fi

  # enable the app manager?
  if [ "$FOX_ENABLE_APP_MANAGER" = "1" ]; then
     echo -e "${GREEN}-- Enabling the App Manager ...${NC}"
  else
     echo -e "${GREEN}-- Omitting the aapt binary (it is useless if the app manager is not enabled) ...${NC}"
     # remove aapt also, as it would be redundant
     rm -f $FOX_RAMDISK/$RAMDISK_SBIN/aapt
  fi

  # fox_10 and later - include some stuff (busybox, new magisk)
  if [ "$FOX_REMOVE_BUSYBOX_BINARY" = "1" ]; then
     rm -f $FOX_RAMDISK/$RAMDISK_SBIN/busybox
  else
     $CP -p $FOX_VENDOR_PATH/Files/busybox $FOX_RAMDISK/$RAMDISK_SBIN/busybox
     chmod 0755 $FOX_RAMDISK/$RAMDISK_SBIN/busybox
  fi

#########################################################################################
  if [ "$(enabled $FOX_CUSTOM_BINS_TO_SDCARD)" = "1" ]; then
     process_custom_bins_to_sdcard;
  fi
#########################################################################################
  
  # Get Magisk version
  tmp1=$FOX_VENDOR_PATH/FoxFiles/Magisk.zip
  if [ -n "$FOX_USE_SPECIFIC_MAGISK_ZIP" -a -e "$FOX_USE_SPECIFIC_MAGISK_ZIP" ]; then
     tmp1=$FOX_USE_SPECIFIC_MAGISK_ZIP
  fi
  # is this an old magisk zip or a new one?
  tmp2=$(unzip -l $tmp1 | grep common/util_functions.sh)
  if [ -n "$tmp2" ]; then
     MAGISK_VER=$(unzip -c $tmp1 common/util_functions.sh | grep MAGISK_VER= | sed -E 's+MAGISK_VER="(.*)"+\1+')
  else
     tmp2=$(unzip -c $tmp1 assets/util_functions.sh | grep "MAGISK_VER=")
     MAGISK_VER=$(cut -d= -f2 <<<$tmp2 | sed "s|[',]||g")
  fi

  echo -e "${GREEN}-- Detected Magisk version: ${MAGISK_VER}${NC}"
  sed -i -E "s+\"magisk_ver\" value=\"(.*)\"+\"magisk_ver\" value=\"$MAGISK_VER\"+" $FOX_RAMDISK/twres/ui.xml

  # Include text files
  $CP -p $FOX_VENDOR_PATH/Files/credits.txt $FOX_RAMDISK/twres/credits.txt
  $CP -p $FOX_VENDOR_PATH/Files/translators.txt $FOX_RAMDISK/twres/translators.txt
  $CP -p $FOX_VENDOR_PATH/Files/changelog.txt $FOX_RAMDISK/twres/changelog.txt

  # if a local callback script is declared, run it, passing to it the ramdisk directory (first call)
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" -a -f "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
	bash $FOX_LOCAL_CALLBACK_SCRIPT "$FOX_RAMDISK" "--first-call"
  fi

  # compress some executables?
  if [ -n "$FOX_COMPRESS_EXECUTABLES" -a "$FOX_COMPRESS_EXECUTABLES" != "0" ]; then
	[  "$FOX_COMPRESS_EXECUTABLES" = "1" ] && export FOX_COMPRESS_EXECUTABLES="/sbin /system/bin";
	compress_some_executables;
  fi

  # reduce ramdisk size drastically?
  if [ "$FOX_DRASTIC_SIZE_REDUCTION" = "1" ]; then
     echo -e "${WHITEONRED}-- Going to do some drastic size reductions! ${NC}"
     echo -e "${WHITEONRED}-- Don't worry if you see some resource errors in the recovery's debug screen. ${NC}"
     reduce_ramdisk_size;
  fi

  # save the build date
  BUILD_DATE=$(date -u "+%c")
  BUILD_DATE_UTC=$(date "+%s")
  [ ! -e "$DEFAULT_PROP" ] && DEFAULT_PROP="$FOX_RAMDISK/default.prop"
  [ ! -e "$DEFAULT_PROP_ROOT" ] && DEFAULT_PROP_ROOT="$DEFAULT_PROP"

  # if we need to work around the bugged aosp alleged anti-rollback protection
  if [ -n "$FOX_BUGGED_AOSP_ARB_WORKAROUND" ]; then
     echo -e "${WHITEONGREEN}-- Dealing with bugged AOSP alleged anti-ARB: setting build date to \"$FOX_BUGGED_AOSP_ARB_WORKAROUND\" (instead of the true date: \"$BUILD_DATE_UTC\") ...${NC}"
     Save_Build_Date "$FOX_BUGGED_AOSP_ARB_WORKAROUND" "$BUILD_DATE_UTC"
  else
     Save_Build_Date "$BUILD_DATE_UTC"
  fi

  # ensure that we have a proper record of the actual build date/time
  grep -q "ro.build.date.utc_fox=" $DEFAULT_PROP_ROOT && \
  	sed -i -e "s/ro.build.date.utc_fox=.*/ro.build.date.utc_fox=$BUILD_DATE_UTC/g" $DEFAULT_PROP_ROOT || \
  	echo "ro.build.date.utc_fox=$BUILD_DATE_UTC" >> $DEFAULT_PROP_ROOT

  grep -q "ro.bootimage.build.date.utc_fox=" $DEFAULT_PROP_ROOT && \
  	sed -i -e "s/ro.bootimage.build.date.utc_fox=.*/ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC/g" $DEFAULT_PROP_ROOT || \
  	echo "ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC" >> $DEFAULT_PROP_ROOT

  # also update prop.default
  grep -q "ro.build.date.utc_fox=" $DEFAULT_PROP && \
  	sed -i -e "s/ro.build.date.utc_fox=.*/ro.build.date.utc_fox=$BUILD_DATE_UTC/g" $DEFAULT_PROP || \
  	echo "ro.build.date.utc_fox=$BUILD_DATE_UTC" >> $DEFAULT_PROP

  grep -q "ro.bootimage.build.date.utc_fox=" $DEFAULT_PROP && \
  	sed -i -e "s/ro.bootimage.build.date.utc_fox=.*/ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC/g" $DEFAULT_PROP || \
  	echo "ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC" >> $DEFAULT_PROP

  #  save also to /etc/fox.cfg
  echo "FOX_BUILD_DATE=$BUILD_DATE" > $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  [ -z "$FOX_CURRENT_DEV_STR" ] && FOX_CURRENT_DEV_STR=$(git -C $FOX_VENDOR_PATH/../../bootable/recovery log -1 --format='%ad (%h)' --date=short) > /dev/null 2>&1
  if [ -n "$FOX_CURRENT_DEV_STR" ]; then
    export FOX_CURRENT_DEV_STR
    echo "FOX_CODE_BASE=$FOX_CURRENT_DEV_STR" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  fi

  echo "ro.build.date.utc_fox=$BUILD_DATE_UTC" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  echo "ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  if [ -n "$FOX_RECOVERY_SYSTEM_PARTITION" ]; then
     echo "SYSTEM_PARTITION=$FOX_RECOVERY_SYSTEM_PARTITION" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  fi
  if [ -n "$FOX_RECOVERY_INSTALL_PARTITION" ]; then
     echo "RECOVERY_PARTITION=$FOX_RECOVERY_INSTALL_PARTITION" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  fi
  if [ -n "$FOX_RECOVERY_VENDOR_PARTITION" ]; then
     echo "VENDOR_PARTITION=$FOX_RECOVERY_VENDOR_PARTITION" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  fi
  if [ -n "$FOX_RECOVERY_BOOT_PARTITION" ]; then
     echo "BOOT_PARTITION=$FOX_RECOVERY_BOOT_PARTITION" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg
  fi

  # save the codebase information
  grep -q "ro.build.fox_codebase=" $DEFAULT_PROP && \
  	sed -i -e "s/ro.build.fox_codebase=.*/ro.build.fox_codebase=$FOX_CURRENT_DEV_STR/g" $DEFAULT_PROP || \
  	echo "ro.build.fox_codebase=$FOX_CURRENT_DEV_STR" >> $DEFAULT_PROP

  grep -q "ro.build.fox_codebase=" $DEFAULT_PROP_ROOT && \
  	sed -i -e "s/ro.build.fox_codebase=.*/ro.build.fox_codebase=$FOX_CURRENT_DEV_STR/g" $DEFAULT_PROP_ROOT || \
  	echo "ro.build.fox_codebase=$FOX_CURRENT_DEV_STR" >> $DEFAULT_PROP_ROOT

  # save the build id
   echo -e "${GREEN}-- Generating the build ID ${NC}"
   tmp1=$(generate_build_id)
   grep -q "ro.build.fox_id=" $DEFAULT_PROP_ROOT && \
  	sed -i -e "s/ro.build.fox_id=.*/ro.build.fox_id=$tmp1/g" $DEFAULT_PROP_ROOT || \
  	echo "ro.build.fox_id=$tmp1" >> $DEFAULT_PROP_ROOT

  # also update prop.default
   grep -q "ro.build.fox_id=" $DEFAULT_PROP && \
  	sed -i -e "s/ro.build.fox_id=.*/ro.build.fox_id=$tmp1/g" $DEFAULT_PROP || \
  	echo "ro.build.fox_id=$tmp1" >> $DEFAULT_PROP

   echo "ro.build.fox_id=$tmp1" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg

   # stamp our identity in the prop
   sed -i -e "s/$TARGET_PRODUCT/fox_$FOX_DEVICE/g" $DEFAULT_PROP

   # save some original file sizes
   echo -e "${GREEN}-- Saving some original file sizes ${NC}"
   [ -n "$recovery_uncompressed_ramdisk" ] && F=$(filesize $recovery_uncompressed_ramdisk) || F=0
   echo "ramdisk_size=$F" >> $FOX_RAMDISK/$RAMDISK_ETC/fox.cfg 

  # let's be clear where we are ...
  if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
     echo -e "${RED}-- Building the recovery image, using the official AOSP recovery image builder ...${NC}"
  fi

fi

# this is the final stage after the recovery image has been created
# process the recovery image where necessary (and repack where necessary)
if [ "$FOX_VENDOR_CMD" = "Fox_After_Recovery_Image" ]; then

     if [ "$FOX_SAMSUNG_DEVICE" = "1" -o "$FOX_SAMSUNG_DEVICE" = "true" ]; then
        SAMSUNG_DEVICE="samsung"
     else
        SAMSUNG_DEVICE=$(file_getprop "$DEFAULT_PROP" "ro.product.manufacturer")
     fi

     if [ -z "$SAMSUNG_DEVICE" ]; then
        SAMSUNG_DEVICE=$(grep "manufacturer=samsung" "$DEFAULT_PROP")
        [ -n "$SAMSUNG_DEVICE" ] && SAMSUNG_DEVICE="samsung"
     fi

     if [ -z "$INSTALLED_RECOVERYIMAGE_TARGET" ]; then
        if [ -n "$INSTALLED_BOOTIMAGE_TARGET" ]; then
           INSTALLED_RECOVERYIMAGE_TARGET="$INSTALLED_BOOTIMAGE_TARGET"
        fi
     fi

     if [ "$IS_VENDOR_BOOT_RECOVERY" = "1" ]; then
        if [ -n "$INSTALLED_VENDOR_BOOTIMAGE_TARGET" ]; then
           INSTALLED_RECOVERYIMAGE_TARGET="$INSTALLED_VENDOR_BOOTIMAGE_TARGET"
        else
           INSTALLED_RECOVERYIMAGE_TARGET="$OUT/$COMPILED_IMAGE_FILE"
        fi
     fi

     # copy
     echo -e "${GREEN}-- Copying recovery: \"$INSTALLED_RECOVERYIMAGE_TARGET\" --> \"$RECOVERY_IMAGE\" ${NC}"
     $CP -p "$INSTALLED_RECOVERYIMAGE_TARGET" "$RECOVERY_IMAGE"

     # samsung stuff?
     if [ "$SAMSUNG_DEVICE" = "samsung" -a "$FOX_NO_SAMSUNG_SPECIAL" != "1" ]; then
     	echo -e "${RED}-- Appending SEANDROIDENFORCE to $RECOVERY_IMAGE ${NC}"
     	echo -n "SEANDROIDENFORCE" >> $RECOVERY_IMAGE
     fi

     # md5sum
     cd "$OUT" && md5sum "$RECOVERY_IMAGE" > "$RECOVERY_IMAGE.md5" && cd - > /dev/null 2>&1

     # more samsung stuff
     if [ "$SAMSUNG_DEVICE" = "samsung" -a "$FOX_NO_SAMSUNG_SPECIAL" != "1" ]; then
     	echo -e "${RED}-- Creating Odin flashable recovery tar ($RECOVERY_IMAGE.tar) ... ${NC}"

     	# make sure that the image being tarred is the correct one
     	$CP -pf "$RECOVERY_IMAGE" $INSTALLED_RECOVERYIMAGE_TARGET
     	tar -C $(dirname "$RECOVERY_IMAGE") -H ustar -c $COMPILED_IMAGE_FILE > $RECOVERY_IMAGE".tar"
     fi

   # create update zip installer
   if [ "$FOX_DISABLE_UPDATEZIP" != "1" ]; then
      	do_create_update_zip
   else
	echo -e "${RED}-- Skip creating recovery zip${NC}"
   fi

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
   export RECOVERY_IMAGE

   if [ "$FOX_DISABLE_UPDATEZIP" != "1" ]; then
	echo -e ""
	echo -e "${GREEN}Recovery zip:${NC} $ZIP_FILE"
	echo -e "          MD5: $ZIP_FILE.md5"
   	echo -e ""
   	export ZIP_FILE
   fi

   echo -e "=================================================================="

   # clean up, with success code
   abort 0
fi
# end!
