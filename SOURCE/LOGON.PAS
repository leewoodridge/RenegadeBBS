{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 07/31/2022 - Removed inputfield from sysoppw prompt
Added: Disabled forgotpw question for CoSysOp+
Added: Won't prompt for SysOpPW if blank
        or phonepw if blank or toggle disabled
        or bdaycheck if = -1869054590 or toggle disabled
}
UNIT Logon;

INTERFACE

FUNCTION GetUser: Boolean;

IMPLEMENTATION

USES
  CRT,
  Common,
  Archive1,
  CUser,
  Doors,
  Email,
  Events,
  Mail0,
  Mail1,
  Maint,
  Menus,
  Menus2,
  NewUsers,
  ShortMsg,
  SysOp2G,
  TimeFunc,
  MiscUser;

VAR
  GotName: Boolean;
  OldUser: UserRecordType;

FUNCTION Hex(i: LongInt; j: Byte): STRING;
CONST
  HC : ARRAY [0..15] OF Char = '0123456789ABCDEF';
VAR
  One,
  Two,
  Three,
  Four: Byte;
BEGIN
  One := (i AND $000000FF);
  Two := (i AND $0000FF00) SHR 8;
  Three := (i AND $00FF0000) SHR 16;
  Four := (i AND $FF000000) SHR 24;
  Hex[0] := chr(j); { Length of string = 4 or 8}
  IF (j = 4) THEN
    BEGIN
      Hex[1] := HC[Two SHR 4];
      Hex[2] := HC[Two AND $F];
      Hex[3] := HC[One SHR 4];
      Hex[4] := HC[One AND $F];
    END
  ELSE
    BEGIN
      Hex[8] := HC[One AND $F];
      Hex[7] := HC[One SHR 4];
      Hex[6] := HC[Two AND $F];
      Hex[5] := HC[Two SHR 4];
      Hex[4] := HC[Three AND $F];
      Hex[3] := HC[Three SHR 4];
      Hex[2] := HC[Four AND $F];
      Hex[1] := HC[Four SHR 4];
    END;
END;

PROCEDURE IEMSI;
VAR
  Tries: Byte;
  T1,T2: LongInt;
  Emsi_Irq: STRING[20];
  Done,Success: Boolean;
  S,Isi: STRING;
  C: Char;
  I: Integer;
  Buffer: ARRAY [1..2048] OF Char;
  Buffptr: Integer;
  User: UserRecordType;
  NextItemPointer: Integer;

  FUNCTION NextItem: STRING;
  VAR
    S: AStr;
  BEGIN
    S := '';
    WHILE (NextItemPointer < 2048) AND (Buffer[NextItemPointer] <> #0) AND (Buffer [NextItemPointer] <> '{') DO
      Inc(NextItemPointer);
    IF (Buffer[NextItemPointer] = '{') THEN
      Inc(NextItemPointer);
    WHILE (NextItemPointer < 2048) AND (Buffer[NextItemPointer] <> #0) AND (Buffer [NextItemPointer] <> '}') DO
      BEGIN
        S := S + Buffer[NextItemPointer];
        Inc(NextItemPointer);
      END;
    IF (Buffer[NextItemPointer] = '}') THEN
      Inc(NextItemPointer);
    NextItem := S;
  END;

BEGIN
  FillChar(IEMSIRec,SizeOf(IEMSIRec),0);
  IF (ComPortSpeed = 0) OR (NOT General.UseIEMSI) THEN
    Exit;
  (* Should this be Prompt ???
  Write('Attempting IEMSI negotiation ... ');
  *)
  Write(lRGLngStr(131,TRUE));
  FillChar(Buffer,SizeOf(Buffer),0);
  T1 := Timer;
  T2 := Timer;
  Tries := 0;
  Done := FALSE;
  Success := FALSE;
  Emsi_Irq := '**EMSI_IRQ8E08'^M^L;
  Com_Flush_Recv;
  SerialOut(Emsi_Irq);
  S := '';
  REPEAT
    HangUp := NOT Com_Carrier;
    IF (ABS(T1 - Timer) > 2) THEN
      BEGIN
        T1 := Timer;
        Inc(Tries);
        IF (Tries >= 2) THEN
          Done := TRUE
        ELSE
          BEGIN
            Com_Flush_Recv;
            SerialOut(Emsi_Irq);
          END;
      END;
    IF (ABS(T2 - Timer) >= 8) THEN
      Done := TRUE;
    C := Cinkey;
    IF (C > #0) THEN
      BEGIN
        IF (Length(S) >= 160) THEN
          Delete(S, 1, 120);
        S := S + C;
        IF (Pos('**EMSI_ICI', S) > 0) THEN
          BEGIN
            Delete(S,1,Pos('EMSI_ICI',S) - 1);
            Move(S[1],Buffer[1],Length(S));
            BuffPtr := Length(S);
            T1 := Timer;
            REPEAT
              C := CInKey;
              IF NOT (C IN [#0, #13]) THEN
                BEGIN
                  Inc(BuffPtr);
                  Buffer[BuffPtr] := C;
                END;
            UNTIL (HangUp) OR (ABS(Timer - T1) > 4) OR (C = ^M) OR (BuffPtr = 2048);
            S [0] := #8;
            Move(Buffer[BuffPtr - 7],S[1],8);
            Dec(BuffPtr,8);
            IF (S = Hex(UpdateCRC32($Ffffffff,Buffer[1],BuffPtr),8)) THEN
              BEGIN
                LoadURec(User,1);
                Isi := '{Renegade,'+General.Version+'}{'+General.BBSName+'}{'+User.CityState+
                       '}{'+General.SysOpName+'}{'+Hex(GetPackDateTime,8)+
                       '}{Live free or die!}{}{Everything!}';
                Isi := 'EMSI_ISI'+ Hex(Length(Isi),4) + Isi;
                Isi := Isi + Hex(UpdateCRC32($Ffffffff,Isi[1],Length(Isi)),8);
                Isi := '**' + Isi + ^M;
                Com_Flush_Recv;
                SerialOut(Isi);
                Tries := 0;
                T1 := Timer;
                S := '';
                REPEAT
                  IF (ABS(Timer - T1) >= 3) THEN
                    BEGIN
                      T1 := Timer;
                      Inc(Tries);
                      Com_Flush_Recv;
                      SerialOut(Isi);
                    END;
                  C := Cinkey;
                  IF (C > #0) THEN
                    BEGIN
                      IF (Length(S) >= 160) THEN
                        Delete(S,1,120);
                      S := S + C;
                      IF (Pos('**EMSI_ACK', S) > 0) THEN
                        BEGIN
                          Com_Flush_Recv;
                          Com_Purge_Send;
                          Done := TRUE;
                          Success := TRUE;
                        END
                      ELSE IF (Pos('**EMSI_NAKEEC3',S) > 0) THEN
                        BEGIN
                          Com_Flush_Recv;
                          SerialOut(Isi);
                          Inc(Tries);
                        END;
                    END;
                UNTIL (Tries >= 3) OR (Done);
              END
            ELSE
              BEGIN
                SerialOut('**EMSI_NAKEEC3');
                T1 := Timer;
              END;
          END;
      END;
  UNTIL (Done) OR (HangUp);
  IF (Success) THEN
    BEGIN
      Writeln(lRGLngStr(132,TRUE)); {"Success"} (* Should this be print ??? *)
      SL1('IEMSI negotiation Suceeded.');
    END
  ELSE
    BEGIN
      WriteLn(lRGLngStr(133,TRUE)); {"Failure"} (* Should this be print ??? *)
      SL1('IEMSI negotiation failed.');
    END;
  NextItemPointer := 1;
  WITH IEMSIRec DO
    BEGIN
      UserName := NextItem;
      Handle := NextItem;
      CityState := NextItem;
      Ph := NextItem;
      S := NextItem;
      Pw := AllCaps(NextItem);
      I := StrToInt('$'+NextItem);
      IF (I > 0) THEN
        BDate := Pd2Date(I);
    END;
  Com_Flush_Recv;
END;

PROCEDURE Check_ANSI;
VAR
  L: LongInt;
  C: Char;
  Ox,X,Y: Byte;
  S: AStr;

  PROCEDURE ANSIResponse(VAR x,y: Byte);
  VAR
    Xs,
    Ys: STRING[4];
  BEGIN
    L := (Timer + 2);
    C := #0;
    Xs := '';
    Ys := '';
    X := 0;
    Y := 0;
    WHILE (L > Timer) AND (C <> ^[) AND (NOT HangUp) DO
      IF (NOT Empty) THEN
        C := Com_Recv; { must be low level to avoid ansi-eater }
      IF (C = ^[) THEN
        BEGIN
          L := (Timer + 1);
          WHILE (L > Timer) AND (C <> ';') AND (NOT HangUp) DO
            IF (NOT Empty) THEN
              BEGIN
                C := Com_Recv;
                IF (C IN ['0'..'9']) AND (Length(Ys) < 4) THEN
                  Ys := Ys + C;
              END;
          L := (Timer + 1);
          WHILE (L > Timer) AND (C <> 'R') AND (NOT HangUp) DO
            IF (NOT Empty) THEN
              BEGIN
                C := Com_Recv;
                IF (C IN ['0'..'9']) AND (Length(Xs) < 4) THEN
                  Xs := Xs + C;
              END;
          X := StrToInt(Xs);
          Y := StrToInt(Ys);
        END;
  END;

BEGIN
  TextAttr := 10;
  Write(lRGLngStr(134,TRUE)); {"Attempting to detect emulation ..."} (* Should this be Prompt ??? *)
  Exclude(ThisUser.ACFlags,Avatar);
  Exclude(ThisUser.ACFlags,Ansi);
  Exclude(ThisUser.ACFlags,Vt100);
  Exclude(ThisUser.SFlags,Rip);
  IF (ComPortSpeed = 0) THEN
    BEGIN
      Include(ThisUser.ACFlags,Ansi);
      Exit;
    END;
  Com_Flush_Recv;
  SerialOut(^M^M^['[!'#8#8#8);
  L := (Timer + 2);
  C := #0;
  S := '';
  WHILE (L > Timer) AND (C <> 'R') AND (NOT HangUp) DO IF (NOT Empty) THEN
    C := Com_Recv;
  IF (C = 'R') THEN
    BEGIN
      L := (Ticks + 3);
      WHILE (NOT Empty) AND (Ticks < L) DO;
        C := Com_Recv;
      IF (C = 'I') THEN
        BEGIN
          L := (Ticks + 3);
          WHILE (NOT Empty) AND (Ticks < L) DO;
            C := Com_Recv;
          IF (C = 'P') THEN
            BEGIN
              Include(ThisUser.SFlags,Rip);
              S := lRGLngStr(135,TRUE); {'RIP'}
            END;
        END;
      Com_Flush_Recv;
    END;
  SerialOut(^M^M^['[6n'#8#8#8#8);
  ANSIResponse(x,y);
  IF (x + y > 0) THEN
    BEGIN
      Include(ThisUser.ACFlags,Ansi);
      ANSIDetected := TRUE;
      IF (S <> '') THEN
        S := S + lRGLngStr(136,TRUE) {'/Ansi'}
      ELSE
        S := lRGLngStr(137,TRUE); {'Ansi'}
      SerialOut(^V^F);
      SerialOut(^['[6n'#8#8);
      Ox := x;
      ANSIResponse(x,y);
      IF (x = Ox + 1) THEN
        BEGIN
          Include(ThisUser.ACFlags,Avatar);
          IF (S <> '') THEN
            S := S + lRGLngStr(138,TRUE)  {'/Avatar'}
          ELSE
            S := lRGLngStr(139,TRUE); {'Avatar'}
        END
      ELSE
        SerialOut(#8#8);
    END;
  IF (S <> '') THEN
    Print('^9'+S+lRGLngStr(140,TRUE)) {' detected.'}
  ELSE
    BEGIN
      TextAttr := 7;
      WriteLn; { Should this be Print ??? }
    END;
END;

PROCEDURE GetPWS(VAR Ok: Boolean; VAR Tries: Integer);  (* Tries should be Byte *)
VAR
  MHeader: MHeaderRec;
  S: AStr;
  PhonePW: STR4;
  Birthday: STR10;
  UserPW,
  SysOpPW: STR20;
  ForgotPW: STR40;
BEGIN
  Ok := TRUE;
  IF (NOT (FastLogon AND (NOT General.LocalSec))) THEN
    BEGIN
      IF (IEMSIRec.Pw = '') THEN
        BEGIN
          lRGLngStr(183,FALSE); {"Password:"}
          InputMain(UserPW,SizeOf(UserPW)-1,[NoInputField,IsPassword]); {GetPassword(UserPw,20);}
        END
      ELSE
        BEGIN
          UserPW := IEMSIRec.Pw;
          IEMSIRec.Pw := '';
        END;
      IF (General.PhonePW) AND (ThisUser.Ph <> '') AND (General.NewUserQToggles[7] = TRUE) THEN
        IF (IEMSIRec.Ph = '') THEN
          BEGIN
            lRGLngStr(184,FALSE); {"(xxx)xxx-"}
            InputMain(PhonePW,SizeOf(PhonePW)-1,[NoInputField,IsPassword]); {GetPassword(PhonePW,4);}
          END
        ELSE
          BEGIN
            PhonePW := Copy(IEMSIRec.Ph,Length(IEMSIRec.Ph) - 3,4);
            IEMSIRec.Ph := '';
          END
        ELSE
          PhonePW := Copy(ThisUser.Ph,Length(ThisUser.Ph) - 3,4);
    END;
  IF (NOT (FastLogon AND (NOT General.LocalSec))) AND ((ThisUser.PW <> CRC32(UserPW)) OR
     (Copy(ThisUser.Ph,Length(ThisUser.Ph) - 3,4) <> PhonePW)) THEN
    BEGIN
      Ok := FALSE;
      lRGLngStr(119,FALSE); (*Prompt(FString.ILogon);*)
      IF (NOT HangUp) AND (UserNum <> 0) THEN
        BEGIN
          S := '^8[*] ^0Invalid Logon! -- USER: ^1'+AllCaps(ThisUser.Name)+'^0 (#'+IntToStr(UserNum)+') PW: ^1'+
               AllCaps(UserPW)+'^0';
          IF (General.PhonePW) THEN
            S := S + ' PH#: ^1'+PhonePW+'^0';
          SendShortMessage(1,S);
          SL1(S);
        END;
      Inc(ThisUser.Illegal);
      IF (UserNum <> - 1) THEN
        SaveURec(ThisUser,UserNum);
      Inc(Tries);
      IF (Tries >= General.MaxLogonTries) THEN
        BEGIN
          IF (General.NewUserQToggles[14] = FALSE) OR (General.ForgotPWQuestion = '') OR (ThisUser.ForgotPWAnswer = '') OR
             (CoSysOp) THEN
            HangUp := TRUE
          ELSE
            BEGIN
              lRGLngStr(186,FALSE); { Forgot Password Question Prompt }
              InputMain(ForgotPW,SizeOf(ForgotPW)-1,[CapAll]);
              IF (ForgotPW <> ThisUser.ForgotPWAnswer) THEN
                BEGIN
                  S := '* Invalid forgot password response: '+ForgotPW;
                  SL1(S);
                  SendShortMessage(1,S);
                  HangUp := TRUE
                END
              ELSE
                BEGIN
                  S := '* Entered correct forgot password response.';
                  SL1(S);
                  SendShortMessage(1,S);
                  CStuff(13,1,ThisUser); { Password }
                  Ok := TRUE;
                  Tries := 0;
                END;
            END;
        END;
    END;
  IF (Ok) THEN
    lStatus_Screen(General.Curwindow,'',FALSE,S);
  IF ((AACS(General.SPW)) AND (General.SysOpPW <> '') AND (Ok) AND (InCom) AND (NOT HangUp)) THEN
    BEGIN
      lRGLngStr(185,FALSE); (*Prompt(FString.SysOpPrompt);*)
      InputMain(SysOpPW,SizeOf(SysOpPW)-1,[IsPassword,NoInputField]); {GetPassword(SysOpPW,20);}
      IF (SysOpPW <> General.SysOpPW) THEN
        BEGIN
          lRGLngStr(119,FALSE); (*Prompt(FString.ILogon);*)
          SL1('* Illegal System password: '+SysOpPw);
          Inc(Tries);
          IF (Tries >= General.MaxLogonTries) THEN
            HangUp := TRUE;
          Ok := FALSE;
        END;
    END;
  IF (Ok) AND NOT (AACS(Liner.LogonACS)) THEN
    BEGIN
      PrintF('NONODE');
      IF (NoFile) THEN
        lRGLngStr(120,FALSE); (*Print('You don''t have the required ACS to logon to this node!');*)
      SysOpLog(ThisUser.Name+': Attempt to logon node '+IntToStr(ThisNode)+' without access.');
      HangUp := TRUE;
    END;
  IF ((Ok) AND (General.ShuttleLog) AND (LockedOut IN ThisUser.SFlags)) THEN
    BEGIN
      PrintF(ThisUser.LockedFile);
      IF (NoFile) THEN
        lRGLngStr(121,FALSE); (*Print('You have been locked out of the BBS by the SysOp.');*)
      SysOpLog(ThisUser.Name+': Attempt to access system when locked out^8 <--');
      HangUp := TRUE;
    END;
  IF (UserNum > 0) AND (Onnode(UserNum) > 0) AND NOT (CoSysOp) THEN
    BEGIN
      PrintF('MULTILOG');
      IF (NoFile) THEN
        lRGLngStr(122,FALSE); (*Print('You are already logged in on another node!');*)
      HangUp := TRUE;
    END;
  IF (NOT FastLogon) AND (Ok) AND (NOT HangUp) AND (General.Birthdatecheck > 0) AND
     (ThisUser.LoggedOn MOD General.Birthdatecheck = 0) AND (ThisUser.Birthdate <> -1869054590) AND
     (General.NewUserQToggles[08] = TRUE) THEN
    BEGIN
      lRGLngStr(187,FALSE); (*Prt('Please verify your date of birth (mm/dd/yyyy): ');*)
      Inputformatted('',Birthday,'##/##/####',FALSE);
      IF (Date2Pd(Birthday) <> ThisUser.Birthdate) THEN
        BEGIN
          Dec(ThisUser.LoggedOn);
          PrintF('WRNGBDAY');
          IF (NoFile) THEN
            lRGLngStr(123,FALSE); (*Print('You entered an incorrect birthdate.');*)
          SL1('*'+ThisUser.Name+' Failed birthday verification. Tried = '+Birthday+' Actual = '+Pd2Date(ThisUser.Birthdate));
          SendShortMessage(1,ThisUser.Name+' failed birthday verification on '+DateStr);
          InResponseTo := '\'#1'Failed birthdate check';
          MHeader.Status := [];
          SeMail(1,MHeader);
          HangUp := TRUE;
        END;
    END;
  UserOn := Ok;
END;

PROCEDURE TryIEMSILogon;
VAR
  I, Zz: Integer;
  Ok: Boolean;
BEGIN
  IF (IEMSIRec.UserName <> '') THEN
    BEGIN
      I := SearchUser(IEMSIRec.UserName,TRUE);
      IF (I = 0) AND (IEMSIRec.Handle <> '') THEN
        I := SearchUser(IEMSIRec.Handle,TRUE);
      IF (I > 0) THEN
        BEGIN
          Zz := UserNum;
          UserNum := 0;
          OldUser := ThisUser;
          LoadURec(ThisUser,I);
          UserNum := Zz;
          GetPWS(Ok,Zz);
          GotName := Ok;
          IF (NOT GotName) THEN
            BEGIN
              ThisUser := OldUser;
              Update_Screen;
            END
          ELSE
            BEGIN
              UserNum := I;
              IF (PD2Date(ThisUser.LastOn) <> DateStr) THEN
                WITH ThisUser DO
                  BEGIN
                    OnToday := 0;
                    TLToday := General.TimeAllow[SL];
                    TimeBankAdd := 0;
                    DLToday := 0;
                    DLKToday := 0;
                    TimeBankWith := 0;
                    {leew: add ultoday/ulktoday}
                  END;
              UserOn := TRUE;
              Update_Screen;
              SysOpLog('Logged in IEMSI as '+Caps(ThisUser.Name));
            END;
        END
      ELSE
        lRGLngStr(118,FALSE); (*Print(FString.NameNotFound);*)
    END;
END;

PROCEDURE FindUser(VAR UserNum: Integer);
VAR
  User: UserRecordType;
  TempUserName: Str36;
  TempUserNum: Integer;
BEGIN
  UserNum := 0;
  TempUserName := '';
  InputMain(TempUserName,SizeOf(TempUserName)-1,[NoInputField,CapAll]);
  IF (TempUserName = 'NEW') THEN
  BEGIN
    UserNum := -1;
    Exit;
  END;
  IF (TempUserName = '?') THEN
    Exit;
  WHILE (Pos('  ',TempUserName) <> 0) DO
    Delete(TempUserName,Pos('  ',TempUserName),1);
  WHILE (TempUserName[1] = ' ') AND (Length(TempUserName) > 0) DO
    Delete(TempUserName,1,1);
  IF (TempUserName = '') OR (HangUp) THEN
    Exit;
  UserNum := StrToInt(TempUserName);
  IF (UserNum <> 0) THEN
  BEGIN
    IF (UserNum < 0) OR (UserNum > (MaxUsers - 1)) THEN
      UserNum := 0
    ELSE
    BEGIN
      LoadURec(User,UserNum);
      IF (Deleted IN User.SFlags) THEN
        UserNum := 0;
    END;
  END
  ELSE IF (TempUserName <> '') THEN
  BEGIN
    TempUserNum := SearchUser(TempUserName,TRUE);
    IF (TempUserNum <> 0) THEN
    BEGIN
      LoadURec(User,TempUserNum);
      IF (NOT (Deleted IN User.SFlags)) THEN
        UserNum := TempUserNum
      ELSE
        UserNum := 0;
    END;
  END;
END;

PROCEDURE DoShuttle;
VAR
  Cmd,NewMenuCmd: AStr;
  SaveMenu,
  CmdToExec: Byte;
  Tries,
  RecNum,
  RecNum1,
  I: Integer;
  Done,Loggedon,Ok,CmdNotHid,CmdExists: Boolean;
BEGIN
  PrintF('PRESHUTL');
  GotName := FALSE;
  Loggedon := FALSE;
  TryIEMSILogon;
  SaveMenu := CurMenu;
  CurMenu := General.ShuttleLogonMenu;
  LoadMenu;
  AutoExecCmd('FIRSTCMD');
  Tries := 0;
  Curhelplevel := 2;
  REPEAT
    TSHuttleLogon := 0;
    MainMenuHandle(Cmd);
    NewMenuCmd:= '';
    CmdToExec := 0;
    Done := FALSE;
    REPEAT
      FCmd(Cmd,CmdToExec,CmdExists,CmdNotHid);
      IF (CmdToExec <> 0) THEN
        IF (MemCmd^[CmdToExec].Cmdkeys <> 'OP') AND (MemCmd^[CmdToExec].Cmdkeys <> 'O2') AND
           (MemCmd^[CmdToExec].Cmdkeys[1] <> 'H') AND (MemCmd^[CmdToExec].Cmdkeys[1] <> '-') AND
           (NOT GotName) THEN
          BEGIN
            lRGLngStr(189,FALSE); (*Prompt(FString.Shuttleprompt);*)
            FindUser(UserNum);
            IF (UserNum >= 1) THEN
              BEGIN
                I := UserNum;
                UserNum := 0;
                OldUser := ThisUser;
                LoadURec(ThisUser,I);
                UserNum := I;
                GetPWS(Ok,Tries);
                GotName := Ok;
                IF (NOT GotName) THEN
                  BEGIN
                    ThisUser := OldUser;
                    Update_Screen;
                  END
                ELSE
                  BEGIN
                    IF (PD2Date(ThisUser.LastOn) <> DateStr) THEN
                      WITH ThisUser DO
                        BEGIN
                          OnToday := 0;
                          TLToday := General.TimeAllow[SL];
                          TimeBankAdd := 0;
                          DLToday := 0;
                          DLKToday := 0;
                          TimeBankWith := 0;
                          {leew: add ultoday/ulktoday}
                        END;
                    UserOn := TRUE;
                    Update_Screen;
                    SysOpLog('Logged on to Shuttle Menu as '+Caps(ThisUser.Name));
                    DoMenuCommand(Done,
                                  MemCmd^[CmdToExec].Cmdkeys,
                                  MemCmd^[CmdToExec].Options,
                                  NewMenuCmd,
                                  MemCmd^[CmdToExec].NodeActivityDesc);
                  END;
              END
            ELSE
              BEGIN
                lRGLngStr(119,FALSE); (*Print(FString.ILogon);*)
                Inc(Tries);
              END;
          END
        ELSE
          DoMenuCommand(Done,
                        MemCmd^[CmdToExec].Cmdkeys,
                        MemCmd^[CmdToExec].Options,
                        NewMenuCmd,
                        MemCmd^[CmdToExec].NodeActivityDesc);
    UNTIL (CmdToExec = 0) OR (Done);
    CASE TSHuttleLogon OF
      1 : BEGIN
            Reset(ValidationFile);
            RecNum1 := -1;
            RecNum := 1;
            WHILE (RecNum <= NumValKeys) AND (RecNum1 = -1) DO
              BEGIN
                Seek(ValidationFile,(RecNum - 1));
                Read(ValidationFile,Validation);
                IF (Validation.Key = '!') THEN
                  RecNum1 := RecNum;
                Inc(RecNum);
              END;
            Close(ValidationFile);
            IF (RecNum1 <> -1) AND (ThisUser.SL > Validation.NewSL) THEN
              Loggedon := TRUE
            ELSE
              BEGIN
                PrintF('NOSHUTT');
                IF (NoFile) THEN
                  lRGLngStr(141,FALSE); (*Print('You have not been validated yet.');*)
                SL1('* Illegal Shuttle Logon attempt');
                Inc(Tries);
              END;
          END;
      2 : BEGIN
            IF (NOT General.ClosedSystem) AND PYNQ(lRGLngStr(182,TRUE),0,FALSE) THEN {"Logon as new?"}
              BEGIN
                NewUserInit;
                NewUser;
                IF (UserNum > 0) AND (NOT HangUp) THEN
                  BEGIN
                    GotName := TRUE;
                    UserOn := TRUE;
                    DailyMaint;
                  END;
                CurMenu := General.ShuttleLogonMenu;
                LoadMenu;
              END;
          END;
    END;
    IF (Tries >= General.MaxLogonTries) THEN
      HangUp := TRUE;
  UNTIL (LoggedOn) OR (HangUp);
  CurMenu := SaveMenu;
  NewMenuToLoad := TRUE;
END;

FUNCTION GetUser: Boolean;
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Pw,
  S,
  ACSReq: AStr;
  OverridePW: Str20;
  Lng: Integer;
  Tries,
  I,
  TTimes,
  Zz,
  EventNum: Integer;    (* Tries/TTimes should be Byte, may NOT need TTimes *)
  Done,
  Nu,
  Ok,
  TooMuch,
  ACSUser: Boolean;
BEGIN
  WasNewUser := FALSE;
  UserNum := -1;
  LoadURec(ThisUser,0);
  TimeOn := GetPackDateTime;
  ChatChannel := 0;
  Update_Node(lRGLngStr(145,TRUE){ Logging on },TRUE);  (* New *)

  LoadNode(ThisNode);     (* New *)
  NodeR.GroupChat := FALSE;
  SaveNode(ThisNode);

  CreditsLastUpdated := GetPackDateTime;

  PublicReadThisCall := 0;

  ExtraTime := 0;
  FreeTime := 0;
  ChopTime := 0;
  CreditTime := 0;

  {SL1('');}

  S := ' ^9* ^5Logon Node ^4'+IntToStr(ThisNode)+'^5 [ ^4'+Dat+'^5 ] (^4';
  IF (ComPortSpeed > 0) THEN
    BEGIN
      S := S + IntToStr(ActualSpeed)+' ^5Baud';
      IF (Reliable) THEN
        S := S + '/^4Reliable^5)'
      ELSE
        S := S + '^5)';
      IF (CallerIDNumber <> '') THEN {LeeW: Fixed?}
        BEGIN
          IF (NOT Telnet) THEN
            S := S + ' PH#: ^4'+CallerIDNumber
          ELSE
            S := S + ' IP#: ^4'+CallerIDNumber;
        END;
    END
  ELSE
    S := S + 'Keyboard^5)';
  SL1(S{+'^0'});

  Nu := FALSE;
  Pw := '';

  IF (ActualSpeed < General.MinimumBaud) AND (ComPortSpeed > 0) THEN
  BEGIN
    IF ((General.MinBaudHiTime - General.MinBaudLowTime) > 1430) THEN
    BEGIN
      IF (General.MinBaudOverride <> '') THEN
      BEGIN
        lRGLngStr(180,FALSE); (*Prt('Baud rate override password: ');*)
        InputMain(OverridePW,SizeOf(OverridePW)-1,[IsPassword]); {GetPassword(OverridePW,20);}
      END;
      IF (General.MinBaudOverride = '') OR (OverRidePW <> General.MinBaudOverride) THEN
      BEGIN
        PrintF('NOBAUD.ASC');
        IF (NoFile) THEN
          lRGLngStr(113,FALSE);
          (*
          Print('You must be using at least '+IntToStr(General.MinimumBaud)+' baud to call this BBS.');
          *)
        HangUp := TRUE;
        Exit;
      END;
    END
    ELSE IF (NOT InTime(Timer,General.MinBaudLowTime,General.MinBaudHiTime)) THEN
    BEGIN
      IF (General.MinBaudOverride <> '') THEN
      BEGIN
        lRGLngStr(180,FALSE); (*Prt('Baud rate override password: ');*)
        InputMain(OverridePW,SizeOf(OverridePW)-1,[IsPassword]); {GetPassword(OverridePW,20);}
      END;
      IF (General.MinBaudOverride = '') OR (OverridePW <> General.MinBaudOverride) THEN
      BEGIN
        PrintF('NOBAUDH.ASC');
        IF (NoFile) THEN
          (*
          Print('Hours for those using less than '+IntToStr(General.MinimumBaud)+' baud are from '+
               Ctim(General.MinBaudLowTime)+' to '+Ctim(General.MinBaudHiTime));
          *)
          lRGLngStr(114,FALSE);
        HangUp := TRUE;
        Exit;
      END;
    END
    ELSE
    BEGIN
      IF (NOT HangUp) THEN
        IF ((General.MinBaudLowTime <> 0) OR (General.MinBaudHiTime <> 0)) THEN
        BEGIN
          PrintF('YESBAUDH.ASC');
          IF (NoFile) THEN
            (*
            Print('NOTE: Callers at less than '+IntToStr(General.MinimumBaud)+' baud are');
            Print('restricted to the following hours ONLY:');
            Print('  '+Ctim(General.MinBaudLowTime)+' to '+Ctim(General.MinBaudHiTime));
            *)
            lRGLngStr(115,FALSE);
        END;
    END;
  END;

  ACSUser := FALSE;
  FOR I := 1 TO NumEvents DO
    WITH MemEventArray[I]^ DO
      IF ((EventIsActive IN EFlags) AND (EventIsLogon IN EFlags) AND (CheckEventTime(I,0))) THEN
      BEGIN
        ACSUser := TRUE;
        ACSReq := MemEventArray[I]^.EventACS;
        EventNum := I;
      END;

  Check_Ansi;
  IEMSI;
  GotName := FALSE;
  IF ((General.ShuttleLog) AND (NOT FastLogon) AND (NOT HangUp)) THEN
    DoShuttle;
  SetC(7);
  CLS;
  Print(Centre(VerLine(1)));
  Print(Centre(VerLine(2)));
  {Print(Centre(VerLine(3)));}
  PrintF('PRELOGON');
  IF (ACSUser) THEN
  BEGIN
    PrintF('ACSEA'+IntToStr(EventNum));
    IF (NoFile) THEN
      (*
      Print('Restricted: Only certain users allowed online at this time.');
      *)
      lRGLngStr(116,FALSE);
  END;
  IF (NOT GotName) THEN
    TryIEMSILogon;
  TTimes := 0;
  Tries := 0;
  REPEAT
    REPEAT
      IF (UserNum <> - 1) AND (TTimes >= General.MaxLogonTries) THEN
        HangUp := TRUE;
      OldUser := ThisUser;
      IF (NOT GotName) THEN
      BEGIN
        (*
        IF (FString.Note[1] <> '') THEN
          Print(FString.Note[1]);
        IF (FString.Note[2] <> '') THEN
          Print(FString.Note[2]);
        IF (FString.Lprompt <> '') THEN
          Prompt(FString.Lprompt);
        *)
        lRGLngStr(181,FALSE);
        FindUser(UserNum);
        Inc(TTimes);
        IF (ACSUser) AND (UserNum = -1) THEN
        BEGIN
          PrintF('ACSEB'+IntToStr(EventNum));
          IF (NoFile) THEN
            (*
            Print('This time window allows certain other users to get online.');
            Print('Please call back later, after it has ended.');
            *)
            lRGLngStr(117,FALSE);
          HangUp := TRUE;
        END;
        IF (NOT HangUp) AND (UserNum = 0) THEN
        BEGIN
          PrintF('LOGERR');
          IF (NoFile) THEN
            (*
            Print('Name not found in user list.');
            *)
            lRGLngStr(118,FALSE);
          IF NOT (General.ShuttleLog) AND (NOT General.ClosedSystem) THEN
            IF PYNQ(lRGLngStr(182,TRUE){FString.LogonAsNew},0,FALSE) THEN
              UserNum := -1;
        END;
      END;
    UNTIL (UserNum <> 0) OR (HangUp);
    IF (ACSUser) AND (UserNum = -1) THEN
    BEGIN
      PrintF('ACSEB'+IntToStr(EventNum));
      IF (NoFile) THEN
        (*
        Print('This time window allows certain other users to get online.');
        Print('Please call back later, after it has ended.');
        *)
        lRGLngStr(117,FALSE);
      HangUp := TRUE;
    END;
    Ok := TRUE;
    Done := FALSE;
    IF (NOT HangUp) THEN
    BEGIN
      IF (UserNum = -1) THEN
      BEGIN
        NewUserInit;
        Nu := TRUE;
        Done := TRUE;
        Ok := FALSE;
      END
      ELSE
      BEGIN
        I := UserNum;
        UserNum := 0;
        LoadURec(ThisUser,I);
        UserNum := I;
        TempPause := (Pause IN ThisUser.ACFlags);
        NewFileDate := ThisUser.LastOn;
        MsgArea := ThisUser.LastMsgArea;
        FileArea := ThisUser.LastFileArea;
        IF (AutoDetect IN ThisUser.SFlags) THEN
        BEGIN
          IF (Rip IN OldUser.SFlags) THEN
            Include(ThisUser.SFlags,Rip)
          ELSE
            Exclude(ThisUser.SFlags,Rip);
          IF (Ansi IN OldUser.ACFlags) THEN
            Include(ThisUser.ACFlags,Ansi)
          ELSE
            Exclude(ThisUser.ACFlags,Ansi);
          IF (Avatar IN OldUser.ACFlags) THEN
            Include(ThisUser.ACFlags,Avatar)
          ELSE
            Exclude(ThisUser.ACFlags,Avatar);
        END;
        IF (Pd2Date(ThisUser.LastOn) <> DateStr) THEN
          WITH ThisUser DO
          BEGIN
            OnToday := 0;
            TLToday := General.TimeAllow[SL];
            TimeBankAdd := 0;
            DLToday := 0;
            DLKToday := 0;
            {leew: add ultoday/ulktoday}
            TimeBankWith := 0;
          END
          ELSE IF (General.PerCall) THEN
            ThisUser.TLToday := General.TimeAllow[ThisUser.SL];

        IF (ThisUser.Expiration > 0) AND
           (ThisUser.Expiration <= GetPackDateTime) AND
           (ThisUser.ExpireTo IN ['!'..'~']) THEN
        BEGIN
          SysOpLog('Subscription expired to level: "'+ThisUser.ExpireTo+'".');
          AutoValidate(ThisUser,UserNum,ThisUser.ExpireTo);
        END;

        IF (CallerIDNumber <> '') THEN
          ThisUser.CallerID := CallerIDNumber;
        SaveURec(ThisUser,UserNum);
        IF (NOT GotName) THEN
          GetPWS(Ok,Tries);
        IF (Ok) THEN
          Done := TRUE;
        IF (NOT Done) THEN
        BEGIN
          ThisUser := OldUser;
          UserNum := 0;
          Update_Screen;
        END;
      END;
    END;
  UNTIL ((Done) OR (HangUp));
  Reset(SchemeFile);
  IF (ThisUser.ColorScheme > 0) AND (ThisUser.ColorScheme <= FileSize(SchemeFile) ) THEN
    Seek(SchemeFile,ThisUser.ColorScheme - 1)
  ELSE
    ThisUser.ColorScheme := 1;
  Read(SchemeFile,Scheme);
  Close(SchemeFile);
  IF (ACSUser) AND NOT (AACS(ACSReq)) THEN
  BEGIN
    PrintF('ACSEB'+IntToStr(EventNum));
    IF (NoFile) THEN
      (*
      Print('This time window allows certain other users to get online.');
      Print('Please call back later, after it has ended.');
      *)
      lRGLngStr(117,FALSE);
    HangUp := TRUE;
  END;
  IF NOT (AACS(Liner.LogonACS)) AND (NOT HangUp) THEN
  BEGIN
    PrintF('NONODE');
    IF (NoFile) THEN
      (*
      Print('You don''t have the required ACS to logon to this node!');
      *)
      lRGLngStr(120,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to logon node '+IntToStr(ThisNode)+' without access.');
    HangUp := TRUE;
  END;
  IF ((LockedOut IN ThisUser.SFlags) AND (NOT HangUp)) THEN
  BEGIN
    PrintF(ThisUser.LockedFile);
    IF (NoFile) THEN
      (*
      Print('You have been locked out of the BBS by the SysOp.');
      *)
      lRGLngStr(121,FALSE);
    SysOpLog(ThisUser.Name+': Attempt to access system when locked out^8 <--');
    HangUp := TRUE;
  END;
  IF ((NOT Nu) AND (NOT HangUp)) THEN
  BEGIN
    TooMuch := FALSE;
    IF (Accountbalance < General.Creditminute) AND (General.Creditminute > 0) AND
       NOT (FNoCredits IN ThisUser.ACFlags) THEN
    BEGIN
      PrintF('NOCREDTS');
      IF (NoFile) THEN
        (*
        Print('You have insufficient credits for online time.');
        *)
        lRGLngStr(124,FALSE);
      SysOpLog(ThisUser.Name+': insufficient credits for logon.');
      IF (General.CreditFreeTime < 1) THEN
        HangUp := TRUE
      ELSE
      BEGIN
        ThisUser.TLToday := General.CreditFreeTime DIV General.Creditminute;
        Inc(ThisUser.lCredit,General.CreditFreeTime);
      END;
    END
    ELSE IF (((Rlogon IN ThisUser.ACFlags) OR (General.CallAllow[ThisUser.SL] = 1)) AND
            (ThisUser.OnToday >= 1) AND (Pd2Date(ThisUser.LastOn) = DateStr)) THEN
    BEGIN
      PrintF('2MANYCAL');
      IF (NoFile) THEN
        (*
        Print('You can only log on once per day.');
        *)
        lRGLngStr(125,FALSE);
      TooMuch := TRUE;
    END
    ELSE IF ((ThisUser.OnToday >= General.CallAllow[ThisUser.SL])  AND
            (Pd2Date(ThisUser.LastOn) = DateStr)) THEN
    BEGIN
      PrintF('2MANYCAL');
      IF (NoFile) THEN
        (*
        Print('You can only log on '+IntToStr(General.CallAllow[ThisUser.SL])+' times per day.');
        *)
        lRGLngStr(126,FALSE);
      TooMuch := TRUE;
    END
    ELSE IF (ThisUser.TLToday <= 0) AND NOT (General.PerCall) THEN
    BEGIN
      PrintF('NOTLEFTA');
      IF (NoFile) THEN
        (*
        Prompt('You can only log on for '+IntToStr(General.TimeAllow[ThisUser.SL])+' minutes per day.');
        *)
        lRGLngStr(127,FALSE);
      TooMuch := TRUE;
      IF (ThisUser.TimeBank > 0) THEN
      BEGIN
        (*
        Print('^1However, you have '+IntToStr(ThisUser.TimeBank)+' minutes left in your Time Bank.');
        *)
        lRGLngStr(128,FALSE);
        IF PYNQ(lRGLngStr(188,TRUE){'Withdraw from Time Bank? '},0,TRUE) THEN
        BEGIN
          InputInteger('Withdraw how many minutes',Lng,[NumbersOnly],1,32767,Changed);
          BEGIN
            IF (Lng > ThisUser.TimeBank) THEN
              Lng := ThisUser.TimeBank;
            Dec(ThisUser.TimeBankAdd,Lng);
            IF (ThisUser.TimeBankAdd < 0) THEN
              ThisUser.TimeBankAdd := 0;
            Dec(ThisUser.TimeBank,Lng);
            Inc(ThisUser.TLToday,Lng);
            (*
            Print('^1In your account: ^1'+IntToStr(ThisUser.TimeBank)+'^1   Time left online: ^1'+Formattedtime(NSL));
            *)
            lRGLngStr(129,FALSE);
            SysOpLog('TimeBank: Withdrew '+ IntToStr(Lng)+' minutes at logon.');
          END;
        END;
        IF (NSL >= 0) THEN
          TooMuch := FALSE
        ELSE
          (*
          Print('Hanging up.');
          *)
          lRGLngStr(130,FALSE);
      END;
    END;
    IF (TooMuch) THEN
    BEGIN
      SL1(ThisUser.Name+' attempt to exceed time/call limits.');
      HangUp := TRUE;
    END;
    IF (Tries >= General.MaxLogonTries) THEN
      HangUp := TRUE;
    IF (NOT HangUp) THEN
      Inc(ThisUser.OnToday);
  END;
  IF (UserNum > 0) AND (NOT HangUp) THEN
  BEGIN
    GetUser := Nu;
    IF (NOT FastLogon) THEN
    BEGIN
      PrintF('WELCOME');
      IF (NOT NoFile) THEN
        PauseScr(FALSE);
      I := 0;
      REPEAT
        Inc(I);
        PrintF('WELCOME'+IntToStr(I));
        IF (NOT NoFile) THEN
          PauseScr(FALSE);
      UNTIL (I = 9) OR (NoFile) OR (HangUp);
    END;
    UserOn := TRUE;
    Update_Screen;
    (*
    Update_Node('Logged on',TRUE);
    *)
    InitTrapFile;
    UserOn := FALSE;
    CLS;
  END;
  IF (HangUp) THEN
    GetUser := FALSE;
END;

END.
