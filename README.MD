# Renegade Bulletin Board System
Copyright (c) 1991-2022 The Renegade Development Team ─ Cott Lang, Patrick Spence, Gary Hall, Jeff Herrings, T.J. McMillen, Chris Hoppman, Lee Palmer, and Lee Woodridge.
#
  * Added datesuffix, timestamp in timefunc.pas
  * Timestamps for user log entries
  * Added language strings for public message list header, user not found, user search ask prompt, quote header
  * Fix for input lengths for negative numbers
  * Changed/added inputflags
  * Removed all input procs without changed check
  * Removed all redundant input procs and changed all calls
  * Removed all redundant MPL calls
  * Combined lOneK and OneK1, now InputChar
  * Added language strings for UpdateUserInfo proc, force_batch_ul, force_batch_dl, add quote prompt
  * added a bunch of hangup checks to prevent leftover jibberish after disconnect
  * redo most cuser procs
  * redo updateuserinfo maint
  * added more fields you can clear to user editor
  * redo newuser question toggles menu
  * converted all onek to lonek
  * converted all getpassword calls to inputmain with ispassword param
  * removed redundant input procs - inputwc,inputcaps,inputl,input,local_onek
  * moving input procs to COMMON3
  * *T menu cmd to toggle sysop chat availability
  * %SA display sysop chat availability
  * combined all language strings to rglng
  * nesting code that doesn't get called elsewhere
  * bugfix yes/no lightbar to prevent it from eating itself
  * removed extra linefeeds above generic menu titles
  * text/lang files to /text/ subdir
  * new user app won't prompt for color scheme if color disabled, or only 1 scheme
  * new user app now uses MaxLogonTries as number of question answer attempts before giving up
  * more verbose startup
  * added ErrorCodeHelp func for more helpful error messages
  * Implemented CoSysOp max mail waiting configuration option
  * a bunch of work on chat, see chat.pas for more info
  * INT moved clear_eol + ansig to COMMON
  * INT OneLiners tolower func moved to common
  * OneLiners filenames now ONELH ONELM ONELT
  * OneLiner strings in RGLNG
  * OneLiners see anonymous posters name now anonpubread ACS instead of SysOp
  * Teleconf strings in lang file instead of node config menu
  * Removed syscfg and and fileareaeditor strings from lang
  * Removed MCIs that were added for sysconfig/fae
  * Added yes/no lightbar
  * Automessage strings in lang
  * Modem/node config can scroll through nodes to configure without reloading for each node
  * Added descriptions for caret color codes
  * Added seperate sysop macros submenu, removed from sys variables menu
  * INT More intuitive user flag names
  * Message area color codes for netmail can be configured with all foreground colors instead of just caret codes
  * Disabled ForgotPW question for CoSysOp+
  * Logon won't prompt for SysOp PW if blank
  * INT Redid most newuserapp/config questions
  * Removed CallerID/IP in SysOp note option since it has its own field
  * %DE bug fixed
  * Added Q ACS check for menu #
  * Fixed dupe description on copy fail bug
  * Fixed mass upload bug
