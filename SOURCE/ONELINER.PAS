{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 09/29/2021 - Moved ToLower func to common, likely useful elsewhere
            - Indented, formatting, cleanup
            - oneliner_view now ONLY views, oneliner_add now ONLY adds
            - renamed ONELE to ONELT to keep with standard format
            - most strings added to RGLNG
            - OneLiner_Random prints a random oneliner, but I don't know how to make the func store it
 10/08/2021 - Change SysOp to AACS(General.AnonPubRead) to see anonymous posters names
 10/19/2021 - Added SysOpLog error message if ONELM.EXT is missing
 04/15/2022 - Removed unused code (onrec)
              Added toggle for newest on top/bottom
 05/16/2022 - Fixed reading oneliner data file out of range
            - Changed Counter var type from byte to integer (need negatives)
            - removed unused var Counter2
 03/06/2023 - deleted users have their attribution set as anonymous
 07/08/2023 - Nested view/add into oneliners proc
            - Added OneLiner Editor (MNUCMD 1E)
 01/21/2024 - Reversed order of OneLiners in editor (Newest at top)
            - Added SysOp log entry for editing OneLiner
 ***   01/21/2024  - Bug found that if new oneliner.dat does not have 25 lines, it will display trash in editor.  ***


 [NOTES]
 - Put anonymous and deleted strings in lang
}
UNIT OneLiner;

INTERFACE

USES
    Common,
    Common2, {ToggleWindow}
    CRT,
    TimeFunc,
    Mail1;

PROCEDURE OneLiners; { View/Prompt to add }
PROCEDURE OneLiners_Edit; { Edit/Delete }
FUNCTION OneLiner_Random: STRING; { Display a random OneLiner }

IMPLEMENTATION

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
                    IF (OneLinerListPtr^.Anonymous) OR (OneLinerListPtr^.UserID = 0) THEN
                      OneLinerListMCI := '';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := '#' + IntToStr(OneLinerListPtr^.UserID);
                  END;
            '1' : BEGIN { User ID Without # }
                    IF (OneLinerListPtr^.Anonymous) OR (OneLinerListPtr^.UserID = 0) THEN
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
                      IF (OneLinerListPtr^.UserID = 0) THEN
                        OneLinerListMCI := 'Deleted'
                      ELSE
                        OneLinerListMCI := Caps(User.Name) + ' ^4(^5A^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := Caps(User.Name);
                  END;
            'L' : BEGIN { User Name Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      IF (OneLinerListPtr^.UserID = 0) THEN
                        OneLinerListMCI := 'deleted'
                      ELSE
                      OneLinerListMCI := ToLower(User.Name) + ' ^4(^5a^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := ToLower(User.Name);
                  END;
            'S' : BEGIN { User Name Short }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'Anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      IF (OneLinerListPtr^.UserID = 0) THEN
                        OneLinerListMCI := 'Del'
                      ELSE
                      OneLinerListMCI := Copy(User.Name,1,2) + ' ^4(^5A^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := Copy(User.Name,1,2);
                  END;
            'U' : BEGIN { User Name Short Lower }
                    LoadURec(User,OneLinerListPtr^.UserID);
                    IF (OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := 'anon';
                    IF (OneLinerListPtr^.Anonymous) AND (AACS(General.AnonPubRead)) THEN
                      IF (OneLinerListPtr^.UserID = 0) THEN
                        OneLinerListMCI := 'del'
                      ELSE
                      OneLinerListMCI := ToLower(Copy(User.Name,1,2)) + ' ^4(^5a^4)';
                    IF (NOT OneLinerListPtr^.Anonymous) THEN
                      OneLinerListMCI := ToLower(Copy(User.Name,1,2));
                  END;
          END;
    END;
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
    Rand := Random(10{FileSize(OneLinerListFile)???});
  UNTIL (Rand>0) AND (Rand<FileSize(OneLinerListFile));
  Seek(OneLinerListFile,(Rand));
  Read(OneLinerListFile,OneLinerList);
  DisplayBuffer(OneLinerListMCI,@OneLinerList,NIL);
  Close(OneLinerListFile);
  LastError := IOResult;
END;

PROCEDURE OneLiners;

PROCEDURE OneLiner_View;
VAR
  OneLinerList: OneLinerRecordType;
  Counter: Integer; { Need negatives }
BEGIN
{Counter2 := 1;}
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
      UserColor(5);
      WHILE WhereX < ThisUser.LineLen DO
        Prt(lRGLngStr(11,TRUE)); {"-"}
      NL;
      UserColor(0);
    END;
  IF (FileSize(OneLinerListFile)=0) THEN
    BEGIN
      lRGLngStr(109,FALSE); { No OneLiners }
    END
  ELSE
    BEGIN
      IF General.OneLinersNewTop THEN
        FOR Counter := (FileSize(OneLinerListFile)) DOWNTO (FileSize(OneLinerListFile)-9) DO { LeeW: Newest at top }
          BEGIN
            IF (Counter<1) THEN
              Break;
            Seek(OneLinerListFile,(Counter-1));
            Read(OneLinerListFile,OneLinerList);
            DisplayBuffer(OneLinerListMCI,@OneLinerList,NIL);
          END
      ELSE
        FOR Counter := (FileSize(OneLinerListFile)-9) TO (FileSize(OneLinerListFile)) DO { LeeW: Newest at bottom }
          BEGIN
            IF (Counter<1) THEN
              Continue;
            Seek(OneLinerListFile,(Counter-1));
            Read(OneLinerListFile,OneLinerList);
            DisplayBuffer(OneLinerListMCI,@OneLinerList,NIL);
          END;
    END;
  Close(OneLinerListFile);
  LastError := IOResult;
  IF (NOT Abort) THEN
    PrintF('ONELT');
  IF (NoFile) THEN
    BEGIN
      UserColor(5);
      WHILE WhereX < ThisUser.LineLen DO
        Prompt(lRGLngStr(11,TRUE)); {"-"}
      NL;
      UserColor(0);
    END;
  AllowContinue := FALSE;
  SysOpLog('Read OneLiners');
END;

PROCEDURE OneLiner_Add;
VAR
  OneLinerList: OneLinerRecordType;

  PROCEDURE AskOneLinerQuestions(VAR OneLinerList: OneLinerRecordType);
  BEGIN
    WHILE (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        lRGLngStr(105,FALSE); {"Enter your OneLiner"}
        InputMain(OneLinerList.OneLiner,(SizeOf(OneLinerList.OneLiner) - 1),[InterActiveEdit,NoInputField]);
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
              lRGLngStr(108,FALSE); {"OneLiners"}
              WHILE WhereX < ThisUser.LineLen DO
                Prt(lRGLngStr(11,TRUE)); {"-"}
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
                ReWrite(OneLinerListFile);
              Seek(OneLinerListFile,FileSize(OneLinerListFile));
              OneLinerList.UserID := UserNum;
              OneLinerList.DateAdded := GetPackDateTime;
              OneLinerList.DateEdited := OneLinerList.DateAdded;
              OneLinerList.RecordNum := (FileSize(OneLinerListFile) + 1);
              Write(OneLinerListFile,OneLinerList);
              Close(OneLinerListFile);
              LastError := IOResult;
              SysOpLog('Wrote OneLiner "'+OneLinerList.OneLiner+'"');
            END;
        END;
    END;
END;

BEGIN { OneLiners }
  OneLiner_View;
  IF AACS(General.AddOneLinerACS) THEN
    OneLiner_Add
  ELSE
    PauseScr(FALSE);
END;

{/}

PROCEDURE OneLiners_Edit;
VAR
  Line: ARRAY[0..100] OF STRING[79]; { The OneLiners }
  Counter,
  RecNum, { Record number we're on (0 - FileSize(OneLinerListFile)-1) }
  LineNum: Integer; { Line number we're on (0 - 20) }
  W: Word; { Input }
  UserTmp: UserRecordType; { Author information }
  StrTmp: STRING[55]; { Original OneLiner for SysOp log }
  
PROCEDURE UpdateArray;
VAR
  Counter: Integer;
BEGIN
  { Reset array }
  FOR Counter := 0 TO 100 DO 
    Line[Counter] := '';
  { Repopulate array from data file }
  FOR Counter := 0 TO FileSize(OneLinerListFile)-1 DO
    BEGIN
      Seek(OneLinerListFile,(Counter));
      Read(OneLinerListFile,OneLineRec);
      LoadURec(UserTmp,OneLineRec.UserID);
      Line[Counter] := PadLeftStr('['+IntToStr(Counter)+'] "'+OneLineRec.OneLiner+'"',61)+PadLeftStr(' - '+UserTmp.Name,18);
    END;
END;

PROCEDURE DrawUI;
BEGIN
  CLS;
  ANSIG(1,1);
  Print('^5 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ^4One-Liner Editor ^5ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[^4'#30'^5]Ä');
  ANSIG(1,23);
  Print('^5 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[^4'#31'^5]Ä');
  Print(Centre('^0<^1'#30#31'^0>Scroll (^1E^0)dit <^1DEL^0>Delete <^1ESC^0/^1Q^0)uit'));
END;

PROCEDURE DrawList;
VAR
  Counter: Integer;
BEGIN
  ANSIG(1,2);
  FOR Counter := FileSize(OneLinerListFile)-1 DOWNTO FileSize(OneLinerListFile)-21 DO
    IF Line[Counter] <> '' THEN
      BEGIN
        IF RecNum = Counter THEN
          Prt('^1')
        ELSE
          Prt('^0');
        Print(PadLeftStr(Line[Counter],79));
      END;
END;

BEGIN { OneLiners_Edit }
  Assign(OneLinerListFile,General.DataPath+'ONELINER.DAT');
  Reset(OneLinerListFile);

  { Check if there's any OneLiners to edit }
  IF (FileSize(OneLinerListFile)=0) THEN
    BEGIN
      lRGLngStr(109,FALSE); { "No OneLiners" }
      PauseScr(FALSE);
      EXIT;
    END;
  
  TempPause := FALSE;
  ToggleWindow(FALSE);
  
  RecNum := FileSize(OneLinerListFile)-1;
  LineNum := 0;

  UpdateArray;
  DrawUI;
  DrawList;
        
  REPEAT
    Cursor(FALSE);
    W := GetKey; { Input }
    IF (W = F_DOWN) AND (RecNum > 0) THEN
      BEGIN
        Dec(RecNum);
        IF (LineNum < 20) THEN
          BEGIN
            Inc(LineNum);
            { No page shift }
            ANSIG(1,LineNum+1);
            Print('^0'+Line[RecNum+1]);
            ANSIG(1,LineNum+2);
            Print('^1'+Line[RecNum]);
          END
        ELSE
          BEGIN { Page shift }
            ANSIG(1,2);
            FOR Counter := RecNum+20 DOWNTO RecNum DO
              BEGIN
                IF RecNum = Counter THEN
                  Prt('^1')
                ELSE
                  Prt('^0');
                Print(PadLeftStr(Line[Counter],79));
              END;
          END;
      END;
    
    IF (W = F_UP) AND (RecNum < FileSize(OneLinerListFile)-1) THEN
      BEGIN
        Inc(RecNum);
        IF (LineNum > 0) THEN
          BEGIN
            Dec(LineNum);
            { No page shift }
            ANSIG(1,LineNum+3);
            Print('^0'+Line[RecNum-1]);
            ANSIG(1,LineNum+2);
            Print('^1'+Line[RecNum]);
          END
        ELSE
          BEGIN { Page shift }
            ANSIG(1,2); { First entry }
            FOR Counter := RecNum DOWNTO RecNum-20 DO
              BEGIN
                IF RecNum = Counter THEN
                  Prt('^1')
                ELSE
                  Prt('^0');
                Print(PadLeftStr(Line[Counter],79));
              END;
          END;
      END;
      
    IF (W = 101{e}) OR (W = 69{E}) THEN
      BEGIN { Edit the OneLiner }
        Cursor(TRUE);
        Seek(OneLinerListFile,RecNum);
        Read(OneLinerListFile,OneLineRec);
        ANSIG(1,24);
        Clear_EOL;
        StrTmp := OneLineRec.OneLiner; { Original OneLiner for SysOp log }
        InputString('',OneLineRec.OneLiner,(SizeOf(OneLineRec.OneLiner) - 1),[InterActiveEdit,NoInputField],Changed);
        IF (Changed) THEN
          BEGIN
            Seek(OneLinerListFile,RecNum);
            Write(OneLinerListFile,OneLineRec);
            LastError := IOResult;
            {}
            LoadURec(UserTmp,OneLineRec.UserID); { Get user data }
            SysOpLog('* Edited OneLiner "'+StrTmp+'" by '+UserTmp.Name+' to "'+OneLineRec.OneLiner+'"');
            {}
            StrTmp := ''; { Clear }
            UpdateArray;
          END;
        { Reset }
        RecNum := FileSize(OneLinerListFile)-1;
        LineNum := 0;
        {}
        DrawUI;
        DrawList;
      END;
      
    IF (W = F_DEL) THEN
      BEGIN { Delete the OneLiner }
        ANSIG(1,24);
        Clear_EOL;
        IF PYNQ('Are you sure you want to delete it?',0,FALSE) THEN
          BEGIN
            Reset(OneLinerListFile);
            IF (RecNum >= 0) AND (RecNum <= (FileSize(OneLinerListFile) - 2)) THEN
              FOR Counter := RecNum TO (FileSize(OneLinerListFile) - 2) DO
                BEGIN
                  Seek(OneLinerListFile,(Counter + 1));
                  Read(OneLinerListFile,OneLineRec);
                  Seek(OneLinerListFile,Counter);
                  Write(OneLinerListFile,OneLineRec);
                END;
            Seek(OneLinerListFile,(FileSize(OneLinerListFile) - 1));
            Truncate(OneLinerListFile);
            LastError := IOResult;
            {}
            LoadURec(UserTmp,OneLineRec.UserID); { Get user data }
            SysOpLog('* Deleted OneLiner "'+OneLineRec.OneLiner+'" by '+UserTmp.Name);
            {}
            UpdateArray;
          END;
        { Reset }
        RecNum := FileSize(OneLinerListFile)-1;
        LineNum := 0;
        {}
        DrawUI;
        DrawList;         
      END;
  UNTIL (W=27{ESC}) OR (W=113{q}) OR (W=81{Q}) OR (HangUp);
  Close(OneLinerListFile);
  TempPause := TRUE;
  ToggleWindow(TRUE);
  Cursor(TRUE);
END;

END.
