{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Flagged Functions }

(*  1.  Add checking for deleted users or forwarded mail to new user letter config *)

UNIT SysOp2E;

INTERFACE

PROCEDURE SystemFlaggedFunctions;

IMPLEMENTATION

USES
  CRT,
  Common,
  SysOp2; {ConfigHeader}

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
		ConfigHeader('System Toggles');
		PrintACR(PadLeftStr('^0(^1A^0) Handles allowed on system : ^1'+ShowOnOff(AllowAlias),39)+
				 PadLeftStr('^0(^1B^0) Phone number in logon     : ^1'+ShowOnOff(PhonePW),39));
		PrintACR(PadLeftStr('^0(^1C^0) Local security protection : ^1'+ShowOnOff(LocalSec),39)+
				 PadLeftStr('^0(^1D^0) Use EMS for overlay file  : ^1'+ShowOnOff(UseEMS),39));
		PrintACR(PadLeftStr('^0(^1E^0) Global activity trapping  : ^1'+ShowOnOff(GlobalTrap),39)+
				 PadLeftStr('^0(^1F^0) Auto chat buffer open     : ^1'+ShowOnOff(AutoChatOpen),39));
		PrintACR(PadLeftStr('^0(^1G^0) AutoMessage in logon      : ^1'+ShowOnOff(AutoMInLogon),39)+
				 PadLeftStr('^0(^1H^0) Bulletins in logon        : ^1'+ShowOnOff(BullInLogon),39));
		PrintACR(PadLeftStr('^0(^1I^0) User info in logon        : ^1'+ShowOnOff(YourInfoInLogon),39)+
				 PadLeftStr('^0(^1J^0) Strip color off SysOp Log : ^1'+ShowOnOff(StripCLog),39));
		PrintACR(PadLeftStr('^0(^1K^0) Offhook in local logon    : ^1'+ShowOnOff(OffHookLocalLogon),39)+
				 PadLeftStr('^0(^1L^0) Trap Teleconferencing     : ^1'+ShowOnOff(TrapTeleConf),39));
		PrintACR(PadLeftStr('^0(^1M^0) Compress file/msg numbers : ^1'+ShowOnOff(CompressBases),39)+
				 PadLeftStr('^0(^1N^0) Use BIOS for video output : ^1'+ShowOnOff(UseBIOS),39));
		PrintACR(PadLeftStr('^0(^1O^0) Use IEMSI handshakes      : ^1'+ShowOnOff(UseIEMSI),39)+
				 PadLeftStr('^0(^1P^0) Refuse new users          : ^1'+ShowOnOff(ClosedSystem),39));
		PrintACR(PadLeftStr('^0(^1R^0) Swap shell function       : ^1'+ShowOnOff(SwapShell),39)+
				 PadLeftStr('^0(^1S^0) Use shuttle logon         : ^1'+ShowOnOff(ShuttleLog),39));
		PrintACR(PadLeftStr('^0(^1T^0) Chat call paging          : ^1'+ShowOnOff(ChatCall),39)+
				 PadLeftStr('^0(^1U^0) Time limits are per call  : ^1'+ShowOnOff(PerCall),39));
		PrintACR(PadLeftStr('^0(^1V^0) SysOp Password checking   : ^1'+ShowOnOff(SysOpPWord),39)+
				 PadLeftStr('^0(^1W^0) Random quote in logon     : ^1'+ShowOnOff(LogonQuote),39));
		PrintACR(PadLeftStr('^0(^1X^0) User add quote in logon   : ^1'+ShowOnOff(UserAddQuote),39)+
				 PadLeftStr('^0(^1Y^0) Use message area lightbar : ^1'+ShowOnOff(UseMsgAreaLightBar),39));
		PrintACR(PadLeftStr('^0(^1Z^0) Use file area lightbar    : ^1'+ShowOnOff(UseFileAreaLightBar),39));

		PrintACR('^02. Mins before TimeOut bell : ^1'+AOnOff((TimeOutBell = -1),'Off',PadLeftInt(TimeOutBell,3)));
		PrintACR('^03. Mins before TimeOut      : ^1'+AOnOff((TimeOut = -1),'Off',PadLeftInt(TimeOut,3)));
		NL;
		InputChar('Enter selection [^1A^2-^1P^2,^1R^2-^1Z^2,^11^2-^13^2,^1Q^2=^1Quit^2]: ',Cmd,
                  'QABCDEFGHIJKLMNOPRSTUVWXYZ123'^M,[CapAll]);
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
        '2'..'3' :
              BEGIN
                InputChar('%LFSelect option [^1E^2=^1Enable^2,^1D^2=^1Disable^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'ED',[CapAll]);
                IF (Cmd1 IN ['E','D']) THEN
                BEGIN
                  CASE Cmd1 OF
                    'E' : BEGIN
                            CASE Cmd OF
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
                            InputInteger('%LFEnter value for this function',TempInt,[NumbersOnly],LowNum,HiNum,Changed);
                          END;
                    'D' : TempInt := -1;
                  END;
                  CASE Cmd OF
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
