{$A+,B+,D+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{
 03/09/2023 - Aesthetic updates
            - Error messages now using Messages PROC
}
UNIT SysOp7M;

INTERFACE

USES
  Common,
  SysOp2; {ConfigHeader/HL}

PROCEDURE CommandEditor(MenuToModify,MenuNumber: Integer; MenuName: AStr);
PROCEDURE LoadMenuPointers;

IMPLEMENTATION

USES
  Menus2;

PROCEDURE LoadMenuPointers;
VAR
  RecNum: Integer;
BEGIN
  NumMenus := 0;
  NumCmds := 0;
  FOR RecNum := 1 TO MaxMenus DO
    MenuRecNumArray[RecNum] := 0;
  FOR RecNum := 1 TO MaxMenus DO
    CmdNumArray[RecNum] := 0;
  Reset(MenuFile);
  RecNum := 0;
  WHILE NOT EOF(MenuFile) DO
    BEGIN
      Read(MenuFile,MenuR);
      IF (MenuR.Menu = FALSE) THEN
        Inc(NumCmds)
      ELSE
        BEGIN
          Inc(NumMenus);
          MenuRecNumArray[NumMenus] := RecNum;
          IF (NumMenus > 1) THEN
            CmdNumArray[NumMenus - 1] := NumCmds;
          NumCmds := 0;
        END;
      Inc(RecNum);
    END;
  CmdNumArray[NumMenus] := NumCmds;
END;

PROCEDURE CommandEditor(MenuToModify,MenuNumber: Integer; MenuName: AStr);
VAR
  TempS: AStr;
  Cmd: Char;
  RecNumToList,
  Counter: Integer;

  FUNCTION DisplayCmdFlags(CmdFlags: CmdFlagSet; C1,C2: Char): AStr;
  VAR
    CmdFlagT: CmdFlagType;
    DisplayStr: AStr;
  BEGIN
    DisplayStr := '';
    FOR CmdFlagT := Hidden TO UnHidden DO
      IF (CmdFlagT IN CmdFlags) THEN
        DisplayStr := DisplayStr + '^'+C1+Copy('HU',(Ord(CmdFlagT) + 1),1)
      ELSE
        DisplayStr := DisplayStr + '^'+C2+'-';
      DisplayCmdFlags := DisplayStr;
  END;

  PROCEDURE ToggleCmdFlag(CmdFlagT: CmdFlagType; VAR CmdFlags: CmdFlagSet);
  BEGIN
    IF (CmdFlagT IN CmdFlags) THEN
      Exclude(CmdFlags,CmdFlagT)
    ELSE
      Include(CmdFlags,CmdFlagT);
  END;

  PROCEDURE ToggleCmdFlags(C: Char; VAR CmdFlags: CmdFlagSet; VAR Changed: Boolean);
  VAR
    TempCmdFlags: CmdFlagSet;
  BEGIN
    TempCmdFlags := CmdFlags;
    CASE C OF
      'H' : ToggleCmdFlag(Hidden,CmdFlags);
      'U' : ToggleCmdFlag(UnHidden,CmdFlags);
    END;
    IF (CmdFlags <> TempCmdFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitCommandVars(VAR MenuR: MenuRec);
  BEGIN
    FillChar(MenuR,SizeOf(MenuR),0);
    WITH MenuR DO
      BEGIN
        LDesc[1] := '<< New Command >>';
        ACS := '';
        NodeActivityDesc := '';
        Menu := FALSE;
        CmdFlags := [];
        SDesc := '(XXX)New Cmd';
        CKeys := 'XXX';
        CmdKeys := '-L';
        Options := '';
      END;
  END;

  FUNCTION GetRecNum(NumCmds: Integer): Integer;
  VAR
    R: REAL;
  BEGIN
    R := (NumCmds / 3);
    IF (Frac(R) = 0.0) THEN
      GetRecNum := Trunc(R)
    ELSE
      GetRecNum := (Trunc(R) + 1);
  END;

  PROCEDURE DeleteCommand;
  VAR
    RecNumToDelete,
    RecNum: Integer;
  BEGIN
    IF (CmdNumArray[MenuToModify] = 0) THEN
      Messages(4,0,'commands')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFDelete which command?',RecNumToDelete,[NumbersOnly],1,CmdNumArray[MenuToModify],Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= CmdNumArray[MenuToModify]) THEN
      BEGIN
        Seek(MenuFile,(MenuRecNumArray[MenuToModify] + RecNumToDelete));
        Read(MenuFile,MenuR);
        Print('%LFCommand: ^1'+MenuR.LDesc[1]);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting command record ...');
          SysOpLog('* Deleted command: ^1'+MenuR.LDesc[1]);
          RecNumToDelete := (MenuRecNumArray[MenuToModify] + RecNumToDelete); { Convert To Real Record Number }
          IF (RecNumToDelete <= (FileSize(MenuFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(MenuFile) - 2) DO
            BEGIN
              Seek(MenuFile,(RecNum + 1));
              Read(MenuFile,MenuR);
              Seek(MenuFile,RecNum);
              Write(MenuFile,MenuR);
            END;
          Seek(MenuFile,FileSize(MenuFile) - 1);
          Truncate(MenuFile);
          LoadMenuPointers;
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE InsertCommand;
  VAR
    RecNumToInsertBefore,
    InsertNum,
    RecNum: Integer;
  BEGIN
    IF (CmdNumArray[MenuToModify] = MaxCmds) THEN
      Messages(5,MaxCmds,'commands')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFCommand to insert before?',RecNumToInsertBefore,[NumbersOnly],1,
                     (CmdNumArray[MenuToModify]+1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (CmdNumArray[MenuToModify] + 1)) THEN
      BEGIN
        InsertNum := 1;
        InputInteger('%LFInsert how many commands?',InsertNum,
                        [InteractiveEdit,NumbersOnly],1,(MaxCmds - CmdNumArray[MenuToModify]),Changed);
        IF (InsertNum < 1) OR (InsertNum > (MaxCmds - CmdNumArray[MenuToModify])) THEN
          InsertNum := 1;
        Print('%LF[> Inserting '+IntToStr(InsertNum)+' commands.');
        SysOpLog('* Inserted '+IntToStr(InsertNum)+' commands.');
        RecNumToInsertBefore := (MenuRecNumArray[MenuToModify] + RecNumToInsertBefore);  { Convert To Real Record Number }
        FOR RecNum := 1 TO InsertNum DO
        BEGIN
          Seek(MenuFile,FileSize(MenuFile));
          Write(MenuFile,MenuR);
        END;
        FOR RecNum := ((FileSize(MenuFile) - 1) - InsertNum) DOWNTO RecNumToInsertBefore DO
        BEGIN
          Seek(MenuFile,RecNum);
          Read(MenuFile,MenuR);
          Seek(MenuFile,(RecNum + InsertNum));
          Write(MenuFile,MenuR);
        END;
        InitCommandVars(MenuR);
        FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + InsertNum) - 1) DO
        BEGIN
          Seek(MenuFile,RecNum);
          Write(MenuFile,MenuR);
        END;
        LoadMenuPointers;
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyCommand;
  VAR
    TempS1: AStr;
    Cmd1: Char;
    TempB: Byte;
    RecNumToModify,
    SaveRecNumToModify: Integer;
    Changed: Boolean;
  BEGIN
    IF (CmdNumArray[MenuToModify] = 0) THEN
      Messages(4,0,'commands')
    ELSE
    BEGIN
      RecNumToModify := -1;
      InputInteger('%LFCommand to modify?',RecNumToModify,[NumbersOnly],1,CmdNumArray[MenuToModify],Changed);
      IF (RecNumToModify >= 1) AND (RecNumToModify <= CmdNumArray[MenuToModify]) THEN
      BEGIN
        SaveRecNumToModify := -1;
        Cmd1 := #0;
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToModify <> RecNumToModify) THEN
          BEGIN
            Seek(MenuFile,(MenuRecNumArray[MenuToModify] + RecNumToModify));
            Read(MenuFile,MenuR);
            SaveRecNumToModify := RecNumToModify;
            Changed := FALSE;
          END;
          WITH MenuR DO
            REPEAT
              IF (Cmd1 <> '?') THEN
              BEGIN
                Abort := FALSE;
                Next := FALSE;
                MCIAllowed := FALSE;
                ConfigHeader('Editing Command',RecNumToModify,CmdNumArray[MenuToModify]); { MenuName / MenuNumber }
                PrintACR('^0(^11^0) Long Description  : ^1'+LDesc[1]);
                PrintACR('^0(^12^0) Short Description : ^1'+SDesc);
                PrintACR('^0(^13^0) Menu Keys         : ^1'+CKeys);
                PrintACR('^0(^14^0) ACS Required      : ^1"'+ACS+'"');
                PrintACR('^0(^15^0) Cmd Keys          : ^1'+CmdKeys);
                PrintACR('^0(^16^0) Options           : ^1'+Options{+'^0'});
                IF (General.MultiNode) THEN
                  PrintACR('^0(^1N^0) Node Activity     : ^1'+NodeActivityDesc);
                PrintACR('^0(^1T^0) Flags             : ^1'+DisplayCmdFlags(CmdFlags,'1','0'));
                MCIAllowed := TRUE;
              END;
              IF (General.MultiNode) THEN
                InputChar(#10'Command Editor [^1123456NT^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'123456NT[]{};?Q'^M,[CapAll])
              ELSE
                InputChar(#10'Command Editor [^1123456T^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'123456T[]{};?Q'^M,[CapAll]);
              CASE Cmd1 OF
                '1' : InputString('%LF^0New long description:%LF^2: ',LDesc[1],(SizeOf(LDesc[1]) - 1),
                [InteractiveEdit,NoInputField],Changed);
                '2' : InputString('%LFNew short description: ',SDesc,(SizeOf(SDesc) - 1),
                [InteractiveEdit],Changed);
                '3' : InputString('%LFNew menu keys: ',Ckeys,(SizeOf(CKeys) - 1),[InterActiveEdit,CapAll],Changed);
                '4' : InputString('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
                '5' : BEGIN
                        REPEAT
                          Prt('%LFNew command keys [^1?^2=^1List^2]: ');
                          InputMain(TempS1,2,[CapAll]);
                          IF (TempS1 = '?') THEN
                          BEGIN
                            CLS;
                            PrintF('MENUCMD');
                            NL;
                          END;
                        UNTIL (HangUp) OR (TempS1 <> '?');
                        IF (Length(TempS1) = 2) THEN
                        BEGIN
                          CmdKeys := TempS1;
                          Changed := TRUE;
                        END;
                      END;
                '6' : InputString('%LFNew options: ',Options,(SizeOf(Options) - 1),[InteractiveEdit],Changed);
                'N' : IF (General.MultiNode) THEN
                        InputString('%LF^0New node activity description:%LF^2: ',NodeActivityDesc,
                                  (SizeOf(NodeActivityDesc) - 1),[InteractiveEdit],Changed);
                'T' : BEGIN
                        REPEAT
                          InputChar('%LFToggle which flag? ('+DisplayCmdFlags(CmdFlags,'5','4')+')'+
                                ' [^1?^2=^1Help^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'HU?',[CapAll]);
                          CASE Cmd1 OF
                            'H','U' :
                                    ToggleCmdFlags(Cmd1,CmdFlags,Changed);
                            '?' : BEGIN
                                    NL;
                                    LCmds(17,1,'Hidden command','UnHidden Command');
                                  END;
                          END;
                        UNTIL (Cmd1 = ^M) OR (HangUp);
                        Cmd1 := #0;
                      END;
                '[' : IF (RecNumToModify > 1) THEN
                        Dec(RecNumToModify)
                      ELSE
                      BEGIN
                        Messages(2,0,'');
                        Cmd1 := #0;
                      END;
                ']' : IF (RecNumToModify < CmdNumArray[MenuToModify]) THEN
                        Inc(RecNumToModify)
                      ELSE
                      BEGIN
                        Messages(3,0,'');
                        Cmd1 := #0;
                      END;
                '{' : IF (RecNumToModify <> 1) THEN
                        RecNumToModify := 1
                      ELSE
                      BEGIN
                        Messages(2,0,'');
                        Cmd1 := #0;
                      END;
                ';' : BEGIN
                        InputInteger('%LFJump to entry',RecNumToModify,[NumbersOnly],1,CmdNumArray[MenuToModify],Changed);
                        IF (RecNumToModify < 1) and (RecNumToModify > CmdNumArray[MenuToModify]) THEN
                          Cmd1 := #0;
                      END;
                '}' : IF (RecNumToModify <> CmdNumArray[MenuToModify]) THEN
                        RecNumToModify := CmdNumArray[MenuToModify]
                      ELSE
                      BEGIN
                        Messages(3,0,'');
                        Cmd1 := #0;
                      END;
                '?' : BEGIN
                        NL;
                        LCmds(19,1,'[ Previous Command','] Next Command');
                        LCmds(19,1,'{ First Command','} Last Command');
                        LCmds(19,1,'; Jump To Command','');
                      END;
              END;
            UNTIL (Pos(Cmd1,'Q[]{};') <> 0) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(MenuFile,(MenuRecNumArray[MenuToModify] + SaveRecNumToModify));
            Write(MenuFile,MenuR);
            Changed := FALSE;
            SysOpLog('* Modified command: ^1'+MenuR.LDesc[1]);
          END;
        END;
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionCommand;
  VAR
    TempMenuR: MenuRec;
    RecNumToPosition,
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (CmdNumArray[MenuToModify] = 0) THEN
      Messages(4,0,'commands')
    ELSE IF (CmdNumArray[MenuToModify] = 1) THEN
      Messages(6,0,'commands')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputInteger('%LFPosition which command',RecNumToPosition,[NumbersOnly],1,CmdNumArray[MenuToModify],Changed);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= CmdNumArray[MenuToModify]) THEN
      BEGIN
        Print('%LFAccording to the current numbering system.');
        InputInteger('%LFPosition before which command?',RecNumToPositionBefore,
                        [NumbersOnly],1,(CmdNumArray[MenuToModify] + 1),Changed);
        IF (RecNumToPositionBefore <> RecNumToPosition) AND
           (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          RecNumToPosition := (MenuRecNumArray[MenuToModify] + RecNumToPosition);  { Convert To Real Record Number }
          RecNumToPositionBefore := (MenuRecNumArray[MenuToModify] + RecNumToPositionBefore);
          Print('%LF[> Positioning command.');
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Seek(MenuFile,RecNumToPosition);
          Read(MenuFile,TempMenuR);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(MenuFile)) THEN
            BEGIN
              Seek(MenuFile,(RecNum1 + RecNum2));
              Read(MenuFile,MenuR);
              Seek(MenuFile,RecNum1);
              Write(MenuFile,MenuR);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(MenuFile,RecNumToPositionBefore);
          Write(MenuFile,TempMenuR);
        END;
        LastError := IOResult;
      END;
    END;
  END;

BEGIN
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      MCIAllowed := FALSE;
      ConfigHeader('Command Editor',0,0);
      PrintACR('^5ó^4###^5³^4Short Description^5ò   ^5ó^4###^5³^4Short Description^5ò   ^5ó^4###^5³^4Short Description^5ò');
      HL;
      Reset(MenuFile);
      RecNumToList := 1;
      WHILE (RecNumToList <= GetRecNum(CmdNumArray[MenuToModify])) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(MenuFile,(RecNumToList + MenuRecNumArray[MenuToModify]));
        Read(MenuFile,MenuR);
        TempS := '^1 '+PadRightStr(IntToStr(RecNumToList),3)+' ^0'+PadLeftStr(MenuR.SDesc,21)+' ';
        Counter := (RecNumToList + GetRecNum(CmdNumArray[MenuToModify]));
        IF (Counter <= CmdNumArray[MenuToModify]) THEN
        BEGIN
          Seek(MenuFile,(Counter + MenuRecNumArray[MenuToModify]));
          Read(MenuFile,MenuR);
          TempS := TempS + '^1'+PadRightStr(IntToStr(Counter),3)+' ^0'+PadLeftStr(MenuR.SDesc,21)+' ';
        END;
        Counter := (Counter + GetRecNum(CmdNumArray[MenuToModify]));
        IF (Counter <= CmdNumArray[MenuToModify]) THEN
        BEGIN
          Seek(MenuFile,Counter + MenuRecNumArray[MenuToModify]);
          Read(MenuFile,MenuR);
          TempS := TempS + '^1'+PadRightStr(IntToStr(Counter),3)+' ^0'+PadLeftStr(MenuR.SDesc,21);
        END;
        PrintACR(TempS);
        Inc(RecNumToList);
      END;
      IF (CmdNumArray[MenuToModify] = 0) THEN
        Messages(4,0,'commands'); { "No commands exist!" } (*Print('*** No commands defined ***');*)
      MCIAllowed := TRUE;
    END;
    NL;
    InputChar('^2Command Editor [^1DILMPS^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'DILMPS?Q'^M,[CapAll]);
    CASE Cmd OF
      'D' : DeleteCommand;
      'I' : InsertCommand;
      'L' : BEGIN
              Seek(MenuFile,MenuRecNumArray[MenuNumber]);
              Read(MenuFile,MenuR);
              CurMenu := MenuNumber;
              LoadMenu;
              Reset(MenuFile);
              GenericMenu(3);
              NL;
              PauseScr(FALSE);
            END;
      'M' : ModifyCommand;
      'P' : PositionCommand;
      'S' : BEGIN
              Seek(MenuFile,MenuRecNumArray[MenuNumber]);
              Read(MenuFile,MenuR);
              CurMenu := MenuNumber;
              LoadMenu;
              Reset(MenuFile);
              GenericMenu(2);
              NL;
              PauseScr(FALSE);
            END;
      '?' : BEGIN
              Print('%LF^0<^1CR^0>Redisplay screen');
              LCmds(20,1,'Delete command','Insert command');
              LCmds(20,1,'Long generic menu','Modify commands');
              LCmds(20,1,'Position command','Quit');
              LCmds(20,1,'Short generic menu','');
            END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  LastError := IOResult;
END;

END.
