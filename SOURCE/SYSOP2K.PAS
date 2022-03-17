{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT SysOp2K;

INTERFACE

PROCEDURE DisplayArcs;
PROCEDURE DisplayCmt;
PROCEDURE ArchiveConfiguration;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader/HL}

PROCEDURE DisplayArcs;
VAR
  RecNumToList: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  ConfigHeader('Archiver Editor');
  PrintACR('^5<^4A^5> <^4##^5> <^4Ext^5> <^4Compression CmdLine^5>    <^4Decompression CmdLine^5>  <^4Success Code^5>');
  HL;
  RecNumToList := 1;
  WHILE (RecNumToList <= NumArcs) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      WITH General.FileArcInfo[RecNumToList] DO
        PrintACR(PadLeftStr(AOnOff(Active,'^9 '#251,'^8 -'),4)+
                 '^1 '+PadLeftInt(RecNumToList,4)+
                 '^0 '+PadLeftStr(Ext,5)+
                 '^0 '+PadLeftStr(ArcLine,24)+
                 '^0 '+PadLeftStr(UnArcLine,24)+
                 '^0 '+PadLeftStr(AOnOff(SuccLevel <> - 1,IntToStr(SuccLevel),'-1 (Ignore)'),13));
      Inc(RecNumToList);
    END;
END;

PROCEDURE DisplayCmt;
VAR
  RecNumToList: Byte;
BEGIN
  FOR RecNumToList := 1 TO 3 DO
    PrintACR('^0(^1'+IntToStr(RecNumToList)+'^0) Archive Comment File #'+IntToStr(RecNumToList)+' : ^1'+
             AOnOff(General.FileArcComment[RecNumToList] <> '',
                    AllCaps(General.FileArcComment[RecNumToList]),'*None*'));
END;

PROCEDURE ArchiveConfiguration;
VAR
  TempArchive: FileArcInfoRecordType;
  Cmd: Char;
  RecNumToList: Byte;
  Changed : Boolean;

  FUNCTION DisplayArcStr(S: AStr): AStr;
  BEGIN
    IF (S <> '') THEN
      DisplayArcStr := S
    ELSE
      DisplayArcStr := '*None*';
    IF (S[1] = '/') THEN
    BEGIN
      S := '"'+S+'" - ';
      CASE s[3] OF
        '1' : DisplayArcStr := S + '*Internal* ZIP viewer';
        '2' : DisplayArcStr := S + '*Internal* ARC/PAK viewer';
        '3' : DisplayArcStr := S + '*Internal* ZOO viewer';
        '4' : DisplayArcStr := S + '*Internal* LZH viewer';
        '5' : DisplayArcStr := S + '*Internal* ARJ viewer';
      END;
    END;
  END;

  PROCEDURE InitArchiveVars(VAR Archive: FileArcInfoRecordType);
  BEGIN
    FillChar(Archive,SizeOf(Archive),0);
    WITH Archive DO
    BEGIN
      Active := FALSE;
      Ext := 'AAA';
      ListLine := '';
      ArcLine := '';
      UnArcLine := '';
      TestLine := '';
      CmtLine := '';
      SuccLevel := -1;
    END;
  END;

  PROCEDURE DeleteArchive(TempArchive1: FileArcInfoRecordType; RecNumToDelete: Byte);
  VAR
    RecNum: Byte;
  BEGIN
    IF (NumArcs = 0) THEN
      Messages(4,0,'archive records')
    ELSE
    BEGIN
      RecNumToDelete := 0;
      InputByte('%LFArchive to delete?',RecNumToDelete,[NumbersOnly],1,NumArcs,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumArcs) THEN
      BEGIN
        TempArchive1 := General.FileArcInfo[RecNumToDelete];
        Print('%LFArchive: ^1'+TempArchive1.Ext);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting archive record ...');
          FOR RecNum := RecNumToDelete TO (NumArcs - 1) DO
            General.FileArcInfo[RecNum] := General.FileArcInfo[RecNum + 1];
          General.FileArcInfo[NumArcs].Ext := '';
          Dec(NumArcs);
          SysOpLog('* Deleted archive: ^1'+TempArchive1.Ext);
        END;
      END;
    END;
  END;

  PROCEDURE CheckArchive(Archive: FileArcInfoRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Archive.Ext = '') OR (Archive.Ext = 'AAA') THEN
            BEGIN
              Print('%LF^8The archive extension is invalid!^0');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditArchive(TempArchive1: FileArcInfoRecordType; VAR Archive: FileArcInfoRecordType; VAR Cmd1: Char;
                        VAR RecNumToEdit: Byte; VAR Changed1: Boolean; Editing: Boolean);
  VAR
    CmdStr: AStr;
    Ok: Boolean;
  BEGIN
    WITH Archive DO
      REPEAT
        IF (Cmd1 <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            {CLS;}
            IF (Editing) THEN
              ConfigHeader('Editing Archiver #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumArcs))
            ELSE
              ConfigHeader('Inserting Archiver #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumArcs + 1));
            PrintACR('^0(^11^0) Active                : ^1'+ShowYesNo(Active));
            PrintACR('^0(^12^0) File Extension        : ^1'+Ext);
            PrintACR('^0(^13^0) Interior List Method  : ^1'+DisplayArcStr(ListLine));
            PrintACR('^0(^14^0) Compression CmdLine   : ^1'+DisplayArcStr(ArcLine));
            PrintACR('^0(^15^0) Decompression CmdLine : ^1'+DisplayArcStr(UnArcLine));
            PrintACR('^0(^16^0) File Testing CmdLine  : ^1'+DisplayArcStr(TestLine));
            PrintACR('^0(^17^0) Add Comment CmdLine   : ^1'+DisplayArcStr(CmtLine));
            PrintACR('^0(^18^0) Success ErrorLevel    : ^1'++AOnOff(SuccLevel <> - 1,IntToStr(SuccLevel),'-1 (Ignore)'));
          END;
        IF (NOT Editing) THEN
          CmdStr := '12345678'
        ELSE
          CmdStr := '12345678[]FJL';
        InputChar('%LFModify menu [^1?^2=^1Help^2]: ',Cmd1,'Q?'+CmdStr+^M,[CapAll]);
        CASE Cmd1 OF
          '1' : BEGIN
                  Active := NOT Active;
                  Changed1 := TRUE;
                END;
          '2' : REPEAT
                  TempArchive1.Ext := Ext;
                  Ok := TRUE;
                  InputString('%LFNew extension: ',Ext,(SizeOf(Ext) - 1),[InterActiveEdit,CapAll],Changed1);
                  CheckArchive(Archive,1,1,Ok);
                  IF (NOT Ok) THEN
                    Ext := TempArchive1.Ext;
                UNTIL (Ok) OR (HangUp);
          '3' : InputString('%LFNew interior list method: ',ListLine,(SizeOf(ListLine) - 1),[InterActiveEdit],Changed1);
          '4' : InputString('%LFNew compression command line: ',ArcLine,(SizeOf(ArcLine) - 1),[InterActiveEdit],Changed1);
          '5' : InputString('%LFNew decompression command line: ',UnArcLine,(SizeOf(UnArcLine) - 1),
                         [InterActiveEdit],Changed1);
          '6' : InputString('%LFNew file testing command line: ',TestLine,(SizeOf(TestLine) - 1),
                         [InterActiveEdit],Changed1);
          '7' : InputString('%LFNew add comment command line: ',CmtLine,(SizeOf(CmtLine) - 1),[InterActiveEdit],Changed1);
          '8' : InputInteger('%LFNew errorlevel for success',SuccLevel,[InteractiveEdit,NumbersOnly],-1,255,Changed1);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumArcs) THEN
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
                  InputByte('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumArcs,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumArcs) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumArcs) THEN
                  RecNumToEdit := NumArcs
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

  PROCEDURE InsertArchive(TempArchive1: FileArcInfoRecordType; Cmd1: Char; RecNumToInsertBefore: Byte);
  VAR
    RecNum,
    RecNumToEdit: Byte;
    Ok,
    Changed1: Boolean;
  BEGIN
    IF (NumArcs = MaxArcs) THEN
      Messages(5,MaxArcs,'archive records')
    ELSE
    BEGIN
      RecNumToInsertBefore := 0;
      InputByte('%LFArchive to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumArcs + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumArcs + 1)) THEN
      BEGIN
        InitArchiveVars(TempArchive1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumArcs + 1)) THEN
          RecNumToEdit := (NumArcs + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditArchive(TempArchive1,TempArchive1,Cmd1,RecNumToEdit,Changed1,FALSE);
          CheckArchive(TempArchive1,1,2,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting archive? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting archive record ...');
          IF (RecNumToInsertBefore <> (NumArcs + 1)) THEN
            FOR RecNum := (NumArcs + 1) DOWNTO (RecNumToInsertBefore + 1) DO
              General.FileArcInfo[RecNum] := General.FileArcInfo[RecNum - 1];
          General.FileArcInfo[RecNumToInsertBefore] := TempArchive1;
          Inc(NumArcs);
          SysOpLog('* Inserted archive: ^1'+TempArchive1.Ext);
        END;
      END;
    END;
  END;

  PROCEDURE ModifyArchive(TempArchive1: FileArcInfoRecordType; Cmd1: Char; RecNumToEdit: Byte);
  VAR
    Archive: FileArcInfoRecordType;
    SaveRecNumToEdit: Byte;
    OK,
    Changed1: Boolean;
  BEGIN
    IF (NumArcs = 0) THEN
      Messages(4,0,'archive records')
    ELSE
    BEGIN
      RecNumToEdit := 0;
      InputByte('%LFArchive to modify?',RecNumToEdit,[NumbersOnly],1,NumArcs,Changed);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumArcs) THEN
      BEGIN
        SaveRecNumToEdit := 0;
        Cmd1 := #0;
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Archive := General.FileArcInfo[RecNumToEdit];
            SaveRecNumToEdit := RecNumToEdit;
            Changed1 := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditArchive(TempArchive1,Archive,Cmd1,RecNumToEdit,Changed1,TRUE);
            CheckArchive(Archive,1,2,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed1) THEN
          BEGIN
            General.FileArcInfo[SaveRecNumToEdit] := Archive;
            Changed1 := FALSE;
            SysOpLog('* Modified archive: ^1'+Archive.Ext);
          END;
        END;
      END;
    END;
  END;

BEGIN
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
    BEGIN
      CLS;
      DisplayArcs;
      NL;
      DisplayCmt;
    END;
    NL;
    InputChar('^2Archiver Editor [^1DIM^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'QDIM123?'^M,[CapAll]);
    CASE Cmd OF
      'D' : DeleteArchive(TempArchive,RecNumToList);
      'I' : InsertArchive(TempArchive,Cmd,RecNumToList);
      'M' : ModifyArchive(TempArchive,Cmd,RecNumToList);
      '1'..'3' :
            BEGIN
              Changed := FALSE;
              InputString('%LFNew comment file #'+IntToStr(Ord(Cmd) - 48)+': ',General.FileArcComment[Ord(Cmd) - 48],
              40,[InteractiveEdit],Changed);
              IF (Changed) THEN
                SysOpLog('* Modified comment: ^1'+IntToStr(Ord(Cmd) - 48)+'.');
            END;
      '?' : BEGIN
              Print('%LF^0<^1CR^0>Next screen or redisplay current screen');
              Print('^0(^1?^0)Help/First archive');
              Print('^11^0-^13^0:Modify Item');
              LCmds(16,1,'Delete archive','Insert archive');
              LCmds(16,1,'Modify archive','Quit');
            END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
