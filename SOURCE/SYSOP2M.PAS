{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{     (                                         }
{    )\ )                           (           }
{   (()/(  (         (  (  (     )  )\ )  (     }
{    \(_))))\ (     ))\ )\))( ( /( (()/( ))\    }
{   (_)) /((_))\ ) /((_|(_))\ )(_)) ((_))(( )   }
{   | _ \_)) _(_/((_)) \( )(_|(_)_  _| (_))/    }
{   |   / -_) ' \)) -_)/ _` |/ _` / _` / -_)    }
{   |_|_\___|_||_|\___|\__, |\__,_\__,_\___|    }
{   ------------------ |___/ ----------------   }
{   B U L L E T I N   B O A R D   S Y S T E M   }
{   -----------------------------------------   }
{
    [DONE]
     - 
    [TO DO]
     - new user msg, use user search input, should check for forward, deleted user etc
     - Allow toggle of new user application message to be mandatory or optional
     birthdate/ph# validation at logon bypass if set to '' but require to update
     
     ''+PadRightStr('',23)+AOnOff((NewAppMsgMandatory),'Mandatory','Optional')
     
}

UNIT SysOp2M; { New User Application Questions Toggles }

INTERFACE

PROCEDURE NewUserTogglesConfiguration;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader}

PROCEDURE NewUserTogglesConfiguration;
VAR
  Cmd,
  Cmd1: Char;
  Counter: Byte; {LeeW: Added}
  {
  LowNum,
  HighNum,
  }
  TempInt: Integer; {LeeW: Added for new user private msg }
BEGIN
  REPEAT
    CLS;
    Abort := FALSE;
    Next := FALSE;
    {MCIAllowed := FALSE;}
    WITH General DO
      BEGIN
        ConfigHeader('New User Question Toggles');
        PrintACR(PadLeftStr('^0(^10^0) Refuse New Users : ^1'+ShowYesNo(ClosedSystem),39));
        NL;
        PrintACR(PadLeftStr('^0(^1A^0) User Name        : ^1'+ShowYesNo(AllowAlias),39)+
                 PadLeftStr('^0(^1N^0) Term Emulation   : ^1'+ShowYesNo(NewUserQToggles[15] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1B^0) Real Name        : ^1'+ShowYesNo(NewUserQToggles[02] = TRUE),39)+
                 PadLeftStr('^0(^1O^0) Color            : ^1'+ShowYesNo(NewUserQToggles[16] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1C^0) Country          : ^1'+ShowYesNo(NewUserQToggles[03] = TRUE),39)+
                 PadLeftStr('^0(^1P^0) Color Scheme     : ^1'+ShowYesNo(NewUserQToggles[17] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1D^0) Address          : ^1'+ShowYesNo(NewUserQToggles[04] = TRUE),39)+
                 PadLeftStr('^0(^1R^0) Screen Size      : ^1'+ShowYesNo(NewUserQToggles[18] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1E^0) City, State      : ^1'+ShowYesNo(NewUserQToggles[05] = TRUE),39)+
                 PadLeftStr('^0(^1S^0) Screen Clearing  : ^1'+ShowYesNo(NewUserQToggles[19] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1F^0) Zip Code         : ^1'+ShowYesNo(NewUserQToggles[06] = TRUE),39)+
                 PadLeftStr('^0(^1T^0) Screen Pausing   : ^1'+ShowYesNo(NewUserQToggles[20] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1G^0) Phone Number     : ^1'+ShowYesNo(NewUserQToggles[07] = TRUE),39)+
                 PadLeftStr('^0(^1U^0) Hotkey Input     : ^1'+ShowYesNo(NewUserQToggles[21] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1H^0) Birthdate        : ^1'+ShowYesNo(NewUserQToggles[08] = TRUE),39)+
                 PadLeftStr('^0(^1V^0) Expert Mode      : ^1'+ShowYesNo(NewUserQToggles[22] = TRUE),39));        
        PrintACR(PadLeftStr('^0(^1I^0) Gender           : ^1'+ShowYesNo(NewUserQToggles[09] = TRUE),39)+
                 PadLeftStr('^0(^1W^0) Lightbars        : ^1'+ShowYesNo(NewUserQToggles[23] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1J^0) '+PadLeftStr(LRGLngStr(41,TRUE),15)+'  : ^1'+ShowYesNo(NewUserQToggles[10] = TRUE),39)+
                 PadLeftStr('^0(^1X^0) Editor           : ^1'+ShowYesNo(NewUserQToggles[24] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1K^0) '+PadLeftStr(LRGLngStr(42,TRUE),15)+'  : ^1'+ShowYesNo(NewUserQToggles[11] = TRUE),39)+
                 PadLeftStr('^0(^1Y^0) Mailbox          : ^1'+ShowYesNo(NewUserQToggles[25] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1L^0) '+PadLeftStr(LRGLngStr(43,TRUE),15)+'  : ^1'+ShowYesNo(NewUserQToggles[12] = TRUE),39)+
                 PadLeftStr('^0(^1Z^0) QWK              : ^1'+ShowYesNo(NewUserQToggles[26] = TRUE),39));
        PrintACR(PadLeftStr('^0(^1M^0) Forgot PW Answer : ^1'+ShowYesNo(NewUserQToggles[14] = TRUE),39)+
                 PadLeftStr('^0(^11^0) New User Message : ^1'+AOnOff((NewApp = -1),'No','Yes ^0'+#196+' #^1'
                                                             +PadLeftInt(NewApp,5)),39));
      END;
    {MCIAllowed := TRUE;}
    NL;
    InputChar('^2New User Question Toggles [^1A^2-^1P^2,^1R^2-^1U^2,^10^2-^11^2,(^1Q^2)uit]: ',Cmd,
          'QABCDEFGHIJKLMNOPRSTUVWXYZ01*',[CapAll]);
    WITH General DO
      CASE Cmd OF
        '*' : BEGIN { Reset Everything }
                FOR Counter := 1 TO 30 DO
                  NewUserQToggles[Counter] := TRUE;
                AllowAlias := TRUE;
                ClosedSystem := FALSE;
                NewApp := 1;
              END;
        '0' : ClosedSystem := NOT ClosedSystem;
        'A' : BEGIN
                AllowAlias := NOT AllowAlias;
                IF (AllowAlias = FALSE) AND (NewUserQToggles[02] = FALSE) THEN
                  BEGIN
                    {Print('Enabling real names');}
                    NewUserQToggles[02] := TRUE;
                    {PauseScr(FALSE);}
                  END;
              END;
        'B' : BEGIN
                NewUserQToggles[02] := NOT NewUserQToggles[02];
                IF (NewUserQToggles[02] = FALSE) AND (AllowAlias = FALSE) THEN
                  BEGIN
                    {Print('Enabling aliases');}
                    AllowAlias := TRUE;
                    {PauseScr(FALSE);}
                  END;
              END;
        'C' : NewUserQToggles[03] := NOT NewUserQToggles[03];
        'D' : NewUserQToggles[04] := NOT NewUserQToggles[04];
        'E' : NewUserQToggles[05] := NOT NewUserQToggles[05];
        'F' : NewUserQToggles[06] := NOT NewUserQToggles[06];
        'G' : BEGIN
                NewUserQToggles[07] := NOT NewUserQToggles[07]; { Phone Number }
                IF ((NewUserQToggles[07] = FALSE) AND (General.PhonePW = TRUE)) THEN
                  BEGIN
                    General.PhonePW := FALSE;
                    Print('Disabling phone number verification at logon');
                    PauseScr(FALSE);
                  END;
              END;
        'H' : BEGIN
                NewUserQToggles[08] := NOT NewUserQToggles[08]; { Birthdate }
                IF ((NewUserQToggles[08] = FALSE) AND (General.BirthDateCheck <> 0)) THEN
                  BEGIN
                    General.BirthDateCheck := 0;
                    Print('Disabling birthdate verification at logon');
                    PauseScr(FALSE);
                  END;
              END;
        'I' : NewUserQToggles[09] := NOT NewUserQToggles[09];
        'J' : NewUserQToggles[10] := NOT NewUserQToggles[10];
        'K' : NewUserQToggles[11] := NOT NewUserQToggles[11];
        'L' : NewUserQToggles[12] := NOT NewUserQToggles[12];
              { 13 = Password }
        'M' : NewUserQToggles[14] := NOT NewUserQToggles[14];
        'N' : NewUserQToggles[15] := NOT NewUserQToggles[15];
        'O' : NewUserQToggles[16] := NOT NewUserQToggles[16];
        'P' : NewUserQToggles[17] := NOT NewUserQToggles[17];
        'R' : NewUserQToggles[18] := NOT NewUserQToggles[18];
        'S' : NewUserQToggles[19] := NOT NewUserQToggles[19];
        'T' : NewUserQToggles[20] := NOT NewUserQToggles[20];
        'U' : NewUserQToggles[21] := NOT NewUserQToggles[21];
        'V' : NewUserQToggles[22] := NOT NewUserQToggles[22];
        'W' : NewUserQToggles[23] := NOT NewUserQToggles[23];
        'X' : NewUserQToggles[24] := NOT NewUserQToggles[24];
        'Y' : NewUserQToggles[25] := NOT NewUserQToggles[25];
        'Z' : NewUserQToggles[26] := NOT NewUserQToggles[26];
        '1' : BEGIN
                NL;
                InputChar('^2New user message '#196#196' (^1E^2)nable, (^1D^2)isable, or <^1CR^2>Abort: ',Cmd,^M'ED',[CapAll]);
                IF (Cmd IN ['E','D']) THEN
                BEGIN
                { LEEW: add mandatory or optional question}
                  CASE Cmd OF
                    'E' : BEGIN
                            NL;
                            {new user application letter -- mandatory or optional?}
                            InputInteger('^2New user message goes to which user number?',TempInt,[NumbersOnly],1,
                                            (MaxUsers - 1),Changed);
                            {&&^^LeeW: Wording--use finduser??}
                            {NewAppMsgMandatory := YNQ('Should the new user letter be mandatory?',TRUE);}
                          END;
                    'D' : TempInt := -1;
                  END;
                  NewApp := TempInt;
                  {Cmd := #0;}
                END;
              END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.