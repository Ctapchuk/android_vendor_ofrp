#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}================================================================${NC}"
echo -e "${RED}          @.                                         &@       ${NC}"
echo -e "${RED}         @@@@@(                                   &@@@@@      ${NC}"
echo -e "${RED}        @@@ (@@@@                               @@@@@ @@@     ${NC}"
echo -e "${RED}       @@@     @@@@#                          @@@@@@   @@%    ${NC}"
echo -e "${RED}      ,@@. @     @@@@#                      @@@@@@@* @  @@    ${NC}"
echo -e "${RED}      @@@ .@@      @@@@/(#%&&@@@@@@@@@@@%.@@@@@@@@@ @@  @@&   ${NC}"
echo -e "${RED}      @@   ,@@      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@  @@   ${NC}"
echo -e "${RED}     #@@    @@@                        @@@@@@@@@@*@@@@@  @@   ${NC}"
echo -e "${RED}     @@@    ,@@@                        %@@@@@@@@@@@@@@( @@*  ${NC}"
echo -e "${RED}     @@@   .@@@                          @@@@@@@@@@@@@@@ @@/  ${NC}"
echo -e "${RED}     @@@, @@@@                              @@@@@@@@@@@@%@@*  ${NC}"
echo -e "${RED}     %@@@@@@*         @@                 &@@@@@@@@@@@@@@@@@   ${NC}"
echo -e "${RED}     .@@@@@        @@@ #@@             @@, @@@@@@@@@@@@@@@@   ${NC}"
echo -e "${RED}      @@@@          ,@@/.@@@@@     @@@@@.#@@@@@@@@@@@@@@@@@   ${NC}"
echo -e "${RED}      /@@.            @@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@   ${NC}"
echo -e "${RED}     @@@%                              .%@@@@@@@@@@@@@@@@@@&  ${NC}"
echo -e "${RED}    .@@@        %            @@@@@@@   @@@@@@@@@@@@@@@@@@@@@  ${NC}"
echo -e "${RED}    @@@#        &           @#@@@@@/@  (@@@@@@@@@@@@@@@@@@@@@ ${NC}"
echo -e "${RED}   *@@@@@%       @   %   .  @@@@@@@@@%@@@@@@@@@@@@@@@@.@@@@@@.${NC}"
echo -e "${RED}   @@@@@@        @@ @   @@@@& %@@@@@@@@@@@@@@@@@@@@@@@ ,@@@@@@${NC}"
echo -e "${RED}   @@@@@@        %@@@  %@@@,@@@@@@@@@.@@@@@@@@@@@@@@@@  @@@@ %${NC}"
echo -e "${RED}    ,@@@@         @@@  @@@@          *@@@@@@@@@@@@@@@/  @@@@  ${NC}"
echo -e "${RED}    %@@@@@         @@@/  @@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@  ${NC}"
echo -e "${RED}    @@@@@@@@        @@@@  @@@ #@@@( @@@@@@@@@@@@@@@@   @@@@@( ${NC}"
echo -e "${RED}     *@@@@@@@@@       @@@%  @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@  ${NC}"
echo -e "${RED}        @@@@@@@@@      .@@@@     ,,,,@@@@@@@@@@@@@. .@@@@@@   ${NC}"
echo -e "${RED}          @@@@@@@@@      /@@@@@  ,&@@@@@@@@@@@@@@, @@@@@@@    ${NC}"
echo -e "${RED}            &@@@@@@@@       @@@@@@@@@  @@@@@@@@@  @@@@@@#     ${NC}"
echo -e "${RED}              @@@@@@@@&               @@@@@@@@@ &@@@@@@       ${NC}"
echo -e "${RED}                @@@@@@@@             (@@@@@@@@ @@@@@@@        ${NC}"
echo -e "${RED}                 /@@@@@@@@          ,@@@@@@@@@@@@@@@.         ${NC}"
echo -e "${RED}                   @@@@@@@@%       (@@@@@@@@@@@@@@&           ${NC}"
echo -e "${RED}                    &@@@@@@@@     %@@@@@@@@@@@@@@             ${NC}"
echo -e "${RED}                      @@@@@@@@/  @@@@@@@@@@@@@@               ${NC}"
echo -e "${RED}                       @@@@@@@@@@@@@@@@@@@@@@                 ${NC}"
echo -e "${RED}                        @@@@@@@@@@@@@@@@@@&                   ${NC}"
echo -e "${RED}                         &@@@@@@@@@@@@@@.                     ${NC}"
echo -e "${RED}                          &@@@@@@@@@@/                        ${NC}"
echo -e "${RED}                           &@@@@@@*                           ${NC}"


echo -e "${RED}-------------------------Making RedWolf-------------------------${NC}"

echo -e "${BLUE}-- Setting up Environment Variables${NC}"
if [ -z "$TW_DEVICE_VERSION" ]; then
RW_BUILD=Unofficial
else
RW_BUILD=$TW_DEVICE_VERSION
fi
RW_VENDOR=vendor/redwolf
RW_WORK=$OUT/RW_AIK
RW_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)

RW_OUT_NAME=RedWolf-$RW_BUILD-$RW_DEVICE

if [ -d "$RW_WORK" ]; then
  echo -e "${BLUE}-- Working Folder Found in OUT. Removing it.${NC}"
  rm -rf "$RW_WORK"
fi

echo -e "${BLUE}-- Unpacking Recovery${NC}"
bash "$RW_VENDOR/tools/mkboot" "$OUT/recovery.img" "$RW_WORK" > /dev/null 2>&1

echo -e "${BLUE}-- Repacking and Copying Recovery${NC}"
bash "$RW_VENDOR/tools/mkboot" "$RW_WORK" "$OUT/$RW_OUT_NAME.img" > /dev/null 2>&1
cd "$OUT" && md5sum "$RW_OUT_NAME.img" > "$RW_OUT_NAME.img.md5" && cd - > /dev/null 2>&1

echo -e "${RED}--------------------Finished Making RedWolf---------------------${NC}"
echo -e "${GREEN}RedWolf Image : \${OUT}/$RW_OUT_NAME.img"
echo -e "          MD5 : \${OUT}/$RW_OUT_NAME.img.md5${NC}"
echo -e "${RED}================================================================${NC}"
