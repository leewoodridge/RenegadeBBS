{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

UNIT File2;

INTERFACE

USES
  Common;

FUNCTION CopyMoveFile(CopyFile: Boolean; DisplayStr: AStr; CONST SrcName,DestName: AStr; CONST ShowProg: Boolean): Boolean;

IMPLEMENTATION

USES
  Dos;

FUNCTION CopyMoveFile(CopyFile: Boolean; DisplayStr: AStr; CONST SrcName,DestName: AStr; CONST ShowProg: Boolean): Boolean;
VAR
  Buffer: ARRAY [1..8192] OF Byte;
  FromF,
  ToF: FILE;
  CurDir: AStr;
  ProgressStr: Str3;
  NumRead: Word;
  TotalNumRead,
  FileDate: LongInt;
  OK,
  Nospace: Boolean;
BEGIN
  OK := TRUE;
  NoSpace := FALSE;
  GetDir(0,CurDir);
  IF (ShowProg) THEN
    Prompt(DisplayStr);
  IF (NOT CopyFile) THEN
  BEGIN
    Assign(FromF,SrcName);
    ReName(FromF,DestName);
    LastError := IOResult;
    IF (LastError <> 0) THEN
      OK := FALSE
    ELSE IF (ShowProg) THEN
        Print('^1100%^0')
  END;
  IF (NOT OK) OR (CopyFile) THEN
  BEGIN
    OK := TRUE;
    IF (SrcName = DestName) THEN
      OK := FALSE
    ELSE
    BEGIN
      Assign(FromF,SrcName);
      Reset(FromF,1);
      LastError := IOResult;
      IF (LastError <> 0) THEN
        OK := FALSE
      ELSE
      BEGIN
        GetFTime(FromF,FileDate);
        IF ((FileSize(FromF) DIV 1024) >= DiskKBFree(DestName)) THEN
        BEGIN
          Close(FromF);
          NoSpace := TRUE;
          OK := FALSE;
        END
        ELSE
        BEGIN
          Assign(ToF,DestName);
          ReWrite(ToF,1);
          LastError := IOResult;
          IF (LastError <> 0) THEN
            OK := FALSE
          ELSE
          BEGIN
            SetFTime(ToF,FileDate);
            IF (ShowProg) THEN
              Prompt('^1  0%^0');
            TotalNumRead := 0;
            REPEAT
              BlockRead(FromF,Buffer,SizeOf(Buffer),NumRead);
              BlockWrite(ToF,Buffer,NumRead);
              Inc(TotalNumRead,NumRead);
              IF (ShowProg) AND (FileSize(FromF) > 0) THEN
              BEGIN
                Str(Trunc(TotalNumRead / FileSize(FromF) * 100):3,ProgressStr);
                Prompt(^H^H^H^H+'^1'+ProgressStr+'%^0');
              END;
            UNTIL (NumRead < SizeOf(Buffer));
            IF (ShowProg) THEN
            BEGIN
              UserColor(0);
              NL;
            END;
            Close(ToF);
            Close(FromF);
            IF (NOT CopyFile) AND (OK) AND (NOT NoSpace) THEN
              Kill(SrcName);
          END;
        END;
      END;
    END;
  END;
  ChDir(CurDir);
  IF (NoSpace) THEN
  BEGIN
    IF (ShowProg) THEN
      Print('^8destination drive full!^0');
    SysOpLog('^8Error '+AOnOff(CopyFile,'copying','moving')+' (No-Space): "'+SrcName+'" to "'+DestName+'"!');
  END
  ELSE IF (NOT Ok) THEN
  BEGIN
    IF (ShowProg) THEN
      Print('^8failed!^0');
    SysOpLog('^8Error '+AOnOff(CopyFile,'copying','moving')+' (I/O): "'+SrcName+'" to "'+DestName+'"!');
  END
  ELSE
    SysOpLog('^0'+AOnOff(CopyFile,'Copied','Moved')+' file: "^1'+SrcName+'^0" to "^1'+DestName+'^0".');
  CopyMoveFile := (OK) AND (NOT NoSpace);
END;

END.
