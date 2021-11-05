{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 09/23/2021 - Removed all strings from lang file
            - Removed all MCIs
 10/04/2021 - Indented everything
}
UNIT SysOp2A;

INTERFACE

PROCEDURE MainBBSConfiguration;

IMPLEMENTATION

USES
  CRT,
  Common,
  SysOp2,
  SysOp7,
  TimeFunc;

PROCEDURE GetTimeRange(CONST prompt: string; VAR LoTime,HiTime: Integer);
VAR
  TempStr: Str5;
  LowTime,
  HighTime: Integer;
BEGIN
  IF (NOT (PYNQ(prompt,0,FALSE))) THEN
    BEGIN
      LowTime := 0;
      HighTime := 0;
    END
  ELSE
    BEGIN
      NL;
      Print('All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)');
      NL;
      Prt('Starting time: ');
      MPL(5);
      InputFormatted('',TempStr,'##:##',TRUE);
      IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
        LowTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)))
      ELSE
        LowTime := 0;
      NL;
      Prt('Ending time: ');
      MPL(5);
      InputFormatted('',TempStr,'##:##',TRUE);
      IF (StrToInt(Copy(TempStr,1,2)) IN [0..23]) AND (StrToInt(Copy(TempStr,4,2)) IN [0..59]) THEN
        HighTime := ((StrToInt(Copy(TempStr,1,2)) * 60) + StrToInt(Copy(TempStr,4,2)))
      ELSE
        HighTime := 0;
    END;
  NL;
  Print('Hours: '+PHours('Always allowed',LowTime,HighTime));
  NL;
  IF PYNQ('Are you sure this is what you want? ',0,FALSE) THEN
    BEGIN
      LoTime := LowTime;
      HiTime := HighTime;
    END;
END;

PROCEDURE MainBBSConfiguration;
VAR
  LineFile: FILE OF LineRec;
  Cmd: Char;
  Changed: Boolean;
BEGIN
  Assign(LineFile,General.DataPath+'NODE'+IntToStr(ThisNode)+'.DAT');
  Reset(LineFile);
  Seek(LineFile,0);
  Read(LineFile,Liner);
  REPEAT
    WITH General DO
      BEGIN
        Abort := FALSE;
        Next := FALSE;
        ConfigHeader('Main BBS Configuration');
        PrintACR(PadLeftStr('^0(^1A^0) BBS name/number   : ^1'+General.BBSName+' ^0(^1'+General.BBSPhone+'^0)',79));
        PrintACR(PadLeftStr('^0(^1B^0) Telnet URL        : ^1'+Liner.NodeTelnetURL,79));
        PrintACR(PadLeftStr('^0(^1C^0) SysOps name       : ^1'+General.SysOpName,39)+
                 PadLeftStr('^0(^1D^0) Renegade Version  : ^1'+General.Version,39));
        PrintACR(PadLeftStr('^0(^1E^0) SysOp chat hours  : ^1'+PHours('Always allowed',
                                                                      General.lLowTime,General.HiTime),39)+
                 PadLeftStr('^0(^1F^0) Min baud hours    : ^1'+PHours('Always allowed',
                                                                      General.MinBaudLowTime,General.MinBaudHiTime),39));
        PrintACR(PadLeftStr('^0(^1G^0) Reg DL hours      : ^1'+PHours('Always allowed',
                                                                      General.DLLowTime,General.DLHiTime),39)+
                 PadLeftStr('^0(^1H^0) Min baud DL hrs   : ^1'+PHours('Always allowed',
                                                                      General.MinBaudDLLowTime,General.MinBaudDLHiTime),39));
        PrintACR(PadLeftStr('^0(^1I^0) BBS Passwords ...',39)+
                 PadLeftStr('^0(^1J^0) Pre-event warning : ^1'+IntToStr(General.EventWarningTime)+' seconds',39));
        PrintACR(PadLeftStr('^0(^1K^0) System Menus ...',39)+
                 PadLeftStr('^0(^1L^0) Bulletin Prefix   : ^1'+General.BulletPrefix,39));
        PrintACR(PadLeftStr('^0(^1M^0) MultiNode support : ^1'+ShowOnOff(General.MultiNode),39)+
                 PadLeftStr('^0(^1N^0) Network mode      : ^1'+ShowOnOff(General.NetworkMode),39));
        NL;
        PrintACR('^0(^10^0) Data files                : ^1'+General.DataPath);
        PrintACR('^0(^11^0) Miscellaneous (Art) files : ^1'+General.MiscPath);
        PrintACR('^0(^12^0) Message area data files   : ^1'+General.MsgPath);
        PrintACR('^0(^13^0) Mail Nodelist (V7) files  : ^1'+General.NodePath);
        PrintACR('^0(^14^0) Log files                 : ^1'+General.LogsPath);
        PrintACR('^0(^15^0) Temporary files           : ^1'+General.TempPath);
        PrintACR('^0(^16^0) Protocol files            : ^1'+General.ProtPath);
        PrintACR('^0(^17^0) Archiver files            : ^1'+General.ArcsPath);
        PrintACR('^0(^18^0) File attachments          : ^1'+General.FileAttachPath);
        PrintACR('^0(^19^0) Text/Language files       : ^1'+General.TextPath);
        NL;
        LOneK('Enter selection [^1A^2-^1N^2,^10^2-^19^2,^1Q^2=^1Quit^2]: ',Cmd,'QABCDEFGHIJKLMN0123456789'^M,TRUE,TRUE);
        CASE Cmd OF
          'A' : BEGIN
                  InputWNWC('%LFNew BBS name: ',BBSName,(SizeOf(BBSName) - 1),Changed);
                  InputFormatted('%LFNew BBS phone number: ',BBSPhone,'###-###-####',FALSE);
                END;
          'B' : InputWN1('%LF^0New Telnet Url:%LF^2: ',Liner.NodeTelnetURL,(SizeOf(Liner.NodeTelnetURL) - 1),
                [InteractiveEdit],Changed);
          'C' : InputWN1('%LFNew SysOp name: ',SysOpName,(SizeOf(SysOpName) - 1),[InterActiveEdit],Changed);
          'D' : lRGLngStr(110,FALSE);
          'E' : IF (InCom) THEN
                  lRGLngStr(111,FALSE)
                ELSE
                  GetTimeRange('%LFDo you want to declare sysop chat hours? ',lLowTime,HiTime);
          'F' : GetTimeRange('%LFDo you want to declare hours people at the minimum baud can logon?',
                MinBaudLowTime,MinBaudHiTime);
          'G' : GetTimeRange('%LFDo you want to declare download hours? ',DLLowTime,DLHiTime);
          'H' : GetTimeRange('%LFDo you want to declare hours people at minimum baud can download? ',
                MinBaudDLLowTime,MinBaudDLHiTime);
          'I' : BEGIN
                  REPEAT
                    ConfigHeader('System Passwords');
                    PrintACR('^0(^1A^0) SysOp Password             : ^1[NOT SHOWN]');
                    PrintACR('^0(^1B^0) New User Password          : ^1[NOT SHOWN]');
                    PrintACR('^0(^1C^0) Min Baud Override Password : ^1[NOT SHOWN]');
                    NL;
                    LOneK('^2System Passwords [^1A^2-^1C^2,<^1CR^2>Quit]: ',Cmd,^M'ABC',TRUE,TRUE);
                    CASE Cmd OF
                      'A' : InputWN1('%LFNew SysOp password: ',SysOpPw,(SizeOf(SysOpPW) - 1),
                            [InterActiveEdit,UpperOnly],Changed);
                      'B' : InputWN1('%LFNew new-user password: ',NewUserPW,(SizeOf(SysOpPW) - 1),
                            [InterActiveEdit,UpperOnly],Changed);
                      'C' : InputWN1('%LFNew minimum baud rate override password: ',MinBaudOverride,(SizeOf(SysOpPW) - 1),
                            [InterActiveEdit,UpperOnly],Changed);
                    END;
                  UNTIL (Cmd = ^M) OR (HangUp);
                  Cmd := #0;
                END;
          'J' : InputByteWOC('%LFNew pre-event warning time',EventWarningTime,[DisplayValue,NumbersOnly],0,255);
          'K' : BEGIN
                  REPEAT
                    ConfigHeader('System Menus');
                    PrintACR('^0(^11^0) Global Commands      : ^1'+IntToStr(General.GlobalMenu));
                    PrintACR('^0(^12^0) Default Start        : ^1'+IntToStr(General.AllStartMenu));
                    PrintACR('^0(^13^0) Shuttle Logon        : ^1'+IntToStr(General.ShuttleLogonMenu));
                    PrintACR('^0(^14^0) New User Information : ^1'+IntToStr(General.NewUserInformationMenu));
                    PrintACR('^0(^15^0) Reading Messages     : ^1'+IntToStr(General.MessageReadMenu));
                    PrintACR('^0(^16^0) Listing Files        : ^1'+IntToStr(General.FileListingMenu));
                    NL;
                    LOneK('^2System Menus [^11^2-^16^2,<^1CR^2>Quit]: ',Cmd,^M'123456',TRUE,TRUE);
                    CASE Cmd OF
                      '1' : FindMenu('%LFMenu for global commands (^10^2=^1None^2)',GlobalMenu,0,NumMenus,Changed);
                      '2' : FindMenu('%LFMenu to start all users at',AllStartMenu,1,NumMenus,Changed);
                      '3' : FindMenu('%LFMenu for shuttle logon (^10^2=^1None^2)',ShuttleLogonMenu,0,NumMenus,Changed);
                      '4' : FindMenu('%LFMenu for new user information',NewUserInformationMenu,1,NumMenus,Changed);
                      '5' : FindMenu('%LFMenu for message read',MessageReadMenu,1,NumMenus,Changed);
                      '6' : FindMenu('%LFMenu for file listing',FileListingMenu,1,NumMenus,Changed);
                    END;
                  UNTIL (Cmd = ^M) OR (HangUp);
                  Cmd := #0;
                END;
          'L' : InputWN1('%LFDefault bulletin prefix: ',BulletPrefix,(SizeOf(BulletPrefix) - 1),
                [InterActiveEdit,UpperOnly],Changed);
          'M' : IF (InCom) THEN
                  lRGLngStr(111,FALSE)
                ELSE
                  BEGIN
                    MultiNode := (NOT MultiNode);
                    SaveGeneral(FALSE);
                    ClrScr;
                    Writeln('Please restart Renegade.');
                    Halt;
                  END;
          'N' : BEGIN
                  NetworkMode := (NOT NetworkMode);
                  IF (NetworkMode) THEN
                    LocalSec := TRUE
                  ELSE
                    LocalSec := PYNQ('%LFDo you want local security to remain on? ',0,FALSE);
                END;
          '0' : InputPath('%LF^0New data files path (^1End with a ^0"^1\^0"):%LF^2: ',DataPath,TRUE,FALSE,Changed);
          '1' : InputPath('%LF^0New miscellaneous files path (^1End with a ^0"^1\^0"):%LF^2: ',MiscPath,TRUE,FALSE,Changed);
          '2' : InputPath('%LF^0New message files path (^1End with a ^0"^1\^0"):%LF^2: ',MsgPath,TRUE,FALSE,Changed);
          '3' : InputPath('%LF^0New nodelist files path (^1End with a ^0"^1\^0"):%LF^2: ',NodePath,TRUE,FALSE,Changed);
          '4' : InputPath('%LF^0New sysop log files path (^1End with a ^0"^1\^0"):%LF^2: ',LogsPath,TRUE,FALSE,Changed);
          '5' : InputPath('%LF^0New temporary files path (^1End with a ^0"^1\^0"):%LF^2: ',TempPath,FALSE,FALSE,Changed);
          '6' : InputPath('%LF^0New protocol files path (^1End with a ^0"^1\^0"):%LF^2: ',ProtPath,TRUE,FALSE,Changed);
          '7' : InputPath('%LF^0New archive files path (^1End with a ^0"^1\^0"):%LF^2: ',ArcsPath,TRUE,FALSE,Changed);
          '8' : InputPath('%LF^0New file attach files path (^1End with a ^0"^1\^0"):%LF^2: ',
                FileAttachPath,TRUE,FALSE,Changed);
          '9' : InputPath('%LF^0New string files path (^1End with a ^0"^1\^0"):%LF^2: ',TextPath,TRUE,FALSE,Changed);
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  Seek(LineFile,0);
  Write(LineFile,Liner);
  Close(LineFile);
  LastError := IOResult;
END;
END.