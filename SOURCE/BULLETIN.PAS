{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
UNIT Bulletin;
{
Lee Woodridge
 09/28/2021 Fixed lastcaller ~TO MCI. Now displays "-" if user hasn't logged off yet
}
INTERFACE

USES
  Common;

FUNCTION FindOnlyOnce: Boolean;
FUNCTION NewBulletins: Boolean;
PROCEDURE Bulletins(MenuOption: Str50);
PROCEDURE UList(MenuOption: Str50);
PROCEDURE TodaysCallers(x: Byte; MenuOptions: Str50);
PROCEDURE RGQuote(MenuOption: Str50);

IMPLEMENTATION

USES
  Dos,
  Common5,
  Mail1,
  ShortMsg,
  TimeFunc;

TYPE
  LastCallerPtrType = ^LastCallerRec;
  UserPtrType = ^UserRecordType;

PROCEDURE Bulletins(MenuOption: Str50);
VAR
  Main,
  Subs,
  InputStr: ASTR;
BEGIN
  NL;
  IF (MenuOption = '') THEN
    IF (General.BulletPrefix = '') THEN
      MenuOption := 'BULLETIN;BULLET'
    ELSE
      MenuOption := 'BULLETIN;'+General.BulletPrefix;
  IF (Pos(';',MenuOption) <> 0) THEN
  BEGIN
    Main := Copy(MenuOption,1,(Pos(';',MenuOption) - 1));
    Subs := Copy(MenuOption,(Pos(';',MenuOption) + 1),(Length(MenuOption) - Pos(';',MenuOption)));
  END
  ELSE
  BEGIN
    Main := MenuOption;
    Subs := MenuOption;
  END;
  PrintF(Main);
  IF (NOT NoFile) THEN
    REPEAT
      NL;
      { Prt(FString.BulletinLine); }
      lRGLngStr(16,FALSE);
      ScanInput(InputStr,'ABCDEFGHIJKLMNOPQRSTUVWXYZ?');
      IF (NOT HangUp) THEN
      BEGIN
        IF (InputStr = '?') THEN
          PrintF(Main);
        IF (InputStr <> '') AND NOT (InputStr[1] IN ['Q','?']) THEN
          PrintF(Subs+InputStr);
      END;
    UNTIL (InputStr = 'Q') OR (HangUp);
END;

FUNCTION FindOnlyOnce: Boolean;
VAR
 {DirInfo: SearchRec;}
  DT: DateTime;
BEGIN
  FindOnlyOnce := FALSE;
  FindFirst(General.MiscPath+'ONLYONCE.*',AnyFile - Directory - VolumeID- DOS.Hidden,DirInfo);
  IF (DosError = 0) THEN
  BEGIN
    UnPackTime(DirInfo.Time,DT);
    IF (DateToPack(DT) > ThisUser.LastOn) THEN
      FindOnlyOnce := TRUE;
  END;
END;

FUNCTION NewBulletins: Boolean;
TYPE
  BulletinType = ARRAY [0..255] OF Byte;
VAR
  BulletinArray: ^BulletinType;
  DT: DateTime;
 {DirInfo: SearchRec;}
  BullCount,
  Biggest,
  LenOfBullPrefix,
  LenToCopy: Byte;
  Found: Boolean;

  PROCEDURE ShowBulls;
  VAR
    Counter,
    Counter1,
    Counter2: Byte;
  BEGIN
    FOR Counter := 0 TO BullCount DO
    BEGIN
      FOR Counter1 := 0 TO BullCount DO
        IF (BulletinArray^[Counter] < BulletinArray^[Counter1]) THEN
        BEGIN
          Counter2 := BulletinArray^[Counter];
          BulletinArray^[Counter] := BulletinArray^[Counter1];
          BulletinArray^[Counter1] := Counter2;
        END;
    END;
    Counter1 := 1;
    Prt('|01[ |11');
    FOR Counter2 := 0 TO (BullCount) DO
    BEGIN
      IF (Counter1 = 15) THEN
      BEGIN
        Prt(PadRightInt(BulletinArray^[Counter2],2));
        IF (Counter2 < BullCount) THEN
          Prt(' |01]'+^M^J+'|01[ |11')
        ELSE
          Prt(' |01]');
        Counter1 := 0;
      END
      ELSE
      BEGIN
        Prt(PadRightInt(BulletinArray^[Counter2],2));
        IF (Counter2 < BullCount) THEN
          Prt('|07,|11 ')
        ELSE
          Prt(' |01]');
      END;
      Inc(Counter1);
    END;
    NL;
 END;

BEGIN
  New(BulletinArray);
  FOR BullCount := 0 TO 255 DO
    BulletinArray^[BullCount] := 0;
  Found := FALSE;
  Biggest := 0;
  BullCount := 0;
  LenOfBullPrefix := (Length(General.BulletPrefix) + 1);
  FindFirst(General.MiscPath+General.BulletPrefix+'*.ASC',AnyFile - Directory - VolumeID - DOS.Hidden,DirInfo);
  WHILE (DosError = 0) DO
  BEGIN
    IF (((Pos(General.BulletPrefix,General.MiscPath+General.BulletPrefix+'*.ASC') > 0) AND
       (Pos('BULLETIN',AllCaps(DirInfo.Name)) = 0)) AND
       (Pos('~',DirInfo.Name) = 0)) THEN
    BEGIN
      UnPackTime(DirInfo.Time,DT);
      IF (DateToPack(DT) > ThisUser.LastOn) THEN
      BEGIN
        Found := TRUE;
        LenToCopy := (Pos('.',DirInfo.Name) - 1) - Length(General.BulletPrefix);
        BulletinArray^[BullCount] := StrToInt(Copy(DirInfo.Name,LenOfBullPrefix,LenToCopy));
        IF (BulletinArray^[BullCount] > Biggest) THEN
          Biggest := BulletinArray^[BullCount];
        Inc(BullCount);
      END;
    END;
    IF (BullCount > 254) THEN
      Exit;
    FindNext(DirInfo);
  END;
  IF (Found) THEN
  BEGIN
    Dec(BullCount);
    ShowBulls;
  END;
  Dispose(BulletinArray);
  NewBulletins := Found;
END;

FUNCTION UlistMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  UserPtr: UserPtrType;
BEGIN
  UlistMCI := S;
  UserPtr := Data1;
  CASE S[1] OF
    'A' : CASE S[2] OF
            'G' : UListMCI := IntToStr(AgeUser(UserPtr^.BirthDate));
          END;
    'D' : CASE S[2] OF
            'K' : UListMCI := IntToStr(UserPtr^.DK);
            'L' : UListMCI := IntToStr(UserPtr^.Downloads);
          END;
    'L' : CASE S[2] OF
            'C' : UListMCI := UserPtr^.CityState;
            'O' : UListMCI := ToDate8(PD2Date(UserPtr^.LastOn));
          END;
    'M' : CASE S[2] OF
            'P' : UListMCI := IntToStr(UserPtr^.MsgPost);
          END;
    'N' : CASE S[2] OF
            'O' : UListMCI := Userptr^.Note;
          END;
    'R' : CASE S[2] OF
            'N' : UListMCI := UserPtr^.RealName;
          END;
    'S' : CASE S[2] OF
            'X' : UListMCI := UserPtr^.Sex;
          END;
    'U' : CASE S[2] OF
            'K' : UListMCI := IntToStr(UserPtr^.UK);
            'L' : UListMCI := IntToStr(UserPtr^.Uploads);
            'N' : UListMCI := Caps(UserPtr^.Name);
            '1' : UListMCI := UserPtr^.UsrDefStr[1];
            '2' : UListMCI := UserPtr^.UsrDefStr[2];
            '3' : UListMCI := UserPtr^.UsrDefStr[3];
          END;
  END;
END;

PROCEDURE UList(MenuOption: Str50);
VAR
  Junk: Pointer;
  User: UserRecordType;
  Cmd: Char;
  TempStr: ASTR;
  Gender: Str1;
  State,
  UState: Str2;
  Age: Str3;
  DateLastOn: Str8;
  City,
  UCity: Str30;
  RName,
  UName: Str36;
  FN: Str50;
  RecNum: Integer;

  PROCEDURE Option(c1: Char; s1,s2: Str160);
  BEGIN
    Prompt('^2<^1'+c1+'^2>'+s1+': ');
    IF (s2 <> '') THEN
      Print('^1"^2'+s2+'^1"^0')
    ELSE
      Print('^1<<INACTIVE>>^0');
  END;

BEGIN
  IF (RUserList IN ThisUser.ACFlags) THEN
  BEGIN
    Print('You are restricted from listing users.');
    Exit;
  END;
  Age := '';
  City := '';
  DateLastOn := '';
  Gender := '';
  RName := '';
  State := '';
  UName := '';
  REPEAT
    NL;
    Print('^1User lister search options:');
    NL;
    Option('A','ge match string             ',Age);
    Option('C','ity match string            ',City);
    Option('D','ate last online match string',DateLastOn);
    Option('G','ender match string          ',Gender);
    Option('R','eal name match string       ',RName);
    Option('S','tate match string           ',State);
    Option('U','ser name match string       ',UName);
    NL;
    Prompt('^2Enter choice (^1A^2,^1C^2,^1D^2,^1G^2,^1R^2,^1S^2,^1U^2) [^1L^2]ist [^1Q^2]uit: ');
    LOneK('',Cmd,'QACDGLRSU'^M,TRUE,TRUE);
    NL;
    IF (Cmd IN ['A','C','D','G','R','S','U']) THEN
    BEGIN
      TempStr := 'Enter new match string for the ';
      CASE Cmd OF
        'A' : TempStr := TempStr + 'age';
        'C' : TempStr := TempStr + 'city';
        'D' : TempStr := TempStr + 'date last online';
        'G' : TempStr := TempStr + 'gender';
        'R' : TempStr := TempStr + 'real name';
        'S' : TempStr := TempStr + 'state';
        'U' : TempStr := TempStr + 'user name';
      END;
      TempStr := TempStr + ' (<CR>=Make INACTIVE)';
      Print('^2'+TempStr);
      Prompt('^2: ');
    END;
    CASE Cmd OF
      'A' : BEGIN
              Mpl(3);
              InputMain(Age,SizeOf(Age)-1,[CapAll]);
            END;
      'C' : BEGIN
              Mpl(30);
              InputMain(City,SizeOf(City)-1,[CapAll]);
            END;
      'D' : BEGIN
              Mpl(8);
              InputFormatted('',DateLastOn,'##/##/##',TRUE);
              IF (DayNum(DateLastOn) <> 0) AND (DayNum(DateLastOn) <= DayNum(DateStr)) THEN
              BEGIN
                Delete(DateLastOn,3,1);
                Insert('-',DateLastOn,3);
                Delete(DateLastOn,6,1);
                Insert('-',DateLastOn,6);
              END;
            END;
      'G' : BEGIN
              Mpl(1);
              InputMain(Gender,SizeOf(Gender)-1,[CapAll]);
            END;
      'R' : BEGIN
              Mpl(36);
              InputMain(RName,SizeOf(RName)-1,[CapAll]);
            END;
      'S' : BEGIN
              Mpl(2);
              InputMain(State,SizeOf(State)-1,[CapAll]);
            END;
      'U' : BEGIN
              Mpl(36);
              InputMain(UName,SizeOf(UName)-1,[CapAll]);
            END;
    END;
  UNTIL (Cmd IN ['L','Q',^M]) OR (HangUp);
  IF (Cmd IN ['L',^M]) THEN
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    AllowContinue := TRUE;
    IF (Pos(';',MenuOption) > 0) THEN
    BEGIN
      FN := Copy(MenuOption,(Pos(';',MenuOption) + 1),255);
      MenuOption := Copy(MenuOption,1,(Pos(';',MenuOption) - 1));
    END
    ELSE
      FN := 'USER';
    IF (NOT ReadBuffer(FN+'M')) THEN
      Exit;
    PrintF(FN+'H');
    {LeeW: Add fallback}
    Reset(UserFile);
    RecNum := 1;
    WHILE (RecNum <= (FileSize(UserFile) - 1)) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      LoadURec(User,RecNum);
      UCity := (Copy(User.CityState,1,(Pos(',',User.CityState) - 1)));
      UState := SQOutSP((Copy(User.CityState,(Pos(',',User.CityState) + 2),(Length(User.CityState)))));
      IF (AACS1(User,RecNum,MenuOption)) AND NOT (Deleted IN User.SFlags) THEN
        IF (Age = '') OR (Pos(Age,IntToStr(AgeUser(User.BirthDate))) > 0) THEN
          IF (City = '') OR (Pos(City,AllCaps(UCity)) > 0) THEN
            IF (DateLastOn = '') OR (Pos(DateLastOn,ToDate8(PD2Date(User.LastOn))) > 0) THEN
              IF (Gender = '') OR (Pos(Gender,User.Sex) > 0) THEN
                IF (RName = '') OR (Pos(RName,AllCaps(User.RealName)) > 0) THEN
                  IF (State = '') OR (Pos(State,AllCaps(UState)) > 0) THEN
                     IF (UName = '') OR (Pos(UName,User.Name) > 0) THEN
                        DisplayBuffer(UlistMCI,@User,Junk);
      Inc(RecNum);
    END;
    Close(UserFile);
    IF (NOT Abort) AND (NOT HangUp) THEN
      PrintF(FN+'T');
    AllowContinue := FALSE;
  END;
  SysOpLog('Viewed User Listing.');
  LastError := IOResult;
END;

FUNCTION TodaysCallerMCI(CONST S: ASTR; Data1,Data2: Pointer): STRING;
VAR
  LastCallerPtr: LastCallerPtrType;
  s1: STRING[100];
BEGIN
  LastCallerPtr := Data1;
  TodaysCallerMCI := S;
  CASE S[1] OF
    'C' : CASE S[2] OF
            'A' : TodaysCallerMCI := FormatNumber(LastCallerPtr^.Caller);
          END;
    'D' : CASE S[2] OF
            'K' : TodaysCallerMCI := IntToStr(LastCallerPtr^.DK);
            'L' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Downloads);
          END;
    'E' : CASE S[2] OF
            'S' : TodaysCallerMCI := IntToStr(LastCallerPtr^.EmailSent);
          END;
    'F' : CASE S[2] OF
            'S' : TodaysCallerMCI := IntToStr(LastCallerPtr^.FeedbackSent);
          END;
    'L' : CASE S[2] OF
            'C' : TodaysCallerMCI := LastCallerPtr^.Location;
            'O' : BEGIN
                    s1 := PDT2Dat(LastCallerPtr^.LogonTime,0);
                    s1[0] := Char(Pos('m',s1) - 2);
                    s1[Length(s1)] := s1[Length(s1) + 1];
                    TodaysCallerMCI := s1;
                  END;
            'T' : BEGIN
                    IF (LastCallerPtr^.LogoffTime = 0) THEN
                      S1 := 'Online'
                    ELSE
                    BEGIN
                      s1 := PDT2Dat(LastCallerPtr^.LogoffTime,0);
                      s1[0] := Char(Pos('m',s1) - 2);
                      s1[Length(s1)] := s1[Length(s1) + 1];
                    END;
                    TodaysCallerMCI := s1;
                  END;
          END;
    'M' : CASE S[2] OF
            'P' : TodaysCallerMCI := IntToStr(LastCallerPtr^.MsgPost);
            'R' : TodaysCallerMCI := IntToStr(LastCallerPtr^.MsgRead);
          END;
    'N' : CASE S[2] OF
            'D' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Node);
            'U' : IF (LastCallerPtr^.NewUser) THEN
                    TodaysCallerMCI := '*'
                  ELSE
                    TodaysCallerMCI := ' ';
          END;
    'S' : CASE S[2] OF
            'P' : IF (LastCallerPtr^.Speed = 0) THEN
                    TodaysCallerMCI := 'Local'
                  ELSE IF (Telnet) THEN
                    TodaysCallerMCI := 'Telnet'
                  ELSE
                    TodaysCallerMCI := IntToStr(LastCallerPtr^.Speed);
          END;
    'T' : CASE S[2] OF
            'O' : WITH LastCallerPtr^ DO
                    IF (LogOffTime=0) THEN
                      TodaysCallerMCI := '-'
                    ELSE
                      TodaysCallerMCI := IntToStr((LogoffTime - LogonTime) DIV 60);
          END;
    'U' : CASE S[2] OF
            'K' : TodaysCallerMCI := IntToStr(LastCallerPtr^.UK);
            'L' : TodaysCallerMCI := IntToStr(LastCallerPtr^.Uploads);
            'N' : TodaysCallerMCI := LastCallerPtr^.UserName;
          END;
  END;
END;

PROCEDURE TodaysCallers(x: Byte; MenuOptions: Str50);
VAR
  Junk: Pointer;
  LastCallerFile: FILE OF LastCallerRec;
  LastCaller: LastCallerRec;
  RecNum: Integer;
BEGIN
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  IF (MenuOptions = '') THEN
    MenuOptions := 'LAST';
  IF (NOT ReadBuffer(MenuOptions+'M')) THEN
    Exit;
  Assign(LastCallerFile,General.DataPath+'LASTON.DAT');
  Reset(LastCallerFile);
  IF (IOResult <> 0) THEN
    Exit;
  RecNum := 0;
  IF (x > 0) AND (x <= FileSize(LastCallerFile)) THEN
    RecNum := (FileSize(LastCallerFile) - x);
  PrintF(MenuOptions+'H');
  {LeeW: Add fallback}
  Seek(LastCallerFile,RecNum);
  WHILE (NOT EOF(LastCallerFile)) AND (NOT Abort) AND (NOT HangUp) DO
  BEGIN
    Read(LastCallerFile,LastCaller);
    IF (((LastCaller.LogonTime DIV 86400) <> (GetPackDateTime DIV 86400)) AND (x > 0)) OR
       (((LastCaller.LogonTime DIV 86400) = (GetPackDateTime DIV 86400))) AND (NOT LastCaller.Invisible) THEN
      DisplayBuffer(TodaysCallerMCI,@LastCaller,Junk);
  END;
  Close(LastCallerFile);
  IF (NOT Abort) THEN
    PrintF(MenuOptions+'T');
  AllowContinue := FALSE;
  
  SysOpLog('Viewed todays callers'+AOnOff(InWFCMenu,' from WFC menu',''));
  LastError := IOResult;
END;

PROCEDURE RGQuote(MenuOption: Str50);
VAR
  StrPointerFile: FILE OF StrPointerRec;
  StrPointer: StrPointerRec;
  RGStrFile: FILE;
  F,
  F1: Text;
  MHeader: MHeaderRec;
  S: STRING;
  StrNum: Word;
  TotLoad: LongInt;
BEGIN
  IF (MenuOption = '') THEN
    Exit;
  Assign(StrPointerFile,General.TextPath+MenuOption+'.PTR');
  Reset(StrPointerFile);
  TotLoad := FileSize(StrPointerFile);
  IF (TotLoad < 1) THEN
    Exit;
  IF (TotLoad > 65535) THEN
    TotLoad := 65535
  ELSE
    Dec(TotLoad);
  Randomize;
  StrNum := Random(TotLoad);
  Seek(StrPointerFile,StrNum);
  Read(StrPointerFile,StrPointer);
  Close(StrPointerFile);
  LastError := IOResult;
  IF (Exist(General.MiscPath+'QUOTEH.*')) THEN
    PrintF('QUOTEH')
  ELSE
	BEGIN
      NL;
      Print('|03[컴컴컴컴컴컴컴컴컴컴컴? |11And Now |03... |11A Quote For You! |03]컴컴컴컴컴컴컴컴컴컴컴]');
      NL;
    END;
  TotLoad := 0;
  Assign(RGStrFile,General.TextPath+MenuOption+'.DAT');
  Reset(RGStrFile,1);
  Seek(RGStrFile,(StrPointer.Pointer - 1));
  REPEAT
    BlockRead(RGStrFile,S[0],1);
    BlockRead(RGStrFile,S[1],Ord(S[0]));
    Inc(TotLoad,(Length(S) + 1));
    IF (S[Length(S)] = '@') THEN
      BEGIN
        Dec(S[0]);
        Prt(Centre(S));
      END
    ELSE
      PrintACR(Centre(S));
  UNTIL (TotLoad >= StrPointer.TextSize) OR EOF(RGStrFile) OR (HangUp);
  Close(RGStrFile);
  LastError := IOResult;
  IF (Exist(General.MiscPath+'QUOTET.*')) THEN
    PrintF('QUOTET')
  ELSE
	BEGIN
      NL;
      Print('|03[컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴?');
      NL;
	END;
  IF (NOT General.UserAddQuote) THEN
    PauseScr(FALSE)
  ELSE IF (PYNQ(lRGLngStr(179,TRUE),0,FALSE)) AND (NOT HangUp) THEN {"Would you like to add a quote?"}
	BEGIN
      PrintF('QUOTEADD');
      InResponseTo := '';
      MHeader.Status := [];
      IF (InputMessage(TRUE,FALSE,'New Quote',MHeader,General.TextPath+MenuOption+'.TMP',78,500)) then
		IF Exist(General.TextPath+MenuOption+'.TMP') THEN
		  BEGIN
			Assign(F,General.TextPath+MenuOption+'.NEW');
			Reset(F);
			IF (IOResult <> 0) THEN
			  ReWrite(F)
			ELSE
			  Append(F);
			Assign(F1,General.TextPath+MenuOption+'.TMP');
			Reset(F1);
			IF (IOResult <> 0) THEN
			  Exit;
			WriteLn(F,'New quote from: '+Caps(ThisUser.Name)+' #'+IntToStr(UserNum)+'.');
			WriteLn(F,'');
			WriteLn(F,'$');
			WHILE (NOT EOF(F1)) DO
			  BEGIN
				ReadLn(F1,S);
				WriteLn(F,S);
			  END;
			WriteLn(F,'$');
			WriteLn(F,'');
			WriteLn(F);
			Close(F);
			Close(F1);
			Kill(General.TextPath+MenuOption+'.TMP');
			NL;
			lRGLngStr(155,FALSE); {"Saved!"} {Print('^9Your quote has been saved!');}
			PauseScr(FALSE);
			SendShortMessage(1,Caps(ThisUser.Name)+' added a new quote to "'+MenuOption+'.NEW".');
		  END;
	END;
END;

END.
