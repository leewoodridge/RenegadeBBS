{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 10/21/2021 - Added desc to color scheme #s
 03/09/2023 - Nested ShowColors in ColorConfig proc
 03/09/2023 - Error messages now using Messages PROC
 01/29/2024 - Prompt,Help aesthetics
}
UNIT SysOp2J;

INTERFACE

FUNCTION DisplayColorStr(Color: Byte): STRING;
FUNCTION GetColor: Byte;
PROCEDURE ColorConfiguration;

IMPLEMENTATION

USES
  Common,
  File11,
  File1,
  Mail4,
  SysOp2, {ConfigHeader,HL}
  TimeFunc;

CONST
  ColorName: ARRAY[0..7] OF STRING[7] = ('Black','Blue','Green','Cyan','Red','Magenta','Yellow','White');
  ColorDesc: ARRAY[0..9] OF STRING[17] = ('Normal Text','Bright Text','Prompt','Input Field','Header Text','Header Border',
                                          'Lightbar Normal','Lightbar Selected','Warning/Error','Notification');

  FUNCTION DisplayColorStr(Color: Byte): STRING;
  VAR
    TempStr: AStr;
  BEGIN
    TempStr := ColorName[Color AND 7]+' on '+ColorName[(Color SHR 4) AND 7];
    IF ((Color AND 8) <> 0) THEN
      TempStr := 'Bright '+TempStr;
    IF ((Color AND 128) <> 0) THEN
      TempStr := 'Blinking '+TempStr;
    DisplayColorStr := TempStr;
  END;

  FUNCTION GetColor: Byte;
  VAR
    NewColor,
    SaveOldColor,
    TempColor,
    Counter: Byte;
  BEGIN
    SetC(7);
    NL;
    FOR Counter := 0 TO 7 DO
    BEGIN
      SetC(7);
      Prompt(IntToStr(Counter)+'. ');
      SetC(Counter);
      Prompt(PadLeftStr(ColorName[Counter],12));
      SetC(7);
      Prompt(PadRightInt((Counter + 8),2)+'. ');
      SetC(Counter + 8);
      Print(PadLeftStr(ColorName[Counter]+'!',9));
    END;
    InputByte('%LFForeground',TempColor,[Numbersonly],0,15,Changed); (* Suppress Error *)
    IF (TempColor IN [0..15]) THEN
      NewColor := TempColor
    ELSE
      NewColor := 7;
    NL;
    FOR Counter := 0 TO 7 DO
    BEGIN
      SetC(7);
      Prompt(IntToStr(Counter)+'. ');
      SetC(Counter);
      Print(PadLeftStr(ColorName[Counter],12));
    END;
    InputByte('%LFBackground',TempColor,[NumbersOnly],0,7,Changed);  (* Suppress Error *)
    IF (TempColor IN [0..7]) THEN
      NewColor := NewColor OR TempColor SHL 4;
    IF PYNQ('%LFBlinking? ',0,FALSE) THEN
      NewColor := NewColor OR 128;
    SetC(7);
    Prompt('%LFExample: ');
    SetC(NewColor);
    Print(DisplayColorStr(NewColor));
    SetC(7);
    GetColor := NewColor;
  END;

PROCEDURE ColorConfiguration;
VAR
  TempScheme: SchemeRec;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  PROCEDURE ShowColors;
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := 1 TO 10 DO
      BEGIN
        SetC(Scheme.Color[Counter]);
        Prompt(IntToStr(Counter - 1));
        SetC(7);
        Prompt(' ');
      END;
    NL;
  END;

  PROCEDURE SystemColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    Counter,
    NewColor: Byte;
  BEGIN
    REPEAT
      CLS;
      NL;
      FOR Counter := 1 TO 10 DO
      BEGIN
        SetC(7);
        {Prompt(PadRightInt((Counter - 1),2)+'. System color '+PadRightInt((Counter - 1),2)+': ');}
        Prompt('^0(^1'+IntToStr(Counter-1)+'^0) '+PadLeftStr(ColorDesc[Counter-1],18)+': ');
        SetC(TempScheme1.Color[Counter]);
        Print(DisplayColorStr(Scheme.Color[Counter]));
      END;
      InputChar('%LFSystem color to change [^10^2-^19^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'0123456789',[CapAll]);
      IF (Cmd1 IN ['0'..'9']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) - Ord('0') + 1] := NewColor;
          Changed := TRUE;
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE FileColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    F: FileInfoRecordType;
    NewColor: Byte;
  BEGIN
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      FileAreaNameDisplayed := FALSE;
      DisplayFileAreaHeader;
      WITH F DO
      BEGIN
        FileName := 'RENEGADE.ZIP';
        Description := 'Latest version of Renegade!';
        FilePoints := 0;
        Downloaded := 0;
        FileSize := 2743;
        OwnerNum := 1;
        OwnerName:= 'Exodus';
        FileDate := Date2Pd(DateStr);
        VPointer := -1;
        VTextSize := 0;
        FIFlags := [];
      END;
      lDisplay_File(F,1,'',FALSE);
      PrintACR(PadLeftStr('',28)+'This is the latest version available');
      PrintACR(PadLeftStr('',28)+'Uploaded by: Exodus');
      WITH F DO
      BEGIN
        FileName := 'RG      .ZIP';
        Description := 'Latest Renegade upgrade.';
        FilePoints := 0;
        Downloaded := 0;
        FileSize := 2158;
        OwnerNum := 2;
        OwnerName := 'Nuclear';
        FileDate := Date2PD(DateStr);
        VPointer := -1;
        VTextSize := 0;
        FIFlags := [];
      END;
      lDisplay_File(F,2,'RENEGADE',FALSE);
      PrintACR(PadLeftStr('',28)+'This is the latest upgrade available');
      PrintACR(PadLeftStr('',28)+'Uploaded by: Nuclear');
      NL;
      LCmds3(20,1,'A Border','B File Name field','C Pts Field');
      LCmds3(20,1,'D Size field','E Desc Field','F Area field');
      NL;
      LCmds3(20,1,'G File name','H File Points','I File size');
      LCmds3(20,1,'J File desc','K Extended','L Status flags');
      LCmds(20,1,'M Uploader','N Search Match');
      InputChar('%LFFile color to change [^1A^2-^1N^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEFGHIJKLMN',[CapAll]);
      IF (Cmd1 IN ['A'..'N']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) - 54] := NewColor;
          Changed := TRUE;
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE MsgColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    NewColor: Byte;
  BEGIN
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      CLS; { starts at color 28 }
      PrintACR('旼컴컴컫컴컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴쩡컴컴컴커');
      PrintACR('� Msg# � Sender            � Receiver           �  '+
               'Subject           �! Posted �');
      PrintACR('읕컴컴컨컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴좔컴컴컴켸');
      PrintACR('''* "2#      Exodus              $Nuclear              %Re: Renegade       &01/01/93');
      PrintACR('''> "3#      Nuclear             $Exodus               %RG Update          &01/01/93');
      NL;
      LCmds3(20,1,'A Border','B Msg Num field','C Sender Field');
      LCmds3(20,1,'D Receiver field','E Subject Field','F Date field');
      NL;
      LCmds3(20,1,'G Msg Num','H Msg Sender','I Msg Receiver');
      LCmds3(20,1,'J Subject','K Msg Date','L Status flags');
      InputChar('%LFMessage color to change [^1A^2-^1L^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEFGHIJKL',[CapAll]);
      IF (Cmd1 IN ['A'..'L']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) - 37] := NewColor;
          Changed := TRUE;
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE FileAreaColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    NewColor: Byte;
    FArea,
    NumFAreas: Integer;
    SaveConfSystem: Boolean;
  BEGIN
    SaveConfSystem := ConfSystem;
    ConfSystem := FALSE;
    IF (SaveConfSystem) THEN
      NewCompTables;
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      Farea := 1;
      NumFAreas := 0;
      LFileAreaList(FArea,NumFAreas,10,TRUE);   { starts at 45 }
      NL;
      LCmds3(20,1,'A Border','B Base Num field','C Base Name Field');
      NL;
      LCmds3(20,1,'D Scan Indicator','E Base Number','F Base Name');
      InputChar('%LFFile area color to change [^1A^2-^1F^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEF',[CapAll]);
      IF (Cmd1 IN ['A'..'F']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) - 20] := NewColor;
          Changed := TRUE;
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
    ConfSystem := SaveConfSystem;
    IF (SaveConfSystem) THEN
      NewCompTables;
  END;

  PROCEDURE MsgAreaColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    NewColor: Byte;
    MArea,
    NumMAreas: Integer;
  BEGIN
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      MArea := 1;
      NumMAreas := 0;
      MessageAreaList(MArea,NumMAreas,5,TRUE);   { starts at 55 }
      NL;
      LCmds3(20,3,'A Border','B Base Num field','C Base Name Field');
      NL;
      LCmds3(20,3,'D Scan Indicator','E Base Number','F Base Name');
      InputChar('%LFMessage area color to change [^1A^2-^1F^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEF',[CapAll]);
      IF (Cmd1 IN ['A'..'F']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) - 10] := NewColor;
          Changed := TRUE; { LeeW: Added}
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE QWKColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    NewColor: Byte;
  BEGIN
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      CLS;  { starts at 115 }
      Print(Centre('|The QWK�System is now gathering mail.'));
      NL;
      PrintACR('s旼컴컴쩡컴컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴쩡컴컴컫컴컴컴컴컫컴컴컫컴컴컴쩡컴컴커');
      PrintACR('s�t Num s�u Message base name     s�v  Short  s�w Echo s�x  Total  '+
               's�y New s�z Your s�{ Size s�');
      PrintACR('s읕컴컴좔컴컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴좔컴컴컨컴컴컴컴컨컴컴컨컴컴컴좔컴컴켸');
      PrintACR('   }1    ~General                 GENERAL    �No      �530     �328    �13    �103k');
      PrintACR('   }2    ~Not so general          NSGEN      �No      �854     � 86    �15     �43k');
      PrintACR('   }3    ~Vague                   VAGUE      �No      �985     �148     �8     �74k');
      NL;
      LCmds3(20,1,'A Border','B Base num field','C Base name field');
      LCmds3(20,1,'D Short field','E Echo field','F Total field');
      LCmds3(20,1,'G New field','H Your field','I Size field');
      NL;
      LCmds3(20,1,'J Title','K Base Number','L Base name');
      LCmds3(20,1,'M Short','N Echo flag','O Total Msgs');
      LCmds3(20,1,'P New Msgs','R Your Msgs','S Msgs size');
      InputChar('%LFQWK color to change [^1A^2-^1S^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ABCDEFGHIJKLMNOPRS'^M,[CapAll]);
      IF (Cmd1 IN ['A'..'P','R'..'S']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
          IF (Cmd1 < 'Q') THEN
          BEGIN
            TempScheme1.Color[Ord(Cmd1) + 50] := NewColor;
            Changed := TRUE;
          END
          ELSE
          BEGIN
            TempScheme1.Color[Ord(Cmd1) + 49] := NewColor;
            Changed := TRUE;
          END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE EmailColors(VAR TempScheme1: SchemeRec; Cmd1: Char; VAR Changed: Boolean);
  VAR
    NewColor: Byte;
  BEGIN
    REPEAT
      Abort := FALSE;
      Next := FALSE;
      CLS;   { starts at 135 }
      PrintACR('뉅컴컴컫컴컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴컴컴컴커');
      PrintACR('눛� Num 눛� Date/Time         눛� Sender                 눛� Subject                  눛');
      PrintACR('눩컴컴컨컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴켸');
      PrintACR('    �1  �01 Jan 1993  01:00a 랤xodus                   뢗enegade');
      PrintACR('    �1  �01 Jan 1993  01:00a 랲uclear                  뢚pgrades');
      NL;
      LCmds3(20,1,'A Border','B Number field','C Date/Time field');
      LCmds(20,1,'D Sender field','E Subject field');
      NL;
      LCmds3(20,1,'F Number','G Date/Time','H Sender');
      LCmds(20,1,'I Subject','');
      InputChar('%LFEmail color to change [^1A^2-^1I^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'QABCDEFGHI',[CapAll]);
      IF (Cmd1 IN ['A'..'I']) THEN
      BEGIN
        NewColor := GetColor;
        IF PYNQ('%LFIs this correct? ',0,FALSE) THEN
        BEGIN
          TempScheme1.Color[Ord(Cmd1) + 70] := NewColor;
          Changed := TRUE;
        END;
      END;
    UNTIL (Cmd1 = ^M) OR (HangUp);
  END;

  PROCEDURE InitSchemeVars(VAR Scheme: SchemeRec);
  BEGIN
    WITH Scheme DO
    BEGIN
      Description := '<< New Color Scheme >>';
      FillChar(Color,SizeOf(Color),7);
      Color[1] := 15;
      Color[2] := 3;
      Color[3] := 13;
      Color[4] := 11;
      Color[5] := 9;
      Color[6] := 14;
      Color[7] := 31;
      Color[8] := 4;
      Color[9] := 132;
      Color[10] := 10;
    END;
  END;

  PROCEDURE DeleteScheme(TempScheme1: SchemeRec; RecNumToDelete: Integer);
  VAR
    User: UserRecordType;
    RecNum: Integer;
  BEGIN
    IF (NumSchemes = 0) THEN
      Messages(4,0,'color schemes')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFColor scheme to delete',RecNumToDelete,[NumbersOnly],1,NumSchemes,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumSchemes) THEN
      BEGIN
        Reset(SchemeFile);
        Seek(SchemeFile,(RecNumToDelete - 1));
        Read(SchemeFile,TempScheme1);
        Close(SchemeFile);
        LastError := IOResult;
        Print('%LFColor scheme: ^1'+TempScheme1.Description);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting color scheme record ...');
          Dec(RecNumToDelete);
          Reset(SchemeFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(SchemeFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(SchemeFile) - 2) DO
            BEGIN
              Seek(SchemeFile,(RecNum + 1));
              Read(SchemeFile,Scheme);
              Seek(SchemeFile,RecNum);
              Write(SchemeFile,Scheme);
            END;
          Seek(SchemeFile,(FileSize(SchemeFile) - 1));
          Truncate(SchemeFile);
          Close(SchemeFile);
          LastError := IOResult;
          Dec(NumSchemes);
          SysOpLog('* Deleted color scheme: ^1'+TempScheme1.Description);
          Inc(RecNumToDelete);
          Print('%LFUpdating user records ...');
          Reset(UserFile);
          RecNum := 1;
          WHILE (RecNum < FileSize(UserFile)) DO
          BEGIN
            LoadURec(User,RecNum);
            IF (User.ColorScheme = RecNumToDelete) THEN
            BEGIN
              User.ColorScheme := 1;
              SaveURec(User,RecNum);
            END
            ELSE IF (User.ColorScheme > RecNumTodelete) THEN
            BEGIN
              Dec(User.ColorScheme);
              SaveURec(User,RecNum);
            END;
            Inc(RecNum);
          END;
          Close(UserFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE CheckScheme(Scheme: SchemeRec; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Scheme.Description = '') OR (Scheme.Description = '<< New Color Scheme >>') THEN
            BEGIN
              Print('%LF^8The description is invalid!^0');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditScheme(TempScheme1: SchemeRec; VAR Scheme: SchemeRec; VAR Cmd1: Char;
                            VAR RecNumToEdit: Integer; VAR Changed: Boolean; Editing: Boolean);
  VAR
    CmdStr: AStr;
    Ok: Boolean;
  BEGIN
    WITH Scheme DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          IF (Editing) THEN
            ConfigHeader('Editing Color Scheme',RecNumToEdit,NumSchemes)
          ELSE
            ConfigHeader('Inserting Color Scheme',RecNumToEdit,NumSchemes+1);
          PrintACR('^0(^11^0) Description   : ^1'+Scheme.Description);
          Prompt('^0(^12^0) System colors : ');
          ShowColors;
          PrintACR('^0(^13^0) File listings');
          PrintACR('^0(^14^0) Message listings');
          PrintACR('^0(^15^0) File area listings');
          PrintACR('^0(^16^0) Message area listings');
          PrintACR('^0(^17^0) Offline mail screen');
          PrintACR('^0(^18^0) Private mail listing');
        END;
        NL;
        IF (NOT Editing) THEN
          InputChar('^2Color Scheme Editor [^11^2-^18^2,(^1Q^2)uit]: ',Cmd1,'12345678Q'^M,[CapAll])
        ELSE
          InputChar('^2Color Scheme Editor [^11^2-^18^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'12345678[]{}?Q;'^M,[CapAll]);
        CASE Cmd1 OF
          '1' : REPEAT
                  TempScheme1.Description := Description;
                  Ok := TRUE;
                  InputString('%LFNew description: ',Description,(SizeOf(Description) - 1),[InterActiveEdit],Changed);
                  CheckScheme(Scheme,1,1,Ok);
                  IF (NOT Ok) THEN
                    Description := TempScheme1.Description;
                UNTIL (Ok) OR (HangUp);
          '2' : SystemColors(Scheme,Cmd1,Changed);
          '3' : FileColors(Scheme,Cmd1,Changed);
          '4' : MsgColors(Scheme,Cmd1,Changed);
          '5' : FileAreaColors(Scheme,Cmd1,Changed);
          '6' : MsgAreaColors(Scheme,Cmd1,Changed);
          '7' : QWKColors(Scheme,Cmd1,Changed);
          '8' : EmailColors(Scheme,Cmd1,Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumSchemes) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '{' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ';' : BEGIN
                  InputInteger('%LFJump to entry?',RecNumToEdit,[NumbersOnly],1,NumSchemes,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumSchemes) THEN
                    Cmd1 := #0;
                END;
          '}' : IF (RecNumToEdit <> NumSchemes) THEN
                  RecNumToEdit := NumSchemes
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
      UNTIL (Pos(Cmd1,'Q[]{};') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertScheme(TempScheme1: SchemeRec; Cmd1: Char; RecNumToInsertBefore: Integer);
  VAR
    User: UserRecordType;
    RecNum,
    RecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumSchemes = MaxSchemes) THEN
      Messages(5,MaxSchemes,'color schemes')
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFColor scheme to insert before',RecNumToInsertBefore,[NumbersOnly],1,(NumSchemes + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumSchemes + 1)) THEN
      BEGIN
        Reset(SchemeFile);
        InitSchemeVars(TempScheme1);
        IF (RecNumToInsertBefore = 1) THEN
          RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumSchemes + 1)) THEN
          RecNumToEdit := (NumSchemes + 1)
        ELSE
          RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditScheme(TempScheme1,TempScheme1,Cmd1,RecNumToEdit,Changed,FALSE);
          CheckScheme(TempScheme1,1,1,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting color scheme? ',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
        BEGIN
          Print('%LF[> Inserting color scheme record ...');
          Seek(SchemeFile,FileSize(SchemeFile));
          Write(SchemeFile,Scheme);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(SchemeFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(SchemeFile,RecNum);
            Read(SchemeFile,Scheme);
            Seek(SchemeFile,(RecNum + 1));
            Write(SchemeFile,Scheme);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            Seek(SchemeFile,RecNum);
            Write(SchemeFile,TempScheme1);
            Inc(NumSchemes);
            SysOpLog('* Inserted color scheme: ^1'+TempScheme1.Description);
          END;
        END;
        Close(SchemeFile);
        LastError := IOResult;
        Inc(RecNumToInsertBefore);
        Print('%LFUpdating user records ...');
        Reset(UserFile);
        RecNum := 1;
        WHILE (RecNum < FileSize(UserFile)) DO
        BEGIN
          LoadURec(User,RecNum);
          IF (User.ColorScheme >= RecNumToInsertBefore) THEN
          BEGIN
            Inc(User.ColorScheme);
            SaveURec(User,RecNum);
          END;
          Inc(RecNum);
        END;
        Close(UserFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ModifyScheme(TempScheme1: SchemeRec; Cmd1: Char; RecNumToEdit: Integer);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumSchemes = 0) THEN
      Messages(4,0,'color schemes')
    ELSE
    BEGIN
      RecNumToEdit := -1;
      InputInteger('%LFColor scheme to modify',RecNumToEdit,[NumbersOnly],1,NumSchemes,Changed);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumSchemes) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(SchemeFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (RecNumToEdit <> SaveRecNumToEdit) THEN
          BEGIN
            Seek(SchemeFile,(RecNumToEdit - 1));
            Read(SchemeFile,Scheme);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditScheme(TempScheme1,Scheme,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckScheme(Scheme,1,1,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(SchemeFile,(SaveRecNumToEdit - 1));
            Write(SchemeFile,Scheme);
            SysOpLog('* Modified color scheme: ^1'+Scheme.Description);
          END;
        END;
        Close(SchemeFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE PositionScheme(TempScheme1: SchemeRec);
  VAR
    User: UserRecordType;
    RecNumToPosition,
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (NumSchemes = 0) THEN
      Messages(4,0,'color schemes')
    ELSE IF (NumSchemes = 1) THEN
      Messages(6,0,'color schemes')
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputInteger('%LFPosition which color scheme',RecNumToPosition,[NumbersOnly],1,NumSchemes,Changed);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumSchemes) THEN
      BEGIN
        Print('%LFAccording to the current numbering system.');
        RecNumToPositionBefore := -1;
        InputInteger('%LFPosition before which color scheme',RecNumToPositionBefore,[NumbersOnly],
        1,(NumSchemes + 1),Changed);
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumSchemes + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Print('%LF[> Positioning color scheme record ...');
          Reset(SchemeFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(SchemeFile,RecNumToPosition);
          Read(SchemeFile,TempScheme1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(SchemeFile)) THEN
            BEGIN
              Seek(SchemeFile,(RecNum1 + RecNum2));
              Read(SchemeFile,Scheme);
              Seek(SchemeFile,RecNum1);
              Write(SchemeFile,Scheme);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(SchemeFile,RecNumToPositionBefore);
          Write(SchemeFile,TempScheme1);
          Close(SchemeFile);
          LastError := IOResult;
          Inc(RecNumToPosition);
          Inc(RecNumToPositionBefore);
          Print('%LFUpdating user records ...');
          Reset(UserFile);
          RecNum1 := 1;
          WHILE (RecNum1 < FileSize(UserFile)) DO
          BEGIN
            LoadURec(User,RecNum1);
            IF (User.ColorScheme = RecNumToPosition) THEN
            BEGIN
              User.ColorScheme := RecNumToPositionBefore;
              SaveURec(User,RecNum1);
            END
            ELSE IF (User.ColorScheme = RecNumToPositionBefore) THEN
            BEGIN
              User.ColorScheme := RecNumToPosition;
              SaveURec(User,RecNum1);
            END;
            Inc(RecNum1);
          END;
          Close(UserFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  PROCEDURE ListSchemes(VAR RecNumToList1: Integer);
  VAR
    NumDone: Integer;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumSchemes) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    {CLS;}
    ConfigHeader('Color Scheme Editor',0,0);
    PrintACR('^5<^4##^5> <^4Description^5>                  <^4Colors^5>');
    HL;
    {PrintACR('^1###^2:^1'+PadLeftStr('Description',30)+'^2:^1Colors');
    PrintACR('^2===:==============================:============================');}
    Reset(SchemeFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumSchemes)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(SchemeFile,(RecNumToList1 - 1));
      Read(SchemeFile,Scheme);
      WITH Scheme DO
        Prompt(' ^1'+PadLeftInt(RecNumToList1,4)+
               ' ^0'+PadLeftStr(Description,30)+
               ' ');
      ShowColors;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(SchemeFile);
    LastError := IOResult;
    IF (NumSchemes = 0) THEN
    Messages(4,0,'color schemes'); { "No color schemes exist!" }
      (*Print('*** No color schemes defined ***');*)
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListSchemes(RecNumToList);
    NL;
    InputChar('^2Color Scheme Editor [^1DIMP^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'QDIMP?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumSchemes) THEN
              RecNumToList := 1;
      'D' : DeleteScheme(TempScheme,RecNumToList);
      'I' : InsertScheme(TempScheme,Cmd,RecNumToList);
      'M' : ModifyScheme(TempScheme,Cmd,RecNumToList);
      'P' : PositionScheme(TempScheme);
      '?' : BEGIN
              Print('%LF^0<^1CR^0>Next screen or redisplay current screen');
              Print('^0(^1?^0)Help/First color scheme');
              LCmds(20,1,'Delete color scheme','Insert color scheme');
              LCmds(20,1,'Modify color scheme','Position color scheme');
              LCmds(20,1,'Quit','');
            END;
    END;
    IF (CMD <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  IF (ThisUser.ColorScheme < 1) OR (ThisUser.ColorScheme > FileSize(SchemeFile)) THEN
    ThisUser.ColorScheme := 1;
  Reset(SchemeFile);
  Seek(SchemeFile,(ThisUser.ColorScheme - 1));
  Read(SchemeFile,Scheme);
  Close(SchemeFile);
  LastError := IOResult;
END;

END.
