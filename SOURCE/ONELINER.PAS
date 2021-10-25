{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
Unit OneLiner;

INTERFACE

Uses
    Common,
    Timefunc,
    Mail1;

Type
    OneLinerRecordType = {$IFDEF WIN32} Packed {$ENDIF} Record
       RecordNum  : LongInt;
       OneLiner   : String[55];
       UserID     : LongInt;
       UserName   : String[36];
       DateAdded,
       DateEdited : UnixTime;
       Anonymous  : Boolean;
    End;

PROCEDURE DoOneLiners;
PROCEDURE OneLiner_Add;
PROCEDURE OneLiner_View;
FUNCTION OneLiner_Random : STRING;
FUNCTION ToLower( S : STRING ) : STRING;

IMPLEMENTATION

VAR
            OneLinerListFile : FILE OF OneLinerRecordType;
            OneLineRec  : OneLinerRecordType;

FUNCTION ToLower( S : STRING ) : STRING;
VAR
  i : BYTE;
BEGIN
 FOR i := 1 TO Length(S) DO
  BEGIN
   IF S[i] IN ['A'..'Z'] THEN
   S[i] := Chr(Ord(S[i]) + 32);
  END;
  ToLower := S;
END;

FUNCTION OneLinerListMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  OneLinerListPtr: ^OneLinerRecordType;
  User: UserRecordType;
  TmpStr : String;
BEGIN
  OneLinerListPtr := Data1;
  OneLinerListMCI := S;
  CASE S[1] OF
    'A' : CASE S[2] OF
            'N' : OneLinerListMCI := ShowYesNo(OneLinerListPtr^.Anonymous); { Anon - Yes/No }
            'T' : OneLinerListMCI := AonOff(OneLinerListPtr^.Anonymous, 'True', 'False'); { Anon - True/False }
          END;
    'D' : CASE S[2] OF
            'A' : OneLinerListMCI := Pd2Date(OneLinerListPtr^.DateAdded); { Date Added }
            'E' : OneLinerListMCI := Pd2Date(OneLinerListPtr^.DateEdited); { Date Edited - Not Used }
          END;
    'O' : CASE S[2] OF
            'L' : OneLinerListMCI := OneLinerListPtr^.OneLiner; { The Oneliner }
          END;
    'R' : CASE S[2] OF
            'N' : OneLinerListMCI := IntToStr(OneLinerListPtr^.RecordNum); { Oneliner Record Number }
          END;
    'U' : CASE S[2] OF
            '#' : BEGIN { User ID }
                   IF (OneLinerListPtr^.Anonymous) THEN
                    OneLinerListMCI := '';
                   IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                    OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                   IF (NOT OneLinerListPtr^.Anonymous) THEN
                   OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                  END;
            '1' : BEGIN { User ID Without # }
                   IF (OneLinerListPtr^.Anonymous) THEN
                    OneLinerListMCI := '';
                   IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                    OneLinerListMCI := IntToStr(OneLinerListPtr^.UserID);
                   IF (NOT OneLinerListPtr^.Anonymous) THEN
                   OneLinerListMCI := IntToStr(OneLinerListPtr^.UserID);
                  END;
            'N' : BEGIN { User Name }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := 'Anon';
                    IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                     OneLinerListMCI := Caps(User.Name) + ' ^2(^1A^2)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := Caps(User.Name);
                  END;
            'L' : BEGIN { User Name Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                     OneLinerListMCI := ToLower(User.Name) + ' ^2(^1a^2)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := ToLower(User.Name);
                  END;
            'S' : BEGIN { User Name Short }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := 'Anon';
                    IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                     OneLinerListMCI := Copy(User.Name,1,2) + ' ^2(^1A^2)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := Copy(User.Name,1,2);
                  END;
            'U' : BEGIN { User Name Short Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (SysOp) THEN
                     OneLinerListMCI := ToLower(Copy(User.Name,1,2)) + ' ^2(^1a^2)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                     OneLinerListMCI := ToLower(Copy(User.Name,1,2));
                  END;
          END;
    END;
END;

FUNCTION OneLinerList_Exists: Boolean;
VAR
  OneLinerListFile: FILE OF OneLinerRecordType;
  FSize: Longint;
  FExist: Boolean;
BEGIN
  FSize := 0;
  FExist := Exist(General.DataPath+'ONELINER.DAT');
  IF (FExist) THEN
  BEGIN
    Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
    Reset(OneLinerListFile);
    FSize := FileSize(OneLinerListFile);
    Close(OneLinerListFile);
  END;
  IF (NOT FExist) OR (FSize = 0) THEN
  BEGIN
    NL;
    PrintF('ONELH');
    IF (NoFile) THEN
      BEGIN
        CLS; NL;
        Print(Centre('^2' + General.BBSName + ' One Liners'));
        Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));
      END;
    Print(' ^2There are currently no One Liners.');
    NL;
    PrintF('ONELE');
    IF (NoFile) THEN
       Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));

    SysOpLog('^1* The ONELINER.DAT file is missing.');
  END;
  OneLinerList_Exists := (FExist) AND (FSize <> 0);
END;

PROCEDURE DisplayError(FName: ASTR; VAR FExists: Boolean);
BEGIN
  NL;
  PrintACR('|12?|09The '+FName+'.*  File is missing.');
  PrintACR('|12?|09Please, inform the Sysop!');
  SysOpLog('The '+FName+'.* file is missing.');
  FExists := FALSE;
END;

FUNCTION OneLinerAddScreens_Exists: Boolean;
VAR
  FExistsH,
  FExistsM,
  FExistsE: Boolean;
BEGIN
  FExistsH := TRUE;
  FExistsM := TRUE;
  FExistsE := TRUE;
  (*IF (NOT ReadBuffer('ONELH')) THEN
    DisplayError('ONELH',FExistsH); *)
  IF (NOT ReadBuffer('ONELM')) THEN
    DisplayError('ONELM',FExistsM);
  (*IF (NOT ReadBuffer('ONELE')) THEN
    DisplayError('ONELE',FExistsE); *)
    OneLinerAddScreens_Exists := (*(FExistsH) AND *)(FExistsM) (*AND (FExistsE)*);
END;

Procedure AskOneLinerQuestions(VAR OneLinerList: OneLinerRecordType);
{Var MHeader : MHeaderRec; }
Begin

 WHILE (NOT Abort) AND (NOT Hangup) DO
  Begin
   NL;
   Print('^2 Enter your one liner');
   Prt(' ^1:');
   MPL(76);
   InputMain(OneLinerList.OneLiner,(SizeOf(OneLinerList.OneLiner) - 1),[InterActiveEdit,ColorsAllowed]);
   NL;
   Abort := (OneLinerList.OneLiner = '');
   IF (Abort) THEN
   Exit
   ELSE
     OneLinerList.Anonymous := PYNQ('^2 Post Anonymous? ^1',0,FALSE);
     Exit;
  End;
End;

PROCEDURE OneLiner_Add;
VAR
  Data2: Pointer;
  OneLinerList: OneLinerRecordType;
BEGIN
  IF (OneLinerAddScreens_Exists) THEN
  BEGIN
    NL;
    OneLiner_View;
    IF PYNQ('^2 Add a one liner? ^1',0, FALSE) THEN
    BEGIN
      FillChar(OneLinerList,SizeOf(OneLinerList),0);
      AskOneLinerQuestions(OneLinerList);
      IF (NOT Abort) THEN
      BEGIN
        PrintF('ONELH');
		IF (NoFile) THEN
		  BEGIN
			CLS; NL;
			Print(Centre('^2' + General.BBSName + ' One Liners'));
			Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));
		  END;
        Print(' ^2'+OneLinerList.OneLiner);
        PrintF('ONELE');
        IF (NoFile) THEN
			Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));
        NL;
        IF (PYNQ('^2 Add this oneliner? ^1',0,TRUE)) THEN
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

          SysOpLog('Added Oneliner : '+OneLinerList.OneLiner+'.');
        END;
      END;
    END;
  END;
END;

PROCEDURE OneLiner_View;
VAR
  Data2: Pointer;
  OneLinerList: OneLinerRecordType;
  OnRec: Longint;
  Cnt : Byte;
BEGIN

  IF (OneLinerList_Exists) AND (OneLinerAddScreens_Exists) THEN
  BEGIN
    Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
    Reset(OneLinerListFile);
    ReadBuffer('ONELM');
    AllowContinue := TRUE;
    Abort := FALSE;
    PrintF('ONELH');
    IF (NoFile) THEN
      BEGIN
        CLS; NL;
        Print(Centre('^2' + General.BBSName + ' One Liners'));
        Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));
        NL;
      END;
    OnRec := 1;
    Cnt := (FileSize(OneLinerListFile));
    {WHILE (OnRec <= FileSize(OneLinerListFile)) AND (NOT Abort) AND (NOT HangUp) DO}

   FOR Cnt := (FileSize(OneLinerListFile)) DOWNTO 1 DO
    BEGIN
      Seek(OneLinerListFile,(Cnt-1));
      Read(OneLinerListFile,OneLinerList);
      DisplayBuffer(OneLinerListMCI,@OneLinerList,Data2);
      Inc(OnRec);
      IF ((OnRec-1) = 10) THEN
       Break
      ELSE
       OnRec := OnRec;
    END;
    Close(OneLinerListFile);
    LastError := IOResult;
    IF (NOT Abort) THEN
      PrintF('ONELE');
      IF (NoFile) THEN
        Print(Centre('^1컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'));

    AllowContinue := FALSE;
    SysOpLog('^1* ^2'+ ThisUser.Name + '^1 Viewed the OneLiners.');
  END;
END;

Function OneLiner_Random : String;
Begin

End;

Procedure DoOneLiners; { To-Do : Variable Number of One Liners To Display }
Begin
OneLiner_Add;
End;

End.
