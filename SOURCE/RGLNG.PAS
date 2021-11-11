{
Lee Woodridge
 09/23/2021 - Removed system config strings
            - Removed file area editor strings
 10/01/2021 - Added Lightbar "Yes"(96) & "No"(97) strings to LNG
 10/02/2021 - Added "Aborted"(44) & "Saved"(45) strings to NOTE
            - Added Auto Message strings (98-104) to LNG
 10/12/2021 - Added Teleconf Normal(11),Anonymous(12),Global(13),Private(14) to MAIN
 11/01/2021 - All string files combined into 1
            - #193 unused -- replace with something
              #179 left blank so easier to convert -- add something here
            - Too many nested IF, ELSE IF statements causing internal stack overflow 
                - temp fixed by starting over after each section but
                  should consider changing to CASE, if that'll fix it -- have to look into this
}
PROGRAM RGLNG;

USES
  CRT,
  DOS;

TYPE
  StrPointerRec = RECORD
    Pointer,
    TextSize: LongInt;
  END;

VAR
  RGStrFile: FILE;
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  F: Text;
  S: STRING;
  RGStrNum: LongInt;
  Done,
  Found: Boolean;

FUNCTION AllCaps(S: STRING): STRING;
VAR
  I: Integer;
BEGIN
  FOR I := 1 TO Length(S) DO
    IF (S[I] IN ['a'..'z']) THEN
      S[I] := Chr(Ord(S[I]) - Ord('a')+Ord('A'));
  AllCaps := S;
END;

FUNCTION SQOutSp(S: STRING): STRING;
BEGIN
  WHILE (Pos(' ',S) > 0) DO
    Delete(s,Pos(' ',S),1);
  SQOutSp := S;
END;

FUNCTION Exist(FN: STRING): Boolean;
VAR
  DirInfo: SearchRec;
BEGIN
  FindFirst(SQOutSp(FN),AnyFile,DirInfo);
  Exist := (DOSError = 0);
END;

BEGIN
  ClrScr;
  WriteLn('Renegade Language String Compiler - Version 3.6');
  Writeln('Copyright (c) 2021 The Renegade Developement Team');
  IF (NOT Exist('RGLNG.TXT')) THEN
    BEGIN
      WriteLn;
      WriteLn(^G^G^G'RGLNG.TXT does not exist!');
      Exit;
    END
  ELSE
    BEGIN
      WriteLn;
      Write('Compiling language strings ... ');
      Found := TRUE;
      Assign(StrPointerFile,'RGLNGPR.DAT');
      ReWrite(StrPointerFile);
      Assign(RGStrFile,'RGLNGTX.DAT');
      ReWrite(RGStrFile,1);
      Assign(F,'RGLNG.TXT');
      Reset(F);
      WHILE NOT EOF(F) AND (Found) DO
        BEGIN
          ReadLn(F,S);
          IF (S <> '') AND (S[1] = '$') THEN
            BEGIN
              Delete(S,1,1);
              S := AllCaps(S);
              RGStrNum := -1;
              IF (S = 'ANONYMOUS_STRING') THEN
                RGStrNum := 0
              ELSE IF (S = 'ECHO_CHAR_FOR_PASSWORDS') THEN
                RGStrNum := 1
              ELSE IF (S = 'ENGAGE_CHAT') THEN
                RGStrNum := 2
              ELSE IF (S = 'END_CHAT') THEN
                RGStrNum := 3
              ELSE IF (S = 'SYSOP_WORKING') THEN
                RGStrNum := 4
              ELSE IF (S = 'PAUSE') THEN
                RGStrNum := 5
              ELSE IF (S = 'ENTER_MESSAGE_LINE_ONE') THEN
                RGStrNum := 6
              ELSE IF (S = 'ENTER_MESSAGE_LINE_TWO') THEN
                RGStrNum := 7
              ELSE IF (S = 'NEWSCAN_BEGIN') THEN {msg}
                RGStrNum := 8
              ELSE IF (S = 'NEWSCAN_DONE') THEN
                RGStrNum := 9
              ELSE IF (S = 'AUTO_MESSAGE_TITLE') THEN
                RGStrNum := 10
              ELSE IF (S = 'AUTO_MESSAGE_BORDER_CHARACTERS') THEN
                RGStrNum := 11
              ELSE IF (S = 'SYSOP_SHELLING_TO_DOS') THEN
                RGStrNum := 12
              ELSE IF (S = 'READ_MAIL') THEN
                RGStrNum := 13
              ELSE IF (S = 'PAGING_SYSOP') THEN
                RGStrNum := 14
              ELSE IF (S = 'CHAT_CALL') THEN
                RGStrNum := 15
              ELSE IF (S = 'BULLETIN_PROMPT') THEN
                RGstrNum := 16
              ELSE IF (S = 'PROTOCOL_PROMPT') THEN
                RGStrNum := 17
              ELSE IF (S = 'LIST_FILES') THEN
                RGStrNum := 18
              ELSE IF (S = 'SEARCH_FOR_NEW_FILES') THEN
                RGStrNum := 19
              ELSE IF (S = 'SEARCH_ALL_DIRS_FOR_FILE_MASK') THEN
                RGStrNum := 20
              ELSE IF (S = 'SEARCH_FOR_DESCRIPTIONS') THEN
                RGStrNum := 21
              ELSE IF (S = 'ENTER_THE_STRING_TO_SEARCH_FOR') THEN
                RGStrNum := 22
              ELSE IF (S = 'DOWNLOAD') THEN
                RGStrNum := 23
              ELSE IF (S = 'UPLOAD') THEN
                RGStrNum := 24
              ELSE IF (S = 'VIEW_INTERIOR_FILES') THEN
                RGStrNum := 25
              ELSE IF (S = 'INSUFFICIENT_FILE_CREDITS') THEN
                RGStrNum := 26
              ELSE IF (S = 'RATIO_IS_UNBALANCED') THEN
                RGStrNum := 27
              ELSE IF (S = 'ALL_FILES') THEN
                RGStrNum := 28
              ELSE IF (S = 'FILE_MASK') THEN
                RGStrNum := 29
              ELSE IF (S = 'FILE_ADDED_TO_BATCH_QUEUE') THEN
                RGStrNum := 30
              ELSE IF (S = 'BATCH_DOWNLOAD_FLAGGING') THEN
                RGStrNum := 31
              ELSE IF (S = 'READ_QUESTION_PROMPT') THEN
                RGStrNum := 32
              ELSE IF (S = 'SYSTEM_PASSWORD_PROMPT') THEN
                RGStrNum := 33
              ELSE IF (S = 'DEFAULT_MESSAGE_TO') THEN
                RGStrNum := 34
              ELSE IF (S = 'NEWSCAN_GLOBAL_BEGIN') THEN
                RGStrNum := 35
              ELSE IF (S = 'NEWSCAN_GLOBAL_COMPLETE') THEN
                RGStrNum := 36
              ELSE IF (S = 'CHAT_REASON') THEN
                RGStrNum := 37
              ELSE IF (S = 'USER_DEFINED_QUESTION_ONE') THEN
                RGStrNum := 38
              ELSE IF (S = 'USER_DEFINED_QUESTION_TWO') THEN
                RGStrNum := 39
              ELSE IF (S = 'USER_DEFINED_QUESTION_THREE') THEN
                RGStrNum := 40
              ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_ONE') THEN
                RGStrNum := 41
              ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_TWO') THEN
                RGStrNum := 42
              ELSE IF (S = 'USER_DEFINED_QUESTION_EDITOR_THREE') THEN
                RGStrNum := 43
              ELSE IF (S = 'CONTINUE_PROMPT') THEN
                RGStrNum := 44
              ELSE IF (S = 'INVISIBLE_LOGIN') THEN
                RGStrNum := 45
              ELSE IF (S = 'CANT_EMAIL') THEN
                RGStrNum := 46
              ELSE IF (S = 'SEND_EMAIL') THEN
                RGStrNum := 47
              ELSE IF (S = 'SENDING_MASS_MAIL_TO') THEN
                RGStrNum := 48
              ELSE IF (S = 'SENDING_MASS_MAIL_TO_ALL_USERS') THEN
                RGStrNum := 49
              ELSE IF (S = 'NO_NETMAIL') THEN
                RGStrNum := 50
              ELSE IF (S = 'NETMAIL_PROMPT') THEN
                RGStrNum := 51
              ELSE IF (S = 'NO_MAIL_WAITING') THEN
                RGStrNum := 52
              ELSE IF (S = 'MUST_READ_MESSAGE') THEN
                RGStrNum := 53
              ELSE IF (S = 'SCAN_FOR_NEW_FILES') THEN
                RGStrNum := 54
              ELSE IF (S = 'NEW_SCAN_CHAR_FILE') THEN
                RGStrNum := 55
              ELSE IF (S = 'BULLETINS_PROMPT') THEN
                RGStrNum := 56
              ELSE IF (S = 'QUICK_LOGON') THEN
                RGStrNum := 57
              ELSE IF (S = 'MESSAGE_AREA_SELECT_HEADER') THEN
                RGStrNum := 58
              ELSE IF (S = 'FILE_AREA_SELECT_HEADER') THEN
                RGStrNum := 59
              ELSE IF (S = 'RECEIVE_EMAIL_HEADER') THEN
                RGStrNum := 60
              ELSE IF (S = 'VOTE_LIST_TOPICS_HEADER') THEN
                RGStrNum := 61
              ELSE IF (S = 'VOTE_TOPIC_RESULT_HEADER') THEN
                RGStrNum := 62
              ELSE IF (S = 'FILE_AREA_NAME_HEADER_NO_RATIO') THEN
                RGStrNum := 63
              ELSE IF (S = 'FILE_AREA_NAME_HEADER_RATIO') THEN
                RGStrNum := 64
              ELSE IF (S = 'SYSOP_CHAT_HELP') THEN
                RGStrNum := 65
              ELSE IF (S = 'NEW_SCAN_CHAR_MESSAGE') THEN
                RGStrNum := 66
              ELSE IF (S = 'FILE_AREA_SELECT_NO_FILES') THEN
                RGStrNum := 67
              ELSE IF (S = 'MESSAGE_AREA_SELECT_NO_FILES') THEN
                RGStrNum := 68
              ELSE IF (S = 'MESSAGE_AREA_LIST_PROMPT') THEN
                RGStrNum := 69
              ELSE IF (S = 'FILE_AREA_LIST_PROMPT') THEN
                RGStrNum := 70
              ELSE IF (S = 'FILE_MESSAGE_AREA_LIST_HELP') THEN
                RGStrNum := 71
              ELSE IF (S = 'FILE_AREA_CHANGE_PROMPT') THEN
                RGStrNum := 72
              ELSE IF (S = 'MESSAGE_AREA_CHANGE_PROMPT') THEN
                RGStrNum := 73
              ELSE IF (S = 'FILE_AREA_NEW_SCAN_TOGGLE_PROMPT') THEN
                RGStrNum := 74
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_TOGGLE_PROMPT') THEN
                RGStrNum := 75
              ELSE IF (S = 'FILE_AREA_MOVE_FILE_PROMPT') THEN
                RGStrNum := 76
              ELSE IF (S = 'MESSAGE_AREA_MOVE_MESSAGE_PROMPT') THEN
                RGStrNum := 77
              ELSE IF (S = 'FILE_AREA_CHANGE_MIN_MAX_ERROR') THEN
                RGStrNum := 78
              ELSE IF (S = 'MESSAGE_AREA_CHANGE_MIN_MAX_ERROR') THEN
                RGStrNum := 79
              ELSE IF (S = 'FILE_AREA_CHANGE_NO_AREA_ACCESS') THEN
                RGStrNum := 80
              ELSE IF (S = 'MESSAGE_AREA_CHANGE_NO_AREA_ACCESS') THEN
                RGStrNum := 81
              ELSE IF (S = 'FILE_AREA_CHANGE_LOWEST_AREA') THEN
                RGStrNum := 82
              ELSE IF (S = 'FILE_AREA_CHANGE_HIGHEST_AREA') THEN
                RGStrNum := 83
              ELSE IF (S = 'MESSAGE_AREA_CHANGE_LOWEST_AREA') THEN
                RGStrNum := 84
              ELSE IF (S = 'MESSAGE_AREA_CHANGE_HIGHEST_AREA') THEN
                RGStrNum := 85
              ELSE IF (S = 'FILE_AREA_NEW_SCAN_SCANNING_ALL_AREAS') THEN
                RGStrNum := 86
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_SCANNING_ALL_AREAS') THEN
                RGStrNum := 87
              ELSE IF (S = 'FILE_AREA_NEW_SCAN_NOT_SCANNING_ALL_AREAS') THEN
                RGStrNum := 88
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_NOT_SCANNING_ALL_AREAS') THEN
                RGStrNum := 89
              ELSE IF (S = 'FILE_AREA_NEW_SCAN_MIN_MAX_ERROR') THEN
                RGStrNum := 90
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_MIN_MAX_ERROR') THEN
                RGStrNum := 91
              ELSE IF (S = 'FILE_AREA_NEW_SCAN_AREA_ON_OFF') THEN
                RGStrNum := 92
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_AREA_ON_OFF') THEN
                RGStrNum := 93
              ELSE IF (S = 'MESSAGE_AREA_NEW_SCAN_AREA_NOT_REMOVED') THEN
                RGStrNum := 94
              ELSE IF (S = 'NEW_FILE_SCANNING') THEN
                RGStrNum := 95
              ELSE IF (S = 'LIGHTBAR_YES') THEN
                RgStrNum := 96
              ELSE IF (S = 'LIGHTBAR_NO') THEN
                RgStrNum := 97
              ELSE IF (S = 'NO_AUTO_MESSAGE') THEN
                RgStrNum := 98
              ELSE IF (S = 'POSTED_ANONYMOUSLY') THEN
                RgStrNum := 99
              ELSE IF (S = 'AUTO_MESSAGE_RESTRICTED') THEN
                RgStrNum := 100
              ELSE IF (S = 'POST_ANONYMOUSLY?') THEN
                RgStrNum := 101
              ELSE IF (S = 'NO_AUTO_MESSAGE_REPLY') THEN
                RgStrNum := 102
              ELSE IF (S = 'CANT_REPLY_ANONYMOUS') THEN
                RgStrNum := 103
              ELSE IF (S = 'AUTO_MESSAGE_HEADER') THEN
                RgStrNum := 104
              ELSE IF (S = 'ENTER_ONELINER') THEN
                RgStrNum := 105
              ELSE IF (S = 'ADD_ONELINER') THEN
                RgStrNum := 106
              ELSE IF (S = 'ADD_ONELINER_CONFIRM') THEN
                RgStrNum := 107
              ELSE IF (S = 'ONELINER_HEADER') THEN
                RgStrNum := 108
              ELSE IF (S = 'NO_ONELINERS') THEN
                RgStrNum := 109;
              {// END OF LNG, START OF NOTE }
              IF (S = 'INTERNAL_USE_ONLY') THEN
                RGStrNum := 110
              ELSE IF (S = 'ONLY_CHANGE_LOCALLY') THEN
                RGStrNum := 111
              ELSE IF (S = 'INVALID_MENU_NUMBER') THEN
                RGStrNum := 112
              ELSE IF (S = 'MINIMUM_BAUD_LOGON_PW') THEN
                RGStrNum := 113
              ELSE IF (S = 'MINIMUM_BAUD_LOGON_HIGH_LOW_TIME_PW') THEN
                RGStrNum := 114
              ELSE IF (S = 'MINIMUM_BAUD_LOGON_HIGH_LOW_TIME_NO_PW') THEN
                RGStrNum := 115
              ELSE IF (S = 'LOGON_EVENT_RESTRICTED_1') THEN
                RGStrNum := 116
              ELSE IF (S = 'LOGON_EVENT_RESTRICTED_2') THEN
                RGStrNum := 117
              ELSE IF (S = 'NAME_NOT_FOUND') THEN
                RGStrNum := 118
              ELSE IF (S = 'ILLEGAL_LOGON') THEN
                RGStrNum := 119
              ELSE IF (S = 'LOGON_NODE_ACS') THEN
                RGStrNum := 120
              ELSE IF (S = 'LOCKED_OUT') THEN
                RGStrNum := 121
              ELSE IF (S = 'LOGGED_ON_ANOTHER_NODE') THEN
                RGStrNum := 122
              ELSE IF (S = 'INCORRECT_BIRTH_DATE') THEN
                RGStrNum := 123
              ELSE IF (S = 'INSUFFICIENT_LOGON_CREDITS') THEN
                RGStrNum := 124
              ELSE IF (S = 'LOGON_ONCE_PER_DAY') THEN
                RGStrNum := 125
              ELSE IF (S = 'LOGON_CALLS_ALLOWED_PER_DAY') THEN
                RGStrNum := 126
              ELSE IF (S = 'LOGON_TIME_ALLOWED_PER_DAY_OR_CALL') THEN
                RGStrNum := 127
              ELSE IF (S = 'LOGON_MINUTES_LEFT_IN_BANK') THEN
                RGStrNum := 128
              ELSE IF (S = 'LOGON_MINUTES_LEFT_IN_BANK_TIME_LEFT') THEN
                RGStrNum := 129
              ELSE IF (S = 'LOGON_BANK_HANGUP') THEN
                RGStrNum := 130
              ELSE IF (S = 'LOGON_ATTEMPT_IEMSI_NEGOTIATION') THEN
                RGStrNum := 131
              ELSE IF (S = 'LOGON_IEMSI_NEGOTIATION_SUCCESS') THEN
                RGStrNum := 132
              ELSE IF (S = 'LOGON_IEMSI_NEGOTIATION_FAILED') THEN
                RGStrNum := 133
              ELSE IF (S = 'LOGON_ATTEMPT_DETECT_EMULATION') THEN
                RGStrNum := 134
              ELSE IF (S = 'LOGON_RIP_DETECTED') THEN
                RGStrNum := 135
              ELSE IF (S = 'LOGON_ANSI_DETECT_OTHER') THEN
                RGStrNum := 136
              ELSE IF (S = 'LOGON_ANSI_DETECT') THEN
                RGStrNum := 137
              ELSE IF (S = 'LOGON_AVATAR_DETECT_OTHER') THEN
                RGStrNum := 138
              ELSE IF (S = 'LOGON_AVATAR_DETECT') THEN
                RGStrNum := 139
              ELSE IF (S = 'LOGON_EMULATION_DETECTED') THEN
                RGStrNum := 140
              ELSE IF (S = 'SHUTTLE_LOGON_VALIDATION_STATUS') THEN
                RGStrNum := 141
              ELSE IF (S = 'LOGON_CLOSED_BBS') THEN
                RGStrNum := 142
              ELSE IF (S = 'NODE_ACTIVITY_WAITING_ONE') THEN
                RGStrNum := 143
              ELSE IF (S = 'NODE_ACTIVITY_WAITING_TWO') THEN
                RGStrNum := 144
              ELSE IF (S = 'NODE_ACTIVITY_LOGGING_ON') THEN
                RGStrNum := 145
              ELSE IF (S = 'NODE_ACTIVITY_NEW_USER_LOGGING_ON') THEN
                RGStrNum := 146
              ELSE IF (S = 'NODE_ACTIVITY_MISCELLANEOUS') THEN
                RGStrNum := 147
              ELSE IF (S = 'NEW_USER_PASSWORD_INVALID') THEN
                RGStrNum := 148
              ELSE IF (S = 'NEW_USER_PASSWORD_ATTEMPT_EXCEEDED') THEN
                RGStrNum := 149
              ELSE IF (S = 'NEW_USER_RECORD_SAVING') THEN
                RGStrNum := 150
              ELSE IF (S = 'NEW_USER_RECORD_SAVED') THEN
                RGStrNum := 151
              ELSE IF (S = 'NEW_USER_APPLICATION_LETTER') THEN
                RGStrNum := 152
              ELSE IF (S = 'NEW_USER_IN_RESPONSE_TO_SUBJ') THEN
                RGStrNum := 153
              ELSE IF (S = 'ABORTED') THEN
                RgStrNum := 154
              ELSE IF (S = 'SAVED') THEN
                RgStrNum := 155
              ELSE IF (S = 'NAME_FIRST_AND_LAST') THEN
                RgStrNum := 156
              ELSE IF (S = 'NAME_EXISTS') THEN
                RgStrNum := 157
              ELSE IF (S = 'NAME_BLACKLISTED') THEN
                RgStrNum := 158
              ELSE IF (S = 'INVALID_ADDRESS') THEN
                RgStrNum := 159
              ELSE IF (S = 'INVALID_CITY') THEN
                RgStrNum := 160
              ELSE IF (S = 'INVALID_BIRTHDATE') THEN
                RgStrNum := 161
              ELSE IF (S = 'INVALID_PASSWORD') THEN
                RgStrNum := 162
              ELSE IF (S = 'BAD_PASSWORD_SHORT') THEN
                RgStrNum := 163
              ELSE IF (S = 'BAD_PASSWORD_LONG') THEN
                RgStrNum := 164
              ELSE IF (S = 'BAD_PASSWORD_SAME') THEN
                RgStrNum := 165
              ELSE IF (S = 'BAD_PASSWORD_NAME') THEN
                RgStrNum := 166
              ELSE IF (S = 'PASSWORDS_DONT_MATCH') THEN
                RgStrNum := 167
              ELSE IF (S = 'PASSWORD_CHANGED') THEN
                RgStrNum := 168
              ELSE IF (S = 'COLOR_SCHEME_DEFAULT') THEN
                RgStrNum := 169
              ELSE IF (S = 'LIGHTBARS_NOT_AVAIL') THEN
                RgStrNum := 170
              ELSE IF (S = 'EDITOR_NO_ANSI') THEN
                RgStrNum := 171
              ELSE IF (S = 'MAILBOX_OPENED') THEN
                RgStrNum := 172
              ELSE IF (S = 'MAILBOX_NO_LONGER_FORWARDING') THEN
                RgStrNum := 173
              ELSE IF (S = 'MAILBOX_CLOSED') THEN
                RgStrNum := 174
              ELSE IF (S = 'FORWARD_MAIL_INFO') THEN
                RgStrNum := 175
              ELSE IF (S = 'CANT_FORWARD_USER') THEN
                RgStrNum := 176
              ELSE IF (S = 'FORWARDING_TO') THEN
                RgStrNum := 177
              ELSE IF (S = 'QWK_CONFIG') THEN
                RgStrNum := 178;
              {// END OF NOTE, START OF MAIN }
              IF (S = 'BAUD_OVERRIDE_PW') THEN
                RGStrNum := 180 
              ELSE IF (S = 'CALLER_LOGON') THEN
                RGStrNum := 181
              ELSE IF (S = 'LOGON_AS_NEW') THEN
                RGStrNum := 182
              ELSE IF (S = 'USER_LOGON_PASSWORD') THEN
                RGStrNum := 183
              ELSE IF (S = 'USER_LOGON_PHONE_NUMBER') THEN
                RGStrNum := 184
              ELSE IF (S = 'SYSOP_LOGON_PASSWORD') THEN
                RGStrNum := 185
              ELSE IF (S = 'FORGOT_PW_QUESTION') THEN
                RGStrNum := 186
              ELSE IF (S = 'VERIFY_BIRTH_DATE') THEN
                RGStrNum := 187
              ELSE IF (S = 'LOGON_WITHDRAW_BANK') THEN
                RGStrNum := 188
              ELSE IF (S = 'SHUTTLE_LOGON') THEN
                RGStrNum := 189
              ELSE IF (S = 'NEW_USER_PASSWORD') THEN
                RGStrNum := 190
              ELSE IF (S = 'TELECONF_NORMAL') THEN
                RGStrNum := 191
              ELSE IF (S = 'TELECONF_ANONYMOUS') THEN
                RGStrNum := 192
              ELSE IF (S = 'TELECONF_GLOBAL') THEN {**}
                RGStrNum := 193
              ELSE IF (S = 'TELECONF_PRIVATE') THEN
                RGStrNum := 194
              ELSE IF (S = 'ENTER_HANDLE') THEN
                RGStrNum := 195
              ELSE IF (S = 'ENTER_NAME_NO_HANDLES') THEN
                RGStrNum := 196
              ELSE IF (S = 'ENTER_REAL_NAME') THEN
                RGStrNum := 197
              ELSE IF (S = 'ENTER_COUNTRY') THEN
                RGStrNum := 198
              ELSE IF (S = 'ENTER_ADDRESS') THEN
                RGStrNum := 199
              ELSE IF (S = 'ENTER_CITY') THEN
                RGStrNum := 200
              ELSE IF (S = 'ENTER_STATE_PROVINCE') THEN
                RGStrNum := 201
              ELSE IF (S = 'ENTER_ZIPCODE') THEN
                RGStrNum := 202
              ELSE IF (S = 'ENTER_POSTAL_CODE_CANADA') THEN
                RGStrNum := 203
              ELSE IF (S = 'ENTER_POSTAL_CODE') THEN
                RGStrNum := 204
              ELSE IF (S = 'ENTER_PHONE_NUMBER') THEN
                RGStrNum := 205
              ELSE IF (S = 'ENTER_BIRTHDATE') THEN
                RGStrNum := 206
              ELSE IF (S = 'ENTER_GENDER') THEN
                RGStrNum := 207
              ELSE IF (S = 'ENTER_CURRENT_PASSWORD') THEN
                RGStrNum := 208
              ELSE IF (S = 'ENTER_PASSWORD') THEN
                RGStrNum := 209
              ELSE IF (S = 'VERIFY_PASSWORD') THEN
                RGStrNum := 210
              ELSE IF (S = 'FORGOT_PW') THEN
                RGStrNum := 211
              ELSE IF (S = 'ENTER_FORGOT_PW_ANSWER') THEN
                RGStrNum := 212
              ELSE IF (S = 'EMULATION_ANSI_SUPPORT') THEN
                RGStrNum := 213
              ELSE IF (S = 'EMULATION_AUTO_DETECT') THEN
                RGStrNum := 214
              ELSE IF (S = 'TOGGLE_COLOR') THEN
                RGStrNum := 215
              ELSE IF (S = 'COLOR_SCHEME_SELECT') THEN
                RGStrNum := 216
              ELSE IF (S = 'SCREEN_COLUMNS') THEN
                RGStrNum := 217
              ELSE IF (S = 'SCREEN_ROWS') THEN
                RGStrNum := 218
              ELSE IF (S = 'TOGGLE_CLEAR') THEN
                RGStrNum := 219
              ELSE IF (S = 'TOGGLE_PAUSE') THEN
                RGStrNum := 220
              ELSE IF (S = 'TOGGLE_HOTKEYS') THEN
                RGStrNum := 221
              ELSE IF (S = 'TOGGLE_EXPERT') THEN
                RGStrNum := 222
              ELSE IF (S = 'TOGGLE_LIGHTBARS') THEN
                RGStrNum := 223
              ELSE IF (S = 'TOGGLE_EDITOR') THEN
                RGStrNum := 224
              ELSE IF (S = 'OPEN_MAILBOX_FORWARDING') THEN
                RGStrNum := 225
              ELSE IF (S = 'OPEN_MAILBOX') THEN
                RGStrNum := 226
              ELSE IF (S = 'CLOSE_MAILBOX') THEN
                RGStrNum := 227
              ELSE IF (S = 'FORWARD_MAIL') THEN
                RGStrNum := 228
              ELSE IF (S = 'USER_SEARCH') THEN
                RGStrNum := 229
              ELSE IF (S = 'QWK_SELECT_ARCHIVE') THEN
                RGStrNum := 230
              ELSE IF (S = 'QWK_OWN_REPLIES') THEN
                RGStrNum := 231
              ELSE IF (S = 'QWK_PRIVATE') THEN
                RGStrNum := 232
              ELSE IF (S = 'QWK_NEW_FILES') THEN
                RGStrNum := 233
              {// END OF COMB }
                (*
              ELSE IF (S = '') THEN
                RgStrNum := 
                *)
                ;
              IF (RGStrNum = -1) THEN
                BEGIN
                  WriteLn('Error!');
                  WriteLn;
                  WriteLn(^G^G^G'The following string definition is invalid:');
                  WriteLn;
                  WriteLn('   '+S);
                  Found := FALSE;
                END
              ELSE
                BEGIN
                  Done := FALSE;
                  WITH StrPointer DO
                    BEGIN
                      Pointer := (FileSize(RGStrFile) + 1);
                      TextSize := 0;
                    END;
                    Seek(RGStrFile,FileSize(RGStrFile));
                    WHILE NOT EOF(F) AND (NOT Done) DO
                      BEGIN
                        ReadLn(F,S);
                        IF (S[1] = '$') THEN
                          Done := TRUE
                        ELSE
                          BEGIN
                            Inc(StrPointer.TextSize,(Length(S) + 1));
                            BlockWrite(RGStrFile,S,(Length(S) + 1));
                          END;
                      END;
                    Seek(StrPointerFile,RGStrNum);
                    Write(StrPointerFile,StrPointer);
                END;
            END;
          END;
          Close(F);
          Close(RGStrFile);
          Close(StrPointerFile);
          IF (Found) THEN
            WriteLn('Done!')
          ELSE
            BEGIN
              Erase(StrPointerFile);
              Erase(RGStrFile);
            END;
    END;  
END.