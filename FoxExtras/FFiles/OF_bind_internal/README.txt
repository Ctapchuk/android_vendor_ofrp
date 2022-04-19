README for OF_bind_internal.zip

*************
DISCLAIMERS:
*************

1. The "OF_bind_internal.zip" is experimental, and is supplied WITHOUT ANY WARRANTIES 
   WHATSOEVER. 

2. If you flash the OF_bind_internal.zip file, you do so ENTIRELY AT YOUR OWN RISK.

3. The OrangeFox Recovery Project and its members and developers disclaim all 
   liability for any loss or damage, resulting directly or indirectly, from the use,
   or the purported use, of the OF_bind_internal.zip or its derivatives, for any 
   purpose whatsosever.

4. If these terms (or any of them) are not acceptable to you, then you have no 
   license to use the OF_bind_internal.zip file. Do NOT EVER flash it.


***********
QUESTIONS:
***********

Q. *What does this flashable zip do?*
A. It will try to force a bind-mount of /data/media/0 to /sdcard/

Q. *Why would I want to flash this zip?*
A. In most cases, you would *NOT* want to flash it. It may however be useful if
   the recovery CANNOT DECRYPT your device, *AND* you are *REALLY* desperate to
   have access to your internal storage in recovery mode.

Q. *If I want to flash it, when must I do so?*
A. You should only flash this *immediately* after formatting the data partition.

Q. *Is it guaranteed to produce the desired effect?*
A. No. On some devices/ROMs, it will work as intended. On some other devices
   its work will simply be undone when you reboot to system. On some other 
   devices, encryption will be broken, meaning that general decryption will 
   fail. You can only know for sure by trial and error.

Q. *What are the consequences of flashing this zip?*
A. If it works, then it should leave the internal storage *unencrypted*, and 
   therefore accessible in recovery, even if decryption of /data fails.
   
   Note: this may produce some side effects on encryption. Use with caution!
   So, do *NOT* flash this zip unless you are prepared to format your data
   partition to get rid of its effect.

Q. *How do I reverse the effect of flashing this zip?*
A. The *only* way to reverse its effect is to format the data partition.


***********
CONCLUSION:
***********
If you flash this zip, and it works as intended, then the internal storage 
will NOT be encrypted. 

--------------------------------------
So, you should only flash this zip if:
-------------------------------------
1. You know what you are doing, and
2. The recovery cannot decrypt your device, and
3. You do not mind your internal storage being freely accessible to the recovery, and
4. You are prepared to format your data partition if things are not how you want them.

