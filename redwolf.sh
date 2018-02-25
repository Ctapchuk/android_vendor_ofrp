#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}-------------------------Making RedWolf-------------------------${NC}"

echo -e "${BLUE}-- Setting up Environment Variables${NC}"
if [ -z "$TW_DEVICE_VERSION" ]; then
RW_BUILD=Unofficial
else
RW_BUILD=$TW_DEVICE_VERSION
fi
RW_VENDOR=vendor/redwolf
RW_WORK=$OUT/RW_AIK
RW_2GB=$OUT/RW_2GB
RW_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

RW_OUT_NAME=RedWolf-$RW_BUILD-$RW_DEVICE

if [ -d "$RW_WORK" ]; then
  echo -e "${BLUE}-- Working Folder Found in OUT. Removing it.${NC}"
  rm -rf "$RW_WORK"
fi

echo -e "${BLUE}-- Unpacking Recovery${NC}"
bash "$RW_VENDOR/tools/mkboot" "$OUT/recovery.img" "$RW_WORK" > /dev/null 2>&1

echo -e "${BLUE}-- Including WolfShit${NC}"
cp -R "$RW_VENDOR/prebuilt/WolfShit" "$RW_WORK/ramdisk/WolfShit"

echo -e "${BLUE}-- Repacking and Copying Recovery${NC}"
bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$OUT/$RW_OUT_NAME.img" > /dev/null 2>&1
cd "$OUT" && md5sum "$RW_OUT_NAME.img" > "$RW_OUT_NAME.img.md5" && cd - > /dev/null 2>&1

if [ "$DEVICE_HAS_2GB_VARIANT" = "true" ]; then
  echo -e "${GREEN}-- 2GB Variant Found${NC}"
  rm -rf "$RW_2GB"
  mkdir "$RW_2GB"
  echo -e "${BLUE}-- Copying Files${NC}"
  mkdir -p "$RW_2GB/META-INF/com/google/android"
  cp "$RW_VENDOR/prebuilt/update-binary" "$RW_2GB/META-INF/com/google/android"
  cp -R "$RW_VENDOR/prebuilt/WolfShit" "$RW_2GB/tools"
  cp "$OUT/recovery.img" "$RW_2GB/tools"
  sed -i -- "s/devicenamehere/${RW_DEVICE}/g" "$RW_2GB/META-INF/com/google/android/update-binary"
  echo -e "${BLUE}-- Compressing Files to ZIP${NC}"
  cd "$RW_2GB" && zip -r "$OUT/$RW_OUT_NAME-2GB_RAM.zip" ./* > /dev/null 2>&1 && cd - > /dev/null 2>&1
  cd "$OUT" && md5sum "$RW_OUT_NAME-2GB_RAM.zip" > "$RW_OUT_NAME-2GB_RAM.zip.md5" && cd - > /dev/null 2>&1
fi

echo -e "${RED}--------------------Finished Making RedWolf---------------------${NC}"
echo -e "${GREEN}RedWolf Image : \${OUT}/$RW_OUT_NAME.img"
echo -e "          MD5 : \${OUT}/$RW_OUT_NAME.img.md5${NC}"
if [ "$DEVICE_HAS_2GB_VARIANT" = "true" ]; then
echo -e "${GREEN}  RedWolf ZIP : \${OUT}/$RW_OUT_NAME-2GB_RAM.zip"
echo -e "          MD5 : \${OUT}/$RW_OUT_NAME-2GB_RAM.zip.md5${NC}"
fi
echo -e "${RED}----------------------------------------------------------------${NC}"
