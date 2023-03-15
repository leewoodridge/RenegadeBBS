{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S-,V-}
{
11/5/2021 Nested Local_Input1 in lStatus_screen
04/15/2022 - alt+s no more, alt-c will use whichever chat is configured as default (as long as ansiok)
}
UNIT Common2;

INTERFACE

USES
  Common;

PROCEDURE BiosScroll(Up: Boolean); {LeeW: Added}
PROCEDURE SKey1(VAR C: Char);
PROCEDURE SaveGeneral(x: Boolean);
PROCEDURE TLeft;
PROCEDURE ChangeUserDataWindow;
PROCEDURE lStatus_Screen(WhichScreen: Byte; CONST Message: AStr; OneKey: Boolean; VAR Answer: AStr);
PROCEDURE Update_Screen;
PROCEDURE ToggleWindow(ShowIt: Boolean);

IMPLEMENTATION

USES
  CRT,
  DOS,
  TimeFunc,
  Chat,
  SysOp2G,
  SysOp3;

CONST
  SYSKEY_LENGTH = 1269;

  SYSKEY: ARRAY [1..1269] OF Char = (
    #3 ,#16,'Ú',#26,'M','Ä','¿',#24,'³',#17,#25,#23,#11,'R','e','n','e',
    'g','a','d','e',' ','B','u','l','l','e','t','i','n',' ','B','o','a',
    'r','d',' ','S','y','s','t','e','m',#25,#23,#3 ,#16,'³',#24,'Ã',#26,
    '%','Ä','Â',#26,'&','Ä','´',#24,'³',' ',#14,'A','L','T','+','A',' ',
    #15,':',' ',#7 ,'S','t','a','t','u','s',' ','L','i','n','e',':',' ',
    'O','n','/','O','f','f',' ',' ',' ',' ',#25,#5 ,#3 ,'³',' ',#14,'A',
    'L','T','+','N',' ',#15,':',' ',#7 ,'S','w','i','t','c','h',' ','t',
    'o',' ','n','e','x','t',' ','S','y','s','O','p',' ','w','i','n','d',
    'o','w',#25,#2 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','C',' ',#15,
    ':',' ',#7 ,'E','n','t','e','r','/','E','x','i','t',' ','c','h','a',
    't',' ','m','o','d','e',#25,#8 ,#3 ,'³',' ',#14,'A','L','T','+','O',
    ' ',#15,':',' ',#7 ,'C','o','n','f','e','r','e','n','c','e',' ','S',
    'y','s','t','e','m',' ','t','o','g','g','l','e',#25,#5 ,#3 ,'³',#24,
    '³',' ',#14,'A','L','T','+','D',' ',#15,':',' ',#7 ,'D','u','m','p',
    ' ','s','c','r','e','e','n',' ','t','o',' ','f','i','l','e',#25,#9 ,
    #3 ,'³',' ',#14,'A','L','T','+','P',' ',#15,':',' ',#7 ,'P','r','i',
    'n','t',' ','f','i','l','e',' ','t','o',' ','t','h','e',' ','u','s',
    'e','r',#25,#7 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','E',' ',#15,
    ':',' ',#7 ,'E','d','i','t',' ','C','u','r','r','e','n','t',' ','U',
    's','e','r',#25,#11,#3 ,'³',' ',#14,'A','L','T','+','Q',' ',#15,':',
    ' ',#7 ,'T','u','r','n',' ','o','f','f',' ','c','h','a','t',' ','p',
    'a','g','i','n','g',#25,#9 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+',
    'F',' ',#15,':',' ',#7 ,'G','e','n','e','r','a','t','e',' ','f','a',
    'k','e',' ','l','i','n','e',' ','n','o','i','s','e',#25,#4 ,#3 ,'³',
    ' ',#14,'A','L','T','+','R',' ',#15,':',' ',#7 ,'S','h','o','w',' ',
    'c','h','a','t',' ','r','e','q','u','e','s','t',' ','r','e','a','s',
    'o','n',#25,#5 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','G',' ',#15,
    ':',' ',#7 ,'T','r','a','p','/','c','h','a','t','-','c','a','p','t',
    'u','r','i','n','g',' ','t','o','g','g','l','e','s',' ',' ',#3 ,'³',
    ' ',#14,'A','L','T','+','S',' ',#15,':',' ',#7 ,'S','t','a','t','u',
    's',' ','L','i','n','e',':',' ','O','n','/','O','f','f',#25,#10,#3 ,
    '³',#24,'³',' ',#14,'A','L','T','+','H',' ',#15,':',' ',#7 ,'H','a',
    'n','g','u','p',' ','u','s','e','r',' ','i','m','m','e','d','i','a',
    't','e','l','y',#25,#5 ,#3 ,'³',' ',#14,'A','L','T','+','T',' ',#15,
    ':',' ',#7 ,'T','o','p','/','B','o','t','t','o','m',' ','S','y','s',
    'O','p',' ','w','i','n','d','o','w',#25,#6 ,#3 ,'³',#24,'³',' ',#14,
    'A','L','T','+','I',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ',
    'u','s','e','r',' ','i','n','p','u','t',#25,#11,#3 ,'³',' ',#14,'A',
    'L','T','+','U',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ','u',
    's','e','r',' ','s','c','r','e','e','n',#25,#11,#3 ,'³',#24,'³',' ',
    #14,'A','L','T','+','J',' ',#15,':',' ',#7 ,'J','u','m','p',' ','t',
    'o',' ','t','h','e',' ','O','S',#25,#14,#3 ,'³',' ',#14,'A','L','T',
    '+','V',' ',#15,':',' ',#7 ,'A','u','t','o','-','v','a','l','i','d',
    'a','t','e',' ','u','s','e','r',#25,#11,#3 ,'³',#24,'³',' ',#14,'A',
    'L','T','+','K',' ',#15,':',' ',#7 ,'K','i','l','l',' ','u','s','e',
    'r',' ','w','/','H','A','N','G','U','P','#',' ','f','i','l','e',#25,
    #4 ,#3 ,'³',' ',#14,'A','L','T','+','W',' ',#15,':',' ',#7 ,'E','d',
    'i','t',' ','U','s','e','r',' ','w','i','t','h','o','u','t',' ','n',
    'o','t','i','c','e',#25,#5 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+',
    'L',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ','l','o','c','a',
    'l',' ','s','c','r','e','e','n',' ','d','i','s','p','l','a','y',' ',
    ' ',#3 ,'³',' ',#14,'A','L','T','+','Z',' ',#15,':',' ',#7 ,'W','a',
    'k','e',' ','u','p',' ','a',' ','s','l','e','e','p','i','n','g',' ',
    'u','s','e','r',#25,#6 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','M',
    ' ',#15,':',' ',#7 ,'M','a','k','e','/','T','a','k','e',' ','T','e',
    'm','p',' ','S','y','s','O','p',' ','A','c','c','e','s','s',' ',' ',
    #3 ,'³',' ',#14,'A','L','T','-','#',' ',#15,':',' ',#7 ,'E','x','e',
    'c','u','t','e',' ','G','L','O','B','A','T','#','.','B','A','T',#25,
    #10,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','+',' ',#15,':',' ',#7 ,
    'G','i','v','e',' ','5',' ','m','i','n','u','t','e','s',' ','t','o',
    ' ','u','s','e','r',#25,#6 ,#3 ,'³',' ',#14,'A','L','T','+','-',' ',
    #15,':',' ',#7 ,'T','a','k','e',' ','5',' ','m','i','n','u','t','e',
    's',' ','f','r','o','m',' ','u','s','e','r',#25,#5 ,#3 ,'³',#24,'Ã',
    #26,'%','Ä','Á',#26,'&','Ä','´',#24,'³',' ',#14,'C','T','R','L','+',
    'H','O','M','E',' ',#15,':',' ',#7 ,'T','h','i','s',' ','h','e','l',
    'p',' ','s','c','r','e','e','n',#25,#10,#14,'C','T','R','L','+','S',
    'Y','S','R','Q',' ',#15,':',' ',#7 ,'F','a','k','e',' ','s','y','s',
    't','e','m',' ','e','r','r','o','r',#25,#7 ,#3 ,'³',#24,'³',' ',#14,
    'S','C','R','L','C','K',#25,#3 ,#15,':',' ',#7 ,'T','o','g','g','l',
    'e',' ','c','h','a','t',' ','a','v','a','i','l','a','b','i','l','i',
    't','y',#25,#2 ,#14,'A','L','T','+','F','1','-','F','5',' ',' ',#15,
    ':',' ',#7 ,'S','y','s','O','p',' ','W','i','n','d','o','w',' ','1',
    ' ','-',' ','5',#25,#6 ,#3 ,'³',#24,'À',#26,'M','Ä','Ù',#24,#24,#24,
    #24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,
    #24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24);

  WIN1_LENGTH = 51;

  WIN1: ARRAY [1..51] OF Char = (
    #15,#23,#25,#27,'A','R',':',#25,#27,'N','S','L',':',#25,#4 ,'T','i',
    'm','e',':',#25,#6 ,#24,#25,#27,'A','C',':',#25,#15,'B','a','u','d',
    ':',#25,#6 ,'D','S','L',':',#25,#4 ,'N','o','d','e',':',#25,#6 ,#24);

  WIN2_LENGTH = 42;

  WIN2: ARRAY [1..42] OF Char = (
    #15,#23,#25,#27,'P','H',':',#25,#18,'F','O',':',#25,#10,'T','e','r',
    'm',':',#25,#10,#24,#25,#27,'B','D',':',#25,#18,'L','O',':',#25,#10,
    'E','d','i','t',':',#25,#10,#24);

  WIN3_LENGTH = 80;

  WIN3: ARRAY [1..80] OF Char = (
    #15,#23,' ','T','C',':',#25, #6,'C','T',':',#25, #6,'P','P',':',#25,
     #6,'F','S',':',#25, #6,'D','L',':',#25,#14,'F','R',':',#25, #5,'T',
    'i','m','e',':',#25, #6,#24,' ','T','T',':',#25, #6,'B','L',':',#25,
     #6,'E','S',':',#25, #6,'T','B',':',#25, #6,'U','L',':',#25,#14,'P',
    'R',':',#25, #5,'N','o','d','e',':',#25, #6,#24);

  WIN4_LENGTH = 96;

  WIN4: ARRAY [1..96] OF Char = (
    #8 ,#23,' ',#15,'T','o','d','a','y',#39,'s',' ',#8 ,'³',' ',' ',#15,
    'C','a','l','l','s',':',#25,#7 ,'E','m','a','i','l',':',#25,#7 ,'D',
    'L',':',#25,#17,'N','e','w','u','s','e','r','s',':',#25,#9 ,#24,#25,
    #2 ,'S','t','a','t','s',' ',#8 ,'³',' ',' ',#15,'P','o','s','t','s',
    ':',#25,#7 ,'F','e','e','d','b',':',#25,#7 ,'U','L',':',#25,#17,'A',
    'c','t','i','v','i','t','y',':',#25,#9 ,#24);

  WIN5_LENGTH = 113;

  WIN5: ARRAY [1..113] OF Char = (
    #8 ,#23,' ',#15,'S','y','s','t','e','m',' ',' ',#8 ,'³',' ',' ',#15,
    'C','a','l','l','s',':',#25,#7 ,'D','L',':',#25,#7 ,'D','a','y','s',
    ' ',':',#25,#6 ,'U','s','e','r','s',':',#25,#6 ,'D','i','s','k','f',
    'r','e','e',':',#25,#7 ,#24,' ',' ','S','t','a','t','s',' ',' ',#8 ,
    '³',' ',' ',#15,'P','o','s','t','s',':',#25,#7 ,'U','L',':',#25,#7 ,
    'H','o','u','r','s',':',#25,#6 ,'M','a','i','l',' ',':',#25,#6 ,'O',
    'v','e','r','l','a','y','s',':',#25,#7 ,#24);

PROCEDURE BiosScroll(up: Boolean); ASSEMBLER;
ASM
  Mov cx,0
  Mov dh,MaxDisplayRows
  Mov dl,MaxDisplayCols
  Mov bh,7
  Mov al,2
  Cmp up,1
  Je @Up
  Mov ah,7
  Jmp @go
  @up:
  Mov ah,6
  @Go:
  Int 10h
END;

PROCEDURE CPR(c1,c2: Byte);
VAR
  Flag: ACFlagType;
BEGIN
  FOR Flag := RLogon TO RMsg DO
  BEGIN
    IF (Flag IN ThisUser.ACFlags) THEN
      TextAttr := c1
    ELSE
      TextAttr := c2;
    Write(Copy('LCVUA*PEKM',(Ord(Flag) + 1),1));
  END;
  FOR Flag := FNoDLRatio TO FNoDeletion DO
  BEGIN
    IF (Flag IN ThisUser.ACFlags) THEN
      TextAttr := c1
    ELSE
      TextAttr := c2;
    Write(Copy('1234',(Ord(Flag) - 19),1));
  END;
END;

PROCEDURE Clear_Status_Box;
BEGIN
  IF (General.IsTopWindow) THEN
    Window(1,1,MaxDisplayCols,2)
  ELSE
    Window(1,(MaxDisplayRows - 1),MaxDisplayCols,MaxDisplayRows);
  ClrScr;
  Window(1,1,MaxDisplayCols,MaxDisplayRows);
END;

PROCEDURE ToggleWindow(ShowIt: Boolean);
VAR
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;
BEGIN
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextattr := TextAttr;
  TextAttr := 7;
  IF (General.WindowOn) THEN
    BEGIN
      Clear_Status_Box;
      IF (General.IsTopWindow) THEN
        BEGIN
          GoToXY(1, MaxDisplayRows);
          Write(^J^J);
        END;
    END
  ELSE
    BEGIN
      IF (General.IsTopWindow AND (SaveWhereY <= (MaxDisplayRows - 2))) THEN
        BiosScroll(FALSE)
      ELSE IF (NOT General.IsTopWindow AND (SaveWhereY > (MaxDisplayRows - 2))) THEN
        BEGIN
          BiosScroll(TRUE);
          Dec(SaveWhereY,2)
        END
      ELSE IF (General.IsTopWindow) THEN
        Dec(SaveWhereY,2);
    END;
  General.WindowOn := NOT General.WindowOn;
  IF (ShowIt) THEN
    Update_Screen;
  GoToXY(SaveWhereX,SaveWhereY);
  TextAttr := SaveTextAttr;
END;

PROCEDURE lStatus_Screen(WhichScreen: Byte; CONST Message: AStr; OneKey: Boolean; VAR Answer: AStr);
VAR
  HistoryFile: FILE OF HistoryRecordType;
  History: HistoryRecordType;
  User: UserRecordType;
  C: Char;
  FirstRow,
  SecondRow,
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;
  SaveWindowOn: Boolean;

PROCEDURE Local_Input1(VAR S: STRING; MaxLen: Byte; LowerCase: Boolean);
VAR
  C: Char;
  B: Byte;
BEGIN
  B := 1;
  REPEAT
    C := ReadKey;
    IF (NOT LowerCase) THEN
      C := UpCase(C);
    IF (C IN [#32..#255]) THEN
      IF (B <= MaxLen) THEN
      BEGIN
        S[B] := C;
        Inc(B);
        Write(C);
      END
      ELSE
    ELSE
      CASE C of
        ^H : IF (B > 1) THEN
             BEGIN
               Write(^H' '^H);
               C := ^H;
               Dec(B);
             END;
     ^U,^X : WHILE (B <> 1) DO
             BEGIN
               Write(^H' '^H);
               Dec(B);
             END;
      END;
  UNTIL (C IN [^M,^N]);
  S[0] := Chr(B - 1);
  IF (WhereY <= Hi(WindMax) - Hi(WindMin)) THEN
    WriteLn;
END;

BEGIN
  IF ((InWFCMenu OR (NOT General.WindowOn)) AND (WhichScreen < 99)) OR
    (General.NetworkMode AND NOT CoSysOp) THEN
    Exit;
  SaveWindowOn := General.WindowOn;
  IF (NOT General.WindowOn) THEN
    ToggleWindow(FALSE);
  TLeft;
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextAttr := TextAttr;
  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  IF (General.IsTopWindow) THEN
    FirstRow := 1
  ELSE
    FirstRow := (MaxDisplayRows - 1);
  SecondRow := (FirstRow + 1);
  TextAttr := 120;
  LastScreenSwap := 0;
  Cursor(FALSE);
  Clear_Status_Box;
  IF (WhichScreen < 99) THEN
    General.CurWindow := WhichScreen;
  CASE WhichScreen OF
    1 : WITH ThisUser DO
        BEGIN
          Update_Logo(Win1,ScreenAddr[(FirstRow - 1) * 160],WIN1_LENGTH);
          GoToXY(02,FirstRow);
          Write(Caps(Name));
          GoToXY(33,FirstRow);
          FOR C := 'A' TO 'Z' DO
          BEGIN
            IF (C IN ARFlags) THEN
              TextAttr := 116
            ELSE
              TextAttr := 120;
            Write(C);
          END;
          TextAttr := 120;
          GoToXY(65,FirstRow);
          IF (TempSysOp) THEN
          BEGIN
            TextAttr := 244;
            Write(255);
            TextAttr := 120;
          END
          ELSE
            Write(SL);
          GoToXY(75,FirstRow);
          Write(NSL DIV 60);
          GoToXY(02,SecondRow);
          Write(RealName+' #'+IntToStr(UserNum));
          GoToXY(33,SecondRow);
          CPR(116,120);
          TextAttr := 120;
          GoToXY(54,SecondRow);
          Write(ActualSpeed);
          GoToXY(65,SecondRow);
          IF (TempSysOp) THEN
          BEGIN
            TextAttr := 244;
            Write(255);
            TextAttr := 120;
          END
          ELSE
            Write(DSL);
          GoToXY(75,SecondRow);
          Write(ThisNode);
        END;
    2 : WITH ThisUser DO
        BEGIN
          Update_Logo(Win2,ScreenAddr[(FirstRow - 1) * 160],WIN2_LENGTH);
          GoToXY(02,FirstRow);
          Write(Street);
          GoToXY(33,FirstRow);
          Write(Ph);
          GoToXY(55,FirstRow);
          Write(ToDate8(PD2Date(Firston)));
          GoToXY(71,FirstRow);
          IF (OKRIP) THEN
            Write('RIP')
          ELSE IF (OKAvatar) THEN
            Write('AVATAR')
          ELSE IF (OkANSI) THEN
            Write('ANSI')
          ELSE IF (OkVT100) THEN
            Write('VT-100')
          ELSE
            Write('NONE');
          GoToXY(02,SecondRow);
          Write(PadLeftStr(Citystate+' '+Zipcode,26));
          GoToXY(33,SecondRow);
          Write(ToDate8(PD2Date(BirthDate)),', ');
          Write(Sex+' ',AgeUser(ThisUser.BirthDate));
          GoToXY(55,SecondRow);
          Write(ToDate8(PD2Date(Laston)));
          GoToXY(71,SecondRow);
          IF (FSEditor IN SFlags) THEN
            Write('FullScrn')
          ELSE
            Write('Regular');
        END;
    3 : WITH ThisUser DO
        BEGIN
          Update_Logo(Win3,ScreenAddr[(FirstRow - 1) * 160],WIN3_LENGTH);
          GoToXY(06,FirstRow);
          Write(Loggedon);
          GoToXY(16,FirstRow);
          Write(OnToday);
          GoToXY(26,FirstRow);
          Write(MsgPost);
          GoToXY(36,FirstRow);
          Write(Feedback);
          GoToXY(46,FirstRow);
          Write(IntToStr(Downloads)+'/'+ConvertKB(DK,FALSE));
          GoToXY(64,FirstRow);
          IF (Downloads > 0) THEN
            Write((Uploads / Downloads) * 100:3:0,'%')
          ELSE
            Write(0);
          GoToXY(75,FirstRow);
          Write(NSL DIV 60);
          GoToXY(06,SecondRow);
          Write(TTimeon);
          GoToXY(16,SecondRow);
          Write(ThisUser.lCredit - ThisUser.Debit);
          GoToXY(26,SecondRow);
          Write(EmailSent);
          GoToXY(36,SecondRow);
          Write(TimeBank);
          GoToXY(46,SecondRow);
          Write(IntToStr(Uploads)+'/'+ConvertKB(UK,FALSE));
          GoToXY(64,SecondRow);
          IF (Loggedon > 0) THEN
            Write((Msgpost / Loggedon) * 100:3:0,'%')
          ELSE
            Write(0);
          GoToXY(75,SecondRow);
          Write(ThisNode);
        END;
    4 : BEGIN
          Assign(HistoryFile,General.DataPath+'HISTORY.DAT');
          Reset(HistoryFile);
          IF (IOResult = 2) THEN
            ReWrite(HistoryFile)
          ELSE
          BEGIN
            Seek(HistoryFile,FileSize(HistoryFile) - 1);
            Read(HistoryFile,History);
          END;
          Close(HistoryFile);
          WITH History DO
          BEGIN
            Update_Logo(Win4,ScreenAddr[(FirstRow - 1) * 160],WIN4_LENGTH);
            GoToXY(20,FirstRow);
            Write(Callers);
            GoToXY(34,FirstRow);
            Write(Email);
            GoToXY(45,FirstRow);
            Write(IntToStr(Downloads)+'/'+ConvertKB(DK,FALSE));
            GoToXY(72,FirstRow);
            Write(NewUsers);
            GoToXY(20,SecondRow);
            Write(Posts);
            GoToXY(34,SecondRow);
            Write(Feedback);
            GoToXY(45,SecondRow);
            Write(IntToStr(Uploads)+'/'+ConvertKB(UK,FALSE));
            IF (Active > 9999) THEN
              Active := 9999;
            GoToXY(72,SecondRow);
            Write(Active,' min');
          END;
        END;
    5 : WITH History DO
        BEGIN
          Update_Logo(Win5,ScreenAddr[(FirstRow - 1) * 160],WIN5_LENGTH);
          GoToXY(20,FirstRow);
          Write(General.CallerNum);
          GoToXY(31,FirstRow);
          Write(General.TotalDloads + Downloads);
          GoToXY(45,FirstRow);
          Write(General.DaysOnline + 1);
          GoToXY(58,FirstRow);
          Write(General.NumUsers);
          GoToXY(74,FirstRow);
          Write(ConvertKB(DiskKbFree(StartDir),FALSE));
          GoToXY(20,SecondRow);
          Write(General.TotalPosts + Posts);
          GoToXY(31,SecondRow);
          Write(General.TotalUloads + Uploads);
          GoToXY(45,SecondRow);
          Write((General.TotalUsage + Active) DIV 60);
          LoadURec(User,1);
          GoToXY(58,SecondRow);
          IF (User.Waiting > 0) THEN
            TextAttr := 244;
          Write(User.Waiting);
          TextAttr := 120;
          GoToXY(74,SecondRow);
          CASE OverlayLocation OF
            0 : Write('Disk');
            1 : Write('EMS');
            2 : Write('XMS');
          END;
        END;
    100 :
        BEGIN
          GoToXY((MaxDisplayCols - Length(Message)) DIV 2,FirstRow);
          Write(Message);
          LastScreenSwap := Timer;
        END;
    99 :
        BEGIN
          GoToXY(1,FirstRow);
          Write(Message);
          IF (OneKey) THEN
            Answer := UpCase(ReadKey)
          ELSE
          BEGIN
            GoToXY(2,(FirstRow + 1));
            Write('> ');
            Local_Input1(Answer,MaxDisplayCols - 4,FALSE);
          END;
        END;
  END;
  IF (General.IsTopWindow) THEN
    Window(1,3,MaxDisplayCols,MaxDisplayRows)
  ELSE
    Window(1,1,MaxDisplayCols,MaxDisplayRows - 2);
  Cursor(TRUE);
  IF (NOT SaveWindowOn) THEN
    ToggleWindow(FALSE);
  GoToXY(SaveWhereX,SaveWhereY);
  TextAttr := SaveTextAttr;
END;

PROCEDURE Update_Screen;
VAR
  Answer: AStr;
BEGIN
  lStatus_Screen(General.CurWindow,'',FALSE,Answer);
END;

PROCEDURE SKey1(VAR C: Char);
VAR
  S: AStr;
  C1: Char;
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;
  RetCode,
  i: Integer;
  SaveTimer: LongInt;
  SaveInChat: Boolean;
BEGIN
  IF (General.NetworkMode AND (NOT CoSysOp OR InWFCMenu)) THEN
    Exit;
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextAttr := TextAttr;
  CASE Ord(C) OF
    120..129 :
          BEGIN  {ALT-1 TO ALT-0}
            GetDir(0,S);
            ChDir(StartDir);
            SaveScreen(Wind);
            ClrScr;
            SaveTimer := Timer;
            i := (Ord(C) - 119);
            IF (i = 10) THEN
              i := 0;
            ShellDOS(FALSE,'GLOBAT'+Chr(i + 48),RetCode);
            Com_Flush_Recv;
            FreeTime := ((FreeTime + Timer) - SaveTimer);
            RemoveWindow(Wind);
            GoToXY(SaveWhereX,SaveWhereY);
            ChDir(S);
          END;
    104..108 :
          lStatus_Screen(((Ord(C) - 104) + 1),'',FALSE,S);   { ALT F1-F5     }
    114 : RunError(255);                                     { CTRL-PRTSC    }
     36 : BEGIN
            SaveScreen(Wind);
            SysOpShell;                                       { ALT-J         }
            RemoveWindow(Wind);
          END;
     32 : BEGIN                                               { ALT-D         }
            lStatus_Screen(99,'Dump screen to what file: ',FALSE,S);
            IF (S <> '') THEN
              ScreenDump(S);
            Update_Screen;
          END;
     59..68 :
          Buf := General.Macro[Ord(C) - 59];                { F1 - F10      }
  END;
  IF (NOT InWFCMenu) THEN
  BEGIN
    CASE Ord(C) OF
      119 : BEGIN                                              { CTRL-HOME     }
              SaveScreen(Wind);
              Update_Logo(SYSKEY,ScreenAddr[0],SYSKEY_LENGTH);
              Cursor(FALSE);
              C := ReadKey;
              IF (C = #0) THEN
                C := ReadKey;
              Cursor(TRUE);
              RemoveWindow(Wind);
              GoToXY(SaveWhereX,SaveWhereY);
              Update_Screen;
            END;
       34 : BEGIN                                             { ALT-G         }
              lStatus_Screen(99,'Log options - [T]rap activity [C]hat buffering',TRUE,S);
              C1 := S[1];
              WITH ThisUser DO
                CASE C1 OF
                  'C' : BEGIN
                          lStatus_Screen(99,'Auto Chat buffering - [O]ff [S]eparate [M]ain (Chat.LOG)',TRUE,S);
                          C1 := S[1];
                          IF (C1 IN ['O','S','M']) THEN
                            ChatFileLog(FALSE);
                          CASE C1 OF
                            'O' : BEGIN
                                    Exclude(ThisUser.SFlags,ChatAuto);
                                    Exclude(ThisUser.SFlags,ChatSeparate);
                                  END;
                            'S' : BEGIN
                                    Include(ThisUser.SFlags,ChatAuto);
                                    Include(ThisUser.SFlags,ChatSeparate);
                                  END;
                            'M' : BEGIN
                                    Include(ThisUser.SFlags,ChatAuto);
                                    Exclude(ThisUser.SFlags,ChatSeparate);
                                  END;
                          END;
                          IF (C1 IN ['S','M']) THEN
                            ChatFileLog(TRUE);
                        END;
                  'T' : BEGIN
                          lStatus_Screen(99,'Activity Trapping - [O]ff [S]eperate [M]ain (TRAP.LOG)',TRUE,S);
                          C1 := S[1];
                          IF (C1 IN ['O','S','M']) THEN
                            IF (Trapping) THEN
                            BEGIN
                              Close(TrapFile);
                              Trapping := FALSE;
                            END;
                            CASE C1 OF
                              'O' : BEGIN
                                      Exclude(ThisUser.SFlags,TrapActivity);
                                      Exclude(ThisUser.SFlags,TrapSeparate);
                                    END;
                              'S' : BEGIN
                                      Include(ThisUser.SFlags,TrapActivity);
                                      Include(ThisUser.SFlags,TrapSeparate);
                                    END;
                              'M' : BEGIN
                                      Include(ThisUser.SFlags,TrapActivity);
                                      Exclude(ThisUser.SFlags,TrapSeparate);
                                    END;
                            END;
                            IF (C1 IN ['S','M']) THEN
                              InitTrapFile;
                        END;
                END;
                Update_Screen;
            END;
       20 : BEGIN                                             { ALT-T         }
              IF (General.WindowOn) THEN
                BiosScroll(General.IsTopWindow);
              General.IsTopWindow := NOT General.IsTopWindow;
              Update_Screen;
            END;
            (*
       31 : IF (NOT InChat) THEN                              { ALT-S   }                   { ALT-A         }
              SysOpSplitChat
            ELSE
            BEGIN
              InChat := FALSE;
              ChatReason := '';
            END;
*)
       47 : IF (UserOn) THEN
            BEGIN                              { ALT-V         }
              S[1] := #0;
              lStatus_Screen(99,'Enter the validation level (!-~) for this user.',TRUE,S);
              IF (S[1] IN ['!'..'~']) THEN
              BEGIN
                AutoValidate(ThisUser,UserNum,S[1]);
                lStatus_Screen(100,'This user has been validated.',FALSE,S);
              END
              ELSE
                Update_Screen;
            END;
       18 : IF (UserOn) THEN
            BEGIN                            { ALT-E         }
              Wait(TRUE);
              SaveScreen(Wind);
              ChangeUserDataWindow;
              RemoveWindow(Wind);
              Update_Screen;
              Wait(FALSE);
           END;
      17 : IF (UserOn) THEN
           BEGIN
             SaveScreen(Wind);
             ChangeUserDataWindow;                         { ALT-W         }
             RemoveWindow(Wind);
             Update_Screen;
           END;
      49 : IF (UserOn) THEN                                                 { ALT-N         }
           BEGIN
             i := ((General.CurWindow MOD 5) + 1);
             lStatus_Screen(i,'',FALSE,S);
           END;
      23 : IF (ComPortSpeed > 0) AND (NOT Com_Carrier) THEN                                                 { ALT-I         }
             lStatus_Screen(100,'No carrier detected!',FALSE,S)
           ELSE IF (ComPortSpeed > 0) THEN
           BEGIN
             IF (OutCom) THEN
                IF (InCom) THEN
                  InCom := FALSE
                ELSE IF (Com_Carrier) THEN
                  InCom := TRUE;
             IF (InCom) THEN
               lStatus_Screen(100,'User keyboard ON.',FALSE,S)
             ELSE
               lStatus_Screen(100,'User keyboard OFF.',FALSE,S);
             Com_Flush_Recv;
           END;
      16 : BEGIN                                             { ALT-Q         }
             ChatCall := FALSE;
             ChatReason := '';
             Exclude(ThisUser.ACFlags,Alert);
             Update_Screen;
           END;
      35 : HangUp := TRUE;                                     { ALT-H         }
      24 : BEGIN                                             { ALT-O         }
             ConfSystem := (NOT ConfSystem);
             IF (ConfSystem) THEN
               lStatus_Screen(100,'The conference system has been turned ON.',FALSE,S)
             ELSE
               lStatus_Screen(100,'The conference system has been turned OFF.',FALSE,S);
             NewCompTables;
           END;
     130 : BEGIN                                            { ALT-MINUS     }
             SaveInChat := InChat;
             InChat := TRUE;
             Dec(ThisUser.TLToday,5);
             TLeft;
             InChat := SaveInChat;
           END;
     131 : BEGIN                                                { ALT-PLUS      }
             SaveInChat := InChat;
             InChat := TRUE;
             Inc(ThisUser.TLToday,5);
             TimeWarn := FALSE;
             TLeft;
             InChat := SaveInChat;
           END;
      50 : IF (UserOn) THEN                                                 { ALT-M         }
           BEGIN
             TempSysOp := NOT TempSysOp;
             IF (TempSysOp) THEN
               lStatus_Screen(100,'Temporary SysOp access granted.',FALSE,S)
             ELSE
               lStatus_Screen(100,'Normal access restored',FALSE,S);
             NewCompTables;
           END;

      30 : ToggleWindow(TRUE);                               { ALT-A }
      31 : ToggleWindow(TRUE);                               { ALT-S }

      46 :  IF (NOT InChat) THEN { ALT-C }
              BEGIN
                IF (OkANSI) AND (General.DefSplitChat) THEN
                  SysOpSplitChat
                ELSE
                  SysOpLineChat;
              END
            ELSE
              BEGIN
                InChat := FALSE;
                ChatReason := '';
              END;

      72,                                                  { Arrow up    }
      75,                                                  { Arrow left  }
      77,                                                  { Arrow Right }
      80 : IF ((InChat) OR (Write_Msg)) THEN                                                 { Arrow Down  }
           BEGIN
             IF (OKAvatar) THEN
               Buf := Buf + ^V
             ELSE
               Buf := Buf + ^[+'[';
             CASE Ord(C) OF
               72 : IF (OKAvatar) THEN
                      Buf := Buf + ^C
                    ELSE
                      Buf := Buf + 'A';
               75 : IF (OKAvatar) THEN
                      Buf := Buf + ^E
                    ELSE
                      Buf := Buf + 'D';
               77 : IF (OKAvatar) THEN
                      Buf := Buf + ^F
                    ELSE
                      Buf := Buf + 'C';
               80 : IF (OKAvatar) THEN
                      Buf := Buf + ^D
                    ELSE
                      Buf := Buf + 'B';
             END;
           END;
      22 : IF (ComPortSpeed > 0) AND (OutCom) THEN                                                  { ALT-U         }
           BEGIN
             lStatus_Screen(100,'User screen and keyboard OFF',FALSE,S);
             OutCom := FALSE;
             InCom := FALSE;
           END
           ELSE IF (ComPortSpeed > 0) AND (Com_Carrier) THEN
           BEGIN
             lStatus_Screen(100,'User screen and keyboard ON',FALSE,S);
             OutCom := TRUE;
             InCom := TRUE;
           END;
      37 : BEGIN                                                  { ALT-K        }
             lStatus_Screen(99,'Display what HangUp file (HANGUPxx) :',FALSE,S);
             IF (S <> '') THEN
             BEGIN
               NL;
               NL;
               InCom := FALSE;
               PrintF('HangUp'+S);
               SysOpLog('Displayed HangUp file HangUp'+S);
               HangUp := TRUE;
             END;
             Update_Screen;
           END;
      48 : BEGIN                                                   { ALT-B         }
             BeepEnd := NOT BeepEnd;
             lStatus_Screen(100,'SysOp next '+ShowOnOff(BeepEnd),FALSE,S);
             SaveInChat := InChat;
             InChat := TRUE;
             TLeft;
             InChat := SaveInChat;
           END;
      38 : IF (WantOut) THEN                                                 { ALT-L         }
           BEGIN
             TextColor(11);
             TextBackGround(0);
             Window(1,1,MaxDisplayCols,MaxDisplayRows);
             ClrScr;
             WantOut := FALSE;
             Cursor(FALSE);
           END
           ELSE
           BEGIN
             WantOut := TRUE;
             Cursor(TRUE);
             WriteLn('Local display on.');
             Update_Screen;
           END;
      44 : BEGIN                                                  { ALT-Z         }
             lStatus_Screen(100,'Waking up user ...',FALSE,S);
             REPEAT
               OutKey(^G);
               Delay(500);
               ASM
                Int 28h
               END;
               CheckHangUp;
             UNTIL ((NOT Empty) OR (HangUp));
             Update_Screen;
           END;
      19 : lStatus_Screen(100,'Chat request: '+ChatReason,FALSE,S);{ ALT-R         }
      25 : BEGIN                                             { ALT-P         }
             lStatus_Screen(99,'Print what file: ',FALSE,S);
             IF (S <> '') THEN
             BEGIN
               NL;
               NL;
               PrintF(S);
               SysOpLog('Displayed file '+S);
             END;
             Update_Screen;
           END;
      33 : BEGIN                                                  { ALT-F         }
             Randomize;
             S := '';
             FOR i := 1 TO Random(50) DO
             BEGIN
               C1 := Chr(Random(255));
               IF NOT (C1 IN [#3,'^','@']) THEN
                 S := S + C1;
             END;
             Prompt(S);
          END;
    END;
  END;
  { any processed keys no longer used should be here }
  IF (Ord(C) IN [16..20,22..25,30,32..38,44,47..50,104..108,114,119..131]) THEN
    C := #0;
  TextAttr := SaveTextAttr;
END;

PROCEDURE SaveGeneral(x: Boolean);
VAR
  GeneralF: FILE OF GeneralRecordType;
  SaveCurWindow: Byte;
  SaveWindowOn,
  SaveIsTopWindow: Boolean;
BEGIN
  Assign(GeneralF,DatFilePath+'RENEGADE.DAT');
  Reset(GeneralF);
  IF (x) THEN
  BEGIN
    SaveWindowOn := General.WindowOn;
    SaveIsTopWindow := General.IsTopWindow;
    SaveCurWindow := General.CurWindow;
    Read(GeneralF,General);
    General.WindowOn := SaveWindowOn;
    General.IsTopWindow := SaveIsTopWindow;
    General.CurWindow := SaveCurWindow;
    Inc(General.CallerNum,TodayCallers);
    TodayCallers := 0;
    Inc(General.NumUsers,lTodayNumUsers);
    lTodayNumUsers := 0;
    Seek(GeneralF,0);
  END;
  Write(GeneralF,General);
  Close(GeneralF);
  LastError := IOResult;
END;

PROCEDURE TLeft;
VAR
  SaveWhereX,
  SaveWhereY,
  SaveCurrentColor: Integer;
BEGIN
  IF (TimedOut) OR (TimeLock) THEN
    Exit;
  SaveCurrentColor := CurrentColor;
  IF ((NSL <= 0) AND (ChopTime <> 0)) THEN
  BEGIN
    SysOpLog('Logged user off for system event');
    NL;
    NL;
    Print('^G^8Shutting down for System Event.'^G);
    NL;
    HangUp := TRUE;
  END;
  IF (NOT InChat) AND NOT (FNoCredits IN ThisUser.ACFlags) AND (General.CreditMinute > 0) AND (UserOn) AND (CreditTime > 0) AND
    (AccountBalance > ((NSL DIV 60) + 1) * General.CreditMinute) AND (NOT HangUp) THEN
  BEGIN
    CreditTime := 0;
    IF (AccountBalance < ((NSL DIV 60) + 1) * General.CreditMinute) THEN
      Inc(CreditTime, NSL - (AccountBalance DIV General.CreditMinute) * 60);
  END;
  IF (NOT InChat) AND NOT (FNoCredits IN ThisUser.ACFlags) AND (General.CreditMinute > 0) AND (UserOn) AND
     (AccountBalance < (NSL DIV 60) * General.CreditMinute) AND
     (NOT InVisEdit) AND (NOT HangUp) THEN
  BEGIN
    Print(^M^J^G^G'^8Note: ^9Your online time has been adjusted due to insufficient account balance.');
    Inc(CreditTime, NSL - (AccountBalance DIV General.CreditMinute) * 60);
  END;
  IF (NOT TimeWarn) AND (NOT InChat) AND (NSL < 180) AND (UserOn) AND (NOT InVisEdit) AND (NOT HangUp) THEN
  BEGIN
    Print(^M^J^G^G'^8Warning: ^9You have less than '+IntToStr(NSL DIV 60 + 1)+' '+
          Plural('minute',NSL DIV 60 + 1)+' remaining online!'^M^J);
    SetC(SaveCurrentColor);
    TimeWarn := TRUE;
  END;
  IF (NOT InChat) AND (NSL <= 0) AND (UserOn) AND (NOT HangUp) THEN
  BEGIN
    NL;
    TimedOut := TRUE;
    PrintF('NOTLEFT');
    IF (NoFile) THEN
      Print('^8You have used up all of your time.');
    NL;
    HangUp := TRUE;
  END;
  CheckHangUp;
  IF (WantOut) AND (General.WindowOn) AND (General.CurWindow = 1) AND (NOT InWFCMenu) AND NOT
    (General.NetworkMode AND NOT CoSysOp) AND (LastScreenSwap = 0) THEN
  BEGIN
    TextAttr := 120;
    SaveWhereX := WhereX;
    SaveWhereY := WhereY;
    Window(1,1,MaxDisplayCols,MaxDisplayRows);
    IF (General.IsTopWindow) THEN
      GoToXY(75, 1)
    ELSE
      GoToXY(75,(MaxDisplayRows - 1));
    Write(NSL DIV 60,' ');
    IF (General.IsTopWindow) THEN
      Window(1,3,MaxDisplayCols,MaxDisplayRows)
    ELSE
      Window(1,1,MaxDisplayCols,(MaxDisplayRows - 2));
    GoToXY(SaveWhereX,SaveWhereY);
    TextAttr := SaveCurrentColor;
  END;
END;

PROCEDURE gp(i,j: Integer);
VAR
  x: Byte;
BEGIN
  CASE j OF
    0 : GoToXY(58,8);
    1 : GoToXY(20,7);
    2 : GoToXY(20,8);
    3 : GoToXY(20,9);
    4 : GoToXY(20,10);
    5 : GoToXY(36,7);
    6 : GoToXY(36,8);
  END;
  IF (j IN [1..4]) THEN
    x := 5
  ELSE
    x := 3;
  IF (i = 2) THEN
    Inc(x);
  IF (i > 0) THEN
    GoToXY((WhereX + x),WhereY);
END;

PROCEDURE ChangeUserDataWindow;
VAR
  S: STRING[39];
  C: Char;
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;
  oo,
  i: Integer;
  Changed,
  Done,
  Done1: Boolean;
  {}
  Infield_Out_FGrd,
  Infield_Out_BkGd,
  Infield_Inp_FGrd,
  Infield_Inp_BkGd,
  Infield_Last_Arrow,
  Infield_Last_Normal: Byte;
TYPE
  Infield_Special_Function_Proc_Rec = PROCEDURE(c: Char);

CONST
  Infield_Seperators: SET OF Char = [' ','\','.'];
  Infield_Only_Allow_On: BOOLEAN = FALSE;
  Infield_Arrow_Exit: BOOLEAN = FALSE;
  Infield_Arrow_Exited: BOOLEAN = FALSE;
  Infield_Arrow_Exited_Keep: BOOLEAN = FALSE;
  Infield_Special_Function_On: BOOLEAN = FALSE;
  Infield_Arrow_Exit_TypeDefs: BOOLEAN = FALSE;
  Infield_Normal_Exit_KeyDefs: BOOLEAN = FALSE;
  Infield_Normal_Exited: BOOLEAN = FALSE;

  PROCEDURE infield1(x,y: Byte; VAR s: AStr; Len: Byte);
  VAR
    SaveS: AStr;
    c: Char;
    SaveTextAttr,
    SaveX,
    SaveY: Byte;
    i,
    p,
    z: Integer;
    Ins,
    Done,
    NoKeyYet: BOOLEAN;

    Infield_Special_Function_Proc: Infield_Special_Function_Proc_Rec;
    Infield_Only_Allow,
    Infield_Special_Function_Keys,
    Infield_Arrow_Exit_Types,
    Infield_Normal_Exit_Keys: STRING;

  PROCEDURE GoCPos;
  BEGIN
    GoToXY(x + p - 1,y);
  END;

  PROCEDURE Exit_W_Arrow;
  VAR
    i: Integer;
  BEGIN
    Infield_Arrow_Exited := TRUE;
    Infield_Last_Arrow := Ord(c);
    Done := TRUE;
    IF (Infield_Arrow_Exited_Keep) THEN
    BEGIN
      z := Len;
      FOR i := Len DOWNTO 1 DO
        IF (s[i] = ' ') THEN
          Dec(z)
        ELSE
          i := 1;
      s[0] := chr(z);
    END
    ELSE
      s := SaveS;
  END;

  PROCEDURE Exit_W_Normal;
  VAR
    i: Integer;
  BEGIN
    Infield_Normal_Exited := TRUE;
    Infield_Last_Normal := Ord(c);
    Done := TRUE;
    IF (Infield_Arrow_Exited_Keep) THEN
    BEGIN
      z := Len;
      FOR i := Len DOWNTO 1 DO
        IF (s[i] = ' ') THEN
          Dec(z)
        ELSE
          i := 1;
      s[0] := chr(z);
    END
    ELSE
      s := SaveS;
  END;

BEGIN
  SaveTextAttr := TextAttr;
  SaveX := WhereX;
  SaveY := WhereY;
  SaveS := s;
  Ins := FALSE;
  Done := FALSE;
  Infield_Arrow_Exited := FALSE;
  GoToXY(x,y);
  TextAttr := (Infield_Inp_BkGd * 16) + Infield_Inp_FGrd;
  FOR i := 1 TO Len DO
    Write(' ');
  FOR i := (Length(s) + 1) TO Len DO
    s[i] := ' ';
  GoToXY(x,y);
  Write(s);
  p := 1;
  gocpos;
  NoKeyYet := TRUE;
  REPEAT
    REPEAT
      c := ReadKey
    UNTIL ((NOT Infield_Only_Allow_On) OR
           (Pos(c,Infield_Special_Function_Keys) <> 0) OR
           (Pos(c,Infield_Normal_Exit_Keys) <> 0) OR
           (Pos(c,Infield_Only_Allow) <> 0) OR (c = #0));

    IF ((Infield_Normal_Exit_Keydefs) AND
      (Pos(c,Infield_Normal_Exit_Keys) <> 0)) THEN
        Exit_W_Normal;

    IF ((Infield_Special_Function_On) AND
        (Pos(c,Infield_Special_Function_Keys) <> 0)) THEN
      Infield_Special_Function_Proc(c)
    ELSE
    BEGIN
      IF (NoKeyYet) THEN
      BEGIN
        NoKeyYet := FALSE;
        IF (c IN [#32..#255]) THEN
        BEGIN
          GoToXY(x,y);
          FOR i := 1 TO Len DO
          BEGIN
            Write(' ');
            s[i] := ' ';
          END;
          GoToXY(x,y);
        END;
      END;
      CASE c OF
        #0 : BEGIN
               c := ReadKey;
               IF ((Infield_Arrow_Exit) AND (Infield_Arrow_Exit_TypeDefs) AND
                   (Pos(c,Infield_Arrow_Exit_Types) <> 0)) THEN
                 Exit_W_Arrow
               ELSE
               CASE c OF
                 #72,#80 :
                       IF (Infield_Arrow_Exit) THEN
                         Exit_W_Arrow;
                 #75 : IF (p > 1) THEN
                         Dec(p);
                 #77 : IF (p < Len + 1) THEN
                         Inc(p);
                 #71 : p := 1;
                 #79 : BEGIN
                         z := 1;
                         FOR i := Len DOWNTO 2 DO
                          IF ((s[i - 1] <> ' ') AND (z = 1)) THEN
                            z := i;
                         IF (s[z] = ' ') THEN
                           p := z
                         ELSE
                           p := Len + 1;
                       END;
                 #82 : Ins := NOT Ins;
                 #83 : IF (p <= Len) THEN
                       BEGIN
                         FOR i := p TO (Len - 1) DO
                         BEGIN
                           s[i] := s[i + 1];
                           Write(s[i]);
                         END;
                         s[Len] := ' ';
                         Write(' ');
                       END;
                #115 : IF (p > 1) THEN
                       BEGIN
                         i := (p - 1);
                         WHILE ((NOT (s[i - 1] IN Infield_Seperators)) OR
                               (s[i] IN Infield_Seperators)) AND (i > 1) DO
                           Dec(i);
                         p := i;
                       END;
                #116 : IF (p <= Len) THEN
                       BEGIN
                         i := p + 1;
                         WHILE ((NOT (s[i-1] IN Infield_Seperators)) OR
                               (s[i] IN Infield_Seperators)) AND (i <= Len) DO
                           Inc(i);
                         p := i;
                       END;
                #117 : IF (p <= Len) THEN
                         FOR i := p TO Len DO
                         BEGIN
                           s[i] := ' ';
                           Write(' ');
                         END;
               END;
               gocpos;
             END;
             {
       #27 : BEGIN
               s := SaveS;
               Done := TRUE;
             END;
             }
       #13 : BEGIN
               Done := TRUE;
               z := Len;
               FOR i := Len DOWNTO 1 DO
                IF (s[i] = ' ') THEN
                  Dec(z)
                ELSE
                  i := 1;
               s[0] := chr(z);
             END;
        #8 : IF (p <> 1) THEN
             BEGIN
               Dec(p);
               s[p] := ' ';
               gocpos;
               Write(' ');
               gocpos;
             END;
      ELSE
        IF ((c IN [#32..#255]) AND (p <= Len)) THEN
        BEGIN
          IF ((Ins) AND (p <> Len)) THEN
          BEGIN
            Write(' ');
            FOR i := Len DOWNTO (p + 1) DO
              s[i] := s[i - 1];
            FOR i := (p + 1) TO Len DO
              Write(s[i]);
            gocpos;
          END;
          Write(c);
          s[p] := c;
          Inc(p);
        END;
      END;
    END;
  UNTIL (Done);
  GoToXY(x,y);
  TextAttr := (Infield_Out_BkGd * 16) + Infield_Out_FGrd;
  FOR i := 1 TO Len DO
    Write(' ');
  GoToXY(x,y);
  Write(s);
  GoToXY(SaveX,SaveY);
  TextAttr := SaveTextAttr;
  Infield_Only_Allow_On := FALSE;
  Infield_Special_Function_On := FALSE;
  Infield_Normal_Exit_Keydefs := FALSE;
END;

{*
 *  ÚÄÄÄ¿   ÉÍÍÍ»   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÖÄÄÄ·  ÕÍÍÍ¸
 *  ³ 1 ³   º 2 º   ° 3 °   ± 4 ±   ² 5 ²   Û 6 Û   º 7 º  ³ 8 ³
 *  ÀÄÄÄÙ   ÈÍÍÍ¼   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÓÄÄÄ½  ÔÍÍÍ¾
 *}

PROCEDURE Box(LineType,TLX,TLY,BRX,BRY: Integer);
VAR
  TL,TR,BL,BR,HLine,VLine: Char;
  i: Integer;
BEGIN
  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  CASE LineType OF
    1 : BEGIN
          TL := #218;
          TR := #191;
          BL := #192;
          BR := #217;
          VLine := #179;
          HLine := #196;
        END;
    2 : BEGIN
          TL := #201;
          TR := #187;
          BL := #200;
          BR := #188;
          VLine := #186;
          HLine := #205;
        END;
    3 : BEGIN
          TL := #176;
          TR := #176;
          BL := #176;
          BR := #176;
          VLine := #176;
          HLine := #176;
        END;
    4 : BEGIN
          TL := #177;
          TR := #177;
          BL := #177;
          BR := #177;
          VLine := #177;
          HLine := #177;
        END;
    5 : BEGIN
          TL := #178;
          TR := #178;
          BL := #178;
          BR := #178;
          VLine := #178;
          HLine := #178;
        END;
    6 : BEGIN
          TL := #219;
          TR := #219;
          BL := #219;
          BR := #219;
          VLine := #219;
          HLine := #219;
        END;
    7 : BEGIN
          TL := #214;
          TR := #183;
          BL := #211;
          BR := #189;
          VLine := #186;
          HLine := #196;
        END;
    8 : BEGIN
          TL := #213;
          TR := #184;
          BL := #212;
          BR := #190;
          VLine := #179;
          HLine := #205;
        END;
    ELSE
    BEGIN
      TL := #32;
      TR := #32;
      BL := #32;
      BR := #32;
      VLine := #32;
      HLine := #32;
    END;
  END;
  GoToXY(TLX,TLY);
  Write(TL);
  GoToXY(BRX,TLY);
  Write(TR);
  GoToXY(TLX,BRY);
  Write(BL);
  GoToXY(BRX,BRY);
  Write(BR);
  FOR i := (TLX + 1) TO (BRX - 1) DO
  BEGIN
    GoToXY(i,TLY);
    Write(HLine);
  END;
  FOR i := (TLX + 1) TO (BRX - 1) DO
  BEGIN
    GoToXY(i,BRY);
    Write(HLine);
  END;
  FOR i := (TLY + 1) TO (BRY - 1) DO
  BEGIN
    GoToXY(TLX,i);
    Write(VLine);
  END;
  FOR i := (TLY + 1) TO (BRY - 1) DO
  BEGIN
    GoToXY(BRX,I);
    Write(VLine);
  END;
  IF (LineType > 0) THEN
    Window((TLX + 1),(TLY + 1),(BRX - 1),(BRY - 1))
  ELSE
    Window(TLX,TLY,BRX,BRY);
END;

  {}

  PROCEDURE Shd(i: Integer; b: Boolean);
  VAR
    C1: Char;
    Counter: Byte;
  BEGIN
    gp(0,i);
    IF (b) THEN
      TextColor(Scheme.Color[1])
    ELSE
      TextColor(Scheme.Color[1]);
    CASE i OF
      1 : Write('SL  :');
      2 : Write('DSL :');
      3 : Write('Crdt:');
      4 : Write('Note:');
      5 : Write('AR:');
      6 : Write('AC:');
    END;
    IF (b) THEN
      BEGIN
        TextColor(Scheme.Color[6]);
        TextBackGround(7);
      END
    ELSE
      TextColor(Scheme.Color[2]); {field values}
    Write(' ');
    WITH ThisUser DO
      CASE i OF
        0 : IF (b) THEN
              BEGIN { Selected }
                TextColor(15);
                Write('[DONE]')
              END
            ELSE
              BEGIN { Not Selected }
                TextColor(7);
                Write('[DONE]');
              END;
        1 : Write(PadLeftInt(SL,3));
        2 : Write(PadLeftInt(DSL,3));
        3 : Write(PadLeftInt(AccountBalance,5));
        4 : Write(PadLeftStr(Note,39));
        5 : FOR C1 := 'A' TO 'Z' DO
              BEGIN
                IF (C1 IN ARFlags) THEN
                  TextColor(4)
                ELSE IF (b) THEN
                  TextColor(0)
                ELSE
                  TextColor(7);
                Write(C1);
              END;
        6 : IF (b) THEN
              CPR(116,112) { Selected }
              { LeeW: First is color for enabled flag
                      Second is color for disabled flag }
            ELSE
              CPR(4,7); { Not Selected }
      END;
    Write(' ');
    TextBackGround(0);
    Cursor(i IN [1..4]);
    IF (b) THEN
      BEGIN
        GoToXY(26,12);
        TextColor(Scheme.Color[2]);
        FOR Counter := 1 TO 41 DO
          Write(' ');
        GoToXY(26,12);
        CASE i OF
          0 : Write('Exit User Editor');
          1 : Write('Security Level (0-255)');
          2 : Write('Download Security Level (0-255)');
          3 : Write('Account Credit Balance');
          4 : Write('SysOp Note');
          5 : Write('Access Flags '#196#196' (!) Clear');
          6 : Write('Restrictions & Privileges '#196#196' (!) Clear');
        END;
      END;
  END;

  PROCEDURE DDWind;
  VAR
    Counter: Byte;
  BEGIN
    Cursor(FALSE);
    TextColor(Scheme.Color[5]); { Border Color }
    Box(1,18,6,68,13);
    Window(19,7,67,12);
    ClrScr;
    Box(1,18,6,68,11);
    Window(19,7,67,10);
    Window(1,1,MaxDisplayCols,MaxDisplayRows);
    GoToXY(20,12);
    TextColor(Scheme.Color[1]); { "Desc:" Text }
    Write('Desc:');
    FOR Counter := 0 TO 6 DO
      Shd(Counter,FALSE);
    Shd(oo,TRUE);
  END;

BEGIN
  SaveURec(ThisUser,UserNum);
  Infield_Out_Fgrd := 0;
  Infield_Out_Bkgd := 7;
  InField_Inp_Fgrd := 15;
  InField_Inp_Bkgd := 7;
  Infield_Arrow_Exit := TRUE;
  Infield_Arrow_Exited := FALSE;
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextAttr := TextAttr;
  TextAttr := 7;
  oo := 1;
  ddwind;
  Done := FALSE;
  REPEAT
    Infield_Arrow_Exited := FALSE;
    CASE oo OF
      0 : BEGIN
      {indent to here}
              Done1 := FALSE;
              Shd(oo,TRUE);
              REPEAT
                C := ReadKey;
                CASE UpCase(C) OF
                  ^M :  BEGIN
                          Done := TRUE;
                          Done1 := TRUE;
                        END;
                  #0 :  BEGIN
                          C := ReadKey;
                          CASE Ord(C) OF
                            80,72 : {Arrow Down, Up}
                              BEGIN
                                Infield_Arrow_Exited := TRUE;
                                Infield_Last_Arrow := Ord(C);
                                Done1 := TRUE;
                              END;
                          END;
                        END;
                END;
              UNTIL (Done1);
            END;
        1 : BEGIN
              S := IntToStr(ThisUser.SL);
              InField1(26,7,S,3);
              IF (StrToInt(S) <> ThisUser.SL) THEN
                IF (StrToInt(S) >= 0) AND (StrToInt(S) <= 255) THEN
                  BEGIN
                    ThisUser.SL := StrToInt(S);
                    Inc(ThisUser.TLToday,General.TimeAllow[ThisUser.SL] - General.TimeAllow[ThisUser.SL]);
                  END;
            END;
        2 : BEGIN
              S := IntToStr(ThisUser.DSL);
              InField1(26,8,S,3);
              IF (StrToInt(S) <> ThisUser.DSL) THEN
                IF (StrToInt(S) >= 0) AND (StrToInt(S) <= 255) THEN
                  ThisUser.DSL := StrToInt(S);
            END;
        3 : BEGIN
              S := IntToStr(AccountBalance);
              InField1(26,9,S,5);
              AdjustBalance(AccountBalance - StrToInt(S));
            END;
        4 : BEGIN
              S := ThisUser.Note;
              InField1(26,10,S,39);
              ThisUser.Note := S;
            END;
        5 : BEGIN
              Done1 := FALSE;
              REPEAT
                C := UpCase(ReadKey);
                CASE C OF
                  #13 : Done1 := TRUE;
                  #0  : BEGIN
                          C := ReadKey;
                          CASE Ord(C) OF
                            80,72 : {Arrow Up, Down}
                              BEGIN
                                Infield_Arrow_Exited := TRUE;
                                Infield_Last_Arrow := Ord(C);
                                Done1 := TRUE;
                              END;
                          END;
                        END;
                  '!' : BEGIN
                          FOR C := 'A' TO 'Z' DO
                            {ToggleARFlag(C,ThisUser.AR,Changed);}
                            Exclude(ThisUser.ARFlags,C);
                            Shd(oo,TRUE);
                        END;
                  'A'..'Z' :
                        BEGIN
                          ToggleARFlag(C,ThisUser.ARFlags,Changed);
                          Shd(oo,TRUE);
                        END;
                END;
              UNTIL (Done1);
            END;
        6 : BEGIN
              S := 'LCVUA*PEKM1234';
              Done1 := FALSE;
              REPEAT
                C := UpCase(ReadKey);
                IF (C = #13) THEN
                  Done1 := TRUE
                ELSE IF (C = #0) THEN
                  BEGIN
                    C := ReadKey;
                    CASE Ord(C) OF
                      80,72: {Arrow Down, Up}
                        BEGIN
                          Infield_Arrow_Exited := TRUE;
                          Infield_Last_Arrow := Ord(C);
                          Done1 := TRUE;
                        END;
                    END;
                  END
                ELSE IF (Pos(C,S) <> 0) THEN
                  BEGIN
                    ToggleACFlags(C,ThisUser.ACFlags,Changed);
                    Shd(oo,TRUE);
                  END
                ELSE
                  BEGIN
                    IF (C = '!') THEN
                      FOR i := 1 TO Length(S) DO
                        {ToggleACFlags(S[i],ThisUser.Flags,Changed);}
                        Exclude(ThisUser.ACFlags,TACCH(S[i]));
                        Shd(oo,TRUE);
                  END;
              UNTIL (Done1);
            END;
      END;
      IF (NOT Infield_Arrow_Exited) THEN
        BEGIN
          Infield_Arrow_Exited := TRUE;
          Infield_Last_Arrow := 80;  {arrow down}
        END;
      IF (Infield_Arrow_Exited) THEN
        CASE Infield_Last_Arrow OF
          80,72 :
            BEGIN     {arrow down,up}
              Shd(oo,FALSE);
              IF (Infield_Last_Arrow = 80) THEN
                BEGIN  {arrow down}
                  Inc(oo);
                  IF (oo > 6) THEN
                    oo := 0;
                END
              ELSE
                BEGIN
                  Dec(oo);
                  IF (oo < 0) THEN
                    oo := 6;
                END;
              Shd(oo,TRUE);
            END;
        END;
    UNTIL (Done);
    GoToXY(SaveWhereX,SaveWhereY);
    TextAttr := SaveTextAttr;
    Cursor(TRUE);
    NewCompTables;
    SaveURec(ThisUser,UserNum);
END;

END.