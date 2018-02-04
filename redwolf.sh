#!/bin/bash

echo "-----------------Making RedWolf-----------------"

echo "-- Setting up Environment Variables"
RW_BUILD=025 #Set RedWolf Version
RW_VENDOR=vendor/redwolf
RW_WORK=$OUT/RW_AIK
RW_2GB=$OUT/RW_2GB
BUILD_DATE=$(date +"%Y%m%d")
RW_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

if [ -z "$RW_TYPE" ]; then # Set Build Type in Device Tree
  RW_TYPE="UNOFFICIAL"
fi

RW_OUT_NAME=RedWolf-$RW_BUILD-$RW_DEVICE-$BUILD_DATE-$RW_TYPE

if [ -d "$RW_WORK" ]; then
  echo "-- AIK Found in OUT"
  rm "$RW_WORK/recovery.img"
  bash "$RW_WORK/cleanup.sh" > /dev/null 2>&1
else
  echo "-- Copying AIK to OUT"
  cp -R "$RW_VENDOR/AIK" "$RW_WORK"
fi

cp "$OUT/recovery.img" "$RW_WORK"

echo "-- Unpacking Recovery"
bash "$RW_WORK/unpackimg.sh" "--nosudo" "$RW_WORK/recovery.img" > /dev/null 2>&1

echo "-- Including WolfShit"
cp -R "$RW_VENDOR/prebuilt/WolfShit" "$RW_WORK/ramdisk/WolfShit"

echo "-- Repacking and Copying Recovery"
bash "$RW_WORK/repackimg.sh" > /dev/null 2>&1
cp "$RW_WORK/image-new.img" "$OUT/$RW_OUT_NAME.img"

if [ "$DEVICE_HAS_2GB_VARIANT" = true ] ; then
  echo '-- 2GB Variant Found'
  rm -rf "$RW_2GB"
  mkdir "$RW_2GB"
  echo '-- Copying Files'
  mkdir -p "$RW_2GB/META-INF/com/google/android"
  cp "$RW_VENDOR/prebuilt/update-binary" "$RW_2GB/META-INF/com/google/android"
  cp -R "$RW_VENDOR/prebuilt/WolfShit" "$RW_2GB/tools"
  cp "$OUT/recovery.img" "$RW_2GB/tools"
  echo '-- Compressing Files to ZIP'
  cd "$RW_2GB" && zip -r "$OUT/$RW_OUT_NAME-2GB_VARIANT.zip" ./* > /dev/null 2>&1 && cd -
fi

echo "------------Finished Making RedWolf-------------"
