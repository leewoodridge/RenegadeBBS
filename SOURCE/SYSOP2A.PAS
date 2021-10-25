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
        PrintACR('^0A. BBS name/number  : ^1'+General.BBSName+' ^0(^1'+General.BBSPhone+'^0)');
        PrintACR('^0B. Telnet Url       : ^1'+Liner.NodeTelnetURL);
        PrintACR(PadLeftStr('^0C. SysOps name      : ^1'+General.SysOpName,39)+'^0D. Renegade Version   : ^1'+General.Version);
        PrintACR(PadLeftStr('^0E. SysOp chat hours : ^1'+PHours('Always allowed',General.lLowTime,General.HiTime),39)+
                    '^0F. Minimum baud hours : '+PHours('Always allowed',General.MinBaudLowTime,General.MinBaudHiTime));
        PrintACR(PadLeftStr('^0G. Regular DL hours : ^1'+PHours('Always allowed',General.DLLowTime,General.DLHiTime),39)+
                    '^0H. Minimum baud DL hrs: ^1'+PHours('Always allowed',General.MinBaudDLLowTime,General.MinBaudDLHiTime));
        PrintACR(PadLeftStr('^0I. BBS Passwords    :',39)+
         '^0J. Pre-event warning  : ^1'+IntToStr(General.EventWarningTime)+' seconds');
        PrintACR(PadLeftStr('^0K. System Menus     :',39)+'^0L. Bulletin Prefix    : ^1'+General.BulletPrefix);
        PrintACR(PadLeftStr('^0M. MultiNode support: ^1'+ShowOnOff(General.MultiNode),39)+
         '^0N. Network mode     : ^1'+ShowOnOff(General.NetworkMode));
        NL;
        PrintACR('^00. Main data files dir.    : ^1'+General.DataPath);
        PrintACR('^01. Miscellaneous Files dir.: ^1'+General.MiscPath);
        PrintACR('^02. Message file storage dir: ^1'+General.MsgPath);
        PrintACR('^03. Nodelist (Version 7) dir: ^1'+General.NodePath);
        PrintACR('^04. Log files/trap files dir: ^1'+General.LogsPath);
        PrintACR('^05. Temporary directory     : ^1'+General.TempPath);
        PrintACR('^06. Protocols directory     : ^1'+General.ProtPath);
        PrintACR('^07. Archivers directory     : ^1'+General.ArcsPath);
        PrintACR('^08. File attach directory   : ^1'+General.FileAttachPath);
        PrintACR('^09. Strings directory       : ^1'+General.lMultPath);
        NL;
        Prt('Enter selection [^1A^2-^1N^2,^10^2-^19^2,^1Q^2=^1Quit^2]: ');
        OneK(Cmd,'QABCDEFGHIJKLMN0123456789'^M,TRUE,TRUE);
        CASE Cmd OF
          'A' : BEGIN
                  InputWNWC('%LFNew BBS name: ',BBSName,(SizeOf(BBSName) - 1),Changed);
                  InputFormatted('%LFNew BBS phone number: ',BBSPhone,'###-###-####',FALSE);
                END;
          'B' : InputWN1('%LF^0New Telnet Url:%LF^2: ',Liner.NodeTelnetURL,(SizeOf(Liner.NodeTelnetURL) - 1),
                [InteractiveEdit],Changed);
          'C' : InputWN1('%LFNew SysOp name: ',SysOpName,(SizeOf(SysOpName) - 1),[InterActiveEdit],Changed);
          'D' : RGNoteStr(0,FALSE);
          'E' : IF (InCom) THEN
                  RGNoteStr(1,FALSE)
                ELSE
                  GetTimeRange('%LFDo you want to declare sysop chat hours? @',lLowTime,HiTime);
          'F' : GetTimeRange('%LFDo you want to declare hours people at the minimum baud can logon?',
                MinBaudLowTime,MinBaudHiTime);
          'G' : GetTimeRange('%LFDo you want to declare download hours? @',DLLowTime,DLHiTime);
          'H' : GetTimeRange('%LFDo you want to declare hours people at minimum baud can download? ',
                MinBaudDLLowTime,MinBaudDLHiTime);
          'I' : BEGIN
                  REPEAT
                    PrintACR('%CL^1System Passwords:^0');
                    PrintACR('^0A. SysOp password        : ^1[NOT SHOWN]');
                    PrintACR('^0B. New user password     : ^1[NOT SHOWN]');
                    PrintACR('^0C. Baud override password: ^1[NOT SHOWN]');
                    OneK(Cmd,^M'ABC',TRUE,TRUE);
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
          'J' : InputByteWOC('%LFNew pre-event warning time@',EventWarningTime,[DisplayValue,NumbersOnly],0,255);
          'K' : BEGIN
                  REPEAT
                    PrintACR('%CL^1System Menus:^0');
                    PrintACR('^01. Global       : ^1'+IntToStr(General.GlobalMenu));
                    PrintACR('^02. All Start    : ^1'+IntToStr(General.AllStartMenu));
                    PrintACR('^03. Shutle logon : ^1'+IntToStr(General.ShuttleLogonMenu));
                    PrintACR('^04. New user info: ^1'+IntToStr(General.NewUserInformationMenu));
                    PrintACR('^05. Message Read : ^1'+IntToStr(General.MessageReadMenu));
                    PrintACR('^06. File List    : ^1'+IntToStr(General.FileListingMenu));
                    Prt('Enter selection [^11^2-^16^2,^1<CR>^2=^1Quit^2]: ');
                    OneK(Cmd,^M'123456',TRUE,TRUE);
                    CASE Cmd OF
                      '1' : FindMenu('%LFMenu for global commands (^10^2=^1None^2)@',GlobalMenu,0,NumMenus,Changed);
                      '2' : FindMenu('%LFMenu to start all users at@',AllStartMenu,1,NumMenus,Changed);
                      '3' : FindMenu('%LFMenu for shuttle logon (^10^2=^1None^2)',ShuttleLogonMenu,0,NumMenus,Changed);
                      '4' : FindMenu('%LFMenu for new user information@',NewUserInformationMenu,1,NumMenus,Changed);
                      '5' : FindMenu('%LFMenu for message read@',MessageReadMenu,1,NumMenus,Changed);
                      '6' : FindMenu('%LFMenu for file listing@',FileListingMenu,1,NumMenus,Changed);
                    END;
                  UNTIL (Cmd = ^M) OR (HangUp);
                  Cmd := #0;
                END;
          'L' : InputWN1('%LFDefault bulletin prefix: ',BulletPrefix,(SizeOf(BulletPrefix) - 1),
                [InterActiveEdit,UpperOnly],Changed);
          'M' : IF (InCom) THEN
                  RGNoteStr(1,FALSE)
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
                    LocalSec := PYNQ('%LFDo you want local security to remain on? @',0,FALSE);
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
          '9' : InputPath('%LF^0New string files path (^1End with a ^0"^1\^0"):%LF^2: ',lMultPath,TRUE,FALSE,Changed);
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
  Seek(LineFile,0);
  Write(LineFile,Liner);
  Close(LineFile);
  LastError := IOResult;
END;
END.