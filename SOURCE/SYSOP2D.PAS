{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
removed macros, in their own submenu now
}
UNIT SysOp2D;

INTERFACE

PROCEDURE SystemGeneralVariables;

IMPLEMENTATION

USES
  Common;

PROCEDURE SystemGeneralVariables;
VAR
  Cmd: Char;
  TempB,
  MinByte,
  MaxByte: Byte;
  TempI,
  MinInt,
  MaxInt: Integer;
  TempL,
  MinLongInt,
  MaxLongInt: LongInt;

  FUNCTION DisplaySwapTo(SwapTo: Byte): Str4;
  BEGIN
    CASE SwapTo OF
      0   : DisplaySwapTo := 'Disk';
      1   : DisplaySwapTo := 'XMS';
      2   : DisplaySwapTo := 'EMS';
      4   : DisplaySwapTo := 'EXT';
      255 : DisplaySwapTo := 'Any';
    END;
  END;

{
  PROCEDURE DisplayMacroo(CONST S: AStr; MaxLen: Byte);
  VAR
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    TempStr := '';
    Prompt('^1"^0');
    FOR Counter := 1 TO Length(S) DO
      IF (S[Counter] >= ' ') THEN
        TempStr := TempStr + S[Counter]
      ELSE
        TempStr := TempStr +  '^1^'+Chr(Ord(S[Counter]) + 64)+'^0';
    Prompt(PadLeftStr(TempStr,MaxLen)+'^1"');
  END;

  PROCEDURE MMacroo(MacroNum: Byte);
  VAR
    S: AStr;
    C: Char;
    Counter: Byte;
  BEGIN
    Print('%CL^1Enter new F'+IntToStr(MacroNum + 1)+' macro now.');
    Print('^1Enter ^Z to end recording. 100 character limit.%LF');
    S := '';
    Counter := 1;
    REPEAT
      C := Char(GetKey);
      IF (C = ^H) THEN
      BEGIN
        C := #0;
        IF (Counter >= 2) THEN
        BEGIN
          BackSpace;
          Dec(Counter);
          IF (S[Counter] < #32) THEN
            BackSpace;
        END;
      END;
      IF (Counter <= 100) AND (C <> #0) THEN
      BEGIN
        IF (C IN [#32..#255]) THEN
        BEGIN
          OutKey(C);
          S[Counter] := C;
          Inc(Counter);
        END
        ELSE IF (C IN [^A,^B,^C,^D,^E,^F,^G,^H,^I,^J,^K,^L,^M,^N,^P,^Q,^R,^S,^T,^U,^V,^W,^X,^Y,#27,#28,#29,#30,#31]) THEN
        BEGIN
          IF (C = ^M) THEN
            NL
          ELSE
            Prompt('^1^'+Chr(Ord(C) + 64)+'^0');
          S[Counter] := C;
          Inc(Counter);
        END;
      END;
    UNTIL ((C = ^Z) OR (HangUp));
    S[0] := Chr(Counter - 1);
    Print('%LF%LF^1Your F'+IntToStr(MacroNum + 1)+' macro is now:%LF');
    DisplayMacroo(S,160);
    Com_Flush_Recv;
    IF (NOT PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
      Print('%LFMacro not saved.')
    ELSE
    BEGIN
      General.Macro[MacroNum] := S;
      Print('%LFMacro saved.');
    END;
    PauseScr(FALSE);
  END;
}
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^1System Variables:');
      NL;
      PrintACR('^0A. Max private sent per call: ^1'+PadLeftInt(MaxPrivPost,6)+
             '^0  B. Max feedback sent per call: ^1'+PadLeftInt(MaxFBack,6));
      PrintACR('^0C. Max public posts per call: ^1'+PadLeftInt(MaxPubPost,6)+
             '^0  D. Max chat attempts per call: ^1'+PadLeftInt(MaxChat,6));
      PrintACR('^0E. Normal max mail waiting  : ^1'+PadLeftInt(MaxWaiting,6)+
             '^0  F. CoSysOp max mail waiting  : ^1'+PadLeftInt(CSMaxWaiting,6));
      PrintACR('^0G. Max mass mail list       : ^1'+PadLeftInt(MaxMassMailList,6)+
             '^0  H. Logins before bday check  : ^1'+PadLeftInt(BirthDateCheck,6));
      PrintACR('^0I. Swap shell should use    : ^1'+PadLeftStr(DisplaySwapTo(SwapTo),6)+
             '^0  J. Number of logon attempts  : ^1'+PadLeftInt(MaxLogonTries,6));
      PrintACR('^0K. Password change in days  : ^1'+PadLeftInt(PasswordChange,6)+
             '^0  L. SysOp chat color          : ^1'+PadLeftInt(SysOpColor,6));
      PrintACR('^0M. User chat color          : ^1'+PadLeftInt(UserColor,6)+
             '^0  N. Min. space for posts      : ^1'+PadLeftInt(MinSpaceForPost,6));
      PrintACR('^0O. Min. space for uploads   : ^1'+PadLeftInt(MinSpaceForUpload,6)+
             '^0  P. Back SysOp Log keep days  : ^1'+PadLeftInt(BackSysOpLogs,6));
      PrintACR('^0R. Blank WFC menu minutes   : ^1'+PadLeftInt(WFCBlankTime,6)+
             '^0  S. Alert beep delay          : ^1'+PadLeftInt(AlertBeep,6));
      PrintACR('^0T. Number of system callers : ^1'+PadLeftInt(CallerNum,6)+
             '^0  U. Minimum logon baud rate   : ^1'+PadLeftInt(MinimumBaud,6));
      PrintACR('^0V. Minimum D/L baud rate    : ^1'+PadLeftInt(MinimumDLBaud,6)+
             '^0  W. Sec''s between Time Slices : ^1'+PadLeftInt(SliceTimer,6));
      PrintACR('^0X. TB max time allowed      : ^1'+PadLeftInt(MaxDepositEver,6)+
             '^0  Y. TB max per day deposit    : ^1'+PadLeftInt(MaxDepositPerDay,6));
      PrintACR('^0Z. TB max per day withdrawal: ^1'+PadLeftInt(MaxWithDrawalPerDay,6));
      {
	  NL;
      FOR TempB := 0 TO 9 DO
      BEGIN
        Prompt('^0'+IntToStr(TempB)+'. F'+IntToStr(TempB + 1)+' Macro :^1');
        DisplayMacroo(Macro[TempB],21);
        IF Odd(TempB) THEN
          NL
        ELSE
          Prompt('   ');
      END;
	  }
      Prt('%LFEnter selection [^1A^2-^1P^2,^1R^2-^1Z^2,^10^2-^19^2,^1Q^2=^1Quit^2]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ1234567890'^M,TRUE,TRUE);
      CASE Cmd OF
	  {
        '0'..'9' :
              MMacroo(Ord(Cmd) - Ord('0'));
			  }
        'I' : BEGIN
                Print('%LF^1Swap locations:^0');
                Print('%LF^0(^1D^0)isk');
                Print('^0(^1E^0)MS');
                Print('^0(^1X^0)MS');
                Print('^0(^1N^0)on XMS Extended');
                Print('^0(^1A^0)ny');
                lOneK('%LFSwap to which? [^1D^2,^1E^2,^1X^2,^1N^2,^1A^2,^1<CR>^2=^1Quit^2]: ',Cmd,'DEXNA'^M,TRUE,TRUE);
                CASE Pos(Cmd,'DXENA') OF
                  1..3 : SwapTo := (Pos(Cmd,'DXE') - 1);
                     4 : SwapTo := 4;
                     5 : SwapTo := 255;
                END;
                Cmd := #0;
              END;
        'A'..'H','J'..'P','R'..'Z' :
              BEGIN
                CASE Cmd OF
                  'A' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxPrivPost;
                        END;
                  'B' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxFBack;
                        END;
                  'C' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxPubPost;
                        END;
                  'D' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxChat;
                        END;
                  'E' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxWaiting;
                        END;
                  'F' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := CSMaxWaiting;
                        END;
                  'G' : BEGIN
                          MinByte := 2;
                          MaxByte := 255;
                          TempB := MaxMassMailList;
                        END;
                  'H' : BEGIN
                          MinInt := 0;
                          MaxInt := 365;
                          TempI := BirthDateCheck;
                        END;
                  'J' : BEGIN
                          MinByte := 0;
                          MaxByte := 255;
                          TempB := MaxLogonTries;
                        END;
                  'K' : BEGIN
                          MinInt := 0;
                          MaxInt := 32767;
                          TempI := PasswordChange;
                        END;
                  'L' : BEGIN
                          MinByte := 0;
                          MaxByte := 9;
                          TempB := SysOpColor;
                        END;
                  'M' : BEGIN
                          MinByte := 0;
                          MaxByte := 9;
                          TempB := UserColor;
                        END;
                  'N' : BEGIN
                          MinInt := 1;
                          MaxInt := 32767;
                          TempI := MinSpaceForPost;
                        END;
                  'O' : BEGIN
                          MinInt := 1;
                          MaxInt := 32767;
                          TempI := MinSpaceForUpload;
                        END;
                  'P' : BEGIN
                          MinByte := 1;
                          MaxByte := 255;
                          TempB := BackSysOpLogs;
                        END;
                  'R' : BEGIN
                          MinByte := 0;
                          MaxByte := 60;
                          TempB := WFCBlankTime;
                        END;
                  'S' : BEGIN
                          MinByte := 0;
                          MaxByte := 60;
                          TempB := AlertBeep;
                        END;
                  'T' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 2147483647;
                          TempL := CallerNum;
                        END;
                  'U' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 115200;
                          TempL := MinimumBaud;
                        END;
                  'V' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 115200;
                          TempL := MinimumDLBaud;
                        END;
                  'W' : BEGIN
                          MinByte := 1;
                          MaxByte := 255;
                          TempB := SliceTimer;
                        END;
                  'X' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxDepositEver;
                        END;
                  'Y' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxDepositPerDay;
                        END;
                  'Z' : BEGIN
                          MinLongInt := 0;
                          MaxLongInt := 6000;
                          TempL := MaxWithdrawalPerDay
                        END;
                END;
                CASE Cmd OF
                  'H','K','N'..'O' :
                        InputIntegerWOC('%LFNew value',TempI,[NumbersOnly],MinInt,MaxInt);
                  'T'..'V','X'..'Z' :
                        InputLongIntWOC('%LFNew value',TempL,[DisplayValue,NumbersOnly],MinLongInt,MaxLongInt);
                ELSE
                  InputByteWOC('%LFNew value',TempB,[NumbersOnly],MinByte,MaxByte);
                END;
                CASE Cmd OF
                  'A' : MaxPrivPost := TempB;
                  'B' : MaxFBack := TempB;
                  'C' : MaxPubPost := TempB;
                  'D' : MaxChat := TempB;
                  'E' : MaxWaiting := TempB;
                  'F' : CSMaxWaiting := TempB; (* Not Hooked Up *)
                  'G' : MaxMassMailList := TempB;
                  'H' : BEGIN
                          BirthDateCheck := TempI;
                          (*
                          IF (BirthDateCheck = 0) THEN
                            NewUserToggles[9] := 0
                          ELSE
                            NewUserToggles[9] := 2;
                          *)
                        END;
                  'J' : MaxLogonTries := TempB;
                  'K' : PasswordChange := TempI;
                  'L' : SysOpColor := TempB;
                  'M' : UserColor := TempB;
                  'N' : MinSpaceForPost := TempI;
                  'O' : MinSpaceForUpload := TempI;
                  'P' : BackSysOpLogs := TempB;
                  'R' : WFCBlankTime := TempB;
                  'S' : AlertBeep := TempB;
                  'T' : CallerNum := TempL;
                  'U' : MinimumBaud := TempL;
                  'V' : MinimumDLBaud := TempL;
                  'W' : SliceTimer := TempB;
                  'X' : MaxDepositEver := TempL;
                  'Y' : MaxDepositPerDay := TempL;
                  'Z' : MaxWithDrawalPerDay := TempL;
                END;
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
