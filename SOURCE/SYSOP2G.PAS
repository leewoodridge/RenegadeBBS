{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{

}
UNIT SysOp2G;

INTERFACE

USES
  Common;

PROCEDURE AutoVal(VAR User: UserRecordType; UNum: Integer);
PROCEDURE AutoValidate(VAR User: UserRecordType; UNum: Integer; Level: Char);
PROCEDURE AutoValidationCmd(MenuOption: Str50);
PROCEDURE ValidationEditor;

IMPLEMENTATION

USES
  ShortMsg,
  SysOp2,
  SysOp7,
  TimeFunc;

CONST
  Settings: ACFlagSet = [RLogon, RChat, RValidate, RUserList, RAMsg, RPostAN, RPost,REmail,
                         RVoting, RMsg, FNoDLRatio, FNoPostRatio, FNoCredits, FNoDeletion];

FUNCTION ARMatch(SoftAR: Boolean; UserAR,NewAR: ARFlagSet): Boolean;
VAR
  SaveUserAR: ARFlagSet;
  Match: Boolean;
BEGIN
  Match := FALSE;
  SaveUserAR := UserAR;
  IF (SoftAR) THEN
    UserAR := (UserAR + NewAR)
  ELSE
    UserAR := NewAR;
  IF (SaveUserAR = UserAR) THEN
    Match := TRUE;
  ARMatch := Match;
END;

FUNCTION ACMatch(SoftAC: Boolean; UserAC,NewAC: ACFlagSet): Boolean;
VAR
  SaveUserAC: ACFlagSet;
  Match: Boolean;
BEGIN
  Match := FALSE;
  SaveUserAC := UserAC;
  IF (NOT SoftAC) THEN
    UserAC := (UserAC - Settings);
  UserAC := (UserAC + (NewAC * Settings));
  IF (SaveUserAC = UserAC) THEN
    Match := TRUE;
  ACMatch := Match;
END;

PROCEDURE DisplayValidationRecords(VAR RecNumToList1: Integer);
VAR
  TempStr: AStr;
  NumDone,
  NumOnLine: Byte;
BEGIN
  IF (RecNumToList1 < 1) OR (RecNumToList1 > NumValKeys) THEN
    RecNumToList1 := 1;
  Abort := FALSE;
  Next := FALSE;
  TempStr := '';
  NumOnline := 0;
  ConfigHeader('Validation Editor');
  PrintACR('^5<^4##^5> <^4K^5/^4Description>                    ^5<^4##^5> <^4K^5/^4Description^5>'); { List header }
  HL;
  Reset(ValidationFile);
  NumDone := 0;
  WHILE (NumDone < (PageLength - 5)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumValKeys)
        AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(ValidationFile,(RecNumToList1 - 1));
      Read(ValidationFile,Validation);
      TempStr := TempStr + PadLeftStr(' ^1'+PadLeftInt(RecNumToList1,3)+' '+
                                      ' ^1'+PadLeftStr(Validation.Key,1)+{' '+}
                                      ' ^1'+Validation.Description,39);
      Inc(NumOnLine);
      IF (NumOnLine = 2) THEN
        BEGIN
          PrintACR(TempStr);
          NumOnLine := 0;
          Inc(NumDone);
          TempStr := '';
        END
      ELSE
        TempStr := TempStr + ' ';
      Inc(RecNumToList1);
    END;
    Close(ValidationFile);
    LastError := IOResult;
    IF (NumOnline = 1) AND (NOT Abort) AND (NOT HangUp) THEN
      PrintACR(TempStr);
    IF (NumValKeys = 0) AND (NOT Abort) AND (NOT HangUp) THEN
      Messages(4,0,'validation records'); {"No validation records exist!"}
END;

PROCEDURE AutoValidate(VAR User: UserRecordType; UNum: Integer; Level: Char);
VAR
  RecNum,
  RecNum1: Integer;
BEGIN
  IF (NOT (Level IN ValKeys)) THEN
  BEGIN
    SysOpLog('^8Validation error, invalid level: "'+Level+'"!');
    Exit;
  END;
  Reset(ValidationFile);
  RecNum1 := -1;
  RecNum := 1;
  WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
  BEGIN
    Seek(ValidationFile,(RecNum - 1));
    Read(ValidationFile,Validation);
    IF (Validation.Key = Level) THEN
      RecNum1 := RecNum;
    Inc(RecNum);
  END;
  Close(ValidationFile);
  LastError := IOResult;
  IF (Validation.Expiration = 0) AND (Validation.ExpireTo <> ' ') OR
     (Validation.Expiration <> 0) AND (Validation.ExpireTo = ' ') THEN
  BEGIN
    SysOpLog('^8Validation error, expiration data invalid: "'+Level+'"!');
    Exit;
  END
  ELSE IF (Validation.ExpireTo <> ' ') AND (NOT (Validation.ExpireTo IN ValKeys)) THEN
  BEGIN
    SysOpLog('^8Validation error, expire to level "'+Validation.ExpireTo+'" does not exists!');
    Exit;
  END;
  User.Subscription := Level;
  User.TLToday := General.TimeAllow[Validation.NewSL] - (General.TimeAllow[User.SL] - User.TLToday);
  User.SL := Validation.NewSL;
  User.DSL := Validation.NewDSL;
  User.UserStartMenu := Validation.NewMenu;
  IF (Validation.Expiration > 0) THEN
    User.Expiration := (GetPackDateTime + (Validation.Expiration * 86400))
  ELSE
    User.Expiration := 0;
  Inc(User.FilePoints,Validation.NewFP);
  Inc(User.lCredit,Validation.NewCredit);
  IF (Validation.ExpireTo IN [' ','!'..'~']) THEN
    User.ExpireTo := Validation.ExpireTo;
  IF (Validation.SoftAR) THEN
    User.ARFlags := (User.ARFlags + Validation.NewAR)
  ELSE
    User.ARFlags := Validation.NewAR;
  IF (NOT Validation.SoftAC) THEN
    User.ACFlags := (User.ACFlags - Settings);
  User.ACFlags := (User.ACFlags + (Validation.NewAC * Settings));
  SaveURec(User,UNum);
  IF (UNum = UserNum) THEN
    NewCompTables;
END;

PROCEDURE AutoVal(VAR User: UserRecordType; UNum: Integer);
VAR
  TempAR: ARFlagSet;
  TempAC: ACFlagSet;
  Level: Char;
  CmdKeys: AStr;
  RecNum,
  RecNum1,
  RecNumToList: Integer;
BEGIN
  CmdKeys := '';
  FOR Level := '!' TO '~' DO
    IF (Level IN ValKeys) THEN
      CmdKeys := CmdKeys + Level;
  RecNumToList := 1;
  Level := '?';
  REPEAT
    IF (Level = '?') THEN
      DisplayValidationRecords(RecNumToList);
    Prt('%LFValidation level? (^1!^2-^1P^2,^1R^2-^1p^2,^1r^2-^1~^2) [^1?^2=^1First^2,^1<CR>^2=^1Next^2,^1Q^2=^1Quit^2]: ');
    OneK1(Level,'Q'+CmdKeys+'?'^M,TRUE,TRUE);
    IF (Level <> 'Q') THEN
    BEGIN
      IF (Level = ^M) THEN
      BEGIN
        Level := '?';
        IF (RecNumToList < 1) OR (RecNumToList > NumValKeys) THEN
          RecNumToList := 1
      END
      ELSE IF (Level = '?') THEN
        RecNumToList := 1
      ELSE
      BEGIN
        IF (Level IN ValKeys) THEN
        BEGIN
          Reset(ValidationFile);
          RecNum1 := -1;
          RecNum:= 1;
          WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
          BEGIN
            Seek(ValidationFile,(RecNum - 1));
            Read(ValidationFile,Validation);
            IF (Validation.Key = Level) THEN
              RecNum1 := RecNum;
            Inc(RecNum);
          END;
          Close(ValidationFile);
          IF (Validation.Expiration = 0) AND (Validation.ExpireTo <> ' ') OR
             (Validation.Expiration <> 0) AND (Validation.ExpireTo = ' ') THEN
          BEGIN
            Print('%LF^8The expiration days/expire to level is invalid!^0');
            Level := #0;
          END
          ELSE IF (Validation.ExpireTo <> ' ') AND (NOT (Validation.ExpireTo IN ValKeys)) THEN
          BEGIN
            Print('%LF^8The expiration level does not exist for level: "'+Level+'"!^0');
            Level := #0;
          END
          ELSE IF (User.SL = Validation.NewSL) AND (User.DSL = Validation.NewDSL) AND
             ARMatch(Validation.SoftAR,User.ARFlags,Validation.NewAR) AND
             ACMatch(Validation.SoftAC,User.ACFlags,Validation.NewAC) THEN
          BEGIN
            Print('%LF^8This user is already validated at level "'+Level+'"!^0');
            Level := #0;
          END
          ELSE
          BEGIN
            Print('%LF^0Description: ^1'+Validation.Description);
            Print('%LF^0       < Old Settings >                   < New Settings >');
            Print('%LF^0Sub: ^1'+PadLeftStr(User.Subscription,30)+'^0Sub: ^1'+Level);
            Print('^0SL : ^1'+PadLeftInt(User.SL,30)+'^0SL : ^1'+IntToStr(Validation.NewSL));
            Print('^0DSL: ^1'+PadLeftInt(User.DSL,30)+'^0DSL: ^1'+IntToStr(Validation.NewDSL));
            TempAR := User.ARFlags;
            IF (Validation.SoftAR) THEN
              TempAR := (TempAR + Validation.NewAR)
            ELSE
              TempAR := Validation.NewAR;
            Print('^0AR : ^1'+PadLeftStr(DisplayARFlags(User.ARFlags,'5','1'),30)+'^0AR : ^1'+DisplayArFlags(TempAR,'5','1'));
            TempAC := User.ACFlags;
            IF (NOT Validation.SoftAC) THEN
              TempAC := (TempAC - Settings);
            TempAC := (TempAC + (Validation.NewAC * Settings));
            Print('^0AC : ^1'+PadLeftStr(DisplayACFlags(User.ACFlags,'5','1'),30)+'^0AC : ^1'+DisplayACFlags(TempAC,'5','1'));
            Print('^0FP : ^1'+PadLeftInt(User.FilePoints,30)+'^0FP : ^1'+IntToStr(User.FilePoints + Validation.NewFP));
            Print('^0Crd: ^1'+PadLeftInt(User.lCredit,30)+'^0Crd: ^1'+IntToStr(User.lCredit + Validation.NewCredit));
            Print('^0Mnu: ^1'+PadLeftInt(User.UserStartMenu,30)+'^0Mnu: ^1'+IntToStr(Validation.NewMenu));
            Print('^0ExD: ^1'+PadLeftStr(AOnOff((User.Expiration > 0),ToDate8(PD2Date(User.Expiration)),'Never'),30)+
                  '^0ExD: ^1'+AOnOff((Validation.Expiration > 0),
                                      ToDate8(PD2Date(GetPackDateTime + (Validation.Expiration * 86400))),
                                     'Never'));
            Print('^0ExS: ^1'+PadLeftStr(AOnOff(User.ExpireTo = ' ','No Change',User.ExpireTo),30)+
                  '^0ExS: ^1'+AOnOff(Validation.ExpireTo = ' ','No Change',Validation.ExpireTo));
            IF (NOT PYNQ('%LFContinue validating user at this level? ',0,FALSE)) THEN
              Level := #0;
          END;
        END;
      END;
    END;
  UNTIL (Level IN ValKeys) OR (Level = 'Q') OR (HangUp);
  IF (Level IN ValKeys) THEN
  BEGIN
    AutoValidate(User,UNum,Level);
    Print('%LFThis user was validated using validation level "'+Level+'".');
    SendShortMessage(UNum,Validation.UserMsg);
    LoadURec(User,UNum);
    SysOpLog('Validated '+Caps(User.Name)+' with validation level "'+Level+'".');
  END;
END;

PROCEDURE AutoValidationCmd(MenuOption: Str50);
VAR
  Level: Char;
  PW,
  TempPW: Str20;
  RecNum,
  RecNum1: Integer;
BEGIN
  IF (MenuOption = '') OR (Pos(';',MenuOption) = 0) OR
     (Copy(MenuOption,(Pos(';',MenuOption) + 1),1) = '') OR
     (Copy(MenuOption,1,(Pos(';',MenuOption) - 1)) = '') THEN
  BEGIN
    Print('%LF^8Command error, operation aborted!^0');
    SysOpLog('^8Auto-validation command error, invalid options!');
    Exit;
  END;
  PW := AllCaps(Copy(MenuOption,1,(Pos(';',MenuOption) - 1)));
  MenuOption := Copy(MenuOption,(Pos(';',MenuOption) + 1),1);
  Level := MenuOption[1];
  IF (NOT (Level IN ValKeys)) THEN
  BEGIN
    Print('%LF^8Command error, operation aborted!^0');
    SysOpLog('^8Auto-validation command error, level not found: '+Level+'!');
    Exit;
  END;
  Reset(ValidationFile);
  RecNum1 := -1;
  RecNum:= 1;
  WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
  BEGIN
    Seek(ValidationFile,(RecNum - 1));
    Read(ValidationFile,Validation);
    IF (Validation.Key = Level) THEN
      RecNum1 := RecNum;
    Inc(RecNum);
  END;
  Close(ValidationFile);
  LastError := IOResult;
  IF (Validation.Expiration = 0) AND (Validation.ExpireTo <> ' ') OR
     (Validation.Expiration <> 0) AND (Validation.ExpireTo = ' ') THEN
  BEGIN
    Print('%LF^8Command error, operation aborted!^0');
    SysOpLog('^8Auto-validation command error, expiration data invalid: "'+Level+'"!');
    Exit;
  END
  ELSE IF (Validation.ExpireTo <> ' ') AND (NOT (Validation.ExpireTo IN ValKeys)) THEN
  BEGIN
    Print('%LF^8Command error, operation aborted!^0');
    SysOpLog('^8Auto-validation command error, expire to level "'+Validation.ExpireTo+'" does not exists!');
    Exit;
  END
  ELSE IF (ThisUser.SL = Validation.NewSL) AND (ThisUser.DSL = Validation.NewDSL) AND
     ARMatch(Validation.SoftAR,ThisUser.ARFlags,Validation.NewAR) AND
     ACMatch(Validation.SoftAC,ThisUser.ACFlags,Validation.NewAC) THEN
  BEGIN
    Print('%LF^8You have already been validated at this access level!^0');
    SysOpLog('User error, previously validated at level: "'+Level+'".');
    Exit;
  END
  ELSE IF (ThisUser.SL > Validation.NewSL) OR (ThisUser.DSL > Validation.NewDSL) THEN
  BEGIN
    Print('%LF^8This option would lower your access level!^0');
    SysOpLog('User error, access would be lowered to level: "'+Level+'".');
    Exit;
  END;
  Print('%LFPress <ENTER> to abort.');
  Prt('%LFPassword: ');
  InputMain(TempPW,SizeOf(TempPW)-1,[IsPassword]); {GetPassword(TempPW,20);}
  IF (TempPW = '') THEN
  BEGIN
    Print('%LFAborted.');
    Exit;
  END;
  IF (TempPW <> PW) THEN
  BEGIN
    Print('%LF^8Incorrect password entered!^0');
    SysOpLog('User error, invalid password entered: "'+TempPW+'"');
    Exit;
  END;
  AutoValidate(ThisUser,UserNum,Level);
  lStatus_Screen(100,'This user has auto-validated '
                 +AOnOff(ThisUser.Sex = 'M','himself','herself')+' with level: "'+Level+'".',FALSE,TempPW);
  PrintF('AUTOVAL');
  IF (NoFile) THEN
    Print('%LF'+Validation.UserMsg);
  SysOpLog('This user has auto-validated '+AOnOff(ThisUser.Sex = 'M','himself','herself')+' with level: "'+Level+'".');
END;

PROCEDURE ValidationEditor;
VAR
  TempValidation: ValidationRecordType;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  PROCEDURE InitValidateVars(VAR Validation: ValidationRecordType);
  VAR
    User: UserRecordType;
  BEGIN
    LoadURec(User,0);
    FillChar(Validation,SizeOf(Validation),0);
    WITH Validation DO
    BEGIN
      Key := ' ';
      ExpireTo := ' ';
      Description := '<< New Validation Record >>';
      UserMsg := 'You have been validated, enjoy the system!';
      NewSL := User.SL;
      NewDSL := User.DSL;
      NewMenu := 0;
      Expiration := 0;
      NewFP := 0;
      NewCredit := 0;
      SoftAR := TRUE;
      SoftAC := TRUE;
      NewAR := [];
      NewAC := [];
    END;
  END;

  PROCEDURE DeleteValidationLevel(TempValidation1: ValidationRecordType; RecNumToDelete: Integer);
  VAR
    User: UserRecordType;
    RecNum: Integer;
  BEGIN
    IF (NumValKeys = 0) THEN
      Messages(4,0,'validation records')
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputIntegerWOC('%LFValidation record to delete?',RecNumToDelete,[NumbersOnly],1,NumValKeys);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumValKeys) THEN
      BEGIN
        Reset(ValidationFile);
        Seek(ValidationFile,(RecNumToDelete - 1));
        Read(ValidationFile,TempValidation1);
        Close(ValidationFile);
        LastError := IOResult;
        IF (TempValidation1.Key = '!') THEN
        BEGIN
          Print('%LFYou can not delete the new user validation key.');
          PauseScr(FALSE);
        END
        ELSE
        BEGIN
          Print('%LFValidation: ^1'+TempValidation1.Description);
          IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
          BEGIN
            Print('%LF[> Deleting validation record ...');
            FOR RecNum := 1 TO (MaxUsers - 1) DO
            BEGIN
              LoadURec(User,RecNum);
              IF (User.ExpireTo = TempValidation1.Key) THEN
              BEGIN
                User.ExpireTo := ' ';
                User.Expiration := 0;
              END;
              SaveURec(User,RecNum);
            END;
            Exclude(ValKeys,TempValidation1.Key);
            Dec(RecNumToDelete);
            Reset(ValidationFile);
            IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(ValidationFile) - 2)) THEN
              FOR RecNum := RecNumToDelete TO (FileSize(ValidationFile) - 2) DO
              BEGIN
                Seek(ValidationFile,(RecNum + 1));
                Read(ValidationFile,Validation);
                Seek(ValidationFile,RecNum);
                Write(ValidationFile,Validation);
              END;
            Seek(ValidationFile,(FileSize(ValidationFile) - 1));
            Truncate(ValidationFile);
            Close(ValidationFile);
            LastError := IOResult;
            Dec(NumValKeys);
            SysOpLog('* Deleted validation record: ^1'+TempValidation1.Description);
          END;
        END;
      END;
    END;
  END;

  PROCEDURE CheckValidationLevel(Validation: ValidationRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Validation.Description = '') OR (Validation.Description = '<< New Validation Record >>') THEN
            BEGIN
              Print('%LF^8The description is invalid!^0');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditValidationLevel(TempValidation1: ValidationRecordType; VAR Validation: ValidationRecordType; VAR Cmd1: Char;
                                VAR RecNumToEdit: Integer; VAR Changed: Boolean; Editing: Boolean);
  VAR
    User: UserRecordType;
    CmdStr,
    OneKCmds: AStr;
    Cmd2: Char;
    RecNumToList: Integer;
    Ok,
    SaveUpgrade: Boolean;
  BEGIN
    WITH Validation DO
      REPEAT
        IF (Cmd1 <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            IF (Editing) THEN
              ConfigHeader('Editing Validation Record #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumValKeys))
            ELSE
              ConfigHeader('Inserting Validation Record #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumValKeys + 1));
          PrintACR('^0(^1A^0) Key         : ^1'+Key);
          PrintACR('^0(^1B^0) Description : ^1'+Description);
          PrintACR('^0(^1C^0) Message     : ^1'+AOnOff(UserMsg='','*None*',UserMsg));
          PrintACR('^0(^1D^0) SL          : ^1'+IntToStr(NewSL));
          PrintACR('^0(^1E^0) DSL         : ^1'+IntToStr(NewDSL));
          PrintACR('^0(^1G^0) AR Flags    : ^1'+DisplayARFlags(NewAR,'1','0')+
                   '^0 Upgrade: ^1'+AOnOff(SoftAR,'Soft','Hard'));
          PrintACR('^0(^1H^0) AC Flags    : ^1'+DisplayACFlags(NewAC,'1','0')+
                   '^0 Upgrade: ^1'+AOnOff(SoftAC,'Soft','Hard'));
          PrintACR('^0(^1I^0) File Points : ^1'+IntToStr(NewFP));
          PrintACR('^0(^1K^0) Credits     : ^1'+IntToStr(NewCredit));
          PrintACR('^0(^1M^0) Start Menu  : ^1'+IntToStr(NewMenu));
          PrintACR('^0(^1N^0) Expiration  : Days: ^1'+AOnOff((Expiration > 0),IntToStr(Expiration),'No Expiration')+
                   '^0 Level: ^1'+AOnOff((ExpireTo IN ['!'..'~']),ExpireTo,'No Change'));
        END;
        IF (NOT Editing) THEN
          CmdStr := 'ABCDEGHIKMN'
        ELSE
          CmdStr := 'ABCDEGHIKMN[]FJL';
        NL;
        LOneK('Modify Validation Level [^1[]FLJ^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'Q?'+CmdStr{+^M},TRUE,TRUE);
        CASE Cmd1 OF
          'A' : BEGIN
                  Print('%LF^8You can not modify the validation key.');
                  PauseScr(FALSE);
                END;
          'B' : IF (Validation.Key = '!') THEN
                BEGIN
                  Print('%LF^8You can not modify the new user description.');
                  PauseScr(FALSE);
                END
                ELSE
                  REPEAT
                    TempValidation1.Description := Description;
                    Ok := TRUE;
                    InputWN1('%LFNew description: ',Description,(SizeOf(Description) - 1),[InterActiveEdit],Changed);
                    CheckValidationLevel(Validation,1,1,Ok);
                    IF (NOT Ok) THEN
                      Description := TempValidation1.Description;
                  UNTIL (Ok) OR (HangUp);
          'C' : InputWN1('%LF^0New user message:%LF^2:',UserMsg,(SizeOf(UserMsg) - 1),[InterActiveEdit],Changed);
          'D' : BEGIN
                  LoadURec(User,0);
                  REPEAT
                    InputByteWC('%LFEnter new SL',NewSL,[DisplayValue,NumbersOnly],User.SL,255,Changed);
                  UNTIL (NewSL >= User.SL) OR (HangUp);
                END;
          'E' : BEGIN
                  LoadURec(User,0);
                  REPEAT
                    InputByteWC('%LFEnter new DSL',NewDSL,[DisplayValue,NumbersOnly],User.DSL,255,Changed);
                  UNTIL (NewDSL >= User.DSL) OR (HangUp);
                END;
          'G' : BEGIN
                  REPEAT
                    LOneK('%LFToggle which AR flag? ('+DisplayARFlags(NewAR,'5','4')+'^2)'+
                        ' [^1*^2=^1All^2,^1?^2=^1Help^2,^1<CR>^2=^1Quit^2]: ',
                        Cmd1,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ*?',TRUE,TRUE);
                    IF (Cmd1 = '?') THEN
                      PrintF('ARFLAGS')
                    ELSE IF (Cmd1 IN ['A'..'Z']) THEN
                      ToggleARFlag(Cmd1,NewAR,Changed)
                    ELSE IF (Cmd1 = '*') THEN
                      FOR Cmd2 := 'A' TO 'Z' DO
                        ToggleARFlag(Cmd2,NewAr,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  SaveUpgrade := SoftAR;
                  SoftAR := NOT PYNQ('%LFShould the AR upgrade be hard? ',0,FALSE);
                  IF (SaveUpgrade <> SoftAR) THEN
                    Changed := TRUE;
                  Cmd1 := #0;
                END;
          'H' : BEGIN
                  REPEAT
                    LOneK('%LFToggle which AC flag? ('+DisplayACFlags(NewAC,'5','4')+'^2)'+
                        ' [^1?^2=^1Help^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'LCVUA*PEKM1234?',TRUE,TRUE);
                    IF (Cmd1 = '?') THEN
                      PrintF('ACFLAGS')
                    ELSE IF (Cmd1 <> ^M) THEN
                      ToggleACFlags(Cmd1,NewAC,Changed);
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  SaveUpgrade := SoftAC;
                  SoftAC := NOT PYNQ('%LFShould the AC upgrade be hard? ',0,FALSE);
                  IF (SaveUpgrade <> SoftAC) THEN
                    Changed := TRUE;
                  Cmd1 := #0;
                END;
          'I' : InputLongIntWC('%LFEnter additional file points',NewFP,
                               [DisplayValue,NumbersOnly],0,2147483647,Changed);
          'K' : InputLongIntWC('%LFEnter additional credit',NewCredit,[DisplayValue,NumbersOnly],0,2147483647,Changed);
          'M' : FindMenu('%LFEnter start menu (^10^2=^1Default^2)',NewMenu,0,NumMenus,Changed);
          'N' : IF (Validation.Key = '!') THEN
                  BEGIN
                    Print('%LF^8You can not modify the new user expiration days or level.');
                    PauseScr(FALSE);
                  END
                ELSE
                  BEGIN
                    InputWordWC('%LF^2Enter days until expiration',Expiration,[InterActiveEdit{DisplayValue},
                        NumbersOnly],0,65535,Changed);
                    IF (Expiration <> 0) THEN
                      BEGIN
                        OneKCmds := '';
                        FOR Cmd2 := '!' TO '~' DO
                          IF (Cmd2 IN ValKeys) THEN
                            IF (NOT (Cmd2 = Key)) THEN
                              OneKCmds := OneKCmds + Cmd2;
                        Prt('%LF^2Enter expiration level (^1!^2-^1P^2,^1R^2-^1p^2,^1r^2-^1~^2) [<Space>Abort]: ');
                        OneK1(Cmd1,^M' '+OneKCmds,TRUE,TRUE);
                        IF (Cmd1 = ' ') THEN
                          BEGIN
                            ExpireTo := ' ';
                            Expiration := 0;
                            Changed := TRUE;
                          END
                      ELSE IF (Cmd1 IN ValKeys) THEN
                        BEGIN
                          IF (Cmd1 <> ExpireTo) THEN
                            Changed := TRUE;
                          ExpireTo := Cmd1;
                        END;
                    END
                  ELSE
                    BEGIN
                      ExpireTo := ' ';
                      {Changed := TRUE;}
                    END;
                  Cmd1 := #0;
                  Cmd2 := #0;
                  END;
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumValKeys) THEN
                  Inc(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          'F' : IF (RecNumToEdit <> 1) THEN
                  RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          'J' : BEGIN
                  InputIntegerWOC('%LFJump to entry',RecNumToEdit,[NumbersOnly],1,NumValKeys);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumValKeys) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumValKeys) THEN
                  RecNumToEdit := NumValKeys
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  {
                  Print('%LF^0<^1CR^0>Redisplay current screen');
                  Print('^1A^0-^1E^0,^1G^0-^1I^0,^1K^0,^1M^0-^1N^0:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,3,'Quit and save','')
                  ELSE
                  }
                  BEGIN
                    NL;
                    LCmds(17,1,'[Previous Record',']Next Record');
                    LCmds(17,1,'First Record','Last Record');
                    LCmds(17,1,'Jump To Record',''{'Quit and save'});
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertValidationLevel(TempValidation1: ValidationRecordType; Cmd1: Char; RecNumToInsertBefore: Integer);
  VAR
    OneKCmds: AStr;
    RecNum,
    RecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumValKeys = MaxValKeys) THEN
      Messages(5,MaxValKeys,'validation records') {"No more than # validation records can exist!"}
    ELSE
      BEGIN
        RecNumToInsertBefore := -1;
        InputIntegerWOC('%LFValidation record to insert before?',RecNumToInsertBefore,[NumbersOnly],1,(NumValKeys + 1));
        IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumValKeys + 1)) THEN
          BEGIN
            OneKCmds := '';
            FOR Cmd1 := '!' TO '~' DO
              IF (NOT (Cmd1 IN ValKeys)) AND (NOT (Cmd1 = 'Q')) AND (NOT (Cmd1 = 'q')) THEN
                OneKCmds := OneKCmds + Cmd1;
            Prt('%LFChoose validation key (^1!^2-^1P^2,^1R^2-^1p^2,^1r^2-^1~^2) [^1<CR>^2=^1Quit^2]: ');
            OneK1(Cmd1,^M+OneKCmds,TRUE,TRUE);
            IF (Cmd1 <> ^M) THEN
              BEGIN
                Reset(ValidationFile);
                InitValidateVars(TempValidation1);
                TempValidation1.Key := Cmd1;
                IF (RecNumToInsertBefore = 1) THEN
                  RecNumToEdit := 1
                ELSE IF (RecNumToInsertBefore = (NumValKeys + 1)) THEN
                  RecNumToEdit := (NumValKeys + 1)
                ELSE
                  RecNumToEdit := RecNumToInsertBefore;
                REPEAT
                  OK := TRUE;
                  EditValidationLevel(TempValidation1,TempValidation1,Cmd1,RecNumToEdit,Changed,FALSE);
                  CheckValidationLevel(TempValidation1,1,1,Ok);
                  IF (NOT OK) THEN
                    IF (NOT PYNQ('%LFContinue inserting validation record? ',0,TRUE)) THEN
                      Abort := TRUE;
                UNTIL (OK) OR (Abort) OR (HangUp);
                IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
                  BEGIN
                    Include(ValKeys,Cmd1);
                    Print('%LF^9[> Inserting validation record ...^0');
                    Seek(ValidationFile,FileSize(ValidationFile));
                    Write(ValidationFile,Validation);
                    Dec(RecNumToInsertBefore);
                    FOR RecNum := ((FileSize(ValidationFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
                      BEGIN
                        Seek(ValidationFile,RecNum);
                        Read(ValidationFile,Validation);
                        Seek(ValidationFile,(RecNum + 1));
                        Write(ValidationFile,Validation);
                      END;
                    FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
                      BEGIN
                        Seek(ValidationFile,RecNum);
                        Write(ValidationFile,TempValidation1);
                        Inc(NumValKeys);
                        SysOpLog('* Inserted validation record: ^1'+TempValidation1.Description);
                      END;
                  END;
                Close(ValidationFile);
                LastError := IOResult;
              END;
          END;
      END;
  END;

  PROCEDURE ModifyValidationLevel(TempValidation1: ValidationRecordType; Cmd1: Char; RecNumToEdit: Integer);
  VAR
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumValKeys = 0) THEN
      Messages(4,0,'validation records') {"No validation records exist!"}
    ELSE
      BEGIN
        RecNumToEdit := -1;
        InputIntegerWOC('%LF^2Modify which validation record?',RecNumToEdit,[NumbersOnly],1,NumValKeys);
        IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumValKeys) THEN
          BEGIN
            SaveRecNumToEdit := -1;
            Cmd1 := #0;
            Reset(ValidationFile);
            WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
              BEGIN
                IF (SaveRecNumToEdit <> RecNumToEdit) THEN
                  BEGIN
                    Seek(ValidationFile,(RecNumToEdit - 1));
                    Read(ValidationFile,Validation);
                    SaveRecNumToEdit := RecNumToEdit;
                    Changed := FALSE;
                  END;
                REPEAT
                  Ok := TRUE;
                  EditValidationLevel(TempValidation1,Validation,Cmd1,RecNumToEdit,Changed,TRUE);
                  CheckValidationLevel(Validation,1,1,Ok);
                  IF (NOT OK) THEN
                    BEGIN
                      PauseScr(FALSE);
                      IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                        RecNumToEdit := SaveRecNumToEdit;
                    END;
                UNTIL (OK) OR (HangUp);
                IF (Changed) THEN
                  BEGIN
                    Seek(ValidationFile,(SaveRecNumToEdit - 1));
                    Write(ValidationFile,Validation);
                    Changed := FALSE;
                    SysOpLog('* Modified validation record: ^1'+Validation.Description);
                  END;
              END;
            Close(ValidationFile);
            LastError := IOResult;
          END;
      END;
  END;

  PROCEDURE PositionValidationLevel(TempValidation1: ValidationRecordType; RecNumToPosition: Integer);
  VAR
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (NumValKeys = 0) THEN
      Messages(4,0,'validation records') {"No validation records exist!"}
    ELSE IF (NumValKeys = 1) THEN
      Messages(6,0,'validation records') {"No validation records to position!"}
    ELSE
      BEGIN
        RecNumToPosition := -1;
        InputIntegerWOC('%LF^2Position which validation record?',RecNumToPosition,[NumbersOnly],1,NumValKeys);
        IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumValKeys) THEN
          BEGIN
            Print('%LF^0According to the CURRENT numbering system ...');
            RecNumToPositionBefore := -1;
            InputIntegerWOC('%LF^2Position before which validation record?',RecNumToPositionBefore,[NumbersOnly],1,
                        (NumValKeys + 1));
            IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumValKeys + 1)) AND
               (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
              BEGIN
                Print('%LF^9[> Positioning validation records ...^0');
                Reset(ValidationFile);
                IF (RecNumToPositionBefore > RecNumToPosition) THEN
                  Dec(RecNumToPositionBefore);
                Dec(RecNumToPosition);
                Dec(RecNumToPositionBefore);
                Seek(ValidationFile,RecNumToPosition);
                Read(ValidationFile,TempValidation1);
                RecNum1 := RecNumToPosition;
                IF (RecNumToPosition > RecNumToPositionBefore) THEN
                  RecNum2 := -1
                ELSE
                  RecNum2 := 1;
                WHILE (RecNum1 <> RecNumToPositionBefore) DO
                  BEGIN
                    IF ((RecNum1 + RecNum2) < FileSize(ValidationFile)) THEN
                      BEGIN
                        Seek(ValidationFile,(RecNum1 + RecNum2));
                        Read(ValidationFile,Validation);
                        Seek(ValidationFile,RecNum1);
                        Write(ValidationFile,Validation);
                      END;
                    Inc(RecNum1,RecNum2);
                  END;
                Seek(ValidationFile,RecNumToPositionBefore);
                Write(ValidationFile,TempValidation1);
                Close(ValidationFile);
                LastError := IOResult;
              END;
          END;
      END;
    {PauseScr(FALSE);}
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      DisplayValidationRecords(RecNumToList);
    NL;
    LOneK('^2Validation Editor [^1DIMP^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'Q?DIMP'^M,TRUE,TRUE);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumValKeys) THEN
              RecNumToList := 1;
      'D' : DeleteValidationLevel(TempValidation,RecNumToList);
      'I' : InsertValidationLevel(TempValidation,Cmd,RecNumToList);
      'M' : ModifyValidationLevel(TempValidation,Cmd,RecNumToList);
      'P' : PositionValidationLevel(TempValidation,RecNumToList);
      '?' : BEGIN
              NL;
              Print('^0<^1CR^0>Next Page / Refresh');
              {Print('^0(^1?^0)Help/First validation level');}
              LCmds(24,1,'Delete Validation Level','Insert Validation Level');
              LCmds(24,1,'Modify Validation Level','Position Validation Level');
              {LCmds(24,1,'Quit','');}
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;
END.