{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
temporarily bypassed newuserq toggles, going to implement new system
stopped newuser application putting caller id in sysop note since it has its own place already

OQ invalid menu command happening line 116
}
UNIT NewUsers;

INTERFACE

PROCEDURE NewUser;
PROCEDURE NewUserInit;

IMPLEMENTATION

USES
  Common,
  CUser,
  EMail,
  Mail0,
  Menus,
  MiscUser,
  Script,
  SysOp2G,
  TimeFunc;

PROCEDURE NewUser;
VAR
  Letter: Text;
  User: UserRecordType;
  UserIDX: UserIDXRec;
  MHeader: MHeaderRec;
  TempStr: STRING;
  Cmd,
  NewMenuCmd: AStr;
  NewUserPassword: Str20;
  SaveMenu,
  PasswordAttemps,
  CmdToExec: Byte;
  Counter,
  Counter1,
  TempNewApp: Integer;
  CmdNotHid,
  CmdExists,
  Done: Boolean;
BEGIN
  {SL1('* New user logon');}
  SysOpLog('^9[*] ^1New user applying ...');

  UserNum := 0;

  Update_Node(lRGLngStr(146,TRUE){'New user logging on'},TRUE);

  UserNum := -1;

  IF (General.NewUserPW <> '') THEN
    BEGIN
      PasswordAttemps := 0;
      NewUserPassword := '';
      WHILE ((NewUserPassword <> General.NewUserPW) AND (PasswordAttemps < General.MaxLogonTries) AND (NOT HangUp)) DO
        BEGIN
          lRGLngStr(190,FALSE); (*Prt(FString.NewUserPassword);*)
          InputMain(NewUserPassword,SizeOf(NewUserPassword)-1,[IsPassword]); {GetPassword(NewUserPassword,20);}
          IF ((NewUserPassword <> '') AND (General.NewUserPW <> NewUserPassword)) THEN
            BEGIN
              lRGLngStr(148,FALSE); (*Print('Invalid password, keep trying ...');*)
              SL1('* Invalid new user password: '+NewUserPassword);
              Inc(PasswordAttemps);
            END;
        END;
      IF (PasswordAttemps >= General.MaxLogonTries) THEN
        BEGIN
          PrintF('NUPWFAIL');
          IF (NoFile) THEN
            lRGLngStr(149,FALSE); (*Print('You have exceeded the maximum new user logon attempts, hanging up ...');*)
          SL1('* Maximum new user logon attempts exceeded - hung user up.');
          HangUp := TRUE;
        END;
    END;

  IF (NOT HangUp) THEN
    BEGIN
      PrintF('NEWUSER');
      Counter := 1;
      WHILE (Counter <= 26) AND (NOT HangUp) DO
        BEGIN
          IF (General.NewUserQToggles[Counter] = TRUE) THEN
            BEGIN
              Update_Screen;
              CStuff(Counter,1,ThisUser);
            END;
          Inc(Counter);
        END;

    Abort := FALSE;
    Next := FALSE;

    SaveMenu := CurMenu;
    CurMenu := General.NewUserInformationMenu;
    LoadMenuPW;
    AutoExecCmd('FIRSTCMD');
    REPEAT
      MainMenuHandle(Cmd);
      NewMenuCmd := '';
      CmdToExec := 0;
      Done := FALSE;
      REPEAT
        FCmd(Cmd,CmdToExec,CmdExists,CmdNotHid);
        IF (CmdToExec <> 0) THEN
        BEGIN
          DoMenuCommand(Done,
                        MemCmd^[CmdToExec].CmdKeys,
                        MemCmd^[CmdToExec].Options,
                        NewMenuCmd,
                        MemCmd^[CmdToExec].NodeActivityDesc);

          IF (MemCmd^[CmdToExec].CmdKeys = 'OQ') THEN
            Abort := TRUE;

        END;
      UNTIL (CmdToExec = 0) OR (Done) OR (HangUp);
    UNTIL (Abort) OR (Next) OR (HangUp);
    CurMenu := SaveMenu;
    NewMenuToLoad := TRUE;
    LastError := IOResult;

  END;
  IF (NOT HangUp) THEN
  BEGIN
    lRGLngStr(150,FALSE); (*Prompt('Saving your information ... ');*)
    SysOpLog('Saving new user information ...');
    Counter1 := 0;
    Counter := 1;
    Reset(UserIDXFile);
    WHILE (Counter <= (FileSize(UserIDXFile) - 1)) AND (Counter1 = 0) DO
    BEGIN
      Read(UserIDXFile,UserIDX);
      IF (UserIDX.Deleted) THEN
      BEGIN
        LoadURec(User,UserIDX.Number);
        IF (Deleted IN User.SFlags) THEN
          Counter1 := UserIDX.Number;
      END;
      Inc(Counter);
    END;
    Close(UserIDXFile);
    LastError := IOResult;
    IF (Counter1 > 0) THEN
      UserNum := Counter1
    ELSE
      UserNum := MaxUsers;
    WITH ThisUser DO
    BEGIN
      FirstOn := GetPackDateTime;
      LastOn := FirstOn;
      IF (CallerIDNumber <> '') THEN
      BEGIN
        CallerID := CallerIDNumber;
        {Note := CallerID;} {LeeW: Removed -- no need to display in 2 places}
      END;
    END;

    SaveURec(ThisUser,UserNum);

    AutoValidate(ThisUser,UserNum,'!');

    InsertIndex(ThisUser.Name,UserNum,FALSE,FALSE);
    InsertIndex(ThisUser.Realname,UserNum,TRUE,FALSE);
    Inc(lTodayNumUsers);
    SaveGeneral(TRUE);
    (*
    Print('^1Saved.');
    *)
    lRGLngStr(151,FALSE);
    SysOpLog('Saved as user #'+IntToStr(UserNum));
    UserOn := TRUE;
    WasNewUser := TRUE;
  END;
  IF (NOT HangUp) THEN
  BEGIN
    CLS;
    IF ((Exist(General.MiscPath+'NEWUSER.INF')) OR (Exist(General.DataPath+'NEWUSER.INF'))) THEN
      ReadQ('NEWUSER');
    Update_Screen;
    TempNewApp := -1;
    IF (General.NewApp <> -1) THEN
    BEGIN
      TempNewApp := General.NewApp;
      IF (TempNewApp < 1) OR (TempNewApp > (MaxUsers - 1)) THEN
      BEGIN
        SL1('* Invalid user number for New User Application: '+IntToStr(General.NewApp));
        TempNewApp := 1;
      END;
    END;
    IF (TempNewApp <> -1) THEN
    BEGIN
      PrintF('NEWAPP');
      IF (NoFile) THEN
        (*
        Print('You must now send a new user application letter to the SysOp.');
        *)
        lRGLngStr(152,FALSE);
      InResponseTo := '\'+#1+lRGLngStr(153,TRUE); { 'New User Application' }
      MHeader.Status := [];
      SeMail(TempNewApp,MHeader);
    END;
  END;
  IF (NOT HangUp) THEN
  BEGIN
    IF (Exist(General.MiscPath+'NEWLET.ASC')) THEN
    BEGIN
      FillChar(MHeader,SizeOf(MHeader),0);
      InitMsgArea(-1);
      Reset(MsgHdrF);
      Seek(MsgHdrF,FileSize(MsgHdrF));
      Reset(MsgTxtF,1);
      Seek(MsgTxtF,FileSize(MsgTxtF));
      MHeader.Pointer := (FileSize(MsgTxtF) + 1);
      MHeader.TextSize := 0;
      Assign(Letter,General.MiscPath+'NEWLET.ASC');
      Reset(Letter);
      ReadLn(Letter,MHeader.From.A1S);
      ReadLn(Letter,MHeader.Subject);
      WITH MHeader DO
      BEGIN
        From.UserNum := TempNewApp;
        MTO.UserNum := UserNum;
        MTO.A1S := ThisUser.Name;
        Date := GetPackDateTime;
        Status := [AllowMCI];
      END;
      WHILE NOT EOF(Letter) DO
      BEGIN
        ReadLn(Letter,TempStr);
        Inc(MHeader.TextSize,(Length(TempStr) + 1));
        BlockWrite(MsgTxtF,TempStr[0],(Length(TempStr) + 1));
      END;
      Close(Letter);
      Close(MsgTxtF);
      Write(MsgHdrF,MHeader);
      Close(MsgHdrF);
      LastError := IOResult;
      ThisUser.Waiting := 1;
    END;
  END;
END;

PROCEDURE NewUserInit;
BEGIN
  IF (General.ClosedSystem) THEN
  BEGIN
    PrintF('NONEWUSR');
    IF (NoFile) THEN
      (*
      Print('This BBS is currently not accepting new users, hanging up ...');
      *)
      lRGLngStr(142,FALSE);
    SL1('* Attempted logon when BBS closed to new users - hung user up.');
    HangUp := TRUE;
  END
  ELSE
  BEGIN
    LoadURec(ThisUser,0);
    WITH ThisUser DO
    BEGIN
      FirstOn := GetPackDateTime;
      LastOn := FirstOn;
    END;
    InitTrapFile;
  END;
END;

END.
