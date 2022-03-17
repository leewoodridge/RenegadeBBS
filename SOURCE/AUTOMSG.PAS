{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 10/07/2021 - Indented
            - AUTO.ASC renamed to AUTOM.ASC to keep with standard filenaming convention
            - Now uses AUTOH.EXT/AUTOT.EXT, if available
            - All strings in RGLNG
 11/10/2021 - added hangup checks to loops to prevent lockups
}
UNIT AutoMsg;

INTERFACE

PROCEDURE ReadAutoMsg;
PROCEDURE WriteAutoMsg;
PROCEDURE ReplyAutoMsg;

IMPLEMENTATION

USES
  CRT,
  DOS,
  Common,
  EMail,
  Mail0,
  Mail1,
  TimeFunc;

PROCEDURE ReadAutoMsg;
VAR
  AutoMsgFile: Text;
  TempAuthor: STRING[65];
  TempStr: AStr;
  Counter: Byte;
  DatePacked: LongInt;
  DateUnPacked: DateTime;
BEGIN
  Assign(AutoMsgFile,General.MiscPath+'AUTOM.ASC');
  Reset(AutoMsgFile);
  IF (IOResult <> 0) THEN
    lRGLngStr(98,FALSE) {"There's no auto-message"}
  ELSE
    BEGIN
      ReadLn(AutoMsgFile,TempAuthor);
      CASE TempAuthor[1] OF
        '@' : IF (AACS(General.AnonPubRead)) THEN
                TempAuthor := Copy(TempAuthor,2,Length(TempAuthor))+' '+lRGLngStr(99,TRUE) {"Posted Anonymously"}
              ELSE
                TempAuthor := lRGLngStr(0,TRUE); {"Anonymous"}
        '!' : IF (CoSysOp) THEN
                TempAuthor := Copy(TempAuthor,2,Length(TempAuthor))+' '+lRGLngStr(99,TRUE)
              ELSE
                TempAuthor := lRGLngStr(0,TRUE);
      END;
      Reset(AutoMsgFile);
      ReadLn(AutoMsgFile,TempStr);
      PrintF('AUTOH');
      IF (NoFile) THEN
        BEGIN
          lRGLngStr(104,FALSE); { Auto-Message header }
          UserColor(5);
          WHILE WhereX < ThisUser.LineLen DO
            Prompt(lRGLngStr(11,TRUE)); {"-"}
          NL;
          UserColor(0);
        END;
      REPEAT
        ReadLn(AutoMsgFile,TempStr);
        PrintACR('^1'+TempStr);
      UNTIL EOF(AutoMsgFile) OR (Abort) OR (HangUp);
      Close(AutoMsgFile);
      TempStr := lRGLngStr(10,TRUE);
      TempStr := Substitute(TempStr,'@U',TempAuthor); { Add username }
      GetFileDateTime(General.MiscPath+'AUTOM.ASC',DatePacked);
      UnPackTime(DatePacked,DateUnpacked);
      WITH DateUnpacked DO
        TempStr := Substitute(TempStr,'@D',IntToStr(Month)+'/'+IntToStr(Day)+'/'+IntToStr(Year)); { Add date }
      Print(TempStr); {" ─ Posted by [USERNAME] on [DATE]"}
      PrintF('AUTOT');
      IF (NoFile) THEN
        BEGIN
          UserColor(5);
          WHILE WhereX < ThisUser.LineLen DO
            Prompt(lRGLngStr(11,TRUE)); {"-"}
          NL;
          UserColor(0);
        END;
    END;
  SysOpLog('Read Auto-Message');
  PauseScr(FALSE);
  LastError := IOResult;
END;

PROCEDURE WriteAutoMsg;
VAR
  AutoMsgFile1,
  AutoMsgFile2: Text;
  MHeader: MHeaderRec;
  TempStr: AStr;
BEGIN
  IF (RAMsg IN ThisUser.ACFlags) THEN
    lRGLngStr(100,FALSE) {"You are restricted from writing auto-messages"}
  ELSE
    BEGIN
      InResponseTo := '';
      MHeader.Status := [];
      IF (InputMessage(TRUE,FALSE,'Auto-Message',MHeader,General.MiscPath+'AUTO'+IntToStr(ThisNode)+'.TMP',78,500)) THEN
        IF Exist(General.MiscPath+'AUTO'+IntToStr(ThisNode)+'.TMP') THEN
          BEGIN
            Assign(AutoMsgFile1,General.MiscPath+'AUTOM.ASC');
            ReWrite(AutoMsgFile1);
            Assign(AutoMsgFile2,General.MiscPath+'AUTO'+IntToStr(ThisNode)+'.TMP');
            Reset(AutoMsgFile2);
            IF (IOResult <> 0) THEN
              Exit;
            IF (AACS(General.AnonPubPost)) AND PYNQ(lRGLngStr(101,TRUE),0,FALSE) THEN {"Post anonymously?"}
              IF (CoSysOp) THEN
                WriteLn(AutoMsgFile1,'!'+Caps(ThisUser.Name))
              ELSE
                WriteLn(AutoMsgFile1,'@'+Caps(ThisUser.Name))
            ELSE
              WriteLn(AutoMsgFile1,Caps(ThisUser.Name));
            WHILE (NOT EOF(AutoMsgFile2)) DO
              BEGIN
                ReadLn(AutoMsgFile2,TempStr);
                WriteLn(AutoMsgFile1,TempStr);
              END;
            Close(AutoMsgFile1);
            Close(AutoMsgFile2);
            Kill(General.MiscPath+'AUTO'+IntToStr(ThisNode)+'.TMP');
          END;
    END;
  SysOpLog('Wrote Auto-Message');
END;

PROCEDURE ReplyAutoMsg;
VAR
  AutoMsgFile: Text;
  MHeader: MHeaderRec;
  TempStr: AStr;
BEGIN
  Assign(AutoMsgFile,General.MiscPath+'AUTOM.ASC');
  Reset(AutoMsgFile);
  IF (IOResult <> 0) THEN
    BEGIN
      lRGLngStr(102,FALSE); {"There is no auto-message to reply to!"}
      PauseScr(FALSE);
    END
  ELSE
    BEGIN
      ReadLn(AutoMsgFile,TempStr);
      Close(AutoMsgFile);
      IF (TempStr[1] IN ['!','@']) THEN
        BEGIN
          LastAuthor := SearchUser(Copy(TempStr,2,Length(TempStr)),CoSysOp);
          IF (NOT AACS(General.AnonPubRead)) THEN {LeeW: This was anonprivread}
            LastAuthor := 0;
        END
      ELSE
        LastAuthor := SearchUser(TempStr,CoSysOp);
      IF (LastAuthor = 0) THEN
        lRGLngStr(103,FALSE) {"You can't reply to an anonymous message!"}
      ELSE
        BEGIN
          InResponseTo := 'Your auto-message';
          MHeader.Status := [];
          AutoReply(MHeader);
          SysOpLog('Replied To Auto-Message'); {LeeW: Can we check to be sure they didn't abort?}
        END;
    END;
END;
END.