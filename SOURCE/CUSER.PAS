{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
procs done except for country, city&st, zip, ph,,--need to redo country before these, 
  oh and termemu, probably removing everything except ansi
  and lightbars because of data file changes


which input cmd is best to be using!?!? will need to update input cmd once i figure out
CStuff calls have been updated, might need to change how in some of them, maint will be =1 for mandatory
}
UNIT CUser;

INTERFACE

USES
  Common;

PROCEDURE CStuff(Which,How: Byte; VAR User: UserRecordType);

IMPLEMENTATION

USES
  DOS,
  Archive1,
  MiscUser,
  TimeFunc;

VAR
  CallFromArea: Integer;
  Changed: Boolean;

PROCEDURE CStuff(Which,How: Byte; VAR User: UserRecordType);
VAR
  Tries: Byte;
  Done1: Boolean;

  PROCEDURE AskCountry;
  VAR
    TmpCountry: Char;
  BEGIN
    Print('Are you calling from:');
    NL;
    Print('(1) United States');
    Print('(2) Canada');
    Print('(3) Other country');
    NL;
    Prt('Select (1-3): ');
    OneK(TmpCountry,'123',TRUE,TRUE);
    CallFromArea := (Ord(TmpCountry) - 48);
    Done1 := TRUE;
  END;

  PROCEDURE AskCityState;
  VAR
    s,
    s1,
    s2: AStr;
  BEGIN
    CASE How OF
      1 : IF CallFromArea = 0 THEN { New user application }
            AskCountry;
      2 : AskCountry; { 'OP' Menu command }
      3 : CallFromArea := 1; { User editor or maintenance }
    END;
    IF (CallFromArea <> 3) THEN
    BEGIN
      IF (How = 3) THEN
      BEGIN
        Print('Enter new city & state abbreviation:');
        Prt(': ');
        MPL((SizeOf(User.CityState) - 1));
        InputL(s,(SizeOf(User.CityState) - 1));
        IF (s <> '') THEN
          User.CityState := s;
        Done1 := TRUE;
        Exit;
      END;

      Print('Enter only your city:');
      Prt(': ');
      MPL(((SizeOf(User.CityState) - 1) - 4));
      InputCaps(s,((SizeOf(User.CityState) - 1) - 4));
      IF (Pos(',',s) <> 0) THEN
      BEGIN
        NL;
        Print('^8Enter only your city name.^0');
        Exit;
      END;
      NL;
      IF (Length(s) < 3) THEN
        Exit;
      Prompt('Enter your '+AOnOff((CallFromArea = 1),'state','province')+' abbreviation: ');
      MPL(2);
      Input(s1,2);
      User.CityState := s+', '+s1;
      Done1 := TRUE;
    END
    ELSE
    BEGIN
      Print('First enter your city name only:');
      Prt(': ');
      MPL(26);
      InputCaps(s1,26);
      IF (Length(s1) < 2) THEN
        Exit;
       NL;
      Print('Now enter your country name:');
      Prt(': ');
      MPL(26);
      InputCaps(s2,26);
      IF (Length(s2) < 2) THEN
        Exit;
       s := s1+', '+s2;
       IF (Length(s) > 30) THEN
      BEGIN
        Print('^8Max total Length is 30 characters!^0');
        Exit;
      END;
       IF (How = 2) AND (User.CityState <> s) THEN
        SysOpLog('Changed city/state from '+User.CityState+' to '+s);
       User.CityState := s;
      Done1 := TRUE;
    END;
  END;

  PROCEDURE AskZipCode;
  VAR
    TempZipCode: Str10;
  BEGIN
    IF (How <> 1) THEN
    BEGIN
      AskCountry;
      NL;
    END;
    CASE CallFromArea OF
      1 : BEGIN
            Print('Enter your zipcode (#####-####):');
            Prt(': ');
            InputFormatted('',TempZipCode,'#####-####',(How <> 1));
            IF (TempZipCode <> '') THEN
              User.ZipCode := TempZipCode;
            Done1 := TRUE;
          END;
      2 : BEGIN
            Print('Enter your postal code (LNLNLN format)');
            Prt(': ');
            InputFormatted('',TempZipCode,'@#@#@#',(How <> 1));
            IF (TempZipCode <> '') THEN
              User.ZipCode := TempZipCode;
            Done1 := TRUE
          END;
      3 : BEGIN
            Print('Enter your postal code:');
            Prt(': ');
            MPL((SizeOf(User.ZipCode) - 1));
            Input(TempZipCode,(SizeOf(User.ZipCode) - 1));
            IF (Length(TempZipCode) > 2) THEN
            BEGIN
              User.ZipCode := TempZipCode;
              Done1 := TRUE;
            END;
          END;
    END;
  END;

  PROCEDURE AskPhone;
  VAR
    TempPhone: AStr;
  BEGIN
    CASE How OF
      1 : BEGIN
            IF (IEMSIRec.Ph <> '') THEN
              BEGIN
                Buf := IEMSIRec.Ph;
                IEMSIRec.Ph := '';
              END;
          END;
      2 : AskCountry;
      3 : CallFromArea := 1;
    END;
    Print('Enter your phone number:');
    Prt(': ');
    IF (((How = 1) AND (CallFromArea = 3)) OR (How = 3)) THEN
      BEGIN
        MPL(12);
        Input(TempPhone,12);
        IF (Length(TempPhone) > 5) THEN
          BEGIN
            User.Ph := TempPhone;
            Done1 := TRUE;
          END;
      END
    ELSE
      BEGIN
        InputFormatted('',TempPhone,'(###)###-####',(How <> 1));
        TempPhone[5] := '-';
        TempPhone := Copy(TempPhone,2,(Length(TempPhone) - 1));
        IF (How = 2) AND (User.Ph <> TempPhone) THEN
          SysOpLog('Changed phone from '+User.Ph+' to '+TempPhone);
        User.Ph := TempPhone;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE CfgTermEmu;
  VAR
    Cmd: Char;
  BEGIN
    PrintF('TERMINAL');
    Print('^0Which terminal emulation do you support?');
    NL;
    Print('^0(^11^0) None');
    Print('^0(^12^0) ANSI');
    Print('^0(^13^0) Avatar');
    Print('^0(^14^0) VT-100');
    Print('^0(^15^0) RIP Graphics');
    NL;
    LOneK('^2Select (^11^2-^15^2): ',Cmd,'12345',TRUE,TRUE);
    Exclude(User.ACFlags,ANSI);
    Exclude(User.ACFlags,Avatar);
    Exclude(User.ACFlags,VT100);
    Exclude(User.SFlags,RIP);
    CASE Cmd OF
      '2' : Include(User.ACFlags,ANSI);
      '3' : BEGIN
              Include(User.ACFlags,Avatar);
              NL;
              IF PYNQ('Does your terminal program support ANSI fallback? ',0,TRUE) THEN
                Include(User.ACFlags,ANSI);
            END;
      '4' : Include(User.ACFlags,VT100);
      '5' : BEGIN
              Include(User.ACFlags,ANSI);
              Include(User.SFlags,RIP);
            END;
    END;
    IF (ANSI IN User.ACFlags) OR (Avatar IN User.ACFlags) OR (VT100 IN User.ACFlags) THEN
      Include(User.SFlags,FSEditor)
    ELSE
      Exclude(User.SFlags,FSEditor);
    NL;
    IF (PYNQ('Would you like this to be auto-detected in the future? ',0,TRUE)) THEN
      Include(User.SFlags,AutoDetect)
    ELSE
      Exclude(User.SFlags,AutoDetect);
    Done1 := TRUE;
  END;
  
  PROCEDURE ToggleLightbars;
  { LeeW: I plan to combine all lightbars into a single boolean, instead of msg/file/ynq etc }
  BEGIN
    IF (NOT General.UseFileAreaLightBar) OR (NOT General.UseMsgAreaLightBar) THEN
      BEGIN
        Print('Lightbars are not available on this system');
        Done1 := TRUE;
        EXIT;
      END;
    {/}
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Enable Lightbars?',0,TRUE) THEN
		  begin
			Include(User.SFlags,FileAreaLightbar);
			Include(User.SFlags,MsgAreaLightbar);
		  end
        ELSE
		  begin
			Exclude(User.SFlags,FileAreaLightbar);
			Exclude(User.SFlags,MsgAreaLightbar);
			Done1 := TRUE;
		  end
      END
    ELSE
      BEGIN
        IF (FileAreaLightbar IN User.SFlags) OR (MsgAreaLightbar IN User.SFlags) THEN
          BEGIN
            Exclude(User.SFlags,FileAreaLightbar);
			Exclude(User.SFlags,MsgAreaLightbar);
            Print('Lightbars disabled');
          END
        ELSE
          BEGIN
            Include(User.SFlags,FileAreaLightbar);
			Include(User.SFlags,MsgAreaLightbar);
            Print('Lightbars enabled');
          END;
        Done1 := TRUE;
      END;
  END;
  
  { --- BELOW THIS ARE (pretty much) DONE & IN RIGHT ORDER --- }

  PROCEDURE AskName;
  VAR
    TmpName,
    TmpName1,
    TmpName2: STRING[160];
    TextFile: Text;
    UNum: Integer;
  BEGIN
    Done1 := TRUE;
    IF (How = 1) THEN
      IF (General.AllowAlias) AND (IEMSIRec.Handle <> '') THEN
        BEGIN
          Buf := IEMSIRec.Handle;
          IEMSIRec.Handle := '';
        END
      ELSE IF (IEMSIRec.UserName <> '') THEN
        BEGIN
          Buf := IEMSIRec.UserName;
          IEMSIRec.UserName := '';
        END;
    IF (General.AllowAlias) THEN
      BEGIN
        Print('^0Enter your handle, or your real first & last');
        Print('^0names if you don''t want to use one.')
      END
    ELSE
      BEGIN
        Print('^0Enter your first & last Name.');
        Print('^0Handles are not allowed.');
      END;
    InputDefault(TmpName,'',(SizeOf(User.Name)-1),[UpperOnly],FALSE);
    WHILE (TmpName[1] IN [' ','0'..'9']) AND (Length(TmpName) > 0) DO
      Delete(TmpName,1,1);
    WHILE (TmpName[Length(TmpName)] = ' ') DO
      Dec(TmpName[0]);
    IF ((Pos(' ',TmpName) = 0) AND (How <> 3) AND NOT (General.AllowAlias)) THEN
      BEGIN
        Done1 := FALSE;
        Print(^G'^8Enter your first AND last name!^0%PA');
        SL1('Invalid name: '+TmpName+' (single word)' );
      END
    ELSE
      BEGIN
        UNum := SearchUser(TmpName,TRUE);
        IF (UNum > 0) AND (UNum <> UserNum) THEN
          BEGIN
            Done1 := FALSE;
            Print(^G'^8That name already exists in our records!^0');
            SL1('Invalid name: '+TmpName+' (duplicate)' );
          END;
        Assign(TextFile,General.MiscPath+'TRASHCAN.TXT');
        Reset(TextFile);
        IF (IOResult = 0) THEN
          BEGIN
            TmpName2 := ' '+TmpName+' ';
            WHILE NOT EOF(TextFile) DO
              BEGIN
                ReadLn(TextFile,TmpName1);
                IF (TmpName1[Length(TmpName1)] = #1) THEN
                  TmpName1[Length(TmpName1)] := ' '
                ELSE
                  TmpName1 := TmpName1 + ' ';
                TmpName1 := ' ' + TmpName1;
                TmpName1 := AllCaps(TmpName1);
                IF (Pos(TmpName1,TmpName2) <> 0) THEN
                  BEGIN
                    Done1 := FALSE;
                    Print(^G'^8That username has been blacklisted!^0');
                    SL1('Invalid username: '+TmpName+' (blacklisted)' );
                  END;
              END;
            Close(TextFile);
          END;
      END;
    IF (Done1) THEN 
      IF (How = 2) AND (UserNum > -1) THEN { Don't add index of unregistered users! }
        BEGIN
          SysOpLog('Changed username from '+User.Name+' to '+TmpName);
          InsertIndex(User.Name,UserNum,FALSE,TRUE);
          User.Name := TmpName;
          InsertIndex(User.Name,UserNum,FALSE,FALSE);
        END
      ELSE
        User.Name := TmpName;
  END;

  PROCEDURE AskRealName;
  VAR
    TmpRealName: STRING[40];
    UNum: Integer;
  BEGIN
    Done1 := TRUE;
    IF (How = 1) THEN
      IF (NOT General.AllowAlias) THEN
        BEGIN
          User.RealName := Caps(User.Name);
          Done1 := TRUE;
          Exit;
        END
      ELSE IF (IEMSIRec.UserName <> '') THEN
        BEGIN
          Buf := IEMSIRec.UserName;
          IEMSIRec.UserName := '';
        END;
    Print('^0Enter your real first & last name:');
    InputDefault(TmpRealName,'',(SizeOf(User.RealName)-1),[CapWords],FALSE);
    WHILE (TmpRealName[1] IN [' ','0'..'9']) AND (Length(TmpRealName) > 0) DO
      Delete(TmpRealName,1,1);
    WHILE (TmpRealName[Length(TmpRealName)] = ' ') DO
      Dec(TmpRealName[0]);
    IF (Pos(' ',TmpRealName) = 0) AND (How <> 3) THEN
      BEGIN
        Done1 := FALSE;
        Print(^G'^8Enter your first AND last name!^0');
        SL1('Invalid real name: '+TmpRealName+' (single word)' );
      END
    ELSE 
      BEGIN
        UNum := SearchUser(TmpRealName,TRUE);
        IF (UNum > 0) AND (UNum <> UserNum) THEN
          BEGIN
            Done1 := FALSE;
            Print(^G'^8That name already exists in our records!^0');
            SL1('Invalid real name: '+TmpRealName+' (duplicate)' );
          END;
      END;
    IF (Done1) THEN
      IF (How = 2) AND (UserNum > -1) THEN { Don't add index of unregistered users! }
        BEGIN
          SysOpLog('Changed real name from '+User.RealName+' to '+TmpRealName);
          InsertIndex(User.RealName,UserNum,TRUE,TRUE);
          User.RealName := TmpRealName;
          InsertIndex(User.RealName,UserNum,TRUE,FALSE);
        END
      ELSE
        User.RealName := TmpRealName;
  END;

  PROCEDURE AskAddress;
  VAR
    TmpAddress: STRING[30];
  BEGIN
    TmpAddress := User.Street;
    InputWN1('^2Enter your street address: ',TmpAddress,(SizeOf(User.Street)-1),[InterActiveEdit],Changed);
    IF (TmpAddress <> '') THEN
      BEGIN
        IF (How = 2) AND (Changed) THEN
          SysOpLog('Changed address from '+User.Street+' to '+TmpAddress);
        User.Street := TmpAddress;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskAge;
  VAR
    TmpDate: STRING[10];
    TmpDay,
    TmpMonth,
    TmpYear,
    CurYear: Word;
    BadDate: Boolean;
  BEGIN
    TmpDate := PD2Date(User.BirthDate);
    GetYear(CurYear);
    IF (How = 1) AND (IEMSIRec.BDate <> '') THEN
      BEGIN
        Buf := IEMSIRec.BDate;
        IEMSIRec.BDate := '';
      END;
      BadDate := FALSE;
      InputFormatted('^2Enter your date of birth (MM/DD/YYYY):',TmpDate,'##/##/####',(How <> 1));
      IF (TmpDate <> '') AND NOT (HangUp) THEN
        BEGIN
          TmpMonth := StrToInt(Copy(TmpDate,1,2));
          TmpDay := StrToInt(Copy(TmpDate,4,2));
          TmpYear := StrToInt(Copy(TmpDate,7,4));
          IF (TmpMonth = 0) OR (TmpDay = 0) OR (TmpYear = 0) THEN
            BadDate := TRUE;
          IF (TmpMonth > 12) THEN
            BadDate := TRUE;
          IF (TmpMonth IN [1,3,5,7,8,10,12]) AND (TmpDay > 31) THEN
            BadDate := TRUE;
          IF (TmpMonth IN [4,6,9,11]) AND (TmpDay > 30) THEN
            BadDate := TRUE;
          IF (TmpMonth = 2) AND ((TmpYear MOD 4) <> 0) AND (TmpDay > 28) THEN
            BadDate := TRUE;
          IF (TmpMonth = 2) AND ((TmpYear MOD 4) = 0) AND (TmpDay > 29) THEN
            BadDate := TRUE;
          IF (TmpYear >= CurYear) THEN
            BadDate := TRUE;
          IF (TmpYear < (CurYear - 100)) THEN
            BadDate := TRUE;
          {/}
          IF (BadDate) THEN
            BEGIN
              NL;
              Print('^8You entered an invalid date of birth!^0');
              NL;
            END
          ELSE
            BEGIN
              IF (How = 2) AND (PD2Date(User.Birthdate) <> PD2Date(Date2PD(TmpDate))) THEN
                SysOpLog('Changed birthdate from '+PD2Date(User.Birthdate)+' to '+PD2Date(Date2PD(TmpDate)));
              User.BirthDate := Date2PD(TmpDate);
              Done1 := TRUE;
            END;
        END;
  END;

  PROCEDURE AskGender;
  VAR
    TmpGender: Char;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        User.Sex := #0;
        LOneK('^2Are you (^1M^2)ale or (^1F^2)emale? ',TmpGender,'MF',TRUE,TRUE);
      END
    ELSE
      LOneK('^2Are you (^1M^2)ale or (^1F^2)emale? ',TmpGender,^M'MF',TRUE,TRUE); { Abortable }
    IF TmpGender IN ['M','F'] THEN
      BEGIN
        IF (How = 2) THEN
          SysOpLog('Changed gender from '+AOnOff((TmpGender='F'),'Male','Female')+' to '+
                                          AOnOff((TmpGender='M'),'Male','Female'));
        User.Sex := TmpGender;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskSysOpDef(QuestionNum: Byte);
  VAR
    TmpQuestion: STRING[80];
    TmpAnswer: STRING[35];
  BEGIN
    TmpQuestion := '';
    TmpAnswer := User.UsrDefStr[QuestionNum];
    CASE QuestionNum OF
      1 : TmpQuestion := lRGLngStr(38,TRUE);
      2 : TmpQuestion := lRGLngStr(39,TRUE);
      3 : TmpQuestion := lRGLngStr(40,TRUE);
    END;
    IF (TmpQuestion = '') THEN
      BEGIN
        User.UsrDefStr[QuestionNum] := '';
        Done1 := TRUE;
        EXIT;
      END;
    {/}
    InputWN1('^2'+TmpQuestion+' ',TmpAnswer,(SizeOf(User.UsrDefStr[QuestionNum])-1),[InterActiveEdit],Changed);
    IF (TmpAnswer <> '') THEN
      BEGIN
        IF (How = 2) AND (Changed) THEN
          SysOpLog('Changed '+TmpQuestion+' response from '+User.UsrDefStr[QuestionNum]+' to '+TmpAnswer);
        User.UsrDefStr[QuestionNum] := TmpAnswer;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskPW;
  VAR
    TmpPW,
    TmpPW2: STRING[20];
    OldPW: LongInt;
  BEGIN
    OldPW := User.PW;
    IF (How = 1) AND (IEMSIRec.PW <> '') THEN
      BEGIN
        Buf := IEMSIRec.PW;
        IEMSIRec.PW := '';
      END;
    IF (How = 2) THEN
      BEGIN
        Print('^0Enter your current password:');
        NL;
        Prompt('^2Password: ^0');
        MPL(20);
        GetPassword(TmpPW,20);
        IF (CRC32(TmpPW) <> User.PW) THEN
          BEGIN
            NL;
            Print('^8Wrong!^0');
            NL;
            Exit;
          END;
      END;
    Print('^0Enter your desired password for future access.');
    Print('^0It should be 4 to 20 characters in length.');
    NL;
    Prompt('^2Password: ');
    MPL(20);
    GetPassword(TmpPW,20);
    NL;
    IF (Length(TmpPW) < 4) THEN
      BEGIN
        Print('^8Must be at least 4 characters long!^0');
      END
    ELSE IF (Length(TmpPW) > 20) THEN
      BEGIN
        Print('^8Must be no more than 20 characters long.^0');
      END
    ELSE IF (How = 3) AND (CRC32(TmpPW) = OldPW) THEN
      BEGIN
        Print('^8Must be different from your old password!^0');
      END
    ELSE IF (TmpPW = ThisUser.Name) OR (TmpPW = ThisUser.RealName) THEN
      BEGIN
        Print('^8You cannot use that password!^0');
      END
    ELSE
      BEGIN
        Print('^0Enter your password again for verification:');
        NL;
        Prompt('^2Password: ');
        MPL(20);
        GetPassword(TmpPW2,20);
        IF (TmpPW2 <> TmpPW) AND NOT (HangUp) THEN
          Print('^8Passwords do not match!^0')
        ELSE
          BEGIN { Success! }
            User.PasswordChanged := DayNum(DateStr);
            User.PW := CRC32(TmpPW);
            Done1 := TRUE;
            IF (How = 1) THEN
              Print('^9Saved!^0');
            IF (How = 2) THEN
              BEGIN
                NL;
                Print('^9Your password has been successfully changed^0');
                SysOpLog('Changed password');
              END;
          END;
      END;
  END;

  PROCEDURE AskForgotPW;
  VAR
    TmpForgotPWAnswer: STRING[40];
  BEGIN
    TmpForgotPWAnswer := User.ForgotPWAnswer;
    Print('This question will be asked should you ever forget your password;');
    NL;
    Print(General.ForgotPWQuestion);
    NL;
    InputWN1('^2Enter your answer: ',TmpForgotPWAnswer,(SizeOf(User.ForgotPWAnswer)-1),[InterActiveEdit],Changed);
    IF (TmpForgotPWAnswer <> '') THEN
      BEGIN
        IF (How = 2) AND (Changed) THEN
          SysOpLog('Changed forgot password answer'); { Probably shouldn't display the values }
        User.ForgotPWAnswer := TmpForgotPWAnswer;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE ToggleColor;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('^2Enable ANSI colors? ',0,TRUE) THEN
          Include(User.ACFlags,Color)
        ELSE
          Exclude(User.ACFlags,Color);
        Done1 := TRUE;
      END
    ELSE
      BEGIN
        IF (Color IN User.ACFlags) THEN
          BEGIN
            Exclude(User.ACFlags,Color);
            Print('ANSI Color disabled.');
          END
        ELSE
          BEGIN
            Include(User.ACFlags,Color);
            Print('ANSI Color enabled.');
          END;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE CfgColorScheme;
  VAR
    TmpScheme: SchemeRec;
    TmpSchemeNum,
    OnLine: Integer;
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    IF NOT (Color IN User.ACFlags) OR (NumSchemes = 1) THEN
      BEGIN
        Print('^0Using default color scheme');
        User.ColorScheme := 1;
        Done1 := TRUE;
        EXIT;
      END;
    {/}
    Reset(SchemeFile);
    Seek(SchemeFile,0);
    PrintACR('^0Available Color schemes:');
    NL;
    TmpSchemeNum := 1;
    OnLine := 0;
    WHILE (FilePos(SchemeFile) < FileSize(SchemeFile)) AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Read(SchemeFile,TmpScheme);
        Inc(OnLine);
        { Formatting will be broken if more than 99 color schemes, seems pretty unlikely though }
        IF (NumSchemes > 9) THEN
          Prompt(PadLeftStr(PadRightStr('^0(^1'+IntToStr(TmpSchemeNum)+'^0)',4)+' '+TmpScheme.Description,39))
        ELSE
          Prompt(PadLeftStr('^0(^1'+IntToStr(TmpSchemeNum)+'^0) '+TmpScheme.Description,39));
        IF (OnLine = 2) THEN
          BEGIN
            NL;
            OnLine := 0;
          END;
        WKey;
        Inc(TmpSchemeNum);
      END;
    NL;
    TmpSchemeNum := ThisUser.ColorScheme;
    InputIntegerWOC('^2%LFSelect a color scheme',TmpSchemeNum,[NumbersOnly],1,FileSize(SchemeFile));
    IF (TmpSchemeNum >= 1) AND (TmpSchemeNum <= FileSize(SchemeFile)) THEN
      BEGIN
        IF (How = 2) AND (TmpSchemeNum <> ThisUser.ColorScheme) THEN
          SysOpLog('Changed color scheme from #'+IntToStr(ThisUser.ColorScheme)+' to #'+IntToStr(TmpSchemeNum));
        ThisUser.ColorScheme := TmpSchemeNum;
        Seek(SchemeFile,(TmpSchemeNum-1));
        Read(SchemeFile,Scheme);
        Done1 := TRUE;
      END;
    Close(SchemeFile);
  END;

  PROCEDURE CfgScreen;
  BEGIN
    InputByteWOC('^2How many columns wide is your display?',User.LineLen,[InteractiveEdit,NumbersOnly],32,132);
    NL;
    IF (User.LineLen >= 32) AND (User.LineLen <= 132) THEN
      Done1 := TRUE;
    InputByteWOC('^2How many rows tall is your display?',User.PageLen,[InteractiveEdit,NumbersOnly],4,50);
    NL;
    IF (User.PageLen >= 4) AND (User.PageLen <= 50) THEN
      Done1 := TRUE;
  END;

  PROCEDURE ToggleClear;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Clear screen before each message read? ',0,TRUE) THEN
          Include(User.SFlags,CLSMsg)
        ELSE
          Exclude(User.SFlags,CLSMsg);
        Done1 := TRUE;
      END
    ELSE
      BEGIN
        IF (CLSMsg IN User.SFlags) THEN
          BEGIN
            Exclude(User.SFlags,CLSMsg);
            Print('Screen clearing off.');
          END
        ELSE
          BEGIN
            Include(User.SFlags,CLSMsg);
            Print('Screen clearing on.');
          END;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE TogglePause;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Pause after each screen? ',0,TRUE) THEN
          Include(User.ACFlags,Pause)
        ELSE
          Exclude(User.ACFlags,Pause);
        Done1 := TRUE;
      END
    ELSE
      BEGIN
        IF (Pause IN User.ACFlags) THEN
          BEGIN
            Exclude(User.ACFlags,Pause);
            Print('Pause on screen disabled');
          END
        ELSE
          BEGIN
            Include(User.ACFlags,Pause);
            Print('Pause on screen enabled');
          END;
        Done1 := TRUE;
      END;
  END;
  
  PROCEDURE ToggleHotKey;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Do you want to use Hot Keys? ',0,TRUE) THEN
          Include(User.ACFlags,HotKey)
        ELSE
          Exclude(User.ACFlags,HotKey);
        Done1 := TRUE;
      END
    ELSE
      BEGIN
        IF (HotKey IN User.ACFlags) THEN
          BEGIN
            Exclude(User.ACFlags,HotKey);
            Print('Full line input.');
          END
        ELSE
          BEGIN
            Include(User.ACFlags,HotKey);
            Print('Hot key input.');
          END;
        Done1 := TRUE;
      END;
  END;
  
  PROCEDURE ToggleExpert;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Do you want to be in expert mode? ',0,FALSE) THEN
          Exclude(User.ACFlags,Novice)
        ELSE
          Include(User.ACFlags,Novice);
        Done1 := TRUE;
      END
    ELSE
      BEGIN
        IF (Novice IN User.ACFlags) THEN
          BEGIN
            Exclude(User.ACFlags,Novice);
            CurHelpLevel := 1;
            Print('Expert mode on.');
          END
        ELSE
          BEGIN
            Include(User.ACFlags,Novice);
            CurHelpLevel := 2;
            Print('Expert mode off.');
          END;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE ToggleEditor;
  BEGIN
    Done1 := TRUE;
    IF (NOT (ANSI IN User.ACFlags)) THEN
      BEGIN
        Print('ANSI terminal emulation required to use fullscreen editor');
        Exclude(User.SFlags,FSEditor);
        EXIT;
      END;
    {/}
    IF (How = 1) THEN
      BEGIN
        IF PYNQ('Enable full screen editor?',0,TRUE) THEN
          Include(User.SFlags,FSEditor)
        ELSE
          Exclude(User.SFlags,FSEditor);
      END
    ELSE
      BEGIN
        IF (FSEditor IN User.SFlags) THEN
          BEGIN
            Exclude(User.SFlags,FSEditor);
            Print('Full screen editor disabled.');
          END
        ELSE
          BEGIN
            Include(User.SFlags,FSEditor);
            Print('Full screen editor enabled.');
          END;
      END;
  END;
  
  PROCEDURE ToggleMailBox;
  VAR
  OpenString: STRING[65];
    
    PROCEDURE ForwardMail;
    VAR
      User1: UserRecordType; { The user we're forwarding to }
      UNum: Integer; { Search result user number }
    BEGIN
      NL;
      Print('^0If you forward your mail, all email sent to your account');
      Print('will be redirected to that person.');
      NL;
      Print('^2Enter User Number, Name, or Partial Search String:');
      lFindUserWS(UNum);
      IF (UNum < 1) OR (UNum > (MaxUsers - 1)) THEN
        User.ForUsr := 0
      ELSE
        BEGIN
          LoadURec(User1,UNum);
          IF (User.Name = User1.Name) OR (LockedOut IN User1.SFlags) OR
             (Deleted IN User1.SFlags) OR (NoMail IN User1.ACFlags) THEN
            BEGIN
              NL;
              Print('^8You can not forward mail to that user!^0');
            END
          ELSE
            BEGIN
              User.ForUsr := UNum;
              NL;
              Print('^0Your mail is now being forwarded to '+Caps(User1.Name)+' (#'+IntToStr(UNum)+')');
              SysOpLog('Forwarding mail to: '+Caps(User1.Name)+' #'+IntToStr(UNum));
            END;
        END;
    END;
    
  BEGIN
    IF (User.ForUsr <> 0) THEN
      OpenString := 'Do you want to stop forwarding your mail and open your mailbox?' { Mail is being forwarded }
    ELSE
      OpenString := 'Do you want to open your mailbox?'; { Mail is not being forwarded }
      
    IF (NoMail IN User.ACFlags) THEN
      BEGIN
        IF PYNQ('^2'+OpenString,0,FALSE) THEN
          BEGIN
            Exclude(User.ACFlags,NoMail);
            Print('Your mailbox is now open');
            SysOpLog(AllCaps(User.Name)+' opened their mailbox');
            IF (User.ForUsr <> 0) THEN
              BEGIN
                User.ForUsr := 0;
                Print('Your mail is no longer being forwarded');
                SysOpLog(AllCaps(User.Name)+' is no longer forwarding their mail');
              END;
          END;
      END
    ELSE
      IF PYNQ('Do you want to close your mail box?',0,FALSE) THEN
        BEGIN
          Include(User.ACFlags,NoMail);
          Print('Your mailbox is now closed');
          SysOpLog(AllCaps(User.Name)+' closed their mailbox');
        END;
    IF ((User.ForUsr = 0) AND (NoMail IN User.ACFlags)) THEN
      BEGIN
        IF PYNQ('Do you want to forward your mail?',0,FALSE) THEN
          ForwardMail;
      END;
    Done1 := TRUE;
  END;
  
  PROCEDURE CfgQWK;
  VAR
    TmpDefArcType: Char;
    Counter: Byte;
    ValidKeys: STRING[10];
  BEGIN
    ValidKeys := '';
    FOR Counter := 1 TO NumArcs DO
      IF (General.FileArcInfo[Counter].Ext <> '') AND (General.FileArcInfo[Counter].Active) THEN
        BEGIN
          Print('^0(^1'+IntToStr(Counter)+'^0) '+General.FileArcInfo[Counter].Ext);
          ValidKeys := ValidKeys+IntToStr(Counter);
        END;
    IF (How <> 1) THEN
      ValidKeys := ValidKeys+^M; { Allow abort }
    NL;
    LOneK('^2Select your preferred archive format: ',TmpDefArcType,ValidKeys,TRUE,TRUE);
    IF (StrToInt(TmpDefArcType) <> User.DefArcType) AND (TmpDefArcType <> ^M) THEN
      BEGIN
        User.DefArcType := StrToInt(TmpDefArcType);
        Done1 := TRUE;
      END;
    {/}
    NL;
    User.GetOwnQWK := PYNQ('^0Do you want your own replies in your QWK packet? ',0,FALSE);
    NL;
    User.PrivateQWK := PYNQ('^0Do you want your private mail in your QWK packet? ',0,FALSE);
    NL;
    User.ScanFilesQWK := PYNQ('^0Do you want new file list in your QWK packet? ',0,FALSE);
    NL;
  END;
  
  { --- }

  PROCEDURE WW(www: Byte);
  BEGIN
    NL;
    CASE www OF
      { Personal Information }
      01 : AskName;         { Users handle *MANDATORY* }
      02 : AskRealName;     { Users real name }
      03 : AskCountry;      { Users country }
      04 : AskAddress;      { Users address }
      05 : AskCityState;    { Users city and state }
      06 : AskZipCode;      { Users zip code }
      07 : AskPhone;        { Users phone number }
      08 : AskAge;          { Users age }
      09 : AskGender;       { Users gender }
      10 : AskSysOpDef(1);  { SysOp defined question #1 }
      11 : AskSysOpDef(2);  { SysOp defined question #2 }
      12 : AskSysOpDef(3);  { SysOp defined question #3 }
      13 : AskPW;           { Users password *MANDATORY* }
      14 : AskForgotPW;     { Users forgotten password answer }
      { Settings }
      15 : CfgTermEmu;      { Configure terminal emulation }
      16 : ToggleColor;     { Toggle ANSI color }
      17 : CfgColorScheme;  { Configure color scheme }
      18 : CfgScreen;       { Configure screen size }
      19 : ToggleClear;     { Toggle screen clearing }
      20 : TogglePause;     { Toggle screen pausing }
      21 : ToggleHotKey;    { Toggle hotkey input }
      22 : ToggleExpert;    { Toggle expert mode }
      23 : ToggleLightBars; { Toggle lightbar use }
      24 : ToggleEditor;    { Toggle line / fullscreen editor }
      25 : ToggleMailbox;   { Toggle mailbox & mail forwarding }
      26 : CfgQWK;          { Configure QWK }
      27 : Done1 := TRUE;   { NOTHING }
      28 : Done1 := TRUE;   { NOTHING }
      29 : Done1 := TRUE;   { NOTHING }
      30 : Done1 := TRUE;   { NOTHING }
    END;
  END;

BEGIN
  Tries := 0;
  Changed := FALSE;
  Done1 := FALSE;
  CASE How OF
    1   : REPEAT { 1 = New user application OR maintenance }
            WW(Which);
            Inc(Tries);
            IF (Tries >= General.MaxLogonTries) THEN
              BEGIN
                NL;
                Print('^8Exceeded maximum number of retries. Disconnecting.^0');
                HangUp := TRUE;
              END;
          UNTIL (Done1) OR (HangUp);
    2,3 :
          BEGIN { 2 = "OP" Menu command, 3 = User editor }
            WW(Which);
            IF (NOT Done1) THEN
              Print('^8Function aborted!^0');
          END;
  END;
END;
END.