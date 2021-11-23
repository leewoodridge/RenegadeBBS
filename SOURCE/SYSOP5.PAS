{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp5;

INTERFACE

PROCEDURE HistoryEditor;

IMPLEMENTATION

USES
  Common,
  TimeFunc;

PROCEDURE HistoryEditor;
CONST
  MaxHistoryDates = 32767;
VAR
  HistoryFile: FILE OF HistoryRecordType;
  History: HistoryRecordType;
  TempHistory: HistoryRecordType;
  Cmd: Char;
  RecNumToList,
  NumHistoryDates: Integer;
  SaveTempPause: Boolean;

  PROCEDURE InitHistoryVars(VAR History: HistoryRecordType);
  VAR
    Counter: Byte;
  BEGIN
    FillChar(History,SizeOf(History),0);
    WITH History DO
    BEGIN
      Date := 0;
      FOR Counter := 0 TO 20 DO
        UserBaud[Counter] := 0;
      Active := 0;
      Callers := 0;
      NewUsers := 0;
      Posts := 0;
      EMail := 0;
      FeedBack := 0;
      Errors := 0;
      Uploads := 0;
      Downloads := 0;
      UK := 0;
      Dk := 0;
    END;
  END;

  PROCEDURE LocateHistoryDate(DisplayStr: AStr; TempHistory1: HistoryRecordType; VAR DateToLocate: Str10;
                              VAR RecNum1: Integer; ShowErr,Searching: Boolean);
  VAR
    RecNum: Integer;
  BEGIN
    RecNum1 := -1;
    InputFormatted(DisplayStr,DateToLocate,'##-##-####',TRUE);
    IF (DateToLocate <> '') AND (Length(DateToLocate) = 10) THEN
    BEGIN
      IF (Searching) THEN
        Reset(HistoryFile);
      RecNum := 1;
      WHILE (RecNum <= FileSize(HistoryFile)) AND (RecNum1 = -1) DO
      BEGIN
        Seek(HistoryFile,(RecNum - 1));
        Read(HistoryFile,TempHistory1);
        IF (PD2Date(TempHistory1.Date) = DateToLocate) THEN
           RecNum1 := RecNum;
        Inc(RecNum);
      END;
      IF (Searching) THEN
        Close(HistoryFile);
      IF (ShowErr) AND (RecNum1 = -1) THEN
      BEGIN
        Print('%LF^8The date entered is invalid!^0');
        PauseScr(FALSE);
      END;
    END;
  END;

  PROCEDURE DeleteHistoryRecord(TempHistory1: HistoryRecordType; RecNumToDelete: Integer);
  VAR
    DateToDelete: Str10;
    RecNum: Integer;
  BEGIN
    IF (NumHistoryDates = 0) THEN
      Messages(4,0,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to delete: ',TempHistory1,DateToDelete,RecNumToDelete,TRUE,TRUE);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumHistoryDates) THEN
      BEGIN
        Reset(HistoryFile);
        Seek(HistoryFile,(RecNumToDelete - 1));
        Read(HistoryFile,TempHistory1);
        Close(HistoryFile);
        LastError := IOResult;
        IF (PD2Date(TempHistory1.Date) = DateStr) THEN
        BEGIN
          Print('%LF^8The current history date can not be deleted!^0');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          Print('%LFHistory date: ^1'+PD2Date(TempHistory1.Date));
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting history record ...');
            Dec(RecNumToDelete);
            Reset(HistoryFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(HistoryFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(HistoryFile) - 2) DO
              BEGIN
                Seek(HistoryFile,(RecNum + 1));
                Read(HistoryFile,History);
                Seek(HistoryFile,RecNum);
                Write(HistoryFile,History);
              END;
            Seek(HistoryFile,(FileSize(HistoryFile) - 1));
            Truncate(HistoryFile);
            Close(HistoryFile);
            LastError := IOResult;
            Dec(NumHistoryDates);
            SysOpLog('* Deleted history date: ^1'+Pd2Date(TempHistory1.Date));
          END;
        END;
      END;
    END;
  END;

  PROCEDURE CheckHistoryRecord(History: HistoryRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : ;
      END;
  END;

  PROCEDURE EditHistoryRecord(TempHistory1: HistoryRecordType; VAR History: HistoryRecordType; VAR Cmd1: Char;
                            VAR RecNumToEdit,SaveRecNumToEdit: Integer; VAR Changed: Boolean; Editing: Boolean);
  VAR
    CmdStr,
    TempStr1: AStr;
    DateToLocate: Str10;
    RecNum: Integer;
    Ok: Boolean;
  BEGIN
    WITH History DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            PrintACR('^1Editing history record #'+IntToStr((NumHistoryDates  + 1) - RecNumToEdit)+
                     ' of '+IntToStr(NumHistoryDates))
          ELSE
            PrintACR('^1Inserting history record #'+IntToStr((NumHistoryDates + 1) - RecNumToEdit)+
                     ' of '+IntToStr(NumHistoryDates + 1));
          NL;
          IF (Callers > 0) THEN
            TempStr1 := IntToStr(Active DIV Callers)
          ELSE
            TempStr1 := '0';
          PrintACR('^0A. Date          : ^1'+PD2Date(Date)+AOnOff(RecNumToEdit = NumHistoryDates,' (Today)',''));
          PrintACR('^0B. Minutes Active: ^1'+FormatNumber(Active));
          PrintACR('^0C. Calls         : ^1'+FormatNumber(Callers));
          PrintACR('^0D. Percent Active: ^1'+SQOutSp(CTP(Active,1440)));
          PrintACR('^0E. New Users     : ^1'+FormatNumber(NewUsers));
          PrintACR('^0G. Time/User     : ^1'+TempStr1);
          PrintACR('^0H. Public Posts  : ^1'+FormatNumber(Posts));
          PrintACR('^0I. Private Posts : ^1'+FormatNumber(EMail));
          PrintACR('^0K. SysOp FeedBack: ^1'+FormatNumber(FeedBack));
          PrintACR('^0M. Errors        : ^1'+FormatNumber(Errors));
          PrintACR('^0N. Uploads       : ^1'+FormatNumber(Uploads));
          PrintACR('^0O. Upload K      : ^1'+FormatNumber(UK));
          PrintACR('^0P. DownLoads     : ^1'+FormatNumber(DownLoads));
          PrintACR('^0R. Download K    : ^1'+FormatNumber(DK));
          PrintACR('^0S. Baud Rates');
        END;
        IF (NOT Editing) THEN
          CmdStr := 'ABCDEGHIKMNOPRS'
        ELSE
          CmdStr := 'ABCDEGHIKMNOPRS[]FJL';
        InputChar('%LFModify menu [^1?^2=^1Help^2]: ',Cmd1,'Q?'+CmdStr+^M,[CapAll]);
        CASE Cmd1 OF
          'A' : IF (PD2Date(Date) = DateStr) THEN
                BEGIN
                  Print('%LF^8The current history date can not be changed!^0');
                  PauseScr(FALSE);
                END
                ELSE
                BEGIN
                  REPEAT
                    Ok := TRUE;
                    LocateHistoryDate('%LFNew history date: ',TempHistory1,DateToLocate,RecNum,FALSE,FALSE);
                    IF (DateToLocate <> '') AND (NOT (DateToLocate = PD2Date(History.Date))) THEN
                    BEGIN
                      IF (RecNum <> -1) THEN
                      BEGIN
                        Print('%LF^8The date entered is invalid!^0');
                        Ok := FALSE;
                      END
                      ELSE IF (DayNum(DateToLocate) > DayNum(DateStr)) THEN
                      BEGIN
                        Print('%LF^8The date can not be changed to a future date!^0');
                        Ok := FALSE;
                      END
                      ELSE IF (DateToLocate <> '') THEN
                      BEGIN
                        Date := Date2PD(DateToLocate);
                        Changed := TRUE;
                      END;
                    END;
                  UNTIL (Ok) OR (HangUp);
                END;
          'B' : InputLongInt('%LFNew minutes active for this date',Active,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'C' : InputLongInt('%LFNew number of system callers for this date',Callers,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'D' : BEGIN
                  Print('%LF^8This is for internal use only.');
                  PauseScr(FALSE);
                END;
          'E' : InputLongInt('%LFNew new user''s for this date',NewUsers,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'G' : BEGIN
                  Print('%LF^8This is for internal use only.');
                  PauseScr(FALSE);
                END;
          'H' : InputLongInt('%LFNew public message post''s this date',Posts,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'I' : InputLongInt('%LFNew private message post''s this date',Email,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'K' : InputLongInt('%LFNew sysop feedback sent this date',FeedBack,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'M' : InputLongInt('%LFNew system error''s this date',Errors,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'N' : InputLongInt('%LFNew user upload''s for this date',Uploads,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'O' : InputLongInt('%LFNew user kbytes uploaded this date',UK,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'P' : InputLongInt('%LFNew user download''s this date',Downloads,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'R' : InputLongInt('%LFNew user kbytes downloaded this date',DK,
                               [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'S' : BEGIN
                  REPEAT
                    Print('%CL^1User Baud Rates');
                    Print('%LF'+PadLeftStr('^0A. Telnet/Other: ^1'+FormatNumber(UserBaud[0]),32)+
                          '^0B. 300 Baud    : ^1'+IntToStr(UserBaud[1]));
                    Print(PadLeftStr('^0C. 600 Baud    : ^1'+IntToStr(UserBaud[2]),32)+
                          '^0D. 1200 Baud   : ^1'+FormatNumber(UserBaud[3]));
                    Print(PadLeftStr('^0E. 2400 Baud   : ^1'+FormatNumber(UserBaud[4]),32)+
                          '^0F. 4800 Baud   : ^1'+FormatNumber(UserBaud[5]));
                    Print(PadLeftStr('^0G. 7200 Baud   : ^1'+FormatNumber(UserBaud[6]),32)+
                          '^0H. 9600 Baud   : ^1'+FormatNumber(UserBaud[7]));
                    Print(PadLeftStr('^0I. 12000 Baud  : ^1'+FormatNumber(UserBaud[8]),32)+
                          '^0J. 14400 Baud  : ^1'+FormatNumber(UserBaud[9]));
                    Print(PadLeftStr('^0K. 16800 Baud  : ^1'+FormatNumber(UserBaud[10]),32)+
                          '^0L. 19200 Baud  : ^1'+FormatNumber(UserBaud[11]));
                    Print(PadLeftStr('^0M. 21600 Baud  : ^1'+FormatNumber(UserBaud[12]),32)+
                          '^0N. 24000 Baud  : ^1'+FormatNumber(UserBaud[13]));
                    Print(PadLeftStr('^0O. 26400 Baud  : ^1'+FormatNumber(UserBaud[14]),32)+
                          '^0P. 28800 Baud  : ^1'+FormatNumber(UserBaud[15]));
                    Print(PadLeftStr('^0Q. 31200 Baud  : ^1'+FormatNumber(UserBaud[16]),32)+
                          '^0R. 33600 Baud  : ^1'+FormatNumber(UserBaud[17]));
                    Print(PadLeftStr('^0S. 38400 Baud  : ^1'+FormatNumber(UserBaud[18]),32)+
                          '^0T. 57600 Baud  : ^1'+FormatNumber(UserBaud[19]));
                    Print(PadLeftStr('^0U. 115200 Baud : ^1'+FormatNumber(UserBaud[20]),32));
                    InputChar('%LFModify menu [^1A^2-^1U^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEFGHIJKLMNOPQRSTU',[CapAll]);
                    IF (Cmd1 <> ^M) THEN
                      InputLongInt('%LFNew value',UserBaud[Ord(Cmd1) - 65],
                                     [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit > 1) THEN
                   Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '[' : IF (RecNumToEdit < NumHistoryDates) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> NumHistoryDates) THEN
                  RecNumToEdit := NumHistoryDates
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  RecNumToEdit := -1;
                  InputInteger('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumHistoryDates,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumHistoryDates) THEN
                  BEGIN
                    RecNumToEdit := SaveRecNumToEdit;
                    Cmd1 := #0;
                  END
                  ELSE
                    RecNumToEdit := ((NumHistoryDates - RecNumToEdit) + 1);
                END;
          'L' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^0<^1CR^0>Redisplay current screen');
                  Print('^1A^0-^1E^0,^1G^0-^1I^0,^1K^0,^1M^0-^1P^0,^1R^0-^1S^0:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,3,'Quit and save','')
                  ELSE
                  BEGIN
                    LCmds(20,3,'[Back entry',']Forward entry');
                    LCmds(20,3,'First entry in list','Jump to entry');
                    LCmds(20,3,'Last entry in list','Quit and save');
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertHistoryRecord(TempHistory1: HistoryRecordType; Cmd1: Char; RecNumToInsertBefore: Integer);
  VAR
    DateToInsert,
    DateToInsertBefore: Str10;
    RecNum,
    RecNum1,
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumHistoryDates = MaxHistoryDates) THEN
      Messages(5,MaxHistoryDates,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to insert before: ',TempHistory1,DateToInsertBefore,RecNumToInsertBefore,TRUE,TRUE);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumHistoryDates + 1)) THEN
      BEGIN
        LocateHistoryDate('%LFNew history date to insert: ',TempHistory1,DateToInsert,RecNum1,FALSE,TRUE);
        IF (RecNum1 <> -1) THEN
        BEGIN
          Print('%LF^8Duplicate date entered!^0');
          PauseScr(FALSE);
        END
        ELSE IF (DayNum(DateToInsert) > DayNum(DateStr)) THEN
        BEGIN
          Print('%LF^8Future dates can not be entered!^0');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          IF (DayNum(DateToInsert) > DayNum(DateToInsertBefore)) THEN
            Inc(RecNumToInsertBefore);
          Reset(HistoryFile);
          InitHistoryVars(TempHistory1);
          TempHistory1.Date := Date2PD(DateToInsert);
          IF (RecNumToInsertBefore = 1) THEN
            RecNum1 := 0
          ELSE IF (RecNumToInsertBefore = NumHistoryDates) THEN
            RecNum1 := (RecNumToInsertBefore - 1)
          ELSE
            RecNum1 := RecNumToInsertBefore;
          REPEAT
            OK := TRUE;
            EditHistoryRecord(TempHistory1,TempHistory1,Cmd1,RecNum1,SaveRecNumToEdit,Changed,FALSE);
            CheckHistoryRecord(TempHistory1,1,1,Ok);
            IF (NOT OK) THEN
              IF (NOT PYNQ('%LFContinue inserting history date? ',0,TRUE)) THEN
                Abort := TRUE;
          UNTIL (OK) OR (Abort) OR (HangUp);
          IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
          BEGIN
            Print('%LF[> Inserting history record ...');
            Seek(HistoryFile,FileSize(HistoryFile));
            Write(HistoryFile,History);
            Dec(RecNumToInsertBefore);
            FOR RecNum := ((FileSize(HistoryFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
            BEGIN
              Seek(HistoryFile,RecNum);
              Read(HistoryFile,History);
              Seek(HistoryFile,(RecNum + 1));
              Write(HistoryFile,History);
            END;
            FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
            BEGIN
              Seek(HistoryFile,RecNum);
              Write(HistoryFile,TempHistory1);
              Inc(NumHistoryDates);
              SysOpLog('* Inserted history date: ^1'+PD2Date(TempHistory1.Date));
            END;
          END;
          Close(HistoryFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ModifyHistoryRecord(TempHistory1: HistoryRecordType; Cmd1: Char; RecNumToEdit: Integer);
  VAR
    DateToEdit: Str10;
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumHistoryDates = 0) THEN
      Messages(4,0,'history dates')
    ELSE
    BEGIN
      LocateHistoryDate('%LFHistory date to modify: ',TempHistory1,DateToEdit,RecNumToEdit,TRUE,TRUE);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumHistoryDates) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(HistoryFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(HistoryFile,(RecNumToEdit - 1));
            Read(HistoryFile,History);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditHistoryRecord(TempHistory1,History,Cmd1,RecNumToEdit,SaveRecNumToEdit,Changed,TRUE);
            CheckHistoryRecord(History,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(HistoryFile,(SaveRecNumToEdit - 1));
            Write(HistoryFile,History);
            Changed := FALSE;
            SysOpLog('* Modified history date: ^1'+PD2Date(History.Date));
          END;
        END;
        Close(HistoryFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ListHistoryDates(VAR RecNumToList1: Integer);
  VAR
    TempStr: AStr;
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumHistoryDates) THEN
      RecNumToList1 := NumHistoryDates;
    Abort := FALSE;
    Next := FALSE;
    CLS;
    PrintACR('^1        ^2:^1Mins ^2:^1    ^2:^1      ^2:^1#New^2:^1Tim/^2:^1Pub ^2:^1Priv^2:^1Feed^2:^1    ^2:^1'+
             '    ^2:^1     ^2:^1    ^2:^1');
    PrintACR('^1  Date  ^2:^1Activ^2:^1Call^2:^1%Activ^2:^1User^2:^1User^2:^1Post^2:^1Post'+
             '^2:^1Back^2:^1Errs^2:^1#ULs^2:^1UL-k ^2:^1#DLs^2:^1DL-k');
    PrintACR('^2========:=====:====:======:====:====:====:====:====:====:====:=====:====:=====');
    Reset(HistoryFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 6)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumHistoryDates)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(HistoryFile,(RecNumToList1 - 1));
      Read(HistoryFile,History);
      WITH History DO
      BEGIN
        IF (Callers > 0) THEN
          TempStr := PadRightInt(Active DIV Callers,4)
        ELSE
          TempStr := '    ';
        PrintACR('^0'+AOnOff((RecNumToList1 = NumHistoryDates),'Today''s ',ToDate8(PD2Date(Date)))+
                 ' '+PadRightInt(Active,5)+
                 ' '+PadRightInt(Callers,4)+
                 ' '+CTP(Active,1440)+
                 ' '+PadRightInt(NewUsers,4)+
                 ' '+TempStr+
                 ' '+PadRightInt(Posts,4)+
                 ' '+PadRightInt(EMail,4)+
                 ' '+PadRightInt(FeedBack,4)+
                 ' '+PadRightInt(Errors,4)+
                 ' '+PadRightInt(Uploads,4)+
                 ' '+PadRightInt(UK,5)+
                 ' '+PadRightInt(DownLoads,4)+
                 ' '+PadRightInt(DK,5));
      END;
      Dec(RecNumToList1);
      Inc(NumDone);
    END;
    Close(HistoryFile);
    LastError := IOResult;
    IF (NumHistoryDates = 0) THEN
      Print('*** No history dates defined ***');
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  Assign(HistoryFile,General.DataPath+'HISTORY.DAT');
  Reset(HistoryFile);
  NumHistoryDates := FileSize(HistoryFile);
  Close(HistoryFile);
  RecNumToList := NumHistoryDates;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListHistoryDates(RecNumToList);
    InputChar('%LFHistory editor [^1?^2=^1Help^2]: ',Cmd,'QDIM?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumHistoryDates) THEN
              RecNumToList := NumHistoryDates;
      'D' : DeleteHistoryRecord(TempHistory,RecNumToList);
      'I' : InsertHistoryRecord(TempHistory,Cmd,RecNumToList);
      'M' : ModifyHistoryRecord(TempHistory,Cmd,RecNumToList);
      '?' : BEGIN
              Print('%LF^0<^1CR^0>Next screen or redisplay current screen');
              Print('^0(^1?^0)Help/First history date');
              LCmds(20,3,'Delete history date','Insert history date');
              LCmds(20,3,'Modify history date','Quit');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := NumHistoryDates;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
