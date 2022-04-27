{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-}
{
 12/16/2021 Colors now use scheme colors for lightbar selected, unselected confd in file area list config
 removed ansig, in common
 
 okansi check for lightbars????
}
UNIT Common5;

INTERFACE

USES
  Common;

PROCEDURE FileAreaScanInput(DisplayStr: AStr; MaxLen: Byte; VAR S: AStr; CONST Allowed: AStr; MinNum,MaxNum: Integer);
PROCEDURE MsgAreaScanInput(DisplayStr: AStr; MaxLen: Byte; VAR S: AStr; CONST Allowed: AStr; MinNum,MaxNum: Integer);

IMPLEMENTATION

USES
  CRT;

FUNCTION CmdExists(Num: Integer): Boolean;
VAR
  Counter: Byte;
  Found: Boolean;
BEGIN
  Found := FALSE;
  FOR Counter := 1 TO LightBarCounter DO
    IF (LightBarArray[Counter].CmdToExec = Num) THEN
      BEGIN
        Found := TRUE;
        Break;
      END;
  CmdExists := Found;
END;

PROCEDURE FileAreaScanInput(DisplayStr: AStr; MaxLen: Byte; VAR S: AStr; CONST Allowed: AStr; MinNum,MaxNum: Integer);
VAR
  SaveS: AStr;
  C: Char;
  Counter,
  SaveX,
  SaveY: Byte;
  W: Word;
  GotCmd: Boolean;
BEGIN
  Prt(DisplayStr);
  MPL(MaxLen);
  IF (LightBarFirstCmd) THEN
    LightBarCmd := 1
  ELSE
    LightBarCmd := LightBarCounter;
  IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
    BEGIN
      SaveX := WhereX;
      SaveY := WhereY;
      ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
      UserColor(7);
      Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
      ANSIG(SaveX,SaveY);
      UserColor(3);
    END;
  GotCmd := FALSE;
  s := '';
  REPEAT
    W := GetKey;
    IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
      BEGIN
        IF (W = 13) AND (S = '') THEN
          BEGIN
            S := IntToStr(LightBarArray[LightBarCmd].CmdToExec);
            GotCmd := TRUE;
          END
        ELSE IF (W = 91) THEN
          BEGIN
            IF (CmdExists(MinNum)) THEN
              W := 0
            ELSE
              BEGIN
                S := '[';
                LightBarFirstCmd := FALSE;
                GotCmd := TRUE
              END;
          END
        ELSE IF (W = 93) THEN
          BEGIN
            IF (CmdExists(MaxNum)) THEN
              W := 0
            ELSE
              BEGIN
                S := ']';
                LightBarFirstCmd := TRUE;
                GotCmd := TRUE
              END
          END
        ELSE IF (W = F_Home) AND (LightBarCmd <> 1) THEN
          BEGIN
            SaveX := WhereX;
            SaveY := WhereY;
            ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
            {UserColor(6);}
            Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
            LightBarCmd := 1;
            ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
            UserColor(7);
            Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
            ANSIG(SaveX,SaveY);
            UserColor(3);
          END
        ELSE IF (W = F_End) AND (LightBarCmd <> LightBarCounter) THEN
          BEGIN
            SaveX := WhereX;
            SaveY := WhereY;
            ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
            {UserColor(6);}
            Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
            LightBarCmd := LightBarCounter;
            ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
            UserColor(7);
            Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
            ANSIG(SaveX,SaveY);
            UserColor(3);
          END
        ELSE IF (W = F_Left) THEN
          BEGIN
            IF (LightBarCmd = 1) AND (LightBarArray[LightBarCmd].CmdToExec <> MinNum) THEN
              BEGIN
                S := '[';
                LightBarFirstCmd := FALSE;
                GotCmd := TRUE
              END
            ELSE IF (LightBarCmd > 1) THEN
              BEGIN
                SaveX := WhereX;
                SaveY := WhereY;
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                {UserColor(6);}
                Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                Dec(LightBarCmd);
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                UserColor(7);
                Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                ANSIG(SaveX,SaveY);
                UserColor(3);
              END;
          END
        ELSE IF (W = F_Right) THEN
          BEGIN
            IF (LightBarCmd = LightBarCounter) AND (LightBarArray[LightBarCmd].CmdToExec <> MaxNum) THEN
              BEGIN
                S := ']';
                LightBarFirstCmd := TRUE;
                GotCmd := TRUE
              END
            ELSE IF (LightBarCmd < LightBarCounter) THEN
              BEGIN
                SaveX := WhereX;
                SaveY := WhereY;
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                {UserColor(6);}
                Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                Inc(LightBarCmd);
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                UserColor(7);
                Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                ANSIG(SaveX,SaveY);
                UserColor(3);
              END;
          END
        ELSE IF (W = F_Up) THEN
          BEGIN
            IF (LightBarCmd = 1) AND (LightBarArray[LightBarCmd].CmdToExec <> MinNum) THEN
              BEGIN
                S := '[';
                LightBarFirstCmd := FALSE;
                GotCmd := TRUE
              END
            ELSE IF ((LightBarCmd - 2) >= 1) THEN
              BEGIN
                SaveX := WhereX;
                SaveY := WhereY;
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                {UserColor(6);}
                Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                Dec(LightBarCmd,2);
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                UserColor(7);
                Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                ANSIG(SaveX,SaveY);
                UserColor(3);
              END
          END
        ELSE IF (W = F_Down) THEN
          BEGIN
            IF (LightBarCmd = LightBarCounter) AND (LightBarArray[LightBarCmd].CmdToExec <> MaxNum) THEN
              BEGIN
                S := ']';
                LightBarFirstCmd := TRUE;
                GotCmd := TRUE
              END
            ELSE IF ((LightBarCmd + 2) <= LightBarCounter) THEN
              BEGIN
                SaveX := WhereX;
                SaveY := WhereY;
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                {UserColor(6);}
                Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                Inc(LightBarCmd,2);
                ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
                UserColor(7);
                Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
                ANSIG(SaveX,SaveY);
                UserColor(3);
              END;
          END;
      END;
    C := UpCase(Char(W));
    SaveS := s;
    IF ((Pos(c,Allowed) <> 0) AND (s = '')) THEN
      BEGIN
        GotCmd := TRUE;
        s := c;
      END
    ELSE IF (Pos(c,'0123456789') > 0) OR (c = '-') THEN
      BEGIN
        IF ((Length(s) < 6) OR ((Pos('-',s) > 0) AND (Length(s) < 11))) THEN
          s := s + c;
      END
    ELSE IF ((s <> '') AND (c = ^H)) THEN
      Dec(s[0])
    ELSE IF (c = ^X) THEN
      BEGIN
        FOR Counter := 1 TO Length(s) DO
          BackSpace;
        s := '';
        SaveS := '';
      END
    ELSE IF (c = #13) AND (S <> '') THEN
      BEGIN
        IF (S = '-') THEN
          BEGIN
            BackSpace;
            S := '';
            SaveS := '';
          END
        ELSE
          GotCmd := TRUE;
      END;
    IF (Length(s) < Length(SaveS)) THEN
      BackSpace;
    IF (Length(s) > Length(SaveS)) THEN
      Prompt(s[Length(s)]);
  UNTIL (GotCmd) OR (HangUp);
  IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
    BEGIN
      SaveX := WhereX;
      SaveY := WhereY;
      ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
      {UserColor(6);}
      Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
      ANSIG(SaveX,SaveY);
    END;
  UserColor(0);
  NL;
END;

PROCEDURE MsgAreaScanInput(DisplayStr: AStr; MaxLen: Byte; VAR S: AStr; CONST Allowed: AStr; MinNum,MaxNum: Integer);
VAR
  SaveS: AStr;
  C: Char;
  Counter,
  SaveX,
  SaveY: Byte;
  W: Word;
  GotCmd: Boolean;
BEGIN
  Prt(DisplayStr);
  MPL(MaxLen);

  IF (LightBarFirstCmd) THEN
    LightBarCmd := 1
  ELSE
    LightBarCmd := LightBarCounter;

  IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
  BEGIN
    SaveX := WhereX;
    SaveY := WhereY;
    ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
    UserColor(7);
    Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
    ANSIG(SaveX,SaveY);
    UserColor(3);
  END;

  GotCmd := FALSE;

  s := '';

  REPEAT

    W := GetKey;

    IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
    BEGIN
      IF (W = 13) AND (S = '') THEN
      BEGIN
        S := IntToStr(LightBarArray[LightBarCmd].CmdToExec);
        GotCmd := TRUE;
      END
      ELSE IF (W = 91) THEN
      BEGIN
        IF (CmdExists(MinNum)) THEN
          W := 0
        ELSE
        BEGIN
          S := '[';
          LightBarFirstCmd := FALSE;
          GotCmd := TRUE
        END;
      END
      ELSE IF (W = 93) THEN
      BEGIN
        IF (CmdExists(MaxNum)) THEN
          W := 0
        ELSE
        BEGIN
          S := ']';
          LightBarFirstCmd := TRUE;
          GotCmd := TRUE
        END
      END
      ELSE IF (W = F_Home) AND (LightBarCmd <> 1) THEN
      BEGIN
        SaveX := WhereX;
        SaveY := WhereY;
        ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
        {UserColor(6);}
        Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
        LightBarCmd := 1;
        ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
        UserColor(7);
        Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
        ANSIG(SaveX,SaveY);
        UserColor(3);
      END
      ELSE IF (W = F_End) AND (LightBarCmd <> LightBarCounter) THEN
      BEGIN
        SaveX := WhereX;
        SaveY := WhereY;
        ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
        {UserColor(6);}
        Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
        LightBarCmd := LightBarCounter;
        ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
        UserColor(7);
        Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
        ANSIG(SaveX,SaveY);
        UserColor(3);
      END
      ELSE IF (W = F_Left) THEN
      BEGIN
        IF (LightBarCmd = 1) AND (LightBarArray[LightBarCmd].CmdToExec <> MinNum) THEN
        BEGIN
          S := '[';
          LightBarFirstCmd := FALSE;
          GotCmd := TRUE
        END
        ELSE IF (LightBarCmd > 1) THEN
        BEGIN
          SaveX := WhereX;
          SaveY := WhereY;
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          {UserColor(6);}
          Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          Dec(LightBarCmd);
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          UserColor(7);
          Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          ANSIG(SaveX,SaveY);
          UserColor(3);
        END;
      END
      ELSE IF (W = F_Right) THEN
      BEGIN
        IF (LightBarCmd = LightBarCounter) AND (LightBarArray[LightBarCmd].CmdToExec <> MaxNum) THEN
        BEGIN
          S := ']';
          LightBarFirstCmd := TRUE;
          GotCmd := TRUE
        END
        ELSE IF (LightBarCmd < LightBarCounter) THEN
        BEGIN
          SaveX := WhereX;
          SaveY := WhereY;
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          {UserColor(6);}
          Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          Inc(LightBarCmd);
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          UserColor(7);
          Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          ANSIG(SaveX,SaveY);
          UserColor(3);
        END;
      END
      ELSE IF (W = F_Up) THEN
      BEGIN
        IF (LightBarCmd = 1) AND (LightBarArray[LightBarCmd].CmdToExec <> MinNum) THEN
        BEGIN
          S := '[';
          LightBarFirstCmd := FALSE;
          GotCmd := TRUE
        END
        ELSE IF ((LightBarCmd - 2) >= 1) THEN
        BEGIN
          SaveX := WhereX;
          SaveY := WhereY;
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          {UserColor(6);}
          Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          Dec(LightBarCmd,2);
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          UserColor(7);
          Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          ANSIG(SaveX,SaveY);
          UserColor(3);
         END
      END
      ELSE IF (W = F_Down) THEN
      BEGIN
        IF (LightBarCmd = LightBarCounter) AND (LightBarArray[LightBarCmd].CmdToExec <> MaxNum) THEN
        BEGIN
          S := ']';
          LightBarFirstCmd := TRUE;
          GotCmd := TRUE
        END
        ELSE IF ((LightBarCmd + 2) <= LightBarCounter) THEN
        BEGIN
          SaveX := WhereX;
          SaveY := WhereY;
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          {UserColor(6);}
          Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          Inc(LightBarCmd,2);
          ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
          UserColor(7);
          Prompt(PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
          ANSIG(SaveX,SaveY);
          UserColor(3);
        END;
      END;
    END;

    C := UpCase(Char(W));

    SaveS := s;

    IF ((Pos(c,Allowed) <> 0) AND (s = '')) THEN
    BEGIN
      GotCmd := TRUE;
      s := c;
    END
    ELSE IF (Pos(c,'0123456789') > 0) OR (c = '-') THEN
    BEGIN
      IF ((Length(s) < 6) OR ((Pos('-',s) > 0) AND (Length(s) < 11))) THEN
        s := s + c;
    END
    ELSE IF ((s <> '') AND (c = ^H)) THEN
      Dec(s[0])
    ELSE IF (c = ^X) THEN
    BEGIN
      FOR Counter := 1 TO Length(s) DO
        BackSpace;
      s := '';
      SaveS := '';
    END
    ELSE IF (c = #13) AND (S <> '') THEN
    BEGIN
      IF (S = '-') THEN
      BEGIN
        BackSpace;
        S := '';
        SaveS := '';
      END
      ELSE
        GotCmd := TRUE;
    END;
    IF (Length(s) < Length(SaveS)) THEN
      BackSpace;
    IF (Length(s) > Length(SaveS)) THEN
      Prompt(s[Length(s)]);
  UNTIL (GotCmd) OR (HangUp);

  IF (General.UseLightBars) AND (LightBars IN ThisUser.SFlags) THEN
  BEGIN
    SaveX := WhereX;
    SaveY := WhereY;
    ANSIG(LightBarArray[LightBarCmd].XPos,LightBarArray[LightBarCmd].YPos);
    {UserColor(6);}
    Prompt('2'+PadLeftStr(LightBarArray[LightBarCmd].CmdToShow,32));
    ANSIG(SaveX,SaveY);
  END;

  UserColor(0);
  NL;
END;
END.