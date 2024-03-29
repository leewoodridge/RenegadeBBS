{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 03/09/2023 - Error messages now using Messages PROC
}
UNIT Archive1;

INTERFACE

USES
  Common;

PROCEDURE ArcDeComp(VAR Ok: Boolean; AType: Byte; CONST FileName,FSpec: AStr);
PROCEDURE ArcComp(VAR Ok: Boolean; AType: Byte; CONST FileName,FSpec: AStr);
PROCEDURE ArcComment(VAR Ok: Boolean; AType: Byte; CommentNum: Byte; CONST FileName: AStr);
PROCEDURE ArcIntegrityTest(VAR Ok: Boolean; AType: Byte; CONST FileName: AStr);
PROCEDURE ConvA(VAR Ok: Boolean; OldAType,NewAType: Byte; CONST OldFN,NewFN: AStr);
FUNCTION ArcType(FileName: AStr): Byte;
PROCEDURE ListArcTypes;
PROCEDURE InvArc;
PROCEDURE ExtractToTemp;
PROCEDURE UserArchive;

IMPLEMENTATION

USES
  Dos,
  ArcView,
  ExecBat,
  File0,
  File1,
  File2,
  File9,
  TimeFunc;

PROCEDURE ArcDeComp(VAR Ok: Boolean; AType: Byte; CONST FileName,FSpec: AStr);
VAR
  ResultCode: Integer;
BEGIN
  PurgeDir(TempDir+'ARC\',FALSE);
  ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+
            FunctionalMCI(General.FileArcInfo[AType].UnArcLine,FileName,FSpec),
            General.FileArcInfo[AType].SuccLevel,ResultCode,FALSE);
  IF (NOT Ok) AND (Pos('.DIZ',FSpec) = 0) THEN
    SysOpLog(FileName+': errors during de-compression');
END;

PROCEDURE ArcComp(VAR Ok: Boolean; AType: Byte; CONST FileName,FSpec: AStr);
VAR
  ResultCode: Integer;
BEGIN
  IF (General.FileArcInfo[AType].ArcLine = '') THEN
    Ok := TRUE
  ELSE
    ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+
              FunctionalMCI(General.FileArcInfo[AType].ArcLine,FileName,FSpec),
              General.FileArcInfo[AType].SuccLevel,ResultCode,FALSE);
  IF (NOT Ok) THEN
    SysOpLog(FileName+': errors during compression');
END;

PROCEDURE ArcComment(VAR Ok: Boolean; AType: Byte; CommentNum: Byte; CONST FileName: AStr);
VAR
  TempStr: AStr;
  ResultCode: Integer;
  SaveSwapShell: Boolean;
BEGIN
  IF (CommentNum > 0) AND (General.FileArcComment[CommentNum] <> '') THEN
  BEGIN
    SaveSwapShell := General.SwapShell;
    General.SwapShell := FALSE;
    TempStr := Substitute(General.FileArcInfo[AType].CmtLine,'%C',General.FileArcComment[CommentNum]);
    TempStr := Substitute(TempStr,'%C',General.FileArcComment[CommentNum]);
    ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+FunctionalMCI(TempStr,FileName,''),
              General.FileArcInfo[AType].SuccLevel,ResultCode,FALSE);
    General.SwapShell := SaveSwapShell;
  END;
END;

PROCEDURE ArcIntegrityTest(VAR Ok: Boolean; AType: Byte; CONST FileName: AStr);
VAR
  ResultCode: Integer;
BEGIN
  IF (General.FileArcInfo[AType].TestLine <> '') THEN
    ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+
              FunctionalMCI(General.FileArcInfo[AType].TestLine,FileName,''),
              General.FileArcInfo[AType].SuccLevel,ResultCode,FALSE);
END;

PROCEDURE ConvA(VAR Ok: Boolean; OldAType,NewAType: Byte; CONST OldFN,NewFN: AStr);
VAR
  NoFN: AStr;
  PS: PathStr;
  NS: NameStr;
  ES: ExtStr;
  FileTime: LongInt;
  Match: Boolean;
BEGIN
  Star('Converting archive - stage one.');

  Match := (OldAType = NewAType);
  IF (Match) THEN
  BEGIN
    FSplit(OldFN,PS,NS,ES);
    NoFN := PS+NS+'.#$%';
  END;

  GetFileDateTime(OldFN,FileTime);

  ArcDeComp(Ok,OldAType,OldFN,'*.*');
  IF (NOT Ok) THEN
    Star('Errors in decompression!')
  ELSE
  BEGIN
    Star('Converting archive - stage two.');

    IF (Match) THEN
      RenameFile('',OldFN,NoFN,Ok);

    ArcComp(Ok,NewAType,NewFN,'*.*');
    IF (NOT Ok) THEN
    BEGIN
      Star('Errors in compression!');
      IF (Match) THEN
        RenameFile('',NoFN,OldFN,Ok);
    END
    ELSE

      SetFileDateTime(NewFN,FileTime);

    IF (NOT Exist(SQOutSp(NewFN))) THEN
      Ok := FALSE;
  END;
  IF (Exist(NoFN)) THEN
    Kill(NoFN);
END;

FUNCTION ArcType(FileName: AStr): Byte;
VAR
  AType,
  Counter: Byte;
BEGIN
  AType := 0;
  Counter := 1;
  WHILE (Counter <= MaxArcs) AND (AType = 0) DO
    BEGIN
      IF (General.FileArcInfo[Counter].Active) THEN
        IF (General.FileArcInfo[Counter].Ext <> '') THEN
          IF (General.FileArcInfo[Counter].Ext = Copy(FileName,(Length(FileName) - 2),3)) THEN
            AType := Counter;
      Inc(Counter);
    END;
  ArcType := AType;
END;

PROCEDURE ListArcTypes;
VAR
  RecNum,
  RecNum1: Byte;
BEGIN
  RecNum1 := 0;
  RecNum := 1;
  WHILE (RecNum <= MaxArcs) AND (General.FileArcInfo[RecNum].Ext <> '') DO
  BEGIN
    IF (General.FileArcInfo[RecNum].Active) THEN
    BEGIN
      Inc(RecNum1);
      IF (RecNum1 = 1) THEN
        Prompt('^0Available archive formats: ')
      ELSE
        Prompt('^0,');
      Prompt('^1'+General.FileArcInfo[RecNum].Ext+'^0');
    END;
    Inc(RecNum);
  END;
  IF (RecNum1 = 0) THEN
    Messages(4,0,'archive formats'); { "No archive formats exist!" }(*Prompt('* No archive formats available *');*)
  NL;
END;

PROCEDURE InvArc;
BEGIN
  NL;
  Print('Unsupported archive format.');
  NL;
  ListArcTypes;
END;

PROCEDURE ExtractToTemp;
TYPE
  TotalsRecordType = RECORD
    TotalFiles: Integer;
    TotalSize: LongInt;
  END;
VAR
  Totals: TotalsRecordType;
  FileName,
  ArcFileName: AStr;
  (*
  DirInfo: SearchRec;
  *)
  DS: DirStr;
  NS: NameStr;
  ES: ExtStr;
  Cmd: Char;
  AType: Byte;
  ReturnCode,
  DirFileRecNum: Integer;
  DidSomething,
  Ok: Boolean;
BEGIN
  NL;
  Print('Extract to temporary directory -');
  NL;
  Prompt('^0Already in TEMP: ');

  FillChar(Totals,SizeOf(Totals),0);
  FindFirst(TempDir+'ARC\*.*',AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
  WHILE (DOSError = 0) DO
  BEGIN
    Inc(Totals.TotalFiles);
    Inc(Totals.TotalSize,DirInfo.Size);
    FindNext(DirInfo);
  END;

  IF (Totals.TotalFiles = 0) THEN
    Print('^1Nothing.^0')
  ELSE
    Print('^1'+FormatNumber(Totals.TotalFiles)+
          ' '+Plural('file',Totals.TotalFiles)+
          ', '+ConvertBytes(Totals.TotalSize,FALSE)+'.^0');

  IF (NOT FileSysOp) THEN
  BEGIN
    NL;
    Print('The limit is '+FormatNumber(General.MaxInTemp)+'k bytes.');
    IF (Totals.TotalSize > (General.MaxInTemp * 1024)) THEN
    BEGIN
      NL;
      Print('You have exceeded this limit.');
      NL;
      Print('Please remove some files with the user-archive command.');
      Exit;
    END;
  END;

  NL;
  Prt('File name: ');
  IF (FileSysOp) THEN
    BEGIN
      InputMain(FileName,52,[CapAll]);
    END
  ELSE
    BEGIN
      InputMain(FileName,12,[CapAll]);
    END;
  FileName := SQOutSp(FileName);
  IF (FileName = '') THEN
    BEGIN
      NL;
      Print('Aborted!');
      Exit;
    END;
  IF (IsUL(FileName)) AND (NOT FileSysOp) THEN
    BEGIN
      NL;
      Print('^8Invalid file name!^0');
      Exit;
    END;
  IF (Pos('.',FileName) = 0) THEN
    FileName := FileName + '*.*';

  Ok := TRUE;

  IF (NOT IsUL(FileName)) THEN
  BEGIN
    RecNo(FileInfo,FileName,DirFileRecNum);
    IF (BadDownloadPath) THEN
      Exit;
    IF (NOT AACS(MemFileArea.DLACS)) THEN
    BEGIN
      NL;
      Print('^8You do not have access to manipulate that file!^0');
      Exit;
    END
    ELSE IF (DirFileRecNum = -1) THEN
    BEGIN
      NL;
      Print('^8File not found!^0');
      Exit;
    END
    ELSE
    BEGIN
      Seek(FileInfoFile,DirFileRecNum);
      Read(FileInfoFile,FileInfo);
      IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
        ArcFileName := MemFileArea.DLPath+SQOutSp(FileInfo.FileName)
      ELSE
        ArcFileName := MemFileArea.ULPath+SQOutSp(FileInfo.FileName);
    END;

  END
  ELSE
  BEGIN
    ArcFileName := FExpand(FileName);
    IF (NOT Exist(ArcFileName)) THEN
    BEGIN
      NL;
      Print('^8File not found!^0');
      Exit;
    END
    ELSE
    BEGIN
      FillChar(FileInfo,SizeOf(FileInfo),0);
      WITH FileInfo DO
      BEGIN
        FileName := Align(StripName(ArcFileName));
        Description := 'Unlisted file';
        FilePoints := 0;
        Downloaded := 0;
        FileSize := GetFileSize(ArcFileName);
        OwnerNum := UserNum;
        OwnerName := Caps(ThisUser.Name);
        FileDate := Date2PD(DateStr);
        VPointer := -1;
        VTextSize := 0;
        FIFlags := [];
      END;
    END;
  END;
  IF (Ok) THEN
  BEGIN
    DidSomething := FALSE;
    Abort := FALSE;
    Next := FALSE;
    AType := ArcType(ArcFileName);
    IF (AType = 0) THEN
      InvArc;
    NL;
    Print('You can (^1C^0)opy this file into the TEMP Directory,');
    IF (AType <> 0) THEN
      Print('or (^1E^0)xtract files from it into the TEMP Directory.')
    ELSE
      Print('but you can''t extract files from it.');
    NL;
    InputChar('Which? (^1C^2=^1Copy'+AOnOff((AType <> 0),'^2,^1E^2=^1Extract','')+'^2,^1Q^2=^1Quit^2): ',Cmd,
          'QC'+AOnOff((AType <> 0),'E',''),[CapAll]);
    CASE Cmd OF
      'C' : BEGIN
              FSplit(ArcFileName,DS,NS,ES);
              NL;
              IF CopyMoveFile(TRUE,'^1Progress: ',ArcFileName,TempDir+'ARC\'+NS+ES,TRUE) THEN
                DidSomething := TRUE;
            END;
      'E' : BEGIN
              NL;
              DisplayFileInfo(FileInfo,TRUE);
              REPEAT
                NL;
                InputChar('Extract files (^1E^2=^1Extract^2,^1V^2=^1View^2,^1Q^2=^1Quit^2): ',Cmd,'QEV',[CapAll]);
                CASE Cmd OF
                  'E' : BEGIN
                          NL;
                          IF PYNQ('Extract all files? ',0,FALSE) THEN
                            FileName := '*.*'
                          ELSE
                          BEGIN
                            NL;
                            Prt('File name: ');
                            InputMain(FileName,12,[CapAll]);
                            FileName := SQOutSp(FileName);
                            IF (FileName = '') THEN
                            BEGIN
                              NL;
                              Print('Aborted!');
                            END
                            ELSE IF IsUL(FileName) THEN
                            BEGIN
                              NL;
                              Print('^8Illegal filespec!^0');
                              FileName := '';
                            END;
                          END;
                          IF (FileName <> '') THEN
                          BEGIN
                            Ok := FALSE;
                            ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+
                                      FunctionalMCI(General.FileArcInfo[AType].UnArcLine,ArcFileName,FileName),
                                      General.FileArcInfo[AType].SuccLevel,ReturnCode,FALSE);
                            IF (Ok) THEN
                            BEGIN
                              NL;
                              Star('Decompressed '+FileName+' into TEMP from '+StripName(ArcFileName));
                              SysOpLog('Decompressed '+FileName+' into '+TempDir+'ARC\ from '+StripName(ArcFileName));
                              DidSomething := TRUE;
                            END
                            ELSE
                            BEGIN
                              NL;
                              Star('Error decompressing '+FileName+' into TEMP from '+StripName(ArcFileName));
                              SysOpLog('Error decompressing '+FileName+' into '+TempDir+'ARC\ from '+StripName(ArcFileName));
                            END;
                          END;
                        END;
                  'V' : IF (IsUL(ArcFileName)) THEN
                          ViewInternalArchive(ArcFileName)
                        ELSE
                        BEGIN
                          IF Exist(MemFileArea.DLPath+FileInfo.FileName) THEN
                            ViewInternalArchive(MemFileArea.DLPath+FileInfo.FileName)
                          ELSE
                            ViewInternalArchive(MemFileArea.ULPath+FileInfo.FileName);
                        END;
                END;
              UNTIL (Cmd = 'Q') OR (HangUp);
           END;
    END;
    IF (DidSomething) THEN
    BEGIN
      NL;
      Print('^1NOTE: ^0Use the user archive menu command to access');
      Print('        files in the TEMP directory.^0');
    END;
  END;
  LastError := IOResult;
END;

PROCEDURE UserArchive;
VAR
  User: UserRecordType;
  (*
  DirInfo: SearchRec;
  *)
  TransferFlags: TransferFlagSet;
  ArcFileName,
  FName: Str12;
  Cmd: Char;
  AType,
  SaveNumBatchDLFiles: Byte;
  ReturnCode,
  GotPts,
  SaveFileArea: Integer;
  Ok,
  SaveFileCreditRatio: Boolean;

  FUNCTION OkName(FileName1: AStr): Boolean;
  BEGIN
    OkName := TRUE;
    OkName := NOT IsWildCard(FileName1);
    IF (IsUL(FileName1)) THEN
      OkName := FALSE;
  END;

BEGIN
  REPEAT
    NL;
    InputChar('Temp archive menu [^1?^2=^1Help^2]: ',Cmd,'QADLRVT?',[CapAll]);
    CASE Cmd OF
      'A' : BEGIN
              NL;
              Prt('Archive name: ');
              InputMain(ArcFileName,SizeOf(ArcFileName)-1,[CapAll]);
              IF (ArcFileName = '') THEN
              BEGIN
                NL;
                Print('Aborted!');
              END
              ELSE
              BEGIN

                LoadFileArea(FileArea);

                IF (Pos('.',ArcFileName) = 0) AND (MemFileArea.ArcType <> 0) THEN
                  ArcFileName := ArcFileName+'.'+General.FileArcInfo[MemFileArea.ArcType].Ext;

                AType := ArcType(ArcFileName);
                IF (AType = 0) THEN
                  InvArc
                ELSE
                BEGIN
                  NL;
                  Prt('File name: ');
                  InputMain(FName,SizeOf(FName)-1,[CapAll]);
                  IF (FName = '') THEN
                  BEGIN
                    NL;
                    Print('Aborted!');
                  END
                  ELSE IF (IsUL(FName)) OR (Pos('@',FName) > 0) THEN
                  BEGIN
                    NL;
                    Print('^8Illegal file name!^0');
                  END
                  ELSE IF (NOT Exist(TempDir+'ARC\'+FName)) THEN
                  BEGIN
                    NL;
                    Print('^8File not found!^0');
                  END
                  ELSE
                  BEGIN
                    Ok := FALSE;
                    ExecBatch(Ok,TempDir+'ARC\',General.ArcsPath+
                              FunctionalMCI(General.FileArcInfo[AType].ArcLine,TempDir+'ARC\'+ArcFileName,FName),
                              General.FileArcInfo[AType].SuccLevel,ReturnCode,FALSE);
                    IF (Ok) THEN
                    BEGIN
                      NL;
                      Star('Compressed "^1'+FName+'^1" into "^1'+ArcFileName+'^1"');
                      SysOpLog('Compressed "^1'+FName+'^0" into "^1'+TempDir+'ARC\'+ArcFileName+'^0"')
                    END
                    ELSE
                    BEGIN
                      NL;
                      Star('Error compressing "^1'+FName+'^1" into "^1'+ArcFileName+'^1"');
                      SysOpLog('Error compressing "^1'+FName+'^0" into "^1'+TempDir+'ARC\'+ArcFileName+'^0"');
                    END;
                  END;
                END;
              END;
            END;
      'D' : BEGIN
              NL;
              Prt('File name: ');
              InputMain(FName,SizeOf(FName)-1,[CapAll]);
              IF (FName = '') THEN
              BEGIN
                NL;
                Print('Aborted!');
              END
              ELSE IF (NOT OkName(FName)) THEN
              BEGIN
                NL;
                Print('^8Illegal file name!^0');
              END
              ELSE
              BEGIN
                FindFirst(TempDir+'ARC\'+FName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
                IF (DOSError <> 0) THEN
                BEGIN
                  NL;
                  Print('^8File not found!^0');
                END
                ELSE
                BEGIN
                  SaveFileArea := FileArea;
                  FileArea := -1;
                  WITH MemFileArea DO
                  BEGIN
                    AreaName := 'Temp Archive';
                    DLPath := TempDir+'ARC\';
                    ULPath := TempDir+'ARC\';
                    FAFlags := [];
                  END;
                  (* Consider charging points, ext. *)
                  LoadURec(User,1);
                  WITH FileInfo DO
                  BEGIN
                    FileName := Align(FName);
                    Description := 'Temporary Archive';
                    FilePoints := 0;
                    Downloaded := 0;
                    FileSize := GetFileSize(TempDir+'ARC\'+FileName);;
                    OwnerNum := 1;
                    OwnerName := Caps(User.Name);
                    FileDate := Date2PD(DateStr);
                    VPointer := -1;
                    VTextSize := 0;
                    FIFlags := [];
                  END;
                  TransferFlags := [IsTempArc,IsCheckRatio];
                  SaveNumBatchDLFiles := NumBatchDLFiles;
                  DLX(FileInfo,-1,TransferFlags);
                  FileArea := SaveFileArea;
                  LoadFileArea(FileArea);
                  IF (NumBatchDLFiles <> SaveNumBatchDLFiles) THEN
                  BEGIN
                    NL;
                    Print('^1REMEMBER: ^0If you delete this file from the temporary directory,');
                    Print('            you will not be able to download it in your batch queue.');
                  END;
                END;
              END;
            END;
      'L' : BEGIN
              AllowContinue := TRUE;
              NL;
              DosDir(TempDir+'ARC\','*.*',TRUE);
              AllowContinue := FALSE;
              SysOpLog('Listed temporary directory: "^1'+TempDir+'ARC\*.*^0"');
            END;
      'R' : BEGIN
              NL;
              Prt('File mask: ');
              InputMain(FName,SizeOf(FName)-1,[CapAll]);
              IF (FName = '') THEN
              BEGIN
                NL;
                Print('Aborted!');
              END
              ELSE IF (IsUL(FName)) THEN
              BEGIN
                NL;
                Print('^8Illegal file name!^0');
              END
              ELSE
              BEGIN
                FindFirst(TempDir+'ARC\'+FName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
                IF (DOSError <> 0) THEN
                BEGIN
                  NL;
                  Print('^8File not found!^0');
                END
                ELSE
                BEGIN
                  NL;
                  REPEAT
                    Kill(TempDir+'ARC\'+DirInfo.Name);
                    Star('Removed temporary archive file: "^1'+DirInfo.Name+'^1"');
                    SysOpLog('^0Removed temp arc file: "^1'+TempDir+'ARC\'+DirInfo.Name+'^0"');
                    FindNext(DirInfo);
                  UNTIL (DOSError <> 0) OR (HangUp);
                END;
              END;
            END;
      'T' : BEGIN
              NL;
              Prt('File name: ');
              InputMain(FName,SizeOf(FName)-1,[CapAll]);
              IF (FName = '') THEN
              BEGIN
                NL;
                Print('Aborted!');
              END
              ELSE IF (NOT OkName(FName)) THEN
              BEGIN
                NL;
                Print('^8Illegal file name!^0');
              END
              ELSE
              BEGIN
                FindFirst(TempDir+'ARC\'+FName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
                IF (DOSError <> 0) THEN
                BEGIN
                  NL;
                  Print('^8File not found!^0');
                END
                ELSE
                BEGIN
                  NL;
                  PrintF(TempDir+'ARC\'+DirInfo.Name);
                  SysOpLog('Displayed temp arc file: "^1'+TempDir+'ARC\'+DirInfo.Name+'^0"');
                END;
              END;
            END;
      'V' : BEGIN
              NL;
              Prt('File mask: ');
              InputMain(FName,SizeOf(FName)-1,[CapAll]);
              IF (FName = '') THEN
              BEGIN
                NL;
                Print('Aborted!');
              END
              ELSE IF (NOT ValidIntArcType(FName)) THEN
              BEGIN
                NL;
                Print('^8Not a valid archive type or not supported!^0')
              END
              ELSE
              BEGIN
                FindFirst(TempDir+'ARC\'+FName,AnyFile - Directory - VolumeID - Hidden - SysFile,DirInfo);
                IF (DOSError <> 0) THEN
                BEGIN
                  NL;
                  Print('^8File not found!^0');
                END
                ELSE
                BEGIN
                  Abort := FALSE;
                  Next := FALSE;
                  REPEAT
                    ViewInternalArchive(TempDir+'ARC\'+DirInfo.Name);
                    SysOpLog('Viewed temp arc file: "^1'+TempDir+'ARC\'+DirInfo.Name+'^0"');
                    FindNext(DirInfo);
                  UNTIL (DOSError <> 0) OR (Abort) OR (HangUp);
                END;
              END;
            END;
      '?' : BEGIN
              NL;
              ListArcTypes;
              NL;
              LCmds(30,1,'Add to archive','');
              LCmds(30,1,'Download files','');
              LCmds(30,1,'List files in directory','');
              LCmds(30,1,'Remove files','');
              LCmds(30,1,'Text view file','');
              LCmds(30,1,'View archive','');
              LCmds(30,1,'Quit','');
            END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  LastCommandOvr := TRUE;
  LastError := IOResult;
END;

END.
