#!/bin/bash
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
   RW_BUILD=Unofficial
else
   RW_BUILD=$TW_DEVICE_VERSION
fi

RW_VENDOR=vendor/recovery
RW_WORK=$OUT/RW_AIK
RW_RAMDISK="$RW_WORK/ramdisk"
RW_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)
RW_OUT_NAME=OrangeFox-$RW_BUILD-$RW_DEVICE
RECOVERY_IMAGE="$OUT/recovery.img"
FOX_VENDOR_PATH="$OUT/../../../../vendor/recovery"

# 2GB version
RECOVERY_IMAGE_2GB=$OUT/$RW_OUT_NAME"_GO.img"
[ -z "$BUILD_2GB_VERSION" ] && BUILD_2GB_VERSION=0 # by default, build only the full version
#

#
# Optional (new) environment variables - to be declared before building
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
  FOX_VENDOR_PATH=$(fullpath "$OUT/../../../../vendor/recovery")
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

  echo -e "${BLUE}-- Creating update.zip${NC}"
  FILES_DIR=$FOX_VENDOR_PATH/FoxFiles
  INST_DIR=$FOX_VENDOR_PATH/installer
  
  # did we export tmp directory for OrangeFox ports?
  [ -n "$FOX_PORTS_TMP" ] && WORK_DIR="$FOX_PORTS_TMP" || WORK_DIR="$FOX_VENDOR_PATH/tmp"

  # names of output zip file(s)
  ZIP_FILE=$OUT/$RW_OUT_NAME.zip
  ZIP_FILE_GO=$OUT/$RW_OUT_NAME"_GO.zip"
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

  # copy FoxFiles/ to sdcard/
  cp -a $FILES_DIR/ sdcard/Fox
  
  # any local changes to a port's installer directory? (eg, updater-script)
  if [ -n "$FOX_PORTS_INSTALLER" ] && [ -d "$FOX_PORTS_INSTALLER" ]; then
     cp -ar $FOX_PORTS_INSTALLER/* . 
  fi
  
  # patch updater-script to run only for the current device (change default to only mido)
  local F="$WORK_DIR/META-INF/com/google/android/updater-script"
  if [ "$RW_DEVICE" != "mido" ]; then
     sed -i -e "s/mido/$RW_DEVICE/g" $F     
  fi
  # embed the release version
  sed -i -e "s/RELEASE_VER/$RW_BUILD/" $F
  
  # create update zip
  ZIP_CMD="zip --exclude=*.git* -r9 $ZIP_FILE ."
  echo "- Running ZIP command: $ZIP_CMD"
  $ZIP_CMD
   
  #  sign zip installer
  if [ -f $ZIP_FILE ]; then
     ZIP_CMD="$FOX_VENDOR_PATH/signature/sign_zip.sh -z $ZIP_FILE"
     echo "- Running ZIP command: $ZIP_CMD"
     $ZIP_CMD
  fi

  # create update zip for "GO" version
  if [ "$BUILD_2GB_VERSION" = "1" ]; then
  	rm -f ./recovery.img
  	cp -a $RECOVERY_IMAGE_2GB ./recovery.img
  	ZIP_CMD="zip --exclude=*.git* --exclude=OrangeFox*.zip* -r9 $ZIP_FILE_GO ."
  	echo "- Running ZIP command: $ZIP_CMD"
  	$ZIP_CMD
  	#  sign zip installer ("GO" version)
  	if [ -f $ZIP_FILE_GO ]; then
     	   ZIP_CMD="$FOX_VENDOR_PATH/signature/sign_zip.sh -z $ZIP_FILE_GO"
     	   echo "- Running ZIP command: $ZIP_CMD"
     	   $ZIP_CMD
     	fi
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
if [ -d "$RW_WORK" ]; then
  echo -e "${BLUE}-- Working folder found in OUT. Cleaning up${NC}"
  rm -rf "$RW_WORK"
fi

# unpack recovery image into working directory
echo -e "${BLUE}-- Unpacking recovery image${NC}"
bash "$RW_VENDOR/tools/mkboot" "$OUT/recovery.img" "$RW_WORK" > /dev/null 2>&1

# copy stuff to the ramdisk
echo -e "${BLUE}-- Copying mkbootimg, unpackbootimg binaries to sbin${NC}"
case "$TARGET_ARCH" in
 "arm")
      echo -e "${GREEN}-- ARM arch detected. Copying ARM binaries${NC}"
      cp "$RW_VENDOR/prebuilt/arm/mkbootimg" "$RW_RAMDISK/sbin"
      cp "$RW_VENDOR/prebuilt/arm/unpackbootimg" "$RW_RAMDISK/sbin"
      ;;
 "arm64")
      echo -e "${GREEN}-- ARM64 arch detected. Copying ARM64 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/arm64/mkbootimg" "$RW_RAMDISK/sbin"
      cp "$RW_VENDOR/prebuilt/arm64/unpackbootimg" "$RW_RAMDISK/sbin"
      ;;
 "x86")
      echo -e "${GREEN}-- x86 arch detected. Copying x86 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/x86/mkbootimg" "$RW_RAMDISK/sbin"
      cp "$RW_VENDOR/prebuilt/x86/unpackbootimg" "$RW_RAMDISK/sbin"
      ;;
 "x86_64")
      echo -e "${GREEN}-- x86_64 arch detected. Copying x86_64 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/x86_64/mkbootimg" "$RW_RAMDISK/sbin"
      cp "$RW_VENDOR/prebuilt/x86_64/unpackbootimg" "$RW_RAMDISK/sbin"
      ;;
    *) echo -e "${RED}-- Couldn't detect current device architecture or it is not supported${NC}" ;;
esac

# build standard (3GB) version
DEBUG=0
  # copy over vendor FFiles/ and vendor sbin/ stuff before creating the boot image
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Copying: $FOX_VENDOR_PATH/FoxExtras/* to $RW_RAMDISK/"
  cp -ar $FOX_VENDOR_PATH/FoxExtras/* $RW_RAMDISK/
  
  # if a local callback script is declared, run it, passing to it the ramdisk directory
  if [ -n "$FOX_LOCAL_CALLBACK_SCRIPT" ] && [ -x "$FOX_LOCAL_CALLBACK_SCRIPT" ]; then
     $FOX_LOCAL_CALLBACK_SCRIPT "$RW_RAMDISK"
  fi
  #
  # repack
  echo -e "${BLUE}-- Repacking and copying recovery${NC}"
  [ "$DEBUG" = "1" ] && echo "- DEBUG: Running command: bash $RW_VENDOR/tools/mkboot $RW_WORK $RECOVERY_IMAGE ***"
  bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$RECOVERY_IMAGE" > /dev/null 2>&1
  cd "$OUT" && md5sum "$RECOVERY_IMAGE" > "$RECOVERY_IMAGE.md5" && cd - > /dev/null 2>&1
# end: standard version

#: build "GO" (2GB) version (virtually obsolete now) #
if [ "$BUILD_2GB_VERSION" = "1" ]; then
	echo -e "${BLUE}-- Repacking and copying the \"GO\" version of recovery${NC}"
	FFil="$RW_RAMDISK/FFiles"
	rm -rf $FFil/OF_initd
	rm -rf $FFil/AromaFM
	[ "$DEBUG" = "1" ] && echo "*** Running command: bash $RW_VENDOR/tools/mkboot $RW_WORK $RECOVERY_IMAGE_2GB ***"
	bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$RECOVERY_IMAGE_2GB" > /dev/null 2>&1
	cd "$OUT" && md5sum "$RECOVERY_IMAGE_2GB" > "$RECOVERY_IMAGE_2GB.md5" && cd - > /dev/null 2>&1
fi
# end: "GO" version

# create update zip installer
do_create_update_zip

echo -e "${RED}--------------------Finished building OrangeFox---------------------${NC}"
echo -e "${GREEN}Recovery image: $RECOVERY_IMAGE"
echo -e "          MD5: $RECOVERY_IMAGE.md5${NC}"
echo -e ""
echo -e "${GREEN}Recovery zip: $OUT/$RW_OUT_NAME.zip"
echo -e "${RED}==================================================================${NC}"

# end!
