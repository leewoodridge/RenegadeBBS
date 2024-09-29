{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File12;

INTERFACE

USES
  Common;

FUNCTION CheckBatchUL(FileName: Str12): Boolean;
PROCEDURE EditBatchULQueue;
PROCEDURE ListBatchULFiles;
PROCEDURE RemoveBatchULFiles;
PROCEDURE ClearBatchULQueue;
PROCEDURE BatchUpload(BiCleanUp: Boolean; TransferTime: LongInt);
PROCEDURE BatchDLULInfo;

IMPLEMENTATION

USES
  Dos,
  Common5,
  ExecBat,
  File0,
  File1,
  File2,
  File4,
  TimeFunc;

FUNCTION CheckBatchUL(FileName: Str12): Boolean;
VAR
  RecNum: LongInt;
  FileFound: Boolean;
BEGIN
  FileFound := FALSE;
  IF (NumBatchULFiles > 0) THEN
  BEGIN
    Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
    Reset(BatchULFile);
    RecNum := 1;
    WHILE (RecNum <= FileSize(BatchULFile)) AND (NOT FileFound) DO
    BEGIN
      Seek(BatchULFile,(RecNum - 1));
      Read(BatchULFile,BatchUL);
      IF (BatchUL.BULUserNum = UserNum) AND (BatchUL.BULFileName = SQOutSp(FileName)) THEN
        FileFound := TRUE;
      Inc(RecNum);
    END;
    Close(BatchULFile);
    LastError := IOResult;
  END;
  CheckBatchUL := FileFound;
END;

PROCEDURE EditBatchULQueue;
VAR
  Cmd: Char;
BEGIN
  IF (NumBatchULFiles = 0) THEN
  BEGIN
    {NL;
    Print('The batch upload queue is empty.');}
    lRGLngStr(286,FALSE);
    	Exit;
  END;
  REPEAT
    NL;
    InputChar('Batch upoad queue [^1C^2]lear, [^1L^2]ist batch, [^1R^2]emove a file, [^1Q^2]uit: ',Cmd,'QCLR',[CapAll]);
    CASE Cmd OF
      'C' : ClearBatchULQueue;
      'L' : ListBatchULFiles;
      'R' : RemoveBatchULFiles;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

PROCEDURE ListBatchULFiles;
VAR
  TempStr: STRING;
  FileNumToList: Byte;
  TempBULVTextSize: Integer;
  RecNum: LongInt;
BEGIN
  IF (NumBatchULFiles = 0) THEN
  BEGIN
    {NL;
    Print('The batch upload queue is empty.');}
    lRGLngStr(286,FALSE);   
	Exit;
  END;
  Abort := FALSE;
  Next := FALSE;
  NL;
  PrintACR('^2###:Filename.Ext Area  Description^0');
  PrintACR('^2===:============:=====:==================================================^0');
  Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
  Reset(BatchULFile);
  Assign(BatchULF,General.DataPath+'BATCHUL.EXT');
  Reset(BatchULF,1);
  FileNumToList := 1;
  RecNum := 1;
  WHILE (RecNum <= FileSize(BatchULFile)) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Seek(BatchULFile,(RecNum - 1));
    Read(BatchULFile,BatchUL);
    IF (BatchUL.BULUserNum = UserNum) THEN
    BEGIN
      PrintACR('^1'+PadRightInt(FileNumToList,3)+
               '^2:^1'+Align(BatchUL.BULFileName)+
               ' '+AOnOff((BatchUL.BULSection = General.ToSysOpDir),'^8SysOp',PadRightInt(BatchUL.BULSection,5))+
               ' ^1'+BatchUL.BULDescription);
      IF (BatchUL.BULVPointer <> -1) THEN
      BEGIN
        TempBULVTextSize := 0;
        Seek(BatchULF,(BatchUL.BULVPointer - 1));
        REPEAT
          BlockRead(BatchULF,TempStr[0],1);
          BlockRead(BatchULF,TempStr[1],Ord(TempStr[0]));
          Inc(TempBULVTextSize,(Length(TempStr) + 1));
          PrintACR('^1'+PadRightStr(TempStr,24)+'^0');
        UNTIL (TempBULVTextSize >= BatchUL.BULVTextSize);
      END;
      Inc(FileNumToList);
    END;
    WKey;
    Inc(RecNum);
  END;
  Close(BatchULFile);
  Close(BatchULF);
  LastError := IOResult;
  PrintACR('^2===:============:=====:==================================================^0');
  SysOpLog('Viewed the batch upload queue.');
END;

PROCEDURE RemoveBatchULFiles;
VAR
  BatchULF1: FILE;
  BatchUL1: BatchULRecordType;
  TempStr: STRING;
  InputStr: Str3;
  Counter,
  FileNumToRemove: Byte;
  TotLoad: Integer;
  TempVPointer,
  RecNum,
  RecNum1: LongInt;
BEGIN
  IF (NumBatchULFiles = 0) THEN
  BEGIN
    {NL;
    Print('The batch upload queue is empty.');}
    lRGLngStr(286,FALSE);
	    Exit;
  END;
  InputStr := '?';
  REPEAT
    IF (InputStr = '?') THEN
      ListBatchULFiles;
    NL;
    Prt('^2File to remove? (^11^2-^1'+IntToStr(NumBatchULFiles)+'^2) [^1?^2=^1List^2,^1<CR>^2=^1Quit^2]: ');
    MPL(Length(IntToStr(NumBatchULFiles)));
    ScanInput(InputStr,^M'?');
    FileNumToRemove := StrToInt(InputStr);
    IF (NOT (InputStr[1] IN ['?','-',^M])) THEN
      IF (FileNumToRemove < 1) OR (FileNumToRemove > NumBatchULFiles) THEN
      BEGIN
        NL;
        Print('^8The range must be from 1 to '+IntToStr(NumBatchULFiles)+'!^0');
        InputStr := '?';
      END
      ELSE
      BEGIN
        Counter := 0;
        Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
        Reset(BatchULFile);
        RecNum := 1;
        WHILE (RecNum <= FileSize(BatchULFile)) DO
        BEGIN
          Seek(BatchULFile,(RecNum - 1));
          Read(BatchULFile,BatchUL);
          IF (BatchUL.BULUserNum = UserNum) THEN
          BEGIN
            Inc(Counter);
            IF (Counter = FileNumToRemove) THEN
            BEGIN
              BatchUL.BULVPointer := -1;
              BatchUL.BULVTextSize := 0;
              Seek(BatchULFile,(RecNum - 1));
              Write(BatchULFile,BatchUL);
              Dec(NumBatchULFiles);
              NL;
              Print('Removed from batch upload queue: "^1'+BatchUL.BULFileName+'^0".');
              SysOpLog('Batch UL Remove: "^1'+BatchUL.BULFileName+'^0".');

              Assign(BatchULF,General.DataPath+'BATCHUL.EXT');
              Reset(BatchULF,1);
              Assign(BatchULF1,General.DataPath+'BATCHUL.EX1');
              ReWrite(BatchULF1,1);
              FOR RecNum1 := 0 TO (FileSize(BatchULFile) - 1) DO
              BEGIN
                Seek(BatchULFile,RecNum1);
                Read(BatchULFile,BatchUL1);
                IF (BatchUL1.BULVPointer <> -1) THEN
                BEGIN
                  TempVPointer := (FileSize(BatchULF1) + 1);
                  Seek(BatchULF1,FileSize(BatchULF1));
                  TotLoad := 0;
                  Seek(BatchULF,(BatchUL1.BULVPointer - 1));
                  REPEAT
                    BlockRead(BatchULF,TempStr[0],1);
                    BlockRead(BatchULF,TempStr[1],Ord(TempStr[0]));
                    Inc(TotLoad,(Length(TempStr) + 1));
                    BlockWrite(BatchULF1,TempStr,(Length(TempStr) + 1));
                  UNTIL (TotLoad >= BatchUL1.BULVTextSize);
                  BatchUL1.BULVPointer := TempVPointer;
                  Seek(BatchULFile,RecNum1);
                  Write(BatchULFile,BatchUL1);
                END;
              END;
              Close(BatchULF);
              Erase(BatchULF);
              Close(BatchULF1);
              ReName(BatchULF1,General.DataPath+'BATCHUL.EXT');

              Dec(RecNum);
              FOR RecNum1 := RecNum TO (FileSize(BatchULFile) - 2) DO
              BEGIN
                Seek(BatchULFile,(RecNum1 + 1));
                Read(BatchULFile,BatchUL);
                Seek(BatchULFile,RecNum1);
                Write(BatchULFile,BatchUL);
              END;
              Seek(BatchULFile,(FileSize(BatchULFile) - 1));
              Truncate(BatchULFile);
            END;
          END;
          Inc(RecNum);
        END;
        Close(BatchULFile);
        LastError := IOResult;
        IF (NumBatchULFiles <> 0) THEN
        BEGIN
          NL;
          Print('^0Batch upload queue: ^1'+IntToStr(NumBatchULFiles)+' '+Plural('file',NumBatchULFiles));
        END
        ELSE
        BEGIN
          {NL;
          Print('The batch upload queue is now empty.');}
		  lRGLngStr(286,FALSE);
          SysOpLog('Cleared the batch upload queue.');
        END;
      END;
  UNTIL (InputStr <> '?') OR (HangUp);
END;

PROCEDURE ClearBatchULQueue;
VAR
  BatchULF1: FILE;
  BatchUL1: BatchULRecordType;
  TempStr: STRING;
  TotLoad: Integer;
  TempVPointer,
  RecNum,
  RecNum1: LongInt;
BEGIN
  IF (NumBatchULFiles = 0) THEN
  BEGIN
    {NL;
    Print('The batch upload queue is empty.');}
	lRGLngStr(286,FALSE);
    Exit;
  END;
  NL;
  IF PYNQ('Clear batch upload queue? ',0,FALSE) THEN
  BEGIN
    NL;
    Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
    Reset(BatchULFile);
    RecNum := 1;
    WHILE (RecNum <= FileSize(BatchULFile)) DO
    BEGIN
      Seek(BatchULFile,(RecNum - 1));
      Read(BatchULFile,BatchUL);
      IF (BatchUL.BULUserNum = UserNum) THEN
      BEGIN
        BatchUL.BULVPointer := -1;
        BatchUL.BULVTextSize := 0;
        Seek(BatchULFile,(RecNum - 1));
        Write(BatchULFile,BatchUL);
        Dec(NumBatchULFiles);

        Assign(BatchULF,General.DataPath+'BATCHUL.EXT');
        Reset(BatchULF,1);
        Assign(BatchULF1,General.DataPath+'BATCHUL.EX1');
        ReWrite(BatchULF1,1);
        FOR RecNum1 := 0 TO (FileSize(BatchULFile) - 1) DO
        BEGIN
          Seek(BatchULFile,RecNum1);
          Read(BatchULFile,BatchUL1);
          IF (BatchUL1.BULVPointer <> -1) THEN
          BEGIN
            TempVPointer := (FileSize(BatchULF1) + 1);
            Seek(BatchULF1,FileSize(BatchULF1));
            TotLoad := 0;
            Seek(BatchULF,(BatchUL1.BULVPointer - 1));
            REPEAT
              BlockRead(BatchULF,TempStr[0],1);
              BlockRead(BatchULF,TempStr[1],Ord(TempStr[0]));
              Inc(TotLoad,(Length(TempStr) + 1));
              BlockWrite(BatchULF1,TempStr,(Length(TempStr) + 1));
            UNTIL (TotLoad >= BatchUL1.BULVTextSize);
            BatchUL1.BULVPointer := TempVPointer;
            Seek(BatchULFile,RecNum1);
            Write(BatchULFile,BatchUL1);
          END;
        END;
        Close(BatchULF);
        Erase(BatchULF);
        Close(BatchULF1);
        ReName(BatchULF1,General.DataPath+'BATCHUL.EXT');

        Print('Removed from batch upload queue: "^1'+BatchUL.BULFileName+'^0".');
        SysOpLog('Batch UL Remove: "^1'+BatchUL.BULFileName+'^0".');

        Dec(RecNum);
        FOR RecNum1 := RecNum TO (FileSize(BatchULFile) - 2) DO
        BEGIN
          Seek(BatchULFile,(RecNum1 + 1));
          Read(BatchULFile,BatchUL);
          Seek(BatchULFile,RecNum1);
          Write(BatchULFile,BatchUL);
        END;
        Seek(BatchULFile,(FileSize(BatchULFile) - 1));
        Truncate(BatchULFile);
      END;
      Inc(RecNum);
    END;
    Close(BatchULFile);
    LastError := IOResult;
    {NL;
    Print('The batch upload queue is now empty.');}
	lRGLngStr(286,FALSE);
    SysOpLog('Cleared the batch upload queue.');
  END;
END;

PROCEDURE BatchUpload(BiCleanUp: Boolean; TransferTime: LongInt);
TYPE
  TotalsRecordType = RECORD
    FilesUL,
    FilesULCredit: Byte;
    BytesUL,
    BytesULCredit,
    PointsULCredit: LongInt;
  END;
VAR
  Totals: TotalsRecordType;
  BatchUL1: BatchULRecordType;
  BatchULF1: FILE;
  (*
  DirInfo: SearchRec;
  *)
  TempStr: STRING;
  InputStr: AStr;
  LineNum,
  FileNumToList,
  NumExtDesc: Byte;
  TotLoad,
  ReturnCode,
  ProtocolNumber,
  SaveFArea,
  SaveFileArea,
  NumFAreas,
  FArea,
  TempBULVTextSize: Integer;
  TempVPointer,
  RecNum,
  RecNum1,
  RefundTime,
  TakeAwayRefundTime,
  TotConversionTime: LongInt;
  AutoLogOff,
  AHangUp,
  WentToSysOp,
  SaveTempPause,
  SaveConfSystem: Boolean;

  PROCEDURE UpFile;
  VAR
    GotPts: Integer;
    ConversionTime: LongInt;
    ArcOk,
    Convt: Boolean;
  BEGIN
    InitFileArea(FileArea);

    ArcStuff(ArcOk,Convt,FileInfo.FileSize,ConversionTime,TRUE,TempDir+'UP\',FileInfo.FileName,FileInfo.Description);

    Inc(TotConversionTime,ConversionTime);

    UpdateFileInfo(FileInfo,FileInfo.FileName,GotPts);

    IF (ArcOk) THEN
    BEGIN

      NL;
      Star('Moving file to ^1'+MemFileArea.AreaName);
      NL;
      IF CopyMoveFile(FALSE,'',SQOutSp(TempDir+'UP\'+FileInfo.FileName),
                      SQOutSp(MemFileArea.ULPath+FileInfo.FileName),FALSE) THEN
      BEGIN

        IF (Totals.FilesULCredit < 255) THEN
          Inc(Totals.FilesULCredit);

        IF ((Totals.BytesULCredit + FileInfo.FileSize) < 2147483647) THEN
          Inc(Totals.BytesULCredit,FileInfo.FileSize)
        ELSE
          Totals.BytesULCredit := 2147483647;

        IF ((Totals.PointsULCredit + GotPts) < 2147483647) THEN
          Inc(Totals.PointsULCredit,GotPts)
        ELSE
          Totals.PointsULCredit := 2147483647;

        IF (AACS(General.ULValReq)) OR (General.ValidateAllFiles) THEN
          Include(FileInfo.FIFlags,FIOwnerCredited);

        WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray);

        Star(SQOutSp(FileInfo.FileName)+' successfully uploaded.');

        SysOpLog('^1Batch uploaded: "^1'+SQOutSp(FileInfo.FileName)+'^1" to ^1'+MemFileArea.AreaName+'.');

      END;

    END
    ELSE
    BEGIN
      Star('Upload not received.');

      IF ((FileInfo.FileSize DIV 1024) >= General.MinResume) THEN
      BEGIN
        NL;
        IF PYNQ('Save file for a later resume? ',0,TRUE) THEN
        BEGIN
          NL;
          IF CopyMoveFile(FALSE,'^1Progress: ',TempDir+'UP\'+FileInfo.FileName,MemFileArea.ULPath+FileInfo.FileName,TRUE) THEN
          BEGIN
            Include(FileInfo.FIFlags,FIResumeLater);
            WriteFV(FileInfo,FileSize(FileInfoFile),ExtendedArray);
          END;

        END;
      END;

      IF (NOT (FIResumeLater IN FileInfo.FIFlags)) THEN
        Kill(TempDir+'UP\'+FileInfo.FileName);

      SysOpLog('^1Errors batch uploading '+SQOutSp(FileInfo.FileName)+' - '+
               AOnOff(FIResumeLater IN FileInfo.FIFlags,'file saved for resume','file deleted'));
    END;

    IF (NOT ArcOk) AND (NOT BiCleanUp) THEN
    BEGIN

      Inc(TakeAwayRefundTime,(FileInfo.FileSize DIV Rate));

      Star('Time refund of '+FormattedTime(FileInfo.FileSize DIV Rate)+' will be taken away.');

    END;
  END;

BEGIN

  IF (NOT CheckDriveSpace('Batch upload',MemFileArea.ULPath,General.MinSpaceForUpload)) THEN
    Exit;

  SaveFileArea := FileArea;

  AutoLogOff := FALSE;

  IF (BiCleanUp) THEN
    RefundTime := 0
  ELSE
  BEGIN

    NL;
    Print('^1Batch upload (Statistics):^0');
    NL;
    Star('^0Total file(s)     : ^1'+FormatNumber(NumBatchULFiles)+'^0');

    IF (NumBatchULFiles = 0) THEN
    BEGIN
      PrintF('BATCHUL0');
      IF (NoFile) THEN
      BEGIN
        NL;
        Print('Warning!  No upload batch files specified yet.');
        Print('If you continue, and batch upload files, you will have to');
        Print('enter file descriptions for each file after the batch upload');
        Print('is complete.');
      END;
    END
    ELSE
    BEGIN
      PrintF('BATCHUL');
      IF (NoFile) THEN
      BEGIN
        NL;
        Print('^0If you batch upload files IN ADDITION to the files already');
        Print('specified in your upload batch queue, you must enter file');
        Print('descriptions for them after the batch upload is complete.');
      END;
    END;

    ProtocolNumber := DoProtocol(Protocol,TRUE,FALSE,TRUE,FALSE);
    CASE ProtocolNumber OF
      -1 : ;
      -2 : Exit;
      -3 : ;
      -4 : ;
      -5 : EditBatchULQueue;
    ELSE
      IF (InCom) THEN
      BEGIN
        PurgeDir(TempDir+'UP\',FALSE);

        NL;
        AutoLogOff := PYNQ('Auto-logoff after file transfer? ',0,FALSE);

        NL;
        Star('Ready to receive batch upload transfer.');

        TimeLock := TRUE;

        ExecProtocol('',
                     TempDir+'UP\',
                     FunctionalMCI(Protocol.EnvCmd,'','')
                     +#13#10+
                     General.ProtPath+FunctionalMCI(Protocol.ULCmd,'',''),
                     -1,
                     ReturnCode,
                     TransferTime);

        TimeLock := FALSE;

        NL;
        Star('Batch upload transfer complete.');

        RefundTime := (TransferTime * (General.ULRefund DIV 100));

        Inc(FreeTime,RefundTime);
      END;
    END;

  END;

  Assign(BatchULFile,General.DataPath+'BATCHUL.DAT');
  Reset(BatchULFile);

  FillChar(Totals,SizeOf(Totals),0);

  FindFirst(TempDir+'UP\*.*',AnyFile - Directory - VolumeID - Dos.Hidden - SysFile ,DirInfo);
  WHILE (DosError = 0) DO
  BEGIN
    Inc(Totals.FilesUL);
    Inc(Totals.BytesUL,DirInfo.Size);
    FindNext(DirInfo);
  END;

  IF (Totals.FilesUL = 0) THEN
  BEGIN
    NL;
    Print('No uploads detected!^0');
    Exit;
  END;

  AHangUp := FALSE;

  IF (HangUp) THEN
  BEGIN
    IF (ComPortSpeed > 0) THEN
    BEGIN
      lStatus_Screen(100,'Hanging up and taking phone off hook...',FALSE,InputStr);
      DoPhoneHangUp(FALSE);
      DoPhoneOffHook(FALSE);
      ComPortSpeed := 0;
    END;
    HangUp := FALSE;
    AHangUp := TRUE;
  END;

  IF (NOT AHangUp) THEN
  BEGIN
    NL;
    Print('^1Batch upload (Totals):^0');
    NL;
    Star('^0Total file(s)     : ^1'+FormatNumber(Totals.FilesUL)+'^0');
    Star('^0Total size        : ^1'+ConvertBytes(Totals.BytesUL,FALSE)+'^0');
    Star('^0Upload time       : ^1'+FormattedTime(TransferTime)+'^0');
    Star('^0Transfer rate     : ^1'+FormatNumber(GetCPS(Totals.BytesUL,TransferTime))+' cps^0');
    Star('^0Time refund       : ^1'+FormattedTime(RefundTime)+'^0');
    IF (AutoLogOff) THEN
      CountDown;
  END;

  TotConversionTime := 0;
  TakeAwayRefundTime := 0;

  RecNum := 1;
  WHILE (RecNum <= FileSize(BatchULFile)) DO
  BEGIN
    Seek(BatchULFile,(RecNum - 1));
    Read(BatchULFile,BatchUL);
    IF (BatchUL.BULUserNum = UserNum) AND Exist(TempDir+'UP\'+BatchUL.BULFileName) THEN
    BEGIN
      FileInfo.FileName := BatchUL.BULFileName;
      FileArea := BatchUL.BULSection;
      NL;
      Star('Found: "^1'+FileInfo.FileName+'^0"');
      IF (General.FileDiz) AND (DizExists(TempDir+'UP\'+FileInfo.FileName)) THEN
        GetDiz(FileInfo,ExtendedArray,NumExtDesc)
      ELSE
      BEGIN
        FileInfo.Description := BatchUL.BULDescription;
        FillChar(ExtendedArray,SizeOf(ExtendedArray),#0);
        IF (BatchUL.BULVPointer <> 0) THEN
        BEGIN
          Assign(BatchULF,General.DataPath+'BATCHUL.EXT');
          Reset(BatchULF,1);
          LineNum := 1;
          TempBULVTextSize := 0;
          Seek(BatchULF,(BatchUL.BULVPointer - 1));
          REPEAT
            BlockRead(BatchULF,TempStr[0],1);
            BlockRead(BatchULF,TempStr[1],Ord(TempStr[0]));
            Inc(TempBULVTextSize,(Length(TempStr) + 1));
            ExtendedArray[LineNum] := TempStr;
            Inc(LineNum);
          UNTIL (TempBULVTextSize >= BatchUL.BULVTextSize);
          BatchUL.BULVPointer := -1;
          BatchUL.BULVTextSize := 0;
          Seek(BatchULFile,(RecNum - 1));
          Write(BatchULFile,BatchUL);
        END;
      END;
      UpFile;
      Reset(BatchULF,1);
      Assign(BatchULF1,General.DataPath+'BATCHUL.EX1');
      ReWrite(BatchULF1,1);
      FOR RecNum1 := 0 TO (FileSize(BatchULFile) - 1) DO
      BEGIN
        Seek(BatchULFile,RecNum1);
        Read(BatchULFile,BatchUL1);
        IF (BatchUL1.BULVPointer <> -1) THEN
        BEGIN
          TempVPointer := (FileSize(BatchULF1) + 1);
          Seek(BatchULF1,FileSize(BatchULF1));
          TotLoad := 0;
          Seek(BatchULF,(BatchUL1.BULVPointer - 1));
          REPEAT
            BlockRead(BatchULF,TempStr[0],1);
            BlockRead(BatchULF,TempStr[1],Ord(TempStr[0]));
            Inc(TotLoad,(Length(TempStr) + 1));
            BlockWrite(BatchULF1,TempStr,(Length(TempStr) + 1));
          UNTIL (TotLoad >= BatchUL1.BULVTextSize);
          BatchUL1.BULVPointer := TempVPointer;
          Seek(BatchULFile,RecNum1);
          Write(BatchULFile,BatchUL1);
        END;
      END;
      Close(BatchULF);
      Erase(BatchULF);
      Close(BatchULF1);
      ReName(BatchULF1,General.DataPath+'BATCHUL.EXT');
      Dec(RecNum);
      IF (RecNum >= 0) AND (RecNum <= (FileSize(BatchULFile) - 2)) THEN
        FOR RecNum1 := RecNum TO (FileSize(BatchULFile) - 2) DO
        BEGIN
          Seek(BatchULFile,(RecNum1 + 1));
          Read(BatchULFile,BatchUL);
          Seek(BatchULFile,RecNum1);
          Write(BatchULFile,BatchUL);
        END;
      Seek(BatchULFile,(FileSize(BatchULFile) - 1));
      Truncate(BatchULFile);
      Dec(NumBatchULFiles);
    END;
    Inc(RecNum);
  END;

  FindFirst(TempDir+'UP\*.*',AnyFile - Directory - VolumeID - Dos.Hidden - SysFile,DirInfo);
  WHILE (DosError = 0) DO
  BEGIN
    FileInfo.FileName := DirInfo.Name;
    NL;
    Star('Found: "^1'+FileInfo.FileName+'^0"');

    IF (General.SearchDup) THEN
      IF (NOT FileSysOp) OR (PYNQ('Search for duplicates? ',0,FALSE)) THEN
          IF (SearchForDups(FileInfo.FileName)) THEN
            Exit;

    IF (General.SearchDup) AND (SearchForDups(FileInfo.FileName)) THEN
    BEGIN
      Star('Deleting duplicate file: "^1'+FileInfo.FileName+'^0"');
      Kill(TempDir+'UP\'+FileInfo.FileName);
    END
    ELSE
    BEGIN
      WentToSysOp := FALSE;
      IF (General.FileDiz) AND (DizExists(TempDir+'UP\'+FileInfo.FileName)) THEN
        GetDiz(FileInfo,ExtendedArray,NumExtDesc)
      ELSE
      BEGIN
        GetFileDescription(FileInfo,ExtendedArray,NumExtDesc,WentToSysOp);
        IF (AHangUp) THEN
        BEGIN
          FileInfo.Description := 'Not in upload batch queue - hungup after transfer';
          FillChar(ExtendedArray,SizeOf(ExtendedArray),#0);
        END;
      END;

      IF (WentToSysOp) THEN
        FileArea := General.ToSysOpDir
      ELSE
      BEGIN
        IF (AHangUp) THEN
          FArea := SaveFileArea
        ELSE
        BEGIN
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
              LFileAreaList(FArea,NumFAreas,6,FALSE);

            FileAreaScanInput('%LFMove to which file area? (^1'+IntToStr(LowFileArea)+'^2-^1'+IntToStr(HighFileArea)+'^2)'+
                             ' [^1?^2=^1First^2,^1<CR>^2=^1Next^2]: ',Length(IntToStr(HighFileArea)),InputStr,'[]?',
                             LowFileArea,HighFileArea);

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
              NL;
              Print('^0(^1###^0)Manual entry selection  ^0(^1<CR>^0)Select current entry');
              Print('^0(^1<Home>^0)First entry on page  ^0(^1<End>^0)Last entry on page');
              Print('^0(^1Left Arrow^0)Previous entry   ^0(^1Right Arrow^0)Next entry');
              Print('^0(^1Up Arrow^0)Move up            ^0(^1Down Arrow^0)Move down');
              Print('^0(^1[^0)Previous page             ^0(^1]^0)Next page');
              PauseScr(FALSE);
              FArea := SaveFArea;
            END
            ELSE IF (StrToInt(InputStr) < LowFileArea) OR (StrToInt(InputStr) > HighFileArea) THEN
            BEGIN
              NL;
              Print('^8The range must be from '+IntToStr(LowFileArea)+' to '+IntToStr(HighFileArea)+'!^0');
              InputStr := '?';
              FArea := 1
            END
            ELSE
            BEGIN
              FArea := CompFileArea(StrToInt(InPutStr),1);
              IF (FArea <> FileArea) THEN
                ChangeFileArea(FArea);
              IF (FArea <> FileArea) THEN
              BEGIN
                NL;
                Print('^8You do not have access to this file area.^0');
                InputStr := '?';
                FArea := 1
              END
              ELSE
              BEGIN
                InitFileArea(FArea);
                IF (NOT AACS(MemFileArea.ULACS)) THEN
                BEGIN
                  NL;
                  Print('^8You do not have the required upload access for this file area.^0');
                  InputStr := '?';
                  FArea := 1
                END
                ELSE IF ((NOT FileSysOp) AND (Exist(MemFileArea.ULPath+FileInfo.FileName)) OR
                     (Exist(MemFileArea.DLPath+FileInfo.FileName))) THEN
                BEGIN
                  NL;
                  Print('^8The file already exists in the upload or download path.^0');
                  InputStr := '?';
                  FArea := 1
                END
                ELSE IF (FileSize(FileInfoFile) >= MemFileArea.MaxFiles) THEN
                BEGIN
                  NL;
                  Print('^8This file area is full.^0');
                  InputStr := '?';
                  FArea := 1
                END;
                Close(FileInfoFile);
                Close(ExtInfoFile);
              END;
            END;
          UNTIL (NOT (InputStr[1] IN [^M,'?'])) OR (HangUp);
          TempPause := SaveTempPause;
          ConfSystem := SaveConfSystem;
          IF (SaveConfSystem) THEN
            NewCompTables;
        END;
        FileArea := FArea;
      END;
      UpFile;
    END;
    FindNext(DirInfo);
  END;

  lil := 0;

  Dec(RefundTime,TakeAwayRefundTime);

  Dec(FreeTime,TakeAwayRefundTime);

  SysOpLog('^1 - Totals:'+
           ' '+FormatNumber(Totals.FilesUL)+' '+Plural('file',Totals.FilesUL)+
           ', '+ConvertBytes(Totals.BytesUL,FALSE)+
           ', '+FormattedTime(TransferTime)+' tt'+
           ', '+FormatNumber(GetCPS(Totals.BytesUL,Transfertime))+' cps'+
           ', '+FormattedTime(RefundTime)+' rt');

  IF ((UploadsToday + Totals.FilesULCredit) < 2147483647) THEN
    Inc(UploadsToday,Totals.FilesULCredit)
  ELSE
    UploadsToday := 2147483647;

  IF ((UploadKBytesToday + (Totals.BytesULCredit DIV 1024)) < 2147483647) THEN
    Inc(UploadKBytesToday,(Totals.BytesULCredit DIV 1024))
  ELSE
    UploadKBytesToday := 2147483647;

  LIL := 0;

  NL;
  Print('^1Batch upload (Credits):^0');
  NL;
  Star('^0Total file(s)     : ^1'+FormatNumber(Totals.FilesULCredit));
  Star('^0Total size        : ^1'+ConvertBytes(Totals.BytesULCredit,FALSE));
  Star('^0Total file points : ^1'+FormatNumber(Totals.PointsULCredit));
  Star('^0Time refund       : ^1'+FormattedTime(RefundTime)+'^0');

  IF (AACS(General.ULValReq)) OR (General.ValidateAllFiles) THEN
  BEGIN

    IF ((ThisUser.Uploads + Totals.FilesULCredit) < 2147483647) THEN
      Inc(ThisUser.Uploads,Totals.FilesULCredit)
    ELSE
      ThisUser.Uploads := 2147483647;

    IF (ThisUser.UK + (Totals.BytesULCredit DIV 1024) < 2147483647) THEN
      Inc(ThisUser.UK,(Totals.BytesULCredit DIV 1024))
    ELSE
      ThisUser.UK := 2147483647;

    IF ((ThisUser.FilePoints + Totals.PointsULCredit) < 2147483647) THEN
      Inc(ThisUser.FilePoints,Totals.PointsULCredit)
    ELSE
      ThisUser.FilePoints := 2147483647;

  END
  ELSE
  BEGIN
    NL;
    Print('^1You will receive upload credit after the SysOp validates the '+Plural('file',Totals.FilesULCredit)+'!');
    Totals.FilesULCredit := 0;
    Totals.BytesULCredit := 0;
    Totals.PointsULCredit := 0;
  END;

  IF (ChopTime <> 0) THEN
  BEGIN
    ChopTime := ((ChopTime + RefundTime) - TakeAwayRefundTime);
    FreeTime := ((FreeTime - RefundTime) + TakeAwayRefundTime);
    NL;
    Star('You will receive your time refund after the event.');
    RefundTime := 0;
  END;

  SysOpLog('^1 - Credits:'+
           ' '+FormatNumber(Totals.FilesULCredit)+' '+Plural('file',Totals.FilesULCredit)+
           ', '+ConvertBytes(Totals.BytesULCredit,FALSE)+
           ', '+FormatNumber(Totals.PointsULCredit)+' fp'+
           ', '+FormattedTime(RefundTime)+' rt');

  IF (NumBatchULFiles > 0) THEN
  BEGIN
    LIL := 0;
    NL;
    Print('^1Batch upload (Not Transferred):^0');
    NL;
    Star('^0Total file(s)     : ^1'+FormatNumber(NumBatchULFiles));
    SysOpLog('^1 - Not uploaded:'+
             ' '+FormatNumber(NumBatchULFiles)+' '+Plural('file',NumBatchULFiles));
  END;

  LIL := 0;

  NL;
  Star('Thanks for the '+Plural('file',Totals.FilesULCredit)+', '+Caps(ThisUser.Name)+'!');
  PauseScr(False);

  SaveURec(ThisUser,UserNum);

  Close(BatchULFile);

  IF (AHangUp) THEN
    BEGIN
      lStatus_Screen(100,'Hanging up phone again...',FALSE,InputStr);
      DoPhoneHangUp(FALSE); {LeeW: What about telnet?}
      HangUp := TRUE;
    END;
  FileArea := SaveFileArea;
  InitFileArea(FileArea);
END;

PROCEDURE BatchDLULInfo;
BEGIN
  IF (NumBatchDLFiles <> 0) THEN
  BEGIN
    Print('^9>> ^1You have ^1'+FormatNumber(NumBatchDLFiles)+'^1 '+Plural('file',NumBatchDLFiles)+
          ' left in your batch download queue.^0');
    NL;
  END;
  IF (NumBatchULFiles <> 0) THEN
  BEGIN
    Print('^9>> ^1You have ^1'+FormatNumber(NumBatchULFiles)+'^1 '+Plural('file',NumBatchULFiles)+
          ' left in your batch upload queue.^0');
    NL;
  END;
END;

END.

