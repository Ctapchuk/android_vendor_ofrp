#!/bin/bash
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2018-2020 The OrangeFox Recovery Project
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
# 20 July 2020
#
# For optional environment variables - to be declared before building,
# see "orangefox_build_vars.txt" for full details
#
# It is best to declare them in a script that you will use for building 
#
#

# export whatever has been passed on by build/core/Makefile (we expect at least 4 arguments)
if [ -n "$4" ]; then
   echo "#########################################################################"
   echo "Variables exported from build/core/Makefile:"
   echo "$@"
   export "$@"
   echo "#########################################################################"
else
   if [ "$FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER" = "1" ]; then
      echo -e "${RED}-- Build OrangeFox: FATAL ERROR! ${NC}"
      echo -e "${RED}-- You cannot use FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER without patching build/core/Makefile in the build system! ${NC}"
      exit 100  
   fi
fi
#

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

#
RECOVERY_DIR="recovery"
FOX_VENDOR_PATH=vendor/$RECOVERY_DIR

# 
[ "$FOX_VENDOR_CMD" != "Fox_After_Recovery_Image" ] && echo -e "${RED}Building OrangeFox...${NC}"
echo -e "${BLUE}-- Setting up environment variables${NC}"

if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
	FOX_WORK="$TARGET_RECOVERY_ROOT_OUT"
	FOX_RAMDISK="$TARGET_RECOVERY_ROOT_OUT"
	DEFAULT_PROP_ROOT="$TARGET_RECOVERY_ROOT_OUT/../../root/default.prop"
else
	FOX_WORK=$OUT/FOX_AIK
	FOX_RAMDISK="$FOX_WORK/ramdisk"
	DEFAULT_PROP_ROOT="$FOX_WORK/../root/default.prop"
fi

# default prop
DEFAULT_PROP="$FOX_RAMDISK/prop.default"

# device name
FOX_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

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

# sort out the out_name
if [ "$FOX_BUILD_TYPE" = "Unofficial" ] && [ "$FOX_BUILD" = "Unofficial" ]; then
   FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$FOX_DEVICE
else
   FOX_OUT_NAME=OrangeFox-$FOX_BUILD-$FOX_BUILD_TYPE-$FOX_DEVICE
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
      echo -e "${RED}-- OrangeFox.sh FATAL ERROR - A/B device - but other necessary vars not set. ${NC}"
      echo "-- You must do this - \"export OF_USE_MAGISKBOOT=1\" "
      echo "-- And this         - \"export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1\" "
      echo -e "${RED}-- Quitting now ... ${NC}"
      echo -e "${RED}-- ************************************************************************************************${NC}"
      exit 200
   fi
fi

# alternative devices
[ -n "$OF_TARGET_DEVICES" -a -z "$TARGET_DEVICE_ALT" ] && export TARGET_DEVICE_ALT="$OF_TARGET_DEVICES"

# copy recovery.img
[ -f $OUT/recovery.img ] && cp -r $OUT/recovery.img $RECOVERY_IMAGE

# 2GB version
RECOVERY_IMAGE_2GB=$OUT/$FOX_OUT_NAME"_lite.img"
[ -z "$BUILD_2GB_VERSION" ] && BUILD_2GB_VERSION="0" # by default, build only the full version

# exports
export FOX_DEVICE TMP_VENDOR_PATH FOX_OUT_NAME FOX_RAMDISK FOX_WORK

# ****************************************************
# --- embedded functions
# ****************************************************

# to saved the build date, and (if desired) patch bugged alleged anti-rollback on some ROMs
Save_Build_Date() {
local DT="$1"
local F="$DEFAULT_PROP_ROOT"
   [ ! -f  "$F" ] && F="$DEFAULT_PROP"
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
local D="$OF_WORKING_DIR"
local F="$D/META-INF/com/google/android/update-binary"
   if [ -n "$TARGET_DEVICE_ALT" ]; then
      sed -i -e "s/TARGET_DEVICE_ALT=.*/TARGET_DEVICE_ALT=\"$TARGET_DEVICE_ALT\"/" $F
   fi
}

# whether this is a system-as-root build
SAR_BUILD() {
  [ ! -d "$FOX_RAMDISK/system_root/" ] && { echo "0"; return; }
  local C=$(cat "$FOX_RAMDISK/etc/recovery.fstab" | grep -s ^"/system_root")
  [ -z "$C" ] && { echo "0"; return; }
  C=$(file_getprop "$FOX_RAMDISK/prop.default" "ro.build.system_root_image")
  [ "$C" = "true" ] && echo "1" || echo "0"
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
     [ -x $T/OrangeFox.sh ] && FOX_VENDOR_PATH=$T
  }
}

# create zip file
do_create_update_zip() {
local TDT=$(date "+%d %B %Y")
  echo -e "${BLUE}-- Creating update.zip${NC}"
  FILES_DIR=$FOX_VENDOR_PATH/FoxFiles
  INST_DIR=$FOX_VENDOR_PATH/installer
  
  # names of output zip file(s)
  ZIP_FILE=$OUT/$FOX_OUT_NAME.zip
  ZIP_FILE_GO=$OUT/$FOX_OUT_NAME"_lite.zip"
  echo "- Creating $ZIP_FILE for deployment ..."
  
  # clean any existing files
  rm -rf $OF_WORKING_DIR
  rm -f $ZIP_FILE_GO $ZIP_FILE

  # recreate dir
  mkdir -p $OF_WORKING_DIR
  cd $OF_WORKING_DIR

  # copy documentation
  cp -a $FOX_VENDOR_PATH/Files/INSTALL.txt .
  
  # copy recovery image
  cp -a $RECOVERY_IMAGE ./recovery.img
   
  # copy installer bins and script 
  cp -a $INST_DIR/* .

  # copy FoxFiles/ to sdcard/Fox/
  cp -a $FILES_DIR/ sdcard/Fox
  
  # any local changes to a port's installer directory?
  if [ -n "$FOX_PORTS_INSTALLER" ] && [ -d "$FOX_PORTS_INSTALLER" ]; then
     cp -a $FOX_PORTS_INSTALLER/* . 
  fi
  
  # patch update-binary (which is a script) to run only for the current device 
  # (mido is the default)
  local F="$OF_WORKING_DIR/META-INF/com/google/android/update-binary"
  sed -i -e "s/mido/$FOX_DEVICE/g" $F     
  sed -i -e "s/ALT_DEVICE/$FOX_DEVICE_ALT/g" $F     

  # embed the release version
  sed -i -e "s/RELEASE_VER/$FOX_BUILD/" $F

  # embed the build date
  sed -i -e "s/TODAY/$TDT/" $F

  # if a local callback script is declared, run it, passing to it the temporary working directory (Last call)
  # "--last-call" = just before creating the OrangeFox update zip file
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$OF_WORKING_DIR" "--last-call"
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
     cp -af $FOX_RAMDISK/sbin/magiskboot .
     sed -i -e "s|^OF_AB_DEVICE=.*|OF_AB_DEVICE=\"1\"|" $F
  fi

  # Reset Settings
  if [ "$FOX_RESET_SETTINGS" = "disabled" ]; then
     echo -e "${WHITEONRED}-- Instructing the zip installer to NOT reset OrangeFox settings (NOT recommended!) ... ${NC}"
     sed -i -e "s|^FOX_RESET_SETTINGS=.*|FOX_RESET_SETTINGS=\"disabled\"|" $F
  fi

  # R11 
  if [ "$FOX_R11" = "1" ]; then
     echo -e "${RED}-- Preparing zip installer for OrangeFox R11 ... ${NC}"
     sed -i -e "s|^FOX_R11=.*|FOX_R11=\"1\"|" $F
  fi

  # skip all patches ?
  if [ "$OF_VANILLA_BUILD" = "1" ]; then
     echo -e "${RED}-- This build will skip all OrangeFox patches ... ${NC}"
     sed -i -e "s|^OF_VANILLA_BUILD=.*|OF_VANILLA_BUILD=\"1\"|" $F
  fi

  # omit AromaFM ?
  if [ "$FOX_DELETE_AROMAFM" = "1" ]; then
     echo -e "${GREEN}-- Deleting AromaFM ...${NC}"
     rm -rf $OF_WORKING_DIR/sdcard/Fox/FoxFiles/AromaFM
  fi

  # use anykernel3 version of OF_initd
  echo -e "${GREEN}-- Using OF_initd-ak3 zip ...${NC}"
  rm -f $OF_WORKING_DIR/sdcard/Fox/FoxFiles/OF_initd.zip
  mv $OF_WORKING_DIR/sdcard/Fox/FoxFiles/OF_initd-ak3.zip $OF_WORKING_DIR/sdcard/Fox/FoxFiles/OF_initd.zip
  
  # alternative/additional device codename? (eg, "kate" (for kenzo); "willow" (for ginkgo))
  if [ -n "$TARGET_DEVICE_ALT" ]; then
     echo -e "${GREEN}-- Adding the alternative device codename: \"$TARGET_DEVICE_ALT\" ${NC}"
     Add_Target_Alt;
  fi

  # create update zip
  ZIP_CMD="zip --exclude=*.git* -r9 $ZIP_FILE ."
  echo "- Running ZIP command: $ZIP_CMD"
  $ZIP_CMD -z <$FOX_VENDOR_PATH/Files/INSTALL.txt
   
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
  	$ZIP_CMD -z <$FOX_VENDOR_PATH/Files/INSTALL.txt
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
  
  rm -rf $OF_WORKING_DIR # delete OF Working dir 
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

# try to trim the ramdisk for really small recovery partitions
reduce_ramdisk_size() {
local big_xml=$FOX_RAMDISK/twres/pages/customization.xml
local small_xml=$FOX_RAMDISK/twres/pages/smaller_size.txt
local C=""
local D=""
local F=""
local REMOVE_THEME_COLORS="1"

      echo "- Pruning the ramdisk to reduce the size..."

      # remove some theme colours
      if [ "$REMOVE_THEME_COLORS" = "1" ]; then
         echo -e "${GREEN}-- Removing some theme colours ... ${NC}"
      	 declare -a fColors=("Amber" "Brown" "Pink" "Purple")
         local image_xml=$FOX_RAMDISK/twres/resources/images.xml
         for i in "${fColors[@]}"
         do
       		F=$FOX_RAMDISK/twres/images/$i
       		[ -d $F ] && rm -rf $F
       		C="Color"$i
       		
       		#D=$C"_deleted_"
       		#sed -i -e "s/$C/$D/" $image_xml
       		
       		# don't load it in the UI
       		sed -i -e "/$C/d" $image_xml
         done
      fi

      # remove some fonts? (only do so if we have a working "small" xml to cover the situation)
      echo -e "${GREEN}-- Removing some fonts ... ${NC}"
      declare -a FontFiles=("Amatic" "AngryBirds" "Bender" "Cooljazz" "Chococooky")
         
      # delete the font (*.ttf) tiles
      for i in "${FontFiles[@]}"
      do
     	   C=$i".ttf"
     	   F=$FOX_RAMDISK/twres/fonts/$C
     	   rm -f $F
     	   # remove references to them in images.xml 
     	   sed -i "/$C/d" $image_xml
      done

      # remove references to them in customization.xml, using their font numbers
      # the the matching line plus the next 2 lines
      for i in {5..9}; do
    	   F="font"$i
     	   sed -i "/$F/I,+2 d" $big_xml
      done
      
      # remove other large files
      echo -e "${GREEN}-- Removing some large files ... ${NC}"
      local FFil="$FOX_RAMDISK/FFiles"
      rm -rf $FFil/OF_initd
      rm -rf $FFil/AromaFM
      rm -rf $FFil/nano
      rm -f $FOX_RAMDISK/sbin/aapt
      rm -f $FOX_RAMDISK/sbin/zip
      rm -f $FOX_RAMDISK/sbin/nano
      if [ "$FOX_USE_BASH_SHELL" = "1" -o "$FOX_ASH_IS_BASH" = "1" ]; then
     	 echo -e "${WHITEONRED}-- ERROR!!! Never use \"FOX_USE_BASH_SHELL=1\" together with \"FOX_DRASTIC_SIZE_REDUCTION\" !!!${NC}"
     	 #exit 255
      else
         rm -f $FOX_RAMDISK/sbin/bash
         rm -f $FOX_RAMDISK/etc/bash.bashrc
      fi
      #
}

# ****************************************************
# *** now the real work starts!
# ****************************************************

# get the full FOX_VENDOR_PATH
expand_vendor_path

# did we export tmp directory for OrangeFox ports?
[ -n "$FOX_PORTS_TMP" ] && OF_WORKING_DIR="$FOX_PORTS_TMP" || OF_WORKING_DIR="$FOX_VENDOR_PATH/tmp"

# is the working directory still there from a previous build? If so, remove it
if [ "$FOX_VENDOR_CMD" != "Fox_Before_Recovery_Image" ]; then
   if [ -d "$FOX_WORK" ]; then
      echo -e "${BLUE}-- Working folder found in OUT. Cleaning up${NC}"
      rm -rf "$FOX_WORK"
   fi

   # unpack recovery image into working directory
   echo -e "${BLUE}-- Unpacking recovery image${NC}"
   bash "$FOX_VENDOR_PATH/tools/mkboot" "$OUT/recovery.img" "$FOX_WORK" > /dev/null 2>&1

  # perhaps we don't need some "Tools" ?
  if [ "$(SAR_BUILD)" = "1" ]; then
     echo -e "${GREEN}-- This is a system-as-root build ...${NC}"
  else
     echo -e "${GREEN}-- This is NOT a system-as-root build - removing the system_sar_mount directory ...${NC}"
     rm -rf "$FOX_RAMDISK/FFiles/Tools/system_sar_mount/"
  fi

fi

###############################################################
# copy stuff to the ramdisk and do all necessary patches
if [ "$FOX_VENDOR_CMD" != "Fox_After_Recovery_Image" ]; then
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
      cp "$FOX_VENDOR_PATH/prebuilt/arm64/resetprop" "$FOX_RAMDISK/sbin"
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
  if [ "$(readlink $FOX_RAMDISK/sbin/ps)" = "toybox" ]; then # if using toybox, then we don't need this
     rm -f "$FOX_RAMDISK/FFiles/ps"
     echo -e "${GREEN}-- The \"ps\" command is symlinked to \"toybox\". NOT replacing it...${NC}"
  else
     if [ "$FOX_REPLACE_BUSYBOX_PS" = "1" ]; then
        if [ -f "$FOX_RAMDISK/FFiles/ps" ]; then
           echo -e "${GREEN}-- Replacing the busybox \"ps\" command with our own full version ...${NC}"
  	   rm -f $FOX_RAMDISK/sbin/ps
  	   ln -s /FFiles/ps $FOX_RAMDISK/sbin/ps
        fi
     fi
  fi

  # Replace the toolbox "getprop" with "resetprop" ?
  if [ "$FOX_REPLACE_TOOLBOX_GETPROP" = "1" -a -f $FOX_RAMDISK/sbin/resetprop ]; then
     echo -e "${GREEN}-- Replacing the toolbox \"getprop\" command with a fuller version ...${NC}"
     rm -f $FOX_RAMDISK/sbin/getprop
     ln -s /sbin/resetprop $FOX_RAMDISK/sbin/getprop
  fi

  # replace busybox lzma (and "xz") with our own 
  # use the full "xz" binary for lzma, and for xz - smaller in size, and does the same job
  if [ "$OF_USE_MAGISKBOOT_FOR_ALL_PATCHES" != "1" ]; then
     echo -e "${GREEN}-- Replacing the busybox \"lzma\" command with our own full version ...${NC}"
     rm -f $FOX_RAMDISK/sbin/lzma
     rm -f $FOX_RAMDISK/sbin/xz
     cp -a $FOX_VENDOR_PATH/Files/xz $FOX_RAMDISK/sbin/lzma
     ln -s lzma $FOX_RAMDISK/sbin/xz
  fi
  
  # system_root stuff
  if [ "$OF_SUPPORT_PRE_FLASH_SCRIPT" = "1" ]; then
     echo -e "${GREEN}-- OF_SUPPORT_PRE_FLASH_SCRIPT=1 (system_root device); copying fox_pre_flash to sbin ...${NC}"
     echo -e "${GREEN}-- Make sure that you mount both /system *and* /system_root in your fstab.${NC}"     
     cp -a $FOX_VENDOR_PATH/Files/fox_pre_flash $FOX_RAMDISK/sbin
  fi
     
  # Include bash shell ?
  if [ "$FOX_REMOVE_BASH" = "1" ]; then
     export FOX_USE_BASH_SHELL="0"
     # remove bash if it is there from a previous build
     rm -f $FOX_RAMDISK/sbin/bash
     rm -f $FOX_RAMDISK/etc/bash.bashrc
  else
     echo -e "${GREEN}-- Copying bash ...${NC}"
     cp -a $FOX_VENDOR_PATH/Files/bash $FOX_RAMDISK/sbin/bash
     cp -a $FOX_VENDOR_PATH/Files/fox.bashrc $FOX_RAMDISK/etc/bash.bashrc
     chmod 0755 $FOX_RAMDISK/sbin/bash
     if [ "$FOX_ASH_IS_BASH" = "1" ]; then
        export FOX_USE_BASH_SHELL="1"     
     fi
  fi
  
  # replace busybox "sh" with bash ?
  if [ "$FOX_USE_BASH_SHELL" = "1" ]; then
     if [ -f "$FOX_RAMDISK/sbin/sh" ]; then
        echo -e "${GREEN}-- Replacing the busybox \"sh\" applet with bash ...${NC}"
  	rm -f $FOX_RAMDISK/sbin/sh
  	ln -s bash $FOX_RAMDISK/sbin/sh
  	# do the same for "ash"?
        if [ "$FOX_ASH_IS_BASH" = "1" ]; then
           echo -e "${GREEN}-- Replacing the busybox \"ash\" applet with bash ...${NC}"
  	   rm -f $FOX_RAMDISK/sbin/ash
  	   ln -s bash $FOX_RAMDISK/sbin/ash
  	fi
     fi
  fi

  # Include nano editor ?
  if [ "$FOX_USE_NANO_EDITOR" = "1" ]; then
      echo -e "${GREEN}-- Copying nano editor ...${NC}"
      cp -af $FOX_VENDOR_PATH/Files/nano/ $FOX_RAMDISK/FFiles/
      cp -af $FOX_VENDOR_PATH/Files/nano/sbin/nano $FOX_RAMDISK/sbin/
  fi

  # Include standalone "tar" binary ?
  if [ "$FOX_USE_TAR_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the GNU \"tar\" binary (gnutar) ...${NC}"
      cp -af $FOX_VENDOR_PATH/Files/gnutar $FOX_RAMDISK/sbin/
      chmod 0755 $FOX_RAMDISK/sbin/gnutar
  fi

  # Include "zip" binary ?
  if [ "$FOX_USE_ZIP_BINARY" = "1" ]; then
      echo -e "${GREEN}-- Copying the OrangeFox InfoZip \"zip\" binary ...${NC}"
      cp -af $FOX_VENDOR_PATH/Files/zip $FOX_RAMDISK/sbin/
      chmod 0755 $FOX_RAMDISK/sbin/zip
  fi

  # Include mmgui
  cp -a $FOX_VENDOR_PATH/Files/mmgui $FOX_RAMDISK/sbin/mmgui
  chmod 0755 $FOX_RAMDISK/sbin/mmgui

  # Include aapt (1.7mb!) ?
  if [ "$FOX_REMOVE_AAPT" = "1" ]; then
     echo -e "${GREEN}-- Omitting the aapt binary ...${NC}"
     # remove aapt if it is there from a previous build
     rm -f $FOX_RAMDISK/sbin/aapt
  else
     cp -a $FOX_VENDOR_PATH/Files/aapt $FOX_RAMDISK/sbin/aapt
     chmod 0755 $FOX_RAMDISK/sbin/aapt
  fi

  # Get Magisk version
  MAGISK_VER=$(unzip -c $FOX_VENDOR_PATH/FoxFiles/Magisk.zip common/util_functions.sh | grep MAGISK_VER= | sed -E 's+MAGISK_VER="(.*)"+\1+')
  echo -e "${GREEN}-- Detected Magisk version: ${MAGISK_VER}${NC}"
  sed -i -E "s+\"magisk_ver\" value=\"(.*)\"+\"magisk_ver\" value=\"$MAGISK_VER\"+" $FOX_RAMDISK/twres/ui.xml

  # Include text files
  cp -a $FOX_VENDOR_PATH/Files/credits.txt $FOX_RAMDISK/twres/credits.txt
  cp -a $FOX_VENDOR_PATH/Files/translators.txt $FOX_RAMDISK/twres/translators.txt
  cp -a $FOX_VENDOR_PATH/Files/changelog.txt $FOX_RAMDISK/twres/changelog.txt

  # if a local callback script is declared, run it, passing to it the ramdisk directory (first call)
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$FOX_RAMDISK" "--first-call"
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

  #  save also to /etc/fox.cfg
  echo "FOX_BUILD_DATE=$BUILD_DATE" > $FOX_RAMDISK/etc/fox.cfg
  echo "ro.build.date.utc_fox=$BUILD_DATE_UTC" >> $FOX_RAMDISK/etc/fox.cfg
  echo "ro.bootimage.build.date.utc_fox=$BUILD_DATE_UTC" >> $FOX_RAMDISK/etc/fox.cfg

  # let's be clear where we are ...
  if [ "$FOX_VENDOR_CMD" = "Fox_Before_Recovery_Image" ]; then
     echo -e "${RED}-- Building the recovery image, using the official TWRP recovery image builder ...${NC}"
  fi
fi

# repack the recovery image
if [ -z "$FOX_VENDOR_CMD" ] || [ "$FOX_VENDOR_CMD" = "Fox_After_Recovery_Image" ]; then
     if [ "$FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER" = "1" ]; then
  	echo -e "${GREEN}-- Copying recovery: \"$INSTALLED_RECOVERYIMAGE_TARGET\" --> \"$RECOVERY_IMAGE\" ${NC}"
        cp -af "$INSTALLED_RECOVERYIMAGE_TARGET" "$RECOVERY_IMAGE"
  	cd "$OUT" && md5sum "$RECOVERY_IMAGE" > "$RECOVERY_IMAGE.md5" && cd - > /dev/null 2>&1
     else
  	echo -e "${BLUE}-- Repacking and copying recovery${NC}"
  	[ "$DEBUG" = "1" ] && echo "- DEBUG: Running command: bash $FOX_VENDOR_PATH/tools/mkboot $FOX_WORK $RECOVERY_IMAGE ***"
  	SAMSUNG_DEVICE=$(file_getprop "$FOX_RAMDISK/prop.default" "ro.product.manufacturer")
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
     fi
     # end: standard version

    #: build "lite" (2GB) version (virtually obsolete now) #
    if [ "$BUILD_2GB_VERSION" = "1" ] && [ "$FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER" != "1" ]; then
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
     	   if [ -L "$FOX_RAMDISK/sbin/sh" ]; then
              echo -e "${GREEN}-- Replacing bash 'sh' with busybox 'sh' ...${NC}"
  	      rm -f $FOX_RAMDISK/sbin/sh
  	      ln -s busybox $FOX_RAMDISK/sbin/sh
  	      # do the same for "ash"?
  	      if [ "$FOX_ASH_IS_BASH" = "1" ]; then
  	         echo -e "${GREEN}-- Replacing bash 'ash' with busybox 'ash' ...${NC}"
  	         rm -f $FOX_RAMDISK/sbin/ash
  	         ln -s busybox $FOX_RAMDISK/sbin/ash
  	      fi
     	   fi
 	fi
	[ "$DEBUG" = "1" ] && echo "*** Running command: bash $FOX_VENDOR_PATH/tools/mkboot $FOX_WORK $RECOVERY_IMAGE_2GB ***"
	bash "$FOX_VENDOR_PATH/tools/mkboot" "$FOX_WORK" "$RECOVERY_IMAGE_2GB" > /dev/null 2>&1
  	if [ "$SAMSUNG_DEVICE" = "samsung" ]; then
     	   echo -e "${RED}-- Appending SEANDROIDENFORCE to $RECOVERY_IMAGE_2GB ${NC}"
     	   echo -n "SEANDROIDENFORCE" >> $RECOVERY_IMAGE_2GB
  	fi
	cd "$OUT" && md5sum "$RECOVERY_IMAGE_2GB" > "$RECOVERY_IMAGE_2GB.md5" && cd - > /dev/null 2>&1
    fi # end: "GO" version

   # create update zip installer
   if [ "$OF_DISABLE_UPDATEZIP" != "1" ]; then
      	do_create_update_zip
      	
      	# create old theme zip file
      	do_create_old_theme_zip
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
   if [ "$OF_DISABLE_UPDATEZIP" != "1" ]; then
   echo -e ""
   echo -e ""
   echo -e "===========================${BLUE}Classic theme${NC}=========================="
   echo -e ""
   echo -e "${GREEN}ZIP File:${NC} $OUT/ClassicTheme.zip"
   echo -e ""
   echo -e "=================================================================="
   fi
fi
# end!
