#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}=====================================================================${NC}"
echo -e "${RED} ,-----.                                      ,------.               ${NC}"
echo -e "${RED}'  .-.  ',--.--. ,--,--.,--,--,  ,---.  ,---. |  .---',---.,--.  ,--.${NC}"
echo -e "${RED}|  | |  ||  .--'' ,-.  ||      \| .-. || .-. :|  `--,| .-. |\  `'  / ${NC}"
echo -e "${RED}'  '-'  '|  |   \ '-'  ||  ||  |' '-' '\   --.|  |`  ' '-' '/  /.  \ ${NC}"
echo -e "${RED} `-----' `--'    `--`--'`--''--'.`-  /  `----'`--'    `---''--'  '--'${NC}"
echo -e "${RED}                                `---'                                ${NC}"

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
bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$OUT/$RW_OUT_NAME.img" > /dev/null 2>&1
cd "$OUT" && md5sum "$RW_OUT_NAME.img" > "$RW_OUT_NAME.img.md5" && cd - > /dev/null 2>&1

echo -e "${RED}--------------------Finished making OrangeFox---------------------${NC}"
echo -e "${GREEN}RedWolf image: \${OUT}/$RW_OUT_NAME.img"
echo -e "          MD5: \${OUT}/$RW_OUT_NAME.img.md5${NC}"
echo -e "${RED}==================================================================${NC}"
