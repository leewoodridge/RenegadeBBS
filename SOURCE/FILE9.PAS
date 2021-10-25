{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File9;

INTERFACE

USES
  Common;

PROCEDURE DosDir(CurDir: ASTR; CONST FSpec: Str12; Expanded: Boolean);
PROCEDURE DirF(Expanded: Boolean);
PROCEDURE DeleteFF(F: FileInfoRecordType; RN: Integer);
PROCEDURE ToggleFileAreaScanFlags;
PROCEDURE SetFileAreaNewScanDate;

IMPLEMENTATION

USES
  Dos,
  Common5,
  File0,
  File1,
  TimeFunc;

PROCEDURE DosDir(CurDir: ASTR; CONST FSpec: Str12; Expanded: Boolean);
VAR
  (*
  DirInfo: SearchRec;
  *)
  DT: DateTime;
  TempStr: ASTR;
  AmPm: Str2;
  Online: Byte;
  NumFiles,
  NumDirs,
  BytesUsed: LongInt;
BEGIN
  CurDir := BSlash(CurDir,TRUE);
  Abort := FALSE;
  Next := FALSE;
  FindFirst(CurDir[1]+':\*.*',VolumeID,DirInfo);
  IF (DOSError <> 0) THEN
    TempStr := 'has no label.'
  ELSE
    TempStr := 'is '+DirInfo.Name;
  PrintACR(' Volume in drive '+UpCase(CurDir[1])+' '+TempStr);

  (*  Add Serial Number if possible *)

  NL;
  PrintACR(' Directory of '+CurDir);
  NL;
  TempStr := '';
  Online := 0;
  NumFiles := 0;
  NumDirs := 0;
  BytesUsed := 0;
  CurDir := CurDir + FSpec;
  FindFirst(CurDir,AnyFile,DirInfo);
  WHILE (DOSError = 0) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    IF (NOT (DirInfo.Attr AND Directory = Directory)) OR (FileSysOp) THEN
      IF (NOT (DirInfo.Attr AND VolumeID = VolumeID)) THEN
        IF ((NOT (DirInfo.Attr AND DOS.Hidden = DOS.Hidden)) OR (UserNum = 1)) THEN
          IF ((DirInfo.Attr AND DOS.Hidden = DOS.Hidden) AND
             (NOT (DirInfo.Attr AND Directory = Directory))) OR
             (NOT (DirInfo.Attr AND DOS.Hidden = DOS.Hidden)) THEN
          BEGIN
            IF (Expanded) THEN
            BEGIN
              UnPackTime(DirInfo.Time,DT);
              ConvertAmPm(DT.Hour,AmPm);
              TempStr := ZeroPad(IntToStr(DT.Month))+
                     '/'+ZeroPad(IntToStr(DT.Day))+
                     '/'+IntToStr(DT.Year)+
                     '  '+ZeroPad(IntToStr(DT.Hour))+
                     ':'+ZeroPad(IntToStr(DT.Min))+
                     AmPm[1];
            END;
            IF ((DirInfo.Attr AND Directory) = Directory) THEN
            BEGIN
              TempStr := TempStr+PadRightStr('<DIR>',11);
              TempStr := TempStr+PadRightStr('',14);
              TempStr := TempStr+' '+DirInfo.Name;
              Inc(NumDirs);
            END
            ELSE
            BEGIN
              TempStr := TempStr+'  '+PadRightStr(FormatNumber(DirInfo.Size),23);
              TempStr := TempStr+' '+DirInfo.Name;
              Inc(NumFiles);
              Inc(BytesUsed,DirInfo.Size);
            END;
            PrintACR(TempStr)
          END
          ELSE
          BEGIN
            Inc(Online);
            IF ((DirInfo.Attr AND Directory) = Directory) THEN
            BEGIN
              TempStr := TempStr+PadLeftStr('['+DirInfo.Name+']',15);
              Inc(NumDirs);
            END
            ELSE
            BEGIN
              TempStr := TempStr+PadLeftStr(DirInfo.Name,15);
              Inc(NumFiles);
              Inc(BytesUsed,DirInfo.Size);
            END;
            IF (Online = 5) THEN
            BEGIN
              PrintACR(TempStr);
              TempStr := '';
              Online := 0;
            END;
          END;
    FindNext(DirInfo);
  END;
  IF (DOSError <> 0) AND (Online IN [1..5]) THEN
    PrintACR(TempStr);
  IF (NumFiles = 0) THEN
    PrintACR('File Not Found')
  ELSE
  BEGIN
    PrintACR(PadRightStr(FormatNumber(NumFiles),16)+' File(s)'+
             PadRightStr(FormatNumber(BytesUsed),15)+' bytes');
    PrintACR(PadRightStr(FormatNumber(NumDirs),16)+' Dir(s)'+
             PadRightStr(FormatNumber(DiskFree(ExtractDriveNumber(CurDir))),16)+' bytes free');
  END;
END;

PROCEDURE DirF(Expanded: Boolean);
VAR
  FSpec: Str12;
BEGIN
  NL;
  Print('Raw directory.');
  { Print(FString.lGFNLine1); }
  lRGLngStr(28,FALSE);
  { Prt(FString.GFNLine2); }
  lRGLngStr(29,FALSE);
  GetFileName(FSpec);
  NL;
  LoadFileArea(FileArea);
  DosDir(MemFileArea.DLPath,FSpec,Expanded);
END;

PROCEDURE DeleteFF(F: FileInfoRecordType; RN: Integer);
VAR
  ExtFile1: FILE;
  S,
  FN: STRING;
  TotLoad,
  DirFileRecNum: Integer;
  TempVPointer: LongInt;
BEGIN
  IF (RN <= FileSize(FileInfoFile)) AND (RN > -1) THEN
  BEGIN
    Seek(FileInfoFile,RN);
    Read(FileInfoFile,F);

    F.VPointer := -1;
    F.VTextSize := 0;

    Seek(FileInfoFile,RN);
    Write(FileInfoFile,F);

    Reset(ExtInfoFile,1);
    IF (FADirDLPath IN MemFileArea.FAFlags) THEN
      FN := MemFileArea.DLPath+MemFileArea.FileName
    ELSE
      FN := General.Datapath+MemFileArea.FileName;
    Assign(ExtFile1,FN+'.EX1');
    ReWrite(ExtFile1,1);
    FOR DirFileRecNum := 0 TO (FileSize(FileInfoFile) - 1) DO
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,F);
      IF (F.VPointer <> -1) THEN
      BEGIN
        TempVPointer := (FileSize(ExtFile1) + 1);
        Seek(ExtFile1,FileSize(ExtFile1));
        TotLoad := 0;
        Seek(ExtInfoFile,(F.VPointer - 1));
        REPEAT
          BlockRead(ExtInfoFile,S[0],1);
          BlockRead(ExtInfoFile,S[1],Ord(S[0]));
          Inc(TotLoad,(Length(S) + 1));
          BlockWrite(ExtFile1,S,(Length(S) + 1));
        UNTIL (TotLoad >= F.VTextSize);
        F.VPointer := TempVPointer;
        Seek(FileInfoFile,DirFileRecNum);
        Write(FileInfoFile,F);
      END;
    END;
    Close(ExtInfoFile);
    Erase(ExtInfoFile);
    Close(ExtFile1);
    ReName(ExtFile1,FN+'.EXT');

    IF (RN <> (FileSize(FileInfoFile) - 1)) THEN
      FOR DirFileRecNum := RN TO (FileSize(FileInfoFile) - 2) DO
      BEGIN
        Seek(FileInfoFile,(DirFileRecNum + 1));
        Read(FileInfoFile,F);
        Seek(FileInfoFile,DirFileRecNum);
        Write(FileInfoFile,F);
      END;
    Seek(FileInfoFile,(FileSize(FileInfoFile) - 1));
    Truncate(FileInfoFile);
  END;
  LastError := IOResult;
END;

(* 1. Verify if CDROM's can have new files in them *)
PROCEDURE ToggleFileAreaScanFlags;
VAR
  InputStr: Str11;
  FirstFArea,
  LastFArea,
  FArea,
  NumFAreas,
  SaveFArea,
  SaveFileArea: Integer;
  SaveConfSystem,
  SaveTempPause: Boolean;

  PROCEDURE ToggleScanFlags(FArea1: Integer; ScanType: Byte);
  BEGIN
    IF (FileArea <> FArea1) THEN
      ChangeFileArea(FArea1);
    IF (FileArea = FArea1) THEN
    BEGIN
      LoadNewScanFile(NewScanFileArea);
      IF (ScanType = 1) THEN
        NewScanFileArea := TRUE
      ELSE IF (ScanType = 2) THEN
        NewScanFileArea := FALSE
      ELSE IF (ScanType = 3) THEN
        NewScanFileArea := (NOT NewScanFileArea);
      SaveNewScanFile(NewScanFileArea);
    END;
  END;

BEGIN
  SaveFileArea := FileArea;
  SaveConfSystem := ConfSystem;
  ConfSystem := FALSE;
  IF (SaveConfSystem) THEN
    NewCompTables;
  SaveTempPause := TempPause;
  TempPause := FALSE;
  FArea := 1;
  NumFAreas := 0;
  LightBarCmd := 1;
  LightBarFirstCmd := TRUE;
  InputStr := '?';
  REPEAT
    SaveFArea := FArea;
    IF (InputStr = '?') THEN
      LFileAreaList(FArea,NumFAreas,5,TRUE);
    {
    %LFToggle new scan? [^1#^2,^1#^2-^1#^2,^1F^2=^1Flag ^2or ^1U^2=^1Unflag All^2,^1?^2=^1Help^2,^1Q^2=^1Quit^2]: @
    }
    FileAreaScanInput(LRGLngStr(74,TRUE),((Length(IntToStr(HighFileArea)) *  2) + 1),InputStr,'QFU[]?',LowFileArea,
                      HighFileArea);
    IF (InputStr <> 'Q') THEN
    BEGIN
      IF (InputStr = '[') THEN
      BEGIN
        FArea := (SaveFArea - ((PageLength - 5) * 2));
        IF (FArea < 1) THEN
          FArea := 1;
        InputStr := '?';
      END
      ELSE IF (InputStr = ']') THEN
      BEGIN
        IF (FArea > NumFileAreas) THEN
          FArea := SaveFArea;
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
        FArea := SaveFArea;
      END
      ELSE
      BEGIN
        FileArea := 0;
        IF (InputStr = 'F') THEN
        BEGIN
          FOR FArea := 1 TO NumFileAreas DO
            ToggleScanFlags(FArea,1);
          {
          %LFYou are now scanning all file areas.
          }
          LRGLngStr(86,FALSE);
          Farea := 1;
          InputStr := '?';
        END
        ELSE IF (InputStr = 'U') THEN
        BEGIN
          FOR FArea := 1 TO NumFileAreas DO
            ToggleScanFlags(FArea,2);
          {
          %LFYou are now not scanning any file areas.
          }
          LRGLngStr(88,FALSE);
          Farea := 1;
          InputStr := '?';
        END
        ELSE
        BEGIN
          FirstFArea := StrToInt(InputStr);
          IF (Pos('-',InputStr) = 0) THEN
            LastFArea := FirstFArea
          ELSE
          BEGIN
            LastFArea := StrToInt(Copy(InputStr,(Pos('-',InputStr) + 1),(Length(InputStr) - Pos('-',InputStr))));
            IF (FirstFArea > LastFArea) THEN
            BEGIN
              FArea := FirstFArea;
              FirstFArea := LastFArea;
              LastFArea := FArea;
            END;
          END;
          IF (FirstFArea < LowFileArea) OR (LastFArea > HighFileArea) THEN
          BEGIN
            {
            %LF^8The range must be from %A1 to %A2!^0
            }
            LRGLngStr(90,FALSE);
            Farea := SavefArea;
            InputStr := '?';
          END
          ELSE
          BEGIN
            FirstFArea := CompFileArea(FirstFArea,1);
            LastFArea := CompFileArea(LastFArea,1);
            FOR FArea := FirstFArea TO LastFArea DO
              ToggleScanFlags(FArea,3);
            IF (FirstFArea = LastFArea) THEN
            BEGIN
              {
              %LF^1%FB^1 will %FSbe scanned.
              }
              LRGLngStr(92,FALSE);
            END;
              Farea := SaveFArea;
              InputStr := '?';
          END;
        END;
        FileArea := SaveFileArea;
      END;
    END;
  UNTIL (InputStr = 'Q') OR (HangUp);
  ConfSystem := SaveConfSystem;
  IF (SaveConfSystem) THEN
    NewCompTables;
  TempPause := SaveTempPause;
  FileArea := SaveFileArea;
  LoadFileArea(FileArea);
  LastCommandOvr := TRUE;
END;

(* Done - Lee Palmer 06/18/06 *)
PROCEDURE SetFileAreaNewScanDate;
VAR
  TempDate: Str10;
  Key: CHAR;
BEGIN
  {
  NL;
  Prt(FString.FileNewScan);
  }
  lRGLngStr(54,FALSE);
  MPL(10);
  Prompt(PD2Date(NewFileDate));
  Key := Char(GetKey);
  IF (Key = #13) THEN
  BEGIN
    NL;
    TempDate := PD2Date(NewFileDate);
  END
  ELSE
  BEGIN
    Buf := Key;
    DOBackSpace(1,10);
    InputFormatted('',TempDate,'##/##/####',TRUE);
    IF (TempDate = '') THEN
      TempDate := PD2Date(NewFileDate);
   Print('|00');
  END;
  IF (DayNum(TempDate) = 0) OR (DayNum(TempDate) > DayNum(DateStr)) THEN
  BEGIN
    NL;
    Print('^8Invalid date entered!^0');
  END
  ELSE
  BEGIN
    NL;
   Print('|00');
{  Print('New file scan date set to: ^1'+TempDate+'^0');}
    NewFileDate := Date2PD(TempDate);
    SL1('Reset file new scan date to: ^1'+TempDate+'.|00');
  END;
END;

END.
