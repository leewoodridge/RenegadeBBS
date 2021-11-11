{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 09/29/2021 - Moved ToLower func to common, likely useful elsewhere
            - Indented, formatting, cleanup
            - oneliner_view now ONLY views, oneliner_add now ONLY adds
            - renamed ONELE to ONELT to keep with standard format
            - All strings added to RGLNG
            - OneLiner_Random prints a random oneliner, but I don't know how to make the func store it
 10/08/2021 - Change SysOp to AACS(General.AnonPubRead) to see anonymous posters names
 10/19/2021 - Added SysOpLog error message if ONELM.EXT is missing
}
UNIT OneLiner;

INTERFACE

USES
    Common,
    CRT,
    TimeFunc,
    Mail1;

TYPE
  OneLinerRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    RecordNum  : LongInt;
    OneLiner   : STRING[55];
    UserID     : LongInt;
    UserName   : STRING[36];
    DateAdded,
    DateEdited : UnixTime;
    Anonymous  : Boolean;
  END;

PROCEDURE OneLiners; { View and prompt to add }
PROCEDURE OneLiner_Add; { Only add }
PROCEDURE OneLiner_View; { Only view }
FUNCTION OneLiner_Random: STRING; { Display a random oneliner }

IMPLEMENTATION

VAR
  OneLinerListFile: FILE OF OneLinerRecordType;
  OneLineRec: OneLinerRecordType;

FUNCTION OneLinerListMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  OneLinerListPtr: ^OneLinerRecordType;
  User: UserRecordType;
BEGIN
  OneLinerListPtr := Data1;
  OneLinerListMCI := S;
  CASE S[1] OF
    'A' : CASE S[2] OF
            'N' : OneLinerListMCI := ShowYesNo(OneLinerListPtr^.Anonymous); { Anon - Yes/No }
            'T' : OneLinerListMCI := AOnOff(OneLinerListPtr^.Anonymous, 'True', 'False'); { Anon - True/False }
          END;
    'D' : CASE S[2] OF
            'A' : OneLinerListMCI := Pd2Date(OneLinerListPtr^.DateAdded); { Date Added }
            'E' : OneLinerListMCI := Pd2Date(OneLinerListPtr^.DateEdited); { Date Edited - Not Used }
          END;
    'O' : CASE S[2] OF
            'L' : OneLinerListMCI := OneLinerListPtr^.OneLiner; { The OneLiner }
          END;
    'R' : CASE S[2] OF
            'N' : OneLinerListMCI := IntToStr(OneLinerListPtr^.RecordNum); { OneLiner Record Number }
          END;
    'U' : CASE S[2] OF
            '#' : BEGIN { User ID }
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := '';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                  END;
            '1' : BEGIN { User ID Without # }
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := '';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := IntToStr(OneLinerListPtr^.UserID);
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := IntToStr(OneLinerListPtr^.UserID);
                  END;
            'N' : BEGIN { User Name }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'Anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := Caps(User.Name) + ' ^4(^5A^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := Caps(User.Name);
                  END;
            'L' : BEGIN { User Name Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := ToLower(User.Name) + ' ^4(^5a^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := ToLower(User.Name);
                  END;
            'S' : BEGIN { User Name Short }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'Anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := Copy(User.Name,1,2) + ' ^4(^5A^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := Copy(User.Name,1,2);
                  END;
            'U' : BEGIN { User Name Short Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := ToLower(Copy(User.Name,1,2)) + ' ^4(^5a^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := ToLower(Copy(User.Name,1,2));
                  END;
          END;
    END;
END;

PROCEDURE OneLiner_Add;
VAR
  OneLinerList: OneLinerRecordType;
  
  PROCEDURE AskOneLinerQuestions(VAR OneLinerList: OneLinerRecordType);
  BEGIN
    WHILE (NOT Abort) AND (NOT Hangup) DO
      BEGIN
        lRGLngStr(105,FALSE); {"Enter your OneLiner"}
        MPL(55);
        InputMain(OneLinerList.OneLiner,(SizeOf(OneLinerList.OneLiner) - 1),[InterActiveEdit,ColorsAllowed]);
        Abort := (OneLinerList.OneLiner = '');
        IF (Abort) THEN
          EXIT
        ELSE
          IF (AACS(General.AnonPubPost)) AND PYNQ(lRGLngStr(101,TRUE),0,FALSE) THEN {"Post anonymously?"}
            OneLinerList.Anonymous := TRUE;
        EXIT;
      END;
  END;
  
BEGIN
  IF PYNQ(lRGLngStr(106,TRUE),0, FALSE) THEN {"Add a OneLiner?"}
    BEGIN
      FillChar(OneLinerList,SizeOf(OneLinerList),0);
      AskOneLinerQuestions(OneLinerList);
      IF (NOT Abort) THEN
        BEGIN
          PrintF('ONELH');
          IF (NoFile) THEN
            BEGIN
              lRGLngStr(108,FALSE);
              WHILE WhereX < ThisUser.LineLen DO
                Prt(lRGLngStr(11,TRUE));
            END;
          Print(' ^4'+OneLinerList.OneLiner);
          PrintF('ONELT');
          IF (NoFile) THEN
            BEGIN
              WHILE WhereX < ThisUser.LineLen DO
                Prt(lRGLngStr(11,TRUE));
              NL;
            END;
          IF (PYNQ(lRGLngStr(107,TRUE),0,TRUE)) THEN {"Are you sure you want to add this OneLiner?"}
            BEGIN
              Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
              IF (Exist(General.DataPath+'ONELINER.DAT')) THEN
                Reset(OneLinerListFile)
              ELSE
                Rewrite(OneLinerListFile);
              Seek(OneLinerListFile,FileSize(OneLinerListFile));
              OneLinerList.UserID := UserNum;
              OneLinerList.DateAdded := GetPackDateTime;
              OneLinerList.DateEdited := OneLinerList.DateAdded;
              OneLinerList.RecordNum := (FileSize(OneLinerListFile) + 1);
              Write(OneLinerListFile,OneLinerList);
              Close(OneLinerListFile);
              LastError := IOResult;
              SysOpLog('Added OneLiner "'+OneLinerList.OneLiner+'"');
            END;
        END;
    END;
END;

PROCEDURE OneLiner_View;
VAR
  OneLinerList: OneLinerRecordType;
  OnRec: LongInt;
  Counter : Byte;
BEGIN
  Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
  Reset(OneLinerListFile);
  LastError := IOResult;
  IF (LastError = 2) THEN
    ReWrite(OneLinerListFile);
  IF (NOT ReadBuffer('ONELM')) THEN
    BEGIN
      SysOpLog('^8[!]^0 Tried to view OneLiners, but ^1ONELM.EXT^0 was missing!');
      EXIT;
    END;
  AllowContinue := TRUE;
  Abort := FALSE;
  PrintF('ONELH');
  IF (NoFile) THEN
    BEGIN
      lRGLngStr(108,FALSE);
      WHILE WhereX < ThisUser.LineLen DO
        Prt(lRGLngStr(11,TRUE));
      NL;
    END;
  IF (FileSize(OneLinerListFile)=0) THEN
    BEGIN
     lRGLngStr(109,FALSE);
    END
  ELSE
    BEGIN
      OnRec := 1;
      Counter := (FileSize(OneLinerListFile));
      FOR Counter := (FileSize(OneLinerListFile)) DOWNTO 1 DO
        BEGIN
          Seek(OneLinerListFile,(Counter-1));
          Read(OneLinerListFile,OneLinerList);
          DisplayBuffer(OneLinerListMCI,@OneLinerList,NIL);
          Inc(OnRec);
          IF ((OnRec-1) = 10) THEN
            Break
          ELSE
            OnRec := OnRec;
        END;
    END;
  Close(OneLinerListFile);
  LastError := IOResult;
  IF (NOT Abort) THEN
    PrintF('ONELT');
  IF (NoFile) THEN
    BEGIN
      WHILE WhereX < ThisUser.LineLen DO
        Prt(lRGLngStr(11,TRUE));
        NL;
    END;
  AllowContinue := FALSE;
  SysOpLog('Viewed OneLiners');
END;

FUNCTION OneLiner_Random: STRING;
VAR
  OneLinerList: OneLinerRecordType;
  Rand: Byte;
BEGIN
  OneLiner_Random := '';
  IF (NOT ReadBuffer('ONELM')) THEN
    BEGIN
      SysOpLog('^8[!]^0 Tried to view oneliners, but ^1ONELM.EXT^0 was missing!');
      EXIT;
    END;
  Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
  Reset(OneLinerListFile);
  REPEAT
    Rand := Random(10);
  UNTIL (Rand>0) and (Rand<FileSize(OneLinerListFile));
  Seek(OneLinerListFile,(Rand));
  Read(OneLinerListFile,OneLinerList);
  DisplayBuffer(OneLinerListMCI,@OneLinerList,NIL);
  Close(OneLinerListFile);
  LastError := IOResult;
END;

PROCEDURE OneLiners;
BEGIN
OneLiner_View;
OneLiner_Add;
END;

END.
