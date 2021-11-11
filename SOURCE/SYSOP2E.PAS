{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Flagged Functions }

(*  1.  Add checking for deleted users or forwarded mail to option 1 *)

UNIT SysOp2E;

INTERFACE

PROCEDURE SystemFlaggedFunctions;

IMPLEMENTATION

USES
  Crt,
  Common;

PROCEDURE SystemFlaggedFunctions;
VAR
  Cmd,
  Cmd1: Char;
  LowNum,
  HiNum,
  TempInt: Integer;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^1System Flagged Functions:');
      NL;
      PrintACR('^0A. Handles allowed on system: ^1'+ShowOnOff(AllowAlias)+
             '^0  B. Phone number in logon     : ^1'+ShowOnOff(PhonePW));
      PrintACR('^0C. Local security protection: ^1'+ShowOnOff(LocalSec)+
             '^0  D. Use EMS for overlay file  : ^1'+ShowOnOff(UseEMS));
      PrintACR('^0E. Global activity trapping : ^1'+ShowOnOff(GlobalTrap)+
             '^0  F. Auto chat buffer open     : ^1'+ShowOnOff(AutoChatOpen));
      PrintACR('^0G. AutoMessage in logon     : ^1'+ShowOnOff(AutoMInLogon)+
             '^0  H. Bulletins in logon        : ^1'+ShowOnOff(BullInLogon));
      PrintACR('^0I. User info in logon       : ^1'+ShowOnOff(YourInfoInLogon)+
             '^0  J. Strip color off SysOp Log : ^1'+ShowOnOff(StripCLog));
      PrintACR('^0K. Offhook in local logon   : ^1'+ShowOnOff(OffHookLocalLogon)+
             '^0  L. Trap Teleconferencing     : ^1'+ShowOnOff(TrapTeleConf));
      PrintACR('^0M. Compress file/msg numbers: ^1'+ShowOnOff(CompressBases)+
             ' ^0 N. Use BIOS for video output : ^1'+ShowOnOff(UseBIOS));
      PrintACR('^0O. Use IEMSI handshakes     : ^1'+ShowOnOff(UseIEMSI)+
             '^0  P. Refuse new users          : ^1'+ShowOnOff(ClosedSystem));
      PrintACR('^0R. Swap shell function      : ^1'+ShowOnOff(SwapShell)+
             '^0  S. Use shuttle logon         : ^1'+ShowOnOff(ShuttleLog));
      PrintACR('^0T. Chat call paging         : ^1'+ShowOnOff(ChatCall)+
             '^0  U. Time limits are per call  : ^1'+ShowOnOff(PerCall));
      PrintACR('^0V. SysOp Password checking  : ^1'+ShowOnOff(SysOpPWord)+
             '^0  W. Random quote in logon     : ^1'+ShowOnOff(LogonQuote));
      PrintACR('^0X. User add quote in logon  : ^1'+ShowOnOff(UserAddQuote)+
             '^0  Y. Use message area lightbar : ^1'+ShowOnOff(UseMsgAreaLightBar));
      PrintACR('^0Z. Use file area lightbar   : ^1'+ShowOnOff(UseFileAreaLightBar));
      PrintACR('');
      PrintACR('^01. New user message sent to : ^1'+AOnOff((NewApp = -1),'Off',PadLeftInt(NewApp,5)));
      PrintACR('^02. Mins before TimeOut bell : ^1'+AOnOff((TimeOutBell = -1),'Off',PadLeftInt(TimeOutBell,3)));
      PrintACR('^03. Mins before TimeOut      : ^1'+AOnOff((TimeOut = -1),'Off',PadLeftInt(TimeOut,3)));
      Prt('%LFEnter selection [^1A^2-^1P^2,^1R^2-^1Z^2,^11^2-^13^2,^1Q^2=^1Quit^2]: ');
      LOneK('',Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ123'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : AllowAlias := NOT AllowAlias;
        'B' : BEGIN
                PhonePW := NOT PhonePW;
                IF (PhonePW) THEN
                  NewUserToggles[7] := 8
                ELSE
                  NewUserToggles[7] := 0;
              END;
        'C' : LocalSec := NOT LocalSec;
        'D' : BEGIN
                UseEMS := NOT UseEMS;
                IF (UseEMS) THEN
                  OvrUseEMS := TRUE
                ELSE
                  OvrUseEMS := FALSE;
              END;
        'E' : GlobalTrap := NOT GlobalTrap;
        'F' : AutoChatOpen := NOT AutoChatOpen;
        'G' : AutoMInLogon := NOT AutoMInLogon;
        'H' : BullInLogon := NOT BullInLogon;
        'I' : YourInfoInLogon := NOT YourInfoInLogon;
        'J' : StripCLog := NOT StripCLog;
        'K' : OffHookLocalLogon := NOT OffHookLocalLogon;
        'L' : TrapTeleConf := NOT TrapTeleConf;
        'M' : BEGIN
                CompressBases := NOT CompressBases;
                IF (CompressBases) THEN
                  Print('%LFCompressing file/message areas ...')
                ELSE
                  Print('%LFDe-compressing file/message areas ...');
                NewCompTables;
              END;
        'N' : BEGIN
                UseBIOS := NOT UseBIOS;
                DirectVideo := NOT UseBIOS;
              END;
        'O' : UseIEMSI := NOT UseIEMSI;
        'P' : ClosedSystem := NOT ClosedSystem;
        'R' : SwapShell := NOT SwapShell;
        'S' : ShuttleLog := NOT ShuttleLog;
        'T' : ChatCall := NOT ChatCall;
        'U' : PerCall := NOT PerCall;
        'V' : SysOpPWord := NOT SysOpPWord;
        'W' : LogonQuote := NOT LogonQuote;
        'X' : UserAddQuote := NOT UserAddQuote;
        'Y' : UseMsgAreaLightBar := NOT UseMsgAreaLightBar;
        'Z' : UseFileAreaLightBar := NOT UseFileAreaLightBar;
        '1'..'3' :
              BEGIN
                Prt('%LFSelect option [^1E^2=^1Enable^2,^1D^2=^1Disable^2,^1<CR>^2=^1Quit^2]: ');
                LOneK('',Cmd1,^M'ED',TRUE,TRUE);
                IF (Cmd1 IN ['E','D']) THEN
                BEGIN
                  CASE Cmd1 OF
                    'E' : BEGIN
                            CASE Cmd OF
                              '1' : BEGIN
                                      LowNum := 1;
                                      HiNum := (MaxUsers - 1);
                                      TempInt := NewApp;
                                    END;
                              '2' : BEGIN
                                      LowNum := 1;
                                      HiNum := 20;
                                      TempInt := TimeOutBell;
                                    END;
                              '3' : BEGIN
                                      LowNum := 1;
                                      HiNum := 20;
                                      TempInt := TimeOut;
                                    END;
                            END;
                            InputIntegerWOC('%LFEnter value for this function',TempInt,[NumbersOnly],LowNum,HiNum);
                          END;
                    'D' : TempInt := -1;
                  END;
                  CASE Cmd OF
                    '1' : NewApp := TempInt;
                    '2' : TimeOutBell := TempInt;
                    '3' : TimeOut := TempInt;
                  END;
                  Cmd := #0;
                END;
          END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
