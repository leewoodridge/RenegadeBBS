{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
LeeW
 09/21/2021 - Fixed move file operation so rg no longer creates dupe description on failure

 inputmain for filepoints different field lengths???
 11/11/2021 changed max filepoint cost to 32767


 ln341 finish nicely
}
UNIT File10;

INTERFACE

USES
  Common;

PROCEDURE CreditFileOwner(VAR User: UserRecordType; VAR FileInfo: FileInfoRecordType; Credit: Boolean; GotPts: Integer);
PROCEDURE EditFile(DirFileRecNum: Integer; VAR Cmd: Char; NoPrompt,IsPoints: Boolean);
PROCEDURE EditFiles;
PROCEDURE ValidateFiles;

IMPLEMENTATION

USES
  Dos,
  ArcView,
  Common5,
  File0,
  File1,
  File2,
  File9,
  Mail1,
  SysOp3,
  TimeFunc,
  MiscUser;

PROCEDURE CreditFileOwner(VAR User: UserRecordType; VAR FileInfo: FileInfoRecordType; Credit: Boolean; GotPts: Integer);
VAR
  FilePointsReceived: Integer;
BEGIN
  IF (AllCaps(FileInfo.OwnerName) <> AllCaps(User.Name)) THEN
  BEGIN
    NL;
    Print('^8File owner name does not match user name!^0');
    Exit;
  END;
  IF (NOT General.FileCreditRatio) THEN
    GotPts := 0
  ELSE IF (GotPts = 0) THEN
  BEGIN
    FilePointsReceived := 0;
    IF (General.FileCreditCompBaseSize <> 0) THEN
      FilePointsReceived := ((FileInfo.FileSize DIV 1024) DIV General.FileCreditCompBaseSize);
    GotPts := (FilePointsReceived * General.FileCreditComp);
    IF (GotPts < 1) THEN
      GotPts := 1;
  END;
  NL;
  Print(AOnOff(Credit,'^0Awarding upload','^0Removing upload')+' credits:'+
               ' ^11 file'+
               ', '+ConvertKB(FileInfo.FileSize DIV 1024,FALSE)+
               ', '+IntToStr(GotPts)+' file points.^0');
  SysOpLog(AOnOff(Credit,'^0Awarding upload','^0Removing upload')+' credits:'+
           ' ^11 file'+
           ', '+ConvertKB(FileInfo.FileSize DIV 1024,FALSE)+
           ', '+IntToStr(GotPts)+' file points.^0');
  IF (Credit) THEN
  BEGIN
    IF (User.Uploads < 2147483647) THEN
      Inc(User.Uploads);
    IF ((User.UK + (FileInfo.FileSize DIV 1024)) < 2147483647) THEN
      Inc(User.UK,(FileInfo.FileSize DIV 1024))
    ELSE
      User.UK := 2147483647;
    IF ((User.FilePoints + GotPts) < 2147483647) THEN
      Inc(User.FilePoints,GotPts)
    ELSE
      User.FilePoints := 2147483647;
    Include(FileInfo.FIFlags,FIOwnerCredited);
  END
  ELSE
  BEGIN
    IF (User.Uploads > 0) THEN
      Dec(User.Uploads);
    IF ((User.UK - (FileInfo.FileSize DIV 1024)) > 0) THEN
      Dec(User.UK,(FileInfo.FileSize DIV 1024))
    ELSE
      User.UK := 0;
    IF ((User.FilePoints - GotPts) > 0) THEN
      Dec(User.FilePoints,GotPts)
    ELSE
      User.FilePoints := 0;
    Exclude(FileInfo.FIFlags,FIOwnerCredited);
  END;
  SaveURec(User,FileInfo.OwnerNum);
END;

PROCEDURE EditFile(DirFileRecNum: Integer; VAR Cmd: Char; NoPrompt,IsPoints: Boolean);
VAR
  FF: FILE;
  ExtText: Text;
  User: UserRecordType;
  Mheader: MheaderRec;
  InputStr,
  MoveFromDir,
  MoveToDir: AStr;
  LineNum,
  NumExtDesc: Byte;
  UNum,
  NewFileArea,
  SaveFileArea,
  FArea,
  NumFAreas,
  Totload,
  SaveFArea: Integer;
  FSize: Longint;
  SaveConfSystem,
  SaveTempPause,
  DontShowList,
  Ok: Boolean;

  PROCEDURE ToggleFIFlag(FIFlagT: FileInfoFlagType; VAR FIFlagS: FIFlagSet);
  BEGIN
    IF (FIFlagT IN FIFlagS) THEN
      Exclude(FIFlagS,FIFlagT)
    ELSE
      Include(FIFlagS,FIFlagT);
  END;

  PROCEDURE ToggleFIFlags(C: Char; VAR FIFlagS: FIFlagSet);
  BEGIN
    CASE C OF
      'V' : ToggleFIFlag(FiNotVal,FIFlagS);
      'T' : ToggleFIFlag(FiIsRequest,FIFlagS);
      'R' : ToggleFIFlag(FIResumeLater,FIFlagS);
      'H' : ToggleFIFlag(FIHatched,FIFlagS);
    END;
  END;

BEGIN
  Seek(FileInfoFile,DirFileRecNum);
  Read(FileInfoFile,FileInfo);
  IF (IOResult <> 0) THEN
    Exit;

  IF (FileInfo.OwnerNum < 1) OR (FileInfo.OwnerNum > (MaxUsers - 1)) THEN
    FileInfo.OwnerNum := 1;
  LoadURec(User,FileInfo.OwnerNum);

  IF (IsPoints) THEN
  BEGIN
    NL;
    DisplayFileInfo(FileInfo,TRUE);
    NL;
    Prt('File points for file (^10^2-^1999^2,^1<CR>^2=^1Skip^2,^1Q^2=^1Quit^2): ');
    InputMain(InputStr,3,[CapAll]);
    IF (InputStr <> '') THEN
    BEGIN
      IF (InputStr = 'Q') THEN
      BEGIN
        NL;
        Print('Aborted.');
        Abort := TRUE
      END
      ELSE IF (StrToInt(InputStr) >= 0) AND (StrToInt(InputStr) <= 999) THEN
      BEGIN
        FileInfo.FilePoints := StrToInt(InputStr);
        Exclude(FileInfo.FIFlags,FINotVal);
        Seek(FileInfoFile,DirFileRecNum);
        Write(FileInfoFile,FileInfo);

        CreditFileOwner(User,FileInfo,TRUE,FileInfo.FilePoints);

        IF (FileInfo.OwnerNum = UserNum) THEN
          User.FilePoints := ThisUser.FilePoints;

        NL;
        Prt('File points for user (^1-'+IntToStr(User.FilePoints)+'^2 to ^1999^2): ');
        InputMain(InputStr,4,[CapAll]);
        IF (InputStr <> '') AND (StrToInt(InputStr) >= -User.FilePoints) AND (StrToInt(InputStr) <= 999) THEN
        BEGIN

          Inc(User.FilePoints,StrToInt(InputStr));

          IF (FileInfo.OwnerNum = UserNum) THEN
            ThisUser.FilePoints := User.FilePoints;

          SaveURec(User,FileInfo.OwnerNum);
        END;
      END;
    END;
    Exit;
  END;
  IF (NoPrompt) THEN
  BEGIN
    Exclude(FileInfo.FIFlags,FINotVal);
    Seek(FileInfoFile,DirFileRecNum);
    Write(FileInfoFile,FileInfo);
    CreditFileOwner(User,FileInfo,TRUE,0);
    Exit;
  END;
  DontShowList := FALSE;
  REPEAT
    Abort := FALSE;
    Next := FALSE;
    IF (NOT DontShowList) THEN
    BEGIN
      NL;
      DisplayFileInfo(FileInfo,TRUE);
      Abort := FALSE;
    END
    ELSE
      DontShowList := FALSE;
    NL;
    Abort := FALSE;
    IF (Next) THEN
      Cmd := 'N'
    ELSE
    BEGIN
      InputChar('Edit files (^1?^2=^1Help^2): ',Cmd,'Q1234567DEGHIMNPRTUVW?'^M,[CapAll]);
    END;
    CASE Cmd OF
      '1' : BEGIN
              NL;
              Prt('New file name: ');
              InputMain(InputStr,(SizeOf(FileInfo.FileName) - 1),[CapAll]);
              IF (InputStr = '') THEN
              BEGIN
                NL;
                Print('Aborted.');
              END
              ELSE IF (SQOutSp(InputStr) = SQOutSp(FileInfo.FileName)) THEN
              BEGIN
                NL;
                Print('^8You must specify a different file name!^0');
              END
              ELSE IF (Exist(MemFileArea.DLPath+InputStr) OR Exist(MemFileArea.ULPath+InputStr)) THEN
              BEGIN
                NL;
                Print('^8That file name exists in the download or upload path!^0');
              END
              ELSE
              BEGIN
                  IF (NOT Exist(MemFileArea.DLPath+FileInfo.FileName)) OR
                     (NOT Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
                  BEGIN
                    NL;
                    Print('That file name does not exist in the download or upload path.');
                    Ok := FALSE;
                    IF (CoSysOp) THEN
                    BEGIN
                      IF (NOT (FIIsRequest IN FileInfo.FIFlagS)) THEN
                      BEGIN
                        NL;
                        IF (PYNQ('Do you want to set this file to offline? ',0,FALSE)) THEN
                        BEGIN
                          FileInfo.FileSize := 0;
                          Include(FileInfo.FIFlagS,FIIsRequest);
                        END;
                      END;
                      NL;
                      IF (PYNQ('Do you want to rename the file anyway? ', 0,FALSE)) THEN
                        Ok := TRUE;
                    END;
                  END;

                IF (Ok) THEN
                BEGIN
                  IF (Exist(MemFileArea.DLPath+FileInfo.FileName)) THEN
                  BEGIN
                    Assign(FF,MemFileArea.DLPath+FileInfo.FileName);
                    ReName(FF,MemFileArea.DLPath+InputStr);
                  END
                  ELSE IF (Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
                  BEGIN
                    Assign(FF,MemFileArea.ULPath+FileInfo.FileName);
                    ReName(FF,MemFileArea.ULPath+InputStr);
                  END;
                  LastError := IOResult;
                  FileInfo.FileName := Align(InputStr);
                END;

              END;
            END;
      '2' : BEGIN
              NL;
              Print('Limit on file size restricted to 1.9 Gig.');
              OK := TRUE;
              IF (NOT Exist(MemFileArea.DLPath+FileInfo.FileName)) OR (NOT Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
              BEGIN
                NL;
                IF (PYNQ('File does not exist, set to offline? ',0,FALSE)) THEN
                BEGIN
                  FSize := 0;
                  Include(FileInfo.FIFlags,FiIsRequest);
                  OK := FALSE;
                END;
              END;
              IF (Ok) THEN
              BEGIN
                NL;
                IF PYNQ('Update with actual file size? ', 0,FALSE) THEN
                BEGIN
                  FSize := 0;
                  IF (Exist(MemFileArea.DLPath+FileInfo.FileName)) THEN
                    FSize := GetFileSize(MemFileArea.DLPath+SQOutSp(FileInfo.FileName))
                  ELSE IF (Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
                    FSize := GetFileSize(MemFileArea.ULPath+SqOutSp(FileInfo.FileName));
                END
                ELSE
                BEGIN
                  FSize := FileInfo.FileSize;
                  InputLongInt('%LF^2New file size in bytes',FSize,[InteractiveEdit,NumbersOnly],0,2147483647,Changed);
                END;
              END;
              IF (FSize >= 0) AND (FSize <= 2147483647) THEN
                FileInfo.FileSize := FSize;
            END;
      '3' : BEGIN
              NL;
              Print('New description: ');
              Prt(': ');
              InputMain(FileInfo.Description,(SizeOf(FileInfo.Description) - 1),[InteractiveEdit]);
            END;
      '4' : BEGIN
              LoadURec(User,FileInfo.OwnerNum);
              IF (AllCaps(FileInfo.OwnerName) <> AllCaps(User.Name)) THEN
              BEGIN
                NL;
                Print('Previous owner was '+Caps(FileInfo.OwnerName)+' #'+IntToStr(FileInfo.OwnerNum));
                NL;
                LoadURec(User,1);
                FileInfo.OwnerNum := 1;
                FileInfo.OwnerName := AllCaps(User.Name);
              END;
              NL;
              Print('New owner user number or name ('+Caps(FileInfo.OwnerName)+' #'+IntToStr(FileInfo.OwnerNum)+'): ');
              {
              Prt(': ');
              MPL((SizeOf(FileInfo.OwnerName) - 1));
              FindUser(UNum);}
              lFindUserWS(UNum); {leew: changed}
              IF (UNum <= 0) THEN
              BEGIN
                NL;
                Print('User not found.');
              END
              ELSE
              BEGIN
                LoadURec(User,UNum);
                FileInfo.OwnerNum := UNum;
                FileInfo.OwnerName := AllCaps(User.Name);
              END;
            END;
      '5' : BEGIN
              NL;
              Prt('New upload file date ('+PD2Date(FileInfo.FileDate)+'): ');
              InputFormatted('',InputStr,'##-##-####',TRUE);
              IF (InputStr = '') THEN
              BEGIN
                NL;
                Print('Aborted.');
              END
              ELSE
              BEGIN
                IF (DayNum(InputStr) = 0) OR (DayNum(InputStr) > DayNum(DateStr)) THEN
                BEGIN
                  NL;
                  Print('^8Invalid date entered!^0');
                END
                ELSE
                  FileInfo.FileDate := Date2PD(InputStr);
              END;
            END;
      '6' : InputLongInt('%LF^2New number of downloads',FileInfo.DownLoaded,[InteractiveEdit,NumbersOnly],
                           0,2147483647,Changed);
      '7' : InputInteger('%LF^2New amount of file points',FileInfo.FilePoints,[InteractiveEdit,NumbersOnly],
                           0,32767,Changed); { LeeW: Changed - was max 999 ? }
      'D' : IF PYNQ('%LFAre you sure? ',0,FALSE) THEN
            BEGIN
              Deleteff(FileInfo,DirFileRecNum);
              InitFileArea(FileArea);
              Dec(LastDIRRecNum);
              InputStr := 'Removed "'+SQOutSp(FileInfo.FileName)+'" from '+MemFileArea.AreaName;
              IF (Exist(MemFileArea.DLPath+FileInfo.FileName) OR Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
              BEGIN
                NL;
                IF PYNQ('Erase file also? ',0,FALSE) THEN
                BEGIN
                  Kill(MemFileArea.DLPath+FileInfo.FileName);
                  Kill(MemFileArea.ULPath+FileInfo.FileName);
                  InputStr := InputStr+' [FILE DELETED]'
                END;
              END;

              IF (NOT (FIOwnerCredited IN FileInfo.FIFlags)) THEN
                Print('%LF^8Owner did not receive upload credit for this file!^0')
              ELSE IF PYNQ('%LFRemove from ^1'+Caps(User.Name)+' #'+IntToStr(FileInfo.OwnerNum)+'^8''s ratio? ',0,FALSE) THEN
                CreditFileOwner(User,FileInfo,FALSE,FileInfo.FilePoints);

              SysOpLog(InputStr);
              Cmd := 'N';
            END;
      'E' : BEGIN
              OK := TRUE;
              IF (FileInfo.VPointer <> -1) THEN
              BEGIN
                IF (NOT PYNQ('%LFDelete the extended description for this file? ',0,FALSE)) THEN
                  LoadVerbArray(FileInfo,ExtendedArray,NumExtDesc)
                ELSE
                BEGIN
                  FileInfo.VPointer := -1;
                  FileInfo.VTextSize := 0;
                  OK := FALSE;
                END;
              END
              ELSE
              BEGIN
                IF (NOT PYNQ('%LFCreate an extended description for this file? ',0,FALSE)) THEN
                BEGIN
                  FileInfo.VPointer := -1;
                  FileInfo.VTextSize := 0;
                  OK := FALSE
                END
                ELSE
                BEGIN
                  FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
                  NumExtDesc := 1;
                END;
              END;
              IF (Ok) THEN
              BEGIN
                Assign(ExtText,TempDir+MemFileArea.FileName+'.TMP');
                ReWrite(ExtText);
                LineNum := 0;
                REPEAT
                  Inc(LineNum);
                  IF (ExtendedArray[LineNum] <> '') THEN
                    WriteLn(ExtText,ExtendedArray[LineNum]);
                UNTIL (LineNum = NumExtDesc);
                Close(ExtText);
                MHeader.Status := [];
                InResponseTo := '';
                IF (InputMessage(TRUE,FALSE,'Extended Description',
                                 MHeader,TempDir+MemFileArea.FileName+'.TMP',50,99)) then
                  IF Exist(TempDir+MemFileArea.FileName+'.TMP') THEN
                  BEGIN
                    FillChar(ExtendedArray,SizeOf(ExtendedArray),0);
                    Assign(ExtText,TempDir+MemFileArea.FileName+'.TMP');
                    Reset(ExtText);
                    NumExtDesc := 0;
                    REPEAT
                      ReadLn(ExtText,InputStr);
                      IF (InputStr <> '') THEN
                      BEGIN
                        Inc(NumExtDesc);
                        ExtendedArray[NumExtDesc] := InputStr;
                      END;
                    UNTIL (NumExtDesc = MaxExtDesc) OR EOF(ExtText);
                    Close(ExtText);
                    IF (ExtendedArray[1] <> '') THEN
                      SaveVerbArray(FileInfo,ExtendedArray,NumExtDesc);
                  END;
                Kill(TempDir+MemFileArea.FileName+'.TMP');
              END;
              Cmd := #0;
            END;
      'G' : IF (NOT General.FileDiz) THEN
              Print('%LF^8This option is not active in the System Configuration!^0')
            ELSE
            BEGIN
              IF (Exist(MemFileArea.ULPath+FileInfo.FileName)) THEN
                InputStr := MemFileArea.ULPath+SQOutSp(FileInfo.FileName)
              ELSE
                InputStr := MemFileArea.DLPath+SQOutSp(FileInfo.FileName);
              IF (NOT DizExists(InputStr)) THEN
                Print('%LFFile has no internal description.')
              ELSE
              BEGIN
                GetDiz(FileInfo,ExtendedArray,NumExtDesc);
                IF (ExtendedArray[1] <> '') THEN
                  SaveVerbArray(FileInfo,ExtendedArray,NumExtDesc)
                ELSE
                BEGIN
                  FileInfo.VPointer := -1;
                  FileInfo.VTextSize := 0;
                END;
              END;
            END;
      'H' : ToggleFIFlags('H',FileInfo.FIFlagS);
      'I' : IF (NOT ValidIntArcType(FileInfo.FileName)) THEN
            BEGIN
              NL;
              Print('^8Not a valid archive type or not supported!^0')
            END
            ELSE
            BEGIN
              OK := FALSE;
              IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
              BEGIN
                ViewInternalArchive(MemFileArea.DLPath+SQOutSp(FileInfo.FileName));
                OK := TRUE;
              END
              ELSE IF Exist(MemFileArea.ULPath+FileInfo.FileName) THEN
              BEGIN
                ViewInternalArchive(MemFileArea.ULPath+SQOutSp(FileInfo.FileName));
                OK := TRUE;
              END;
              IF (NOT Ok) THEN
              BEGIN
                NL;
                IF (PYNQ('File does not exist, set to offline? ',0,FALSE)) THEN
                BEGIN
                  FileInfo.FileSize := 0;
                  ToggleFIFlags('T',FileInfo.FIFlagS);
                END;
              END;
              Abort := FALSE;
            END;
      'M' : BEGIN
              SaveFileArea := FileArea;
              SaveConfSystem := ConfSystem;
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
                  LFileAreaList(FArea,NumFAreas,6,FALSE);
                {
                %LFMove to which file area? (^1'+IntToStr(LowFileArea)+'^2-^1'+IntToStr(HighFileArea)+'^2)
                   [^1#^2,^1?^2=^1Help^2,^1Q^2=^1Quit^2]: @
                }
                FileAreaScanInput(LRGLngStr(76,TRUE),Length(IntToStr(HighFileArea)),InputStr,'Q[]?',LowFileArea,HighFileArea);
                IF (InputStr <> 'Q') THEN
                BEGIN
                  IF (InputStr = '[') THEN
                  BEGIN
                    Farea := (SaveFArea - ((PageLength - 5) * 2));
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
                  ELSE IF (StrToInt(InputStr) < LowFileArea) OR (StrToInt(InputStr) > HighFileArea) THEN
                  BEGIN
                    NL;
                    Print('^8The range must be from '+IntToStr(LowFileArea)+' to '+IntToStr(HighFileArea)+'!^0');
                    PauseScr(FALSE);
                    InputStr := '?';
                    FArea := SaveFArea;
                  END
                  ELSE IF (StrToInt(InputStr) = FileArea) THEN
                  BEGIN
                    NL;
                    Print('^8You can not move a file to the same file area.^0');
                    PauseScr(FALSE);
                    InputStr := '?';
                    FArea := SaveFArea;
                  END
                  ELSE
                  BEGIN
                    NewFileArea := CompFileArea(StrToInt(InputStr),1);
                    IF (FileArea <> NewFileArea) THEN
                      ChangeFileArea(NewFileArea);
                    IF (FileArea <> NewFileArea) THEN
                    BEGIN
                      NL;
                      Print('^8You do not have access to this file area!^0');
                      PauseScr(FALSE);
                      InputStr := '?';
                      FArea := SaveFArea;
                    END
                    ELSE
                    BEGIN
                      FileArea := SaveFileArea;
                      LoadFileArea(FileArea);
                      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
                        MoveFromDir := MemFileArea.DLPath
                      ELSE
                        MoveFromDir := MemFileArea.ULPath;
                      LoadFileArea(NewFileArea);
                      MoveToDir := MemFileArea.ULPath;
                      NL;
                      IF (NOT PYNQ('Move file to '+MemFileArea.AreaName+'? ',0,FALSE)) THEN
                      BEGIN
                        InputStr := '?';
                        FArea := SaveFArea;
                      END
                      ELSE
                      BEGIN
                        OK := TRUE;
                        IF Exist(MoveToDir+SQoutSp(FileInfo.FileName)) THEN
                        BEGIN
                          NL;
                          Print('^8The file exists in the upload path!^0');
                          OK := FALSE;
                        END
                        ELSE IF (NOT Exist(MoveFromDir+SQOutSp(FileInfo.FileName))) THEN
                        BEGIN
                          NL;
                          Print('^8The file does not exist in the download path!^0');
                          OK := FALSE;
                        END;
                        IF (Ok) THEN
                        BEGIN
                          NL;
                          CopyMoveFile(FALSE,'^1Moving file: ',
                                       MoveFromDir+SQOutSp(FileInfo.FileName),
                                       MoveToDir+SQOutSp(FileInfo.FileName),
                                       TRUE);
                        NL;
                        Prompt('^1Moving records: ');
                        FileArea := SaveFileArea;
                        InitFileArea(FileArea);
                        IF (BadDownloadPath) THEN
                          Exit;
                        IF (FileInfo.VPointer <> -1) THEN
                          LoadVerbArray(FileInfo,ExtendedArray,NumExtDesc);
                        Deleteff(FileInfo,DirFileRecNum);
                        FileArea := NewFileArea;
                        InitFileArea(FileArea);
                        IF (BadDownloadPath) THEN
                          Exit;
                        IF (FileInfo.VPointer <> -1) THEN
                          SaveVerbArray(FileInfo,ExtendedArray,NumExtDesc);
                        Seek(FileInfoFile,FileSize(FileInfoFile));
                        Write(FileInfoFile,FileInfo);
                        FileArea := SaveFileArea;
                        InitFileArea(FileArea);
                        Dec(LastDIRRecNum);
                        Print('Done!^0');
                        Cmd := 'N';
                        END
                        ELSE
                        Cmd := 'N';
                      END;
                    END;
                    FileArea := SaveFileArea;
                    LoadFileArea(FileArea);
                  END;
                END;
                IF (InputStr = 'Q') THEN
                  Cmd := 'N';
              UNTIL (Cmd = 'N') OR (HangUp);
              ConfSystem := SaveConfSystem;
              IF (SaveConfSystem) THEN
                NewCompTables;
              TempPause := SaveTempPause;
              FileArea := SaveFileArea;
              LoadFileArea(FileArea);
            END;
      'P' : ;
      'Q' : Abort := TRUE;
      'R' : ToggleFIFlags('R',FileInfo.FIFlagS);
      'T' : ToggleFIFlags('T',FileInfo.FIFlagS);
      'U' : IF (NOT CoSysOp) THEN
            BEGIN
              NL;
              Print('^8You do not have the required access level for this option!^0')
            END
            ELSE
            BEGIN
              IF (FileInfo.OwnerNum < 1) OR (FileInfo.OwnerNum > (MaxUsers - 1)) THEN
              BEGIN
                LoadURec(User,1);
                FileInfo.OwnerNum := 1;
                FileInfo.OwnerName := AllCaps(User.Name);
              END;
              UserEditor(FileInfo.OwnerNum);
            END;

      'V' : BEGIN
              ToggleFIFlags('V',FileInfo.FIFlagS);

              IF (FINotVal IN FileInfo.FIFlags) THEN
              BEGIN
                IF (NOT (FIOwnerCredited IN FileInfo.FIFlags)) THEN
                  Print('%LF^8Owner did not receive upload credit for this file!^0')
                ELSE
                  CreditFileOwner(User,FileInfo,FALSE,FileInfo.FilePoints);
              END
              ELSE
                CreditFileOwner(User,FileInfo,TRUE,0);
            END;

      'W' : IF (NOT (FIOwnerCredited IN FileInfo.FIFlags)) THEN
              Print('%LF^8Owner did not receive upload credit for this file!^0')
            ELSE IF PYNQ('%LFWithdraw credit? ',0,FALSE) THEN
              CreditFileOwner(User,FileInfo,FALSE,FileInfo.FilePoints);

      '?' : BEGIN
              NL;
              Print('^11-7^0:Modify item');
              LCmds(18,1,'Move file','Delete file');
              LCmds(18,1,'Extended edit','Hatched toggle');
              LCmds(18,1,'Previous file','Next file');
              LCmds(18,1,'Resume toggle','Toggle availability');
              LCmds(18,1,'Validation toggle','Withdraw credit');
              LCmds(18,1,'Internal listing','Get Description');
              LCmds(18,1,'Uploader','Quit');
              DontShowList := TRUE;
            END;
      ^M  : Cmd := 'N';
    ELSE
      Next := TRUE;
    END;
    IF (NOT (Cmd IN ['P','N','Q'])) THEN
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Write(FileInfoFile,FileInfo);
    END;
  UNTIL (Cmd IN ['P','N','Q']) OR (Abort) OR (Next) OR (HangUp);
END;

PROCEDURE EditFiles;
VAR
  FileName,
  SaveLastDirFileName: Str12;
  Cmd: Char;
  DirFileRecNum,
  SaveLastDirFileRecNum: Integer;
  FO: Boolean;
BEGIN
  NL;
  Print('File editor:');
  { Print(FString.lGFNLine1); }
  lRGLngStr(28,FALSE);
  { Prt(FString.GFNLine2); }
  lRGLngStr(29,FALSE);
  GetFileName(FileName);
  IF (FileName = '') OR (Pos('.',FileName) = 0) THEN
  BEGIN
    NL;
    Print('Aborted.');
  END
  ELSE
  BEGIN
    SaveLastDirFileRecNum := LastDIRRecNum;
    SaveLastDirFileName := LastDIRFileName;
    FO := (FileRec(FileInfoFile).Mode <> FMClosed);
    IF (FO) THEN
    BEGIN
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
    RecNo(FileInfo,FileName,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    IF (DirFileRecNum = -1) THEN
    BEGIN
      NL;
      Print('No matching files.');
    END
    ELSE
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        EditFile(DirFileRecNum,Cmd,FALSE,FALSE);
        IF (Cmd = 'Q') THEN
          Abort := TRUE
        ELSE
        BEGIN
          IF (Cmd = 'P') THEN
            LRecNo(FileInfo,DirFileRecNum)
          ELSE
            NRecNo(FileInfo,DirFileRecNum);
        END;
        WKey;
      END;
    END;
    Close(FileInfoFile);
    Close(ExtInfoFile);
    IF (FO) THEN
      InitFileArea(FileArea);
    LastDIRRecNum := SaveLastDirFileRecNum;
    LastDIRFileName := SaveLastDirFileName;
    LastCommandOvr := TRUE;
  END;
  LastError := IOResult;
END;

PROCEDURE ValidateFiles;
VAR
  Cmd: Char;
  FArea,
  SaveFileArea: Integer;
  SaveConfSystem: Boolean;

  PROCEDURE ValFiles(FArea: Integer; Cmd1: Char; NoPrompt,IsPoints: Boolean);
  VAR
    DirFileRecNum: Integer;
    Found,
    FirstOne: Boolean;
  BEGIN
    IF (FileArea <> FArea) THEN
      ChangeFileArea(FArea);
    IF (FileArea = FArea) THEN
    BEGIN
      RecNo(FileInfo,'*.*',DirFileRecNum);
      IF (BadDownloadPath) THEN
        Exit;
      LIL := 0;
      CLS;
      Cmd1 := #0;
      Found := FALSE;
      FirstOne := TRUE;
      Prompt('^0Scanning ^1'+MemFileArea.AreaName+' #'+IntToStr(CompFileArea(FileArea,0))+'^0 ...');
      WHILE (DirFileRecNum <> -1) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(FileInfoFile,DirFileRecNum);
        Read(FileInfoFile,FileInfo);
        IF (FINotVal IN FileInfo.FIFlagS) AND (NOT (FIResumeLater IN FileInfo.FIFlagS)) THEN
        BEGIN
          IF (FirstOne) THEN
          BEGIN
            NL;
            FirstOne := FALSE;
          END;
          EditFile(DirFileRecNum,Cmd1,NoPrompt,IsPoints);
          Found := TRUE;
        END;
        IF (Cmd1 = 'P') THEN
        BEGIN
          REPEAT
            LRecNo(FileInfo,DirFileRecNum);
          UNTIL (DirFileRecNum = -1) OR ((FINotVal IN FileInfo.FIFlags) AND NOT (FIResumeLater IN FileInfo.FIFlags));
        END
        ELSE
          NRecNo(FileInfo,DirFileRecNum);
        WKey;
      END;
      IF (NOT Found) THEN
      BEGIN
        LIL := 0;
        BackErase(15 + LennMCI(MemFileArea.AreaName) + Length(IntToStr(CompFileArea(FileArea,0))));
      END;
      Close(FileInfoFile);
      Close(ExtInfoFile);
    END;
    LastError := IOResult;
  END;

BEGIN
  NL;
  Print('^2[^1M^2]anual, [^1A^2]utomatic, [^1P^2]oint entry, [^1Q^2]uit');
  NL;
  InputChar('File validation: ',Cmd,'QMAP',[CapAll]);
  IF (Cmd <> 'Q') THEN
  BEGIN
    SaveFileArea := FileArea;
    SaveConfSystem := ConfSystem;
    ConfSystem := FALSE;
    IF (SaveConfSystem) THEN
      NewCompTables;
    TempPause := (Cmd <> 'A');
    Abort := FALSE;
    Next := FALSE;
    NL;
    IF (NOT InWFCMenu) AND (NOT PYNQ('Search all file areas? ',0,TRUE)) THEN
      ValFiles(FileArea,Cmd,(Cmd = 'A'),(Cmd = 'P'))
    ELSE
    BEGIN
      FArea := 1;
      WHILE (FArea >= 1) AND (FArea <= NumFileAreas) AND (NOT Next) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        ValFiles(FArea,Cmd,(Cmd = 'A'),(Cmd = 'P'));
        WKey;
        IF (Next) THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
        END;
        Inc(FArea);
      END;
    END;
    ConfSystem := SaveConfSystem;
    IF (SaveConfSystem) THEN
      NewCompTables;
    FileArea := SaveFileArea;
    LoadFileArea(FileArea);
  END;
  LastError := IOResult;
END;

END.
