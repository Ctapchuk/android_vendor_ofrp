#!/system/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2023-2024 The OrangeFox Recovery Project
#
#	SPDX-License-Identifier: GPL-3.0-or-later
#

MSG() {
	echo "I: $@" >> /tmp/recovery.log;
	echo "$@";
}

enable_emulated_storage_props() {
	MSG "Enabling the emulate storage props. You can now format the data partition.";
	resetprop "external_storage.casefold.enabled" "1";
	resetprop "external_storage.projid.enabled" "1";
	resetprop "external_storage.sdcardfs.enabled" "0";
}

disable_emulated_storage_props() {
	MSG "Disabling emulate storage props. You can now format the data partition.";
	resetprop --delete "external_storage.casefold.enabled";
	resetprop --delete "external_storage.projid.enabled";
	resetprop --delete "external_storage.sdcardfs.enabled";
}

main() {
	MSG "Shell script for OrangeFox Recovery Project [$0]";
	MSG "Run this just before formatting the data partition, if you need to enable or disable emulated storage.";
	if [ "$1" = "on" ]; then
		enable_emulated_storage_props;
	elif [ "$1" = "off" ]; then
		disable_emulated_storage_props;
	else
		MSG "Syntax error";
		MSG "Syntax = $0 <'on'/'off'>";
	fi
}

## -- ##
main "$@";
exit 0;
## -- ##
