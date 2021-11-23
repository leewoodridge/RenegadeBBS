{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp11;

INTERFACE

PROCEDURE ChangeUser;
PROCEDURE ShowLogs;

IMPLEMENTATION

USES
  Common,
  TimeFunc,
  MiscUser;

PROCEDURE ChangeUser;
VAR
  UNum: Integer;
BEGIN
  lFindUserWS(UNum); {LeeW: Changed -- was FindUser(UNum);}
  IF (UNum >= 1) THEN
    BEGIN
      SaveURec(ThisUser,UserNum);
      LoadURec(ThisUser,UNum);
      UserNum := UNum;
      ChopTime := 0;
      ExtraTime := 0;
      FreeTime := 0;
      IF (ComPortSpeed > 0) THEN
        SysOpLog('^8[*] ^0Switched User Account To: ^1'+AllCaps(ThisUser.Name));
      Update_Screen;
      NewCompTables;
      LoadNode(ThisNode);
      WITH NodeR DO
        BEGIN
          User := UserNum;
          UserName := ThisUser.Name;
        END;
      SaveNode(ThisNode);
    END;
END;

PROCEDURE ShowLogs;
VAR
  TempStr: Str10;
  Day: Word;
BEGIN
  NL;
  TempStr := '0';
  Prt('^0Enter date (^1MM/DD/YYYY^0 format), or # of days ago (^10^0-^1'+IntToStr(General.BackSysOpLogs)+'^0): ');
  InputMain(TempStr,SizeOf(TempStr)-1,[InteractiveEdit,CapAll]);
  IF (Length(TempStr) = 10) AND (DayNum(TempStr) > 0) THEN
    Day := (DayNum(DateStr) - DayNum(TempStr))
  ELSE
    Day := StrToInt(TempStr);
  AllowContinue := TRUE;
  IF (Day = 0) THEN
    PrintF(General.LogsPath+'SYSOP.LOG')
  ELSE
    PrintF(General.LogsPath+'SYSOP'+IntToStr(Day)+'.LOG');
  AllowContinue := FALSE;
  IF (NoFile) THEN
    BEGIN
      NL;
      Print('SysOp log file not found');
    END;
  IF (UserOn) THEN
    SysOpLog('Read SysOp Log ('+AOnOff(Day = 0,'Today''s',IntToStr(Day)+' Days Ago')+')');
  PauseScr(FALSE);
END;

END.
