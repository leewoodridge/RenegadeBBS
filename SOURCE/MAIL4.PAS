{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
ansiok check for lightbar menu???
}
UNIT Mail4;

INTERFACE

USES
  Common;

PROCEDURE MessageAreaList(VAR MArea,NumMAreas: Integer; AdjPageLen: Byte; ShowScan: Boolean);
PROCEDURE MessageAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);
PROCEDURE ToggleMsgAreaScanFlags;

IMPLEMENTATION

USES
  Crt,
  Common5,
  Mail0;

PROCEDURE MessageAreaList(VAR MArea,NumMAreas: Integer; AdjPageLen: Byte; ShowScan: Boolean);
VAR
  ScanChar: Str1;
  TempStr: AStr;
  NumOnline,
  NumDone: Byte;
  SaveMsgArea: Integer;
BEGIN
  SaveMsgArea := MsgArea;
  Abort := FALSE;
  Next := FALSE;
  NumOnline := 0;
  TempStr := '';

  FillChar(LightBarArray,SizeOf(LightBarArray),0);
  LightBarCounter := 0;

  {
  $New_Scan_Char_Message
  �
  $
  }
  IF (ShowScan) THEN
    ScanChar := lRGLngStr(66,TRUE);
  {
  $Message_Area_Select_Header
  %CL7�����������������������������������������������������������������������������Ŀ
  7�8 Num 7�9 Name                           7�8 Num 7�9 Name                           7�
  7�������������������������������������������������������������������������������
  $
  }
  lRGLngStr(58,FALSE);
  Reset(MsgAreaFile);
  NumDone := 0;
  WHILE (NumDone < (PageLength - AdjPageLen)) AND (MArea >= 1) AND (MArea <= NumMsgAreas) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    LoadMsgArea(MArea);
    IF (ShowScan) THEN
      LoadLastReadRecord(LastReadRecord);
    IF (AACS(MemMsgArea.ACS)) OR (MAUnHidden IN MemMsgArea.MAFlags) THEN
    BEGIN

      IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
      BEGIN
        Inc(LightBarCounter);
        LightBarArray[LightBarCounter].CmdToExec := CompMsgArea(MArea,0);
        LightBarArray[LightBarCounter].CmdToShow := MemMsgArea.Name;
        IF (NumOnline = 0) THEN
        BEGIN
          LightBarArray[LightBarCounter].Xpos := 8;
          LightBarArray[LightBarCounter].YPos := WhereY;
        END
        ELSE
        BEGIN
          LightBarArray[LightBarCounter].Xpos := 47;
          LightBarArray[LightBarCounter].YPos := WhereY;
        END;
      END;

      TempStr := TempStr + AOnOff(ShowScan AND LastReadRecord.NewScan,':'+ScanChar[1],' ')+
                           PadLeftStr(PadRightStr(';'+IntToStr(CompMsgArea(MArea,0)),5)+
                           +'< '+MemMsgArea.Name,37)+' ';
      Inc(NumOnline);
      IF (NumOnline = 2) THEN
      BEGIN
        PrintaCR(TempStr);
        NumOnline := 0;
        Inc(NumDone);
        TempStr := '';
      END;
      Inc(NumMAreas);
    END;
    WKey;
    Inc(MArea);
  END;
  Close(MsgAreaFile);
  LastError := IOResult;
  IF (NumOnline = 1) AND (NOT Abort) AND (NOT HangUp) THEN
    PrintACR(TempStr)
  ELSE IF (NumMAreas = 0) AND (NOT Abort) AND (NOT HangUp) THEN
    LRGLngStr(68,FALSE);
  {
  %LF^8No message areas!^0'
  }
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
END;

PROCEDURE MessageAreaChange(VAR Done: Boolean; CONST MenuOption: Str50);
VAR
  InputStr: Str5;
  Cmd: Char;
  MArea,
  NumMAreas,
  SaveMArea: Integer;
  SaveTempPause: Boolean;
BEGIN
{
no param goes to lightbar selection
l param goes to regular selection
}

  IF (MenuOption <> '') THEN
    CASE UpCase(MenuOption[1]) OF
      '+' : BEGIN
              MArea := MsgArea;
              IF (MsgArea >= NumMsgAreas) THEN
                MArea := 0
              ELSE
              REPEAT
                Inc(MArea);
                ChangeMsgArea(MArea);
              UNTIL (MsgArea = MArea) OR (MArea >= NumMsgAreas);
              IF (MsgArea <> MArea) THEN
              BEGIN
                {
                %LFHighest accessible message area.
                %PA
                }
                LRGLngStr(85,FALSE);
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      '-' : BEGIN
              MArea := MsgArea;
              IF (MsgArea <= 0) THEN
                MArea := 0
              ELSE
              REPEAT
                Dec(MArea);
                ChangeMsgArea(MArea);
              UNTIL (MsgArea = MArea) OR (MArea <= 0);
              IF (MsgArea <> MArea) THEN
              BEGIN
                {
                %LFLowest accessible message area.
                %PA
                }
                LRGLngStr(84,FALSE);
              END
              ELSE
                LastCommandOvr := TRUE;
            END;
      'L' : BEGIN
              SaveTempPause := TempPause;
              TempPause := FALSE;
              MArea := 1;
              NumMAreas := 0;
              Cmd := '?';
              REPEAT
                SaveMArea := MArea;
                IF (Cmd = '?') THEN
                  MessageAreaList(MArea,NumMAreas,6,FALSE);
                {
                %LFMessage area list? [^1?^2=^1Help^2,^1Q^2=^1Quit^2]: @
                }
                InputChar(LRGLngStr(69,TRUE),Cmd,'Q?[]',[CapAll]);
                TempPause := FALSE;
                IF (Cmd <> 'Q') THEN
                BEGIN
                  IF (Cmd = '[') THEN
                  BEGIN
                    MArea := (SaveMArea - ((PageLength - 5) * 2));
                    IF (MArea < 1) THEN
                      MArea := 1;
                    Cmd := '?';
                  END
                  ELSE IF (Cmd = ']') THEN
                  BEGIN
                    IF (MArea > NumMsgAreas) THEN
                      MArea := SaveMArea;
                    Cmd := '?';
                  END
                END
                ELSE IF (Cmd = '?') THEN
                BEGIN
                  {
                  $File_Message_Area_List_Help
                  %LF^0(^1###^0)Manual entry selection  ^0(^1<CR>^0)Select current entry
                  ^0(^1<Home>^0)First entry on page  ^0(^1<End>^0)Last entry on page
                  ^0(^1Left Arrow^0)Previous entry   ^0(^1Right Arrow^0)Next entry
                  ^0(^1Up Arrow^0)Move up            ^0(^1Down Arrow^0)Move down
                  ^0(^1[^0)Previous page             ^0(^1]^0)Next page
                  %PA
                  }
                  LRGLngStr(71,FALSE);
                  MArea := SaveMArea;
                END
              UNTIL (Cmd = 'Q') OR (HangUp);
              TempPause := SaveTempPause;
              LastCommandOvr := TRUE;
            END;
    ELSE
    BEGIN
      IF (StrToInt(MenuOption) > 0) THEN
      BEGIN
        MArea := StrToInt(MenuOption);
        IF (MArea <> MsgArea) THEN
          ChangeMsgArea(MArea);
        IF (Pos(';',MenuOption) > 0) THEN
        BEGIN
          CurMenu := StrToInt(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)));
          NewMenuToLoad := TRUE;
          Done := TRUE;
        END;
        LastCommandOvr := TRUE;
      END;
    END;
  END
  ELSE
  BEGIN {lightbar area selection}
    SaveTempPause := TempPause;
    TempPause := FALSE;
    MArea := 1;
    NumMAreas := 0;
    LightBarCmd := 1;
    LightBarFirstCmd := TRUE;
    InputStr := '?';
    REPEAT
      SaveMArea := MArea;
      IF (InputStr = '?') THEN
        MessageAreaList(MArea,NumMAreas,6,FALSE);
      {
      %LFChange message area? [^1#^2,^1?^2=^1Help^2,^1Q^2=^1Quit^2]: @
      }
      MsgAreaScanInput(LRGLngStr(73,TRUE),Length(IntToStr(HighMsgArea)),InputStr,'Q[]?',LowMsgarea,HighMsgArea);
      IF (InputStr <> 'Q') THEN
      BEGIN
        IF (InputStr = '[') THEN
        BEGIN
          MArea := (SaveMArea - ((PageLength - 5) * 2));
          IF (MArea < 1) THEN
            MArea := 1;
          InputStr := '?';
        END
        ELSE IF (InputStr = ']') THEN
        BEGIN
          IF (MArea > NumMsgAreas) THEN
            MArea := SaveMArea;
          InputStr := '?';
        END
        ELSE IF (InputStr = '?') THEN
        BEGIN
          {
          $File_Message_Area_List_Help
          %LF^0(^1###^0)Manual entry selection  ^0(^1<CR>^0)Select current entry
          ^0(^1<Home>^0)First entry on page  ^0(^1<End>^0)Last entry on page
          ^0(^1Left Arrow^0)Previous entry   ^0(^1Right Arrow^0)Next entry
          ^0(^1Up Arrow^0)Move up            ^0(^1Down Arrow^0)Move down
          ^0(^1[^0)Previous page             ^0(^1]^0)Next page
          %PA
          }
          LRGLngStr(71,FALSE);
          MArea := SaveMArea;
        END
        ELSE IF (StrToInt(InputStr) < LowMsgArea) OR (StrToInt(InputStr) > HighMsgArea) THEN
        BEGIN
          {
          %LF^8The range must be from %A3 to %A4!^0
          }
          LRGLngStr(79,FALSE);
          MArea := SaveMArea;
          InputStr := '?';
        END
        ELSE
        BEGIN
          MArea := CompMsgArea(StrToInt(InputStr),1);
          IF (MArea <> MsgArea) THEN
            ChangeMsgArea(MArea);
          IF (MArea = MsgArea) THEN
            InputStr := 'Q'
          ELSE
          BEGIN
            {
            %LF^8You do not have access to this message area!^0
            }
            LRGLngStr(81,FALSE);
            MArea := SaveMArea;
            InputStr := '?';
          END;
        END;
      END;
    UNTIL (InputStr = 'Q') OR (HangUp);
    TempPause := SaveTempPause;
    LastCommandOvr := TRUE;
  END;
END;

PROCEDURE ToggleMsgAreaScanFlags;
VAR
  InputStr: Str11;
  FirstMArea,
  LastMArea,
  MArea,
  NumMAreas,
  SaveMArea,
  SaveMsgArea: Integer;
  SaveConfSystem,
  SaveTempPause: Boolean;

  PROCEDURE ToggleScanFlags(MArea1: Integer; ScanType: Byte);
  BEGIN
    IF (MsgArea <> MArea1) THEN
      ChangeMsgArea(MArea1);
    IF (MsgArea = MArea1) THEN
    BEGIN
      LoadLastReadRecord(LastReadRecord);
      IF (ScanType = 1) THEN
        LastReadRecord.NewScan := TRUE
      ELSE IF (ScanType = 2) THEN
      BEGIN
        IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) THEN
          LastReadRecord.NewScan := FALSE
        ELSE
          LastReadRecord.NewScan := TRUE;
      END
      ELSE IF (ScanType = 3) THEN
      BEGIN
        IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) THEN
          LastReadRecord.NewScan := (NOT LastReadRecord.NewScan)
        ELSE
          LastReadRecord.NewScan := TRUE;
      END;
      SaveLastReadRecord(LastReadRecord);
    END;
  END;

BEGIN
  SaveMsgArea := MsgArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  SaveTempPause := TempPause;
  TempPause := FALSE;
  MArea := 1;
  NumMAreas := 0;
  LightBarCmd := 1;
  LightBarFirstCmd := TRUE;
  InputStr := '?';
  REPEAT
    SaveMArea := MArea;
    IF (InputStr = '?') THEN
      MessageAreaList(MArea,NumMAreas,6,TRUE);
    {
    %LFToggle new scan? [^1#^2,^1#^2-^1#^2,^1F^2=^1Flag ^2or ^1U^2=^1Unflag All^2,^1?^2=^1Help^2,^1Q^2=^1Quit^2]: @
    }
    MsgAreaScanInput(LRGLngStr(75,TRUE),((Length(IntToStr(HighMsgArea)) *  2) + 1),InputStr,'QFU[]?',LowMsgArea,HighMsgArea);
    IF (InputStr <> 'Q') THEN
    BEGIN
      IF (InputStr = '[') THEN
      BEGIN
        MArea := (SaveMArea - ((PageLength - 5) * 2));
        IF (MArea < 1) THEN
          MArea := 1;
        InputStr := '?';
      END
      ELSE IF (InputStr = ']') THEN
      BEGIN
        IF (MArea > NumMsgAreas) THEN
          MArea := SaveMArea;
        InputStr := '?';
      END
      ELSE IF (InputStr = '?') THEN
      BEGIN
        {
        $File_Message_Area_List_Help
        %LF^0(^1###^0)Manual entry selection  ^0(^1<CR>^0)Select current entry
        ^0(^1<Home>^0)First entry on page  ^0(^1<End>^0)Last entry on page
        ^0(^1Left Arrow^0)Previous entry   ^0(^1Right Arrow^0)Next entry
        ^0(^1Up Arrow^0)Move up            ^0(^1Down Arrow^0)Move down
        ^0(^1[^0)Previous page             ^0(^1]^0)Next page
        %PA
        }
        LRGLngStr(71,FALSE);
        MArea := SaveMArea;
      END
      ELSE
      BEGIN
        MsgArea := 0;
        IF (InputStr = 'F') THEN
        BEGIN
          FOR MArea := 1 TO NumMsgAreas DO
            ToggleScanFlags(MArea,1);
          {
          %LFYou are now reading all message areas.
          }
          LRGLngStr(87,FALSE);
          MArea := 1;
          InputStr := '?';
        END
        ELSE IF (InputStr = 'U') THEN
        BEGIN
          FOR MArea := 1 TO NumMsgAreas DO
            ToggleScanFlags(MArea,2);
          {
          %LFYou are now not reading any message areas.
          }
          LRGLngStr(89,FALSE);
          MArea := 1;
          InputStr := '?';
        END
        ELSE IF (StrToInt(InputStr) > 0) THEN
        BEGIN
          FirstMArea := StrToInt(InputStr);
          IF (Pos('-',InputStr) = 0) THEN
            LastMArea := FirstMArea
          ELSE
          BEGIN
            LastMArea := StrToInt(Copy(InputStr,(Pos('-',InputStr) + 1),(Length(InputStr) - Pos('-',InputStr))));
            IF (FirstMArea > LastMArea) THEN
            BEGIN
              MArea := FirstMArea;
              FirstMArea := LastMArea;
              LastMArea := MArea;
            END;
          END;
          IF (FirstMArea < LowMsgArea) OR (LastMArea > HighMsgArea) THEN
          BEGIN
            {
            %LF^8The range must be from %A3 to %A4!^0
            }
            LRGLngStr(91,FALSE);
            MArea := SaveMArea;
            InputStr := '?';
          END
          ELSE
          BEGIN
            FirstMArea := CompMsgArea(FirstMArea,1);
            LastMArea := CompMsgArea(LastMArea,1);
            FOR MArea := FirstMArea TO LastMArea DO
              ToggleScanFlags(MArea,3);
            IF (FirstMArea = LastMArea) THEN
              IF (NOT (MAForceRead IN MemMsgArea.MAFlags)) THEN
              BEGIN
                LRGLngStr(93,FALSE); {"MessageBaseName will (not) be scanned"}
              END
              ELSE
              BEGIN
                LRGLngStr(94,FALSE); {"MessageBaseName can not be removed from your newscan"}
              END;
              MArea := SaveMArea;
              InputStr := '?';
          END;
        END;
        MsgArea := SaveMsgArea;
      END;
    END;
  UNTIL (InputStr = 'Q') OR (HangUp);
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  TempPause := SaveTempPause;
  MsgArea := SaveMsgArea;
  LoadMsgArea(MsgArea);
  LastCommandOvr := TRUE;
END;

END.
