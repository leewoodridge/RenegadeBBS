{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Added: Won't ask for forgot pw answer if question is blank
Added: Almost all strings are in lang except for a few i'm still working on
All CStuff calls in other units have been updated, might need to change how in some of them, maint will be =1 for mandatory

colorscheme and screen have changed var now
--
TODO:
Update lightbarproc when datafile changes are made
add country in userrec
better validation for qwk & screensize
better maxtries msg/file before hangup
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
  TmpCountryCode: Byte;

PROCEDURE CStuff(Which,How: Byte; VAR User: UserRecordType);
VAR
  Tries: Byte;
  Done1: Boolean;

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
      lRGLngStr(195,FALSE) {"Enter handle"}
    ELSE
      lRGLngStr(196,FALSE); {"Enter real name"}
    InputMain(TmpName,(SizeOf(User.Name)-1),[CapAll]);
    WHILE (TmpName[1] IN [' ','0'..'9']) AND (Length(TmpName) > 0) DO
      Delete(TmpName,1,1);
    WHILE (TmpName[Length(TmpName)] = ' ') DO
      Dec(TmpName[0]);
    IF ((Pos(' ',TmpName) = 0) AND (How <> 3) AND NOT (General.AllowAlias)) THEN
      BEGIN
        Done1 := FALSE;
        Print(^G+lRGLngStr(156,TRUE)); {"First and last!"}
        SL1('Invalid name: '+TmpName+' (single word)' );
      END
    ELSE
      BEGIN
        UNum := SearchUser(TmpName,TRUE);
        IF (UNum > 0) AND (UNum <> UserNum) THEN
          BEGIN
            Done1 := FALSE;
            Print(^G+lRGLngStr(157,TRUE)); {"Already exists"}
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
                    Print(^G+lRGLngStr(158,TRUE)); {"Blacklisted"}
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
    lRGLngStr(197,FALSE); {"Enter real name"}
    InputMain(TmpRealName,(SizeOf(User.RealName)-1),[CapWords]);
    WHILE (TmpRealName[1] IN [' ','0'..'9']) AND (Length(TmpRealName) > 0) DO
      Delete(TmpRealName,1,1);
    WHILE (TmpRealName[Length(TmpRealName)] = ' ') DO
      Dec(TmpRealName[0]);
    IF (Pos(' ',TmpRealName) = 0) AND (How <> 3) THEN
      BEGIN
        Done1 := FALSE;
        Print(^G+lRGLngStr(156,TRUE)); {"First and last!"}
        SL1('Invalid real name: '+TmpRealName+' (single word)' );
      END
    ELSE 
      BEGIN
        UNum := SearchUser(TmpRealName,TRUE);
        IF (UNum > 0) AND (UNum <> UserNum) THEN
          BEGIN
            Done1 := FALSE;
            Print(^G+lRGLngStr(157,TRUE)); {"Already exists"}
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

  PROCEDURE AskCountry;
  VAR
    TmpCountry: Char;
  BEGIN
    lRGLngStr(198,FALSE); {"Select country"}
    IF (How=1) THEN
      InputChar('',TmpCountry,'123',[CapAll])
    ELSE
      InputChar('',TmpCountry,^M'123',[CapAll]);
    IF TmpCountry <> ^M THEN
      BEGIN
        TmpCountryCode := (Ord(TmpCountry) - 48);
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskAddress;
  VAR
    TmpAddress: STRING[30];
  BEGIN
    TmpAddress := User.Street;
    lRGLngStr(199,FALSE); {"Enter your address"}
    InputMain(TmpAddress,(SizeOf(User.Street)-1),[CapWords]);
    IF (TmpAddress <> '') THEN { LeeW: Add check for 1 letter, 1 number, 1 space }
      BEGIN
        IF (How = 2) AND (TmpAddress <> User.Street) THEN
          SysOpLog('Changed address from '+User.Street+' to '+TmpAddress);
        User.Street := TmpAddress;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskCityState;
  VAR
    TmpCityState,
    TmpCityState1: AStr;
  BEGIN
    IF (How <> 1) OR (TmpCountryCode=0) THEN
      AskCountry;
    {/}
    CASE TmpCountryCode OF
      1, 2  : BEGIN
                IF (How = 3) THEN { User editor }
                  BEGIN
                    Prt('Enter new city & state abbreviation: ');
                    InputMain(TmpCityState,(SizeOf(User.CityState) - 1),[{CapWords}]);
                    IF (TmpCityState <> '') THEN
                      User.CityState := TmpCityState;
                    Done1 := TRUE;
                    Exit;
                  END
                ELSE
                  BEGIN
                    lRGLngStr(200,FALSE); {"Enter city name"}
                    InputMain(TmpCityState,((SizeOf(User.CityState) - 1) - 4),[CapWords]);
                    IF (Pos(',',TmpCityState) <> 0) THEN
                      BEGIN
                        lRGLngStr(160,FALSE); {"Invalid"}
                        Exit;
                      END;
                    IF (Length(TmpCityState) < 3) THEN
                      Exit;
                    LangStringArray[0] := AOnOff((TmpCountryCode = 1),'state','province');
                    lRGLngStr(201,FALSE); {"Enter state/province abbreviation"}
                    InputMain(TmpCityState1,2,[CapAll]);
                    IF (Length(TmpCityState1) < 2) THEN
                      Exit;
                    TmpCityState := TmpCityState+', '+TmpCityState1;
                  END;
              END;
      3     : BEGIN
                lRGLngStr(200,FALSE); {"Enter city name"}
                InputMain(TmpCityState1,SizeOf(User.CityState)-1,[CapWords]);
                IF (Length(TmpCityState1) < 2) THEN
                  Exit;
             END;
    END;
    IF (Length(TmpCityState) > 2) THEN
      BEGIN
        IF (How = 2) AND (User.CityState <> TmpCityState) THEN
          SysOpLog('Changed city/state from '+User.CityState+' to '+TmpCityState);
        User.CityState := TmpCityState;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskZipCode;
  VAR
    TmpZipCode: STRING[10];
  BEGIN
    IF (How <> 1) OR (TmpCountryCode=0) THEN
      AskCountry;
    CASE TmpCountryCode OF
      1 : InputFormatted(lRGLngStr(202,TRUE),TmpZipCode,'#####-####',(How <> 1)); {"Enter zip code"}
      2 : InputFormatted(lRGLngStr(203,TRUE),TmpZipCode,'@#@#@#',(How <> 1)); {"Enter postal code"}
      3 : BEGIN
            lRGLngStr(204,FALSE); {"Enter postal code"}
            InputMain(TmpZipCode,(SizeOf(User.ZipCode) - 1),[CapAll]);
          END;
    END;
    IF (TmpZipCode <> '') OR ((Length(TmpZipCode) > 2) AND (TmpCountryCode=3)) THEN
      BEGIN
        User.ZipCode := TmpZipCode;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE AskPhone;
  VAR
    TmpPhone: STRING[12];
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
      3 : TmpCountryCode := 1;
    {/}
    END;
    lRGLngStr(205,FALSE); {"Enter phone number"}
    CASE TmpCountryCode OF
      1, 2 :  BEGIN
                InputFormatted('',TmpPhone,'(###)###-####',(How <> 1));
                TmpPhone[5] := '-';
                TmpPhone := Copy(TmpPhone,2,Length(TmpPhone));
              END;
      3    :  BEGIN
                InputMain(TmpPhone,SizeOf(User.Ph)-1,[NumbersOnly]);
              END;
    END;
    IF (TmpPhone <> '') AND ((TmpCountryCode = 1) OR (TmpCountryCode = 2)) OR 
       ((TmpCountryCode = 3) AND (Length(TmpPhone) > 5)) THEN
      BEGIN
        IF (How = 2) AND (User.Ph <> TmpPhone) THEN
          SysOpLog('Changed phone from '+User.Ph+' to '+TmpPhone);
        User.Ph := TmpPhone;
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
      InputFormatted(lRGLngStr(206,TRUE),TmpDate,'##/##/####',(How <> 1)); {"Enter date of birth"}
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
              lRGLngStr(161,FALSE); {"Invalid"}
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
        InputChar(lRGLngStr(207,TRUE),TmpGender,'MF',[CapAll]); {"Are you (M)ale or (F)emale?"}
      END
    ELSE
      InputChar(lRGLngStr(207,TRUE),TmpGender,^M'MF',[CapAll]); { Abortable }
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
    NL;
    Prt('^2'+TmpQuestion{+' '});
    InputMain(TmpAnswer,(SizeOf(User.UsrDefStr[QuestionNum])-1),[InterActiveEdit,CapWords]);
    IF (TmpAnswer <> '') THEN
      BEGIN
        IF (How = 2) AND (TmpAnswer <> User.UsrDefStr[QuestionNum]) THEN
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
        lRGLngStr(208,FALSE); {""}
        InputMain(TmpPW,SizeOf(TmpPW)-1,[IsPassword]); {GetPassword(TmpPW,20);}
        IF (CRC32(TmpPW) <> User.PW) THEN
          BEGIN
            lRGLngStr(162,FALSE); {"Wrong!"}
            Exit;
          END;
      END;
    lRGLngStr(209,FALSE); {""}
    InputMain(TmpPW,SizeOf(TmpPW)-1,[IsPassword]); {GetPassword(TmpPW,20);}
    IF (Length(TmpPW) < 4) THEN
      BEGIN
        lRGLngStr(163,FALSE); {"Too short!"}
      END
    ELSE IF (Length(TmpPW) > 20) THEN
      BEGIN
        lRGLngStr(164,FALSE); {"Too long!"}
      END
    ELSE IF (How = 3) AND (CRC32(TmpPW) = OldPW) THEN
      BEGIN
        lRGLngStr(165,FALSE); {"Can't be same!"}
      END
    ELSE IF (TmpPW = ThisUser.Name) OR (TmpPW = ThisUser.RealName) THEN
      BEGIN
        lRGLngStr(166,FALSE); {"Can't use names!"}
      END
    ELSE
      BEGIN
        lRGLngStr(210,FALSE); {"Enter password again for verification"}
        InputMain(TmpPW2,SizeOf(TmpPW2)-1,[IsPassword]); {GetPassword(TmpPW2,20);}
        IF (TmpPW2 <> TmpPW) AND NOT (HangUp) THEN
          lRGLngStr(167,FALSE) {"Passwords don't match!"}
        ELSE
          BEGIN { Success! }
            User.PasswordChanged := DayNum(DateStr);
            User.PW := CRC32(TmpPW);
            Done1 := TRUE;
            IF (How = 2) THEN
              BEGIN
                lRGLngStr(168,FALSE); {"Password has been changed"}
                SysOpLog('Changed password');
              END;
          END;
      END;
  END;

  PROCEDURE AskForgotPW;
  VAR
    TmpForgotPWAnswer: STRING[40];
  BEGIN
    IF (General.ForgotPWQuestion <> '') THEN
      BEGIN
        TmpForgotPWAnswer := User.ForgotPWAnswer;
        lRGLngStr(211,FALSE); {"This question will be asked..."}
        NL;
        Print(General.ForgotPWQuestion);
        lRGLngStr(212,FALSE); {"Your answer"}
        InputMain(TmpForgotPWAnswer,(SizeOf(User.ForgotPWAnswer)-1),[CapAll,InterActiveEdit]);
        IF (TmpForgotPWAnswer <> '') THEN
          BEGIN
            IF (How = 2) AND (TmpForgotPWAnswer <> User.ForgotPWAnswer) THEN
              SysOpLog('Changed forgot password answer'); { Probably shouldn't display the values }
            User.ForgotPWAnswer := TmpForgotPWAnswer;
            Done1 := TRUE;
          END;
      END
    ELSE
      Done1 := TRUE;
  END;

  PROCEDURE CfgTermEmu;
  VAR
    Cmd: Char;
  BEGIN
  { Exclude(User.ACFlags,ANSI); }
    Exclude(User.ACFlags,Avatar);
    Exclude(User.ACFlags,VT100);
    Exclude(User.SFlags,RIP);
  { Exclude(User.SFlags,AutoDetect); }
    {/}
    PrintF('TERMINAL');
    IF PYNQ(lRGLngStr(213,TRUE),0,TRUE) THEN {"Support ANSI?"}
      Include(User.ACFlags,ANSI)
    ELSE
      Exclude(User.ACFlags,ANSI);
    IF (PYNQ(lRGLngStr(214,TRUE),0,TRUE)) THEN {"Auto-detect?"}
      Include(User.SFlags,AutoDetect)
    ELSE
      Exclude(User.SFlags,AutoDetect);
    {/}
    IF (ANSI IN User.ACFlags) THEN
      Include(User.SFlags,FSEditor)
    ELSE
      Exclude(User.SFlags,FSEditor);
    Done1 := TRUE;
  END;

  PROCEDURE ToggleColor;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ(lRGLngStr(215,TRUE),0,TRUE) THEN {"ANSI Color?"}
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
        lRGLngStr(169,FALSE); {"Using default color scheme"}
        User.ColorScheme := 1;
        Done1 := TRUE;
        EXIT;
      END;
    {/}
    Reset(SchemeFile);
    Seek(SchemeFile,0);
    PrintACR('^0Available Color schemes:');
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
            OnLine := 0;
          END;
        WKey;
        Inc(TmpSchemeNum);
      END;
    TmpSchemeNum := ThisUser.ColorScheme;
    InputInteger(lRGLngStr(216,TRUE),TmpSchemeNum,[NumbersOnly],1,FileSize(SchemeFile),Changed);
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
  VAR
    TmpColumns,
    TmpRows: Byte;
  BEGIN
    TmpColumns := User.LineLen;
    TmpRows := User.PageLen;
    InputByte(lRGLngStr(217,TRUE),TmpColumns,[InterActiveEdit,NumbersOnly],32,132,Changed); {"Screen columns?"}
    IF (TmpColumns >= 32) AND (TmpColumns <= 132) THEN
      BEGIN
        IF (How = 2) AND (TmpColumns <> ThisUser.LineLen) THEN
          SysOpLog('Changed screen columns from '+IntToStr(ThisUser.LineLen)+' to '+IntToStr(TmpColumns));
        User.LineLen := TmpColumns;
        Done1 := TRUE;
      END;
    InputByte(lRGLngStr(218,TRUE),TmpRows,[InterActiveEdit,NumbersOnly],4,50,Changed); {"Screen rows?"}
    IF (TmpRows >= 4) AND (TmpRows <= 50) THEN
      BEGIN
        IF (How = 2) AND (TmpRows <> ThisUser.PageLen) THEN
          SysOpLog('Changed screen rows from '+IntToStr(ThisUser.PageLen)+' to #'+IntToStr(TmpRows));
        User.PageLen := TmpRows;
        Done1 := TRUE;
      END;
  END;

  PROCEDURE ToggleClear;
  BEGIN
    IF (How = 1) THEN
      BEGIN
        IF PYNQ(lRGLngStr(219,TRUE),0,TRUE) THEN {"Clear screens?"}
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
        IF PYNQ(lRGLngStr(220,TRUE),0,TRUE) THEN {"Pause screens?"}
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
        IF PYNQ(lRGLngStr(221,TRUE),0,TRUE) THEN {"Use hotkeys?"}
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
        IF PYNQ(lRGLngStr(222,TRUE),0,FALSE) THEN {"Expert mode?"}
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

  PROCEDURE ToggleLightbars;
  BEGIN
    IF (NOT General.UseLightBars){ OR (NOT General.UseMsgAreaLightBar)} THEN
      BEGIN
        lRGLngStr(170,FALSE); {"Lightbars not available"}
        Done1 := TRUE;
        EXIT;
      END;
    {/}
    IF (How = 1) THEN
      BEGIN
        IF PYNQ(lRGLngStr(223,TRUE),0,TRUE) THEN {"Enable lightbars?"}
          BEGIN
            Include(User.SFlags,FileAreaLightbar);
            Include(User.SFlags,MsgAreaLightbar);
          END
        ELSE
          BEGIN
            Exclude(User.SFlags,FileAreaLightbar);
            Exclude(User.SFlags,MsgAreaLightbar);
          END;
        Done1 := TRUE;
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

  PROCEDURE ToggleEditor;
  BEGIN
    Done1 := TRUE;
    IF (NOT (ANSI IN User.ACFlags)) THEN
      BEGIN
        lRGLngStr(171,FALSE); {"Need ANSI for fullscreen editor"}
        Exclude(User.SFlags,FSEditor);
        EXIT;
      END;
    {/}
    IF (How = 1) THEN
      BEGIN
        IF PYNQ(lRGLngStr(224,TRUE),0,TRUE) THEN {"Use full-screen editor?"}
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
      TmpUser: UserRecordType; { The user we're forwarding to }
      TmpUNum: Integer; { Search result user number }
    BEGIN
      (*lRGLngStr(229,FALSE); { Search for user prompt }*)
      lFindUserWS(TmpUNum);
      IF (TmpUNum < 1) OR (TmpUNum > (MaxUsers - 1)) THEN
        User.ForUsr := 0
      ELSE
        BEGIN
          LoadURec(TmpUser,TmpUNum);
          IF (User.Name = TmpUser.Name) OR (LockedOut IN TmpUser.SFlags) OR
             (Deleted IN TmpUser.SFlags) OR (NoMail IN TmpUser.ACFlags) THEN
            BEGIN
              lRGLngStr(176,FALSE); {"Can't forward to that user!"}
            END
          ELSE
            BEGIN
              User.ForUsr := TmpUNum;
              
              LangStringArray[0] := Caps(TmpUser.Name);
              LangStringArray[1] := IntToStr(TmpUNum);
              
              lRGLngStr(177,FALSE); {"Mail is being forwarded to"}
              SysOpLog('Forwarding mail to: '+Caps(TmpUser.Name)+' #'+IntToStr(TmpUNum));
            END;
        END;
    END;
    
  BEGIN
    IF (User.ForUsr <> 0) THEN
      OpenString := lRGLngStr(225,TRUE) {"Open mailbox?" Mail is being forwarded }
    ELSE
      OpenString := lRGLngStr(226,TRUE); {"Open mailbox?" Mail is not being forwarded }      
    IF (NoMail IN User.ACFlags) THEN
      BEGIN
        IF PYNQ('^2'+OpenString,0,FALSE) THEN
          BEGIN
            Exclude(User.ACFlags,NoMail);
            lRGLngStr(172,FALSE); {"Mailbox open"}
            SysOpLog(AllCaps(User.Name)+' opened their mailbox');
            IF (User.ForUsr <> 0) THEN
              BEGIN
                User.ForUsr := 0;
                lRGLngStr(173,FALSE); {"No longer forwarding"}
                SysOpLog(AllCaps(User.Name)+' is no longer forwarding their mail');
              END;
          END;
      END
    ELSE
      IF PYNQ(lRGLngStr(227,TRUE),0,FALSE) THEN {"Close your mailbox?"}
        BEGIN
          Include(User.ACFlags,NoMail);
          lRGLngStr(174,FALSE); {"Mailbox closed"}
          SysOpLog(AllCaps(User.Name)+' closed their mailbox');
        END;
    IF ((User.ForUsr = 0) AND (NoMail IN User.ACFlags)) THEN
      BEGIN
        lRGLngStr(175,FALSE); { Mail forwarding info }
        IF PYNQ(lRGLngStr(228,TRUE),0,FALSE) THEN {"Forward mail?"}
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
    lRGLngStr(178,FALSE); {"QWK configuration"}
    ValidKeys := '';
    FOR Counter := 1 TO NumArcs DO
      IF (General.FileArcInfo[Counter].Ext <> '') AND (General.FileArcInfo[Counter].Active) THEN
        BEGIN
          Print('^0(^1'+IntToStr(Counter)+'^0) '+General.FileArcInfo[Counter].Ext);
          ValidKeys := ValidKeys+IntToStr(Counter);
        END;
    IF (How <> 1) THEN
      ValidKeys := ValidKeys+^M; { Allow abort }
    InputChar(lRGLngStr(230,TRUE),TmpDefArcType,ValidKeys,[CapAll]); {"Select archive format"}
    IF (StrToInt(TmpDefArcType) <> User.DefArcType) AND (TmpDefArcType <> ^M) THEN
      BEGIN
        User.DefArcType := StrToInt(TmpDefArcType);
      END;
    {/}
    User.GetOwnQWK := PYNQ(lRGLngStr(231,TRUE),0,FALSE); {"Own replies?"}
    User.PrivateQWK := PYNQ(lRGLngStr(232,TRUE),0,FALSE); {"Private mail?"}
    User.ScanFilesQWK := PYNQ(lRGLngStr(233,TRUE),0,FALSE); {"New file list?"}
    Done1 := TRUE;
  END;
  
  { --- }

  PROCEDURE WW(Num: Byte);
  BEGIN
    {NL;}
    CASE Num OF
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
  Done1 := FALSE;
  CASE How OF
    1   : REPEAT { 1 = New user application OR maintenance }
            WW(Which);
            Inc(Tries);
            IF (Tries >= General.MaxLogonTries) THEN
              BEGIN
                Print('^8Exceeded maximum number of retries. Disconnecting.^0'); {**improve this**use file/lang fallback}
                HangUp := TRUE;
              END;
          UNTIL (Done1) OR (HangUp);
    2,3 :
          BEGIN { 2 = "OP" Menu command, 3 = User editor }
            WW(Which);
            IF (NOT Done1) THEN
			  lRGLngStr(154,FALSE); {"Aborted!"} (*Print('^8Function aborted!^0');*)
            IF (How=2) THEN
              PauseScr(FALSE);
          END;
  END;
END;
END.