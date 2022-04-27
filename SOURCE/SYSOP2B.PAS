{$A+,B-,D+,E-,L+,I-,L+,N-,O+,R-,S+,V-}
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
     10/13/2021 - Moved teleconference strings to RGMain lang
     10/17/2021 - Added changed checks to some options
                - Changed menu options order, aesthetic redesign
                - Indent, Clean-up, etc
                - updated color codes to new scheme format
                - can now scroll through the nodes with "[" and "]", 
                - Added "?" help cmd
                - Moving fore and back in nodes or quitting will prompt you to save if you made changes
                - Advancing to a node that doesn't exist will now prompt to add.
                  If yes, it copies the previous nodes data file
                - Error messages now using Messages proc in COMMON
    [TODO]
     - maybe could add cmd to delete node?
     - maybe could scan files incase nodes are no linear ie. node1 exist, node2 doesn't, node3 does
     - maybe do first, last, jumpto
}
UNIT SysOp2B;

INTERFACE

PROCEDURE ModemConfiguration;

IMPLEMENTATION

USES
  SysOp2,
  Common,
  File2; { CopyMoveFile }

PROCEDURE ModemConfiguration;
VAR
  LineFile: FILE OF LineRec;
  Cmd: Char;
  TempB,
  NodeNum: Byte; { LeeW: Added }
  Changed: Boolean;

  PROCEDURE ToggleMFlag(MFlagT: ModemFlagType; VAR MFlags: MFlagSet);
  BEGIN
    IF (MFlagT IN MFlags) THEN
      Exclude(MFlags,MFlagT)
    ELSE
      Include(MFlags,MFlagT);
  END;

  PROCEDURE ToggleMFlags(C: Char; VAR MFlags: MFlagSet; VAR Changed: Boolean);
  VAR
    SaveMFlags: MFlagSet;
  BEGIN
    SaveMFlags := MFlags;
    CASE C OF
      '7' : ToggleMFlag(LockedPort,MFlags);
      '8' : ToggleMFlag(XONXOFF,MFlags);
      '9' : ToggleMFlag(CTSRTS,MFlags);
    END;
    IF (MFlags <> SaveMFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE NewModemString(CONST DisplayStr: AStr; VAR InputStr: AStr; Len: Byte);
  BEGIN
    NL;
    Print('^0Current modem '+DisplayStr+' string: "^1'+InputStr+'^0"');
    NL;
    Print('^0Use "^1|^0" for a carriage return');
    Print('^0    "^1~^0" for a half-second delay');
    Print('^0    "^1^^0" to toggle DTR off for 1/4 of a second');
    NL;
    InputString('^2Enter new modem '+DisplayStr+' string: ',InputStr,Len,[InterActiveEdit],Changed);
  END;

  FUNCTION WhichBaud(B: Byte): AStr;
  BEGIN
    CASE B OF
      01 : WhichBaud := 'CONNECT 300';
      02 : WhichBaud := 'CONNECT 600';
      03 : WhichBaud := 'CONNECT 1200';
      04 : WhichBaud := 'CONNECT 2400';
      05 : WhichBaud := 'CONNECT 4800';
      06 : WhichBaud := 'CONNECT 7200';
      07 : WhichBaud := 'CONNECT 9600';
      08 : WhichBaud := 'CONNECT 12000';
      09 : WhichBaud := 'CONNECT 14400';
      10 : WhichBaud := 'CONNECT 16800';
      11 : WhichBaud := 'CONNECT 19200';
      12 : WhichBaud := 'CONNECT 21600';
      13 : WhichBaud := 'CONNECT 24000';
      14 : WhichBaud := 'CONNECT 26400';
      15 : WhichBaud := 'CONNECT 28800';
      16 : WhichBaud := 'CONNECT 31200';
      17 : WhichBaud := 'CONNECT 33600';
      18 : WhichBaud := 'CONNECT 38400';
      19 : WhichBaud := 'CONNECT 57600';
      20 : WhichBaud := 'CONNECT 115200';
    END;
  END;

BEGIN
  Changed := FALSE;
  NodeNum := ThisNode;
  Assign(LineFile,General.DataPath+'NODE'+IntToStr(NodeNum)+'.DAT');
  Reset(LineFile);
  Read(LineFile,Liner);
  REPEAT
    WITH Liner DO
      BEGIN
        IF (Cmd <> '?') THEN
          BEGIN
            Abort := FALSE;
            Next := FALSE;
            ConfigHeader('Modem / Node #'+IntToStr(NodeNum)+' Configuration',0);
            PrintACR(PadLeftStr('^0(^1A^0) Com Port         : ^1'+IntToStr(ComPort),39)+
                     PadLeftStr('^0(^1B^0) IRQ              : ^1'+IRQ,39));
            PrintACR(PadLeftStr('^0(^1C^0) I/O Address      : ^1'+Address,39)+
                     PadLeftStr('^0(^1D^0) Max Baud Rate    : ^1'+IntToStr(InitBaud),39));
            PrintACR(PadLeftStr('^0(^1E^0) Com Port Locking : ^1'+ShowOnOff(LockedPort IN MFlags),39)+
                     PadLeftStr('^0(^1F^0) CTS/RTS (HW) FC  : ^1'+ShowOnOff(CTSRTS IN MFlags),39));
            PrintACR(PadLeftStr('^0(^1G^0) XON/XOFF (SW) FC : ^1'+ShowOnOff(XONXOFF IN MFlags),39)+
                     PadLeftStr('^0(^1H^0) Multi-Ring Only  : ^1'+ShowOnOff(MultiRing),39));
            PrintACR(PadLeftStr('^0(^1I^0) Answer On Ring # : ^1'+IntToStr(AnswerOnRing),39){+
                     PadLeftStr('',39)});
            NL;
            PrintACR('^0(^1J^0) Modem Command Strings ...');
            PrintACR('^0(^1K^0) Modem Result Codes ...');
            NL;
            PrintACR(PadLeftStr('^0(^1L^0) ACS Required     : ^1'+AOnOff(LogonACS = '','*None*',LogonACS),39));
            NL;
            PrintACR(PadLeftStr('^0(^1M^0) Drop File Path   : ^1'+DoorPath,79));
            NL;
          END;
        InputChar('^2Node Configuration [^1A^2-^1M^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,
              'Q[]?ABCDEFGHIJKLM'^M,[CapAll]);
        CASE Cmd OF
          '?' : BEGIN
                  NL;
                  LCmds(16,1,'[ Previous Node','] Next Node');
                  NL;
                  {PauseScr(FALSE);}
                END;
          'A' : IF (InCom) THEN
                  Messages(9,0,'') {"This can only be changed locally"}
                ELSE
                  BEGIN
                    TempB := ComPort;
                    InputByte('^2%LFCom port',TempB,[InterActiveEdit,NumbersOnly],0,64,Changed);
                    IF (Changed) THEN
                      IF PYNQ('%LFAre you sure this is what you want?',0,FALSE) THEN
                        BEGIN
                          Com_DeInstall;
                          ComPort := TempB;
                          Com_Install;
                        END;
                    IF (NOT LocalIOOnly) AND (ComPort=0) THEN
                      LocalIOOnly := TRUE;
                  END;
          'B' : InputString('^2%LFIRQ for %E MCI code: ',IRQ,(SizeOf(IRQ)-1),[InterActiveEdit],Changed);
          'C' : InputString('^2%LFI/O Address for %C MCI code: ',Address,(SizeOf(Address)-1),[InterActiveEdit],Changed);
          'D' : IF (InCom) THEN
                  Messages(9,0,'') {"This can only be changed locally"}
                ELSE
                  BEGIN
                    ConfigHeader('Node '+IntToStr(NodeNum)+' Maximum Baud Rate',0);
                    Print('^0(^11^0) 2400');
                    Print('^0(^12^0) 9600');
                    Print('^0(^13^0) 19200');
                    Print('^0(^14^0) 38400');
                    Print('^0(^15^0) 57600');
                    Print('^0(^16^0) 115200');
                    NL;
                    InputChar('^2Maximum Baud Rate [^11^2-^16^2,<^1CR^2>Quit]: ',Cmd,^M'123456',[CapAll]);
                    CASE Cmd OF
                      '1' : InitBaud := 2400;
                      '2' : InitBaud := 9600;
                      '3' : InitBaud := 19200;
                      '4' : InitBaud := 38400;
                      '5' : InitBaud := 57600;
                      '6' : InitBaud := 115200;
                    END;
                    IF (Cmd<>^M) THEN { LeeW: Cheating a bit here }
                      Changed := TRUE;
                    Cmd := #0;
                  END;
          'E' : ToggleMFlags('7',MFlags,Changed);
          'F' : ToggleMFlags('9',MFlags,Changed);
          'G' : ToggleMFlags('8',MFlags,Changed);
          'H' : BEGIN
                  MultiRing := NOT MultiRing;
                  Changed := TRUE; { LeeW: Here too }
                END;
          'I' : InputByte('^2%LFAnswer after how many rings?',AnswerOnRing,
                            [NumbersOnly,InterActiveEdit],0,255,Changed);
          'J' : BEGIN
                  REPEAT
                    ConfigHeader('Modem Command Strings',0);
                    PrintACR('^0(^11^0) Modem Init     : ^1'+Init);
                    PrintACR('^0(^12^0) Modem Answer   : ^1'+Answer);
                    PrintACR('^0(^13^0) Modem Hang Up  : ^1'+HangUp);
                    PrintACR('^0(^14^0) Modem Off Hook : ^1'+OffHook);
                    NL;
                    InputChar('^2Modem Command Strings [^11^2-^14^2,<^1CR^2>Quit]: ',Cmd,^M'1234',[CapAll]);
                    CASE Cmd OF
                      '1' : NewModemString('Init',Init,(SizeOf(Init)-1));
                      '2' : NewModemString('Answer',Answer,(SizeOf(Answer)-1));
                      '3' : NewModemString('HangUp',HangUp,(SizeOf(HangUp)-1));
                      '4' : NewModemString('Off Hook',OffHook,(SizeOf(OffHook)-1));
                    END;
                  UNTIL (Cmd = ^M);
                  Cmd := #0;
                END;
          'K' : BEGIN
                  REPEAT
                    ConfigHeader('Modem Result Codes',0);
                    PrintACR(PadLeftStr('^0(^1A^0) NO CARRIER    : ^1'+NoCarrier,39)+
                             PadLeftStr('^0(^1B^0) RELIABLE      : ^1'+Reliable,39));
                    PrintACR(PadLeftStr('^0(^1C^0) OK            : ^1'+Ok,39)+
                             PadLeftStr('^0(^1D^0) RING          : ^1'+Ring,39));
                    PrintACR(PadLeftStr('^0(^1E^0) CALLER ID     : ^1'+CallerID,39));
                    NL;
                    FOR TempB := 1 TO MaxResultCodes DO
                      IF (NOT Odd(TempB)) THEN
                        Print(PadLeftStr(PadLeftStr('^0(^1'+Chr(TempB + 70)+'^0) '
                              +WhichBaud(TempB),18)+': ^1'+Connect[TempB],39))
                      ELSE
                        Prompt(PadLeftStr(PadLeftStr('^0(^1'+Chr(TempB + 70)+'^0) '
                               +WhichBaud(TempB),18)+': ^1'+Connect[TempB],39));
                    NL;
                    InputChar('^2Modem Result Codes [^1A^2-^1E^2,^1G^2-^1Z^2,<^1CR^2>Quit]: ',
                          Cmd,^M'ABCDEGHIJKLMNOPQRSTUVWXYZ',[CapAll]);
                    CASE Cmd OF
                      'A' : InputString('^2%LFEnter NO CARRIER string: ',NoCarrier,(SizeOf(NoCarrier)-1),
                                     [InterActiveEdit,CapAll],Changed);
                      'B' : InputString('^2%LFEnter RELIABLE string: ',Reliable,(SizeOf(Reliable)-1),
                                     [InterActiveEdit,CapAll],Changed);
                      'C' : InputString('^2%LFEnter OK string: ',Ok,(SizeOf(Ok)-1),
                                     [InterActiveEdit,CapAll],Changed);
                      'D' : InputString('^2%LFEnter RING string: ',Ring,(SizeOf(Ring)-1),
                                     [InterActiveEdit,CapAll],Changed);
                      'E' : InputString('^2%LFEnter Caller ID string: ',CallerID,(SizeOf(CallerID)-1),
                                     [InterActiveEdit,CapAll],Changed);
                      'G'..'Z' :
                            BEGIN
                              TempB := (Ord(Cmd) - 70);
                              IF (TempB IN [1..MaxResultCodes]) THEN
                                InputString('^2%LFEnter '+WhichBaud(TempB)+' string: ',Connect[TempB],(SizeOf(Connect[1])-1),
                                         [InterActiveEdit,CapAll],Changed);
                            END;
                    END;
                  UNTIL (Cmd = ^M);
                  Cmd := #0;
                END;
          'L' : InputString('^2%LFEnter ACS requirements for this node: ',
                         LogonACS,(SizeOf(LogonACS)-1),[InterActiveEdit],Changed);
          'M' : InputPath('^2%LFEnter path to write door interface files to:%LF',
                          DoorPath,TRUE,FALSE,Changed);
          ']', '[', 'Q' : 
                BEGIN
                  IF (Changed) THEN
                    IF PYNQ('^2%LFSave settings for node '+IntToStr(NodeNum)+'? ',0,TRUE) THEN
                      BEGIN
                        Seek(LineFile,0);
                        Write(LineFile,Liner);
                      END;
                  Close(LineFile);
                  Changed := FALSE;
                  IF (Cmd = ']') AND (NodeNum < 255) THEN
                    BEGIN
                      IF NOT Exist(General.DataPath+'NODE'+IntToStr(NodeNum+1)+'.DAT') THEN
                        BEGIN
                          IF (PYNQ('^2%LFNode '+IntToStr(NodeNum+1)+' doesn''t exist - Initialize it now? ',0,TRUE)) THEN
                            BEGIN
                              CopyMoveFile(TRUE,'',General.DataPath+'NODE'+IntToStr(NodeNum)+'.DAT',
                                           General.DataPath+'NODE'+IntToStr(NodeNum+1)+'.DAT',FALSE);
                              Inc(NodeNum);
                            END;
                        END
                      ELSE
                        Inc(NodeNum);
                    END
                  ELSE IF (Cmd = '[') AND (NodeNum > 1) THEN 
                    BEGIN
                      IF NOT Exist(General.DataPath+'NODE'+IntToStr(NodeNum-1)+'.DAT') THEN
                        BEGIN
                          IF (PYNQ('^2%LFNode '+IntToStr(NodeNum-1)+' doesn''t exist - Initialize it now? ',0,TRUE)) THEN
                            BEGIN
                              CopyMoveFile(TRUE,'',General.DataPath+'NODE'+IntToStr(NodeNum)+'.DAT',
                                           General.DataPath+'NODE'+IntToStr(NodeNum-1)+'.DAT',FALSE);
                              Dec(NodeNum);
                            END;
                        END
                      ELSE
                        Dec(NodeNum);
                    END;
                  Assign(LineFile,General.DataPath+'NODE'+IntToStr(NodeNum)+'.DAT');
                  Reset(LineFile);
                  Read(LineFile,Liner);
                END;
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);  
END;
END.