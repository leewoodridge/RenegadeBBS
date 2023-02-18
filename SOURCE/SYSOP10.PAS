{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 11/24/2021 - Added 2ND line of question to list
            - List aesthetics
 11/25/2021 - Changed list lengths, verify
}
UNIT SysOp10;

INTERFACE

PROCEDURE VotingEditor;

IMPLEMENTATION

USES
  Common,
  MiscUser,
  SysOp2; {ConfigHeader,HR}

PROCEDURE VotingEditor;
VAR
  TempTopic: VotingRecordType;
  Cmd: Char;
  RecNumToList: Byte;
  SaveTempPause: Boolean;

  PROCEDURE InitTopicVars(VAR Topic: VotingRecordType);
  VAR
    User: UserRecordType;
    Counter: Byte;
  BEGIN
    LoadURec(User,UserNum);
    FillChar(Topic,SizeOf(Topic),0);
    WITH Topic DO
      BEGIN
        Question1 := '<< New Voting Topic >>';
        Question2 := '';
        ACS := 'VV';
        ChoiceNumber := 0;
        NumVotedQuestion := 0;
        CreatedBy := Caps(User.Name);
        AddAnswersACS := General.AddChoice;
        FOR Counter := 1 TO MaxChoices DO
          WITH Answers[Counter] DO
            BEGIN
              Answer1 := '<< New Topic Choice >>';
              Answer2 := '';
              NumVotedAnswer := 0;
            END;
      END;
  END;

  PROCEDURE DeleteChoice(VAR Topic: VotingRecordType; RecNumToDelete: Byte; VAR Changed: Boolean);
  VAR
    User: UserRecordType;
    RecNum,
    RecNum1: Byte;
    UNum: Integer;
  BEGIN
    IF (Topic.ChoiceNumber < 1) THEN
      Messages(4,0,'topic choices')
    ELSE
    BEGIN
      RecNum := 0;
      InputByte('%LFDelete which choice',RecNum,[Numbersonly],1,Topic.ChoiceNumber,Changed);
      IF (RecNum >= 1) AND (RecNum <= Topic.ChoiceNumber) THEN
      BEGIN
        Dec(Topic.ChoiceNumber);
        Dec(Topic.NumVotedQuestion,Topic.Answers[RecNum].NumVotedAnswer);
        IF (RecNum < MaxChoices) THEN
          FOR RecNum1 := RecNum TO Topic.ChoiceNumber DO
          BEGIN
            Topic.Answers[RecNum1].Answer1 := Topic.Answers[RecNum1 + 1].Answer1;
            Topic.Answers[RecNum1].Answer2 := Topic.Answers[RecNum1 + 1].Answer2;
            Topic.Answers[RecNum1].NumVotedAnswer := Topic.Answers[RecNum1 + 1].NumVotedAnswer;
          END;
       Reset(UserFile);
       FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
       BEGIN
         Seek(UserFile,Unum);
         Read(UserFile,User);
         IF (User.Vote[RecNumToDelete] = RecNum) THEN
           User.Vote[RecNumToDelete] := 0
         ELSE IF (User.Vote[RecNumToDelete] > RecNum) THEN
           Dec(User.Vote[RecNumToDelete]);
         Seek(UserFile,UNum);
         Write(UserFile,User);
       END;
       Close(UserFile);
       IF (ThisUser.Vote[RecNumToDelete] = RecNum) THEN
         ThisUser.Vote[RecNumToDelete] := 0;
       Changed := TRUE;
      END;
    END;
  END;

  PROCEDURE InsertChoice(VAR Topic: VotingRecordType; RecNumToEdit: Byte; VAR Changed: Boolean);
  BEGIN
    IF (Topic.ChoiceNumber >= MaxChoices) THEN
      Messages(5,MaxChoices,'topic choices')
    ELSE IF PYNQ('%LFAdd topic choice #'+IntToStr(Topic.ChoiceNumber + 1)+'? ',0,FALSE) THEN
    BEGIN
      InputString('%LFChoice: ',Topic.Answers[Topic.ChoiceNumber + 1].Answer1,65,[InteractiveEdit],Changed);
      IF (Topic.Answers[Topic.ChoiceNumber + 1].Answer1 <> '') THEN
      BEGIN
        Topic.Answers[Topic.ChoiceNumber + 1].NumVotedAnswer := 0;
        InputString(PadLeftStr('',6)+': ',Topic.Answers[Topic.ChoiceNumber + 1].Answer2,65,[InteractiveEdit],Changed);
        Inc(Topic.ChoiceNumber);
      END;
      Changed := TRUE;
    END;
  END;

  PROCEDURE CheckChoice(Topic: VotingRecordType; RecNum1: Byte; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Topic.Answers[RecNum1].Answer1 = '') OR (Topic.Answers[RecNum1].Answer1 = '<< New Topic Choice >>') THEN
            BEGIN
              Print('%LF^8The answer is invalid!^0');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE ModifyChoice(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; RecNumToEdit: Byte; VAR Changed: Boolean);
  VAR
    Cmd1: Char;
    RecNum: Byte;
    Ok: Boolean;
  BEGIN
    IF (Topic.ChoiceNumber < 1) THEN
      Messages(4,0,'topic choices')
    ELSE
    BEGIN
      RecNum := 0;
      InputByte('%LFModify which choice',RecNum,[Numbersonly],1,Topic.ChoiceNumber,Changed);
      IF (RecNum >= 1) AND (RecNum <= Topic.ChoiceNumber) THEN
      BEGIN
        REPEAT
          IF (Cmd1 <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            Print('%CL^1Topic choice #'+IntToStr(RecNum)+' of '+IntToStr(Topic.ChoiceNumber));
            NL;
            PrintACR('^01. Choice: ^1'+Topic.Answers[RecNum].Answer1);
            IF (Topic.Answers[RecNum].Answer2 <> '') THEN
              PrintACR('^0         : ^1'+Topic.Answers[RecNum].Answer2);
            PrintACR('^02. Voters: ^1'+IntToStr(Topic.Answers[RecNum].NumVotedAnswer));
          END;
          InputChar('%LFModify menu [^1?^2=^1Help^2]: ',Cmd1,'Q12[]FJL?'^M,[CapAll]);
          CASE Cmd1 OF
            '1' : BEGIN
                    REPEAT
                      TempTopic1.Answers[RecNum].Answer1 := Topic.Answers[RecNum].Answer1;
                      Ok := TRUE;
                      InputString('%LFNew choice: ',Topic.Answers[RecNum].Answer1,
                                (SizeOf(Topic.Answers[RecNum].Answer1) - 1),[InteractiveEdit],Changed);
                      CheckChoice(Topic,RecNum,1,1,Ok);
                      IF (NOT Ok) THEN
                        Topic.Answers[RecNum].Answer1 := TempTopic1.Answers[RecNum].Answer1;
                    UNTIL (Ok) OR (HangUp);
                    IF (Topic.Answers[RecNum].Answer1 <> '') THEN
                      InputString(PadLeftStr('',10)+': ',Topic.Answers[Recnum].Answer2,
                                (SizeOf(Topic.Answers[RecNum].Answer2) - 1),[InteractiveEdit],Changed);
                  END;
            '2' : InputInteger('%LFNew number of voters',Topic.Answers[RecNum].NumVotedAnswer,
                               [InteractiveEdit,NumbersOnly],0,(MaxUsers - 1),Changed);
            '[' : IF (RecNum > 1) THEN
                    Dec(RecNum)
                  ELSE
                  BEGIN
                    Messages(2,0,'');
                    Cmd1 := #0;
                  END;
            ']' : IF (RecNum < Topic.ChoiceNumber) THEN
                    Inc(RecNum)
                  ELSE
                  BEGIN
                    Messages(3,0,'');
                    Cmd1 := #0;
                  END;
            'F' : IF (RecNum <> 1) THEN
                    RecNum := 1
                  ELSE
                  BEGIN
                    Messages(2,0,'');
                    Cmd1 := #0;
                  END;
            'J' : BEGIN
                    InputByte('%LFJump to entry',RecNum,[Numbersonly],1,Topic.ChoiceNumber,Changed);
                    IF (RecNum < 1) OR (RecNum > Topic.ChoiceNumber) THEN
                      Cmd1 := #0;
                  END;
            'L' : IF (RecNum <> Topic.ChoiceNumber) THEN
                    RecNum := Topic.ChoiceNumber
                  ELSE
                  BEGIN
                    Messages(3,0,'');
                    Cmd1 := #0;
                  END;
            '?' : BEGIN
                    Print('%LF^0<^1CR^0>Redisplay screen');
                    Print('^11-2^0:Modify item');
                    LCmds(20,1,'[Back entry',']Forward entry');
                    LCmds(20,1,'First entry in list','Jump to entry');
                    LCmds(20,1,'Last entry in list','Quit and save');
                  END;
          END;
        UNTIL (Cmd1 = 'Q') OR (HangUp);
      END;
    END;
  END;

  PROCEDURE ListChoices(VAR Topic: VotingRecordType; VAR RecNumToList1: Byte);
  VAR
    NumDone: Byte;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > Topic.ChoiceNumber) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    ConfigHeader('Voting Topic Choice Editor',0,0);
    PrintACR('^5<^4##^5> <^4Votes^5> <^4Choice^5>');
    HL;
    NumDone := 0;
    WHILE (NumDone < (PageLength - 7)/2) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= Topic.ChoiceNumber)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      PrintACR(' ^1'+PadLeftInt(RecNumToList1,4)+
               ' ^1'+PadLeftInt(Topic.Answers[RecNumToList1].NumVotedAnswer,7)+
               ' ^1'+PadLeftStr(Topic.Answers[RecNumToList1].Answer1,60));
      PrintACR(PadLeftStr('^1',14)+PadLeftStr(Topic.Answers[RecNumToList1].Answer2,60));

      WKey;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    IF (Topic.ChoiceNumber = 0) THEN
      Messages(4,0,'voting choices'); {Print('*** No voting choices defined ***');}
  END;

  PROCEDURE ChoiceEditor(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; Cmd1: Char;
                         RecNumToEdit: Byte; VAR Changed: Boolean);
  VAR
    RecNumToList1: Byte;
  BEGIN
    SaveTempPause := TempPause;
    TempPause := FALSE;
    RecNumToList1 := 1;
    Cmd1 := #0;
    REPEAT
      IF (Cmd1 <> '?') THEN
        ListChoices(Topic,RecNumToList1);
      InputChar('%LFTopic choice editor [^1?^2=^1Help^2]: ',Cmd1,'QDIM?'^M,[CapAll]);
      CASE Cmd1 OF
        ^M  : IF (RecNumToList1 < 1) OR (RecNumToList1 > Topic.ChoiceNumber) THEN
                RecNumToList1 := 1;
        'D' : DeleteChoice(Topic,RecNumToEdit,Changed);
        'I' : InsertChoice(Topic,RecNumToEdit,Changed);
        'M' : ModifyChoice(TempTopic1,Topic,RecNumToEdit,Changed);
        '?' : BEGIN
                Print('%LF^0<^1CR^0>Next screen or redisplay current screen');
                Print('^0(^1?^0)Help/First topic choice');
                LCmds(20,1,'Delete topic choice','Insert topic choice');
                LCmds(20,1,'Modify topic choice','Quit');
              END;
      END;
      IF (Cmd1 <> ^M) THEN
        RecNumToList1 := 1;
    UNTIL (Cmd1 = 'Q') OR (HangUp);
    TempPause := SaveTempPause;
  END;

  PROCEDURE DeleteTopic(TempTopic1: VotingRecordType; RecNumToDelete: Byte);
  VAR
    User: UserRecordType;
    RecNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToDelete := 0;
      InputByte('%LFVoting topic to delete',RecNumToDelete,[NumbersOnly],1,NumVotes,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumVotes) THEN
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNumToDelete - 1));
        Read(VotingFile,TempTopic1);
        Close(VotingFile);
        LastError := IOResult;
        Print('%LF^0Voting topic: ^1'+TempTopic1.Question1);
        IF (TempTopic1.Question2 <> '') THEN
          Print('^0'+PadLeftStr('',12)+': ^1'+TempTopic1.Question2);
        IF PYNQ('%LFAre you sure you want to delete it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Deleting voting topic record ...');
          Dec(RecNumToDelete);
          Reset(VotingFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(VotingFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(VotingFile) - 2) DO
            BEGIN
              Seek(VotingFile,(RecNum + 1));
              Read(VotingFile,Topic);
              Seek(VotingFile,RecNum);
              Write(VotingFile,Topic);
            END;
          Seek(VotingFile,(FileSize(VotingFile) - 1));
          Truncate(VotingFile);
          Close(VotingFile);
          LastError := IOResult;
          SysOpLog('* Deleted topic: ^1'+TempTopic1.Question1);
          IF (Topic.Question2 <> '') THEN
            SysOpLog(PadLeftStr('',15)+': ^1'+TempTopic1.Question2);
          Reset(UserFile);
          FOR RecNum := 1 TO (FileSize(UserFile) - 1) DO
          BEGIN
            Seek(UserFile,RecNum);
            Read(UserFile,User);
            Move(User.Vote[RecNumToDelete + 1],User.Vote[RecNumToDelete],(MaxVotes - RecNumToDelete));
            User.Vote[25] := 0;
            Seek(UserFile,RecNum);
            Write(UserFile,User);
          END;
          Close(UserFile);
          LastError := IOResult;
          Move(ThisUser.Vote[RecNumToDelete + 1],ThisUser.Vote[RecNumToDelete],(MaxVotes - RecNumToDelete));
          ThisUser.Vote[25] := 0;
          Dec(NumVotes);
        END;
      END;
    END;
  END;

  PROCEDURE CheckTopic(Topic: VotingRecordType; StartErrMsg,EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter,
    Counter1: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (Topic.Question1 = '') OR (Topic.Question1 = '<< New Voting Topic >>') THEN
            BEGIN
              Print('%LF^8The question is invalid!^0');
              OK := FALSE;
            END;
        2 : IF (Topic.ChoiceNumber = 0) THEN
            BEGIN
              Print('%LF^8You must setup choices for your topic!^0');
              OK := FALSE;
            END;
      END;
  END;

  PROCEDURE EditTopic(TempTopic1: VotingRecordType; VAR Topic: VotingRecordType; VAR Cmd1: Char;
                      VAR RecNumToEdit: Byte; VAR Changed: Boolean; Editing: Boolean);
  VAR
    User: UserRecordType;
    CmdStr: AStr;
    Unum: Integer;
    Ok: Boolean;
  BEGIN
    WITH Topic DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          {CLS;}
          IF (Editing) THEN
            ConfigHeader('^1Editing Voting Topic #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumVotes),0,0)

          ELSE
            ConfigHeader('^1Inserting Voting Topic #'+IntToStr(RecNumToEdit)+' Of '+IntToStr(NumVotes + 1),0,0);
          {NL;}
          PrintACR('^0(^11^0) Topic       : ^1'+Question1);
          IF (Question2 <> '') THEN
            PrintACR('^0'+PadLeftStr('',16)+': ^1'+Question2);
          PrintACR('^0(^12^0) Author      : ^1'+CreatedBy);
          PrintACR('^0(^13^0) ACS To Vote : ^1'+AOnOff(ACS = '','*None*',ACS));
          PrintACR('^0(^14^0) ACS To Add  : ^1'+AOnOff(AddAnswersACS = '','*None*',AddAnswersACS));
          PrintACR('^0(^15^0) Total Votes : ^1'+IntToStr(NumVotedQuestion));
          NL;
          PrintACR('^0 - This topic has ^1'+IntToStr(ChoiceNumber)+'^0 '+Plural('choice',ChoiceNumber));
        END;
        IF (NOT Editing) THEN
          CmdStr := '12345C'
        ELSE
          CmdStr := '12345C[]FJL';
        InputChar('%LFModify menu [^1C^2=^1Choice Editor^2,^1?^2=^1Help^2]: ',Cmd1,'Q?'+CmdStr+^M,[CapAll]);
        CASE Cmd1 OF
          '1' : BEGIN
                  REPEAT
                    TempTopic1.Question1 := Question1;
                    Ok := TRUE;
                    InputString('%LFNew topic: ',Question1,(SizeOf(Question1) - 1),[InteractiveEdit],Changed);
                    CheckTopic(Topic,1,1,Ok);
                    IF (NOT Ok) THEN
                      Question1 := TempTopic1.Question1;
                  UNTIL (Ok) OR (HangUp);
                  IF (Question1 <> '') THEN
                    InputString(PadLeftStr('',9)+': ',Question2,(SizeOf(Question2) - 1),[InteractiveEdit],Changed);
                END;
          '2' : BEGIN
                  Print('%LFWho is the new author of this voting topic?');
                  LFindUserWS(UNum);
                  IF (Unum < 1) THEN
                    PauseScr(FALSE)
                  ELSE
                  BEGIN
                    LoadURec(User,UNum);
                    IF (CreatedBy <> Caps(User.Name)) THEN
                      IF (PYNQ('%LFSet the new creator name to '+Caps(User.Name)+'? ',0,FALSE)) THEN
                      BEGIN
                        CreatedBy := Caps(User.Name);
                        Changed := TRUE;
                      END;
                  END;
                END;
          '3' : InputString('%LFNew voting ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '4' : IF PYNQ('%LFAllow other users to add choices? ',0,FALSE) THEN
                  AddAnswersACS := ACS
                ELSE
                  AddAnswersACS := General.AddChoice;
          '5' : InputInteger('%LFNew number of voters',NumVotedQuestion,
          [InteractiveEdit{,DisplayValue},NumbersOnly],0,(MaxUsers - 1),Changed);
          'C' : ChoiceEditor(TempTopic1,Topic,Cmd1,RecNumToEdit,Changed);
          '[' : IF (RecNumToEdit > 1) THEN
                  Dec(RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,'');
                  Cmd1 := #0;
                END;
          ']' : IF (RecNumToEdit < NumVotes) THEN
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
                  InputByte('%LFJump to entry',RecNumToEdit,[NumbersOnly],1,NumVotes,Changed);
                  IF (RecNumToEdit < 1) OR (RecNumToEdit > NumVotes) THEN
                    Cmd1 := #0;
                END;
          'L' : IF (RecNumToEdit <> NumVotes) THEN
                  RecNumToEdit := NumVotes
                ELSE
                BEGIN
                  Messages(3,0,'');
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  Print('%LF^0<^1CR^0>Redisplay current screen');
                  Print('^11^0-^15^0,^1C^0:Modify item');
                  IF (NOT Editing) THEN
                    LCmds(20,1,'Quit and save','')
                  ELSE
                  BEGIN
                    LCmds(20,1,'[Back entry',']Forward entry');
                    LCmds(20,1,'First entry in list','Jump to entry');
                    LCmds(20,1,'Last entry in list','Quit and save');
                  END;
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]FJL') <> 0) OR (HangUp);
  END;

  PROCEDURE InsertTopic(TempTopic1: VotingRecordType; Cmd1: Char; RecNumToInsertBefore: Byte);
  VAR
    RecNumToEdit: Byte;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumVotes = MaxVotes) THEN
      Messages(5,MaxVotes,'voting topics')
    ELSE IF (PYNQ('%LFAdd voting topic #'+IntToStr(NumVotes + 1)+'? ',0,FALSE)) THEN
    BEGIN
      Reset(VotingFile);
      InitTopicVars(TempTopic1);
      RecNumToInsertBefore := (FileSize(VotingFile) + 1);
      IF (RecNumToInsertBefore = 1) THEN
        RecNumToedit := 1
      ELSE IF (RecNumToInsertBefore = (NumVotes + 1)) THEN
        RecNumToEdit := (NumVotes + 1)
      ELSE
        RecNumToEdit := RecNumToInsertBefore;
      REPEAT
        OK := TRUE;
        EditTopic(TempTopic1,TempTopic1,Cmd1,RecNumToEdit,Changed,FALSE);
        CheckTopic(TempTopic1,1,2,Ok);
        IF (NOT OK) THEN
          IF (NOT PYNQ('%LFContinue inserting topic? ',0,TRUE)) THEN
            Abort := TRUE;
      UNTIL (OK) OR (Abort) OR (HangUp);
      IF (NOT Abort) AND (PYNQ('%LFIs this what you want? ',0,FALSE)) THEN
      BEGIN
        Print('%LF[> Inserting voting topic record ...');
        Seek(VotingFile,FileSize(VotingFile));
        Write(VotingFile,TempTopic1);
        Close(VotingFile);
        LastError := IOResult;
        Inc(NumVotes);
        SysOpLog('* Inserted topic: ^1'+TempTopic1.Question1);
        IF (TempTopic1.Question2 <> '') THEN
          SysOpLog(PadLeftStr('',16)+': ^1'+TempTopic1.Question2);
      END;
    END;
  END;

  PROCEDURE ModifyTopic(TempTopic1: VotingRecordType; Cmd1: Char; RecNumToEdit: Byte);
  VAR
    SaveRecNumToEdit: Byte;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToEdit := 0;
      InputByte('%LFModify which topic',RecNumToEdit,[NumbersOnly],1,NumVotes,Changed);
      IF (RecNumToEdit >= 1) AND (RecNumToEdit <= NumVotes) THEN
      BEGIN
        SaveRecNumToEdit := 0;
        Cmd1 := #0;
        Reset(VotingFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> RecNumToEdit) THEN
          BEGIN
            Seek(VotingFile,(RecNumToEdit - 1));
            Read(VotingFile,Topic);
            SaveRecNumToEdit := RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditTopic(TempTopic1,Topic,Cmd1,RecNumToEdit,Changed,TRUE);
            CheckTopic(Topic,1,2,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (RecNumToEdit <> SaveRecNumToEdit) THEN
                RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (Ok) OR (HangUp);
          IF (Changed) THEN
          BEGIN
            Seek(VotingFile,(SaveRecNumToEdit - 1));
            Write(VotingFile,Topic);
            Changed := FALSE;
            SysOpLog('* Modified topic: ^1'+Topic.Question1);
            IF (Topic.Question2 <> '') THEN
              SysOpLog(PadLeftStr('',16)+': ^1'+Topic.Question2);
          END;
        END;
        Close(VotingFile);
        LastError := IOResult;
      END;
    END;
  END;

  PROCEDURE ResetTopic(RecNumToReset: Byte);
  VAR
    User: UserRecordType;
    RecNum: Byte;
    UNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE
    BEGIN
      RecNumToReset := 0;
      InputByte('%LFReset which topic',RecNumToReset,[NumbersOnly],1,NumVotes,Changed);
      IF (RecNumToReset >= 1) AND (RecNumToReset <= NumVotes) THEN
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNumToReset - 1));
        Read(VotingFile,Topic);
        Close(VotingFile);
        Print('%LF^0Voting topic: ^1'+Topic.Question1);
        IF (Topic.Question2 <> '') THEN
          Print('^0'+PadLeftStr('',12)+': ^1'+Topic.Question2);
        IF PYNQ('%LFAre you sure you want to reset it? ',0,FALSE) THEN
        BEGIN
          Print('%LF[> Resetting voting topic record ...');
          Reset(VotingFile);
          Seek(VotingFile,(RecNumToReset - 1));
          Read(VotingFile,Topic);
          Topic.NumVotedQuestion := 0;
          FOR RecNum := 1 TO Topic.ChoiceNumber DO
            Topic.Answers[RecNum].NumVotedAnswer := 0;
          Seek(VotingFile,(RecNumToReset - 1));
          Write(VotingFile,Topic);
          Close(VotingFile);
          Reset(UserFile);
          FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
          BEGIN
            Seek(UserFile,Unum);
            Read(UserFile,User);
            User.Vote[RecNumToReset] := 0;
            Seek(UserFile,UNum);
            Write(UserFile,User);
         END;
         Close(UserFile);
         ThisUser.Vote[RecNumToReset] := 0;
         SysOpLog('* Reset topic: ^1'+Topic.Question1);
         IF (Topic.Question2 <> '') THEN
           SysOpLog(PadLeftStr('',13)+': ^1'+Topic.Question2);
       END;
      END;
    END;
  END;

  PROCEDURE RecalculateTopics;
  VAR
    User: UserRecordType;
    RecNum,
    RecNum1: Byte;
    UNum: Integer;
  BEGIN
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics')
    ELSE IF (PYNQ('%LFRecalculate all voting topics? ',0,FALSE)) THEN
    BEGIN
      Print('%LF[> Recalculating all voting topics ...');
      Reset(VotingFile);
      FOR RecNum := 1 TO NumVotes DO
      BEGIN
        Reset(VotingFile);
        Seek(VotingFile,(RecNum - 1));
        Read(VotingFile,Topic);
        Topic.NumVotedQuestion := 0;
        FOR RecNum1 := 1 TO Topic.ChoiceNumber DO
          Topic.Answers[RecNum1].NumVotedAnswer := 0;
        Seek(VotingFile,(RecNum - 1));
        Write(VotingFile,Topic);
      END;
      Close(VotingFile);
      Reset(VotingFile);
      Reset(UserFile);
      FOR UNum := 1 TO (FileSize(UserFile) - 1) DO
      BEGIN
        Seek(UserFile,Unum);
        Read(UserFile,User);
        IF (Deleted IN User.SFlags) THEN
        BEGIN
          FOR RecNum := 1 TO MaxVotes DO
            User.Vote[RecNum] := 0;
        END
        ELSE
        BEGIN
          FOR RecNum := 1 TO NumVotes DO
            IF (User.Vote[RecNum] <> 0) THEN
            BEGIN
              Seek(VotingFile,(RecNum - 1));
              Read(VotingFile,Topic);
              Inc(Topic.NumVotedQuestion);
              Inc(Topic.Answers[User.Vote[RecNum]].NumVotedAnswer);
              Seek(VotingFile,(RecNum - 1));
              Write(VotingFile,Topic);
            END;
        END;
        Seek(UserFile,Unum);
        Write(UserFile,User);
      END;
      Close(UserFile);
      Close(VotingFile);
      SysOpLog('* Recalculated all voting topics.');
    END;
  END;

  PROCEDURE ListTopics(VAR RecNumToList1: Byte);
  VAR
    NumDone: Byte;
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumVotes) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    ConfigHeader('Voting Topic Editor',0,0);
    PrintACR('^5<^4##^5> <^4Votes^5> <^4Topic^5>');
    HL;
    Reset(VotingFile);
    NumDone := 0;
    WHILE (NumDone < (PageLength - 7)) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumVotes)
          AND (NOT Abort) AND (NOT HangUp) DO
    BEGIN
      Seek(VotingFile,(RecNumToList1 - 1));
      Read(VotingFile,Topic);
      WITH Topic DO
        BEGIN
          PrintACR('^1 '+PadLeftInt(RecNumToList1,4)+
                   '^1 '+PadLeftInt(NumVotedQuestion,7)+
                   '^1 '+PadLeftStr(Question1,60));
          IF (Question2 <> '') THEN
            BEGIN
              PrintACR(PadLeftStr('^1',14)+PadLeftStr(Question2,60));
              Inc(NumDone); { Adds 1 line }
            END;
        END;
      WKey;
      Inc(RecNumToList1);
      Inc(NumDone);
    END;
    Close(VotingFile);
    LastError := IOResult;
    IF (NumVotes = 0) THEN
      Messages(4,0,'voting topics'); {Print('*** No voting topics defined ***');}
  END;

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListTopics(RecNumToList);
    InputChar('%LFVoting topic editor [^1?^2=^1Help^2]: ',Cmd,'QDIMRS?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumVotes) THEN
              RecNumToList := 1;
      'D' : DeleteTopic(TempTopic,RecNumToList);
      'I' : InsertTopic(TempTopic,Cmd,RecNumToList);
      'M' : ModifyTopic(TempTopic,Cmd,RecNumToList);
      'R' : ResetTopic(RecNumToList);
      'S' : RecalculateTopics;
      '?' : BEGIN
              NL;
              Print('^0<^1CR^0>Next Page/Refresh');
              Print('^0(^1?^0)Help/First Voting Topic');
              LCmds(20,1,'Delete Voting Topic','Insert Voting Topic');
              LCmds(20,1,'Modify Voting Topic','Quit');
              LCmds(20,1,'Reset Voting Topic','SRecalculate Voting Topics');
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  LastError := IOResult;
END;

END.
