{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
change info showed in list... no warn, maybe 
}
UNIT SysOp6;

INTERFACE

PROCEDURE EventEditor;

IMPLEMENTATION

USES
  Common,
  SysOp2, {ConfigHeader}
  TimeFunc;

PROCEDURE EventEditor;
VAR
  TempEvent: EventRecordType;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DaysEventActive(EventDays: EventDaysType; C1,C2: Char): AStr;
  CONST
    Days: Str7 = 'SMTWTFS';
  VAR
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    TempStr := '';
    FOR Counter := 0 TO 6 DO
     IF (Counter IN EventDays) THEN
       TempStr := TempStr + '^'+C1+Days[Counter + 1]
     ELSE
       TempStr := TempStr + '^'+C2+'-';
    DaysEventActive := TempStr;
  END;

  FUNCTION NextDay(Date: Str10): LongInt;
  VAR
    Day,
    Month,
    Year: Word;
  BEGIN
    Month := StrToInt(Copy(Date,1,2));
    Day := StrToInt(Copy(Date,4,2));
    Year := StrToInt(Copy(Date,7,4));
    IF (Day = 31) AND (Month = 12) THEN
    BEGIN
      Inc(Year);
      Month := 1;
      Day := 1;
    END
    ELSE
    BEGIN
      IF (Day < Days(Month,Year)) THEN
        Inc(Day)
      ELSE IF (Month < 12) THEN
      BEGIN
        Inc(Month);
        Day := 1;
      END;
    END;
    NextDay := Date2PD(ZeroPad(IntToStr(Month))+'/'+ZeroPad(IntToStr(Day))+'/'+IntToStr(Year));
  END;

  FUNCTION ShowTime(W: Word): Str5;
  BEGIN
    ShowTime := ZeroPad(IntToStr(W DIV 60))+':'+ZeroPad(IntToStr(W MOD 60));
  END;

  PROCEDURE ToggleEFlag(EFlagT: EventFlagType; VAR EFlags: EFlagSet);
  BEGIN
    IF (EFlagT IN EFlags) THEN
      Exclude(EFlags,EFlagT)
    ELSE
      Include(EFlags,EFlagT);
  END;

  PROCEDURE ToggleEFlags(C: Char; VAR EFlags: EFlagSet; VAR Changed: Boolean);
  VAR
    SaveEFlags: EFlagSet;
  BEGIN
    SaveEFlags := EFlags;
    CASE C OF
      'A' : ToggleEFlag(EventIsExternal,EFlags);
      'B' : ToggleEFlag(EventIsActive,EFlags);
      'C' : ToggleEFlag(EventIsShell,EFlags);
      'D' : ToggleEFlag(EventIsOffhook,EFlags);
      'E' : ToggleEFlag(EventIsMonthly,EFlags);
      'F' : ToggleEFlag(EventIsPermission,EFlags);
      'G' : ToggleEFlag(EventIsLogon,EFlags);
      'H' : ToggleEFlag(EventIsChat,EFlags);
      'I' : ToggleEFlag(EventIsPackMsgAreas,EFlags);
      'J' : ToggleEFlag(EventIsSortFiles,EFlags);
      'K' : ToggleEFlag(EventIsSoft,EFlags);
      'L' : ToggleEFlag(EventIsMissed,EFlags);
      'M' : ToggleEFlag(BaudIsActive,EFlags);
      'N' : ToggleEFlag(AcsIsActive,EFlags);
      'O' : ToggleEFlag(TimeIsActive,EFlags);
      'P' : ToggleEFlag(ARisActive,EFlags);
      'Q' : ToggleEFlag(SetARisActive,EFlags);
      'R' : ToggleEFlag(ClearARisActive,EFlags);
      'S' : ToggleEFlag(InRatioIsActive,EFlags);
    END;
    IF (EFlags <> SaveEFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitEventVars(VAR Event: EventRecordType);
  BEGIN
    FillChar(Event,SizeOf(Event),0);
    WITH Event DO
    BEGIN
      EventDescription := '<< New Event >>';
      EventDayOfMonth := 0;
      EventDays := [];
      EventStartTime := 0;
      EventFinishTime := 0;
      EventQualMsg := '';
      EventNotQualMsg := '';
      EventPreTime := 0;
      EventNode := 0;
      EventLastDate := 0;
      EventErrorLevel := 0;
      EventShellPath := '';
      LoBaud := 300;
      HiBaud := 19200;
      EventACS := 's10';
      MaxTimeAllowed := 60;
      SetARflag := '@';
      ClearARflag := '@';
      EFlags := [EventIsExternal,EventIsShell];
    END;
  END;

  PROCEDURE DeleteEvent(TempEvent1: EventRecordType; RecNumToDelete: Integer);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFEvent to delete?',RecNumToDelete,[NumbersOnly],1,NumEvents,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumEvents) THEN
      BEGIN
        Reset(EventFile);
        Seek(EventFile,(RecNumToDelete - 1));
        Read(EventFile,TempEvent1);
        Close(EventFile);
        LastError := IOResult;
        Print('%LFEvent: ^1'+TempEvent1.EventDescription);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting event record ...');
          Dec(RecNumToDelete);
          Reset(EventFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(EventFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(EventFile) - 2) DO
            BEGIN
              Seek(EventFile,(RecNum + 1));
              Read(EventFile,Event);
              Seek(EventFile,RecNum);
              Write(EventFile,Event);
            END;
          Seek(EventFile,(FileSize(EventFile) - 1));
          Truncate(EventFile);
          Close(EventFile);
          LastError := IOResult;
          Dec(NumEvents);
          SysOpLog('* Deleted event: ^1'+TempEvent1.EventDescription);
        END;
      END;
    END;
  END;

  PROCEDURE CheckEvent(Event: EventRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : ;
      END;
  END;

  PROCEDURE EditEvent(TempEvent1: EventRecordType; VAR Event: EventRecordType; VAR Cmd1: Char;
                      VAR RecNumToEdit: Integer; VAR Changed: Boolean; Editing: Boolean);
  CONST
    BaudRates: ARRAY [1..20] OF LongInt = (300,   600,  1200,  2400,  4800,  7200,  9600, 12000,
                                         14400, 16800, 19200, 21600, 24000, 26400, 28800, 31200,
                                         33600, 38400, 57600, 115200);
  VAR
    OneKCmds,
    TempStr: AStr;
    Counter: Byte;
  BEGIN
    WITH Event DO
      REPEAT
        IF (Cmd1 <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            IF (Editing) THEN
              ConfigHeader('Editing Event #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumEvents))
            ELSE
              ConfigHeader('Inserting Event #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumEvents + 1));
            PrintACR('^0(^1A^0) Event Type            : ^1'+AOnOff(EventIsExternal IN EFlags,'External','Internal'));
            PrintACR('^0(^1B^0) Description           : ^1'+EventDescription);
            PrintACR('^0(^1C^0) Active                : ^1'+AOnOff(EventIsActive IN EFlags,'Active','Inactive'));
            IF (EventIsExternal IN EFlags) THEN
              BEGIN
                PrintACR('^0(^1D^0) Execution Type        : ^1'+AOnOff(EventIsSoft IN EFlags,'Soft','Hard'));
                TempStr := '^0(^1E^0) Event Type            : ^1';
                IF (EventIsErrorLevel IN EFlags) THEN
                  TempStr := TempStr + 'Error Level = '+IntToStr(EventErrorLevel)
                ELSE IF (EventIsShell IN EFlags) THEN
                  TempStr := TempStr + 'Shell File = "'+EventShellPath+'"'
                ELSE IF (EventIsSortFiles IN EFlags) THEN
                  TempStr := TempStr + 'Sort Files'
                ELSE IF (EventIsPackMsgAreas IN EFlags) THEN
                  TempStr := TempStr + 'Pack Message Areas'
                ELSE IF (EventIsFilesBBS IN EFlags) THEN
                  TempStr := TempStr + 'Check FILES.BBS';
                PrintACR(TempStr);
                PrintACR('^0(^1G^0) Scheduled Day(s)      : ^1'+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly: ^0-^1 Day ^0=^1 '+IntToStr(EventDayOfMonth),
                                                   'Weekly: ^0-^1 Days ^0=^1 '+DaysEventActive(EventDays,'5','1')));
                PrintACR('^0(^1H^0) Start Time            : ^1'+ShowTime(EventStartTime));
                PrintACR('^0(^1I^0) Phone Status          : ^1'+AOnOff(EventIsOffHook IN EFlags,
                                                   'Off-hook ('+IntToStr(EventPreTime)+' minutes before the event)',
                                                   'Remain on-hook'));
                PrintACR('^0(^1K^0) Executed Today?       : ^1'+ShowYesNo(PD2Date(EventLastDate) = DateStr)+' '
                                                   +AOnOff(EventIsActive IN EFlags,
                                                   '(Next scheduled date: '+PD2Date(EventLastDate)+')',
                                                   '(Not scheduled)'));
              END
            ELSE
              BEGIN { Internal event }
                PrintACR('^0(^1D^0) Scheduled Day(s)      : '+AOnOff(EventIsMonthly IN EFlags,
                                                   'Monthly: ^1 '+IntToStr(EventDayOfMonth),
                                                   'Weekly: ^1'+DaysEventActive(EventDays,'5','1')));
                PrintACR('^0(^1E^0) Time Active           : ^1'+ShowTime(EventStartTime)+' to '+
                                                   ShowTime(EventFinishTime));
                PrintACR('^0(^1G^0) Permission/Restriction: ^1'+AOnOff(EventIsPermission IN EFlags,
                                                   'Permission','Restriction'));
                PrintACR('^0(^1H^0) Event Type            : ^1'+AOnOff(EventIsChat IN EFlags,'Chat','Logon'));
                PrintACR('^0(^1I^0) Affected Message      : "^1'+eventqualmsg+'^0"');
                PrintACR('^0(^1K^0) Unaffected Message    : "^1'+eventnotqualmsg+'^0"');
              END;
            PrintACR('^0(^1M^0) Run If Missed?        : ^1'+ShowYesNo(EventIsMissed IN EFlags));
            PrintACR('^0(^1N^0) Node Number           : ^1'+IntToStr(EventNode));
            IF (NOT (EventIsExternal IN EFlags)) THEN
              BEGIN
                NL;
                PrintACR('       ^2<<<^1 Qualifiers ^2>>>');
                NL;
                PrintACR('^0(^11^0) Baud rate range  : ^1'+AOnOff(BaudIsActive IN EFlags,
                                                                  IntToStr(LoBaud)+' to '+IntToStr(HiBaud),
                                                                  '<<Inactive>>'));
                PrintACR('^0(^12^0) ACS              : ^1'+AOnOff(ACSIsActive IN EFlags,EventACS,'<<Inactive>>'));
                IF (EventIsPermission IN EFlags) THEN
                  PrintACR('^0(^13^0) Maximum time     : ^1'+AOnOff(TimeIsActive IN EFlags,
                                                IntToStr(MaxTimeAllowed),'<<Inactive>>'));
                IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    PrintACR('^0(^14^0) Set AR flag      : ^1'+AOnOff(SetArIsActive IN EFlags,
                                                SetArFlag,'<<Inactive>>'));
                    PrintACR('^0(^15^0) Clear AR flag    : ^1'+AOnOff(ClearArIsActive IN EFlags,
                                                ClearArFlag,'<<Inactive>>'));
                  END;
                PrintACR('^0(^16^0) UL/DL ratio check: ^1'+AOnOff(InRatioIsActive IN EFlags,
                                              'Active','<<Inactive>>'));
              END;
          END;
        IF (EventIsExternal IN EFlags) THEN
          OneKCmds := ''
        ELSE
          BEGIN
            IF (EventIsPermission IN EFlags) THEN
              OneKCmds := '123456'
            ELSE
              OneKCmds := '126';
          END;
        NL;
        InputChar('^2Modify '+AOnOff(EventIsExternal IN EFlags,'External','Internal')+' Event [(^1?^2)Help,(^1Q^2)uit]: ',
              Cmd1,'QABCDEGHIKMN'+OneKCmds+'[]FJL?'^M,[CapAll]);
        CASE Cmd1 OF
          'A' : ToggleEFlagS('A',EFlags,Changed);  { External/Internal }
          'B' : InputString('%LFNew description: ',EventDescription,30,[InterActiveEdit],Changed);
          'C' : ToggleEFlags('B',EFlags,Changed);  { Active/InActive }
          'D' : IF (EventIsExternal IN EFlags) THEN
                  ToggleEFlags('K',EFlags,Changed) { Soft/Hard }
                ELSE                               { Daily/Monthly }
                  BEGIN
                    InputChar('%LFSchedule? [^1D^2=^1Daily^2,^1M^2=^1Monthly^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'DM',[CapAll]);
                    CASE Cmd1 OF
                      'D' : BEGIN
                              IF (EventIsMonthly IN EFlags) THEN
                                BEGIN
                                  Exclude(EFlags,EventIsMonthly);
                                  EventDayOfMonth := 0;
                                  Changed := TRUE;
                                END;
                              REPEAT
                                Print('%LF^1Active Days: ^1'+DaysEventActive(EventDays,'5','4')+'^0');
                                NL;
                                LCmds(11,1,'1 Sunday','');
                                LCmds(11,1,'2 Monday','');
                                LCmds(11,1,'3 Tuesday','');
                                LCmds(11,1,'4 Wednesday','');
                                LCmds(11,1,'5 Thursday','');
                                LCmds(11,1,'6 Friday','');
                                LCmds(11,1,'7 Saturday','');
                                InputChar('%LFToggle which day? [^11^2-^17^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'1234567',[CapAll]);
                                IF (Cmd1 <> ^M) THEN
                                  BEGIN
                                    IF ((StrToInt(Cmd1) - 1) IN EventDays) THEN
                                      Exclude(EventDays,(StrToInt(Cmd1) - 1))
                                    ELSE
                                      Include(EventDays,(StrToInt(Cmd1) - 1));
                                    Changed := TRUE;
                                  END;
                              UNTIL (Cmd1 = ^M) OR (HangUp);
                            Cmd1 := #0;
                          END;
                    'M' : BEGIN
                            IF (NOT (EventIsMonthly IN EFlags)) THEN
                            BEGIN
                              Include(EFlags,EventIsMonthly);
                              EventDays := [];
                              Changed := TRUE;
                            END;
                            InputByte('%LFDay of the month',EventDayOfMonth,[],1,31,Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          'E' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  Print('%LF^1External event type');
                  NL;
                  LCmds(18,1,'1Errorlevel','');
                  LCmds(18,1,'2Shell','');
                  LCmds(18,1,'3Sort Files','');
                  LCmds(18,1,'4Pack Message Areas','');
                  LCmds(18,1,'5Files.BBS','');
                  InputChar('%LFWhich external event? [^11^2-^15^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'12345',[CapAll]);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    CASE Cmd1 OF
                      '1' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsErrorLevel);
                              InputByte('%LFError Level',EventErrorLevel,[],0,255,Changed);
                            END;
                      '2' : BEGIN
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsShell);
                              InputString('%LFShell file: ',EventShellPath,8,[CapAll],Changed);
                            END;
                      '3' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsSortFiles);
                            END;
                      '4' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsFilesBBS IN EFlags) THEN
                                Exclude(EFlags,EventIsFilesBBS);
                              Include(EFlags,EventIsPackMsgAreas);
                            END;
                      '5' : BEGIN
                              IF (EventIsShell IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsShell);
                                EventShellPath := '';
                              END;
                              IF (EventIsErrorLevel IN EFlags) THEN
                              BEGIN
                                Exclude(EFlags,EventIsErrorLevel);
                                EventErrorLevel := 0;
                              END;
                              IF (EventIsSortFiles IN EFlags) THEN
                                Exclude(EFlags,EventIsSortFiles);
                              IF (EventIsPackMsgAreas IN EFlags) THEN
                                Exclude(EFlags,EventIsPackMsgAreas);
                              Include(EFlags,EventIsFilesBBS);
                            END;
                    END;
                    Changed := TRUE;
                  END;
                  Cmd1 := #0;
                END
                ELSE
                BEGIN
                  Prt('%LFNew event start time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventStartTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^1Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                  Prt('%LFNew event finish time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventFinishTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^1Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                END;
          'G' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  InputChar('%LFSchedule? [^1D^2=^1Daily^2,^1M^2=^1Monthly^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'DM',[CapAll]);
                  CASE Cmd1 OF
                    'D' : BEGIN
                            IF (EventIsMonthly IN EFlags) THEN
                            BEGIN
                              Exclude(EFlags,EventIsMonthly);
                              EventDayOfMonth := 0;
                              Changed := TRUE;
                            END;
                            REPEAT
                              Print('%LF^1Active Days: ^1'+DaysEventActive(EventDays,'5','4')+'^0');
                              NL;
                              LCmds(11,1,'1Sunday','');
                              LCmds(11,1,'2Monday','');
                              LCmds(11,1,'3Tuesday','');
                              LCmds(11,1,'4Wednesday','');
                              LCmds(11,1,'5Thursday','');
                              LCmds(11,1,'6Friday','');
                              LCmds(11,1,'7Saturday','');
                              InputChar('%LFToggle which day? [^11^2-^17^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'1234567',[CapAll]);
                              IF (Cmd1 <> ^M) THEN
                              BEGIN
                                IF (StrToInt(Cmd1) - 1 IN EventDays) THEN
                                  Exclude(EventDays,StrToInt(Cmd1) - 1)
                                ELSE
                                  Include(EventDays,StrToInt(Cmd1) - 1);
                                Changed := TRUE;
                              END;
                            UNTIL (Cmd1 = ^M) OR (HangUp);
                            Cmd1 := #0;
                          END;
                    'M' : BEGIN
                            IF (NOT (EventIsMonthly IN EFlags)) THEN
                            BEGIN
                              Include(EFlags,EventIsMonthly);
                              EventDays := [];
                              Changed := TRUE;
                            END;
                            InputByte('%LFDay of the month',EventDayOfMonth,[],1,31,Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END
                ELSE
                BEGIN
                  ToggleEFlag(EventIsPermission,EFlags);
                  Changed := TRUE;
                END;
          'H' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  Prt('%LFNew event start time? (24 Hour Format) Hour: (0-23), Minute: (0-59): ');
                  InputFormatted('',TempStr,'##:##',TRUE);
                  IF (TempStr <> '') AND (Length(TempStr) = 5) AND (Pos(':',TempStr) = 3) THEN
                  BEGIN
                    IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
                    BEGIN
                      EventStartTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)));
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Print('%LF^1Invalid time - Format is HH:MM (24 hour military)');
                      PauseScr(FALSE);
                    END;
                  END;
                END
                ELSE
                BEGIN
                  Print('%LF^1Internal event type:');
                  NL;
                  LCmds(7,1,'1Logon','');
                  LCmds(7,1,'2Chat','');
                  InputChar('%LFWhich internal event? [^11^2-^12^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'12',[CapAll]);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    CASE Cmd1 OF
                      '1' : BEGIN
                              IF (EventIsChat IN EFlags) THEN
                                Exclude(EFlags,EventIsChat);
                              Include(EFlags,EventIsLogon);
                            END;
                      '2' : BEGIN
                              IF (EventIsLogon IN EFlags) THEN
                                Exclude(EFlags,EventIsLogon);
                              Include(EFlags,EventIsChat);
                            END;
                    END;
                    Changed := TRUE;
                  END;
                  Cmd1 := #0;
                END;
          'I' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  IF (EventIsOffHook IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,EventIsOffHook);
                    EventPreTime := 0;
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,EventIsOffHook);
                    InputByte('%LFMinutes before event to take phone offhook',EventPreTime,[],0,255,Changed);
                  END;
                END
                ELSE
                  InputString('%LF^0Message/@File if the user is effected by the event:%LF^2: ',EventQualMsg,64,[],Changed);
          'K' : IF (EventIsExternal IN EFlags) THEN
                BEGIN
                  IF (PD2Date(EventLastDate) = DateStr) THEN
                    EventLastDate := NextDay(PD2Date(EventLastDate))
                  ELSE
                    EventLastDate := Date2PD(DateStr);
                  Changed := TRUE;
                END
                ELSE
                  InputString('%LF^0Message/@File if the user IS NOT effected by the event:%LF^2: ',
                           EventNotQualMsg,64,[],Changed);
          'M' : BEGIN
                  IF PYNQ('%LFRun this event later if the event time is missed? ',0,FALSE) THEN
                    Include(EFlags,EventIsMissed)
                  ELSE
                    Exclude(EFlags,EventIsMissed);
                  Changed := TRUE;
                END;
          'N' : InputByte('%LFNode number to execute event from (0=All)',EventNode,
                            [InteractiveEdit{,DisplayValue},NumbersOnly],0,MaxNodes,Changed);
          '1' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (BaudIsActive IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,BaudIsActive);
                    LoBaud := 300;
                    HiBaud := 115200;
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,BaudIsActive);
                    Print('%LF^1Baud lower limit:^0%LF');
                    Counter := 1;
                    WHILE (Counter <= 20) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      PrintACR(Char(Counter + 64)+'. '+IntToStr(BaudRates[Counter]));
                      Inc(Counter);
                    END;
                    InputChar('%LFWhich? (^1A^2-^1T^2): ',Cmd1,'ABCDEFGHIJKLMNOPQRST',[CapAll]);
                    LoBaud := BaudRates[Ord(Cmd1) - 64];
                    Print('%LF^1Baud upper limit:^0%LF');
                    Counter := 1;
                    WHILE (Counter <= 20) AND (NOT Abort) AND (NOT HangUp) DO
                    BEGIN
                      PrintACR(Char(Counter + 64)+'. '+IntToStr(BaudRates[Counter]));
                      Inc(Counter);
                    END;
                    InputChar('%LFWhich? (^1A^2-^1T^2): ',Cmd1,'ABCDEFGHIJKLMNOPQRST',[CapAll]);
                    HiBaud := BaudRates[Ord(Cmd1) - 64];
                    Changed := TRUE;
                    Cmd1 := #0;
                  END;
          '2' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (ACSIsActive IN EFlags) THEN
                  BEGIN
                    Exclude(EFlags,ACSIsActive);
                    EventACS := 's10';
                    Changed := TRUE;
                  END
                  ELSE
                  BEGIN
                    Include(EFlags,ACSIsActive);
                    InputString('%LFSL ACS: ',EventACS,(SizeOf(EventACS) - 1),[InterActiveEdit],Changed);
                  END;
          '3' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (TimeIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,TimeIsActive);
                      MaxTimeAllowed := 60;
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,TimeIsActive);
                      InputWord('%LFMaximum time allowed on-line (minutes)',MaxTimeAllowed,
                                   [InteractiveEdit{,DisplayValue},NumbersOnly],0,65535,Changed);
                    END;
                  END;
          '4' : IF NOT (EventIsExternal IN EFlags) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (SetArIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,SetArIsActive);
                      SetARFlag := '@';
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,SetArIsActive);
                      InputChar('%LFAR flag to set (^1A^2-^1Z^2): ',Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',[CapAll]);
                      SetARFlag := Cmd1;
                      Cmd1 := #0;
                    END;
                  END;
          '5' : IF NOT (EventIsExternal IN EFlags) THEN
                  IF (EventIsPermission IN EFlags) THEN
                  BEGIN
                    IF (ClearArIsActive IN EFlags) THEN
                    BEGIN
                      Exclude(EFlags,ClearArIsActive);
                      ClearArFlag := '@';
                      Changed := TRUE;
                    END
                    ELSE
                    BEGIN
                      Include(EFlags,ClearArIsActive);
                      InputChar('%LFAR flag to clear (^1A^2-^1Z^2): ',Cmd1,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',[CapAll]);
                      ClearArFlag := Cmd1;
                      Cmd1 := #0;
                    END;
                  END;
          '6' : IF (NOT (EventIsExternal IN EFlags)) THEN
                  ToggleEFlags('S',EFlags,Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumEvents) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  InputInteger('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumEvents,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumEvents) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumEvents) THEN
                  RecNumToEdit := NumEvents
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  NL;
                  LCmds(20,1,'[ Previous Entry','] Next Entry');
                  LCmds(20,1,'First Entry','Last Entry');
                  LCmds(20,1,'Jump To Entry','');
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertEvent(TempEvent1: EventRecordType; Cmd1: Char; RecNumToInsertBefore: Integer);
  VAR
    RecNum,
    RecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumEvents = MaxEvents) THEN
      Messages(5,MaxEvents,'events')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFEvent to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumEvents + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumEvents + 1)) THEN
      BEGIN
        Reset(EventFile);
        InitEventVars(TempEvent1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumEvents + 1)) THEN
          RecNumToEdit := (NumEvents + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditEvent(TempEvent1,TempEvent1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckEvent(TempEvent1,1,1,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting event? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting event record ...');
          Seek(EventFile,FileSize(EventFile));
          Write(EventFile,Event);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(EventFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(EventFile,RecNum);
            Read(EventFile,Event);
            Seek(EventFile,(RecNum + 1));
            Write(EventFile,Event);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            Seek(EventFile,RecNum);
            Write(EventFile,TempEvent1);
            Inc(NumEvents);
            SysOpLog('* Inserted event: ^1'+TempEvent1.EventDescription);
          END;
        END;
        Close(EventFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyEvent(TempEvent1: EventRecordType; Cmd1: Char; RecNumToEdit: Integer);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputInteger('%LF^2Modify which event?',RecNumToEdit,[NumbersOnly],1,NumEvents,Changed);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumEvents) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(EventFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(EventFile,(RecNumToEdit - 1));
            Read(EventFile,Event);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditEvent(TempEvent1,Event,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckEvent(Event,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(EventFile,(SaveRecNumToEdit - 1));
            Write(EventFile,Event);
            Changed := FALSE;
            SysOpLog('* Modified event: ^1'+Event.EventDescription);
          END;
        END;
        Close(EventFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionEvent(TempEvent1: EventRecordType; RecNumToPosition: Integer);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (NumEvents = 0) THEN
      Messages(4,0,'events')
    ELSE IF (NumEvents = 1) THEN
      Messages(6,0,'events')
    ELSE
    BEGIN
      InputInteger('%LFPosition which event?',RecNumToPosition,[NumbersOnly],1,NumEvents,Changed);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumEvents) THEN
      BEGIN
        Print('%LFAccording to the current numbering system.');
        InputInteger('%LFPosition before which event?',RecNumToPositionBefore,[Numbersonly],1,(NumEvents + 1),Changed);
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumEvents + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning event.');
          Reset(EventFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(EventFile,RecNumToPosition);
          Read(EventFile,TempEvent1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(EventFile)) THEN
            BEGIN
              Seek(EventFile,(RecNum1 + RecNum2));
              Read(EventFile,Event);
              Seek(EventFile,RecNum1);
              Write(EventFile,Event);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(EventFile,RecNumToPositionBefore);
          Write(EventFile,TempEvent1);
          Close(EventFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ListEvents(VAR RecNumToList1: Integer);
  VAR
    NumDone: Integer;
    Sched: STRING[25];
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumFileAreas) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    ConfigHeader('Event Editor');
    PrintACR('^5<^4A^5> <^4##^5> <^4Description^5>                  <^4Schedule^5>');
    HL;
    Reset(EventFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumEvents) AND 
          (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(EventFile,(RecNumToList1 - 1));
        Read(EventFile,Event);
        WITH Event DO
          PrintACR(' '+PadLeftStr(AOnOff(EventIsActive IN EFlags,'^9'+#251,'^8-'),3)+
                   ' ^1'+PadLeftInt(RecNumToList1,4)+
                   ' ^1'+PadLeftStr(EventDescription,30)+               
                   ' ^5D: ^1'+PadLeftStr(AOnOff(EventDayOfMonth <> 0,
                                    IntToStr(EventDayOfMonth)+AllCaps(DateSuffix(EventDayOfMonth)), {Day of month}
                                    DaysEventActive(EventDays,'1','5'))+ {Days of week}
                   ' ^5T: ^1'+Copy(CTim(EventStartTime),4,5),20)); {Time}
        Inc(RecNumToList1);
        Inc(NumDone);
      END;
    Close(EventFile);
    LastError := IOResult;
    IF (NumEvents = 0) THEN
      Messages(4,0,'events'); {Print('*** No events defined ***');}
  END;

BEGIN
  IF (MemEventArray[Numevents] <> NIL) THEN
    FOR RecNumToList := 1 TO NumEvents DO
      IF (MemEventArray[RecNumToList] <> NIL) THEN
        Dispose(MemEventArray[RecNumToList]);
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListEvents(RecNumToList);
    NL;
    InputChar('^2Event Editor [^1DIMP^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'QDIMP?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumEvents) THEN
              RecNumToList := 1;
      'D' : DeleteEvent(TempEvent,RecNumToList);
      'I' : InsertEvent(TempEvent,Cmd,RecNumToList);
      'M' : ModifyEvent(TempEvent,Cmd,RecNumToList);
      'P' : PositionEvent(TempEvent,RecNumToList);
      '?' : BEGIN
              NL;
              Print('^0<^1CR^0> Next Page / Refresh');
              {Print('^0(^1?^0)Help/First event');}
              LCmds(13,1,'Delete Event','Insert Event');
              LCmds(13,1,'Modify Event','Position Event');
              {LCmds(13,3,'Quit','');}
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  NumEvents := 0;
  Reset(EventFile);
  WHILE NOT EOF(EventFile) DO
  BEGIN
    Inc(NumEvents);
    New(MemEventArray[NumEvents]);
    Read(EventFile,MemEventArray[NumEvents]^);
  END;
  Close(EventFile);
  LastError := IOResult;
END;
END.