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
echo -e "${RED}----------------------------Making OrangeFox-------------------------${NC}"

echo -e "${BLUE}-- Setting up environment variables${NC}"
if [ -z "$TW_DEVICE_VERSION" ]; then
RW_BUILD=Unofficial
else
RW_BUILD=$TW_DEVICE_VERSION
fi
RW_VENDOR=vendor/redwolf
RW_WORK=$OUT/RW_AIK
RW_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

RW_OUT_NAME=OrangeFox-$RW_BUILD-$RW_DEVICE

RECOVERY_IMAGE="$OUT/$RW_OUT_NAME.img"

# create an update zip for deployment
do_create_update_zip() {
  FOX_DIR=$OUT/../../../../vendor/redwolf
  FILES_DIR=$FOX_DIR/FoxFiles
  INST_DIR=$FOX_DIR/installer
  WORK_DIR=$FOX_DIR/tmp
  ZIP_FILE=$OUT/$RW_OUT_NAME.zip
  
  echo "- Creating $ZIP_FILE for deployment ..."
  
  # clean any existing files
  rm -rf $WORK_DIR

  # recreate dir
  mkdir -p $WORK_DIR
  cd $WORK_DIR

  # copy recovery image
  cp -a $RECOVERY_IMAGE ./recovery.img
   
  # copy installer bins and script and sdcard/
  cp -ar $INST_DIR/* .
  
  # copy foxfiles
  cp -a $FILES_DIR/ sdcard/Fox
  
  # create zip
  zip -r9 $ZIP_FILE .
}

if [ -d "$RW_WORK" ]; then
  echo -e "${BLUE}-- Working folder found in OUT. Cleaning up${NC}"
  rm -rf "$RW_WORK"
fi

echo -e "${BLUE}-- Unpacking recovery image${NC}"
bash "$RW_VENDOR/tools/mkboot" "$OUT/recovery.img" "$RW_WORK" > /dev/null 2>&1

echo -e "${BLUE}-- Copying mkbootimg, unpackbootimg binaries to sbin${NC}"
case "$TARGET_ARCH" in
 "arm")
      echo -e "${GREEN}-- ARM arch detected. Copying ARM binaries${NC}"
      cp "$RW_VENDOR/prebuilt/arm/mkbootimg" "$RW_WORK/ramdisk/sbin"
      cp "$RW_VENDOR/prebuilt/arm/unpackbootimg" "$RW_WORK/ramdisk/sbin"
      ;;
 "arm64")
      echo -e "${GREEN}-- ARM64 arch detected. Copying ARM64 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/arm64/mkbootimg" "$RW_WORK/ramdisk/sbin"
      cp "$RW_VENDOR/prebuilt/arm64/unpackbootimg" "$RW_WORK/ramdisk/sbin"
      ;;
 "x86")
      echo -e "${GREEN}-- x86 arch detected. Copying x86 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/x86/mkbootimg" "$RW_WORK/ramdisk/sbin"
      cp "$RW_VENDOR/prebuilt/x86/unpackbootimg" "$RW_WORK/ramdisk/sbin"
      ;;
 "x86_64")
      echo -e "${GREEN}-- x86_64 arch detected. Copying x86_64 binaries${NC}"
      cp "$RW_VENDOR/prebuilt/x86_64/mkbootimg" "$RW_WORK/ramdisk/sbin"
      cp "$RW_VENDOR/prebuilt/x86_64/unpackbootimg" "$RW_WORK/ramdisk/sbin"
      ;;
    *) echo -e "${RED}-- Couldn't detect current device architecture or it is not supported${NC}" ;;
esac

echo -e "${BLUE}-- Repacking and copying recovery${NC}"
bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$RECOVERY_IMAGE" > /dev/null 2>&1
cd "$OUT" && md5sum "$RECOVERY_IMAGE" > "$RECOVERY_IMAGE.md5" && cd - > /dev/null 2>&1

echo -e "${RED}--------------------Finished making OrangeFox---------------------${NC}"
echo -e "${GREEN}Recovery image: $RECOVERY_IMAGE"
echo -e "          MD5: $RECOVERY_IMAGE.md5${NC}"
echo -e ""
echo -e "${GREEN}Recovery zip: $OUT/$RW_OUT_NAME.zip"

echo -e "${RED}==================================================================${NC}"

# create update zip
do_create_update_zip
