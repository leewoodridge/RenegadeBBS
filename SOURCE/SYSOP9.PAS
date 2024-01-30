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
     - Removed all strings from FAE language file and the proc
     - Removed all MCIs from FAEMCI and the proc
     - 12/8/2021 deleting file area reports correct name/sysop log
     - file area list prints to bottom of pagelen now
     - 't' to toggle display is now working again
     - 03/09/2023 error messages now using messages proc
     - aesthetic changes
 01/29/2024 - Prompt,Help aesthetics
    [TO DO]
     - aesthetics
     - test fa list longer than 1 page for pagination
}

UNIT SysOp9; { File Area Editor }

INTERFACE

PROCEDURE FileAreaEditor;

IMPLEMENTATION

USES
  Common,
  File0,
  File2,
  SysOp2K,
  SysOp2; { ConfigHeader/HL }

PROCEDURE FileAreaEditor;
TYPE
  MCIVarRecord = RECORD
    OldPath,
    NewPath: AStr;
    Drive: Char;
    FirstRecNum,
    LastRecNum,
    RecNumToEdit: Integer;
  END;

CONST
  DisplayType: Byte = 1;

VAR
  TempMemFileArea: FileAreaRecordType;
  MCIVars: MCIVarRecord;
  Cmd: Char;
  RecNumToList: Integer;
  SaveTempPause: Boolean;

  FUNCTION DisplayFAFlags(FAFlags: FAFlagSet; C1,C2: Char): AStr;
  VAR
    FAFlagT: FileAreaFlagType;
    DisplayStr: AStr;
  BEGIN
    DisplayStr := '';
    FOR FAFlagT := FANoRatio TO FANoDupeCheck DO
    BEGIN
      IF (FAFlagT IN FAFlags) THEN
        DisplayStr := DisplayStr + '^'+C1+Copy('NUISGCDP',(Ord(FAFlagT) + 1),1)
      ELSE
        DisplayStr := DisplayStr + '^'+C2+'-'
    END;
    DisplayFAFlags := DisplayStr+'^1'; {LeeW: Reset color}
  END;

  PROCEDURE ToggleFAFlag(FAFlagT: FileAreaFlagType; VAR FAFlags: FAFlagSet);
  BEGIN
    IF (FAFlagT IN FAFlags) THEN
      Exclude(FAFlags,FAFlagT)
    ELSE
      Include(FAFlags,FAFlagT);
  END;

  PROCEDURE ToggleFAFlags(C: Char; VAR FAFlags: FAFlagSet; VAR Changed: Boolean);
  VAR
    SaveFAFlags: FAFlagSet;
  BEGIN
    SaveFAFlags := FAFlags;
    CASE C OF
      'N' : ToggleFAFlag(FANoRatio,FAFlags);
      'U' : ToggleFAFlag(FAUnHidden,FAFlags);
      'I' : ToggleFAFlag(FADirDLPath,FAFlags);
      'S' : ToggleFAFlag(FAShowName,FAFlags);
      'G' : ToggleFAFlag(FAUseGIFSpecs,FAFlags);
      'C' : ToggleFAFlag(FACDRom,FAFlags);
      'D' : ToggleFAFlag(FAShowDate,FAFlags);
      'P' : ToggleFAFlag(FANoDupeCheck,FAFlags);
    END;
    IF (FAFlags <> SaveFAFlags) THEN
      Changed := TRUE;
  END;

  PROCEDURE InitFileAreaVars(VAR MemFileArea: FileAreaRecordType);
  BEGIN
    FillChar(MemFileArea,SizeOf(MemFileArea),0);
    WITH MemFileArea DO
    BEGIN
      AreaName := '<< New File Area >>';
      FileName := 'NEWDIR';
      DLPath := StartDir[1]+':\';
      ULPath := DLPath;
      MaxFiles := 2000;
      Password := '';
      ArcType := 0;
      CmtType := 0;
      ACS := '';
      ULACS := '';
      DLACS := '';
      FAFlags := [];
    END;
  END;

  { --- }

  PROCEDURE ChangeFileAreaDrive(MCIVars1: MCIVarRecord);
  VAR
    RecNum: Integer;
  BEGIN
    IF (NumFileAreas = 0) THEN
      Messages(4,0,'file areas') { "No file areas exist!" } (*Prompt('%LFNo file areas exist!%LF%PA')*)
    ELSE
    BEGIN
      MCIVars1.FirstRecNum := -1;
      InputInteger('%LFFile area to start at? ',MCIVars1.FirstRecNum,[NumbersOnly],1,NumFileAreas,Changed);
      IF (MCIVars1.FirstRecNum >= 1) AND (MCIVars1.FirstRecNum <= NumFileAreas) THEN
      BEGIN
        MCIVars1.LastRecNum := -1;
        InputInteger('%LFFile area to end at? ',MCIVars1.LastRecNum,[NumbersOnly],1,NumFileAreas,Changed);
        IF (MCIVars1.LastRecNum >= 1) AND (MCIVars1.LastRecNum <= NumFileAreas) THEN
        BEGIN
          IF (MCIVars1.FirstRecNum > MCIVars1.LastRecNum) OR (MCIVars1.LastRecNum < MCIVars1.FirstRecNum) THEN
            Messages(8,0,'') { "No commands exist!" }(*Prompt('%LF^8Invalid record number order!^0%LF%PA')*)
          ELSE
          BEGIN
            InputChar('%LFChange to which drive? (^1A^2-^1Z^2): ',MCIVars1.Drive,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M,[CapAll]);
            ChDir(MCIVars1.Drive+':');
            IF (IOResult <> 0) THEN
              Messages(7,0,'') (* Prompt('%LF^8Invalid drive!^0%LF%PA') {LeeW: Messages} *)
            ELSE
            BEGIN
              ChDir(StartDir);
              Prompt('%LFUpdating the drive for file area '+IntToStr(MCIVars1.FirstRecNum)+
              ' to '+IntToStr(MCIVars1.LastRecNum)+'...');
              Reset(FileAreaFile);
              FOR RecNum := MCIVars1.FirstRecNum TO MCIVars1.LastRecNum DO
              BEGIN
                Seek(FileAreaFile,(RecNum - 1));
                Read(FileAreaFile,MemFileArea);
                MemFileArea.ULPath[1] := MCIVars1.Drive;
                MemFileArea.DLPath[1] := MCIVars1.Drive;
                Seek(FileAreaFile,(RecNum - 1));
                Write(FileAreaFile,MemFileArea);
              END;
              Close(FileAreaFile);
              LastError := IOResult;
              Prompt('Done!');
              SysOpLog('* Changed file areas: '+IntToStr(MCIVars1.FirstRecNum)+
              ' - '+IntToStr(MCIVars1.LastRecNum)+' to '+MCIVars1.Drive+':\');
            END;
          END;
        END;
      END;
    END;
  END;

{ --- }

  PROCEDURE DeleteFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    RecNum,
    RecNumToDelete: Integer;
    Ok,
    OK1,
    Ok2: Boolean;
  BEGIN
    IF (NumFileAreas = 0) THEN
      Messages(4,0,'file areas') { "No file areas exist!" } (*Prompt('%LFNo file areas exist!%LF%PA')*)
    ELSE
    BEGIN
      RecNumToDelete := -1;
      InputInteger('%LFFile area to delete? ',RecNumToDelete,[NumbersOnly],1,NumFileAreas,Changed);
      IF (RecNumToDelete >= 1) AND (RecNumToDelete <= NumFileAreas) THEN
      BEGIN
        Reset(FileAreaFile);
        Seek(FileAreaFile,(RecNumToDelete - 1));
        Read(FileAreaFile,TempMemFileArea1);
        Close(FileAreaFile);
        LastError := IOResult;
        Prompt('%LFFile area: '+TempMemFileArea1.AreaName); {LeeW: Was reporting wrong area name, was MemFileArea}

        IF PYNQ('%LFAre you sure you want to delete it?',0,FALSE) THEN
        BEGIN
          Prompt('%LF[> Deleting file area ...');
          Dec(RecNumToDelete);
          Reset(FileAreaFile);
          IF (RecNumToDelete >= 0) AND (RecNumToDelete <= (FileSize(FileAreaFile) - 2)) THEN
            FOR RecNum := RecNumToDelete TO (FileSize(FileAreaFile) - 2) DO
            BEGIN
              Seek(FileAreaFile,(RecNum + 1));
              Read(FileAreaFile,MemFileArea);
              Seek(FileAreaFile,RecNum);
              Write(FileAreaFile,MemFileArea);
            END;
          Seek(FileAreaFile,(FileSize(FileAreaFile) - 1));
          Truncate(FileAreaFile);
          Close(FileAreaFile);
          LastError := IOResult;
          Dec(NumFileAreas);
          SysOpLog('* Deleted file area: '+TempMemFileArea1.AreaName); {LeeW: Again, reporting wrong name}
          Ok := TRUE;
          Ok1 := TRUE;
          OK2 := TRUE;
          Reset(FileAreaFile);
          FOR RecNum := 1 TO FileSize(FileAreaFile) DO
          BEGIN
            Seek(FileAreaFile,(RecNum - 1));
            Read(FileAreaFile,MemFileArea);
            IF (MemFileArea.FileName = TempMemFileArea1.FileName) THEN
              Ok := FALSE;
            IF (MemFileArea.DLPath = TempMemFileArea1.DLPath) THEN
              Ok1 := FALSE;
            IF (MemFileArea.ULPath = TempMemFileArea1.ULPath) THEN
              Ok2 := FALSE;
          END;
          Close(FileAreaFile);
          IF (Ok) AND (PYNQ('%LFDelete file area data files also?',0,FALSE)) THEN
          BEGIN
            Kill(GetDirPath(TempMemFileArea1)+'.DIR');
            Kill(GetDirPath(TempMemFileArea1)+'.EXT');
            Kill(GetDirPath(TempMemFileArea1)+'.SCN');
          END;
          IF (Ok1) AND (ExistDir(TempMemFileArea1.DLPath)) THEN
            IF PYNQ('%LFRemove the download directory?',0,FALSE) THEN
              PurgeDir(TempMemFileArea1.DLPath,TRUE);
          IF (Ok2) AND (ExistDir(TempMemFileArea1.ULPath)) THEN
            IF PYNQ('%LFRemove the upload directory?',0,FALSE) THEN
              PurgeDir(TempMemFileArea1.ULPath,TRUE);
        END;
      END;
    END;
  END;

  { --- }

  PROCEDURE CheckFileArea(MemFileArea: FileAreaRecordType; MCIVars1: MCIVarRecord;
                          StartErrMsg, EndErrMsg: Byte; VAR Ok: Boolean);
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := StartErrMsg TO EndErrMsg DO
      CASE Counter OF
        1 : IF (MemFileArea.AreaName = '') OR (MemFileArea.AreaName = '<< New File Area >>') THEN
            BEGIN
              Prompt('%LF^8The area name is invalid!^0');
              OK := FALSE;
            END;
        2 : IF (MemFileArea.FileName = '') OR (MemFileArea.FileName = 'NEWDIR') THEN
            BEGIN
              Prompt('%LF^8The file name is invalid!^0');
              OK := FALSE;
            END;
        3 : IF (MemFileArea.DLPath = '') THEN
            BEGIN
              Prompt('%LF^8The download path is invalid!^0');
              OK := FALSE;
            END;
        4 : IF (MemFileArea.ULPath = '') THEN
            BEGIN
              Prompt('%LF^8The upload path is invalid!^0');
              OK := FALSE;
            END;
        5 : IF (MemFileArea.ArcType <> 0) AND (NOT General.FileArcInfo[MemFileArea.ArcType].Active) THEN
            BEGIN
              Prompt('%LF^8The archive type is invalid!^0');
              OK := FALSE;
            END;
        6 : IF (MemFileArea.CmtType <> 0) AND (General.FileArcComment[MemFileArea.CmtType] = '') THEN
            BEGIN
              Prompt('%LF^8The comment type is invalid!^0');
              OK := FALSE;
            END;
      END;
  END;

  { --- }

  PROCEDURE EditFileArea(TempMemFileArea1: FileAreaRecordType; VAR MemFileArea: FileAreaRecordType; VAR Cmd1: Char;
                         VAR MCIVars1: MCIVarRecord; VAR Changed: Boolean; Editing: Boolean);
  VAR
    TempFileName: Str8;
    CmdStr: AStr;
    RecNum,
    RecNum1: Integer;
    Ok: Boolean;
  BEGIN
    WITH MemFileArea DO
      REPEAT
        IF (Cmd1 <> '?') THEN
        BEGIN
          Abort := FALSE;
          Next := FALSE;
          {CLS;}
          IF (Editing) THEN
            ConfigHeader('Editing File Area',MCIVars1.RecNumToEdit,NumFileAreas)
          ELSE
            ConfigHeader('Inserting File Area',MCIVars1.RecNumToEdit,NumFileAreas+1);
          {NL;}
          PrintACR('^0(^11^0) Area Name    : ^1'+MemFileArea.AreaName);
          PrintACR('^0(^12^0) File Name    : ^1'+MemFileArea.FileName+' ^0(^1'+GetDirPath(MemFileArea)+'.*^0)');
          PrintACR('^0(^13^0) DL Path      : ^1'+MemFileArea.DLPath);
          PrintACR('^0(^14^0) UL Path      : ^1'+MemFileArea.ULPath);
          PrintACR('^0(^15^0) Area ACS     : ^1'+AOnOff((MemFileArea.ACS = ''),'*None*',MemFileArea.ACS));
          PrintACR('^0(^16^0) DL/UL ACS    : ^1'+AOnOff((MemFileArea.DLACS = ''),'*None*',MemFileArea.DLACS)+
          '^0 / ^1'+AOnOff((MemFileArea.ULACS = ''),'*None*',MemFileArea.ULACS));
          PrintACR('^0(^17^0) Max Files    : ^1'+IntToStr(MemFileArea.MaxFiles));
          PrintACR('^0(^18^0) Password     : ^1'+AOnOff((MemFileArea.Password = ''),'*None*',MemFileArea.Password));
          PrintACR('^0(^19^0) Arc/Cmt Type : ^1'+AOnOff((MemFileArea.ArcType = 0),'*None*',
          General.FileArcInfo[MemFileArea.ArcType].Ext)+'^0 / ^1'+AOnOff((MemFileArea.CmtType = 0),'*None*',
          IntToStr(MemFileArea.CmtType)));
          PrintACR('^0(^1T^0) Flags        : '+DisplayFAFlags(MemFileArea.FAFlags,'1','0'));
        END;
        NL;
        IF (NOT Editing) THEN
          InputChar('Modify File Area Menu [^1123456789T^2,(^1Q^2)uit]: ',Cmd1,'Q123456789T'^M,[CapAll])
        ELSE
          InputChar('Modify File Area Menu [(^1?^2)Help,(^1Q^2)uit]: ',Cmd1,'Q?123456789T[]{};'^M,[CapAll]);
        CASE Cmd1 OF
          '1' : REPEAT
                  TempMemFileArea1.AreaName := MemFileArea.AreaName;
                  OK := TRUE;
                  InputString('%LFNew area name: ',AreaName,(SizeOf(AreaName) - 1),[InteractiveEdit],Changed);
                  {^ LeeW: no blank}
                  CheckFileArea(MemFileArea,MCIVars1,1,1,Ok);
                  IF (NOT Ok) THEN
                    MemFileArea.AreaName := TempMemFileArea1.AreaName;
                UNTIL (OK) OR (HangUp);
          '2' : REPEAT
                  OK := TRUE;
                  TempFileName := FileName;
                  InputString('%LFNew file name (^1Do not enter ^2"^1.EXT^2"): ',TempFileName,(SizeOf(FileName) - 1),
                           [CapAll,InterActiveEdit],Changed);
                  TempFileName := SQOutSp(TempFileName);
                  IF (Pos('.',TempFileName) > 0) THEN
                    TempFileName := Copy(TempFileName,1,(Pos('.',TempFileName) - 1));
                  TempMemFileArea1.FileName := TempFileName;
                  CheckFileArea(TempMemFileArea1,MCIVars1,2,2,Ok);
                  IF (Ok) AND (TempFileName <> MemFileArea.FileName) THEN
                  BEGIN
                    RecNum1 := -1;
                    RecNum := 0;
                    WHILE (RecNum <= (FileSize(FileAreaFile) - 1)) AND (RecNum1 = -1) DO
                    BEGIN
                      Seek(FileAreaFile,RecNum);
                      Read(FileAreaFile,TempMemFileArea1);
                      IF (TempFileName = TempMemFileArea1.FileName) THEN
                      BEGIN
                        Prompt('%LF^8The file name is already in use!^0');
                        RecNum1 := 1;
                        IF NOT PYNQ('%LFUse this file name anyway?',0,FALSE) THEN
                          Ok := FALSE;
                      END;
                      Inc(RecNum);
                    END;
                  END;
                  IF (Ok) THEN
                  BEGIN
                    MCIVars1.OldPath := GetDirPath(MemFileArea);
                    FileName := TempFileName;
                    IF (Editing) THEN
                    BEGIN
                      MCIVars1.NewPath := GetDirPath(MemFileArea);
                      IF Exist(MCIVars1.OldPath+'.DIR') AND (NOT Exist(MCIVars1.NewPath+'.DIR')) THEN
                      BEGIN
                        Prompt('%LFOld DIR/EXT/SCN file names: "^1'+MCIVars1.OldPath+'.*^0"');
                        Prompt('%LFNew DIR/EXT/SCN file names: "^1'+MCIVars1.NewPath+'.*^0"');
                        IF PYNQ('%LFRename old data files?',0,FALSE) THEN
                        BEGIN
                          CopyMoveFile(FALSE,'%LF^0Renaming "^1'+MCIVars1.OldPath+'.DIR^0" to "^1'+
                                       MCIVars1.NewPath+'.DIR^0": ',MCIVars1.OldPath+'.DIR',MCIVars1.NewPath+'.DIR',TRUE);
                          CopyMoveFile(FALSE,'%LF^0Renaming "^1'+MCIVars1.OldPath+'.EXT^0" to "^1'+
                                       MCIVars1.NewPath+'.EXT^0": ',MCIVars1.OldPath+'.EXT',MCIVars1.NewPath+'.EXT',TRUE);
                          CopyMoveFile(FALSE,'%LF^0Renaming "^1'+MCIVars1.OldPath+'.SCN^0" to "^1'+
                                       MCIVars1.NewPath+'.SCN^0": ',MCIVars1.OldPath+'.SCN',MCIVars1.NewPath+'.SCN',TRUE);
                        END;
                      END;
                    END;
                  END;
                UNTIL (Ok) OR (HangUp);
          '3' : BEGIN
                  InputPath('^2New download path ',DLPath,Editing,FALSE,Changed);
                  IF (ULPath <> DLPath) AND (PYNQ('%LFSet the upload path to the download path?',0,FALSE)) THEN
                  BEGIN
                    ULPath := DLPath;
                    Changed := TRUE;
                  END;
                END;
          '4' : InputPath('^2New upload path ',ULPath,Editing,FALSE,Changed);
          '5' : InputString('%LFNew ACS: ',ACS,(SizeOf(ACS) - 1),[InterActiveEdit],Changed);
          '6' : BEGIN
                  InputString('%LFNew download ACS: ',DLACS,(SizeOf(DLACS) - 1),[InterActiveEdit],Changed);
                  {leew: ask same as other?}
                  InputString('%LFNew upload ACS: ',ULACS,(SizeOf(ULACS) - 1),[InterActiveEdit],Changed);
                END;
          '7' : InputInteger('%LFNew max files ',MaxFiles,[InteractiveEdit{DisplayValue},NumbersOnly],0,32767,Changed);
          '8' : InputString('%LFNew password: ',Password,(SizeOf(Password) - 1),[InterActiveEdit,CapAll],Changed);
          '9' : BEGIN
                  REPEAT
                    OK := TRUE;
                    NL;
                    DisplayARCS;
                    InputByte('%LFNew archive type (^10^2=^1None^2) ',MemFileArea.ArcType,
                                [InteractiveEdit{DisplayValue},NumbersOnly],0,NumArcs,Changed);
                    CheckFileArea(MemFileArea,MCIVars1,5,5,Ok);
                  UNTIL (Ok) OR (HangUp);
                  REPEAT
                    OK := TRUE;
                    NL;
                    DisplayCmt;
                    InputByte('%LFNew comment type (^10^2=^1None^2) ',CmtType,[InteractiveEdit
                        {DisplayValue},NumbersOnly],0,3,Changed);
                    CheckFileArea(MemFileArea,MCIVars1,6,6,Ok);
                  UNTIL (Ok) OR (HangUp)
                END;
          'T' : BEGIN
                  REPEAT
                    InputChar('%LFToggle which flag ('+DisplayFAFlags(MemFileArea.FAFlags,'5',
                    '4')+')^2) [^1?^2=^1Help^2,^1<CR>^2=^1Quit^2]: ',Cmd1,^M'CDGINPSU?',[CapAll]);
                    CASE (Cmd1) OF
                      'C','D','G','N','P','S','U' :
                         ToggleFAFlags(Cmd1,FAFlags,Changed);
                      'I' : BEGIN
                              MCIVars1.OldPath := GetDIRPath(MemFileArea);
                              ToggleFAFlags('I',FAFlags,Changed);
                              IF (Editing) THEN
                              BEGIN
                                MCIVars1.NewPath := GetDIRPath(MemFileArea);
                                IF (Exist(MCIVars1.OldPath+'.DIR')) AND (NOT Exist(MCIVars1.NewPath+'.DIR')) THEN
                                BEGIN
                                Prompt('%LFOld DIR/EXT/SCN file names: "^1'+MCIVars1.OldPath+'.*^0"');
                                Prompt('%LFNew DIR/EXT/SCN file names: "^1'+MCIVars1.NewPath+'.*^0"');
                                {
                                FAELngStr(43,MemFileArea,MCIVars1,FALSE);
                                FAELngStr(44,MemFileArea,MCIVars1,FALSE);
                                }
                                  IF PYNQ('%LFMove old data files to new directory?',0,FALSE) THEN
                                  BEGIN
                                    CopyMoveFile(FALSE,'%LF^0Moving "^1'+MCIVars1.OldPath+'.DIR^0" to "^1'+
                                                 MCIVars1.NewPath+'.DIR^0": ',MCIVars1.OldPath+'.DIR',MCIVars1.NewPath+'.DIR',
                                                 TRUE);
                                    CopyMoveFile(FALSE,'%LF^0Moving "^1'+MCIVars1.OldPath+'.EXT^0" to "^1'+
                                                 MCIVars1.NewPath+'.EXT^0": ',MCIVars1.OldPath+'.EXT',MCIVars1.NewPath+'.EXT',
                                                 TRUE);
                                    CopyMoveFile(FALSE,'%LF^0Moving "^1'+MCIVars1.OldPath+'.SCN^0" to "^1'+
                                                 MCIVars1.NewPath+'.SCN^0": ',MCIVars1.OldPath+'.SCN',MCIVars1.NewPath+'.SCN',
                                                 TRUE);
                                  END;
                                END;
                              END;
                            END;
                      '?' : BEGIN
                              NL;
                              LCmds(25,1,'N No Ratio',          'U Unhidden');
                              LCmds(25,1,'G Show .GIF Specs',       'I .DIR files in DL Path');
                              LCmds(25,1,'C CD-ROM / Read-Only',    'S Show Uploader Name');
                              LCmds(25,1,'D Show Date Uploaded',    'P No Duplicate Checking');
                            END;
                    END;
                  UNTIL (Cmd1 = ^M) OR (HangUp);
                  Cmd1 := #0;
                END;
          '[' : IF (MCIVars1.RecNumToEdit > 1) THEN
                  Dec(MCIVars1.RecNumToEdit)
                ELSE
                BEGIN
                  Messages(2,0,''); {First valid record!}
                  Cmd1 := #0;
                END;
          ']' : IF (MCIVars1.RecNumToEdit < NumFileAreas) THEN
                  Inc(MCIVars1.RecNumToEdit)
                ELSE
                BEGIN
                  Messages(3,0,''); {Last valid record!}
                  Cmd1 := #0;
                END;
          '{' : IF (MCIVars1.RecNumToEdit <> 1) THEN
                  MCIVars1.RecNumToEdit := 1
                ELSE
                BEGIN
                  Messages(2,0,''); {First valid record!}
                  Cmd1 := #0;
                END;
          ';' : BEGIN
                  InputInteger('%LFJump to entry?',MCIVars1.RecNumToEdit,[Numbersonly],1,NumFileAreas,Changed);
                  IF (MCIVars1.RecNumToEdit < 1) OR (MCIVars1.RecNumToEdit > NumFileAreas) THEN
                    Cmd1 := #0;
                END;
          '}' : IF (MCIVars1.RecNumToEdit <> NumFileAreas) THEN
                  MCIVars1.RecNumToEdit := NumFileAreas
                ELSE
                BEGIN
                  Messages(3,0,''); {Last valid record!}
                  Cmd1 := #0;
                END;
          '?' : BEGIN
                  NL;
                  LCmds(17,1,'[Previous Record',']Next Record');
                  LCmds(17,1,'{First Record','}Last Record');
                  LCmds(17,1,';Jump To Record','');
                END;
        END;
      UNTIL (Pos(Cmd1,'Q[]{};') <> 0) OR (HangUp);
  END;

  { --- }

  PROCEDURE InsertFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    FileAreaScanFile: FILE OF Boolean;
    Cmd1: Char;
    RecNum,
    RecNum1,
    RecNumToInsertBefore: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumFileAreas = MaxFileAreas) THEN
      Messages(5,MaxFileAreas,'file areas') { "No more than 0 file areas can exist!" }
      (*Prompt('%LF^8No more then '+IntToStr(MaxFileAreas)+' file areas can exist!^0%LF%PA')*)
    ELSE
    BEGIN
      RecNumToInsertBefore := -1;
      InputInteger('%LFFile area to insert before? ',RecNumToInsertBefore,[NumbersOnly],1,(NumFileAreas + 1),Changed);
      IF (RecNumToInsertBefore >= 1) AND (RecNumToInsertBefore <= (NumFileAreas + 1)) THEN
      BEGIN
        Reset(FileAreaFile);
        InitFileAreaVars(TempMemFileArea1);
        IF (RecNumToInsertBefore = 1) THEN
          MCIVars1.RecNumToEdit := 1
        ELSE IF (RecNumToInsertBefore = (NumFileAreas + 1)) THEN
          MCIVars1.RecNumToEdit := (NumFileAreas + 1)
        ELSE
          MCIVars1.RecNumToEdit := RecNumToInsertBefore;
        REPEAT
          OK := TRUE;
          EditFileArea(TempMemFileArea1,TempMemFileArea1,Cmd1,MCIVars1,Changed,FALSE);
          CheckFileArea(TempMemFileArea1,MCIVars1,1,6,Ok);
          IF (NOT OK) THEN
            IF (NOT PYNQ('%LFContinue inserting file area?',0,TRUE)) THEN
              Abort := TRUE;
        UNTIL (OK) OR (Abort) OR (HangUp);
        IF (NOT Abort) AND (PYNQ('%LFIs this what you want?',0,FALSE)) THEN
        BEGIN
          Prompt('%LF[> Inserting file area ...');
          Seek(FileAreaFile,FileSize(FileAreaFile));
          Write(FileAreaFile,MemFileArea);
          Dec(RecNumToInsertBefore);
          FOR RecNum := ((FileSize(FileAreaFile) - 1) - 1) DOWNTO RecNumToInsertBefore DO
          BEGIN
            Seek(FileAreaFile,RecNum);
            Read(FileAreaFile,MemFileArea);
            Seek(FileAreaFile,(RecNum + 1));
            Write(FileAreaFile,MemFileArea);
          END;
          FOR RecNum := RecNumToInsertBefore TO ((RecNumToInsertBefore + 1) - 1) DO
          BEGIN
            MakeDir(TempMemFileArea1.DLPath,FALSE);
            MakeDir(TempMemFileArea1.ULPath,FALSE);
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.DIR')) THEN
            BEGIN
              Assign(FileInfoFile,GetDIRPath(TempMemFileArea1)+'.DIR');
              ReWrite(FileInfoFile);
              Close(FileInfoFile);
            END;
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.EXT')) THEN
            BEGIN
              Assign(ExtInfoFile,GetDIRPath(TempMemFileArea1)+'.EXT');
              ReWrite(ExtInfoFile,1);
              Close(ExtInfoFile);
            END;
            IF (NOT Exist(GetDirPath(TempMemFileArea1)+'.SCN')) THEN
            BEGIN
              Assign(FileAreaScanFile,GetDIRPath(TempMemFileArea1)+'.SCN');
              ReWrite(FileAreaScanFile);
              Close(FileAreaScanFile);
            END;
            IF (Exist(GetDirPath(TempMemFileArea1)+'.SCN')) THEN
            BEGIN
              Assign(FileAreaScanFile,GetDIRPath(TempMemFileArea1)+'.SCN');
              Reset(FileAreaScanFile);
              NewScanFileArea := TRUE;
              FOR RecNum1 := (FileSize(FileAreaScanFile) + 1) TO (MaxUsers - 1) DO
                Write(FileAreaScanFile,NewScanFileArea);
              Close(FileAreaScanFile);
            END;
            {LeeW:done?msg}
            Seek(FileAreaFile,RecNum);
            Write(FileAreaFile,TempMemFileArea1);
            Inc(NumFileAreas);
            SysOpLog('* Inserted file area: ^1'+MemFileArea.AreaName);
          END;
        END;
        Close(FileAreaFile);
        LastError := IOResult;
      END;
    END;
  END;

  { --- }

  PROCEDURE ModifyFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    FileAreaScanFile: FILE OF Boolean;
    User: UserRecordType;
    Cmd1: Char;
    RecNum1,
    SaveRecNumToEdit: Integer;
    Ok,
    Changed: Boolean;
  BEGIN
    IF (NumFileAreas = 0) THEN
      Messages(4,0,'file areas') { "No file areas exist!" } (*Prompt('%LF^8No file areas exist!^0%LF%PA')*)
    ELSE
    BEGIN
      MCIVars1.RecNumToEdit := -1;
      InputInteger('%LFFile area to modify? ',MCIVars1.RecNumToEdit,[NumbersOnly],1,NumFileAreas,Changed);
      IF (MCIVars1.RecNumToEdit >= 1) AND (MCIVars1.RecNumToEdit <= NumFileAreas) THEN
      BEGIN
        SaveRecNumToEdit := -1;
        Cmd1 := #0;
        Reset(FileAreaFile);
        WHILE (Cmd1 <> 'Q') AND (NOT HangUp) DO
        BEGIN
          IF (SaveRecNumToEdit <> MCIVars1.RecNumToEdit) THEN
          BEGIN
            Seek(FileAreaFile,(MCIVars1.RecNumToEdit - 1));
            Read(FileAreaFile,MemFileArea);
            SaveRecNumToEdit := MCIVars1.RecNumToEdit;
            Changed := FALSE;
          END;
          REPEAT
            Ok := TRUE;
            EditFileArea(TempMemFileArea1,MemFileArea,Cmd1,MCIVars1,Changed,TRUE);
            CheckFileArea(MemFileArea,MCIVars1,1,6,Ok);
            IF (NOT OK) THEN
            BEGIN
              PauseScr(FALSE);
              IF (MCIVars1.RecNumToEdit <> SaveRecNumToEdit) THEN
                MCIVars1.RecNumToEdit := SaveRecNumToEdit;
            END;
          UNTIL (OK) OR (HangUp);
          MakeDir(MemFileArea.DLPath,FALSE);
          MakeDir(MemFileArea.ULPath,FALSE);
          IF (NOT Exist(GetDirPath(MemFileArea)+'.DIR')) THEN
          BEGIN
            Assign(FileInfoFile,GetDIRPath(MemFileArea)+'.DIR');
            ReWrite(FileInfoFile);
            Close(FileInfoFile);
          END;
          IF (NOT Exist(GetDirPath(MemFileArea)+'.EXT')) THEN
          BEGIN
            Assign(ExtInfoFile,GetDIRPath(MemFileArea)+'.EXT');
            ReWrite(ExtInfoFile,1);
            Close(ExtInfoFile);
          END;
          IF (NOT Exist(GetDirPath(MemFileArea)+'.SCN')) THEN
          BEGIN
            Assign(FileAreaScanFile,GetDIRPath(MemFileArea)+'.SCN');
            ReWrite(FileAreaScanFile);
            Close(FileAreaScanFile);
          END;
          IF (Exist(GetDirPath(MemFileArea)+'.SCN')) THEN
          BEGIN
            Assign(FileAreaScanFile,GetDIRPath(MemFileArea)+'.SCN');
            Reset(FileAreaScanFile);
            NewScanFileArea := TRUE;
            Seek(FileAreaScanFile,FileSize(FileAreaScanFile));
            FOR RecNum1 := (FileSize(FileAreaScanFile) + 1) TO (MaxUsers - 1) DO
              Write(FileAreaScanFile,NewScanFileArea);
            Reset(UserFile);
            FOR RecNum1 := 1 TO (MaxUsers - 1) DO
            BEGIN
              LoadURec(User,RecNum1);
              IF (Deleted IN User.SFlags) THEN
              BEGIN
                Seek(FileAreaScanFile,(RecNum1 - 1));
                Write(FileAreaScanFile,NewScanFileArea);
              END;
            END;
            Close(UserFile);
            Close(FileAreaScanFile);
          END;
          IF (Changed) THEN
          BEGIN
            Seek(FileAreaFile,(SaveRecNumToEdit - 1));
            Write(FileAreaFile,MemFileArea);
            Changed := FALSE;
            SysOpLog('* Modified file area: '+MemFileArea.AreaName);
          END;
        END;
        Close(FileAreaFile);
        LastError := IOResult;
      END;
    END;
  END;

  { --- }

  PROCEDURE PositionFileArea(TempMemFileArea1: FileAreaRecordType; MCIVars1: MCIVarRecord);
  VAR
    RecNumToPosition,
    RecNumToPositionBefore,
    RecNum1,
    RecNum2: Integer;
  BEGIN
    IF (NumFileAreas = 0) THEN
      Messages(4,0,'file areas') { "No file areas exist!" }
    ELSE IF (NumFileAreas = 1) THEN
      Messages(6,0,'file areas') { "No file areas to position!" }
    ELSE
    BEGIN
      RecNumToPosition := -1;
      InputInteger('%LFPosition which file area? ',RecNumToPosition,[NumbersOnly],1,NumFileAreas,Changed);
      IF (RecNumToPosition >= 1) AND (RecNumToPosition <= NumFileAreas) THEN
      BEGIN
        RecNumToPositionBefore := -1;
        Prompt('%LFAccording to the current numbering system.');
        InputInteger('%LFPosition before which file area?',RecNumToPositionBefore,[Numbersonly],
        1,(NumFileAreas + 1),Changed);
        IF (RecNumToPositionBefore >= 1) AND (RecNumToPositionBefore <= (NumFileAreas + 1)) AND
           (RecNumToPositionBefore <> RecNumToPosition) AND (RecNumToPositionBefore <> (RecNumToPosition + 1)) THEN
        BEGIN
          Prompt('%LF[> Positioning file areas ...');
          Reset(FileAreaFile);
          IF (RecNumToPositionBefore > RecNumToPosition) THEN
            Dec(RecNumToPositionBefore);
          Dec(RecNumToPosition);
          Dec(RecNumToPositionBefore);
          Seek(FileAreaFile,RecNumToPosition);
          Read(FileAreaFile,TempMemFileArea1);
          RecNum1 := RecNumToPosition;
          IF (RecNumToPosition > RecNumToPositionBefore) THEN
            RecNum2 := -1
          ELSE
            RecNum2 := 1;
          WHILE (RecNum1 <> RecNumToPositionBefore) DO
          BEGIN
            IF ((RecNum1 + RecNum2) < FileSize(FileAreaFile)) THEN
            BEGIN
              Seek(FileAreaFile,(RecNum1 + RecNum2));
              Read(FileAreaFile,MemFileArea);
              Seek(FileAreaFile,RecNum1);
              Write(FileAreaFile,MemFileArea);
            END;
            Inc(RecNum1,RecNum2);
          END;
          Seek(FileAreaFile,RecNumToPositionBefore);
          Write(FileAreaFile,TempMemFileArea1);
          Close(FileAreaFile);
          LastError := IOResult;
        END;
      END;
    END;
  END;

  { --- }

  PROCEDURE ListFileAreas(VAR RecNumToList1: Integer; MCIVars1: MCIVarRecord);
  VAR
    NumDone: Integer;
    NumOnLine: Byte; { LeeW: Added for double column list }
    TempStr: AStr; { ^ }
  BEGIN
    IF (RecNumToList1 < 1) OR (RecNumToList1 > NumFileAreas) THEN
      RecNumToList1 := 1;
    Abort := FALSE;
    Next := FALSE;
    ConfigHeader('File Area Editor',0,0);
    CASE DisplayType OF
      1 : PrintACR('^5<^4##^5> <^4File Area Name^5>                  <^4##^5> <^4File Area Name^5>                  ');
      2 : PrintACR('^5<^4##^5> <^4File Area Name^5>      <^4Dat^5>    <^4DL Path^5>            <^4UL Path^5>            ');
    END;
    HL;
    Reset(FileAreaFile);
    NumDone := 0;
    NumOnLine := 0; { LeeW: Added }
    TempStr := ''; { ^ }
    WHILE (NumDone < (PageLength - 7)*2) AND (RecNumToList1 >= 1) AND (RecNumToList1 <= NumFileAreas)
     AND (NOT Abort) AND (NOT HangUp) DO
      BEGIN
        Seek(FileAreaFile,(RecNumToList1 - 1));
        Read(FileAreaFile,MemFileArea);
        WITH MemFileArea DO
         CASE DisplayType OF
          1 : TempStr := TempStr+'^1 '+PadLeftInt(RecNumToList1,4)+' ^0'+PadLeftStr(AreaName,33);
          2 : PrintACR('^1 '+PadLeftInt(RecNumToList1,4)+'^0'+
                       ' '+PadLeftStr(AreaName,21)+
                       ' '+PadLeftStr(FileName,8)+
                       ' '+PadLeftStr(DLPath,20)+
                       ' '+PadLeftStr(ULPath,20));
        END;
        Inc(NumOnLine);
        IF (NumOnLine = 2) AND (DisplayType <> 2) THEN
          BEGIN
            PrintACR(TempStr);
            NumOnLine := 0;
            TempStr := '';
          END;
        Inc(RecNumToList1);
        Inc(NumDone);
      END;
    Close(FileAreaFile);
    LastError := IOResult;
    IF (NumOnLine = 1) AND (NOT Abort) AND (NOT HangUp) THEN
      PrintACR(TempStr);
    IF (NumFileAreas = 0) AND (NOT Abort) AND (NOT HangUp) THEN
      Messages(4,0,'file areas'); { "No file areas exist!" }
  END;

  { --- }

BEGIN
  SaveTempPause := TempPause;
  TempPause := FALSE;
  RecNumToList := 1;
  Cmd := #0;
  REPEAT
    IF (Cmd <> '?') THEN
      ListFileAreas(RecNumToList,MCIVars);
    NL;
    InputChar('^2File Area Editor [^1CDIMPT^2,(^1?^2)Help,<^1CR^2>Page,(^1Q^2)uit]: ',Cmd,'QCDIMPT?'^M,[CapAll]);
    CASE Cmd OF
      ^M  : IF (RecNumToList < 1) OR (RecNumToList > NumFileAreas) THEN
              RecNumToList := 1;
      'C' : ChangeFileAreaDrive(MCIVars);
      'D' : DeleteFileArea(TempMemFileArea,MCIVars);
      'I' : InsertFileArea(TempMemFileArea,MCIVars);
      'M' : ModifyFileArea(TempMemFileArea,MCIVars);
      'P' : PositionFileArea(TempMemFileArea,MCIVars);
      'T' : DisplayType := ((DisplayType MOD 2) + 1);
      '?' : BEGIN
              NL;
              {Print('%LF<CR>Next screen or redisplay current screen');}
              LCmds(23,1,'D Delete File Area',     'I Insert File Area');
              LCmds(23,1,'M Modify File Area',     'P Position File Area');
              LCmds(23,1,'-','-');
              LCmds(23,1,'C Change Storage Drive', 'T Toggle Display Format');
              {LCmds(23,1,'Q Quit',                 '');}
            END;
    END;
    IF (Cmd <> ^M) THEN
      RecNumToList := 1;
  UNTIL (Cmd = 'Q') OR (HangUp);
  TempPause := SaveTempPause;
  NewCompTables;
  IF ((FileArea < 1) OR (FileArea > NumFileAreas)) THEN
    FileArea := 1;
  ReadFileArea := -1;
  LoadFileArea(FileArea);
  LastError := IOResult;
END;
END.