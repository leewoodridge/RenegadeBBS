{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 03/22/2022 fixed downloads not modifying user stats -- do testing to make sure all ok
 what about uploads???
}
UNIT File8;

INTERFACE

USES
  DOS,
  Common;

PROCEDURE Send(FileInfo: FileInfoRecordType; DirFileRecNum: Integer; DownloadPath: PathStr;
               VAR TransferFlags: TransferFlagSet);
PROCEDURE Receive(FileName: Str12; UploadPath: PathStr; ResumeFile: Boolean; VAR UploadOk,KeyboardAbort,AddULBatch: Boolean;
                  VAR TransferTime: LongInt);

IMPLEMENTATION

USES
  CRT,
  ExecBat,
  File0,
  File1,
  File2,
  File4,
  File6,
  File12,
  TimeFunc;

{ CheckFileRatio
 1 - File bad
 2 - File + Batch bad
 3 - File Bad - Daily
 4 - File + Batch bad - Daily
}

PROCEDURE CheckFileRatio(FileInfo: FileInfoRecordType; VAR ProtocolNumber: Integer);
VAR
  Counter: Byte;
  RecNum: LongInt;
  FileKBSize: LongInt;
  Ratio: Real;
  BadRatio,
  DailyLimits: Boolean;
BEGIN
  FileKbSize := (FileInfo.FileSize DIV 1024);
  IF (NumBatchDLFiles > 0) THEN
    BEGIN
      Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
      Reset(BatchDLFile);
      RecNum := 1;
      WHILE (RecNum <= FileSize(BatchDLFile)) DO
        BEGIN
          Seek(BatchDLFile,(RecNum - 1));
          Read(BatchDLFile,BatchDL);
          IF (BatchDL.BDLUserNum = UserNum) AND (BatchDL.BDLFileName = FileInfo.FileName) THEN
            IF (NOT (IsNoRatio IN BatchDL.BDLFlags)) THEN
              Inc(FileKBSize,(BatchDL.BDLFSize DIV 1024));
          Inc(RecNum);
        END;
      Close(BatchDLFile);
      LastError := IOResult;
    END;

  BadRatio := FALSE;

  IF (ThisUser.UK > 0) THEN
    Ratio := ((FileKbSize + ThisUser.DK) / ThisUser.UK)
  ELSE
    Ratio := (FileKBSize + ThisUser.DK);

  IF (General.DLKRatio[ThisUser.SL] > 0) AND (Ratio > General.DLKRatio[ThisUser.SL]) THEN
    BadRatio := TRUE;

  IF (ThisUser.Uploads > 0) THEN
    Ratio := (((ThisUser.Downloads + NumBatchDLFiles) + 1) / ThisUser.Uploads)
  ELSE
    Ratio := ((ThisUser.Downloads + NumBatchDLFiles) + 1);

  IF (General.DLRatio[ThisUser.SL] > 0) AND (Ratio > General.DLRatio[ThisUser.SL]) THEN
    BadRatio := TRUE;

  IF (NOT General.ULDLRatio) THEN
    BadRatio := FALSE;

  DailyLimits := FALSE;
  IF (General.DailyLimits) THEN
    IF ((ThisUser.DLKToday + FileKbSize) > General.DLKOneDay[ThisUser.SL]) OR
       (((ThisUser.DLToday + NumBatchDLFiles) + 1) > General.DLOneDay[ThisUser.SL]) THEN
    BEGIN
      BadRatio := TRUE;
      DailyLimits := TRUE;
    END;

  IF (AACS(General.NoDLRatio)) OR (FNoDLRatio IN ThisUser.ACFlags) THEN
    BadRatio := FALSE;

  LoadFileArea(FileArea);
  IF (FANoRatio IN MemFileArea.FAFlags) THEN
    BadRatio := FALSE;

  Counter := 0;

  IF (BadRatio) THEN
    IF (NumBatchDLFiles = 0) THEN
      Counter := 1
    ELSE
      Counter := 2;

  IF (DailyLimits) AND (Counter > 0) THEN
    Inc(Counter,2);

  CASE Counter OF
    1,3 : BEGIN
            IF (Counter = 3) THEN
            BEGIN
              PrintF('DLTMAX');
              IF (NoFile) THEN
              BEGIN
                {
                NL;
                Print('^1Your upload/download ratio is too poor to download this.');
                }
                NL;
                lRGLngStr(27,FALSE);
                NL;
                Print('^0Today you have downloaded '+FormatNumber(ThisUser.DLToday)+' '+Plural('file',ThisUser.DLToday)+
                      '^0 totaling '+FormatNumber(ThisUser.DLKToday)+'k');
                NL;
                Print('^0The maximum you can download in one day is '+FormatNumber(General.DLOneDay[ThisUser.SL])+
                      ' '+Plural('file',General.DLOneDay[ThisUser.SL])+
                      '^0 totaling '+FormatNumber(General.DLKOneDay[ThisUser.SL])+'k');
              END;
            END
            ELSE
            BEGIN
              PrintF('DLMAX');
              IF (NoFile) THEN
              BEGIN
                {
                NL;
                Print('^1Your upload/download ratio is too poor to download this.');
                }
                NL;
                lRGLngStr(27,FALSE);
                NL;
                Print('^1You have downloaded: '+FormatNumber(ThisUser.DK)+'k in '+FormatNumber(ThisUser.Downloads)+
                      ' '+Plural('file',ThisUser.Downloads));
                Print('^1You have uploaded  : '+FormatNumber(ThisUser.UK)+'k in '+FormatNumber(ThisUser.Uploads)+
                      ' '+Plural('file',ThisUser.Uploads));
                NL;
                Print('^1  1 upload for every '+FormatNumber(General.DLRatio[ThisUser.SL])+
                      ' downloads must be maintained.');
                Print('^1  1k must be uploaded for every '+FormatNumber(General.DLKRatio[ThisUser.SL])+'k downloaded.');
              END;
            END;
          END;
    2,4 : BEGIN
            IF (Counter = 4) THEN
              PrintF('DLBTMAX')
            ELSE
              PrintF('DLBMAX');
            IF (NoFile) THEN
            BEGIN
              {
              NL;
              Print('^1Your upload/download ratio is too poor to download this.');
              }
              NL;
              lRGLngStr(27,FALSE);
              NL;
              Print('^1Assuming you download the files already in the batch queue,');
              IF (Counter = 2) THEN
                Print('^1your upload/download ratio would be out of balance.')
              ELSE
                Print('^1you would exceed the maximum download limits for one day.');
            END;
          END;
  END;
  IF (Counter IN [1..4]) THEN
  BEGIN
    SysOpLog('Download refused: Ratio out of balance: '+SQOutSp(FileInfo.FileName));
    SysOpLog(' ULs: '+FormatNumber(ThisUser.UK)+'k in '+FormatNumber(ThisUser.Uploads)+
             ' '+Plural('file',ThisUser.Uploads)+
             ' - DLs: '+FormatNumber(ThisUser.DK)+'k in '+FormatNumber(ThisUser.Downloads)+
             ' '+Plural('file',ThisUser.Downloads));
    ProtocolNumber := -2;
  END;

END;

PROCEDURE BatchDLAdd(FileInfo: FileInfoRecordType; DownloadPath: Str40; TransferFlags: TransferFlagSet);
VAR
  User: UserRecordType;
BEGIN
  IF CheckBatchDL(DownloadPath+FileInfo.FileName) THEN
  BEGIN
    NL;
    Print('^8This file is already in the batch download queue!^0');
  END
  ELSE IF (NumBatchDLFiles = General.MaxBatchDLFiles) THEN
  BEGIN
    NL;
    Print('^8The batch download queue is full!^0');
  END
  ELSE IF ((BatchDLTime + (FileInfo.FileSize DIV Rate)) > NSL) THEN
  BEGIN
    NL;
    Print('^8Insufficient time left online to add to the batch download queue!^0');
  END
  ELSE
  BEGIN

    Assign(BatchDLFile,General.DataPath+'BATCHDL.DAT');
    IF (NOT Exist(General.DataPath+'BATCHDL.DAT')) THEN
      ReWrite(BatchDLFile)
    ELSE
      Reset(BatchDLFile);

    WITH BatchDL DO
    BEGIN

      BDLFileName := SQOutSp(DownloadPath+FileInfo.FileName);

      IF (FileArea <> -1) THEN
        BDLOwnerName := AllCaps(FileInfo.OwnerName)
      ELSE
      BEGIN
        LoadURec(User,1);
        BDLOwnerName := AllCaps(User.Name);
      END;

      IF (IsCDRom IN TransferFlags) THEN
        BDLStorage := CD
      ELSE
        BDLStorage := Disk;

      BDLUserNum := UserNum;

      BDLSection := FileArea;

      IF (FileArea <> -1) THEN
        BDLPoints := FileInfo.FilePoints
      ELSE
        BDLPoints := 0;

      IF (FileArea <> -1) THEN
        BDLUploader := FileInfo.OwnerNum
      ELSE
        BDLUploader := 1;

      BDLFSize := FileInfo.FileSize;

      BDLTime := (FileInfo.FileSize DIV Rate);

      IF (IsFileAttach IN TransferFlags) THEN
        Include(BDLFlags,IsFileAttach)
      ELSE IF (IsUnlisted IN TransferFlags) THEN
        Include(BDLFlags,IsUnlisted)
      ELSE IF (IsTempArc IN TransferFlags) THEN
        Include(BDLFlags,IsTempArc)
      ELSE IF (IsQWK IN TransferFlags) THEN
        Include(BDLFlags,IsQWK);

      IF (NOT ChargeFilePoints(FileArea)) THEN
        Include(BDLFlags,IsNoFilePoints);

      IF (NOT ChargeFileRatio(FileArea)) THEN
        Include(BDLFlags,IsNoRatio);

    END;
    Seek(BatchDLFile,FileSize(BatchDLFile));
    Write(BatchDLFile,BatchDL);
    Close(BatchDLFile);

    Inc(NumBatchDLFiles);

    Inc(BatchDLSize,BatchDL.BDLFSize);

    Inc(BatchDLTime,BatchDL.BDLTime);

    Inc(BatchDLPoints,BatchDL.BDLPoints);

    {
    NL;
    Print('^1File added to batch download queue.');
    }
    lRGLngStr(30,FALSE);
    NL;
    Print('^0Batch download queue:'+
          ' ^1'+IntToStr(NumBatchDLFiles)+' '+Plural('file',NumBatchDLFiles)+
          ', '+ConvertBytes(BatchDLSize,FALSE)+
          ', '+FormatNumber(BatchDLPoints)+' '+Plural('file point',BatchDLPoints)+
          ', '+FormattedTime(BatchDLTime)+'^0');

    IF (IsFileAttach IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'File Attach'
    ELSE IF (IsUnlisted IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'Unlisted Download'
    ELSE IF (IsTempArc IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'Temporary Archive'
    ELSE IF (IsQWK IN BatchDL.BDLFlags) THEN
      MemFileArea.AreaName := 'QWK Download';

    SysOpLog('Batch DL Add: "^1'+StripName(BatchDL.BDLFileName)+
            '^0" from ^1'+MemFileArea.AreaName);
  END;
END;

PROCEDURE Send(FileInfo: FileInfoRecordType; DirFileRecNum: Integer; DownloadPath: PathStr;
               VAR TransferFlags: TransferFlagSet);
(*
TYPE
  TotalsRecordType = RECORD
    FilesDL,
    FilesDLRatio: Byte;
    BytesDL,
    BytesDLRatio,
    PointsDL,
    PointsDLRatio: LongInt;
  END;
*)
VAR
  {Totals: TotalsRecordType;}
  ReturnCode,
  ProtocolNumber: Integer;
  TransferTime: LongInt;
BEGIN
  Exclude(TransferFlags,IsKeyboardAbort);
  Exclude(TransferFlags,IsTransferOk);

  IF (lIsAddDLBatch IN TransferFlags) THEN
    ProtocolNumber := -4
  ELSE
    ProtocolNumber := DoProtocol(Protocol,FALSE,TRUE,FALSE,FALSE);

  IF (IsCheckRatio IN TransferFlags) THEN
    IF (-ProtocolNumber IN [1,4]) OR (NOT (-ProtocolNumber IN [2..3,5])) THEN
      CheckFileRatio(FileInfo,ProtocolNumber);

  CASE ProtocolNumber OF
    -2: BEGIN
          NL;
          Print('^0Aborted!');
          Include(TransferFlags,IsKeyboardAbort);
        END;
    -3: BEGIN
          NL;
          Print('^0Skipped!');
        END;
    -4: BatchDLAdd(FileInfo,DownloadPath,TransferFlags);
    -5: ;
    ELSE
      IF (InCom) OR (ProtocolNumber = -1) THEN
        BEGIN
          IF (ProtocolNumber = -1) THEN
            BEGIN
              NL;
              Print('^1Caution: ^0No check is made to ensure the file you selected for viewing^0');
              Print('^0         is an ascii text file!');
              NL;
              IF (NOT PYNQ('Continue to view selected file? ',0,FALSE)) THEN
                BEGIN
                  Include(TransferFlags,IsKeyboardAbort);
                  Exit;
                END;
            END;
          IF (IsCDRom IN TransferFlags) THEN
            BEGIN
              NL;
              Print('Please wait, copying file from CD-ROM ... ');
              IF CopyMoveFile(TRUE,'',DownloadPath+SQOutSp(FileInfo.FileName),TempDir+'CD\'+
                 SQOutSp(FileInfo.FileName),FALSE) THEN
                DownloadPath := TempDir+'CD\';
            END;
          NL;
          IF PYNQ('Auto-logoff after '+AOnOff(ProtocolNumber = -1,'viewing file','file transfer')+'? ',0,FALSE) THEN
            Include(TransferFlags,IsAutoLogOff);
          NL;
          Star('Ready to '+AOnOff(ProtocolNumber = -1,'view','send')+': ^1'+SQOutSp(FileInfo.FileName)+'.');

          ExecProtocol(AOnOff(ProtocolNumber = -1,DownloadPath+SQOutSp(FileInfo.FileName),''),
                              TempDir+'UP\',FunctionalMCI(Protocol.EnvCmd,'','')+#13#10+General.ProtPath+
                              FunctionalMCI(Protocol.DLCmd,DownloadPath+SQOutSp(FileInfo.FileName),''),
                              0,ReturnCode,TransferTime);

          NL;
          Star('File '+AOnOff(ProtocolNumber = -1,'viewing','download')+' complete.');

          IF (ProtocolNumber = -1) THEN
            BEGIN
              IF (ReturnCode = 0) THEN
                Include(TransferFlags,IsTransferOk);
            END
          ELSE
            BEGIN
              IF FindReturnCode(Protocol.DLCode,Protocol.PRFlags,IntToStr(ReturnCode)) THEN
                Include(TransferFlags,IsTransferOk);
            END;

          IF (NOT (IsTransferOk IN TransferFlags)) THEN
            BEGIN
              NL;
              Star(AOnOff(ProtocolNumber = -1,'Text view','Download')+' unsuccessful.');
              SysOpLog('^8'+AOnOff(ProtocolNumber = -1,'Text view','Download')+' failed: "^1'+SQOutSp(FileInfo.FileName)+
                       '^8" from ^1'+MemFileArea.AreaName);
              Include(TransferFlags,isPaused);
            END
          ELSE
            BEGIN
              LIL := 0;
              SysOpLog('^1'+AOnOff(ProtocolNumber = -1,'Viewed','Downloaded')+' "^1'+SQOutSp(FileInfo.FileName)+
                       '^1" from ^1'+MemFileArea.AreaName+'.');

              {
                LeeW: This totals record seems to be screwing everything up --
                      Was it part of unfinished batch DL implementation?
              }

              (*
              FillChar(Totals,SizeOf(Totals),0);

              Inc(Totals.FilesDL);
              Inc(Totals.BytesDL,FileInfo.FileSize);
              Inc(Totals.PointsDL,FileInfo.FilePoints);

              IF (ChargeFileRatio(FileArea)) THEN
                BEGIN
                  Inc(Totals.FilesDLRatio);
                  Inc(Totals.BytesDLRatio,FileInfo.FileSize);
                END;

              IF (ChargeFilePoints(FileArea)) THEN
                Inc(Totals.PointsDLRatio,FileInfo.FilePoints);
              *)

              IF ((ThisUser.Downloads + 1{Totals.FilesDLRatio}) < 2147483647) THEN
                Inc(ThisUser.Downloads{,Totals.FilesDLRatio})
              ELSE
                ThisUser.Downloads := 2147483647;

              IF ((ThisUser.DLToday + 1{Totals.FilesDLRatio}) < 2147483647) THEN
                Inc(ThisUser.DLToday{,Totals.FilesDLRatio})
              ELSE
                ThisUser.DLToday := 2147483647;

              IF ((ThisUser.DK + ({Totals.BytesDLRatio}FileInfo.FileSize DIV 1024)) < 2147483647) THEN
                Inc(ThisUser.DK,({Totals.BytesDLRatio}FileInfo.FileSize DIV 1024))
              ELSE
                ThisUser.DK := 2147483647;

              IF ((ThisUser.DLKToday + ({Totals.BytesDLRatio}FileInfo.FileSize DIV 1024)) < 2147483647) THEN
                Inc(ThisUser.DLKToday,({Totals.BytesDLRatio}FileInfo.FileSize DIV 1024))
              ELSE
                ThisUser.DLKToday := 2147483647;

              IF ((ThisUser.FilePoints - {Totals.PointsDLRatio}FileInfo.FilePoints) > 0) THEN
                Dec(ThisUser.FilePoints,{Totals.PointsDLRatio}FileInfo.FilePoints)
              ELSE
                ThisUser.FilePoints := 0;

              IF ((DownloadsToday + 1{Totals.FilesDL}) < 2147483647) THEN
                Inc(DownloadsToday{,Totals.FilesDL})
              ELSE
                DownloadsToday := 2147483647;

              IF ((DownloadKBytesToday + ({Totals.BytesDL}FileInfo.FileSize DIV 1024)) < 2147483647) THEN
                Inc(DownloadKBytesToday,({Totals.BytesDL}FileInfo.FileSize DIV 1024))
              ELSE
                DownloadKBytesToday := 2147483647;

              SaveURec(ThisUser,UserNum);

              LIL := 0;

              { LeeW: Improve these stats/make custo}

              NL;
              Print('^1Download statistics (Totals):^0');
              NL;
              Star('^0File name         : ^1'+SQOutSp(FileInfo.FileName));
              Star('^0File size         : ^1'+ConvertBytes({Totals.BytesDL}FileInfo.FileSize,FALSE));
              Star('^0File point(s)     : ^1'+FormatNumber({Totals.PointsDL}FileInfo.FilePoints));
              Star(AOnOff(ProtocolNumber = -1,'View time         ','^0Download time     ')+': ^1'+FormattedTime(TransferTime));
              Star('^0Transfer rate     : ^1'+FormatNumber(GetCPS(FileInfo.FileSize,Transfertime))+' cps');

              SysOpLog('^1 - Totals:'+
                       ' '+FormatNumber({Totals.FilesDL}1)+' '+Plural('file',{Totals.FilesDL}1)+
                       ', '+ConvertBytes({Totals.BytesDL}FileInfo.FileSize,FALSE)+
                       ', '+FormatNumber({Totals.PointsDL}FileInfo.FilePoints)+' fp'+
                       ', '+FormattedTime(TransferTime)+
                       ', '+FormatNumber(GetCPS({Totals.BytesDL}FileInfo.FileSize,TransferTime))+' cps.');
              LIL := 0;

              NL;
              Print('^1Download statistics (Charges):^0');
              NL;
              Star('^0File(s)           : ^1'+FormatNumber({Totals.FilesDLRatio}1));
              Star('^0File size         : ^1'+ConvertBytes({Totals.BytesDLRatio}FileInfo.FileSize,FALSE));
              Star('^0File point(s)     : ^1'+FormatNumber({Totals.PointsDLRatio}FileInfo.FilePoints));

              SysOpLog('^1 - Charges:'+
                       ' '+FormatNumber({Totals.FilesDLRatio}1)+' '+Plural('file',{Totals.FilesDLRatio}1)+
                       ', '+ConvertBytes({Totals.BytesDLRatio}FileInfo.FileSize,FALSE)+
                       ', '+FormatNumber({Totals.PointsDLRatio}FileInfo.FilePoints)+' fp.');

              CreditUploader(FileInfo);

              IF (DirFileRecNum <> -1) THEN
                BEGIN
                  Inc(FileInfo.Downloaded);
                  Seek(FileInfoFile,DirFileRecNum);
                  Write(FileInfoFile,FileInfo);
                  LastError := IOResult;
                END;

              LIL := 0;
              NL;
              Print('^1Enjoy the file, '+Caps(ThisUser.Name)+'!^0');
              PauseScr(FALSE);
            END;

          IF (ProtBiDirectional IN Protocol.PRFlags) AND (NOT OfflineMail) THEN
            BatchUpload(TRUE,0);
          IF (IsAutoLogoff IN TransferFlags) THEN
            CountDown
        END;
  END;
END;

PROCEDURE Receive(FileName: Str12; UploadPath: PathStr; ResumeFile: Boolean; VAR UploadOk, KeyboardAbort, AddULBatch: Boolean;
                  VAR TransferTime: LongInt);
VAR
  ReturnCode,
  ProtocolNumber: Integer;
BEGIN
  UploadOk := TRUE;
  KeyboardAbort := FALSE;
  TransferTime := 0;
  ProtocolNumber := DoProtocol(Protocol,TRUE,FALSE,FALSE,ResumeFile);
  CASE ProtocolNumber OF
    -1: UploadOk := FALSE;
    -2: BEGIN
          UploadOk := FALSE;
          KeyboardAbort := TRUE;
         END;
    -3: BEGIN
          UploadOk := FALSE;
          KeyboardAbort := TRUE;
        END;
    -4: AddULBatch := TRUE;
    -5: UploadOk := FALSE;
    ELSE
      IF (NOT InCom) THEN
        UploadOk := FALSE
      ELSE
        BEGIN
          PurgeDir(TempDir+'UP\',FALSE);
          NL;
          Star('Ready to receive: ^1'+SQOutSp(FileName)+'.');
          TimeLock := TRUE;
          ExecProtocol('',UploadPath,FunctionalMCI(Protocol.EnvCmd,'','')+#13#10+General.ProtPath+FunctionalMCI(
                       Protocol.ULCmd,SQOutSp(FileName),''),0,ReturnCode,TransferTime);
          TimeLock := FALSE;
          NL;
          Star('File upload complete.');
          UploadOk := FindReturnCode(Protocol.ULCode,Protocol.PRFlags,IntToStr(ReturnCode));
        END;
  END;
END;
END.