{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 [DONE]
 02/16/2023 - Aesthetic changes
            - DL/UL size now in most reasonable units, not always kB
 03/09/2023 - Error messages now using Messages procedure
 01/27/2024 - Indented
 [TO·DO]
 - Add pagination
}
UNIT SysOp5; { History Editor }

INTERFACE

PROCEDURE HistoryEditor;

IMPLEMENTATION

USES
  Common,
  SysOp2, {ConfigHeader}
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

(*
  PROCEDURE CheckHistoryRecord(History: HistoryRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : ;
      END;
  END;
*)

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
            IF (Editing) THEN
              ConfigHeader('Editing History Record',(NumHistoryDates+1)-RecNumToEdit,NumHistoryDates)
            ELSE
              ConfigHeader('Inserting History Record',(NumHistoryDates+1)-RecNumToEdit,NumHistoryDates+1);
            IF (Callers > 0) THEN
              TempStr1 := IntToStr(Active DIV Callers)
            ELSE
              TempStr1 := '0';
              PrintACR('^0(^1A^0) Date           : ^1'+PD2Date(Date)+AOnOff(RecNumToEdit = NumHistoryDates,' (Today)',''));
              PrintACR('^0(^1B^0) Minutes Active : ^1'+FormatNumber(Active));
              PrintACR('^0(^1C^0) Calls          : ^1'+FormatNumber(Callers));
              PrintACR('^0(^1D^0) Percent Active : ^1'+SQOutSp(CTP(Active,1440)));
              PrintACR('^0(^1E^0) New Users      : ^1'+FormatNumber(NewUsers));
              PrintACR('^0(^1F^0) Time/User      : ^1'+TempStr1);
              PrintACR('^0(^1G^0) Public Posts   : ^1'+FormatNumber(Posts));
              PrintACR('^0(^1H^0) Private Posts  : ^1'+FormatNumber(EMail));
              PrintACR('^0(^1I^0) SysOp Feedback : ^1'+FormatNumber(FeedBack));
              PrintACR('^0(^1J^0) Errors         : ^1'+FormatNumber(Errors));
              PrintACR('^0(^1K^0) Uploads        : ^1'+FormatNumber(Uploads));
              PrintACR('^0(^1L^0) Uploaded xB    : ^1'+ConvertKB(UK,FALSE));
              PrintACR('^0(^1M^0) Downloads      : ^1'+FormatNumber(DownLoads));
              PrintACR('^0(^1N^0) Downloaded xB  : ^1'+ConvertKB(DK,FALSE));
              PrintACR('^0(^1O^0) Baud Rates ...');
          END;
        IF (NOT Editing) THEN
          CmdStr := 'ABCDEFGHIJKLMNO'
        ELSE
          CmdStr := 'ABCDEFGHIJKLMNO[]{};';
        NL;
        InputChar('^2History Editor [^1A^2-^1O^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'Q?'+CmdStr+^M,[CapAll]);
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
          'F' : BEGIN
                  Print('%LF^8This is for internal use only.');
                  PauseScr(FALSE);
                END;
          'G' : InputLongInt('%LFNew public message post''s this date',Posts,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'H' : InputLongInt('%LFNew private message post''s this date',Email,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'I' : InputLongInt('%LFNew sysop feedback sent this date',FeedBack,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'J' : InputLongInt('%LFNew system error''s this date',Errors,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'K' : InputLongInt('%LFNew user upload''s for this date',Uploads,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'L' : InputLongInt('%LFNew user kbytes uploaded this date',UK,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'M' : InputLongInt('%LFNew user download''s this date',Downloads,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'N' : InputLongInt('%LFNew user kbytes downloaded this date',DK,
                             [InteractiveEdit{,DisplayValue},NumbersOnly],0,2147483647,Changed);
          'O' : BEGIN
                  REPEAT
                    ConfigHeader('User Baud Rates',0,0);
                    Print(PadLeftStr('^0(^1A^0) Telnet/Other : ^1'+FormatNumber(UserBaud[0]),39)+
                                     '^0(^1B^0) 300 Baud     : ^1'+FormatNumber(UserBaud[1]));
                    Print(PadLeftStr('^0(^1C^0) 600 Baud     : ^1'+FormatNumber(UserBaud[2]),39)+
                                     '^0(^1D^0) 1200 Baud    : ^1'+FormatNumber(UserBaud[3]));
                    Print(PadLeftStr('^0(^1E^0) 2400 Baud    : ^1'+FormatNumber(UserBaud[4]),39)+
                                     '^0(^1F^0) 4800 Baud    : ^1'+FormatNumber(UserBaud[5]));
                    Print(PadLeftStr('^0(^1G^0) 7200 Baud    : ^1'+FormatNumber(UserBaud[6]),39)+
                                     '^0(^1H^0) 9600 Baud    : ^1'+FormatNumber(UserBaud[7]));
                    Print(PadLeftStr('^0(^1I^0) 12000 Baud   : ^1'+FormatNumber(UserBaud[8]),39)+
                                     '^0(^1J^0) 14400 Baud   : ^1'+FormatNumber(UserBaud[9]));
                    Print(PadLeftStr('^0(^1K^0) 16800 Baud   : ^1'+FormatNumber(UserBaud[10]),39)+
                                     '^0(^1L^0) 19200 Baud   : ^1'+FormatNumber(UserBaud[11]));
                    Print(PadLeftStr('^0(^1M^0) 21600 Baud   : ^1'+FormatNumber(UserBaud[12]),39)+
                                     '^0(^1N^0) 24000 Baud   : ^1'+FormatNumber(UserBaud[13]));
                    Print(PadLeftStr('^0(^1O^0) 26400 Baud   : ^1'+FormatNumber(UserBaud[14]),39)+
                                     '^0(^1P^0) 28800 Baud   : ^1'+FormatNumber(UserBaud[15]));
                    Print(PadLeftStr('^0(^1Q^0) 31200 Baud   : ^1'+FormatNumber(UserBaud[16]),39)+
                                     '^0(^1R^0) 33600 Baud   : ^1'+FormatNumber(UserBaud[17]));
                    Print(PadLeftStr('^0(^1S^0) 38400 Baud   : ^1'+FormatNumber(UserBaud[18]),39)+
                                     '^0(^1T^0) 57600 Baud   : ^1'+FormatNumber(UserBaud[19]));
                    Print(PadLeftStr('^0(^1U^0) 115200 Baud  : ^1'+FormatNumber(UserBaud[20]),39));
                    NL;
                    InputChar('User Baud Rates [^1A^2-^1U^2,<^1CR^2>Quit]: ',Cmd1,^M'ABCDEFGHIJKLMNOPQRSTU',[CapAll]);
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
          '{' : IF (RecNumToEdit <> NumHistoryDates) THEN
                  RecNumToEdit := NumHistoryDates
                ELSE
                  BEGIN
                    Messages(2,0,'');
                    Cmd1 := #0;
                  END;
          '}' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                  BEGIN
                    Messages(3,0,'');
                    Cmd1 := #0;
                  END;
          ';' : BEGIN
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
          '?' : BEGIN
                  IF (NOT Editing) THEN
                    Cmd1 := #0 {LCmds(16,1,'Quit/Save','')}
                  ELSE
                    BEGIN
                      NL;
                      LCmds(17,1,'[Previous Record',']Next Record');
                      LCmds(17,1,'{First Record','}Last Record');
                      LCmds(17,1,';Jump To Record','')
                    END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]{};') <> 0) OR (HangUp);
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
                  {CheckHistoryRecord(TempHistory1,1,1,Ok);}
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
                  {CheckHistoryRecord(History,1,1,Ok);}
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
    PrintACR('^5ÚÄÄÄÄÄÄÄÄÂ^4Mins^5ÂÄÄÄÄÂ^4%^5ÄÄÄÂ^4New^5ÄÂ^4Time^5Â^4Pub^5ÄÂ^4Prv^5ÄÂ'+
             '^4Feed^5ÂÄÄÄÄÂ^4#^5ÄÄÄÂ^4xB^5ÄÄÄÄÂ^4#^5ÄÄÄÂ^4xB^5ÄÄÄÄ¿');
    PrintACR('^5À^4MM^5Ä^4DD^5Ä^4YY^5Á^4Actv^5Á^4Call^5Á^4Actv^5Á^4User^5Á^4User^5Á^4Post^5Á^4Post^5Á'+
             '^4Back^5Á^4Errs^5Á^4UL^5ÄÄÁ^4UL^5ÄÄÄÄÁ^4DL^5ÄÄÁ^4DL^5ÄÄÄÄÙ');
    NL;
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
              TempStr := '   0';
            PrintACR(' ^1'+AOnOff((RecNumToList1 = NumHistoryDates),'Today   ',ToDate8(PD2Date(Date)))+'^0'+
                     ' '+PadRightInt(Active,4)+
                     ' '+PadRightInt(Callers,4)+
                     ' '+PadRightStr(SQOutSp(CTP(Active,1440)),4)+
                     ' '+PadRightInt(NewUsers,4)+
                     ' '+TempStr+ {LeeW: Use AOnOff?}
                     ' '+PadRightInt(Posts,4)+
                     ' '+PadRightInt(EMail,4)+
                     ' '+PadRightInt(FeedBack,4)+
                     ' '+PadRightInt(Errors,4)+
                     ' '+PadRightInt(Uploads,4)+
                     ' '+PadRightStr(AOnOff(UK=0,'0',AllCaps(ConvertKB(UK,TRUE))),6)+
                     ' '+PadRightInt(Downloads,4)+
                     ' '+PadRightStr(AOnOff(UK=0,'0',AllCaps(ConvertKB(DK,TRUE))),6));
          END;
        Dec(RecNumToList1);
        Inc(NumDone);
      END;
    Close(HistoryFile);
    LastError := IOResult;
    IF (NumHistoryDates = 0) THEN
      Messages(4,0,'history dates'); { "No history dates exist!" }
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
    NL;
    InputChar('History Editor [^1DIM^2,(^1?^2)Help,<^1CR^2>Page,(^1Q^2)uit]: ',Cmd,'QDIM?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumHistoryDates) THEN
              RecNumToList := NumHistoryDates;
      'D' : DeleteHistoryRecord(TempHistory,RecNumToList);
      'I' : InsertHistoryRecord(TempHistory,Cmd,RecNumToList);
      'M' : ModifyHistoryRecord(TempHistory,Cmd,RecNumToList);
      '?' : BEGIN
              NL;
              LCmds3(20,1,'Delete History Date','Insert History Date','Modify History Date');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := NumHistoryDates;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.