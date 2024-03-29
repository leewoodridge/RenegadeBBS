{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

{
why does downloads show blank entries but users not???
added hmt files
04/15/2022 added check for download top files prompt
}

UNIT STATS;

INTERFACE

USES
  Common,
  CRT, {X&Y Coordinates}
  SysOp2; {HL}

TYPE
  Top10UserRec = RECORD
    RecNum: Byte; {LeeW: Added}
    UNum: Integer;
    Info: Real;
    Decimal: Byte; {LeeW: Added}
  END;

  Top10FileRec = RECORD
    RecNum: Byte; {LeeW: Added}
    DirNum,
    DirRecNum: Integer;
    Downloaded: LongInt;
  END;

  Top10UserArray = ARRAY [1..10] OF Top10UserRec;
  Top10FileArray = ARRAY [1..10] OF Top10FileRec;

  Top10UserPtrType = ^Top10UserRec;
  Top10FilePtrType = ^Top10FileRec;

  UserPtrType = ^UserRecordType;
  FilePtrType = ^FileInfoRecordType;

VAR
  Top10User: Top10UserArray;
  Top10File: Top10FileArray;

PROCEDURE GetUserStats(MenuOption: Str50);

IMPLEMENTATION

USES
  File0,
  File1,
  File11;

FUNCTION MaxR(R,R1: Real): Real;
BEGIN
  IF (R1 = 0.0) THEN
    MaxR := R
  ELSE
    MaxR := R1;
END;

FUNCTION TopUserMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  TopUserPtr: Top10UserPtrType;
  UserPtr: UserPtrType;
BEGIN
  TopUserPtr := Data1;
  UserPtr := Data2;
  TopUserMCI := S;
  CASE S[1] OF
    'L' : CASE S[2] OF
            'N' : TopUserMCI := IntToStr(TopUserPtr^.RecNum); { The List Number }
          END;
    'U' : CASE S[2] OF
            '#' : TopUserMCI := IntToStr(TopUserPtr^.UNum); { The Users Number }
            'N' : TopUserMCI := AOnOff(UserPtr^.Name = ThisUser.Name,'^9','^0')+UserPtr^.Name+'^0'; { The Users Handle }
            'R' : TopUserMCI := UserPtr^.RealName; { The Users Real Name }
            'V' : TopUserMCI := RealToStr(TopUserPtr^.Info,0,TopUserPtr^.Decimal); { The Statistic Value }
          END;
  END;
END;

FUNCTION TopFileMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  TopPtr: Top10FilePtrType;
  FilePtr: FilePtrType;
BEGIN
  TopPtr := Data1;
  FilePtr := Data2;
  TopFileMCI := S;
  CASE S[1] OF
    'L' : CASE S[2] OF
            'N' : TopFileMCI := IntToStr(TopPtr^.RecNum); { The List Number }
          END;
    'F' : CASE S[2] OF
            'N' : TopFileMCI := FilePtr^.Filename; { The Filename }
          END;
    'D' : CASE S[2] OF
            'L' : TopFileMCI := FormatNumber(TopPtr^.Downloaded); { Number Of Downloads }
          END;
  END;
END;

{---}

PROCEDURE InitTop10UserArray(VAR Top10User: Top10UserArray);
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO 10 DO
    BEGIN
      Top10User[Counter].RecNum := Counter;
      Top10User[Counter].UNum := -1;
      Top10User[Counter].Info := 0.0;
      Top10User[Counter].Decimal := 0;
    END;
END;

PROCEDURE InitTop10FileArray(VAR Top10User: Top10FileArray);
VAR
  Counter: Byte;
BEGIN
  FOR Counter := 1 TO 10 DO
    BEGIN
      Top10File[Counter].RecNum := Counter;
      Top10File[Counter].DirNum := -1;
      Top10File[Counter].DirRecNum := -1;
      Top10File[Counter].Downloaded := 0;
    END;
END;

PROCEDURE SortUserDecending(VAR Top10User: Top10UserArray; UNum: Integer; Info: Real; Decimal: Byte);
VAR
  Counter,
  Counter1: Byte;
BEGIN
  IF (Info > 0.0) THEN
    FOR Counter := 1 TO 10 DO
      IF (Info >= Top10User[Counter].Info) THEN
        BEGIN
          FOR Counter1 := 10 DOWNTO (Counter + 1) DO
            BEGIN
              Top10User[Counter1] := Top10User[Counter1 - 1];
              Top10User[Counter1].RecNum := Counter1; {LeeW: Added}
            END;
          Top10User[Counter].RecNum := Counter; {LeeW: Added}
          Top10User[Counter].UNum := UNum;
          Top10User[Counter].Info := Info;
          Top10User[Counter].Decimal := Decimal;
          Counter := 10;
        END;
END;

PROCEDURE SortFileDecending(VAR Top10File: Top10FileArray; DirNum,DirRecNum: Integer; Downloaded: LongInt);
VAR
  Counter,
  Counter1: Byte;
BEGIN
  IF (Downloaded > 0) THEN
    FOR Counter := 1 to 10 DO
      IF (Downloaded >= Top10File[Counter].Downloaded) THEN
        BEGIN
          FOR Counter1 := 10 DOWNTO (Counter + 1) DO
            BEGIN
              Top10File[Counter1] := Top10File[Counter1 - 1];
              Top10File[Counter1].RecNum := Counter1; {LeeW: Added}
            END;
          Top10File[Counter].RecNum := Counter; {LeeW: Added}
          Top10File[Counter].DirNum := DirNum;
          Top10File[Counter].DirRecNum := DirRecNum;
          Top10File[Counter].Downloaded := Downloaded;
          Counter := 10;
        END;
END;

PROCEDURE SearchTop10User(VAR Top10User: Top10UserArray; Cmd: Char; ExcludeUserNum: Integer; Decimal: Byte);
VAR
  User: UserRecordType;
  UNum: Integer;
  Info: Real;
BEGIN
  InitTop10UserArray(Top10User);
  Abort := FALSE;
  Next := FALSE;
  Reset(UserFile);
  UNum := 1;
  WHILE (UNum <= (FileSize(UserFile) - 1)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      IF (ExcludeUserNum = 0) OR (UNum <> ExcludeUserNum) THEN
        BEGIN
          Seek(UserFile,UNum);
          Read(UserFile,User);
          IF (NOT (Deleted IN User.SFlags)) AND (NOT (LockedOut IN User.SFlags)) THEN
            BEGIN
              CASE Cmd OF
                'A' : Info := User.TTimeOn;
                'B' : Info := User.UK;
                'C' : Info := User.DK;
                'D' : Info := User.EmailSent;
                'E' : Info := User.MsgPost;
                'F' : Info := User.FeedBack;
                'G' : Info := User.LoggedOn;
                'H' : Info := User.Uploads;
                'I' : Info := User.Downloads;
                'J' : Info := User.FilePoints;
                'K' : Info := (User.UK / MaxR(1.0,User.DK));
                'L' : Info := (User.MsgPost / MaxR(1.0,User.LoggedOn));
              END;
              SortUserDecending(Top10User,UNum,Info,Decimal);
            END;
        END;
      Inc(UNum);
    END;
  Close(UserFile);
END;

PROCEDURE SearchTop10AreaFileSpec(FArea: Integer; VAR Top10File: Top10FileArray);
VAR
  F: FileInfoRecordType;
  DirFileRecNum: Integer;
BEGIN
  IF (FileArea <> FArea) THEN
    ChangeFileArea(FArea);
  IF (FileArea = FArea) THEN
    BEGIN
      RecNo(F,'*.*',DirFileRecNum);
      IF (BadDownloadPath) THEN
        Exit;
      WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
        BEGIN
          Seek(FileInfoFile,DirFileRecNum);
          Read(FileInfoFile,F);
          IF (CanSee(F)) THEN
            SortFileDecending(Top10File,FileArea,DirFileRecNum,F.Downloaded);
          NRecNo(F,DirFileRecNum);
        END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
END;

PROCEDURE SearchTop10GlobalFileSpec(VAR Top10File: Top10FileArray);
VAR
  FArea,
  SaveFileArea: Integer;
  SaveConfSystem: Boolean;
BEGIN
  InitTop10FileArray(Top10File);
  SaveFileArea := FileArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  Abort := FALSE;
  Next := FALSE;
  FArea := 1;
  WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      SearchTop10AreaFileSpec(FArea,Top10File);
      WKey;
      IF (Next) THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
        END;
      Inc(FArea);
    END;
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
END;

PROCEDURE DisplayTop10UserArray(Top10User: Top10UserArray; Title,Header: AStr; Decimal,Width: Byte);
VAR
  User: UserRecordType;
  TempStr: AStr;
  Counter,
  Counter1: Byte;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  MCIPosRecArray[0].X := 0; { Header title }
  MCIPosRecArray[0].Y := 0;
  MCIPosRecArray[1].X := 0; { Data field title }
  MCIPosRecArray[1].Y := 0;
  PrintF('TOPUH');
  IF (NoFile) THEN
    BEGIN
      LangStringArray[0] := Centre(Title);
      LangStringArray[1] := PadRightStr(Header,20);
      lRGLngStr(261,FALSE) { $TOP_USERS_HEADER }
    END
  ELSE
    IF NOT (MCIPosRecArray[0].X = 0) AND NOT (MCIPosRecArray[1].X = 0) THEN
      BEGIN
        SaveX := WhereX;
        SaveY := WhereY;
        ANSIG(MCIPosRecArray[0].X,MCIPosRecArray[0].Y);
        Print(Centre(Title));
        ANSIG(MCIPosRecArray[1].X,MCIPosRecArray[1].Y);
        Print(PadRightStr(Header,20));
        ANSIG(SaveX,SaveY);
      END;
  Counter := 1;
  WHILE (Counter <= 10) AND (Top10User[Counter].UNum >= 1) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      LoadURec(User,Top10User[Counter].UNum);
      IF (NOT ReadBuffer('TOPUM')) THEN
        EXIT;
      DisplayBuffer(TopUserMCI,@Top10User[Counter],@User);
      Inc(Counter);
    END;
  PrintF('TOPUT');
  IF (NoFile) THEN
    HL;
  PauseScr(FALSE);
END;

{ --- }

PROCEDURE DisplayTop10FileArray(Top10File: Top10FileArray; Title,Header: AStr);
VAR
  F: FileInfoRecordType;
  TempStr: AStr;
  Counter,
  SaveFileArea: Integer;
  AddBatch: Boolean;
  TransferFlags: TransferFlagSet;
BEGIN
  SaveFileArea := FileArea;
  Abort := FALSE;
  Next := FALSE;
  MCIPosRecArray[0].X := 0; { Header title }
  MCIPosRecArray[0].Y := 0;
  MCIPosRecArray[1].X := 0; { Data field title }
  MCIPosRecArray[1].Y := 0;
  PrintF('TOPFH');
  IF (NoFile) THEN
    BEGIN
      LangStringArray[0] := Centre(Title);
      LangStringArray[1] := PadRightStr(Header,20);
      lRGLngStr(262,FALSE) { $TOP_FILES_HEADER }
    END
  ELSE
    IF NOT (MCIPosRecArray[0].X = 0) AND NOT (MCIPosRecArray[1].X = 0) THEN
      BEGIN
        SaveX := WhereX;
        SaveY := WhereY;
        ANSIG(MCIPosRecArray[0].X,MCIPosRecArray[0].Y);
        Print(Centre(Title));
        ANSIG(MCIPosRecArray[1].X,MCIPosRecArray[1].Y);
        Print(PadRightStr(Header,20));
        ANSIG(SaveX,SaveY);
      END;
  FOR Counter := 1 TO 10 DO
  { if not empty }
    BEGIN
      F.FileName := '';
      IF (Top10File[Counter].DirNum > 0) AND (Top10File[Counter].Downloaded > 0) THEN
        BEGIN
          InitFileArea(Top10File[Counter].DirNum);
          IF (BadDownloadPath) THEN
            EXIT;
          Seek(FileInfoFile,Top10File[Counter].DirRecNum);
          Read(FileInfoFile,F);
          Close(FileInfoFile);
          Close(ExtInfoFile);
          IF (NOT ReadBuffer('TOPFM')) THEN
            EXIT;
          DisplayBuffer(TopFileMCI,@Top10File[Counter],@F);
        END;
      FileArea := SaveFileArea;
      LoadFileArea(FileArea);
    END;
  PrintF('TOPFT');
  IF (NoFile) THEN
    HL;

  { --- }

  IF (General.TopFilesDownload) AND (PYNQ(lRGLngStr(271,TRUE),0,FALSE)) THEN
    BEGIN
      Counter := -1;
      InputInteger(lRGLngStr(272,TRUE),Counter,[],1,10,Changed);
      IF (Counter <> -1) THEN
        IF (Top10File[Counter].DirNum <> -1) AND (Top10File[Counter].DirRecNum <> -1) THEN
          BEGIN
            InitFileArea(Top10File[Counter].DirNum);
            IF (BadDownloadPath) THEN
              Exit;
            Seek(FileInfoFile,Top10File[Counter].DirRecNum);
            Read(FileInfoFile,F);
            CLS; {?}
            TransferFlags := [];
            DLX(F,Top10File[Counter].DirRecNum,TransferFlags); { LeeW: Updated this }
            Close(FileInfoFile);
            Close(ExtInfoFile);
          END;
    END;
  IF NOT (General.TopFilesDownload) THEN
    PauseScr(FALSE);
END;

PROCEDURE GetUserStats(MenuOption: Str50);
VAR
  Title,
  Header: AStr;
  Decimal,
  Width: Byte;
  ExcludeUserNum: Integer;
BEGIN
  MenuOption := AllCaps(MenuOption);
  IF (MenuOption = '') OR (NOT (MenuOption[1] IN ['A'..'M'])) THEN
    BEGIN
      NL;
      Print('Invalid menu option for user statistics, please inform the SysOp.');
      PauseScr(FALSE);
      SysOpLog('Invalid menu option for user statistics, valid options are A-M. "'+MenuOption+'"');
    END
  ELSE IF (MenuOption[1] IN ['A'..'L']) THEN
    BEGIN
      ExcludeUserNum := 0;
      IF (Pos(';',MenuOption) <> 0) THEN
        ExcludeUserNum := StrToInt(Copy(MenuOption,(Pos(';',MenuOption) + 1),50));
      CASE UpCase(MenuOption[1]) OF
        'A' : BEGIN
                Title := SemiCmd(lRGLngStr(243,TRUE),1);
                Header := SemiCmd(lRGLngStr(243,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'B' : BEGIN
                Title := SemiCmd(lRGLngStr(244,TRUE),1);
                Header := SemiCmd(lRGLngStr(244,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'C' : BEGIN
                Title := SemiCmd(lRGLngStr(245,TRUE),1);
                Header := SemiCmd(lRGLngStr(245,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'D' : BEGIN
                Title := SemiCmd(lRGLngStr(246,TRUE),1);
                Header := SemiCmd(lRGLngStr(246,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'E' : BEGIN
                Title := SemiCmd(lRGLngStr(247,TRUE),1);
                Header := SemiCmd(lRGLngStr(247,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'F' : BEGIN
                Title := SemiCmd(lRGLngStr(248,TRUE),1);
                Header := SemiCmd(lRGLngStr(248,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'G' : BEGIN
                Title := SemiCmd(lRGLngStr(249,TRUE),1);
                Header := SemiCmd(lRGLngStr(249,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'H' : BEGIN
                Title := SemiCmd(lRGLngStr(250,TRUE),1);
                Header := SemiCmd(lRGLngStr(250,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'I' : BEGIN
                Title := SemiCmd(lRGLngStr(251,TRUE),1);
                Header := SemiCmd(lRGLngStr(251,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'J' : BEGIN
                Title := SemiCmd(lRGLngStr(252,TRUE),1);
                Header := SemiCmd(lRGLngStr(252,TRUE),2);
                Decimal := 0;
                Width := 10;
              END;
        'K' : BEGIN
                Title := SemiCmd(lRGLngStr(253,TRUE),1);
                Header := SemiCmd(lRGLngStr(253,TRUE),2);
                Decimal := 2;
                Width := 12;
              END;
        'L' : BEGIN
                Title := SemiCmd(lRGLngStr(254,TRUE),1);
                Header := SemiCmd(lRGLngStr(254,TRUE),2);
                Decimal := 2;
                Width := 12;
              END;
      END;
      SearchTop10User(Top10User,MenuOption[1],ExcludeUserNum,Decimal);
      DisplayTop10UserArray(Top10User,Title,Header,Decimal,Width);
    END
  ELSE IF (MenuOption[1] = 'M') THEN
    BEGIN
      Title := SemiCmd(lRGLngStr(255,TRUE),1);
      Header := SemiCmd(lRGLngStr(255,TRUE),2);
      {
      Decimal := 0;
      Width := 12;
      }
      SearchTop10GlobalFileSpec(Top10File);
      DisplayTop10FileArray(Top10File,Title,Header);
  END;
END;
END.