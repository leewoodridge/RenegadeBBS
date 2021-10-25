{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2M;

INTERFACE

PROCEDURE NewUserTogglesConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE NewUserTogglesConfiguration;
VAR
  TempStr: STRING[70];
  Cmd: CHAR;
  TempB: BYTE;
  Changed: Boolean;

  FUNCTION Toggle(NUToggle,CUSerNum: BYTE): BYTE;
  BEGIN
    IF (NUToggle = 0) THEN
      Toggle := CUserNum
    ELSE
      Toggle := 0;
  END;

BEGIN
  REPEAT
    CLS;
    Abort := FALSE;
    Next := FALSE;
    MCIAllowed := FALSE;
    WITH General DO
    BEGIN
      Print('^1New User Question Toggles Configuration:');
      NL;
      NewUserToggles[1] := 7;
      PrintACR('^0A. Ask what the REAL NAME is           : ^1'+ShowYesNo(NewUserToggles[2] <> 0));
      PrintACR('^0B. Ask which COUNTRY from              : ^1'+ShowYesNo(NewUserToggles[3] <> 0));
      PrintACR('^0C. Ask what the ADDRESS is             : ^1'+ShowYesNo(NewUserToggles[4] <> 0));
      PrintACR('^0D. Ask what the CITY, STATE is         : ^1'+ShowYesNo(NewUserToggles[5] <> 0));
      PrintACR('^0E. Ask what the ZIP CODE is            : ^1'+ShowYesNo(NewUserToggles[6] <> 0));
      PrintACR('^0F. Ask what the PHONE NUMBER is        : ^1'+ShowYesNo(NewUserToggles[7] <> 0));
      PrintACR('^0G. Ask which Gender (Male/Female)      : ^1'+ShowYesNo(NewUserToggles[8] <> 0));
      PrintACR('^0H. Ask what the BIRTHDAY is            : ^1'+ShowYesNo(NewUserToggles[9] <> 0));
      PrintACR('^0I. Ask SysOp Question #1               : ^1'+ShowYesNo(NewUserToggles[10] <> 0));
      PrintACR('^0J. Ask SysOp Question #2               : ^1'+ShowYesNo(NewUserToggles[11] <> 0));
      PrintACR('^0K. Ask SysOp Question #3               : ^1'+ShowYesNo(NewUserToggles[12] <> 0));
      PrintACR('^0L. Ask EMULATION that is required      : ^1'+ShowYesNo(NewUserToggles[13] <> 0));
      PrintACR('^0M. Ask SCREEN SIZE that is required    : ^1'+ShowYesNo(NewUserToggles[14] <> 0));
      PrintACR('^0N. Ask if Msg SCREEN CLEARING is needed: ^1'+ShowYesNo(NewUserToggles[15] <> 0));
      PrintACR('^0O. Ask if SCREEN PAUSES are needed     : ^1'+ShowYesNo(NewUserToggles[16] <> 0));
      PrintACR('^0P. Ask if HOTKEYS are needed           : ^1'+ShowYesNo(NewUserToggles[17] <> 0));
      PrintACR('^0R. Ask if EXPERT MODE is needed        : ^1'+ShowYesNo(NewUserToggles[18] <> 0));
      NewUserToggles[19] := 9;
      PrintACR('^0S. Ask FORGOT PW question              : ^1'+ShowYesNo(NewUserToggles[20] <> 0));
      IF (ForgotPWQuestion <> '') THEN
        PrintACR('^0   ('+ForgotPWQuestion+')');
    END;
    MCIAllowed := TRUE;
    Prt('%LFEnter selection [^1A^2-^1P^2,^1R^2-^1S^2,^1Q^2=^1Quit^2]: ');
    OneK(Cmd,'QABCDEFGHIJKLMNOPRS'^M,TRUE,TRUE);
    WITH General DO
      CASE Cmd OF
        'A' : NewUserToggles[2] := Toggle(NewUserToggles[2],10);
        'B' : NewUserToggles[3] := Toggle(NewUserToggles[3],23);
        'C' : NewUserToggles[4] := Toggle(NewUserToggles[4],1);
        'D' : NewUserToggles[5] := Toggle(NewUserToggles[5],4);
        'E' : NewUserToggles[6] := Toggle(NewUserToggles[6],14);
        'F' : BEGIN
                NewUserToggles[7] := Toggle(NewUserToggles[7],8);
                IF (NewUserToggles[7] <> 0) THEN
                  General.PhonePW := TRUE
                ELSE
                  General.PhonePW := FALSE;
             END;
       'G' : NewUserToggles[8] := Toggle(NewUserToggles[8],12);
       'H' : BEGIN
               NewUserToggles[9] := Toggle(NewUserToggles[9],2);
               (*
               IF (NewUserToggles[9] = 0) THEN
                 General.BirthDateCheck := 0
               ELSE
               BEGIN
                 REPEAT
                   NL;
                   Prt('Logins before birthday check (0-255): ');
                   Ini(TempB);
                   IF (TempB < 0) OR (TempB > 255) THEN
                   BEGIN
                     NL;
                     Print('Invalid Range!');
                     PauseScr(FALSE);
                   END;
                 UNTIL (TempB >= 0) AND (TempB <= 255) OR (HangUp);
                 General.BirthDateCheck := TempB;
               END;
               *)
             END;
       'I' : NewUserToggles[10] := Toggle(NewUserToggles[10],5);
       'J' : NewUserToggles[11] := Toggle(NewUserToggles[11],6);
       'K' : NewUserToggles[12] := Toggle(NewUserToggles[12],13);
       'L' : NewUserToggles[13] := Toggle(NewUserToggles[13],3);
       'M' : NewUserToggles[14] := Toggle(NewUserToggles[14],11);
       'N' : NewUserToggles[15] := Toggle(NewUserToggles[15],29);
       'O' : NewUserToggles[16] := Toggle(NewUserToggles[16],24);
       'P' : NewUserToggles[17] := Toggle(NewUserToggles[17],25);
       'R' : NewUserToggles[18] := Toggle(NewUserToggles[18],28);
       'S' : BEGIN
               NewUserToggles[20] := Toggle(NewUserToggles[20],30);
               IF (NewUserToggles[20] = 0) THEN
                 ForgotPWQuestion := ''
               ELSE
               BEGIN
                 TempStr := General.ForgotPWQuestion;
                 REPEAT
                   InputWN1('%LFEnter question to ask user if they forget thier password:%LF: ',TempStr,70,
                            [InterActiveEdit],Changed);
                 UNTIL (TempStr <> '') OR (HangUp);
                 IF (Changed) THEN
                   ForgotPWQuestion := TempStr;
               END;
             END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
