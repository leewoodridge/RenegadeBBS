{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
removed macros, in their own submenu now
}
UNIT SysOp2D;

INTERFACE

PROCEDURE SystemGeneralVariables;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader}

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

BEGIN
  REPEAT
    WITH General DO
      BEGIN
        Abort := FALSE;
        Next := FALSE;
		ConfigHeader('System Variables');
        PrintACR(PadLeftStr('^0(^1A^0) Max private sent per call : ^1'+IntToStr(MaxPrivPost),39)+
                 PadLeftStr('^0(^1B^0) Max feedback sent per call : ^1'+IntToStr(MaxFBack),39));
        PrintACR(PadLeftStr('^0(^1C^0) Max public posts per call : ^1'+IntToStr(MaxPubPost),39)+
                 PadLeftStr('^0(^1D^0) Max chat attempts per call : ^1'+IntToStr(MaxChat),39));
        PrintACR(PadLeftStr('^0(^1E^0) Normal max mail waiting   : ^1'+IntToStr(MaxWaiting),39)+
                 PadLeftStr('^0(^1F^0) CoSysOp max mail waiting   : ^1'+IntToStr(CSMaxWaiting),39));
        PrintACR(PadLeftStr('^0(^1G^0) Max mass mail list        : ^1'+IntToStr(MaxMassMailList),39)+
                 PadLeftStr('^0(^1H^0) Logins before bday check   : ^1'+IntToStr(BirthDateCheck),39));
        PrintACR(PadLeftStr('^0(^1I^0) Swap shell should use     : ^1'+DisplaySwapTo(SwapTo),39)+
                 PadLeftStr('^0(^1J^0) Number of logon attempts   : ^1'+IntToStr(MaxLogonTries),39));
        PrintACR(PadLeftStr('^0(^1K^0) Password change in days   : ^1'+IntToStr(PasswordChange),39)+
                 PadLeftStr('^0(^1L^0) SysOp chat color           : ^1'+IntToStr(SysOpColor),39));
        PrintACR(PadLeftStr('^0(^1M^0) User chat color           : ^1'+IntToStr(UserColor),39)+
                 PadLeftStr('^0(^1N^0) Min. space for posts       : ^1'+IntToStr(MinSpaceForPost),39));
        PrintACR(PadLeftStr('^0(^1O^0) Min. space for uploads    : ^1'+IntToStr(MinSpaceForUpload),39)+
                 PadLeftStr('^0(^1P^0) Back SysOp Log keep days   : ^1'+IntToStr(BackSysOpLogs),39));
        PrintACR(PadLeftStr('^0(^1R^0) Blank WFC menu minutes    : ^1'+IntToStr(WFCBlankTime),39)+
                 PadLeftStr('^0(^1S^0) Alert beep delay           : ^1'+IntToStr(AlertBeep),39));
        PrintACR(PadLeftStr('^0(^1T^0) Number of system callers  : ^1'+IntToStr(CallerNum),39)+
                 PadLeftStr('^0(^1U^0) Minimum logon baud rate    : ^1'+IntToStr(MinimumBaud),39));
        PrintACR(PadLeftStr('^0(^1V^0) Minimum D/L baud rate     : ^1'+IntToStr(MinimumDLBaud),39)+
                 PadLeftStr('^0(^1W^0) Sec`s between Time Slices  : ^1'+IntToStr(SliceTimer),39));
        PrintACR(PadLeftStr('^0(^1X^0) TB max time allowed       : ^1'+IntToStr(MaxDepositEver),39)+
                 PadLeftStr('^0(^1Y^0) TB max per day deposit     : ^1'+IntToStr(MaxDepositPerDay),39));
        PrintACR(PadLeftStr('^0(^1Z^0) TB max per day withdrawal : ^1'+IntToStr(MaxWithDrawalPerDay),39)+
                 PadLeftStr('',39));
        InputChar('%LFEnter selection [^1A^2-^1P^2,^1R^2-^1Z^2,^10^2-^19^2,^1Q^2=^1Quit^2]: ',Cmd,
                  'QABCDEFGHIJKLMNOPRSTUVWXYZ1234567890'{^M},[CapAll]);
        CASE Cmd OF
          'I' : BEGIN
                  NL;
                  Print('^1Swap locations:^0');
                  NL;
                  Print('^0(^1D^0)isk');
                  Print('^0(^1E^0)MS');
                  Print('^0(^1X^0)MS');
                  Print('^0(^1N^0)on XMS Extended');
                  Print('^0(^1A^0)ny');
                  NL;
                  InputChar('Swap to which? [^1DEXNA^2,<^1CR^2>Quit]: ',Cmd,'DEXNA'^M,[CapAll]);
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
                            MinByte := 1;
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
                      InputInteger('%LFNew value',TempI,[NumbersOnly],MinInt,MaxInt,Changed);
                    'T'..'V','X'..'Z' :
                      InputLongInt('%LFNew value',TempL,[NumbersOnly],MinLongInt,MaxLongInt,Changed);
                    ELSE
                      InputByte('%LFNew value',TempB,[NumbersOnly],MinByte,MaxByte,Changed);
                  END;
                  CASE Cmd OF
                    'A' : MaxPrivPost := TempB;
                    'B' : MaxFBack := TempB;
                    'C' : MaxPubPost := TempB;
                    'D' : MaxChat := TempB;
                    'E' : MaxWaiting := TempB;
                    'F' : CSMaxWaiting := TempB;
                    'G' : MaxMassMailList := TempB;
                    'H' : BEGIN
                            BirthDateCheck := TempI;
                            { Toggle newuser question also }
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