{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-,X-}
{
 10/21/2021 - Updated color codes
 11/04/2021 - Remove redundant procs ...
            - Removed InputWC, now using InputMain with [ColorAllowed] param
            - Removed InputCaps
            - Removed InputL, now using InputMain with no param
 11/05/2021 - Removed Input, now using InputMain with [CapAll] param
            - Removed Local_OneK (was unused)
            - Moved Local_Input1 to COMMON2 (nested in lStatus_screen)
            - Converted all OneK to LOneK, same proc except prompt string
            - Converted all GetPassword calls to InputMain with [IsPassword] param
 11/18/2021 - Increased all numeric string lengths by 1 to account for possible negatives needing extra char for "-"
            - InputMain increases MaxLen by 1 if AllowNegative
            - InputMain prints MPL unless NoInputField specified (Can remove MPL from everywhere, some places will need added)
            - If InteractiveEdit specified, and no ANSI, now prints current val like DisplayValue flag used to
 11/20/2021 - Removed all WOC input procs and converted all calls (UGH!)
            - InputMain - ESC now aborts
 11/21/2021 - Removed InputDefault, now using InputString
            - Removed all redundant MPL calls (UGH!)
 11/22/2021 - OneK1 is now InputChar, now uses InputFlags -- supports CapAll,NoInputField,NoLineFeed, ...
            - Removed DisplayKey param from InputChar (was unused)
            - Replaced all calls to LOneK to InputChar (UGH!)
 04/26/2022 - Cleaning up InputPath
 04/22/2023 - Creating NewInput ...

[TODO]
 - add inputvalidation for inputformatted, maybe have it pass '' if incomplete? --PARAMS for AllowIncomplete
 - inputflags : add different types like dir, filename etc, notabortable, askblank
 - SHOULD BLANK PROMPT BE IN MAIN OR PRINTSTRING--main
[NOTES]
 - AFTER MPL MUST RESET COLOR TO 0 USERCOLOR(0);
}

{ Byte = 0 .. 255 | Integer = -32768 .. 32767 | LongInt = -2147483648 .. 2147483647 | Word = 0 .. 65535 }

UNIT Common3; { INPUT PROCS }

INTERFACE

USES
  Common;

PROCEDURE MPL(MaxLen: Byte); { Print input field }
{/}
PROCEDURE InputByte(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
PROCEDURE InputChar(S: AStr; VAR C: Char; ValidKeys: AStr; InputFlags: InputFlagSet);
PROCEDURE InputInteger(S: AStr; VAR I: Integer; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
PROCEDURE InputLongInt(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
PROCEDURE InputString(S: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
PROCEDURE InputWord(S: AStr; VAR W: Word; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
{...}
PROCEDURE InputFormatted(S: AStr; VAR InputStr: STRING; Format: STRING; Abortable: Boolean);
PROCEDURE InputPath(S: AStr; VAR DirPath: Str40; CreateDir,AllowExit: Boolean; VAR Changed: Boolean);
{/}
PROCEDURE InputMain(VAR S: STRING; MaxLen: Byte; InputFlags: InputFlagSet); { MAIN INPUT PROCEDURE }
PROCEDURE NewInput(VAR InputStr: AStr; InputLen, FieldLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);

IMPLEMENTATION

USES
  CRT,
  DOS;

PROCEDURE InputPath(S: AStr; VAR DirPath: Str40; CreateDir,AllowExit: Boolean; VAR Changed: Boolean);
{notes
mkdir cant make subdirs

call common.makedir???
}
VAR
  TempDirPath: Str40;
  CurDir: PathStr;
  Counter: Byte;
BEGIN
  REPEAT
    TempDirPath := DirPath;
    Changed := FALSE;
    InputString(S,TempDirPath,39,[CapAll,InteractiveEdit],Changed);
    TempDirPath := SQOutSp(TempDirPath);

    IF (Length(TempDirPath) = 1) THEN
      TempDirPath := TempDirPath + ':\'
    ELSE IF (Length(TempDirPath) = 2) AND (TempDirPath[2] = ':') THEN
      TempDirPath := TempDirPath + '\';

    IF (AllowExit) AND (TempDirPath = '') THEN
      Print('%LFAborted!')
    ELSE IF (TempDirPath = '') THEN
      Print('%LF^8A valid path must be specified!^0')
    ELSE IF (NOT (TempDirPath[1] IN ['A'..'Z'])) OR (Length(TempDirPath) < 3) OR
            (NOT (TempDirPath[2] = ':')) OR (NOT (TempDirPath[3] = '\')) THEN
      BEGIN
        NL;
        Print('^8Invalid drive specification: "'+Copy(TempDirPath,1,3)+'"^0');
        TempDirPath := '';
      END
    ELSE { no unexpected input, continue }
      BEGIN
        GetDir(0,CurDir); { store current dir in curdir }
        ChDir(TempDirPath[1]+':'); { try changing to input drive }
        IF (IOResult <> 0) THEN
          BEGIN
            NL;
            Print('^8Drive does not exist: "'+Copy(TempDirPath,1,3)+'"^0');
            TempDirPath := '';
          END
        ELSE { no error on drive change }
          BEGIN
            ChDir(CurDir);
            TempDirPath := BSlash(TempDirPath,TRUE);
            IF (CreateDir) AND (Length(TempDirPath) > 3) AND (NOT ExistDir(TempDirPath)) AND
               PYNQ('%LFDirectory does not exist, create it? ',0,FALSE) THEN
                    FOR Counter := 2 to Length(TempDirPath) DO
                      IF (TempDirPath[Counter] = '\') THEN
                        IF (TempDirPath[Counter - 1] <> ':') THEN
                          IF (NOT ExistDir(Copy(TempDirPath,1,(Counter - 1)))) THEN
                            BEGIN
                              MkDir(Copy(TempDirPath,1,(Counter - 1)));
                              LastError := IOResult;
                              IF (LastError <> 0) THEN
                                BEGIN
                                  NL;
                                  Print('Error creating directory: '+Copy(TempDirPath,1,(Counter - 1)));
                                  SysOpLog('^8Error creating directory: '+Copy(TempDirPath,1,(Counter - 1)));
                                  TempDirPath := '';
                                END;
                            END;
          END;
      END;
  UNTIL (TempDirPath <> '') OR (AllowExit) OR (HangUp);

  {IF (TempDirPath <> '') THEN
    TempDirPath := BSlash(TempDirPath,TRUE);}
  IF (TempDirPath <> DirPath) THEN
    Changed := TRUE;
  DirPath := TempDirPath;
END;

{-}

PROCEDURE MPL(MaxLen: Byte);
VAR
  Counter,
  SaveWhereX : Byte;
BEGIN
  IF (OkANSI) THEN
    BEGIN
      IF (WhereX+MaxLen > ThisUser.LineLen) THEN
        NL;
      UserColor(3);
      SaveWhereX := WhereX;
      IF (OutCom) THEN
        BEGIN
          FOR Counter := 1 TO MaxLen DO
            Com_Send(' ');
          SerialOut(#27+'['+IntToStr(MaxLen)+'D');
        END;
      IF (WantOut) THEN
        BEGIN
          FOR Counter := 1 TO MaxLen DO
            Write(' ');
          GoToXY(SaveWhereX,WhereY);
        END;
    END;
END;

PROCEDURE InputChar(S: AStr; VAR C: Char; ValidKeys: AStr; InputFlags: InputFlagSet);
BEGIN
  Prt('^2'+S);
  IF NOT (NoInputField IN InputFlags) THEN
    MPL(1);
  TempPause := (Pause IN ThisUser.ACFlags);
  REPEAT
    IF (CapAll IN InputFlags) THEN
      C := UpCase(Char(GetKey))
    ELSE
      C := Char(GetKey);
    IF (C = 'q') THEN
      C := UpCase(C);
  UNTIL (Pos(C,ValidKeys) > 0) OR (HangUp);
  IF (HangUp) THEN
    C := ValidKeys[1];
  OutKey(C);
  IF (Trapping) THEN
    OutTrap(C);
  UserColor(0);
  IF NOT (NoLineFeed IN InputFlags) THEN
    NL;
END;

PROCEDURE InputFormatted(S: AStr; VAR InputStr: STRING; Format: STRING; Abortable: Boolean);
VAR
  c: Char;
  i,
  FarBack: Byte;

  PROCEDURE UpdateString;
  BEGIN
    WHILE (NOT (Format[i] IN ['#','@']) AND (i <= Length(Format))) DO
      BEGIN
        OutKey(Format[i]);
        InputStr := InputStr + Format[i];
        Inc(i);
      END;
  END;

BEGIN
  InputStr := '';
  Prt('^2'+S);
  MPL(Length(Format));
  i := 1;
  UpdateString;
  FarBack := i;
  REPEAT
    c := Char(GetKey);
    IF (i <= Length(Format)) THEN
      IF ((Format[i] = '@') AND (c IN ['a'..'z','A'..'Z'])) OR ((Format[i] = '#') AND (c IN ['0'..'9'])) THEN
        BEGIN
          c := UpCase(c);
          OutKey(c);
          InputStr := InputStr + c;
          Inc(i);
          UpdateString;
        END;
    IF (c = ^H) THEN
      BEGIN
        WHILE ((i > FarBack) AND NOT (Format[i - 1] IN ['#','@'])) DO
          BEGIN
            BackSpace;
            Dec(InputStr[0]);
            Dec(i);
          END;
        IF (i > FarBack) THEN
          BEGIN
            BackSpace;
            Dec(InputStr[0]);
            Dec(i);
          END;
      END;
  UNTIL (HangUp) OR ((i > Length(Format)) OR (Abortable)) AND (c = #13);
  UserColor(0);
  NL;
END;

PROCEDURE InputLongInt(S: AStr; VAR L: LongInt; InputFlags: InputFlagSet; LowNum,HighNum: LongInt; VAR Changed: Boolean);
VAR
  TempStr: STRING[11];
  SaveL: LongInt;
  TempL: Real;
BEGIN
  Changed := FALSE; { LeeW: Added }
  SaveL := L;
  {/}
  IF NOT (NoInputRange IN InputFlags) THEN
    S := '^2'+S+' ^2(^1'+IntToStr(LowNum)+'^2-^1'+IntToStr(HighNum)+'^2)' { Show valid input range }
  ELSE
    S := '^2'+S;
  IF (InteractiveEdit IN InputFlags) AND NOT (OkANSI) THEN
    S := S+'^2 [^1'+IntToStr(L)+'^2]: ' { Show current value }
  ELSE
    S := S+'^2: ';
  Prt(S);
  {/}
  TempStr := IntToStr(L);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempL := ValueR(TempStr);
    IF ((Trunc(TempL) >= LowNum) AND (Trunc(TempL) <= HighNum)) THEN
      L := Trunc(TempL)
    ELSE
    BEGIN
      NL;
      Print('^8The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^0');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveL <> L) THEN
    Changed := TRUE;
END;

PROCEDURE InputWord(S: AStr; VAR W: Word; InputFlags: InputFlagSet; LowNum,HighNum: Word; VAR Changed: Boolean);
VAR
  TempStr: STRING[6];
  SaveW: Word;
  TempW: LongInt;
BEGIN
  Changed := FALSE; { LeeW: Added }
  SaveW := W;
  {/}
  IF NOT (NoInputRange IN InputFlags) THEN
    S := '^2'+S+' ^2(^1'+IntToStr(LowNum)+'^2-^1'+IntToStr(HighNum)+'^2)' { Show valid input range }
  ELSE
    S := '^2'+S;
  IF (InteractiveEdit IN InputFlags) AND NOT (OkANSI) THEN
    S := S+'^2 [^1'+IntToStr(W)+'^2]: ' { Show current value }
  ELSE
    S := S+'^2: ';
  Prt(S);
  {/}
  TempStr := IntToStr(W);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempW := StrToInt(TempStr);
    IF ((TempW >= LowNum) AND (TempW <= HighNum)) THEN
      W := TempW
    ELSE
    BEGIN
      NL;
      Print('^8The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^0');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveW <> W) THEN
    Changed := TRUE;
END;

PROCEDURE InputInteger(S: AStr; VAR I: Integer; InputFlags: InputFlagSet; LowNum,HighNum: Integer; VAR Changed: Boolean);
VAR
  TempStr: STRING[6];
  SaveI: Integer;
  TempI: LongInt;
BEGIN
  Changed := FALSE; { LeeW: Added }
  SaveI := I;
  {/}
  IF NOT (NoInputRange IN InputFlags) THEN
    S := '^2'+S+' ^2(^1'+IntToStr(LowNum)+'^2-^1'+IntToStr(HighNum)+'^2)' { Show valid input range }
  ELSE
    S := '^2'+S;
  IF (InteractiveEdit IN InputFlags) AND NOT (OkANSI) THEN
    S := S+'^2 [^1'+IntToStr(I)+'^2]: ' { Show current value }
  ELSE
    S := S+'^2: ';
  Prt(S);
  {/}
  TempStr := IntToStr(I);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
    BEGIN
      TempI := StrToInt(TempStr);
      IF ((TempI >= LowNum) AND (TempI <= HighNum)) THEN
        I := TempI
      ELSE
        BEGIN
          NL;
          Print('^8The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^0');
          PauseScr(FALSE);
        END;
    END;
  IF (SaveI <> I) THEN
    Changed := TRUE;
END;

PROCEDURE InputByte(S: AStr; VAR B: Byte; InputFlags: InputFlagSet; LowNum,HighNum: Byte; VAR Changed: Boolean);
VAR
  TempStr: STRING[4];
  SaveB: Byte;
  TempB: Integer;
BEGIN
  Changed := FALSE; { LeeW: Added }
  SaveB := B;
  {/}
  IF NOT (NoInputRange IN InputFlags) THEN
    S := '^2'+S+' ^2(^1'+IntToStr(LowNum)+'^2-^1'+IntToStr(HighNum)+'^2)' { Show valid input range }
  ELSE
    S := '^2'+S;
  IF (InteractiveEdit IN InputFlags) AND NOT (OkANSI) THEN
    S := S+'^2 [^1'+IntToStr(B)+'^2]: ' { Show current value }
  ELSE
    S := S+'^2: ';
  Prt(S);
  {/}
  TempStr := IntToStr(B);
  InputMain(TempStr,Length(IntToStr(HighNum)),InputFlags);
  IF (TempStr <> '') THEN
  BEGIN
    TempB := StrToInt(TempStr);
    IF ((TempB >= LowNum) AND (TempB <= HighNum)) THEN
      B := TempB
    ELSE
    BEGIN
      NL;
      Print('^8The range must be from '+IntToStr(LowNum)+' to '+IntToStr(HighNum)+'!^0');
      PauseScr(FALSE);
    END;
  END;
  IF (SaveB <> B) THEN
    Changed := TRUE;
END;

PROCEDURE InputString(S: AStr; VAR InputStr: AStr; MaxLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
VAR
  SaveInputStr: AStr;
BEGIN
  Changed := FALSE;
  Prt(S);
  SaveInputStr := InputStr;
  InputMain(SaveInputStr,MaxLen,InputFlags);

  IF (SaveInputStr = '') OR (Length(SQOutSp(SaveInputStr)) = 0) THEN
    IF NOT (NoBlankPrompt IN InputFlags) AND PYNQ('Blank String?',0,FALSE) THEN
      SaveInputStr := ''
    ELSE
      IF (SaveInputStr = '') THEN
        SaveInputStr := InputStr;

  IF (SaveInputStr <> InputStr) THEN
    Changed := TRUE;
  InputStr := SaveInputStr;
END;

PROCEDURE InputMain(VAR S: STRING; MaxLen: Byte; InputFlags: InputFlagSet);
VAR
  SaveS: STRING;
  Is: STRING[2];
  Cp,
  Cl,
  Counter: Byte;
  c,
  C1: Word;
  InsertMode,
  FirstKey: Boolean;

  PROCEDURE MPrompt(S: STRING);
  BEGIN
    SerialOut(S);
    IF (WantOut) THEN
      Write(S);
  END;

  PROCEDURE Cursor_Left;
  BEGIN
    IF (NOT OkAvatar) THEN
      SerialOut(#27'[D')
    ELSE
      SerialOut(^V^E);
    IF (WantOut) THEN
      GotoXY((WhereX - 1),WhereY);
  END;

  PROCEDURE Cursor_Right;
  BEGIN
    OutKey(S[Cp]);
    Inc(Cp);
  END;

  PROCEDURE SetCursor(InsertMode: Boolean); ASSEMBLER;
  ASM
    cmp InsertMode,0
    je @turnon
    mov ch,0
    mov Cl,7
    jmp @goforit
    @turnon:
    mov ch,6
    mov Cl,7
    @goforit:
    mov ah,1
    int 10h
  END;

BEGIN
  IF (AllowNegative IN InputFlags) THEN
    Inc(MaxLen); {For the "-"}
  IF (NOT (NoInputField IN InputFlags)) AND (OkANSI) THEN
    MPL(MaxLen);
  IF (IsPassword IN InputFlags) THEN
    Echo := FALSE;

  FirstKey := FALSE;
  IF (NOT (InterActiveEdit IN InputFlags)) OR (IsPassword IN InputFlags) OR NOT (OkANSI OR OkAvatar) THEN
    BEGIN
      S := '';
      Cp := 1;
      Cl := 0;
    END
  ELSE
    BEGIN
      Cp := Length(S);
      Cl := Length(S);
      IF (Cp = 0) THEN
        Cp := 1;
      MPrompt(S);
      IF (Length(S) > 0) THEN
        BEGIN
          Cursor_Left;
          IF (Cp <= MaxLen) THEN  (* Was Cp < MaxLen *)
            Cursor_Right;
        END;
      FirstKey := TRUE;
    END;

  SaveS := S;
  InsertMode := FALSE;

  REPEAT
    MLC := S;
    SetCursor(InsertMode);
    c := GetKey;

    IF (FirstKey) AND (C = 32) THEN { SPACE - Clears field }
      C := 24;

    IF (C = 27) AND (AllowEscape IN InputFlags) THEN { ESC - Aborts }
      BEGIN
        S := SaveS;
        IF (IsPassword IN InputFlags) THEN
          Echo := TRUE;
        UserColor(0);
        IF (NOT (NoLineFeed IN InputFlags)) THEN
          NL;
        MLC := '';
        SetCursor(FALSE);
        EXIT;
      END;

    FirstKey := FALSE;

    CASE c OF
      8 : IF (Cp > 1) THEN
            BEGIN
              Dec(Cl);
              Dec(Cp);
              Delete(S,Cp,1);
              BackSpace;
              IF (Cp < Cl) THEN
                BEGIN
                  MPrompt(Copy(S,Cp,255)+' ');
                  FOR Counter := Cp TO (Cl + 1) DO
                    Cursor_Left;
                END;
            END;
     24 : BEGIN
            FOR Counter := Cp TO Cl DO
              OutKey(' ');
            FOR Counter := 1 TO Cl DO
              BackSpace;
            Cl := 0;
            Cp := 1;
          END;
     32..255:
          BEGIN
            IF (NOT (NumbersOnly IN InputFlags)) THEN
              BEGIN
                IF (CapAll IN InputFlags) OR (IsPassword IN InputFlags) THEN
                  c := Ord(UpCase(Char(c)));
                IF (CapWords IN InputFlags) THEN
                  IF (Cp > 1) THEN
                    BEGIN
                      IF (S[Cp - 1] IN [#32..#64]) THEN
                        c := Ord(UpCase(Char(c)))
                      ELSE IF (c IN [Ord('A')..Ord('Z')]) THEN
                        Inc(c,32);
                    END
                  ELSE
                    c := Ord(UpCase(Char(c)));
              END;
            IF (NOT (NumbersOnly IN InputFlags)) OR (c IN [45,48..57]) THEN
              BEGIN
                IF ((InsertMode) AND (Cl < MaxLen)) OR ((NOT InsertMode) AND (Cp <= MaxLen)) THEN
                  BEGIN
                    OutKey(Char(c));
                    IF (InsertMode) THEN
                      BEGIN
                        Is := Char(c);
                        MPrompt(Copy(S,Cp,255));
                        Insert(Is,S,Cp);
                        FOR Counter := Cp TO Cl DO
                          Cursor_Left;
                      END
                    ELSE
                      S[Cp]:= Char(c);
                    IF (InsertMode) OR ((Cp - 1) = Cl) THEN
                      Inc(Cl);
                    Inc(Cp);
                    IF (Trapping) THEN
                      Write(TrapFile,Char(c));
                  END;
              END;
          END;
      F_END :
          WHILE (Cp < (Cl + 1)) AND (Cp <= MaxLen) DO
            Cursor_Right;
     F_HOME :
          WHILE (Cp > 1) DO
            BEGIN
              Cursor_Left;
              Dec(Cp);
            END;
     F_LEFT :
          IF (Cp > 1) THEN
            BEGIN
              Cursor_Left;
              Dec(Cp);
            END;
    F_RIGHT :
          IF (Cp <= Cl) THEN
            Cursor_Right;
      F_INS :
          BEGIN
            InsertMode := (NOT InsertMode);
            SetCursor(InsertMode);
          END;
      F_DEL :
          IF (Cp > 0) AND (Cp <= Cl) THEN
            BEGIN
              Dec(Cl);
              Delete(S,Cp,1);
              MPrompt(Copy(S,Cp,255)+' ');
              FOR Counter := Cp TO (Cl + 1) DO
                Cursor_Left;
            END;
    END;
    S[0] := Chr(Cl);
  UNTIL (c = 13) OR (HangUp);

  UserColor(0);

  {
  IF ((Redisplay IN InputFlags) AND (S = '')) THEN
    BEGIN
      S := SaveS;
      MPrompt(S);
    END;
  }

  IF (IsPassword IN InputFlags) THEN
    Echo := TRUE;

  IF (NOT (NoLineFeed IN InputFlags)) THEN
    NL;

  MLC := '';
  SetCursor(FALSE);
END;

{ --- EXPERIMENTAL INPUT W/ SCROLLING FIELD --- }

PROCEDURE NewInput(VAR InputStr: AStr; InputLen, FieldLen: Byte; InputFlags: InputFlagSet; VAR Changed: Boolean);
VAR
  FieldPos, { Current position in field }
  StartPos, { X-Axis input field starting position }
  StringPos: Byte; { Current position in string }
  InsertMode: Boolean; { Are we inserting? }
  KeyInput: Word; { Input }
  NewStr: STRING; { Current state of the string that we're modifying }

  PROCEDURE GoLeft;
  BEGIN
    IF (FieldPos>1) THEN
      Dec(FieldPos)
    ELSE
      BEGIN
        ANSIG(StartPos,WhereY);
        Prompt(Copy(NewStr,StringPos-1,FieldLen))
      END;
    Dec(StringPos);
  END;

  PROCEDURE GoRight;
  BEGIN
    IF NOT (FieldPos>FieldLen) THEN
      Inc(FieldPos)
    ELSE
      BEGIN
        ANSIG(StartPos,WhereY);
        Prompt(Copy(NewStr,StringPos-(FieldLen-1),FieldLen))
      END;
    Inc(StringPos);
  END;

  PROCEDURE GoBackspace;
  BEGIN
    Dec(StringPos);
    Delete(NewStr,StringPos,1);
    IF (FieldPos>1) THEN
      BEGIN
        Dec(FieldPos);
        Backspace;
        IF (StringPos<Length(NewStr)) THEN
          Prompt(Copy(NewStr+' ',StringPos,FieldLen-FieldPos+1));
      END;
  END;

  PROCEDURE GoDelete;
  BEGIN
    Delete(NewStr,StringPos,1);
    Prompt(Copy(NewStr+' ',StringPos,FieldLen-FieldPos+1));
  END;

  PROCEDURE GoUpdateString;
  BEGIN
    {CapAll}
    IF (CapAll IN InputFlags) OR (IsPassword IN InputFlags) THEN
      KeyInput := Ord(UpCase(Char(KeyInput)))
    {CapWords}
    ELSE IF (CapWords IN InputFlags) THEN
      IF (StringPos > 1) THEN
        BEGIN
          IF (NewStr[StringPos - 1] IN [#32..#64]) THEN
            KeyInput := Ord(UpCase(Char(KeyInput)))
          ELSE IF (KeyInput IN [Ord('A')..Ord('Z')]) THEN
            Inc(KeyInput,32);
        END
      ELSE
        KeyInput := Ord(UpCase(Char(KeyInput)));
    {NumbersOnly/AllowNegative}
    IF ((NumbersOnly IN InputFlags) AND (AllowNegative IN InputFlags) AND NOT (KeyInput IN [45,48..57])) OR
       ((NumbersOnly IN InputFlags) AND NOT (AllowNegative IN InputFlags) AND NOT (KeyInput IN [48..57])) THEN
      EXIT;
    {Only allow "-" in first position}
    IF (AllowNegative IN InputFlags) AND ((StringPos<>1)OR(NewStr[1]='-')) AND (KeyInput=45) THEN
      EXIT;
    {/}
    IF (InsertMode) THEN
      BEGIN {Insert}
        Insert(Char(KeyInput),NewStr,StringPos);
        NewStr := Copy(NewStr,1,InputLen); {Truncate}
        Prompt(Copy(NewStr,StringPos,FieldLen-FieldPos+1));
      END
    ELSE
      BEGIN {OverWrite}
        NewStr[StringPos] := Char(KeyInput);
        Prompt(Char(KeyInput));
      END;
    {/}
    IF (StringPos<=Length(NewStr)) THEN
      GoRight;
  END;

BEGIN
  IF (FieldLen<1) THEN
    EXIT;
  StartPos := WhereX;
  IF (AllowNegative IN InputFlags) THEN
    Inc(InputLen); {For the "-"}
  IF (NOT (NoInputField IN InputFlags)) AND (OkANSI) THEN
    MPL(FieldLen);
  IF (IsPassword IN InputFlags) THEN
    Echo := FALSE;
  NewStr := InputStr;
  Prompt(Copy(NewStr,1,FieldLen));
  StringPos := 1;
  FieldPos := 1;
  Changed := FALSE;
  REPEAT
    ANSIG(StartPos+FieldPos-1,WhereY);
    KeyInput := GetKey;
    CASE KeyInput OF
      8       : IF (StringPos>1) THEN {Backspace}
                  GoBackspace;
      32..255 : IF (StringPos <= InputLen) THEN {Printable characters}
                  GoUpdateString;
      F_DEL   : GoDelete; {Delete}
      F_END   : WHILE (StringPos <= Length(NewStr)) DO {End}
                  GoRight;
      F_HOME  : WHILE (StringPos > 1) DO {Home}
                  GoLeft;
      F_INS   : Toggle(InsertMode); {Insert}
      F_LEFT  : IF (StringPos>1) THEN {Left Arrow}
                  GoLeft;
      F_RIGHT : IF (StringPos<=Length(NewStr)) THEN {Right Arrow}
                  GoRight;
    END;
  UNTIL (KeyInput IN [13{Enter},27{Escape}]) OR (HangUp);
  {/}
  IF (NewStr<>InputStr) AND (KeyInput<>27) THEN
    BEGIN
      Changed := TRUE;
      InputStr := NewStr;
    END;
  UserColor(0);
  Echo := TRUE;
  IF NOT (NoLineFeed IN InputFlags) THEN
    NL;
END;

END.