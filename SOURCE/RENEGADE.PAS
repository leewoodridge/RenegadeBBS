{$M 35500,0,131072}

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

{$A+} { Align data for faster execution }
{$B-} { Shortcut boolean evaluation }
{$D+} { No debug info }
{$E-} { No math-co library }
{$F+} { Force far calls }
{$I-} { Disable I/O check }
{$L+} { Local symbols }
{$N-} { No math-co use }
{$P+} { Allow open strings }
{$O+} { Use overlays }
{$Q-} { No overflow check }
{$R-} { No range check }
{$S-} { Don't check stack usage }
{$V-} { Variable string length allowed }
{$X+} { Allow extended syntax }

{
 02/24/2022 - Exodus added command line parameter help
}

PROGRAM Renegade;

USES
  Boot,
  Common,
  Common1,
  CRT,
  DOS,
  Events,
  File0,
  File13,
  File7,
  Logon,
  Mail0,
  Maint,
  Menus,
  Menus2,
  MsgPack,
  MyIO,
  NewUsers,
  Offline,
{ OneLiner, }
  Overlay,
  TimeFunc,
  WFCMenu;

{$O Archive1 } {$O Archive2 } {$O Archive3 } {$O ArcView  } {$O AutoMsg  } {$O BBSList   } {$O Boot     } {$O Bulletin }
{$O CUser    } {$O Chat     } {$O Common1  } {$O Common2  } {$O Common3  } {$O Common4   } {$O Doors    } {$O EMail    }
{$O Events   } {$O ExecBat  } {$O File0    } {$O File1    } {$O File2    } {$O File4     } {$O File5    } {$O File6    }
{$O File7    } {$O File8    } {$O File9    } {$O File10   } {$O File11   } {$O File12    } {$O File13   } {$O File14   }
{$O Logon    } {$O Mail0    } {$O Mail1    } {$O Mail2    } {$O Mail3    } {$O Mail4     } {$O Maint    } {$O Menus2   }
{$O Menus3   } {$O MiscUser } {$O MsgPack  } {$O MultNode } {$O MyIO     } {$O NewUsers  } {$O Nodelist } {$O Offline  }
{$O OneLiner } {$O Script   } {$O ShortMsg } {$O Stats    } {$O SysOp1   } {$O SysOp2    } {$O SysOp2A  } {$O SysOp2B  }
{$O SysOp2C  } {$O SysOp2D  } {$O SysOp2E  } {$O SysOp2F  } {$O SysOp2G  } {$O SysOp2H   } {$O SysOp2I  } {$O SysOp2J  }
{$O SysOp2K  } {$O SysOp2L  } {$O SysOp2M  } {$O SysOp2O  } {$O SysOp3   } {$O SysOp4    } {$O SysOp5   } {$O SysOp6   }
{$O SysOp7   } {$O SysOp7M  } {$O SysOp8   } {$O SysOp9   } {$O SysOp10  } {$O SysOp11   } {$O SysOp12  } {$O TimeBank }
{$O TimeFunc } {$O Vote     } {$O WFCMenu  }

CONST
  NeedToHangUp: Boolean = FALSE;
VAR
  ExitSave: Pointer;
  GeneralF: FILE OF GeneralRecordType;
  ByteFile: FILE OF Byte;
  TextFile: Text;
  S: Astr;
  Counter: Byte;
  Counter1: Integer;

PROCEDURE ErrorHandle;
VAR
  TextFile: Text;
  S: STRING[50];
BEGIN
  ExitProc := ExitSave;
  IF (ErrorAddr <> NIL) THEN
    BEGIN
      CHDir(StartDir);
      IF (General.Multinode) AND (ThisNode > 0) THEN
        Assign(SysOpLogFile,TempDir+'TEMPLOG.'+IntToStr(ThisNode) )
      ELSE
        Assign(SysOpLogFile,General.LogsPath+'SYSOP.LOG');
      Append(SysOpLogFile);
      S := '^8*>>^8 Runtime error '+IntToStr(ExitCode)+' at '+DateStr+' '+TimeStr+ '^8 <<*^1'+' (Check ERROR.LOG)';
      WriteLn(SysOpLogFile,S);
      Flush(SysOpLogFile);
      Close(SysOpLogFile);
      IF (TextRec(Trapfile).Mode = FMOutPut) THEN
        BEGIN
          WriteLn(Trapfile,S);
          Flush(Trapfile);
          Close(Trapfile);
        END;
      Assign(TextFile,'ERROR.LOG');
      Append(TextFile);
      IF (IOResult <> 0) THEN
        ReWrite(TextFile);
      WriteLn(TextFile,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
      WriteLn(TextFile,'Critical error Log file - Contains screen images at instant of error.');
      WriteLn(TextFile,'The "ฒ" character shows the cursor position at time of error.');
      WriteLn(TextFile,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
      WriteLn(TextFile);
      WriteLn(TextFile);
      WriteLn(TextFile,'ฏ>ฏ error #'+IntToStr(ExitCode)+' at '+DateStr+' '+TimeStr+' version: '+General.Version);
      IF (UserOn) THEN
        BEGIN
          Write(TextFile,'ฏ>ฏ User "'+AllCaps(ThisUser.name)+' #'+IntToStr(UserNum)+'" was on ');
          IF (ComPortSpeed > 0) THEN
            WriteLn(TextFile,'at '+IntToStr(ActualSpeed)+ 'baud')
          ELSE
            WriteLn(TextFile,'Locally');
        END;
      Close(TextFile);
      ScreenDump('ERROR.LOG');
      Assign(TextFile,'CRITICAL.ERR');
      ReWrite(TextFile);
      Close(TextFile);
      SetFAttr(TextFile,DOS.Hidden);
      Print('^8* SYSTEM MALFUNCTION *');
      LoadNode(ThisNode);
      Noder.Status := [];
      Noder.User := 0;
      SaveNode(ThisNode);
      Com_Flush_Send;
      DTR(FALSE);
      Com_DeInstall;
      Halt(ExitErrors);
    END;
END;

PROCEDURE ReadP;
VAR
  d: astr;
  Counter: Integer;
  FUNCTION SC(s: astr; i: Integer): Char;
  BEGIN
    SC := UpCase(s[i]);
  END;
BEGIN
  Reliable := FALSE;
  Telnet := FALSE;
  CallerIDNumber := '';
  Counter := 0;
  WHILE (Counter < ParamCount) DO
  BEGIN
    Inc(Counter);
    IF ((SC(ParamStr(Counter),1) = '-') OR (SC(ParamStr(Counter),1) = '/')) THEN
      CASE SC(ParamStr(Counter),2) OF
          '?' : BEGIN { Command line parameters help }
                  ClrScr;
                  TextColor(LightGray);
                  TextBackground(Black);
                  WriteLn('ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
                  WriteLn('บ         Renegade BBS Supports the Following Command-Line Parameters         บ');
                  WriteLn('บอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บ            ๚ LOADING ๚               บ               ๚ EXIT ๚               บ');
                  WriteLn('บอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บ  -L  : Logon Locally to Renegade     บ  -Q  : Exit to DOS After Hangup      บ');
                  WriteLn('บ                                      บ  -X# : Log User Off in # Minutes     บ');
                  WriteLn('บ  -N# : Specify Which Node # to Load  บ -EE# : Critical Errorlevel           บ');
                  WriteLn('บ  -T  : If Using Net2BBS              บ -EN# : Normal Errorlevel             บ');
                  WriteLn('บ  -TC : If Using NetSerial or COM/IP  บออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บ  -B# : Force Baudrate #####          บ               ๚ QWK ๚                บ');
                  WriteLn('บ  -D  : Load Overlay File to DISK     บออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บ                                      บ  -M# : Create QWK Packet For User #  บ');
                  WriteLn('บออออออออออออออออออออออออออออออออออออออบ  -U# : Upload REP Packet For User #  บ');
                  WriteLn('บ  ๚ OPTIONAL CONNECTION PARAMETERS ๚  บออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บออออออออออออออออออออออออออออออออออออออบ           ๚ MAINTENANCE ๚            บ');
                  WriteLn('บ  -H# : Specify Socket Handle         บออออออออออออออออออออออออออออออออออออออบ');
                  WriteLn('บ  -C  : Reliable Connection Flag      บ  -F  : Import FILES.BBS              บ');
                  WriteLn('บ  -ID#: Pass Caller-ID Info           บ  -P  : Pack Message Bases            บ');
                  WriteLn('บ  -IP#: Pass Caller-IP Info           บ  -S  : Sort File Areas               บ');
                  WriteLn('ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
                          {---------------------------------------|----------------------------------------} {80 CHARS}
                  Halt;
                END;
        {'5' : TextMode(259);}
        'B' : AnswerBaud := StrToInt(Copy(ParamStr(Counter),3,255));
        'C' : Reliable := (Pos(AllCaps(Liner.Reliable),AllCaps(ParamStr(Counter))) > 0);
        'D' : OvrUseEms := FALSE;
        'E' : IF (Length(ParamStr(Counter)) >= 4) THEN
              BEGIN
                d := AllCaps(ParamStr(Counter));
                CASE d[3] OF
                  'E' : ExitErrors := StrToInt(Copy(d,4,(Length(d) - 3)));
                  'N' : ExitNormal := StrToInt(Copy(d,4,(Length(d) - 3)));
                END;
              END;
        'H' : SockHandle := Copy(ParamStr(Counter),3,255);
        'I' : BEGIN
                CASE SC(ParamStr(Counter),3) OF
                 'D' : CallerIDNumber := Copy(ParamStr(Counter),4,255);
                 'P' : CallerIDNumber := Copy(ParamStr(Counter),4,255);
               END;
              END;
        'L' : LocalIOOnly := TRUE;
        'M' : BEGIN
                MakeQWKFor := StrToInt(Copy(ParamStr(Counter),3,255));
                LocalIOOnly := TRUE;
              END;
        'N' : ThisNode := StrToInt(Copy(ParamStr(Counter),3,255));
        'P' : BEGIN
                PackBasesOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'Q' : QuitAfterDone := TRUE;
        'S' : BEGIN
                SortFilesOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'F' : BEGIN
                FileBBSOnly := TRUE;
                LocalIOOnly := TRUE;
              END;
        'T' : BEGIN
                IF (SC(ParamStr(Counter),3) <> 'C') THEN
                  HangUpTelnet := TRUE;
                Telnet := TRUE;
              END;
        'U' : BEGIN
                UpQWKFor := StrToInt(Copy(ParamStr(Counter),3,255));
                LocalIOOnly := TRUE;
              END;
        'X' : ExtEventTime := StrToInt(Copy(ParamStr(Counter),3,255));
      END;
  END;
  AllowAbort := TRUE;
END;

BEGIN
  ClrScr;
  TextColor(LightGray);
  WriteLn('  ____                              _     ');
  WriteLn(' |  _ \___ __ _  ___  __ _  __ _ __| |___ ');
  WriteLn(' |    / -_)  ` \/ -_)/ _` |/ _` / _` / -_)');
  WriteLn(' |__|_\___|__|_|\___|\__, |\__,_\__,_\___|');
  WriteLn(' ------------------- |___/ ---------------');
  WriteLn(' B U L L E T I N   B O A R D   S Y S T E M');
  WriteLn(' -----------------------------------------');

  GetIntVec($14,Interrupt14);
  FileMode := 66;
  ExitSave := ExitProc;
  ExitProc := @ErrorHandle;
  DirectVideo := FALSE;
  CheckSnow := FALSE;
  UserOn := FALSE;
  UserNum := 0;
  GetDir(0,StartDir);

  DATFilePath := GetEnv('RENEGADE');
  IF (DATFilePath <> '') THEN
    DATFilePath := BSlash(DATFilePath,TRUE);

  Write(' - Initializing RENEGADE.DAT ... ');
  Assign(ByteFile,DATFilePath+'RENEGADE.DAT');
  Reset(ByteFile);
  LastError := IOResult;
  IF (LastError <> 0) THEN
    BEGIN
      WriteLn('[ERROR] '+ErrorCodeHelp(LastError));
      Halt;
    END
  ELSE
    BEGIN
      WriteLn('Done!');
    END;
  Counter := 0;
  Seek(ByteFile,FileSize(ByteFile));
  WHILE FileSize(ByteFile) < SizeOf(General) DO
    Write(ByteFile,Counter);
  Close(ByteFile);

  Assign(GeneralF,DATFilePath+'RENEGADE.DAT');
  Reset(GeneralF);
  Read(GeneralF,General);
  Close(GeneralF);

  ReadP; { Read command-line parameters }

  Write(' - Initializing RENEGADE.OVR ... ');
  OvrFileMode := 0; { Read only }
  OvrInit('RENEGADE.OVR');
  IF (OvrResult <> OvrOK) THEN
    BEGIN
      CASE OvrResult OF
        OvrError    : WriteLn('[ERROR] Overlay manager error');
        OvrNotFound : WriteLn('[ERROR] Overlay file not found');
      END;
      Halt;
    END
  ELSE
    BEGIN
      WriteLn('Done!'); { Initialized overlays }
      IF (General.UseEMS) AND (OvrUseEMS) THEN
        BEGIN
          Write(' - Attempting to load overlays ('+FormatNumber(OvrGetBuf)+' Bytes) into EMS memory ... ');
          OvrInitEMS;
          IF (OvrResult = OvrOK) THEN
            BEGIN
              WriteLn('Done!');
              OverLayLocation := 1; { EMS }
            END
          ELSE
            BEGIN { Failed to load overlays to EMS }
              WriteLn;
              CASE OvrResult OF
              { OvrError       : WriteLn('Overlay manager error');
                OvrNotFound    : WriteLn('Overlay file not found'); }
                OvrNoMemory    : WriteLn('[ERROR] Not enough memory for overlay buffer');
                OvrIOError     : WriteLn('[ERROR] Overlay file I/O error');
                OvrNoEMSDriver : WriteLn('[ERROR] EMS driver not installed');
                OvrNoEMSMemory : WriteLn('[ERROR] Not enough EMS memory');
              END;
              OverLayLocation := 0; { Disk }
            END;
        END;
    END;

  Init;

  MaxDisplayRows := (Hi(WindMax) + 1); {25}
  MaxDisplayCols := (Lo(WindMax) + 1); {80}
  ScreenSize := 2 * MaxDisplayRows * MaxDisplayCols;
  IF (ScreenSize > 8000) THEN
    ScreenSize := 8000;

  IF (FileBBSOnly) OR (PackBasesOnly) OR (SortFilesOnly) OR (MakeQWKFor > 0) OR (UpQWKFor > 0) THEN
    BEGIN
      WFCMDefine;
      TempPause := FALSE;
      IF (MakeQWKFor > 0) THEN
        BEGIN
          UserNum := MakeQWKFor;
          LoadURec(ThisUser,MakeQWKFor);
          NewFileDate := ThisUser.LastOn;
          Downloadpacket;
          SaveURec(ThisUser,MakeQWKFor);
        END;
      IF (UpQWKFor > 0) THEN
        BEGIN
          UserNum := UpQWKFor;
          LoadURec(ThisUser,UpQWKFor);
          Uploadpacket(TRUE);
          SaveURec(ThisUser,UpQWKFor);
        END;
      IF (PackBasesOnly) THEN
        DoShowPackMessageAreas;
      IF (SortFilesOnly) THEN
        Sort;
      IF (FileBBSOnly) THEN
        CheckFilesBBS;
      Halt(0);
    END;

  GetMem(MemCmd,MaxCmds * SizeOf(MemCmdRec));

  REPEAT
    IF (NeedToHangUp) THEN
      BEGIN
        NeedToHangUp := FALSE;
        DoPhoneHangUp(FALSE);
      END;
    WFCMenus;
    UserOn := FALSE;
    UserNum := 0;
    IF (NOT DoneDay) THEN
      BEGIN
        lStatus_Screen(100,'User logging in.',FALSE,S);
        LastScreenSwap := 0;
        IF (GetUser) THEN
          NewUser;
        IF (NOT HangUp) THEN
          BEGIN
            NumBatchDLFiles := 0;
            NumBatchULFiles := 0;
            BatchDLPoints := 0;
            BatchDLSize := 0;
            BatchDLTime := 0;
            LogonMaint;
            IF (NOT HangUp) THEN
              BEGIN
                NewFileDate := ThisUser.LastOn;
                IF (MsgAreaAC(ThisUser.LastMsgArea)) THEN
                  MsgArea := ThisUser.LastMsgArea
                ELSE
                  BEGIN
                    FOR Counter := 1 TO NumMsgAreas DO
                      IF (MsgAreaAC(Counter)) THEN
                        BEGIN
                          MsgArea := Counter;
                          Counter := NumMsgAreas;
                        END;
                  END;
                IF (FileAreaAC(ThisUser.LastFileArea)) THEN
                  FileArea := ThisUser.LastFileArea
                ELSE
                  BEGIN
                    FOR Counter := 1 TO NumFileAreas DO
                      IF (FileAreaAC(Counter)) THEN
                        BEGIN
                          FileArea := Counter;
                          Counter := NumFileAreas;
                        END;
                  END;
                NewCompTables;
                MenuStackPtr := 0;
                FOR Counter := 1 TO MaxMenus DO
                  MenuStack[Counter] := 0;
                IF (Novice in ThisUser.ACFlags) THEN
                  CurHelpLevel := 2
                ELSE
                  CurHelpLevel := 1;
                GlobalCmds := 0;
                NumCmds := 0;
                CurMenu := 0;
                FallBackMenu := 0;
                IF (General.GlobalMenu <> 0) THEN
                  BEGIN
                    CurMenu := General.GlobalMenu;
                    LoadMenu;
                    GlobalCmds := NumCmds;
                  END;
                IF (ThisUser.UserStartMenu = 0) THEN
                  CurMenu := General.AllStartMenu
                ELSE
                  CurMenu := ThisUser.UserStartMenu;
                LoadMenu;
                AutoExecCmd('FIRSTCMD');
              END;
            WHILE (NOT HangUp) DO
              MenuExec;
          END;
        IF (QuitAfterDone) THEN
          BEGIN
            IF (ExitErrorLevel = 0) THEN
              ExitErrorLevel := ExitNormal;
            HangUp := TRUE;
            DoneDay := TRUE;
            NeedToHangUp := TRUE;
          END;
        LogOffMaint;
        IF (General.Multinode) THEN
          BEGIN
            Assign(TextFile,General.LogsPath+'SYSOP.LOG');
            IF Exist(General.LogsPath+'SYSOP.LOG') THEN
              Append(TextFile)
            ELSE
              ReWrite(TextFile);
            Reset(SysOpLogFile);
            WHILE NOT EOF(SysOpLogFile) DO
              BEGIN
                ReadLn(SysOpLogFile,S);
                WriteLn(TextFile,S);
              END;
            Close(SysOpLogFile);
            Close(TextFile);
            ReWrite(SysOpLogFile);
            Close(SysOpLogFile);
            LastError := IOResult;
          END;
        IF (Com_Carrier) AND (NOT DoneDay) THEN
          IF (InCom) THEN
            NeedToHangUp := TRUE;
      END;
  UNTIL (DoneDay);

  SL1('');
  SL1('^0Renegade '+General.Version+' Node ^1'+IntToStr(ThisNode)+'^0 Shut Down On ^1'+Dat+'^0'); {LeeW: Added}
  SL1('');

  Window(1,1,MaxDisplayCols,MaxDisplayRows);
  TextBackGround(0);
  TextColor(7);
  ClrScr;

  IF (NeedToHangUp) THEN
    BEGIN
      Write(' - Disconnecting ... ');
      IF (HangUpTelnet) THEN
        DoTelnetHangUp(TRUE);
      IF (NOT HangUpTelnet) THEN
        DoPhoneHangUp(FALSE);
      WriteLn('Done!');
    END;

  Write(' - Releasing memory ... ');
  FreeMem(MemCmd,MaxCmds * SizeOf(MemCmdRec));
  IF (MCIBuffer <> NIL) THEN
    Dispose(MCIBuffer);
  IF (MemEventArray[NumEvents] <> NIL) THEN
    FOR Counter1 := 1 TO NumEvents DO
      IF (MemEventArray[Counter1] <> NIL) THEN
        Dispose(MemEventArray[Counter1]);
  WriteLn('Done!');


  IF (General.Multinode) THEN
    BEGIN
      Write(' - Merging log files ... ');
      Assign(TextFile,General.LogsPath+'SYSOP.LOG');
      IF Exist(General.LogsPath+'SYSOP.LOG') THEN
        Append(TextFile)
      ELSE
        ReWrite(TextFile);
      Reset(SysOpLogFile);
      WHILE NOT EOF(SysOpLogFile) DO
        BEGIN
          ReadLn(SysOpLogFile,S);
          WriteLn(TextFile,S);
        END;
      Close(SysOpLogFile);
      Close(TextFile);
      ReWrite(SysOpLogFile);
      Close(SysOpLogFile);
      LastError := IOResult;
      {/}
      Kill(TempDir+'TEMPLOG.'+IntToStr(ThisNode));
      WriteLn('Done!');
    END;

  IF (NewEchoMail) AND (ExitErrorLevel = 0) THEN {LeeW: Shouldn't this check against ExitNormal instead of 0?}
    ExitErrorLevel := 2;

  Write(' - Resetting node status ... ');
  LoadNode(ThisNode);
  Noder.Status := [];
  SaveNode(ThisNode);
  WriteLn('Done!');

  Write(' - Purging temporary directory ... ');
  PurgeDir(TempDir,FALSE);
  IF (LastError = 0) THEN
    WriteLn('Done!')
  ELSE
    WriteLn('Failure!'); { LeeW: Give more info }

  Write(' - Unloading communications driver ... ');
  Com_DeInstall;
  WriteLn('Done!');

  WriteLn('');
  WriteLn('Exiting with errorlevel ',ExitErrorLevel);
  WriteLn('');
  {read(s);}
  Halt(ExitErrorLevel);
END.
