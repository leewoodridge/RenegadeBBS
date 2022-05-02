{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Flagged Functions }

(*  1.  Add checking for deleted users or forwarded mail to new user letter config --i think searchusers does*)
{
 12/02/2021 - combined timeout warning/logoff
            - combined lightbar toggles, now only 1 for all system lightbars
 04/26/2022 - testing out multi-page menu system
}


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
  OnPage: Byte;
BEGIN
  OnPage := 1;
  REPEAT
    IF (OnPage = 1) THEN
      WITH General DO
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          ConfigHeader('System Toggles',12);
          PrintACR(PadLeftStr('^0(^1A^0) Mandatory voting          : ^1'+ShowOnOff(ForceVoting),39)+
                   PadLeftStr('^0(^1B^0) Phone # security question : ^1'+ShowOnOff(PhonePW),39));
          PrintACR(PadLeftStr('^0(^1C^0) Local security protection : ^1'+ShowOnOff(LocalSec),39)+
                   PadLeftStr('^0(^1D^0) Use EMS for overlay file  : ^1'+ShowOnOff(UseEMS),39));
          PrintACR(PadLeftStr('^0(^1E^0) Global activity logging   : ^1'+ShowOnOff(GlobalTrap),39)+
                   PadLeftStr('^0(^1F^0) Global chat logging       : ^1'+ShowOnOff(AutoChatOpen),39));
          PrintACR(PadLeftStr('^0(^1G^0) AutoMessage in logon      : ^1'+ShowOnOff(AutoMInLogon),39)+
                   PadLeftStr('^0(^1H^0) Bulletins in logon        : ^1'+ShowOnOff(BullInLogon),39));
          PrintACR(PadLeftStr('^0(^1I^0) User info in logon        : ^1'+ShowOnOff(YourInfoInLogon),39)+
                   PadLeftStr('^0(^1J^0) Strip color off SysOp log : ^1'+ShowOnOff(StripCLog),39));
          PrintACR(PadLeftStr('^0(^1K^0) Offhook for local logon   : ^1'+ShowOnOff(OffHookLocalLogon),39)+
                   PadLeftStr('^0(^1L^0) Global teleconf logging   : ^1'+ShowOnOff(TrapTeleConf),39));
          PrintACR(PadLeftStr('^0(^1M^0) Compress file/msg numbers : ^1'+ShowOnOff(CompressBases),39)+
                   PadLeftStr('^0(^1N^0) Use BIOS for video output : ^1'+ShowOnOff(UseBIOS),39));
          PrintACR(PadLeftStr('^0(^1O^0) Use IEMSI handshakes      : ^1'+ShowOnOff(UseIEMSI),39)+
                   PadLeftStr('^0(^1P^0) Refuse new users          : ^1'+ShowOnOff(ClosedSystem),39));
          PrintACR(PadLeftStr('^0(^1R^0) Swap shell function       : ^1'+ShowOnOff(SwapShell),39)+
                   PadLeftStr('^0(^1S^0) Use shuttle logon         : ^1'+ShowOnOff(ShuttleLog),39));
          PrintACR(PadLeftStr('^0(^1T^0) Chat call paging          : ^1'+ShowOnOff(ChatCall),39)+
                   PadLeftStr('^0(^1U^0) Time limits are per call  : ^1'+ShowOnOff(PerCall),39));
          PrintACR(PadLeftStr('^0(^1V^0) SysOp password checking   : ^1'+ShowOnOff(SysOpPWord),39)+
                   PadLeftStr('^0(^1W^0) Random quote in logon     : ^1'+ShowOnOff(LogonQuote),39));
          PrintACR(PadLeftStr('^0(^1X^0) User add random quote     : ^1'+ShowOnOff(UserAddQuote),39)+
                   PadLeftStr('^0(^1Y^0) Use lightbars             : ^1'+ShowOnOff(UseLightBars),39));
          PrintACR(PadLeftStr('^0(^1Z^0) Inactivity Warn/TimeOut   : ^1'+AOnOff((TimeOutBell = -1) AND (TimeOut = -1),'Off',
                              AOnOff((TimeOutBell = -1),'Off',IntToStr(TimeOutBell))+'^0/^1'+AOnOff((TimeOut = -1),'Off',
                              IntToStr(TimeOut))),39));
          NL;
          InputChar('System Toggles [^1A^2-^1P^2,^1R^2-^1Z^2,<^1CR^2>Page,(^1Q^2)uit]: ',Cmd,
                    'QABCDEFGHIJKLMNOPRSTUVWXYZ'^M,[CapAll]);
          CASE Cmd OF
            ^M  : IF (OnPage = 1) THEN
                    OnPage := 2
                  ELSE
                    OnPage := 1;
            'A' : Toggle(ForceVoting);
            'B' : Toggle(PhonePW);
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
            'Y' : UseLightBars := NOT UseLightBars;
            'Z' : BEGIN
                    InputChar('%LF^2Timeout Warning - [(^1E^2)nable, (^1D^2)isable, <^1CR^2>Abort]: ',Cmd1,'ED'^M,[CapAll]);
                    CASE Cmd1 OF
                      'E' : InputInteger('Minutes before timeout warning',TimeOutBell,[NumbersOnly],1,20,Changed);
                      'D' : TimeOutBell := -1;
                    END;
                    InputChar('%LF^2Timeout LogOff - [(^1E^2)nable, (^1D^2)isable, <^1CR^2>Abort]: ',Cmd1,'ED'^M,[CapAll]);
                    CASE Cmd1 OF
                      'E' : InputInteger('Minutes before timeout logoff',TimeOut,[NumbersOnly],1,20,Changed);
                      'D' : TimeOut := -1;
                    END;
                  END;
          END;
        END;
    
    {-}
    
    IF (OnPage = 2) THEN
      WITH General DO
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          ConfigHeader('System Toggles',22);
          PrintACR(PadLeftStr('^0(^1A^0) Newest OneLiners on top   : ^1'+ShowOnOff(OneLinersNewTop),39)+
                   PadLeftStr('^0(^1B^0) LastCallers in logon      : ^1'+ShowOnOff(LogonLastCallers),39));
          PrintACR(PadLeftStr('^0(^1C^0) OneLiners in logon        : ^1'+ShowOnOff(LogonOneLiners),39)+
                   PadLeftStr('^0(^1D^0) Voting in logon           : ^1'+ShowOnOff(LogonVoting),39));
          PrintACR(PadLeftStr('^0(^1E^0) Prompt to DL top files    : ^1'+ShowOnOff(TopFilesDownload),39)+
                   PadLeftStr('^0(^1F^0) TimeStamp SysOp log       : ^1'+ShowOnOff(TimeStampLogs),39));
          PrintACR(PadLeftStr('^0(^1G^0) Use split chat as default : ^1'+ShowOnOff(DefSplitChat),39));
          NL;
          InputChar('System Toggles [^1A^2-^1G^2,<^1CR^2>Page,(^1Q^2)uit^2]: ',Cmd,
                    'QABCDEFG'^M,[CapAll]);
          CASE Cmd OF
            ^M  : IF (OnPage = 1) THEN
                    OnPage := 2
                  ELSE
                    OnPage := 1;
            'A' : Toggle(OneLinersNewTop);
            'B' : Toggle(LogonLastCallers);
            'C' : Toggle(LogonOneLiners);
            'D' : Toggle(LogonVoting);
            'E' : Toggle(TopFilesDownload);
            'F' : Toggle(TimeStampLogs);
            'G' : Toggle(DefSplitChat);
          END;
        END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.