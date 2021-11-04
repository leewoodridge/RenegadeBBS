{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}

{ 
Lee Woodridge
 09/20/2021 - Combined line & splitscreen chat into CHAT.PAS
 10/03/2021 - Changed header for chatlog
            - splitchat: Fixed vertical positioning for user and sysop, now they stay inside their lines
              (had to toggle statusbar off and on to keep it from messing positioning up,
              need to figure out actual fix for this because it affects a lot more than just this)
            - splitchat: carriage return now scrolls down instead of clearing everything
            - splitchat: changed border style
 10/11/2021 - splitchat: Ctrl+G now does what it says - disconnects, instead of bell
            - splitchat: Ctrl+P now pages, same as linechat
            - moved ansig and clear_eol to COMMON
 10/16/2021 - Answering chat call will use splitchat if user has ANSI support, linechat otherwise
 10/16/2021 - SysOp can now display file when chatting with user. ONLY sysop can execute the cmd, not user.
			  before was only allowing /type cmd if chatting with sysop
			- Added "Buf := ^M" after line/split chat exit, is equiv to pressing enter after chat to refresh screen
			  maybe there's a better way to do this??? should keep eye on it incase unintended consequences
				- skips to next if reading messages, same behavior for file listing expected
}

UNIT Chat;

INTERFACE

USES
  Common,
  Common2, {togglewindow}
  Menus2,
  MyIO;

PROCEDURE RequestSysOpChat(CONST MenuOption: Str50);
PROCEDURE ChatFileLog(b: Boolean);
PROCEDURE SysOpLineChat;
PROCEDURE SysOpSplitChat;

IMPLEMENTATION

USES
  CRT,
  DOS,
  EMail,
  Events,
  TimeFunc;
  
TYPE
  ChatStrArray = ARRAY [1..10] OF AStr;
  {
VAR
}

PROCEDURE RequestSysOpChat(CONST MenuOption: Str50);
VAR
  User: UserRecordType;
  MHeader: MHeaderRec;
  Reason: AStr;
  Cmd: Char;
  Counter: Byte;
  UNum,
  Counter1: Integer;
  Chatted: Boolean;
BEGIN
  IF (ChatAttempts < General.MaxChat) OR (CoSysOp) THEN
  BEGIN
    NL;
    IF (Pos(';',MenuOption) <> 0) THEN
      Print(Copy(MenuOption,(Pos(';',MenuOption) + 1),Length(MenuOption)))
    ELSE
      lRGLngStr(37,FALSE); { FString.ChatReason; }
    Chatted := FALSE;
    Prt(': ');
    MPL(60);
    InputL(Reason,60);
    IF (Reason <> '') THEN
    BEGIN
      Inc(ChatAttempts);
      SysOpLog('^4Chat attempt:');
      SL1(Reason);
      IF (NOT SysOpAvailable) AND AACS(General.OverRideChat) THEN
        PrintF('CHATOVR');
      IF (SysOpAvailable) OR (AACS(General.OverRideChat) AND PYNQ(^M^J'SysOp is not available. Override? ',0,FALSE)) THEN
      BEGIN
        lStatus_Screen(100,'Press [SPACE] to chat or [ENTER] for silence.',FALSE,Reason);        
        lRGLngStr(14,FALSE); { Print(FString.ChatCall1); }
        Counter := 0;
        Abort := FALSE;
        NL;
        REPEAT
          Inc(Counter);
          WKey;
          IF (OutCom) THEN
            Com_Send(^G);
          lRGLngStr(15,FALSE); { Prompt(FString.ChatCall2); }
          IF (OutCom) THEN
            Com_Send(^G);
          IF (ShutUpChatCall) THEN
            Delay(600)
          ELSE
          BEGIN
            FOR Counter1 := 300 DOWNTO 2 DO
            BEGIN
              Delay(1);
              Sound(Counter1 * 10);
            END;
            FOR Counter1 := 2 TO 300 DO
            BEGIN
              Delay(1);
              Sound(Counter1 * 10);
            END;
          END;
          NoSound;
          IF (KeyPressed) THEN
          BEGIN
            Cmd := ReadKey;
            CASE Cmd OF
               #0 : BEGIN
                      Cmd := ReadKey;
                      SKey1(Cmd);
                    END;
              #32 : BEGIN
                      Chatted := TRUE;
                      ChatAttempts := 0;
					  IF (OkANSI) THEN
                        SysOpSplitChat
                      ELSE
                        SysOpLineChat;
                    END;
               ^M : ShutUpChatCall := TRUE;
            END;
          END;
        UNTIL (Counter = 9) OR (Chatted) OR (Abort) OR (HangUp);
        NL;
      END;
      lStatus_Screen(100,'Chat Request: '+Reason,FALSE,Reason);
      IF (Chatted) THEN
        ChatReason := ''
      ELSE
      BEGIN
        ChatReason := Reason;
        PrintF('NOSYSOP');
        UNum := StrToInt(MenuOption);
        IF (UNum > 0) THEN
        BEGIN
          InResponseTo := #1'Tried chatting';
          LoadURec(User,UNum);
          NL;
          IF PYNQ('Send mail to '+Caps(User.Name)+'? ',0,FALSE) THEN
          BEGIN
            MHeader.Status := [];
            SEmail(UNum,MHeader);
          END;
        END;
      END;
      TLeft;
    END;
  END
  ELSE
  BEGIN
    PrintF('GOAWAY');
    UNum := StrToInt(MenuOption);
    IF (UNum > 0) THEN
    BEGIN
      InResponseTo := 'Tried chatting (more than '+IntToStr(General.MaxChat)+' times!)';
      SysOpLog(InResponseTo);
      MHeader.Status := [];
      SEmail(UNum,MHeader);
    END;
  END;
END;

PROCEDURE ChatFileLog(b: Boolean);
VAR
  s: AStr;
BEGIN
  s := 'Chat';
  IF (ChatSeparate IN ThisUser.SFlags) THEN
    s := s + IntToStr(UserNum);
  s := General.LogsPath+s+'.LOG';
  IF (NOT b) THEN
  BEGIN
    IF (CFO) THEN
    BEGIN
      lStatus_Screen(100,'Chat recorded to '+s,FALSE,s);
      CFO := FALSE;
      IF (TextRec(ChatFile).Mode <> FMClosed) THEN
        Close(ChatFile);
    END;
  END
  ELSE
  BEGIN
    CFO := TRUE;
    IF (TextRec(ChatFile).Mode = FMOutPut) THEN
      Close(ChatFile);
    Assign(ChatFile,s);
    Append(ChatFile);
    IF (IOResult = 2) THEN
      ReWrite(ChatFile);
    IF (IOResult <> 0) THEN
      SysOpLog('Cannot open chat log file: '+s);
    lStatus_Screen(100,'Recording chat to '+s,FALSE,s);
    WriteLn(ChatFile,'-------------------------------------------------------------------------------');
    Writeln(ChatFile,'Recorded with user: '+Caps(ThisUser.Name)+' on '+Dat);
    WriteLn(ChatFile,'Chat reason: '+AOnOff(ChatReason = '','None',ChatReason));
    WriteLn(ChatFile,'-------------------------------------------------------------------------------');
    WriteLn(ChatFile);
  END;
END;

PROCEDURE InLi1(VAR S: STRING);
VAR
  C,
  C1: Char;
  Counter,
  Counter1,
  CPos: Byte;
BEGIN
  CPos := 1;
  S := '';
  IF (LastLineStr <> '') THEN
  BEGIN
    Prompt(LastLineStr);
    S := LastLineStr;
    LastLineStr := '';
    CPos := (Length(S) + 1);
  END;

  REPEAT
    C := Char(GetKey);
    CheckHangUp;
    CASE Ord(C) OF
      32..255 :
            IF (CPos < 79) THEN
            BEGIN
              S[CPos] := C;
              Inc(CPos);
              OutKey(C);
              IF (Trapping) THEN
                Write(TrapFile,C);
            END;
       16 : IF (OkANSI OR OkAvatar) THEN
            BEGIN
              C1 := Char(GetKey);
              UserColor(Ord(C1) - 48);
            END;
       27 : IF (CPos < 79) THEN
            BEGIN
              S[CPos] := C;
              Inc(CPos);
              OutKey(C);
              IF (Trapping) THEN
                Write(TrapFile,C);
            END;
        8 : IF (CPos > 1) THEN
            BEGIN
              Dec(CPos);
              BackSpace;
            END;
       24 : BEGIN
              FOR Counter := 1 TO (CPos - 1) DO
                BackSpace;
              CPos := 1;
            END;
        7 : IF (OutCom) THEN
              Com_Send(^G);
       23 : IF (CPos > 1) THEN
              REPEAT
                Dec(CPos);
                BackSpace;
              UNTIL (CPos = 1) OR (S[CPos] = ' ');
        9 : BEGIN
              Counter := (5 - (CPos MOD 5));
              IF ((CPos + Counter) < 79) THEN
                FOR Counter1 := 1 TO Counter DO
                BEGIN
                  S[CPos] := ' ';
                  Inc(CPos);
                  Prompt(' ');
                END;
           END;
    END;
  UNTIL ((C = ^M) OR (CPos = 79) OR (HangUp) OR (NOT InChat));
  IF (NOT InChat) THEN
  BEGIN
    C := #13;
    InChat := FALSE;
  END;
  S[0] := Chr(CPos - 1);
  IF (C <> ^M) THEN
  BEGIN
    Counter := (CPos - 1);
    WHILE (Counter > 0) AND (S[Counter] <> ' ') AND (S[Counter] <> ^H) DO
      Dec(Counter);
    IF (Counter > (CPos DIV 2)) AND (Counter <> (CPos - 1)) THEN
    BEGIN
      LastLineStr := Copy(S,(Counter + 1),(CPos - Counter));
      FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        Prompt(^H);
      FOR Counter1 := (CPos - 2) DOWNTO Counter DO
        Prompt(' ');
      S[0] := Chr(Counter - 1);
    END;
  END;
  NL;
END;

PROCEDURE SysOpLineChat;
VAR
  S: AStr;
  Counter: Integer;
  ChatTime: LongInt;
  SaveEcho,
  SavePrintingFile,
  SaveMCIAllowed: Boolean;
BEGIN
  UserColor(1);
  SaveMCIAllowed := MCIAllowed;
  MCIAllowed := TRUE;
  ChatTime := GetPackDateTime;
  DOSANSIOn := FALSE;
  IF (General.MultiNode) THEN
	BEGIN
      LoadNode(ThisNode);
      SaveNAvail := (NAvail IN Noder.Status);
      Exclude(Noder.Status,NAvail);
      SaveNode(ThisNode);
	END;
  SavePrintingFile := PrintingFile;
  InChat := TRUE;
  ChatCall := FALSE;
  SaveEcho := Echo;
  Echo := TRUE;
  IF (General.AutoChatOpen) THEN
    ChatFileLog(TRUE)
  ELSE IF (ChatAuto IN ThisUser.SFlags) THEN
    ChatFileLog(TRUE);
  NL;
  Exclude(ThisUser.ACFlags,Alert);
  PrintF('CHATINIT');
  IF (NoFile) THEN
    lRGLNGStr(2,FALSE); (* Prompt('^5'+FString.EnGage); *)
  UserColor({10}General.SysOpColor);
  WColor := TRUE;
  IF (ChatReason <> '') THEN
	BEGIN
      lStatus_Screen(100,ChatReason,FALSE,S);
      ChatReason := '';
	END;
  REPEAT
    InLi1(S);
    IF (S[1] = '/') THEN
      S := AllCaps(S);
    IF (Copy(S,1,6) = '/TYPE ') AND (WColor) THEN
	  BEGIN
		S := Copy(S,7,(Length(S) - 6));
		IF (S <> '') THEN
		  BEGIN
			PrintFile(S);
			IF (NoFile) THEN
			Print('*File not found*');
		END;
      END
    ELSE IF ((S = '/HELP') OR (S = '/?')) THEN
	  BEGIN
		IF (WColor) THEN
          Print('^5/TYPE D:\PATH\FILENAME.EXT^3: Type a file');
     (* Print('^5/BYE^3:   Hang up');
        Print('^5/CLS^3:   Clear the screen');
        Print('^5/PAGE^3:  Page the SysOp and User');
        Print('^5/Q^3:     Exit chat mode'^M^J); *)
		lRGLngStr(65,FALSE);
      END
    ELSE IF (S = '/CLS') THEN
      CLS
    ELSE IF (S = '/PAGE') THEN
	  BEGIN
		FOR Counter := 650 TO 700 DO
		  BEGIN
			Sound(Counter);
			Delay(4);
			NoSound;
		  END;
		REPEAT
          Dec(Counter);
          Sound(Counter);
          Delay(2);
          NoSound;
		UNTIL (Counter = 200);
        Prompt(^G^G);
      END
    ELSE IF (S = '/BYE') THEN
	  BEGIN
		Print('Hanging up ...');
		HangUp := TRUE;
      END
    ELSE IF (S = '/Q') THEN
	  BEGIN
		InChat := FALSE;
		Print('Chat Aborted ...');
      END;
    IF (CFO) THEN
      WriteLn(ChatFile,S);
  UNTIL ((NOT InChat) OR (HangUp));

  PrintF('CHATEND');
  IF (NoFile) THEN
    lRGLngStr(3,FALSE); (* Print('^5'+FString.lEndChat); *)
  IF (General.MultiNode) THEN
	BEGIN
      LoadNode(ThisNode);
      IF (SaveNAvail) THEN
		Include(Noder.Status,NAvail);
      SaveNode(ThisNode);
	END;
  ChatTime := (GetPackDateTime - ChatTime);
  IF (ChopTime = 0) THEN
    Inc(FreeTime,ChatTime);
  TLeft;
  S := 'Chatted for '+FormattedTime(ChatTime);
  IF (CFO) THEN
	BEGIN
      S := S+'  -{ Recorded in Chat';
      IF (ChatSeparate IN ThisUser.SFlags) THEN
		S := S + IntToStr(UserNum);
      S := S+'.LOG }-';
	END;
  SysOpLog(S);
  InChat := FALSE;
  Echo := SaveEcho;
  IF ((HangUp) AND (CFO)) THEN
	BEGIN
      WriteLn(ChatFile);
      WriteLn(ChatFile,'=> User disconnected');
      WriteLn(ChatFile);
    END;
  PrintingFile := SavePrintingFile;
  IF (CFO) THEN
    ChatFileLog(FALSE);
  IF (InVisEdit) THEN
    Buf := ^L
  ELSE
	  Buf := ^M; { LeeW: Added - Carriage feed, to refresh menu after }
  MCIAllowed := SaveMCIAllowed;
END;

{ --- LeeW: SPLITCHA.PAS added below --- }
{
PROCEDURE ANSIG(X,Y: Byte);
BEGIN
  IF (ComPortSpeed > 0) THEN
    IF (OkAvatar) THEN
      SerialOut(^V^H+Chr(Y)+Chr(X))
    ELSE
      SerialOut(#27+'['+IntToStr(Y)+';'+IntToStr(X)+'H');
  IF (WantOut) THEN
    GoToXY(X,Y);
END;
}

PROCEDURE SysOpChatWindow;
VAR
  Counter: Byte;
BEGIN
  {
  PrintF('SPLTCHAT');
  IF NoFile THEN 
	BEGIN
	  SysOpLog('SPLTCHAT.ANS file missing from MISC directory');
	  EXIT;
	END;  }
  CLS;
  ANSIG(1,1);
  UserColor(1);
  FOR Counter := 1 TO 79 DO
        OutKey(#196);
  ANSIG((80-Length(General.SysOpName)-5),1);
  Prompt('^1[ ^2'+AllCaps(General.SysOpName)+'^1 ]');
  UserColor(1);
  ANSIG(1,12);
  FOR Counter := 1 TO 79 DO
        OutKey(#196);
  ANSIG(31,12);
  Prompt('^1[ ^2CTRL+Z for Help^2 ]');
  ANSIG(1,23);
  UserColor(1);
  FOR Counter := 1 TO 79 DO
        OutKey(#196);
  ANSIG(2,23);
  Prompt('^1[^2 '+AllCaps(ThisUser.Name)+'^1 ]');
END;

PROCEDURE SysOpSplitChat;
VAR
  UserChat: ChatStrArray;
  SysOpChat: ChatStrArray;
  UserXPos,
  UserYPos,
  SysOpXPos,
  SysOpYPos: Byte;
  Cmd : Char;
  ChatHelp : Boolean;
  ClrHlp : ShortInt;
{ ^ moved these from global}

  S,
  SysOpStr,
  UserStr,
  SysOpLastLineStr,
  UserLastLineStr: AStr;

  SysOpLine,
  UserLine,
  SysOpCPos,
  UserCPos,
  SaveWhereX,
  SaveWhereY,
  SaveTextAttr: Byte;

  C: Char;
  Counter: Integer;
  ChatTime: LongInt;
  SaveEcho,
  SavePrintingFile,
  SaveMCIAllowed: Boolean;

  PROCEDURE DoChar(C: Char; VAR CPos,XPos,YPos,Line: Byte; VAR ChatArray: ChatStrArray; VAR WrapLine: AStr);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
  (*
    IF C = #27 THEN { ESC - Exit }
      BEGIN
        InChat := False;
        Update_Screen;
      END;
    IF C = #63 THEN { F5 - Exit }
      BEGIN
        InChat := False;
        Update_Screen;
      END; 
      *)
    IF (CPos < 79) THEN
      BEGIN
        ANSIG(XPos,YPos);
        ChatArray[Line][CPos] := C;
        OutKey(C);
        Inc(CPos);
        Inc(XPos);
        ChatArray[Line][0] := Chr(CPos - 1);
        IF (Trapping) THEN
          Write(TrapFile,C);
      END
    ELSE
      BEGIN
        ChatArray[Line][CPos] := C;
        Inc(CPos);
        ChatArray[Line][0] := Chr(CPos - 1);
        Counter := (CPos - 1);
        WHILE (Counter > 0) AND (ChatArray[Line][Counter] <> ' ') AND (ChatArray[Line][Counter] <> ^H) DO
          Dec(Counter);
        IF (Counter > (CPos DIV 2)) AND (Counter <> (CPos - 1)) THEN
          BEGIN
            WrapLine := Copy(ChatArray[Line],(Counter + 1),(CPos - Counter));
            FOR Counter1 := (CPos - 2) DOWNTO Counter DO
              BEGIN
                ANSIG(XPos,YPos);
                Prompt(^H);
                Dec(XPos);
              END;
            FOR Counter1 := (CPos - 2) DOWNTO Counter DO
              BEGIN
                ANSIG(XPos,YPos);
                Prompt(' ');
                Inc(XPos);
              END;
            ChatArray[Line][0] := Chr(Counter - 1);
          END;
        NL;
        XPos := 2;
        IF (YPos > 1) AND (YPos < 11) OR (YPos > 12) AND (YPos < 22) THEN
          BEGIN
            Inc(YPos);
            Inc(Line);
          END
        ELSE
          BEGIN
            FOR Counter := 1 TO 9 DO
              ChatArray[Counter] := ChatArray[Counter + 1];
            ChatArray[10] := '';
            FOR Counter := 10 DOWNTO 1 DO
              BEGIN
                ANSIG(2,Counter + 1);
                PrintMain(ChatArray[Counter]);
                Clear_EOL;
              END;
          END;
        ANSIG(XPos,YPos);
        CPos := 1;
        ChatArray[Line] := '';
        IF (WrapLine <> '') THEN
          BEGIN
            Prompt(WrapLine);
            ChatArray[Line] := WrapLine;
            WrapLine := '';
            CPos := (Length(ChatArray[Line]) + 1);
            XPos := Length(ChatArray[Line]) + 2;
          END;
      END;
  END;

  PROCEDURE DoBackSpace(VAR Cpos,XPos: Byte; YPos: Byte; VAR S: AStr);
  BEGIN
    IF (CPos > 1) THEN
      BEGIN
        ANSIG(XPos,YPos);
        BackSpace;
        Dec(CPos);
        Dec(XPos);
        S[0] := Chr(CPos - 1);
      END;
  END;

  PROCEDURE DoTab(VAR CPos,XPos: Byte; YPos: Byte; VAR S: AStr);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
    Counter := (5 - (CPos MOD 5));
    IF ((CPos + Counter) < 79) THEN
      BEGIN
        FOR Counter1 := 1 TO Counter DO
          BEGIN
            ANSIG(XPos,YPos);
            Prompt(' ');
            S[CPos] := ' ';
            Inc(CPos);
            Inc(XPos);
          END;
        S[0] := Chr(CPos - 1);
      END;
  END;

  PROCEDURE DoCarriageReturn(VAR CPos,XPos,YPos: Byte; VAR S: AStr);
  VAR 
    i : Integer;
  BEGIN
    S[0] := Chr(CPos - 1);
    (* Check Scrool here *)
    Inc(YPos);
    XPos := 2;
    { Fix Splitscreen so user and op stay on their own sides }
    IF (YPos = 12) THEN
      BEGIN
        ANSIG(1,2);
        Prompt(#27'[M'); { Delete line }
        ANSIG(1,11);
        Prompt(#27'[L'); { Insert line }
        YPos := 11;
      END
    ELSE IF (YPos = 23) THEN
      BEGIN
        ANSIG(1,13);
        Prompt(#27'[M'); { Delete line }
        ANSIG(1,22);
        Prompt(#27'[L'); { Insert line }
        YPos := 22;
      END;
    ANSIG(XPos,YPos);
    (* Do Cmds Here or add as Ctrl *)
    CPos := 1;
    S := '';
  END;

  PROCEDURE DoBackSpaceWord(VAR CPos,XPos: Byte; YPos: Byte; VAR S: AStr);
  BEGIN
    IF (CPos > 1) THEN
      BEGIN
        REPEAT
          ANSIG(XPos,YPos);
          BackSpace;
          Dec(CPos);
          Dec(XPos);
        UNTIL (CPos = 1) OR (S[CPos] = ' ');
        S[0] := Chr(CPos - 1);
      END;
  END;

  PROCEDURE DoBackSpaceLine(VAR CPos,Xpos: Byte; YPos: Byte; VAR S: AStr);
  VAR
    Counter: Byte;
  BEGIN
    IF (CPos > 1) THEN
      BEGIN
        FOR Counter := 1 TO (CPos - 1) DO
          BEGIN
            ANSIG(XPos,YPos);
            BackSpace;
            Dec(CPos);
            Dec(XPos);
          END;
        S[0] := Chr(CPos - 1);
      END;
  END;

BEGIN
  ChatHelp := FALSE; {LeeW: is this the best spot for this?}
  SaveWhereX := WhereX;
  SaveWhereY := WhereY;
  SaveTextAttr := TextAttr;
  SaveScreen(Wind);
  UserColor(1);
  SaveMCIAllowed := MCIAllowed;
  MCIAllowed := TRUE;
  ChatTime := GetPackDateTime;
  DOSANSIOn := FALSE;
  IF (General.MultiNode) THEN
    BEGIN
      LoadNode(ThisNode);
      SaveNAvail := (NAvail IN Noder.Status);
      Exclude(Noder.Status,NAvail);
      SaveNode(ThisNode);
    END;
  SavePrintingFile := PrintingFile;
  InChat := TRUE;
  ChatCall := FALSE;
  SaveEcho := Echo;
  Echo := TRUE;
  IF (General.AutoChatOpen) THEN
    ChatFileLog(TRUE)
  ELSE IF (ChatAuto IN ThisUser.SFlags) THEN
    ChatFileLog(TRUE);
  {NL;}
  Exclude(ThisUser.ACFlags,Alert);
  {
  PrintF('CHATINIT');
  IF (NoFile) THEN
    (*
    Prompt('^5'+FString.EnGage);
    *)
    lRGLNGStr(2,FALSE);
  }
  IF (ChatReason <> '') THEN
    BEGIN
      lStatus_Screen(100,ChatReason,FALSE,S);
      ChatReason := '';
    END;

  SysOpLastLineStr := '';
  UserLastLineStr := '';
  SysOpXPos := 2;
  SysOpYPos := 2;
  UserXPos := 2;
  UserYPos := 13;

  SysOpStr := '';
  UserStr := '';
  SysOpCPos := 1;
  UserCPos := 1;
  SysOpLine := 1;
  UserLine := 1;

  ToggleWindow(FALSE);
  SysOpChatWindow;
  ANSIG(SysOpXPos,SysOpYPos);
  ToggleWindow(TRUE);
  UserColor({10}General.SysOpColor);
  WColor := TRUE;
  REPEAT
    C := Char(GetKey);
    CheckHangUp;
    CASE Ord(C) OF
      32..255 :
          IF (WColor) THEN
            DoChar(C,SysOpCPos,SysOpXPos,SysOpYPos,SysOpLine,SysOpChat,SysOpLastLineStr)
          ELSE
            DoChar(C,UserCPos,UserXPos,UserYPos,UserLine,UserChat,UserLastLineStr);
     16 : BEGIN { Ctrl+P - Page user & SysOp }
            FOR Counter := 650 TO 700 DO
              BEGIN
                Sound(Counter);
                Delay(4);
                NoSound;
              END;
            REPEAT
              Dec(Counter);
              Sound(Counter);
              Delay(2);
              NoSound;
            UNTIL (Counter = 200);
            Prompt(^G^G);
          END;
      7 : HangUp := TRUE; { Ctrl+G - Log off }
      8 : IF (WColor) THEN
            DoBackSpace(SysOpCpos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DoBackSpace(UserCpos,UserXPos,UserYPos,UserStr);
      9 : IF (WColor) THEN
            DoTab(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DoTab(UserCPos,UserXPos,UserYPos,UserStr);
     13 : IF (WColor) THEN
            DoCarriageReturn(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DoCarriageReturn(UserCPos,UserXPos,UserYPos,UserStr);
     17 : InChat := FALSE;
     23 : IF (WColor) THEN
            DoBackSpaceWord(SysOpCPos,SysOpXPos,SysOpYPos,SysOpStr)
          ELSE
            DoBackSpaceWord(UserCPos,UserXPos,UserYPos,UserStr);
     24 : IF (WColor) THEN
            DoBackSpaceLine(SysOpCPos,SysOpXpos,SysOpYPos,SysOpStr)
          ELSE
            DoBackSpaceLine(UserCPos,UserXpos,UserYPos,UserStr);
     26 : BEGIN { Ctrl+Z = Chat help }
            SaveWhereX := WhereX;
            SaveWhereY := WhereY;
            IF (ChatHelp) THEN
              BEGIN
				ANSIG(1,12);
				UserColor(1);
				FOR Counter := 1 TO 79 DO
				OutKey(#196);
				ANSIG(31,12);
				Prompt('^1[ ^2CTRL+Z for Help^1 ]');
                ANSIG(SaveWhereX,SaveWhereY);
                ChatHelp := FALSE;
              END
            ELSE
              BEGIN
                ChatHelp := TRUE;
				ANSIG(1,12);
				UserColor(1);
				FOR Counter := 1 TO 79 DO
				  OutKey(#196);
				ANSIG(10,12);
				Prompt('[ ^2CTRL+^1Q^2 = Quit, ^1G^2 = Hang Up, ^1X^2 = Del Line, ^1W^2 = Del Word^1 ]');
                ANSIG(SaveWhereX,SaveWhereY);
              END;
                IF (WColor) THEN
                  UserColor(General.SysOpColor)
                ELSE
                  UserColor(General.UserColor);
      END; { Help }
    END;
  UNTIL ((NOT InChat) OR (HangUp));
{
  RemoveWindow(Wind);
  ANSIG(SaveWhereX,SaveWhereY);
  TextAttr := SaveTextAttr;
}
  IF (General.MultiNode) THEN
    BEGIN
      LoadNode(ThisNode);
      IF (SaveNAvail) THEN
        Include(Noder.Status,NAvail);
      SaveNode(ThisNode);
    END;
  ChatTime := (GetPackDateTime - ChatTime);
  IF (ChopTime = 0) THEN
    Inc(FreeTime,ChatTime);
  TLeft;
  S := 'Chatted for '+FormattedTime(ChatTime);
  IF (CFO) THEN
    BEGIN
      S := S+'  -{ Recorded in Chat';
      IF (ChatSeparate IN ThisUser.SFlags) THEN
        S := S + IntToStr(UserNum);
      S := S+'.LOG }-';
    END;
  SysOpLog(S);
  InChat := FALSE;
  Echo := SaveEcho;
  IF ((HangUp) AND (CFO)) THEN
    BEGIN
      WriteLn(ChatFile);
      WriteLn(ChatFile,'=> User disconnected');
      WriteLn(ChatFile);
    END;
  PrintingFile := SavePrintingFile;
  IF (CFO) THEN
    ChatFileLog(FALSE);
  IF (InVisEdit) THEN
    Buf := ^L
  ELSE
	Buf := ^M; { LeeW: Added - Carriage feed, to refresh menu after }
  MCIAllowed := SaveMCIAllowed;
END;
END.