{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 00/00/2021 - SearchUser changed username string from astr to string[36] 
 11/18/2021 - Moved finduser to logon.pas only place its used, doesn't seem like it'll be useful anywhere else
            - lfinduserws added search string before
}
UNIT MiscUser;

INTERFACE

USES
  Common;

PROCEDURE lFindUserWS(VAR UserNum: Integer); { Search for user by Handle, Real Name, or Number }
PROCEDURE ChangeARFlags(MenuOption: Str50);
PROCEDURE ChangeACFlags(MenuOption: Str50);
PROCEDURE InsertIndex(UName: AStr; UserNum: Integer; IsReal, IsDeleted: Boolean);

IMPLEMENTATION

USES
  DOS;

PROCEDURE lFindUserWS(VAR UserNum: Integer); { Quit = -1 | Not Found = 0 }
VAR
  User: UserRecordType;
  UserIDX: UserIDXRec;
  UserName: STRING[36];
  Cmd: Char;
  Counter,
  NumIDX: Integer;
  Done,
  Asked: Boolean;
BEGIN
  lRGLngStr(229,FALSE); { Search for user prompt }
  InputMain(UserName,SizeOf(UserName)-1,[CapAll]);
  IF (UserName = 'SYSOP') THEN
    UserName := '1';
  UserNum := StrToInt(UserName);
  IF (UserNum > 0) THEN
    BEGIN
      IF (UserNum > (MaxUsers - 1)) THEN
        BEGIN
          NL;
          lRGLngStr(239,FALSE); {"User not found"}
          UserNum := 0
        END
      ELSE
        LoadURec(User,UserNum);
    END
  ELSE IF (UserName = '') THEN
    BEGIN
      NL;
      lRGLngStr(154,FALSE); {"Aborted!"}
    END
  ELSE
    BEGIN
      Done := FALSE;
      Asked := FALSE;
      UserNum := SearchUser(UserName,CoSysOp);
      IF (UserNum > 0) THEN
        Exit;
      Reset(UserIDXFile);
      Counter := 0;
      NumIDX := FileSize(UserIDXFile);
      WHILE (Counter < NumIDX) AND (NOT Done) DO
        BEGIN
          Read(UserIDXFile,UserIDX);
          Inc(Counter);
          IF NOT (UserIDX.Deleted) AND (Pos(UserName,UserIDX.Name) <> 0) AND 
             ((NOT UserIDX.RealName) OR (CoSysOp)) THEN
            IF ((UserIDX.Name = UserName) OR (CoSysOp AND (UserIDX.Name = UserName))) AND 
               (UserIDX.number <= (MaxUsers - 1)) THEN
              UserNum := UserIDX.Number
            ELSE
              BEGIN
                IF (NOT Asked) THEN
                  BEGIN
                    NL;
                    Asked := TRUE;
                  END;
                LangStringArray[0] := Caps(UserIDX.Name);
                InputChar(lRGLngStr(240,TRUE),Cmd,'QYN'^M,[CapAll]); {"Did you mean USERNAME?"}
                Done := TRUE;
                CASE Cmd OF
                  'Q' : UserNum := -1;
                  'Y' : UserNum := UserIDX.Number;
                  ELSE
                    Done := FALSE;
                END;
              END;
        END;
      Close(UserIDXFile);
      IF (UserNum = 0) THEN
        BEGIN
          NL;
          lRGLngStr(239,FALSE); {"User not found"}
        END;
      IF (UserNum = -1) THEN
        UserNum := 0;
    END;
  LastError := IOResult;
END;

PROCEDURE ChangeARFlags(MenuOption: Str50);
VAR
  Counter: Byte;
  Changed: Boolean;
BEGIN
  MenuOption := AllCaps(MenuOption);
  FOR Counter := 1 TO (Length(MenuOption) - 1) DO
    CASE MenuOption[Counter] OF
      '+' : IF (MenuOption[Counter + 1] IN ['A'..'Z']) THEN
              Include(ThisUser.ARFlags,MenuOption[Counter + 1]);
      '-' : IF (MenuOption[Counter + 1] IN ['A'..'Z']) THEN
              Exclude(ThisUser.ARFlags,MenuOption[Counter + 1]);
      '!' : IF (MenuOption[Counter + 1] IN ['A'..'Z']) THEN
              ToggleARFlag((MenuOption[Counter + 1]),ThisUser.ARFlags,Changed);
    END;
  NewCompTables;
  Update_Screen;
END;

PROCEDURE ChangeACFlags(MenuOption: Str50);
VAR
  Counter: Byte;
  Changed: Boolean;
BEGIN
  MenuOption := AllCaps(MenuOption);
  FOR Counter := 1 TO (Length(MenuOption) - 1) DO
    CASE MenuOption[Counter] OF
      '+' : Include(ThisUser.ACFlags,TACCH(MenuOption[Counter + 1]));
      '-' : Exclude(ThisUser.ACFlags,TACCH(MenuOption[Counter + 1]));
      '!' : ToggleACFlags(MenuOption[Counter + 1],ThisUser.ACFlags,Changed);
    END;
  NewCompTables;
  Update_Screen;
END;

PROCEDURE InsertIndex(UName: AStr; UserNum: Integer; IsReal,IsDeleted: Boolean);
VAR
  UserIDX: UserIDXRec;
  Current,
  InsertAt: Integer;
  SFO,
  Done: Boolean;

  PROCEDURE WriteIndex;
  BEGIN
    WITH UserIDX DO
      BEGIN
        FillChar(UserIDX,SizeOf(UserIDX),0);
        Name := UName;
        Number := UserNum;
        RealName := IsReal;
        Deleted := IsDeleted;
        Left := -1;
        Right := -1;
        Write(UserIDXFile,UserIDX);
      END
  END;

BEGIN
  Done := FALSE;
  UName := AllCaps(UName);
  Current := 0;
  SFO := (FileRec(UserIDXFile).Mode <> FMClosed);
  IF (NOT SFO) THEN
    Reset(UserIDXFile);
  IF (FileSize(UserIDXFile) = 0) THEN
    WriteIndex
  ELSE
    REPEAT
      Seek(UserIDXFile,Current);
      InsertAt := Current;
      Read(UserIDXFile,UserIDX);
      IF (Uname < UserIDX.Name) THEN
        Current := UserIDX.Left
      ELSE IF (Uname > UserIDX.Name) THEN
        Current := UserIDX.Right
      ELSE IF (UserIDX.Deleted <> IsDeleted) THEN
        BEGIN
          Done := TRUE;
          UserIDX.Deleted := IsDeleted;
          UserIDX.RealName := IsReal;
          UserIDX.Number := UserNum;
          Seek(UserIDXFile,Current);
          Write(UserIDXFile,UserIDX);
        END
      ELSE
        BEGIN
          IF (UserNum <> UserIDX.Number) THEN
            SysOpLog('Note: Duplicate user '+UName+' #'+IntToStr(UserIDX.Number)+' and '+UName+' #'+IntToStr(UserNum))
          ELSE
            BEGIN
              UserIDX.RealName := FALSE;
              Seek(UserIDXFile,Current); { Make it be his handle if it's BOTH }
              Write(UserIDXFile,UserIDX);
            END;
          Done := TRUE;
        END;
    UNTIL (Current = -1) OR (Done);
    IF (Current = -1) THEN
      BEGIN
        IF (Uname < UserIDX.Name) THEN
          UserIDX.Left := FileSize(UserIDXFile)
        ELSE
          UserIDX.Right := FileSize(UserIDXFile);
        Seek(UserIDXFile,InsertAt);
        Write(UserIDXFile,UserIDX);
        Seek(UserIDXFile,FileSize(UserIDXFile));
        WriteIndex;
      END;
    IF (NOT SFO) THEN
      Close(UserIDXFile);
  LastError := IOResult;
END;

END.
