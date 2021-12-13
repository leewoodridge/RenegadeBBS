{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
Lee Woodridge
 10/10/2021 - Listnodes now has a pause param -- temp removed
            - Cleaned up procs
 10/12/2021 - Teleconf strings for normal,anon,priv,global used to be in liner, now in main lang
            - Indenting...
 12/12/2021 - removed pause from msgnode
            
            added can't set teleconf room 1 private
            11/1/2021 fixed bug where someone you ignored could still send you msg out of chat
            
            to do --- 
            not be able to change room 1 topic
            joining empty room should set you as mod
            leaving room displays to every room i think
            combine teleconfcheck and checkstatus???
}

UNIT Multnode;

INTERFACE

USES
  Common;

PROCEDURE PrintMsg(s: STRING);
PROCEDURE TeleConfCheck; { called from getkey }
PROCEDURE ToggleChatAvailability;
PROCEDURE CheckStatus; { Executed during DOS emulator and menu load }
PROCEDURE ListNodes;
PROCEDURE PageNode;
PROCEDURE MessageNode(CONST b: ASTR);
PROCEDURE TeleConference;
PROCEDURE DumpNode;

IMPLEMENTATION

USES
  CRT, {WhereY}
  Common2, {ToggleWindow}
  Doors,
  Menus,
  Script,
  ShortMsg,
  TimeFunc;
  
VAR
  OnLine: Byte; { LeeW: What line we're on in chat }

PROCEDURE PrintMsg(s: STRING);
VAR
  b,
  Y1,
  Y2: Byte;
BEGIN
  IF (OnLine+(Length(s) DIV 80) > MCIPosRecArray[2].Y) THEN
    BEGIN
      ANSIG(MCIPosRecArray[1].X,MCIPosRecArray[1].Y); { Start line }
      FOR b := Length(s) DIV 80 DOWNTO 0 DO
        Dec(OnLine);
      FOR b := Length(s) DIV 80 DOWNTO 0 DO
        Prompt(#27'[M'); { Delete line }
      ANSIG(1,OnLine);
      FOR b := Length(s) DIV 80 DOWNTO 0 DO
        Prompt(#27'[L'); { Insert line }
      Print(s);
      FOR b := Length(s) DIV 80 DOWNTO 0 DO
        Inc(OnLine)
    END
  ELSE
    BEGIN
      ANSIG(1,OnLine);
      Print(s);
      FOR b := Length(s) DIV 80 DOWNTO 0 DO
        Inc(OnLine)
    END;
END;

PROCEDURE TeleConfCheck;
VAR
  f: FILE;
  s: STRING;
  Counter: Byte;
  SaveMCIAllowed: Boolean;
  Y1,
  Y2: Byte;
  { Only check if we're bored and not slicing }
BEGIN
  IF (MaxChatRec > NodeChatLastRec) THEN
    BEGIN
      Assign(f,General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP');
      Reset(f,1);
      Seek(f,NodeChatLastRec);
      WHILE NOT EOF(f) DO
        BEGIN
          BlockRead(f,s[0],1);
          BlockRead(f,s[1],Ord(s[0]));
          MultiNodeChat := FALSE;  { Avoid recursive calls during pause! }
          SaveMCIAllowed := MCIAllowed;
          MCIAllowed := FALSE;
          PrintMsg(s);
          MCIAllowed := SaveMCIAllowed;
          MultiNodeChat := TRUE;
          ANSIG(MCIPosRecArray[0].X,MCIPosRecArray[0].Y); { Go to input field }
        END;
      Close(f);
      LastError := IOResult;
      NodeChatLastRec := MaxChatRec;
    END;
END;

PROCEDURE SelectNode(VAR NodeNum: Byte; IsChat: BOOLEAN);
BEGIN
  ListNodes;
  InputByte('Which node',NodeNum,[NumbersOnly],1,MaxNodes,Changed);
  IF (NodeNum >= 1) AND (NodeNum <= MaxNodes) AND (NodeNum <> ThisNode) THEN
    BEGIN
      LoadNode(NodeNum);
      IF (NOT (NActive IN NodeR.Status) OR (NOT (NAvail IN NodeR.Status) AND IsChat)) AND NOT
         ((NInvisible IN NodeR.Status) AND NOT CoSysOp) THEN
        BEGIN
          NL;
          Print('That node is unavailable.');
          NodeNum := 0;
        END;
      IF (NodeR.User = 0) OR NOT (NAvail IN NodeR.Status) OR ((NInvisible IN NodeR.Status) AND NOT CoSysOp) THEN
        NodeNum := 0;
    END
  ELSE
    NodeNum := 0;
END;

PROCEDURE DumpNode;
VAR
  NodeNum: Byte;
BEGIN
  SelectNode(NodeNum,FALSE);
  IF (NodeNum > 0) THEN
    IF PYNQ('Hang up user on node '+IntToStr(NodeNum)+'? ',0,FALSE) THEN
      BEGIN
        LoadNode(NodeNum);
        Include(NodeR.Status,NHangup);
        IF PYNQ('Recycle node '+IntToStr(NodeNum)+' after logoff? ',0,FALSE) THEN
          Include(NodeR.Status,NRecycle);
        SaveNode(NodeNum);
      END;
END;

PROCEDURE PageNode;
VAR
  NodeNum: Byte;
BEGIN
  IF (NOT General.MultiNode) THEN
    BEGIN
      Print('This BBS is currently not operating in Multi-Node.');
      EXIT;
    END;
  SelectNode(NodeNum,TRUE);
  IF (NodeNum > 0) AND (NodeNum <> ThisNode) THEN
    MessageNode(IntToStr(NodeNum)+';^8'+Caps(ThisUser.Name)+' on node '+IntToStr(ThisNode)+' has paged you for chat.'^M^J);
END;

PROCEDURE CheckStatus;
VAR
  f: FILE;
  s: STRING;
  j: BYTE;
BEGIN
  LoadNode(ThisNode);
  WITH NodeR DO
    BEGIN
      IF (NUpdate IN Status) THEN
        BEGIN
          j := ThisUser.Waiting;
          Reset(UserFile);
          Seek(UserFile,UserNum);
          Read(UserFile,ThisUser);
          Close(UserFile);
          LastError := IOResult;
          update_screen;
          IF (ThisUser.Waiting > j) THEN
            BEGIN
              Print('^8You have new private mail waiting.');
            END;
          Exclude(Status,NUpdate);
          SaveNode(ThisNode);
          IF (SMW IN ThisUser.ACFlags) THEN
            BEGIN
              ReadShortMessage;
            END;
        END;
      IF (NHangup IN Status) OR (NRecycle IN Status) THEN
        BEGIN
          HangUp := TRUE;
          IF (NRecycle IN Status) THEN
            QuitAfterDone := TRUE;
        END;
      IF {(NOT MultiNodeChat) AND }(MaxChatRec > NodeChatLastRec) THEN
        BEGIN
          Assign(f,General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP');
          Reset(f,1);
          Seek(f,NodeChatLastRec);
          WHILE NOT EOF(f) DO
            BEGIN
              BlockRead(f,s[0],1);
              BlockRead(f,s[1],Ord(s[0]));
              Print(s);
            END;
          Close(f);
          LastError := IOResult;
          NodeChatLastRec := MaxChatRec;
          {PauseScr(FALSE);}
        END;
    END;
END;

PROCEDURE LowLevelSend(s: STRING; Node: Byte);
VAR
  F: FILE;
BEGIN
  IF (Node < 0) THEN
    Exit;
  Assign(f,General.TempPath+'MSG'+IntToStr(Node)+'.TMP');
  Reset(f,1);
  IF (IOResult = 2) THEN
    ReWrite(f,1);
  Seek(f,FileSize(f));
  BlockWrite(f,s[0],(Length(s) + 1));
  Close(f);
  LastError := IOResult;
END;



PROCEDURE ToggleChatAvailability;
BEGIN
  NL;
  IF (NOT General.MultiNode) THEN
  BEGIN
    Print('This BBS is currently not operating in Multi-Node.');
    Exit;
  END;
  LoadNode(ThisNode);
  IF (NAvail IN NodeR.Status) THEN
  BEGIN
    Exclude(NodeR.Status,NAvail);
    Print('You are not available for chat.');
  END
  ELSE
  BEGIN
    Include(NodeR.Status,NAvail);
    Print('You are now available for chat.');
  END;
  SaveNode(ThisNode);
END;

PROCEDURE MessageNode(CONST b: ASTR);
VAR
  s: STRING;
  NodeNum: Byte;
  Forced: BOOLEAN;
BEGIN
  IF (NOT General.MultiNode) THEN
    BEGIN
      Print('This BBS is currently not operating in Multi-Node.');
      Exit;
    END;
  s := b;
  NodeNum := StrToInt(s);
  IF (b <> '') AND (IsInvisible) THEN
    Exit;
  Forced := (s <> '');
  IF (NodeNum = 0) AND (Copy(s,1,1) <> '0') THEN
    BEGIN
      SelectNode(NodeNum,TRUE);
      Forced := FALSE;
      IF (NodeNum = 0) THEN
        Exit;
    END;
  IF (NodeNum = ThisNode) THEN
    Exit;
  IF (Forced OR AACS(General.TeleConfMCI)) THEN
    s := MCI(s);
  IF (NodeNum > 0) THEN
    BEGIN
      LoadNode(NodeNum);
      IF (NodeR.User = 0) THEN
        Exit;
    END;
  IF (s <> '') THEN
    s := '^1'+Copy(s,(Pos(';',s) + 1),255)
  ELSE
    BEGIN
      Prt('Message: ');
      InputMain(s,(SizeOf(s) - 1),[NoInputField]);
    END;
  IF (Forced OR AACS(General.TeleConfMCI)) THEN
    s := MCI(s);
  IF (s <> '') THEN
    BEGIN
      LoadNode(NodeNum);
      IF (NOT Forced) THEN
        BEGIN
          IF ((ThisNode MOD 8) IN NodeR.Forget[ThisNode DIV 8]) THEN
            BEGIN
              Print({^M^J}'^8That node is ignoring you!^0');
              {pause?}
              Exit;
            END;
            (*
          IF NOT (NodeR.GroupChat) THEN
                LowLevelSend({^M^J}'^0Message from ^1'+Caps(ThisUser.Name)+
				'^0 on node ^1'+IntToStr(ThisNode)+'^0:'{^M^J},NodeNum);
                *)
                (*
          LoadNode(NodeNum);
          IF NOT ((ThisNode MOD 8) IN NodeR.Forget[ThisNode DIV 8]) THEN
            BEGIN
              IF NOT (NodeR.GroupChat) THEN
                LowLevelSend({^M^J}'^0Message from ^1'+Caps(ThisUser.Name)+
				'^0 on node ^1'+IntToStr(ThisNode)+'^0:'{^M^J},NodeNum);
            END
          ELSE
            *)
        END;
      IF (NodeNum = 0) THEN
        BEGIN { Send message to all nodes }
          FOR NodeNum := 1 TO MaxNodes DO
            IF (NodeNum <> ThisNode) THEN
              BEGIN
                LoadNode(NodeNum);
                IF (NodeR.User > 0) THEN
                  LowLevelSend(s,NodeNum);
                {SysOp log here}
              END;
        END
      ELSE
        BEGIN { Normal message }
          IF (NodeR.GroupChat) THEN
            LowLevelSend(MCI(lRGLngStr(194,TRUE)) + s,NodeNum)
          ELSE
            BEGIN
              LowLevelSend('^0Message from ^1'+Caps(ThisUser.Name)+'^0 on node ^1'+IntToStr(ThisNode)+'^0:',NodeNum);
              LowLevelSend(s,NodeNum);
            END;
          {SysOp log here}
        END;
    END;
  {PauseScr(FALSE);}
  {save/restorecolor}
END;

FUNCTION NodeListMCI(CONST s: ASTR; Data1,Data2: Pointer): STRING;
VAR
  NodeRecPtr: ^NodeRecordType;
  NodeNum: ^Byte;
BEGIN
  NodeRecPtr := Data1;
  NodeNum := Data2;
  NodeListMCI := s;
  IF (NOT (NActive IN NodeRecPtr^.Status)) OR (NodeRecPtr^.User > (MaxUsers - 1)) OR
     (NodeRecPtr^.User < 1) OR ((NInvisible IN NodeRecPtr^.Status) AND (NOT CoSysOp)) THEN
    BEGIN
      NodeListMCI := '-';
      WITH NodeRecPtr^ DO
        CASE s[1] OF
          'N' : IF (s[2] = 'N') THEN
                  NodeListMCI := IntToStr(NodeNum^);
          'A' : CASE s[2] OF
                  'C' : NodelistMCI := lRGLngStr(143,TRUE);
                  'V' : NodeListMCI := AOnOff((NAvail IN Status),'Y','N');
                END;
          'U' : IF (s[2] = 'N') THEN
                  NodeListMCI := lRGLngStr(144,TRUE);
        END;
    END
  ELSE
    WITH NodeRecPtr^ DO
      CASE s[1] OF
        'A' : CASE s[2] OF
                'C' : NodeListMCI := ActivityDesc;
                'G' : NodeListMCI := IntToStr(Age);
                'T' : NodeListMCI := AOnOff((NActive IN Status),'Y','N');
                'V' : NodeListMCI := AOnOff((NAvail IN Status),'Y','N');
              END;
        'L' : IF (s[2] = 'C') THEN
                NodeListMCI := CityState;
        'N' : IF (s[2] = 'N') THEN
                NodeListMCI := IntToStr(NodeNum^);
        'U' : IF (s[2] = 'N') THEN
                NodeListMCI := Caps(UserName);
        'R' : IF (s[2] = 'M') THEN
                NodeListMCI := IntToStr(Room);
        'S' : IF (s[2] = 'X') THEN
                NodeListMCI := Sex;
        'T' : IF (s[2] = 'O') THEN
                NodeListMCI := IntToStr((GetPackDateTime - LogonTime) DIV 60);
      END;
END;

PROCEDURE ListNodes;
VAR
  NodeNum: Byte;
BEGIN
  IF (NOT General.MultiNode) THEN
    BEGIN
      Print('This BBS is currently not operating in Multi-Node.');
      Exit;
    END;
  Abort := FALSE;
  Next := FALSE;
  AllowContinue := TRUE;
  IF (NOT ReadBuffer('NODELM')) THEN
    Exit;
  PrintF('NODELH');
  NodeNum := 1;
  WHILE (NodeNum <= MaxNodes) AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      LoadNode(NodeNum);
      DisplayBuffer(NodeListMCI,@NodeR,@NodeNum);
      Inc(NodeNum);
    END;
  IF (NOT Abort) THEN
    PrintF('NODELT');
  AllowContinue := FALSE;
  {IF (PauseAfter) THEN
    PauseScr(FALSE);}
END;

{ ** teleconf start here ** }

PROCEDURE TeleConference;
TYPE
  WhyNot = (NotModerator,NotOnline,NotRoom,NotInRoom,NotValid);
VAR
  RoomFile: FILE OF RoomRec;
  ActionsFile: TEXT;
  Room: RoomRec;
  User: UserRecordType;
  s: STRING;
  s2,
  s3,
  {execs: ASTR;}
  SaveName: STRING[36];
  Cmd: CHAR;
  i,
  j,
  SaveTimeOut,
  SaveTimeOutBell: INTEGER;
  Done{,
  ChannelOnly}: BOOLEAN;
  Y1,
  Y2: Byte;

{printmsg was here}

  FUNCTION ActionMCI(s: ASTR): STRING;
  VAR
    Temp: ASTR;
    Index: INTEGER;
  BEGIN
    Temp := '';
    FOR Index := 1 TO Length(s) DO
      IF (s[Index] = '%') THEN
        CASE (UpCase(s[Index + 1])) OF
          'S' : BEGIN
                  Temp := Temp + Caps(ThisUser.Name);
                  Inc(Index);
                END;
          'R' : BEGIN
                  Temp := Temp + Caps(SaveName);
                  Inc(Index);
                END;
          'G' : BEGIN
                  Temp := Temp + AOnOff((ThisUser.sex = 'M'),'his','her');
                  Inc(Index);
                END;
          'H' : BEGIN
                  Temp := Temp + AOnOff((ThisUser.sex = 'M'),'him','her');
                  Inc(Index);
                END;
        END
      ELSE
        Temp := Temp + s[Index];
    ActionMCI := Temp;
  END;

  PROCEDURE LoadRoom(VAR Chan: INTEGER);
  BEGIN
    Reset(RoomFile);
    Seek(RoomFile,(Chan - 1));
    Read(RoomFile,Room);
    Close(RoomFile);
    LastError := IOResult;
  END;

  PROCEDURE SaveRoom(VAR Chan: INTEGER);
  BEGIN
    Reset(RoomFile);
    Seek(RoomFile,(Chan - 1));
    Write(RoomFile,Room);
    Close(RoomFile);
    LastError := IOResult;
  END;
  
  PROCEDURE RemoveRoom(VAR Chan: INTEGER);
  BEGIN
    Reset(RoomFile);
    Seek(RoomFile,(Chan - 1));

    WITH Room DO
      BEGIN
        Topic := '';
        Anonymous := FALSE;
        Private := FALSE;
        Occupied := FALSE;
        Moderator := 0;
      END;

    Write(RoomFile,Room);
    Close(RoomFile);
    LastError := IOResult;
  END;

  PROCEDURE SendMessage(s: STRING; ShowHere: Boolean);
  VAR
    i: WORD;
    Trap: TEXT;
  BEGIN
    IF (General.TrapTeleConf) THEN
      BEGIN
        Assign(Trap,General.LogsPath+'ROOM'+IntToStr(RoomNumber)+'.TRP');
        Append(Trap);
        IF (IOResult = 2) THEN
          ReWrite(Trap);
        WriteLn(Trap,StripColor(s));
        Close(Trap);
      END;
    WITH NodeR DO
      FOR i := 1 TO MaxNodes DO
        BEGIN
          LoadNode(i);
          { should we check for multinodechat??}
          IF (i <> ThisNode) AND (NOT ((ThisNode MOD 8) IN Forget[ThisNode DIV 8])) AND { not yourself, and not ignoring you}
          ((NodeR.GroupChat) AND (NodeR.Room = RoomNumber)) OR
          ((NodeR.Channel = ChatChannel) AND (ChatChannel > 0){ AND ChannelOnly})
          THEN { in the same room of chat }
          (*
          IF (i <> ThisNode) AND 
             ((NOT ((ThisNode MOD 8) IN Forget[ThisNode DIV 8])) AND ((NOT ChannelOnly) AND (MultiNodeChat){ AND 
             (Room = RoomNumber)) OR
             ((NodeR.Channel = ChatChannel) AND (ChatChannel > 0) AND ChannelOnly})) THEN*)
            LowLevelSend(s,i);
        END;
        IF (MultiNodeChat) AND NOT AACS(General.TeleConfMCI) THEN
          MCIAllowed := FALSE;
        PrintMsg(s);
        MCIAllowed := TRUE;
  END;

  PROCEDURE AddToRoom(VAR Chan: INTEGER);
  VAR
    s: string;
    People: WORD;
    i: WORD;
  BEGIN
    IF (NOT IsInvisible) AND NOT ((Chan MOD 8) IN NodeR.Booted[Chan DIV 8]) THEN
      SendMessage('^9 * '+allCaps(ThisUser.Name)+' has joined room #'+IntToStr(Chan),TRUE);
    LoadRoom(Chan);
    IF (NOT Room.Occupied) THEN
      BEGIN
        Room.Occupied := TRUE;
        SaveRoom(Chan);
      END;
    People := 0;
    FOR i := 1 TO MaxNodes DO
      BEGIN
        IF (i = ThisNode) THEN
          Continue;
        LoadNode(i);
        IF (NodeR.Room = Chan) AND (NodeR.GroupChat) THEN
          Inc(People);
      END;
    WITH Room DO
      BEGIN
      (*
    ANSIG(MCIPosRecArray[3].X,MCIPosRecArray[3].Y); { Room number position }
    Prt(PadLeftInt(Chan,3));
    ANSIG(MCIPosRecArray[4].X,MCIPosRecArray[4].Y); { Room topic position }
    Prt('topic');
    ANSIG(MCIPosRecArray[5].X,MCIPosRecArray[5].Y); { Room moderator position }
    Prt(IntToStr(Moderator));
    *)
        ANSIG(MCIPosRecArray[4].X,MCIPosRecArray[4].Y); { Topic }
        IF (Chan = 1) THEN
          Topic := '%BN'; {add this to lang}
        {Prt(PadLeftStr(Topic,40));}
      
          {ANSIG(1,OnLine);}
        IF (People = 0) THEN
          PrintMsg('^0 '#254' You''re the only one in this room^0')
        ELSE
          BEGIN
            s := '';
            j := 1;
            WHILE (J <= MaxNodes) AND (NOT Abort) DO
              BEGIN
                LoadNode(j);
                IF (NodeR.GroupChat) AND (NodeR.Room = Chan) AND (j <> ThisNode) THEN
                  IF NOT (NInvisible IN NodeR.Status) OR (CoSysOp) THEN
                    BEGIN
                      s := s+'^1'+AllCaps(NodeR.UserName)+'^0, ';
                    END;
                Inc(j);
              END;
          s := Copy(s,1,(Length(s) - 2));
          s := s+AOnOff(People = 1,' is',' are')+' also here';
          PrintMsg('^0 '#254' '+s);
          END;
          {Print('^1There '+AOnOff(People = 1,'is','are')+' '+IntToStr(People)+
                ' other '+AOnOff(People = 1,'person','people')+' present.');
                SendMessage('',ThisUser.TeleConfEcho); {leew}  
      END;
    LoadNode(ThisNode);
    NodeR.Room := Chan;
    SaveNode(ThisNode);
  END;

  PROCEDURE RemoveFromRoom(VAR Chan: INTEGER);
  VAR
    People: WORD;
    i: WORD;
  BEGIN
    IF (NOT IsInvisible) AND NOT ((Chan MOD 8) IN NodeR.Booted[Chan DIV 8]) THEN {leew add match rooms??}
      SendMessage('^8 * '+AllCaps(ThisUser.Name)+' has left the room', FALSE);
    LoadRoom(Chan);
    WITH Room DO
      IF (Moderator = UserNum) THEN
        Moderator := 0;
    People := 0;
    FOR i := 1 TO MaxNodes DO
      BEGIN
        IF (i = ThisNode) THEN
          Continue;
        LoadNode(i);
        IF (NodeR.Room = Chan) AND (NodeR.GroupChat) THEN
          Inc(People);
      END;
    IF (People = 0) THEN
      {Room.Occupied := FALSE;}
      RemoveRoom(Chan);
      
    IF (NOT IsInvisible) THEN
      SaveRoom(Chan);
      {leew: reset room here!}
  END;

  FUNCTION Name2Number(VAR s,sname: ASTR): INTEGER;
  VAR
    i: INTEGER;
    Temp: STRING;
  BEGIN
    Name2Number := 0;
    IF (Pos(' ',s) > 0) THEN
      Sname := Copy(s,1,Pos(' ',s))
    ELSE
      Sname := s;
    i := StrToInt(SQOutSp(Sname));
    IF (SQOutSp(Sname) = IntToStr(i)) AND ((i > 0) AND (i <= MaxNodes)) THEN
      BEGIN
        LoadNode(i);
        WITH NodeR DO
          IF (User > 0) THEN
            BEGIN
              IF ((NOT (NInvisible IN Status)) OR (CoSysOp)) THEN
                Name2Number := i
              ELSE
                Name2Number := 0;
              s := Copy(s,(Length(Sname) + 1),255);
              Sname := Caps(UserName);
              Exit;
            END;
      END;
    i := 1;
    Sname := '';
    IF (Pos(' ',s) > 0) THEN
      Temp := AllCaps(Copy(s,1,(Pos(' ',s) - 1)))
    ELSE
      Temp := AllCaps(s);
    WHILE (i <= MaxNodes) DO
      BEGIN
        LoadNode(i);
        WITH NodeR DO
          IF (User > 0) THEN
            BEGIN
              IF ((UserName = AllCaps(Copy(s,1,Length(UserName)))) OR (Pos(Temp,UserName) > 0)) THEN
                BEGIN
                  Name2Number := i;
                  IF (UserName = AllCaps(Copy(s,1,Length(UserName)))) THEN
                    s := Copy(s,(Length(UserName) + 2), 255)
                  ELSE
                    s := Copy(s,(Length(temp) + 2), 255);
                  sname := Caps(UserName);
                  Break;
                END;
            END;
        Inc(i);
      END;
  END;

  PROCEDURE Nope(Reason: WhyNot);
  BEGIN
    CASE Reason OF
      NotModerator : PrintMsg('^8 * You are not the moderator!^0');
      NotOnline    : PrintMsg('^8 * That user is not logged on!^0');
      NotRoom      : PrintMsg('^8 * Invalid room number!^0');
      NotInRoom    : PrintMsg('^8 * That user is not in this room!^0');
      NotValid     : PrintMsg('^8 * Invalid option! Type "/?" for help^0');
    END;
  END;

  PROCEDURE ShowRoom(Chan: INTEGER);
  VAR
    People: WORD;
    i: WORD;
    UsersInRoom: STRING;
  BEGIN
    UsersInRoom := '';
    LoadRoom(Chan);
    People := 0;
    FOR i := 1 TO MaxNodes DO
      BEGIN
        LoadNode(i);
        IF (NodeR.Room = Chan) AND (NodeR.GroupChat) {AND (i <> ThisNode)} THEN
          BEGIN
            Inc(People);
            UsersInRoom := UsersInRoom+'^1'+NodeR.UserName+'^0, ';
          END;
      END;
      UsersInRoom := Copy(UsersInRoom,1,(Length(UsersInRoom) - 2)); { Remove last ', ' }
      
    IF (Room.Occupied) THEN
      BEGIN
        IF (Room.Moderator > 0) THEN
          LoadURec(User,Room.Moderator)
        ELSE
          User.Name := 'None';
          
        PrintMsg('^0Conference Room: ^1'+PadLeftInt(Chan,5)+' ^0Moderator: ^1'+Caps(User.Name));
        PrintMsg('^0Type: ^1'+PadLeftStr(AOnOff(Room.Private,'Private','Public'),17)+'^0Topic: ^1'+Room.Topic);
        IF (People <> 0) THEN
          PrintMsg('^0People: ^1'+IntToStr(People)+' - '+UsersInRoom)
        ELSE
          PrintMsg('^0People: ^1'+IntToStr(People));
        
        IF (Room.Anonymous) THEN
          PrintMsg('This room is in anonymous mode.');
      END;
(*    
    j := 1;
    WHILE (J <= MaxNodes) AND (NOT Abort) DO
      BEGIN
        LoadNode(j);
        IF (NodeR.GroupChat) AND (NodeR.Room = Chan) THEN
          IF NOT (NInvisible IN NodeR.Status) OR (CoSysOp) THEN
            PrintMsg('^1'+Caps(NodeR.UserName)+' on node '+IntToStr(j));
        Inc(j);
      END;
    *)  
  END;

  PROCEDURE InputMain(VAR s: STRING);
  VAR
    os,
    cs: STRING;
    cp: INTEGER;
    c: CHAR;
    ml,
    origcolor: BYTE;
    cb: WORD;
    LastCheck: LONGINT;

    PROCEDURE DoBackSpace;
    VAR
      i,j,c: BYTE;
      WasColor: BOOLEAN;

      PROCEDURE set_color;
      BEGIN
        c := origcolor;
        i := 1;
        WHILE (i < cp) DO
        BEGIN
          IF (s[i]='^') THEN
          BEGIN
            c := Scheme.Color[Ord(s[i+1]) + Ord('1')];
            Inc(i);
          END;
          IF (s[i]='|') AND (i + 1 < Length(s)) AND (s[i + 1] IN ['0'..'9']) AND (s[i + 2] IN ['0'..'9']) THEN
          BEGIN
            cs := s[i + 1] + s[i + 2];
            CASE cb OF
              0..15  : c := (c - (c MOD 16) + cb);
              16..23 : c:= ((cb - 16) * 16) + (c MOD 16);
            END;
          END;
          Inc(i);
        END;
        SetC(c);
      END;

    BEGIN { DoBackSpace }
      WasColor := FALSE;
      IF (cp > 1) THEN
      BEGIN
        Dec(cp);
        IF (cp > 1) THEN
        BEGIN
          IF (s[cp] IN ['0'..'9']) THEN
          BEGIN
            IF (s[cp-1] = '^') THEN
            BEGIN
              Dec(cp);
              WasColor := TRUE;
              set_color;
            END
            ELSE
            BEGIN
              j := 0;
              WHILE (s[cp-j] <> '|') AND (s[cp - j] IN ['0'..'9']) AND (j < cp) DO
              BEGIN
                Inc(j);
              END;
              IF (s[cp - j] = '|') THEN
              BEGIN
                 WasColor := TRUE;
                 Dec(cp,j);
                 set_color;
              END;
            END;
          END;
        END;
        IF (NOT WasColor) THEN
        BEGIN
          BackSpace;
          IF (trapping) THEN
            Write(TrapFile,^H' '^H);
        END;
      END;
    END;

  BEGIN { InputMain }
    origcolor := CurrentColor;
    os := s;
    s:='';
    ml := (253 - Length(MCI(lRGLngStr(191,TRUE))));
    checkhangup;
    IF (HangUp) THEN
      Exit;
    cp := 1;
    LastCheck := 0;
    repeat
      mlc := s;
      MultiNodeChat := TRUE;
      {
      IF (cp > 1) AND MultiNodeChat AND NOT ThisUser.TeleConfInt THEN
        MultiNodeChat := FALSE;
        }
      C := CHAR(GetKey);
      IF (Timer - LastCheck > 1) THEN
      BEGIN
        LoadNode(ThisNode);
        IF ((RoomNumber MOD 8) IN NodeR.Booted[RoomNumber DIV 8]) THEN
        BEGIN
          s := '';
          PrintMsg('^8You have been BANNED from the room.'^M^J);
          IF (RoomNumber = 1) THEN
            Done := TRUE
          ELSE
          BEGIN
            RemoveFromRoom(RoomNumber);
            RoomNumber := 1;
            AddToRoom(RoomNumber);
          END;
          Exit;
        END
      END;
      CASE c OF
        ^H : DoBackSpace;
        ^P : IF (cp < ml) THEN
             BEGIN
               c := CHAR(GetKey);
               IF (c IN ['0'..'9']) THEN
               BEGIN
                 UserColor(Ord(c)-48);
                 s[cp] := '^';
                 s[cp + 1] := c;
                 Inc(cp,2);
               END;
             END;
         #32..#123,#125..#255 :
             IF (cp <= ml) THEN
             BEGIN
               s[cp] := c;
               Inc(cp);
               outkey(c);
               IF (trapping) THEN
                 Write(TrapFile,c);
             END;
        '|' : IF (cp + 1 <= ml) THEN
              BEGIN
                cs := '';
                c := '0';
                cb := 0;
                WHILE (c IN ['0'..'9']) AND (cb < 2) DO
                BEGIN
                  c := CHAR(GetKey);
                  IF (c IN ['0'..'9']) THEN
                    cs := cs + c;
                  Inc(cb);
                END;
                cb := StrToInt(cs);
                CASE cb OF
                   0..15 : SetC(CurrentColor - (CurrentColor MOD 16) + cb);
                  16..23 : SetC(((cb - 16) * 16) + (CurrentColor MOD 16));
                END;
                IF NOT (c IN ['0'..'9']) THEN
                BEGIN
                  outkey(c);
                  IF (trapping) THEN
                    Write(TrapFile,c);
                  cs := cs + c;  {here was buf}
                END;
                s := s + '|' + cs;
                Inc(cp,Length(cs)+1);
              END
              ELSE IF (cp <= ml) THEN
              BEGIN
                s[cp] := c;
                Inc(cp);
                outkey(c);
                IF (trapping) THEN
                  Write(TrapFile,c);
              END;
        ^X : BEGIN
               WHILE (cp <> 1) DO
                 DoBackSpace;
                 SetC(origcolor);
               END;
      END;
      s[0] := Chr(cp - 1);
    until ((c = ^M) OR (c = ^N) OR (HangUp));
    mlc := '';
    Prompt(#27'[M'); { Delete line }
  END;

BEGIN { Teleconference }
  IF (NOT General.MultiNode) THEN
    BEGIN
      Print('This BBS is not currently operating in multi-node');
      Exit;
    END;
  IF (NOT OkANSI) THEN
    BEGIN
      Print('ANSI terminal emulation is required to use teleconferencing');
      Exit;
    END;

  Assign(ActionsFile,General.MiscPath+'ACTIONS.LST');
  Reset(ActionsFile);
  IF (IOResult = 2) THEN
    ReWrite(ActionsFile);
  Close(ActionsFile);

  Assign(RoomFile,General.DataPath+'ROOM.DAT');
  Reset(RoomFile);
  IF (IOResult = 2) THEN
    ReWrite(RoomFile);
  FillChar(Room,SizeOf(Room),0);
  Seek(RoomFile,FileSize(RoomFile));
  WHILE (FileSize(RoomFile) < 255) DO
    Write(RoomFile,Room);
  Close(RoomFile);

  IF (IOResult <> 0) THEN
    Exit;

  SaveTimeOut := General.TimeOut;
  General.TimeOut := -1;
  SaveTimeOutBell := General.TimeOutBell;
  General.TimeOutBell := -1;

  Kill(General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP');

  IF (General.MultiNode) THEN
    BEGIN
      LoadNode(ThisNode);
      NodeR.GroupChat := TRUE;
      SaveNode(ThisNode);
    END;

  mlc := '';
  RoomNumber := 1;
  NodeChatLastRec := 0;
  CLS;
  SysOpLog('Entered Teleconferencing');
  ToggleWindow(FALSE);
  PrintF('TELECONF');
  IF (NoFile) THEN
  Print('^0  Welcome to Teleconferencing.  Type ^5/?^0 for help or ^5/Q^0 to quit.');
    
    ANSIG(MCIPosRecArray[1].X,MCIPosRecArray[1].Y);
    OnLine := WhereY;
    
  AddToRoom(RoomNumber);
  
  Done := FALSE;

  { leew draw default bg here }
  
  ToggleWindow(TRUE);
  WHILE (NOT Done) AND (NOT HangUp) DO
    BEGIN
      TLeft;
      MultiNodeChat := TRUE;
      LoadNode(ThisNode);
      {CheckStatus;}
      (*WITH Room DO
        BEGIN
          ANSIG(MCIPosRecArray[3].X,MCIPosRecArray[3].Y); { Room number position }
          Prt(PadLeftInt(RoomNumber,3));
          ANSIG(MCIPosRecArray[4].X,MCIPosRecArray[4].Y); { Room topic position }
          Prt(PadLeftStr(Topic,40));
          
          s := '';
          j := 1;
          WHILE (J <= MaxNodes) DO
            BEGIN
              LoadNode(j);
              IF NodeR.User = Moderator THEN
                s := AllCaps(NodeR.UserName);
              Inc(j);
            END;  
          IF (s='') THEN
            s := 'None';
              
          LoadNode(ThisNode);
          NodeR.Room := RoomNumber;
          SaveNode(ThisNode);
          
          ANSIG(MCIPosRecArray[5].X,MCIPosRecArray[5].Y); { Room moderator position }
          Prt(PadLeftStr(s,36));
          s := '';
        END;*)
      (*ANSIG(1,23); *)
      ANSIG(MCIPosRecArray[0].X,MCIPosRecArray[0].Y); { LeeW: Go to input field }
      Clear_EOL; { LeeW: Clear input field }
      InputMain(s);
      {ANSIG(1,OnLine);}
      MultiNodeChat := FALSE;
      IF (HangUp) THEN
        s := '/Q';
      IF (NOT Done) AND (s <> '') AND (s[1] = '/') THEN
        BEGIN
          Cmd := UpCase(s[2]);
          s3 := AllCaps(Copy(s,2,255));
          IF (Pos(' ',s3) > 0) THEN
            BEGIN
              SaveName := Copy(s3,(Pos(' ',s3) + 1),255);
              s3 := Copy(s3,1,(Pos(' ',s3) - 1));
            END
          ELSE
            SaveName := '';
          s2 := SaveName;
          IF (SaveName <> '') THEN
            BEGIN
              i := Name2Number(s2,SaveName);
              IF (SaveName = '') THEN
                i := -1;
            END
          ELSE
            i := 0;
          Reset(ActionsFile);
          WHILE NOT EOF(ActionsFile) DO
            BEGIN
              ReadLn(ActionsFile,s2); { Action word }
              IF (AllCaps(s2) = s3) THEN
                BEGIN
                  ReadLn(ActionsFile,s2); { What sender sees }
                  s2 := MCI(s2);
                  Print('^0'+ActionMCI(s2));
                  ReadLn(ActionsFile,s2); { What everybody else sees }
                  IF (i = 0) THEN
                    ReadLn(ActionsFile,s2); { What everybody sees if no receiver }
                  s2 := MCI(s2);
                  s2 := '^0' + ActionMCI(s2);
                  WITH NodeR DO
                    FOR j := 1 TO MaxNodes DO
                      BEGIN
                        LoadNode(j);
                        IF (GroupChat) AND (Room = RoomNumber) AND
                           (j <> ThisNode) AND NOT ((ThisNode MOD 8) IN Forget[ThisNode DIV 8]) AND
                           (j <> i) THEN
                          LowLevelSend(s2,j);
                      END;
                  IF (i > 0) THEN
                    ReadLn(ActionsFile,s2);
                  ReadLn(ActionsFile,s2); { What receiver sees }
                  s2 := MCI(s2);
                  IF (i > 0) THEN
                    BEGIN
                      LoadNode(i);
                      IF (NodeR.GroupChat) AND (NodeR.Room = RoomNumber) AND
                         NOT ((ThisNode MOD 8) IN NodeR.Forget[ThisNode DIV 8]) THEN
                        LowLevelSend('^0'+ActionMCI(s2), i);
                    END;
                  s := '';
                  Break;
                END
              ELSE 
                FOR j := 1 TO 4 DO
                  ReadLn(ActionsFile,s2);
            END;
          Close(ActionsFile);
          IF (s <> '') THEN
            CASE Cmd OF
              'R' : IF (AllCaps(Copy(s,2,2)) = 'RA') THEN { Toggle anonymous mode }
                      BEGIN
                        IF (Room.Moderator = UserNum) OR (CoSysOp) THEN
                          BEGIN
                            LoadRoom(RoomNumber);
                            Room.Anonymous := NOT Room.Anonymous;
                            SaveRoom(RoomNumber);
                            SendMessage('^0 '#254' This room is now in ^1'+AOnOff(Room.Anonymous,
                                        'ANONYMOUS','REGULAR')+'^0 mode',TRUE);
                          END
                        ELSE
                          Nope(NotModerator);
                      END
                    ELSE IF (AllCaps(Copy(s,2,2)) = 'RP') AND (Length(s) = 3) THEN { Toggle room between private / public}
                      BEGIN
                        IF (Room.Moderator = UserNum) OR (CoSysOp) {AND (RoomNumber <> 1)} THEN
                          BEGIN
                            LoadRoom(RoomNumber);
                            Room.Private := NOT Room.Private;
                            SaveRoom(RoomNumber);
                            SendMessage('^0 '#254' This room is now ^1'+AOnOff(Room.Private,'PRIVATE','PUBLIC')+ 
                                        '^0',TRUE);
                          END
                        ELSE
                          Nope(NotModerator);
                      END
                    ELSE IF (AllCaps(Copy(s,2,8)) = 'REMEMBER') AND (AllCaps(Copy(s,10,1)) = ' ') THEN { Stop ignoring user}
                      BEGIN
                        s := Copy(s,(Pos(' ',s) + 1), 255);
                        i := Name2Number(s,SaveName);
                        IF (i > 0) AND (i <= MaxNodes) THEN
                          BEGIN
                            LoadNode(ThisNode);
                            NodeR.Forget[i DIV 8] := NodeR.Forget[i DIV 8] - [i MOD 8];
                            SaveNode(ThisNode);
                            PrintMsg('^0 '#254' You are no longer ignoring ^1'+AllCaps(SaveName)+'^0');
                          END
                        ELSE
                          Nope(NotOnLine);
                      END
                    ELSE
                      Nope(NotValid);
              'F' : IF (AllCaps(Copy(s,2,6)) = 'FORGET') AND (AllCaps(Copy(s,8,1)) = ' ') THEN { Ignore user }
                      BEGIN
                        s := Copy(s,9,(Length(s) - 8));
                        i := Name2Number(s,SaveName);
                        IF (i > 0) AND (i <= MaxNodes) THEN
                          BEGIN
                            LoadURec(User,NodeR.User);
                            IF (AACS1(User,NodeR.User,General.CSOp)) THEN
                              PrintMsg('^0 '#254' You can''t ignore ^1'+AllCaps(SaveName)+'^0, they''re a SysOp!')
                            ELSE
                              BEGIN
                                LoadNode(ThisNode);
                                NodeR.Forget[i DIV 8] := NodeR.Forget[i DIV 8] + [i MOD 8];
                                SaveNode(ThisNode);
                                PrintMsg('^0 '#254' You are now ignoring ^1'+AllCaps(SaveName)+'^0');
                              END;
                          END
                        ELSE
                          Nope(NotOnLine);
                        s := '';
                      END
                        ELSE
                          Nope(NotValid);
              'E' : IF (AllCaps(Copy(s,2,5)) = 'EJECT') THEN { Ban user from room }
                      BEGIN
                        IF (Room.Moderator = UserNum) OR (CoSysOp) THEN
                          BEGIN
                            s := Copy(s,(Pos(' ',s) + 1),Length(s));
                            i := Name2Number(s,SaveName);
                            IF (i > 0) AND (i <= MaxNodes) THEN
                              BEGIN
                                LoadNode(i);
                                IF (NodeR.GroupChat) AND (NodeR.Room = RoomNumber) THEN
                                  BEGIN
                                    LoadURec(User,NodeR.User);
                                    IF (AACS1(User,NodeR.User,General.CSOp)) THEN
                                      PrintMsg('^0 '#254' You cannot eject ^1'+AllCaps(NodeR.UserName)+'^0, they''re a SysOp!')
                                    ELSE
                                      BEGIN
                                        NodeR.Booted[RoomNumber DIV 8] := NodeR.Booted[RoomNumber DIV 8] + 
                                                                          [RoomNumber MOD 8];
                                        NodeR.Room := 1;
                                        SaveNode(i);
                                        SendMessage('^9 * ^1'+AllCaps(SaveName)+'^9 has just been ejected from the room by ^1'+
                                                    AllCaps(ThisUser.Name)+'^0',TRUE);
                                        SysOpLog('Ejected '+SaveName);
                                      END;
                                  END
                                    ELSE
                                      Nope(NotInRoom);
                              END
                                ELSE
                                  Nope(NotOnline);
                            s := '';
                          END
                        ELSE
                          Nope(NotModerator);
                      END;
              'G' : IF (AllCaps(s) = '/G') THEN { Logoff }
                      BEGIN
                        ANSIG(MCIPosRecArray[0].X,MCIPosRecArray[0].Y);
                        IF PYNQ('Are you sure you want to disconnect? ',39,FALSE) THEN
                          BEGIN
                            IF (NOT IsInvisible) THEN
                              SendMessage('^9 * '+Caps(ThisUser.Name)+' has logged off node '+
                                          IntToStr(ThisNode),FALSE);
                            HangUp := TRUE;
                          END;
                      END;

              'I' : IF (AllCaps(Copy(s,2,6)) = 'INVITE') THEN
                      BEGIN
                        s := Copy(s,9,(Length(s) - 3));
                        i := Name2Number(s,SaveName);
                        if roomnumber = 1 then
                        continue;
                        IF (i > 0) AND (i <= MaxNodes) THEN
                          BEGIN
                            LoadNode(i);
                            s := '^0 '#254' ^1'+AllCaps(ThisUser.Name)+'^0 has invited you to join conference room ^1#'
                                 +IntToStr(RoomNumber)+'^0';
                            NodeR.Invited[RoomNumber DIV 8] := NodeR.Invited[RoomNumber DIV 8] + [RoomNumber MOD 8];
                            NodeR.Booted[RoomNumber DIV 8] := NodeR.Booted[RoomNumber DIV 8] - [RoomNumber MOD 8];
                            PrintMsg('^0'+SaveName+' on node '+IntToStr(i)+' has been invited.');
                            SaveNode(i);
                            IF (i <> ThisNode) THEN
                              LowLevelSend(s,i);
                          END
                        ELSE
                          Nope(NotOnline);
                        s := '';
                        END;
              'J' : IF (S[3] <> ' ') OR (Copy(S,4,(Length(s) - 3)) = '') THEN { Join room }
                      Nope(NotValid)
                    ELSE
                      BEGIN
                        s := Copy(s,4,3);
                        i := StrToInt(s);
                        IF (i >= 1) AND (i <= 255) THEN
                          BEGIN
                            LoadNode(ThisNode);
                            IF ((i MOD 8) IN NodeR.Booted[i DIV 8]) THEN
                              BEGIN
                                PrintMsg('^8 '#254' You have been banned from that room!^0');
                              END
                            ELSE
                              BEGIN
                                LoadRoom(i);
                                IF (Room.Private) AND NOT (CoSysOp) AND NOT ((i MOD 8) IN NodeR.Invited[i DIV 8]) THEN
                                  BEGIN
                                    PrintMsg('^8 '#254' You must be invited to join a private conference room!');
                                    LoadRoom(RoomNumber);
                                  END
                                ELSE
                                  BEGIN
                                    RemoveFromRoom(RoomNumber);
                                    RoomNumber := i;
                                    AddToRoom(RoomNumber);
                                    SysOpLog('Joined room '+IntToStr(RoomNumber)+' '+Room.Topic);
                                  END;
                              END;
                          END
                        ELSE
                          Nope(NotRoom);
                        s := '';
                      END;
              'L' : PrintF('ACTIONS');
              'M' : IF (S[3] <> ' ') OR (Copy(S,4,(Length(s) - 3)) = '') THEN { Become moderator and set topic }
                      Nope(NotValid)
                    ELSE
                      BEGIN
                        IF (CoSysOp) OR (Room.Moderator = UserNum) OR ((Room.Moderator = 0) AND (RoomNumber <> 1)) THEN
                        { leew ^^fix this only sysops mod room 1}
                          BEGIN
                            s := Copy(S,4,40);
                            LoadRoom(RoomNumber);
                            Room.Topic := s;
                            IF (NOT IsInvisible) THEN
                              SendMessage('^0[ Conference "'+Room.Topic+'" is now moderated by '+
                              Caps(ThisUser.Name)+' ]',TRUE);
                            IF (Room.Moderator = 0) THEN
                              BEGIN
                                FOR i := 1 TO MaxNodes DO
                                  BEGIN
                                    LoadNode(i);
                                    NodeR.Invited[RoomNumber DIV 8] := NodeR.Invited[RoomNumber DIV 8] - [RoomNumber MOD 8];
                                    NodeR.Booted[RoomNumber DIV 8] := NodeR.Booted[RoomNumber DIV 8] - [RoomNumber MOD 8];
                                    SaveNode(i);
                                  END;
                              END;
                            Room.Moderator := UserNum;
                            SaveRoom(RoomNumber);
                          END
                        ELSE
                          Nope(NotModerator);
                        s := '';
                      END;
              'P' : IF (S[3] <> ' ') OR (Copy(s,4,(Length(s) - 3)) = '') THEN { Private Message }
                      Nope(NotValid)
                    ELSE
                      BEGIN
                        s := Copy(s,4,(Length(s) - 3));
                        i := Name2Number(s,SaveName);
                        IF (i > 0) AND (i <= MaxNodes) THEN
                          BEGIN
                            LoadNode(i);
                            IF ((ThisNode MOD 8) IN NodeR.Forget[ThisNode DIV 8]) THEN
                              PrintMsg('^8 '#254' That user is ignoring you!'{^M^J})
                            ELSE IF (i = ThisNode) THEN
                              PrintMsg('^8Talking to ourselves, are we?')
                            ELSE IF NOT (NAvail IN NodeR.Status) THEN
                              Nope(NotOnline)
                            ELSE IF NOT (NInvisible IN NodeR.Status) THEN
                              BEGIN
                                PrintMsg('^0 '#254' Private message "^1'+s+'^0" sent to ^1'+AllCaps(SaveName)+'^0');
                                IF AACS(General.TeleConfMCI) THEN
                                  s := MCI(s);
                                IF NodeR.GroupChat THEN
                                  s := MCI(lRGLngStr(194,TRUE)) + s
                                ELSE
                                  BEGIN
LowLevelSend({^M^J}'^0Message from ^1'+Caps(ThisUser.Name)+'^0 on node ^1'+IntToStr(ThisNode)+'^0:'{^M^J},{NodeNum}i);
                                  s := '[notinchat] '+s; {LeeW}
                                  END;
                                LowLevelSend(s,i)
                              END
                            ELSE
                              Nope(NotOnline);
                          END
                        ELSE
                          Nope(NotOnline);
                        s := '';
                      END;
              'Q' : BEGIN { Quit teleconference }
                      s := Copy(s,4,40);
                      IF (s <> '') THEN
                        IF (Room.Anonymous) THEN
                          s := MCI(lRGLngStr(192,TRUE)) + s
                        ELSE
                          s := MCI(lRGLngStr(191,TRUE)) + s;
                        (*s := {'^0'+}AllCaps(ThisUser.Name)+' '+s;*)
                      LoadNode(ThisNode);
                      SaveNode(ThisNode);
                      Done := TRUE;
                    END;
              'S' : IF (Copy(S,3,(Length(s) - 2)) <> '') THEN { Show users in all conference rooms }
                      Nope(NotValid)
                    ELSE
                      BEGIN
                        Abort := FALSE;
                        i := 1;
                        WHILE (i <= 255) AND (NOT Abort) DO
                          BEGIN
                            ShowRoom(i);
                            Inc(i);
                          END;
                        LoadRoom(RoomNumber);
                        s := '';
                      END;
              'U' : IF (Copy(S,3,(Length(s) - 2)) <> '') THEN { Show users in current conference room }
                      Nope(NotValid)
                    ELSE
                      BEGIN
                        ShowRoom(RoomNumber);
                        s := '';
                      END;
              'W' : ListNodes; { Show nodelist }
              '?' : PrintF('TELEHELP'); { Show teleconference help }
            END;
            {add invalid cmd message to / not found}
          IF (s[1] = '/') THEN
            s := '';
        END
      ELSE
        IF (s > #0) THEN
          BEGIN
            LoadRoom(RoomNumber);
              IF (Room.Anonymous) THEN
                s := MCI(lRGLngStr(192,TRUE)) + s
              ELSE
                s := MCI(lRGLngStr(191,TRUE)) + s;
          END
        ELSE
          s := '';
      IF (s <> '') THEN
        BEGIN
          MultiNodeChat := TRUE;
          IF (AACS(General.TeleConfMCI)) THEN
            s := MCI(s);
          SendMessage(s,TRUE);
        END;
    END;
  MultiNodeChat := FALSE;
  IF (General.MultiNode) THEN
    BEGIN
      LoadNode(ThisNode);
      NodeR.GroupChat := FALSE;
      SaveNode(ThisNode);
    END;
  RemoveFromRoom(RoomNumber);
  NodeChatLastRec := 0;
  Kill(General.TempPath+'MSG'+IntToStr(ThisNode)+'.TMP');
  General.TimeOut := SaveTimeOut;
  General.TimeOutBell := SaveTimeOutBell;
END;
END.