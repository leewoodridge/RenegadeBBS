{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp1;

INTERFACE

PROCEDURE ProtocolEditor;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader,HL}

PROCEDURE ProtocolEditor;
VAR
  TempProtocol: ProtocolRecordType;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  PROCEDURE ToggleXBFlag(XBFlagT: ProtocolFlagType; VAR XBFlags: PRFlagSet);
  BEGIN
    IF (XBFlagT IN XBFlags) THEN
      Exclude(XBFlags,XBFlagT)
    ELSE
      Include(XBFlags,XBFlagT);
  END;

  PROCEDURE ToggleXBFlags(C: Char; VAR XBFlags: PRFlagSet; VAR Changed: Boolean);
  VAR
    TempXBFlags: PRFlagSet;
  BEGIN
    TempXBFlags := XBFlags;
    CASE C OF
      '1' : ToggleXBFlag(ProtActive,XBFlags);
      '2' : ToggleXBFlag(ProtIsBatch,XBFlags);
      '3' : ToggleXBFlag(ProtIsResume,XBFlags);
      '4' : ToggleXBFlag(ProtBiDirectional,XBFlags);
      '5' : ToggleXBFlag(ProtReliable,XBFlags);
      '6' : ToggleXBFlag(ProtXferOkCode,XBFlags);
    END;
    IF (XBFlags <> TempXBFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitProtocolVars(VAR Protocol: ProtocolRecordType);
  VAR
    Counter: BYTE;
  BEGIN
    FillChar(Protocol,SizeOf(Protocol),0);
    WITH Protocol DO
    BEGIN
      PRFlags := [ProtXferOkCode];
      CKeys := '!';
      Description := '<< New Protocol >>';
      ACS := '';
      TempLog := '';
      DLoadLog := '';
      ULoadLog := '';
      DLCmd := '';
      ULCmd := '';
      FOR Counter := 1 TO 6 DO
      BEGIN
        DLCode[Counter] := '';
        ULCode[Counter] := '';
      END;
      EnvCmd := '';
      DLFList := '';
      MaxChrs := 127;
      TempLogPF := 0;
      TempLogPS := 0;
    END;
  END;

  PROCEDURE DeleteProtocol(TempProtocol1: ProtocolRecordType; RecNumToDelete: Integer);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFProtocol to delete?',RecNumToDelete,[NumbersOnly],1,NumProtocols,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumProtocols) THEN
      BEGIN
        Reset(ProtocolFile);
        Seek(ProtocolFile,(RecNumToDelete - 1));
        Read(ProtocolFile,TempProtocol1);
        Close(ProtocolFile);
        LastError := IOResult;
        Print('%LFProtocol: ^1'+TempProtocol1.Description);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting protocol record ...');
          Dec(RecNumToDelete);
          Reset(ProtocolFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(ProtocolFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(ProtocolFile) - 2) DO
            BEGIN
              Seek(ProtocolFile,(RecNum + 1));
              Read(ProtocolFile,Protocol);
              Seek(ProtocolFile,RecNum);
              Write(ProtocolFile,Protocol);
            END;
          Seek(ProtocolFile,(FileSize(ProtocolFile) - 1));
          Truncate(ProtocolFile);
          Close(ProtocolFile);
          LastError := IOResult;
          Dec(NumProtocols);
          SysOpLog('* Deleted Protocol: ^1'+TempProtocol1.Description);
        END;
      END;
    END;
  END;

  FUNCTION CmdOk(Protocol: ProtocolRecordType): Boolean;
  VAR
    Ok1: Boolean;
  BEGIN
    Ok1 := TRUE;
    WITH Protocol DO
      IF (DLCmd = 'ASCII') OR (DLCmd = 'BATCH') OR (DLCmd = 'EDIT') OR
         (DLCmd = 'NEXT') OR (DLCmd = 'QUIT') OR (ULCmd = 'ASCII') OR
         (ULCmd = 'BATCH') OR (ULCmd = 'EDIT') OR (ULCmd = 'NEXT') OR
         (ULCmd = 'QUIT') THEN
      OK1 := FALSE;
    CmdOk := Ok1;
  END;

  FUNCTION DLCodesEmpty(Protocol: ProtocolRecordType): Boolean;
  VAR
    Counter1: Byte;
  BEGIN
    DLCodesEmpty := TRUE;
    FOR Counter1 := 1 TO 6 DO
      IF (Protocol.DLCode[Counter1] <> '') THEN
        DLCodesEmpty := FALSE;
  END;

  FUNCTION ULCodesEmpty(Protocol: ProtocolRecordType): Boolean;
  VAR
    Counter1: Byte;
  BEGIN
    ULCodesEmpty := TRUE;
    FOR Counter1 := 1 TO 6 DO
      IF (Protocol.ULCode[Counter1] <> '') THEN
        ULCodesEmpty := FALSE;
  END;

  PROCEDURE CheckProtocol(Protocol: ProtocolRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Protocol.Ckeys = '') THEN
            BEGIN
              Print('%LF^8The command keys are invalid!^0');
              Ok := FALSE;
            END;
        2 : IF (Protocol.Description = '<< New Protocol >>') THEN
            BEGIN
              Print('%LF^8The description is invalid!^0');
              Ok := FALSE;
            END;
        3 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
               (Protocol.TempLogPF = 0) THEN
            BEGIN
              Print('%LF^8You must specify the file name position if you utilize the Temp Log.^0');
              Ok := FALSE;
            END;
        4 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
              (Protocol.TempLogPS = 0) THEN
            BEGIN
              Print('%LF^8You must specify the status position if you utilize the Temp Log.');
              Ok := FALSE;
            END;
        5 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFLags) AND (Protocol.TempLog <> '') AND
              (DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify <D>L codes if you utilize the Temp. Log.^0');
              Ok := FALSE;
            END;
        6 : IF (CMDOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLoadLog <> '') AND
               (Protocol.TempLog = '') THEN
            BEGIN
              Print('%LF^8You must specify a Temp. Log if you utilize the <D>L Log.^0');
              Ok := FALSE;
            END;
        7 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.ULCmd <> '') AND
               (ULCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify <U>L Codes if you utilize the <U>L Command.^0');
              Ok := FALSE;
            END;
        8 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.DLCmd <> '') AND
               (DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify <D>L Codes if you utilize the <D>L Command.^0');
              Ok := FALSE;
            END;
        9 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLCmd <> '') AND
               (Protocol.DLFList = '') THEN
            BEGIN
              Print('%LF^8You must specify a DL File List if you utilize the <D>L Command.^0');
              Ok := FALSE;
            END;
       10 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.DLCmd <> '') AND
               (Protocol.MaxChrs = 0) THEN
            BEGIN
              Print('%LF^8You must specify the Max DOS Chars if you utilize the <D>L Command.^0');
              Ok := FALSE;
            END;
       11 : IF (Protocol.ULCmd = '') AND (Protocol.DLCmd = '') THEN
            BEGIN
              Print('%LF^8You must specify a <U>L or <D>L Command.^0');
              Ok := FALSE;
            END;
       12 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.DLCmd = '') AND
              (NOT DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify a <D>L Command if you utilize <D>L Codes.^0');
              Ok := FALSE;
            END;
       13 : IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN Protocol.PRFlags)) AND (Protocol.ULCmd = '') AND
              (NOT ULCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify a <U>L Command if you utilize <U>L Codes.^0');
              Ok := FALSE;
            END;
       14 : IF (CmdOk(Protocol)) AND (ProtIsBatch IN Protocol.PRFlags) AND (Protocol.TempLog = '') AND
              (NOT DLCodesEmpty(Protocol)) THEN
            BEGIN
              Print('%LF^8You must specify a Temp Log if you utilize <D>L Codes.^0');
              Ok := FALSE;
            END;
      END;
  END;

  PROCEDURE EditProtocol(TempProtocol1: ProtocolRecordType; VAR Protocol: ProtocolRecordType; VAR Cmd1: Char;
                         VAR RecNumToEdit: Integer; VAR Changed: Boolean; Editing: Boolean);
  VAR
    TempStr,
    CmdStr: AStr;
    Cmd2: Char;
    Counter: Byte;
    OK: Boolean;
  BEGIN
    WITH Protocol DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          MCIAllowed := FALSE;
          Abort := FALSE;
          Next := FALSE;
          CLS;
          IF (Editing) THEN
            ConfigHeader('Editing Protocol #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumProtocols),0)
          ELSE
            ConfigHeader('Inserting Protocol #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumProtocols + 1),0);
          PrintACR('^0(^1!^0) Type/protocl: ^1'+
                   AOnOff(ProtActive IN PRFlags,'Active','INACTIVE')+' - '+
                   AOnOff(ProtIsBatch IN PRFlags,'Batch','Single')+
                   AOnOff(ProtIsResume IN PRFlags,' - Resume','')+
                   AOnOff(ProtBiDirectional IN PRFlags,' - Bidirectional','')+
                   AOnOff(ProtReliable IN PRFlags,' - Reliable only',''));
          PrintACR('^0(^11^0) Keys/descrip: ^1'+CKeys+'^0 / ^1'+AOnOff(Description = '','*None*',Description)+'^0');
          PrintACR('^0(^12^0) ACS required: ^1'+AOnOff(ACS = '','*None*',ACS)+'^0');
          IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFLags) THEN
          BEGIN
            PrintACR('^0(^13^0) Temp. log   : ^1'+AOnOff(TempLog = '','*None*',TempLog));
            IF (Protocol.TempLog <> '') THEN
              PrintACR('^0               : File name position: ^1'+IntToStr(TempLogPF)+
                       ' ^0/ Status position: ^1'+IntToStr(TempLogPS));
          END;
          IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFLags) THEN
          BEGIN
            PrintACR('^0(^14^0) <U>L log    : ^1'+AOnOff(ULoadLog = '','*None*',ULoadLog));
            PrintACR('^0    <D>L log    : ^1'+AOnOff(DLoadLog = '','*None*',DLoadLog));
          END;
          PrintACR('^0(^15^0) <U>L command: ^1'+AOnOff(ULCmd = '','*None*',ULCmd));
          PrintACR('^0    <D>L command: ^1'+AOnOff(DLCmd = '','*None*',DLCmd));
          IF (ProtIsBatch IN PRFLags) AND (CMDOk(Protocol)) AND (Protocol.DLCmd <> '') THEN
            PrintACR('^0                : DL File List: ^1'+AOnOff(DLFList = '','*None*',DLFList)+
                     ' ^0/ Max DOS chars: ^1'+IntToStr(MaxChrs));
          IF (CmdOk(Protocol)) THEN
            PrintACR('^0(^16^0) Codes mean  : ^1'+AOnOff(ProtXferOkCode IN PRFlags,'Transfer Successful','Transfer Failed'));
          IF (CmdOk(Protocol)) THEN
          BEGIN
            TempStr := '^0(^17^0) <U>L codes  :';
            FOR Counter := 1 TO 3 DO
              TempStr := TempStr + PadLeftStr('^0 ('+IntToStr(Counter)+') "^1'+ULCode[Counter]+'^0" ',13);
            PrintACR(TempStr);
            TempStr := '^0                :';
            FOR Counter := 4 TO 6 DO
              TempStr := TempStr + PadLeftStr('^0 ('+IntToStr(Counter)+') "^1'+ULCode[Counter]+'^0" ',13);
            PrintACR(TempStr);
            TempStr := '^0    <D>L codes  :';
            FOR Counter := 1 TO 3 DO
              TempStr := TempStr + PadLeftStr('^0 ('+IntToStr(Counter)+') "^1'+DLCode[Counter]+'^0" ',13);
            PrintACR(TempStr);
            TempStr := '^0                :';
            FOR Counter := 4 TO 6 DO
              TempStr := TempStr + PadLeftStr('^0 ('+IntToStr(Counter)+') "^1'+DLCode[Counter]+'^0" ',13);
            PrintACR(TempStr);
          END;
          IF (CmdOk(Protocol)) THEN
            PrintACR('^0(^18^0) Environ. cmd: ^1'+AOnOff(EnvCmd = '','*None*',EnvCmd));
          MCIAllowed := TRUE;
        END;
        IF (NOT Editing) THEN
          CmdStr := '!12345678'
        ELSE
          CmdStr := '!12345678[]FJL';
        InputChar('%LFModify menu [^1?^2=^1Help^2]: ',Cmd1,'Q?'+CmdStr+^M,[CapAll]);
        CASE Cmd1 OF
          '!' : BEGIN
                  REPEAT
                    Print('%LF^1Protocol types:^0');
                    Print('%LF^01. Protocol active   : ^1'+ShowYesNo(ProtActive IN PRFlags));
                    Print('^02. Is batch protocol : ^1'+ShowYesNo(ProtIsBatch IN PRFlags));
                    Print('^03. Is resume protocol: ^1'+ShowYesNo(ProtIsResume IN PRFlags));
                    Print('^04. Is bidirectional  : ^1'+ShowYesNo(ProtBiDirectional IN PRFlags));
                    Print('^05. For reliable only : ^1'+ShowYesNo(ProtReliable IN PRFlags));
                    InputChar('%LFNew protocol type? [^11^2-^15^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'12345',[CapAll]);
                    IF (Cmd1 IN ['1'..'5']) THEN
                      ToggleXBFlags(Cmd1,PRFlags,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          '1' : BEGIN
                  REPEAT
                    Ok := TRUE;
                    TempProtocol1.Ckeys := CKeys;
                    InputString('%LFNew command keys: ',CKeys,(SizeOf(Ckeys) - 1),[InterActiveEdit],Changed);
                    CheckProtocol(Protocol,1,1,Ok);
                    IF (NOT Ok) THEN
                      Ckeys := TempProtocol1.Ckeys;
                  UNTIL (Ok) OR (HangUp);
                  REPEAT
                    Ok := TRUE;
                    TempProtocol1.Description := Description;
                    InputString('%LFNew description: ',Description,(SizeOf(Description) - 1),[InteractiveEdit],Changed);
                    CheckProtocol(Protocol,2,2,Ok);
                    IF (NOT Ok) THEN
                      Description := TempProtocol1.Description;
                  UNTIL (Ok) OR (HangUp);
                END;
          '2' : InputString('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '3' : IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) THEN
                BEGIN
                  Print('%LFIf you specify a Temporary Log file, you must also');
                  Print('specify the "File Name" position, "Status" position and');
                  Print('the corresponding Batch <D>L Codes.');
                  InputString('%LFNew temporary log: ',TempLog,(SizeOf(TempLog) - 1),[InterActiveEdit],Changed);
                  IF (Protocol.TempLog = '') THEN
                  BEGIN
                    Protocol.TempLogPF := 0;
                    Protocol.TempLogPS := 0;
                  END;
                  IF (ProtIsBatch IN PRFLags) AND (CMDOk(Protocol)) AND (Protocol.TempLog <> '') THEN
                  BEGIN
                    REPEAT
                      Ok := TRUE;
                      TempProtocol1.TempLogPF := TempLogPF;
                      InputByte('%LFNew file name log position',TempLogPF,[InteractiveEdit{,DisplayValue},
                      NumbersOnly],0,127,Changed);
                      CheckProtocol(Protocol,3,3,Ok);
                      IF (NOT Ok) THEN
                        TempLogPF := TempProtocol1.TempLogPF;
                    UNTIL (Ok) OR (HangUp);
                    REPEAT
                      Ok := TRUE;
                      TempProtocol1.TempLogPS := TempLogPS;
                      InputByte('%LFNew status log position',TempLogPS,[InteractiveEdit{,DisplayValue},
                      NumbersOnly],0,127,Changed);
                      CheckProtocol(Protocol,4,4,Ok);
                      IF (NOT Ok) THEN
                        TempLogPS := TempProtocol1.TempLogPS;
                    UNTIL (Ok) OR (HangUp);
                  END;
                END;
          '4' : IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) THEN
                BEGIN
                  InputChar('%LFFile transfer type? [^1U^2=^1Upload^2,^1D^2=^1Download^2,^1<CR>^2=^1Quit^2]: ',
                        Cmd1,^M'UD',[CapAll]);
                  CASE Cmd1 OF
                    'U' : BEGIN
                            Print('%LF^8The permanent batch upload log is not utilized by Renegade!^0');
                            PauseScr(FALSE);
                          END;
                    'D' : BEGIN
                            Print('%LFIf you specify a permanent batch download log, you must also');
                            Print('specify a temporary log.');
                            InputString('%LFNew permanent download log: ',DLoadLog,(SizeOf(DloadLog) - 1),
                                     [InterActiveEdit],Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          '5' : BEGIN
                  TempStr := #0;
                  InputChar('%LFFile transfer type? [^1U^2=^1Upload^2,^1D^2=^1Download^2,^1<CR>^2=^1Quit^2]: ',
                        Cmd1,^M'UD',[CapAll]);
                  IF (Cmd1 <> ^M) THEN
                  BEGIN
                    InputChar('%LFFile transfer method? [^1E^2=^1External^2,^1I^2=^1Internal^2,^1O^2=^1Off^2,'+
                              '^1<CR>^2=^1Quit^2]: ',Cmd2,^M'EIO',[CapAll]);
                    CASE Cmd2 OF
                      'E' : CASE Cmd1 OF
                              'U' : BEGIN
                                      TempStr := ULCmd;
                                      IF (CmdOk(Protocol)) AND (NOT (ProtIsBatch IN PRFlags)) THEN
                                      BEGIN
                                        Print('%LFIf you specify an external single upload protocol, you must also');
                                        Print('specify single upload <U>L codes.');
                                      END;
                                      InputString('%LF^0New external upload protocol:%LF^2: ',TempStr,(SizeOf(DlCmd) - 1),
                                               [InterActiveEdit],Changed);
                                    END;
                              'D' : BEGIN
                                      TempStr := DLCmd;
                                      IF (CmdOk(Protocol)) THEN
                                        IF (ProtIsBatch IN PRFlags) THEN
                                        BEGIN
                                          Print('%LFIf you specify an external batch download protocol, you must');
                                          Print('also specify a batch file list and the maximum DOS characters');
                                          Print('allowed on the DOS commandline.');
                                        END
                                        ELSE
                                        BEGIN
                                          Print('%LFIf you specify an external single download protocol, you must also');
                                          Print('specify single download <D>L codes.');
                                        END;
                                      InputString('%LF^0New external download protocol:%LF^2: ',TempStr,(SizeOf(DlCmd) - 1),
                                               [InterActiveEdit],Changed);
                                      IF (TempStr = '') THEN
                                      BEGIN
                                        Protocol.DLFList := '';
                                        Protocol.MaxChrs := 127;
                                      END;
                                      IF (CmdOk(Protocol)) AND (ProtIsBatch IN PRFlags) AND (TempStr <> '') THEN
                                      BEGIN
                                        REPEAT
                                          Ok := TRUE;
                                          TempProtocol1.DLFList := DLFList;
                                          InputString('%LFNew batch file list: ',DLFList,(SizeOf(DLFList) - 1),
                                                   [InterActiveEdit],Changed);
                                          CheckProtocol(Protocol,9,9,Ok);
                                          IF (NOT Ok) THEN
                                            DLFList := TempProtocol1.DLFList;
                                        UNTIL (Ok) OR (HangUp);
                                        REPEAT
                                          Ok := TRUE;
                                          TempProtocol1.MaxChrs := MaxChrs;
                                          InputByte('%LFNew max DOS characters in commandline',MaxChrs,
                                                      [InteractiveEdit{,DisplayValue},NumbersOnly],0,127,Changed);
                                          CheckProtocol(Protocol,10,10,Ok);
                                          IF (NOT Ok) THEN
                                            MaxChrs := TempProtocol1.MaxChrs;
                                        UNTIL (Ok) OR (HangUp);
                                      END;
                                    END;
                            END;
                      'I' : BEGIN
                              Print('%LF^1Internal protocol types:^0');
                              NL;
                              LCmds(40,1,'ASCII','');
                              LCmds(40,1,'BATCH','');
                              LCmds(40,1,'EDIT','');
                              LCmds(40,1,'NEXT','');
                              LCmds(40,1,'QUIT','');
                              InputChar('%LFNew internal protocol? [^1A^2,^1B^2,^1E^2,^1N^2,^1Q^2,^1<CR>^2=^1Quit^2]: ',
                                    Cmd2,^M'ABENQ',[CapAll]);
                              IF (Cmd2 <> ^M) THEN
                                CASE Cmd2 OF
                                  'A' : TempStr := 'ASCII';
                                  'B' : TempStr := 'BATCH';
                                  'E' : TempStr := 'EDIT';
                                  'N' : TempStr := 'NEXT';
                                  'Q' : TempStr := 'QUIT';
                                END;
                              IF (Cmd2 <> ^M) THEN
                                Changed := TRUE;
                              Cmd2 := #0;
                            END;
                      'O' : IF PYNQ('%LFSet to NULL string? ',0,FALSE) THEN
                            BEGIN
                              TempStr := '';
                              Changed := TRUE;
                            END;
                    END;
                    IF (TempStr <> #0) THEN
                      CASE Cmd1 OF
                        'D' : DLCmd := TempStr;
                        'U' : ULCmd := TempStr;
                      END;
                    IF (NOT CmdOk(Protocol)) THEN
                    BEGIN
                      TempLog := '';
                      ULoadLog := '';
                      DLoadLog := '';
                      FOR Counter := 1 TO 6 DO
                      BEGIN
                        ULCode[Counter] := '';
                        DLCode[Counter] := '';
                      END;
                      EnvCmd := '';
                      DLFList := '';
                      MaxChrs := 127;
                      TempLogPF := 0;
                      TempLogPS := 0;
                    END;
                  END;
                  Cmd1 := #0;
                  Cmd2 := #0;
                END;
          '6' : IF (CmdOk(Protocol)) THEN
                  ToggleXBFlags('6',PRFlags,Changed);
          '7' : IF (CmdOk(Protocol)) THEN
                BEGIN
                  InputChar('%LFFile transfer type? [^1U^2=^1Upload^2,^1D^2=^1Download^2,^1<CR>^2=^1Quit^2]: ',
                        Cmd1,'UD'^M,[CapAll]);
                  CASE Cmd1 OF
                    'U' : BEGIN
                            IF (ProtIsBatch IN PRFlags) THEN
                            BEGIN
                              Print('%LF^8The batch upload codes are not utilized by Renegade!^0');
                              PauseScr(FALSE);
                            END
                            ELSE
                            BEGIN
                              Print('%LF^1New upload codes:^0');
                              FOR Counter := 1 TO 6 DO
                                InputString('%LFCode #'+IntToStr(Counter)+': ',ULCode[Counter],
                                         (SizeOf(ULCode[Counter]) - 1),[InterActiveEdit],Changed);
                            END;
                          END;
                    'D' : BEGIN
                            Print('%LF^1New download codes:^0');
                            FOR Counter := 1 TO 6 DO
                              InputString('%LFCode #'+IntToStr(Counter)+': ',DLCode[Counter],
                                       (SizeOf(DlCode[Counter]) - 1),[InterActiveEdit],Changed);
                          END;
                  END;
                  Cmd1 := #0;
                END;
          '8' : IF (CmdOk(Protocol)) THEN
                  InputString('%LFNew environment setup commandline:%LF: ',EnvCmd,(SizeOf(EnvCmd) - 1),
                              [InterActiveEdit],Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumProtocols) THEN
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
                  InputInteger('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumProtocols,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumProtocols) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumProtocols) THEN
                  RecNumToEdit := NumProtocols
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^0<^1CR^0>Redisplay current screen');
                  Print('^11^0-^18^0:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,1,'Quit and save','')
                  ELSE
                  BEGIN
                    LCmds(20,1,'[Back entry',']Forward entry');
                    LCmds(20,1,'First entry in list','Jump to entry');
                    LCmds(20,1,'Last entry in list','Quit and save');
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertProtocol(TempProtocol1: ProtocolRecordType; RecNumToInsertBefore: Integer);
  VAR
    Cmd1: Char;
    RecNum,
    RecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumProtocols = MaxProtocols) THEN
      Messages(5,MaxProtocols,'protocols')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFProtocol to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumProtocols + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumProtocols + 1)) THEN
      BEGIN
        Reset(ProtocolFile);
        InitProtocolVars(TempProtocol1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumProtocols + 1)) THEN
          RecNumToEdit := (NumProtocols + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditProtocol(TempProtocol1,TempProtocol1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckProtocol(TempProtocol1,1,14,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting protocol? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting protocol record ...');
          Seek(ProtocolFile,FileSize(ProtocolFile));
          Write(ProtocolFile,Protocol);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(ProtocolFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(ProtocolFile,RecNum);
            Read(ProtocolFile,Protocol);
            Seek(ProtocolFile,(RecNum + 1));
            Write(ProtocolFile,Protocol);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            Seek(ProtocolFile,RecNum);
            Write(ProtocolFile,TempProtocol1);
            Inc(NumProtocols);
            SysOpLog('* Inserted protocol: ^1'+TempProtocol1.Description);
          END;
          Close(ProtocolFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ModifyProtocol(TempProtocol1: ProtocolRecordType; Cmd1: Char; RecNumToEdit: Integer);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputInteger('%LFProtocol to modify?',RecNumToEdit,[NumbersOnly],1,NumProtocols,Changed);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumProtocols) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(ProtocolFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(ProtocolFile,(RecNumToEdit - 1));
            Read(ProtocolFile,Protocol);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditProtocol(TempProtocol1,Protocol,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckProtocol(Protocol,1,14,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(ProtocolFile,(SaveRecNumToEdit - 1));
            Write(ProtocolFile,Protocol);
            Changed := FALSE;
            SysOpLog('* Modified protocol: ^1'+Protocol.Description);
          END;
        END;
        Close(ProtocolFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionProtocol(TempProtocol1: ProtocolRecordType; RecNumToPosition: Integer);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (NumProtocols = 0) THEN
      Messages(4,0,'protocols')
    ELSE IF (NumProtocols = 1) THEN
      Messages(6,0,'protocols')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputInteger('%LFPosition which protocol?',RecNumToPosition,[NumbersOnly],1,NumProtocols,Changed);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumProtocols) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        Print('%LFAccording to the current numbering system.');
        InputInteger('%LFPosition before which protocol?',RecNumToPositionBefore,[NumbersOnly],1,(NumProtocols + 1),Changed);
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumProtocols + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning protocol records ...');
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Reset(ProtocolFile);
          Seek(ProtocolFile,RecNumToPosition);
          Read(ProtocolFile,TempProtocol1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(ProtocolFile)) THEN
            BEGIN
              Seek(ProtocolFile,(RecNum1 + RecNum2));
              Read(ProtocolFile,Protocol);
              Seek(ProtocolFile,RecNum1);
              Write(ProtocolFile,Protocol);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(ProtocolFile,RecNumToPositionBefore);
          Write(ProtocolFile,TempProtocol1);
          Close(ProtocolFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ListProtocols(VAR RecNumToList1: Integer);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumProtocols) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    {CLS;}
    ConfigHeader('Protocol Editor',0);
    {
    PrintACR('^1 ###^2:^1ACS       ^2:^1Description');
    PrintACR('^2 ===:==========:=============================================================');
    }
    PrintACR('^5<^4A^5> <^4##^5> <^4Description^5>');
    HL;
    Reset(ProtocolFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumProtocols)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(ProtocolFile,(RecNumToList1 - 1));
      Read(ProtocolFile,Protocol);
      WITH Protocol DO
        PrintACR(' '+PadLeftStr(AOnOff((ProtActive IN PRFlags),'^9'#251,'^8-'),3)+
                 ' ^1'+PadLeftInt(RecNumToList1,4)+
                 {' ^9'+PadLeftStr(ACS,10)+}
                 ' ^0'+Description);
      Inc(RecNumToList1);
      Inc(Numdone);
    END;
    Close(ProtocolFile);
    LastError := IOResult;
    IF (NumProtocols = 0) THEN
      Print('*** No protocols defined ***'); {leew: messages!}
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListProtocols(RecNumToList);
    InputChar('%LFProtocol Editor [^1DIMP^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'QDIMP?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumProtocols) THEN
              RecNumToList := 1;
      'D' : DeleteProtocol(TempProtocol,RecNumToList);
      'I' : InsertProtocol(TempProtocol,RecNumToList);
      'M' : ModifyProtocol(TempProtocol,Cmd,RecNumToList);
      'P' : PositionProtocol(TempProtocol,RecNumToList);
      '?' : BEGIN
              NL;
              Print('^0<^1CR^0>Next Screen / Refresh');
              LCmds(16,1,'Delete Protocol','Insert Protocol');
              LCmds(16,1,'Modify Protocol','Position Protocol');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
