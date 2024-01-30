{$A+,B+,D+,E+,F+,I+,L+,N-,O+,R-,S+,V-}
{
 12/17/2021 - aesthetic changes
 03/09/2023 - Error messages now using Messages PROC
 01/29/2024 - Indented
 01/29/2024 - Prompt,Help aesthetics

menu titles not saving if last line blank
}
UNIT SysOp7;

INTERFACE

USES
 Common;

PROCEDURE FindMenu(DisplayStr: AStr; VAR MenuNum: Byte; LowMenuNum,HighMenuNum: Byte; VAR Changed: Boolean);
PROCEDURE MenuEditor;

IMPLEMENTATION

USES
  Common5,
  Menus2,
  SysOp2, {ConfigHeader/HL}
  SysOp7M;

PROCEDURE DisplayMenus(VAR RecNumToList1: Integer; DisplayListNum: Boolean);
VAR
  NumDone: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  MCIAllowed := FALSE;
  IF (DisplayListNum) THEN
    PrintACR('^5<^4I#^5> <^4M#^5> <^4Menu Name^5>')
  ELSE
    PrintACR('^5<^4##^5> <^4Menu Name^5>');
  HL;
  Reset(MenuFile);
  NumDone := 0;
  WHILE (NumDone < (PageLength - 7)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumMenus)
        AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(MenuFile,MenuRecNumArray[RecNumToList1]);
      Read(MenuFile,MenuR);
      WITH MenuR DO
        BEGIN
          IF (DisplayListNum) THEN
            PrintACR(' ^1'+PadLeftInt(RecNumToList1,4)+
                     ' ^1'+PadLeftInt(MenuNum,4)+
                     ' ^0'+PadLeftStr(LDesc[1],68))
          ELSE
            PrintACR(' ^1'+PadLeftInt(MenuNum,4)+
                     ' ^0'+PadLeftStr(LDesc[1],73));
        END;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
  Close(MenuFile);
  LastError := IOResult;
  MCIAllowed := TRUE;
  AllowContinue := FALSE;
  IF (NumMenus = 0) THEN
     Messages(4,0,'menus'); { "No commands exist!" } (*Print('*** No menus defined ***'); {leew: messages!}*)
  {
  IF (DisplayListNum) THEN
    PrintACR('%LF^0[Users start at menu number: ^1'+IntToStr(General.AllStartMenu)+'^0]');
  }
END;

PROCEDURE FindMenu(DisplayStr: AStr; VAR MenuNum: Byte; LowMenuNum,HighMenuNum: Byte; VAR Changed: Boolean);
VAR
  TempMenuR: MenuRec;
  InputStr: AStr;
  SaveMenuNum: Byte;
  RecNum,
  RecNum1,
  RecNumToList: Integer;
BEGIN
  SaveMenuNum := MenuNum;
  RecNumToList := 1;
  InputStr := '?';
  REPEAT
    ConfigHeader('System Menus Configuration',0,0);
    IF (InputStr = '?') THEN
      DisplayMenus(RecNumToList,FALSE);
    Prt(DisplayStr+' (^1'+IntToStr(LowMenuNum)+'^2-^1'+IntToStr(HighMenuNum)+'^2)'+
        ' [^1?^2=^1First^2,^1<CR>^2=^1Next^2,^1Q^2=^1Quit^2): ');
    MPL(Length(IntToStr(NumMenus)));
    ScanInput(InputStr,'Q?'^M);
    IF (InputStr = '-') THEN
      InputStr := 'Q';
    IF (InputStr <> 'Q') THEN
      BEGIN
        IF (InputStr = ^M) THEN
          BEGIN
            InputStr := '?';
            IF (RecNumToList < 1) OR (RecNumToList > NumMenus) THEN
              RecNumToList := 1
          END
        ELSE IF (InputStr = '?') THEN
          RecNumToList := 1
        ELSE IF (StrToInt(InputStr) < LowMenuNum) OR (StrToInt(InputStr) > HighMenuNum) THEN
          Print('%LF^8The range must be from '+IntToStr(LowMenuNum)+' to '+IntToStr(HighMenuNum)+'!^0')
        ELSE IF (InputStr = '0') AND (LowMenuNum = 0) THEN
          BEGIN
            MenuNum := StrToInt(InputStr);
            InputStr := 'Q';
            Changed := TRUE;
          END
        ELSE
          BEGIN
            RecNum1 := -1;
            RecNum := 1;
            Reset(MenuFile);
            WHILE (RecNum <= NumMenus) AND (RecNum1 = -1) DO
              BEGIN
                Seek(MenuFile,MenuRecNumArray[RecNum]);
                Read(MenuFile,TempMenuR);
                IF (StrToInt(InputStr) = TempMenuR.MenuNum) THEN
                  RecNum1 := TempMenuR.MenuNum;
                Inc(RecNum);
              END;
            Close(MenuFile);
            IF (RecNum1 = -1) THEN
              BEGIN
                lRGLngStr(112,FALSE);
                MenuNum := SaveMenuNum;
              END
            ELSE
              BEGIN
                MenuNum := StrToInt(InputStr);
                InputStr := 'Q';
                Changed := TRUE;
              END;
          END;
      END;
  UNTIL (InputStr = 'Q') OR (HangUp);
END;

PROCEDURE MenuEditor;
VAR
  Cmd: Char;
  SaveCurMenu: Byte;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DisplayMenuFlags(MenuFlags: MenuFlagSet; C1,C2: Char): AStr;
  VAR
    MenuFlagT: MenuFlagType;
    TempS: AStr;
  BEGIN
    TempS := '';
    FOR MenuFlagT := ClrScrBefore TO NoGlobalUsed DO
      IF (MenuFlagT IN MenuFlags) THEN
        TempS := TempS + '^'+C1+Copy('CDTNPAF12345',(Ord(MenuFlagT) + 1),1)
      ELSE
        TempS := TempS + '^'+C2+'-';
    DisplayMenuFlags := TempS;
  END;

  PROCEDURE ToggleMenuFlag(MenuFlagT: MenuFlagType; VAR MenuFlags: MenuFlagSet);
  BEGIN
    IF (MenuFlagT IN MenuFlags) THEN
      Exclude(MenuFlags,MenuFlagT)
    ELSE
      Include(MenuFlags,MenuFlagT);
  END;

  PROCEDURE ToggleMenuFlags(C: Char; VAR MenuFlags: MenuFlagSet; VAR Changed: Boolean);
  VAR
    TempMenuFlags: MenuFlagSet;
  BEGIN
    TempMenuFlags := MenuFlags;
    CASE C OF
      'C' : ToggleMenuFlag(ClrScrBefore,MenuFlags);
      'D' : ToggleMenuFlag(DontCenter,MenuFlags);
      'T' : ToggleMenuFlag(NoMenuTitle,MenuFlags);
      'N' : ToggleMenuFlag(NoMenuPrompt,MenuFlags);
      'P' : ToggleMenuFlag(ForcePause,MenuFlags);
      'A' : ToggleMenuFlag(AutoTime,MenuFlags);
      'F' : ToggleMenuFlag(ForceLine,MenuFlags);
      '1' : ToggleMenuFlag(NoGenericAnsi,MenuFlags);
      '2' : ToggleMenuFlag(NoGenericAvatar,MenuFlags);
      '3' : ToggleMenuFlag(NoGenericRIP,MenuFlags);
      '4' : ToggleMenuFlag(NoGlobalDisplayed,MenuFlags);
      '5' : ToggleMenuFlag(NoGlobalUsed,MenuFlags);
    END;
    IF (MenuFlags <> TempMenuFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitMenuVars(VAR MenuR: MenuRec);
  BEGIN
    FillChar(MenuR,SizeOf(MenuR),0);
    WITH MenuR DO
    BEGIN
      LDesc[1] := '<< New Menu >>';
      LDesc[2] := '';
      LDesc[3] := '';
      ACS := '';
      NodeActivityDesc := '';
      Menu := TRUE;
      MenuFlags := [AutoTime];
      LongMenu := '';
      MenuNum := 0;
      MenuPrompt := 'Command? ';
      Password := '';
      FallBack := 0;
      Directive := '';
      ForceHelpLevel := 0;
      GenCols := 4;
      GCol[1] := 4;
      GCol[2] := 3;
      GCol[3] := 5;
    END;
  END;

  PROCEDURE DeleteMenu;
  VAR
    RecNumToDelete,
    RecNum: Integer;
    DeleteOk: Boolean;
  BEGIN
    IF (NumMenus = 0) THEN
      Messages(4,0,'menus')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFMenu number to delete?',RecNumToDelete,[NumbersOnly],1,NumMenus,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumMenus) THEN
      BEGIN
        Reset(MenuFile);
        Seek(MenuFile,MenuRecNumArray[RecNumToDelete]);
        Read(MenuFile,MenuR);
        Close(MenuFile);
        LastError := IOResult;
        DeleteOK := TRUE;
        IF (MenuR.MenuNum = General.AllStartMenu) THEN
        BEGIN
          Print('%LFYou can not delete the menu new users start at.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.NewUserInformationMenu) THEN
        BEGIN
          Print('%LFYou can not delete the new user information menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.FileListingMenu) THEN
        BEGIN
          Print('%LFYou can not delete the file listing menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (MenuR.MenuNum = General.MessageReadMenu) THEN
        BEGIN
          Print('%LFYou can not delete the message read menu.');
          DeleteOK := FALSE;
        END
        ELSE IF (CmdNumArray[RecNumToDelete] <> 0) THEN
        BEGIN
          Print('%LFThis menu is not empty.');
          DeleteOK := FALSE;
        END;
        IF (NOT DeleteOK) THEN
          PauseScr(FALSE)
        ELSE
        BEGIN
          Print('%LFMenu: ^1'+MenuR.LDesc[1]);
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting menu record ...');
            SysOpLog('* Deleted menu: ^1'+MenuR.LDesc[1]);
            RecNumToDelete := MenuRecNumArray[RecNumToDelete];  { Convert To Real Record Number }
            Reset(MenuFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(MenuFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(MenuFile) - 2) DO
              BEGIN
                Seek(MenuFile,(RecNum + 1));
                Read(MenuFile,MenuR);
                Seek(MenuFile,RecNum);
                Write(MenuFile,MenuR);
              END;
            Seek(MenuFile,(FileSize(MenuFile) - 1));
            Truncate(MenuFile);
            LoadMenuPointers;
            Close(MenuFile);
            LastError := IOResult;
          END;
        END;
      END;
    END;
  END;

  PROCEDURE InsertMenu;
  VAR
    RecNumToInsertBefore,
    NewMenuNum,
    RecNum: Integer;
  BEGIN
    IF (NumMenus = MaxMenus) THEN
      Messages(5,MaxMenus,'menus')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFMenu number to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumMenus + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumMenus + 1)) THEN
      BEGIN
        Print('%LF[> Inserting menu record ...');
        SysOpLog('* Inserted 1 menu.');
        IF (RecNumToInsertBefore = (NumMenus + 1)) THEN
          MenuRecNumArray[RecNumToInsertBefore] := (MenuRecNumArray[NumMenus] + CmdNumArray[NumMenus] + 1);
        RecNumToInsertBefore := MenuRecNumArray[RecNumToInsertBefore];  {Convert To Real Record Number }
        NewMenuNum := 0;
        Reset(MenuFile);
        RecNum := 1;
        WHILE (RecNum <= NumMenus) DO
        BEGIN
          Seek(MenuFile,MenuRecNumArray[RecNum]);
          Read(MenuFile,MenuR);
          IF (MenuR.MenuNum > NewMenuNum) THEN
            NewMenuNum := MenuR.MenuNum;
          Inc(RecNum);
        END;
        FOR RecNum := 1 TO 1 DO
        BEGIN
          Seek(MenuFile,FileSize(MenuFile));
          Write(MenuFile,MenuR);
        END;
        FOR RecNum := ((FileSize(MenuFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
        BEGIN
          Seek(MenuFile,RecNum);
          Read(MenuFile,MenuR);
          Seek(MenuFile,(RecNum + 1));
          Write(MenuFile,MenuR);
        END;
        InitMenuVars(MenuR);
        FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
        BEGIN
          Seek(MenuFile,RecNum);
          MenuR.MenuNum := (NewMenuNum + 1);
          Write(MenuFile,MenuR);
        END;
        LoadMenuPointers;
        Close(MenuFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyMenu;
  VAR
    TempMenuR: MenuRec;
    Cmd1: Char;
    SaveMenuNum: Byte;
    RecNum,
    RecNum1,
    RecNumToModify,
    SaveRecNumToModify: Integer;
    Changed: Boolean;
  BEGIN
    IF (NumMenus = 0) THEN
      Messages(4,0,'menus')
    ELSE
      BEGIN
        RecNumToModify := -1;
        InputInteger('%LFMenu number to modify?',RecNumToModify,[NumbersOnly],1,NumMenus,Changed);
        IF (RecNumToModify >= 1) AND (RecNumToModify <= NumMenus) THEN
          BEGIN
            SaveRecNumToModify := -1;
            Cmd1 := #0;
            Reset(MenuFile);
            WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
              BEGIN
                IF (SaveRecNumToModify <> RecNumToModify) THEN
                  BEGIN
                    Seek(MenuFile,MenuRecNumArray[RecNumToModify]);
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
                        ConfigHeader('Editing Menu',RecNumToModify,NumMenus);
                        PrintACR('^0(^11^0) Menu Number    : ^1'+IntToStr(MenuNum));
                        PrintACR('^0(^12^0) Menu Title     : ^1'+LDesc[1]);
                        IF (LDesc[2] <> '') THEN
                          PrintACR('^0    Menu Title #2  : ^1'+LDesc[2]);
                        IF (LDesc[3] <> '') THEN
                          PrintACR('^0    Menu Title #3  : ^1'+LDesc[3]);
                        PrintACR('^0(^13^0) Help Files     : ^1'+AOnOff((Directive = ''),'*Generic*',Directive)+'^0 / ^1'+
                                                           AOnOff((LongMenu = ''),'*Generic*',LongMenu));
                        PrintACR('^0(^14^0) Menu Prompt    : ^1'+MenuPrompt);
                        PrintACR('^0(^15^0) ACS Required   : ^1'+AOnOff((ACS = ''),'*None*','^0"^1'+ACS+'^0"'));
                        PrintACR('^0(^16^0) Password       : ^1'+AOnOff((Password = ''),'*None*',Password));
                        PrintACR('^0(^17^0) Fallback Menu  : ^1'+IntToStr(FallBack));
                        PrintACR('^0(^18^0) Forced ? Level : ^1'+AOnOff((ForceHelpLevel=0),'*None*',IntToStr(ForceHelpLevel)));
                        PrintACR('^0(^19^0) Generic Config : Columns: ^1'+IntToStr(GenCols)+'^0 Colors: ^1'+IntToStr(GCol[1])+
                                 '^0 / ^1'+IntToStr(GCol[2])+'^0 / ^1'+IntToStr(GCol[3]));
                        IF (General.MultiNode) THEN
                          PrintACR('^0(^1N^0) Node Activity  : ^1'+NodeActivityDesc);
                        PrintACR('^0(^1T^0) Flags          : ^1'+DisplayMenuFlags(MenuFlags,'1','0'));
                        MCIAllowed := TRUE;
                        NL;
                        PrintACR('^0 '#196' This menu contains ^1'+IntToStr(CmdNumArray[RecNumToModify])+'^0 '
                                 +Plural('command',CmdNumArray[RecNumToModify]));
                        IF (NumMenus = 0) THEN
                          Messages(4,0,'menus'); { "No commands exist!" }
                          (*Print('*** No menus defined ***'); {LeeW: Messages!}*)
                      END;
                    NL;
                    IF (General.MultiNode) THEN
                      InputChar('^2Menu Editor [^1123456789NT^2,(^1C^2)ommand Editor,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,
                                '123456789CNT[]{};?Q'^M,[CapAll])
                    ELSE
                      InputChar('^2Menu Editor [^11^2-^19^2,^1T^2,(^1C^2)ommand Editor,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,
                                '123456789CT[]{};?Q'^M,[CapAll]);
                    CASE Cmd1 OF
                      '1' : BEGIN
                              REPEAT
                                SaveMenuNum := MenuNum;
                                RecNum1 := -1;
                                InputByte('%LFNew menu number',MenuNum,[InteractiveEdit,NumbersOnly],1,(NumMenus + 1),Changed);
                                IF (MenuNum <> SaveMenuNum) AND (MenuNum >= 1) AND (MenuNum <= (NumMenus + 1)) THEN
                                  BEGIN
                                    RecNum := 1;
                                    WHILE (Recnum <= NumMenus) AND (RecNum1 = -1) DO
                                      BEGIN
                                        Seek(MenuFile,MenuRecNumArray[RecNum]);
                                        Read(MenuFile,TempMenuR);
                                        IF (MenuNum = TempMenuR.MenuNum) THEN
                                          RecNum1 := TempMenuR.MenuNum;
                                        Inc(RecNum);
                                      END;
                                    IF (RecNum1 <> -1) THEN
                                      BEGIN
                                        NL;
                                        Print('^8Duplicate menu number!^0');
                                        MenuNum := SaveMenuNum;
                                      END;
                                  END;
                              UNTIL (RecNum1 = -1) OR (HangUp);
                              Changed := TRUE;
                            END;
                      '2' : BEGIN
                              NL;
                              InputString('New menu title #1: %LF',LDesc[1],
                                          (SizeOf(LDesc[1]) - 1),[InteractiveEdit,NoInputField],Changed);
                              {IF (LDesc[1] <> '') THEN}
                              InputString('New menu title #2: %LF',LDesc[2],
                                          (SizeOf(LDesc[2]) - 1),[InteractiveEdit,NoInputField],Changed);
                              {IF (LDesc[2] <> '') THEN}
                              InputString('New menu title #3: %LF',LDesc[3],
                                          (SizeOf(LDesc[3]) - 1),[InteractiveEdit,NoInputField],Changed);
                              Changed := TRUE; {LeeW: Cheating here}
                            END;
                      '3' : BEGIN
                              InputString('%LFNew file displayed for help: ',Directive,(SizeOf(Directive) - 1),
                                          [InterActiveEdit,CapAll],Changed);
                              InputString('%LFNew file displayed for extended help: ',LongMenu,(SizeOf(LongMenu) - 1),
                                          [InterActiveEdit,CapAll],Changed);
                              Changed := TRUE; {LeeW: Cheating here}
                            END;
                      '4' : InputString('%LFNew menu prompt: %LF',MenuPrompt,(SizeOf(MenuPrompt) - 1),
                                        [InteractiveEdit,NoInputField],Changed);
                      '5' : InputString('%LFNew menu ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
                      '6' : InputString('%LFNew password: ',Password,(SizeOf(Password) - 1),[InterActiveEdit,CapAll],Changed);
                      '7' : BEGIN
                              SaveMenuNum := FallBack;
                              IF (Changed) THEN
                                BEGIN
                                  Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                  Write(MenuFile,MenuR);
                                  Changed := FALSE;
                                END;
                              Close(MenuFile);
                              FindMenu('%LF^2New fallback menu (^10^2=^1None^2)',SaveMenuNum,0,NumMenus,Changed);
                              Reset(MenuFile);
                              Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                              Read(MenuFile,MenuR);
                              IF (Changed) THEN
                                FallBack := SaveMenuNum;
                            END;
                      '8' : InputByte('%LFNew forced menu help-level (0=None)',ForceHelpLevel,
                                      [InteractiveEdit,NumbersOnly],0,3,Changed);
                      '9' : BEGIN
                              REPEAT
                                ConfigHeader('Generic Menu Configuration',0,0);
                                PrintACR('^0(^1C^0) Number Of Columns : ^1'+IntToStr(GenCols));
                                PrintACR('^0(^11^0) Bracket Color     : ^1'+IntToStr(GCol[1]));
                                PrintACR('^0(^12^0) Command Color     : ^1'+IntToStr(GCol[2]));
                                PrintACR('^0(^13^0) Description Color : ^1'+IntToStr(GCol[3]));
                                NL;
                                PrintACR('^0(^1S^0) Show Menu');
                                NL;
                                InputChar('^2Generic Menu Configuration [^1C123S^2,(^1Q^2)uit]: ',Cmd1,'QCS123'^M,[CapAll]);
                                CASE Cmd1 OF
                                  'S' : BEGIN
                                          IF (Changed) THEN
                                            BEGIN
                                              Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                              Write(MenuFile,MenuR);
                                              Changed := FALSE;
                                            END;
                                          Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                          Read(MenuFile,MenuR);
                                          CurMenu := MenuR.MenuNum;
                                          LoadMenu;
                                          Reset(MenuFile);
                                          GenericMenu(2);
                                          NL;
                                          PauseScr(FALSE);
                                          Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                          Read(MenuFile,MenuR);
                                        END;
                                  'C' : InputByte('%LFNew number of generic columns',GenCols,
                                                  [InteractiveEdit,NumbersOnly],0,7,Changed);
                                  '1' : InputByte('%LFNew bracket color',GCol[1],
                                                  [InteractiveEdit,NumbersOnly],0,9,Changed);
                                  '2' : InputByte('%LFNew command color',GCol[2],
                                                  [InteractiveEdit,NumbersOnly],0,9,Changed);
                                  '3' : InputByte('%LFNew description color',GCol[3],
                                                  [InteractiveEdit,NumbersOnly],0,9,Changed);
                                END;
                              UNTIL (Cmd1 IN ['Q',^M]) OR (HangUp);
                              Cmd1 := #0;
                            END;
                      'C' : BEGIN
                              IF (Changed) THEN
                                BEGIN
                                  Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                                  Write(MenuFile,MenuR);
                                  Changed := FALSE;
                                END;
                              CommandEditor(RecNumToModify,MenuNum,LDesc[1]);
                              SaveRecNumToModify := -1;
                            END;
                      'N' : IF (General.MultiNode) THEN
                              InputString('%LF^0New node activity description:%LF^2: ',NodeActivityDesc,
                                  (SizeOf(NodeActivityDesc) - 1),[InteractiveEdit],Changed);
                      'T' : BEGIN
                              REPEAT
                                InputChar('%LF^2Toggle which menu flag? ('+DisplayMenuFlags(MenuFlags,'1','2')+'^2)'+
                                ' [(^1?^2)Help,<^1CR^2>Quit]: ',Cmd1,^M'CDTNPAF12345?',[CapAll]);
                                CASE Cmd1 OF
                                  'C','D','T','N','P','A','F','1'..'5' :
                                    ToggleMenuFlags(Cmd1,MenuFlags,Changed);
                                  '?' : BEGIN
                                          NL;
                                          LCmds(21,1,'Clear screen',         'Don''t center titles');
                                          LCmds(21,1,'No menu prompt',       'Pause before display');
                                          LCmds(21,1,'Auto Time display',    'Force line input');
                                          LCmds(21,1,'Titles not displayed', '1 No ANS prompt');
                                          LCmds(21,1,'2 No AVT prompt',      '3 No RIP prompt');
                                          LCmds(21,1,'4 No Global disp',     '5 No global use');
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
                      ']' : IF (RecNumToModify < NumMenus) THEN
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
                              InputInteger('%LFJump to entry?',RecNumToModify,[NumbersOnly],1,NumMenus,Changed);
                              IF (RecNumToModify < 1) AND (RecNumToModify > NumMenus) THEN
                                Cmd1 := #0;
                            END;
                      '}' : IF (RecNumToModify <> NumMenus) THEN
                              RecNumToModify := NumMenus
                            ELSE
                              BEGIN
                                Messages(3,0,'');
                                Cmd1 := #0;
                              END;
                      '?' : BEGIN
                              NL;
                              LCmds(17,1,'[Previous Record',']Next Record');
                              LCmds(17,1,'{First Record','}Last Record');
                              LCmds(17,1,';Jump To Record','');
                            END;
                    END;
                  UNTIL (Pos(Cmd1,'QC[]FJL') <> 0) OR (HangUp);
                IF (Changed) THEN
                  BEGIN
                    Seek(MenuFile,MenuRecNumArray[SaveRecNumToModify]);
                    Write(MenuFile,MenuR);
                    Changed := FALSE;
                    SysOpLog('* Modified menu: ^1'+Menur.LDesc[1]);
                  END;
              END;
            Close(MenuFile);
            LastError := IOResult;
          END;
      END;
  END;

BEGIN
  LoadMenuPointers;
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      BEGIN
        ConfigHeader('Menu Editor',0,0);
        DisplayMenus(RecNumToList,TRUE);
      END;
    InputChar('%LF^2Menu Editor [^1DIM^2,(^1?^2)Help,<^1CR^2>Page,(^1Q^2)uit]: ',Cmd,'QDIM?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumMenus) THEN
              RecNumToList := 1;
      'D' : DeleteMenu;
      'I' : InsertMenu;
      'M' : ModifyMenu;
      '?' : BEGIN
              NL;
              LCmds3(12,1,'Delete Menu','Insert Menu','Modify Menu');
            END;
    END;
    IF (CMD <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
  LoadMenuPointers;
  IF (UserOn) THEN
    BEGIN
      SaveCurMenu := CurMenu;
      NumCmds := 0;
      GlobalCmds := 0;
      IF (General.GlobalMenu > 0) THEN
        BEGIN
          CurMenu := General.GlobalMenu;
          LoadMenu;
          GlobalCmds := NumCmds;
        END;
      CurMenu := SaveCurMenu;
      LoadMenu;
    END;
END;

END.