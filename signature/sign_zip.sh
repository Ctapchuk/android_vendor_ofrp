#!/bin/bash
# --------------------------------------------------------------------
# Bash Script to sign zip or apk files, using "signapk" stuff
# Note: this script requires bash
# --------------------------------------------------------------------

abort() {
  echo "$@"
  exit 1
}

Syntax() {
 echo "Syntax = $0 <switch> <zip file>"
 echo "  Switches:"
 echo "          -z = sign an existing zip installer file"
 echo "  Examples: "
 echo "          $0 -z myapp.zip"
 exit
}

# begin processing
zipfile=""
zipbase=""
echo "- Signing $2 ..."

# try to locate the signature support files
HERE=$PWD
WORK_DIR="${BASH_SOURCE%/*}"
[ "$WORK_DIR" = "." ] && WORK_DIR=$PWD || {
  cd $WORK_DIR
  WORK_DIR=$PWD
  cd $HERE
}

j1_jar=$WORK_DIR/signapk.jar
j2_jar=$WORK_DIR/minsignapk.jar
PEM=$WORK_DIR/certificate.pem
KEY=$WORK_DIR/key.pk8

# look for support files
[ ! -e $j1_jar ] || [ ! -e $j2_jar ] || [ ! -e $PEM ] || [ ! -e $KEY ] && {
   WORK_DIR=~/Android/bin
   j1_jar=$WORK_DIR/signapk.jar
   j2_jar=$WORK_DIR/minsignapk.jar
   PEM=$WORK_DIR/certificate.pem
   KEY=$WORK_DIR/key.pk8
}

[ ! -e $j1_jar ] || [ ! -e $j2_jar ] || [ ! -e $PEM ] || [ ! -e $KEY ] && {
   abort "Error. Missing jar and/or certificate files! Quitting ..."
}

##
processzip() {
  [ -z "$1" ] && abort "Syntax = $0 -z <zip_file>"
  [ ! -f $1 ] && abort "Error: \"$1\" file not found"
  zipbase=$(basename -s .zip $1)  # strip the .zip extension
  java -jar $j1_jar $PEM $KEY $1 "$zipbase"_tmp1
  #echo "Adjust programe = $WORK_DIR/zipadjust "$zipbase"_tmp1 "$zipbase"_fixed"
  $WORK_DIR/zipadjust "$zipbase"_tmp1 "$zipbase"_fixed
  java -jar $j2_jar $PEM $KEY "$zipbase"_fixed "$zipbase"-signed.zip 
  rm -f "$zipbase"_tmp1 "$zipbase"_fixed
  rm -f "$zipbase"-unsigned.zip
  
  # rename original zip to "...unsigned"
  mv -f $1 "$zipbase"-unsigned.zip
  
  # rename signed zip file original zip
  mv -f "$zipbase"-signed.zip $1
}

# "-z" or "-f" = sign existing zip installer # 
if [ "$1" = "-z" ] || [ "$1" = "-f" ]; then
   processzip $2
   exit 0
else  
   Syntax
fi

