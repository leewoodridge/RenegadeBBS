{
 05/13/2022	- Added /L parameter TO list index AND data file records
 first param is RGDir
 
 use truncate on file???
 
 InsertIndex should update old rec instead of deleting old and adding new
 
}
PROGRAM RenegadeUserPacker;

USES
  CRT,
  DOS,
  {WinDOS,}
  Strings,
  RUPTPU,
  Runtime;
  
CONST
  Check = '|10'#251; { Square root symbol, kind of looks like a check mark -- for successful operation }

VAR
  RGDir         : String; { Paths }
  CurDir        : String; { ^ }
  DatDir        : String; { ^ }
  Path2SCN      : String;
  {Path2SCNPChar : Array [0..255] OF Char;}
  RenegadeDatIn : GeneralRec;
  UsersDatIn    : UserRec;
  UsersIDXIn    : UserIDXRec;
  NewUsersDatIn : UserRec;
  NewUsersIDXIn : UserIDXRec;
  SCNIn,
  NewSCNIn      : ScanRec;
  SCN_FName     : String;
  TookOut       : Array [0..6500] OF Integer;
  TookOutCountUser,
  TookOutCountScanRec,
  TookOutCountScanRecTot,
  ScanFilesCount: Integer;
  FileErr       : Boolean;

  OldBackupOne,
  OldBackupTwo  : File;
  Skip          : Boolean;
  RecCount,
  NewRecCount,
  C1,
  C2            : LongInt;
  
  PROCEDURE Pipe(InStr: String; CRLF: Boolean);
  VAR
	S: String;
	I,
	Err: Integer;
	Col: Byte;
  BEGIN
	S := InStr;
	I := 1;
	REPEAT
	  IF (S[I] = '|') THEN
		BEGIN
		  Val(Copy(S,I+1,2),Col,Err);
		  IF (Err = 0) AND (Col IN [0..22]) THEN
			IF Col IN [0..15] THEN
			  TextColor(Col)
			ELSE IF Col IN [16..22] THEN
			  TextBackground(Col - 16);
		  Inc(I,3);
		END
	  ELSE
		BEGIN
		  Write(S[I]);
		  Inc(I);
		END;
	UNTIL (I > Length(S));
	IF (CRLF) THEN
	  WriteLn;
	Delay(50); { LeeW: Remove this -- FOR testing }
  END;

  PROCEDURE Error(InStr: String);
  BEGIN
	WriteLn;
	Pipe('|12[ERROR]',FALSE);
	Pipe(InStr,TRUE); { Single line? }
	Window(1,1,80,25);
	GoToXY(1,23);
	Halt(IOResult);
  END;

  PROCEDURE Intro;
  VAR
	Loop: Byte;
  BEGIN
    ClrScr;
	Pipe('|07                     Renegade BBS User Packer Ä Version 1.0',TRUE);
	Pipe('|07              Copyright (c) 2022 The Renegade BBS Development Team',TRUE);
    GoToXY(1,3);
    Pipe('|08 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',TRUE);
    FOR Loop := 1 TO 18 DO
	  Pipe('',TRUE);
    Pipe('|08 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',TRUE);
    Window(2,4,78,21);
  END;

  FUNCTION DirExist(InDir: DirStr): Boolean;
  VAR
	Attr : Word;
	TempFile  : File;
  BEGIN
	Assign(TempFile,(InDir+'.'));
	GetFAttr(TempFile,Attr);
	IF (DOSError <> 0) THEN
	  DirExist := FALSE
	ELSE
	  DirExist := ((Attr AND Directory) <> 0)
  END;

  FUNCTION FileExist(InFile: String): Boolean;
  VAR
	F: File;
  BEGIN
    Assign(F,InFile);
    {$I-}Reset(F);{$I+}
    IF IOResult = 0 THEN
	  FileExist := TRUE
    ELSE
	  FileExist := FALSE;
  END;

  FUNCTION IntToStr(InInt: LongInt): String;
  VAR
	S: String;
  BEGIN
    S := '';
    Str(InInt,S);
    IntToStr := S;
  END;

  PROCEDURE GetRGDir;
  BEGIN
	GetDir(0,CurDir);
	IF ParamStr(1) <> '' THEN
	  RGDir := ParamStr(1);
	IF (ParamStr(1) = '') OR (RGDir[2] <> ':') THEN
	  RGDir := GetEnv('RENEGADE');
	IF RGDir = '' THEN
	  RGDir := GetEnv('RG');
	IF RGDir = '' THEN
	  RGDir := GetEnv('BBS');
	IF RGDir = '' THEN
	  BEGIN
		RGDir := FSearch('RENEGADE.DAT',GetEnv('PATH'));
		IF RGDir <> '' THEN
		  RGDir := CurDir;
	  END;
	IF RGDir = '' THEN
	  BEGIN
		RGDir := FSearch('RENEGADE.DAT',CurDir);
		IF RGDir <> '' THEN
		  RGDir := CurDir;
	  END;
	IF (RGDir <> '') AND (RGDir[Length(RGDir)] <> '\') THEN
	  RGDir := RGDir + '\';
	IF (RGDir = '') OR (NOT DirExist(RGDir)) THEN
	  Error(' þ RENEGADE.DAT not found!');
  END;

  FUNCTION AllCaps(InString: STRING): STRING;
  VAR
    Counter: Byte;
  BEGIN
    FOR Counter := 1 TO Length(InString) DO
      IF (InString[Counter] IN ['a'..'z']) THEN
        InString[Counter] := Chr(Ord(InString[Counter]) - Ord('a')+Ord('A'));
    AllCaps := InString;
  END;

FUNCTION SearchUser(UName: Str36; RealNameOK: Boolean): Integer;
VAR
  UserIDX: UserIDXRec;
  UserIDXFile: FILE OF UserIDXRec;  { USER.IDX }
  Current: Integer;
  Done: Boolean;
BEGIN
  SearchUser := 0;
  Assign(UserIDXFile,+DatDir+'\USERS.IDX');
  Reset(UserIDXFile);
  IF (IOResult <> 0) THEN
    BEGIN
      {SysOpLog}Error('Error opening USERS.IDX.');
      Exit;
	END;

  WHILE (Uname[Length(Uname)] = ' ') DO
    Dec(Uname[0]);

  UName := AllCaps(UName);

  Current := 0;
  Done := FALSE;

  IF (FileSize(UserIDXFile) > 0) THEN
    REPEAT
      Seek(UserIDXFile,Current);
      Read(UserIDXFile,UserIDX);
      IF (Uname < UserIDX.Name) THEN
        Current := UserIDX.Left
      ELSE IF (Uname > UserIDX.Name) THEN
        Current := UserIDX.Right
      ELSE
        Done := TRUE;
    UNTIL (Current = -1) OR (Done);
  Close(UserIDXFile);

  IF (Done) AND (RealNameOK OR NOT UserIDX.RealName) AND (NOT UserIDX.Deleted) THEN
    SearchUser := UserIDX.Number;

  {LastError := IOResult;}
END;

  FUNCTION Plural(InString: STRING; Number: Integer): STRING;
  BEGIN
	IF (Number <> 1) THEN
      Plural := InString + 's'
	ELSE
      Plural := InString;
  END;

  FUNCTION IsUpdate: Boolean; { Was user deleted, or just changed username or realname? }
  BEGIN
	IsUpdate := FALSE;
	ReadFromUsersDat(UsersDatIn,UsersIdxIn.Number);
	IF ((UsersIdxIn.RealName) AND (SearchUser(UsersDatIn.Name,FALSE) > 0)) OR 
	   ((NOT UsersIdxIn.RealName) AND (SearchUser(UsersDatIn.RealName,TRUE) > 0)) THEN
	  IsUpdate := TRUE;
  END;

BEGIN { User/SCN Packer }
  Intro;

  GetRGDir;

  OpenRenegadeDat(RGDir,FileErr);
  IF FileErr THEN
	Error(' þ RENEGADE.DAT not found!'); { I think this is redundant because of GetRGDir }
	
  ReadFromRenegadeDat(RenegadeDatIn);
  CloseRenegadeDat;

  DatDir := AddSlash(RenegadeDatIn.DataPath);
  
  OpenUsersIDX(DatDir,FileErr);
  IF FileErr THEN
	Error(' þ USERS.IDX not found!');
  OpenUsersDat(DatDir,FileErr);
  IF FileErr THEN
	Error(' þ USERS.DAT not found!');

  { Assign and ReWrite new IDX and DAT files }
  OpenNewUsersIDX(DatDir,FileErr);
  IF FileErr THEN
	Error(' þ USER_IDX.NEW not found!');
  OpenNewUsersDat(DatDir,FileErr);
  IF FileErr THEN
	Error(' þ USER_DAT.NEW not found!');
   
  { --- }

(* TEST CODE
  IF (ParamCount <> 0) AND (AllCaps(ParamStr(1))='/L') THEN
	BEGIN
	  {Writeln (ParamStr(0),' : Got ',ParamCount,' command-line parameters: ');
	  FOR i:=1 TO ParamCount DO
		Writeln (ParamStr (i));}
	
	{pipe(inttostr(filesize(usersidx)),true);
	pipe(inttostr(filesize(usersdat)),true);}
	
	  Pipe('IDX',TRUE);
	  FOR RecCount := 0 TO (FileSize(UsersIdx)-1) DO
		BEGIN
		  ReadFromUsersIdx(UsersIdxIn,RecCount);
		  Pipe('REC: '+IntToStr(RecCount)+' IDX#: '+IntToStr(UsersIdxIn.Number)+' NAME: '+UsersIdxIn.Name,TRUE);
		  IF usersidxin.deleted THEN
		  pipe('deleted',TRUE);
		  IF usersidxin.realname THEN
		  pipe('realname',TRUE);
		END;
	  Pipe('DAT',TRUE);
	  FOR RecCount := 0 TO (FileSize(UsersDat)-1) DO
		BEGIN
		  ReadFromUsersDat(UsersDatIn,RecCount);
		  Pipe('REC: '+IntToStr(RecCount)+' NAME: '+UsersDatIn.Name,TRUE);
		END;
	  EXIT;
	END;

  IF (ParamCount <> 0) AND (AllCaps(ParamStr(1))='/M') THEN
	BEGIN

  OpenSCN('c:\renegade\msgs\NEWBB.SCN',FileErr);
  
  FOR RecCount := 0 TO FileSize(SCN)-1 DO
	BEGIN
	ReadFromSCN(SCNIn,RecCount);
	pipe(inttostr(SCNIn.lastread),FALSE);
	if SCNIn.newscan then
	pipe('true',FALSE)
	else
	pipe('false',FALSE)
	END;
EXIT;
	END;
*)
	{ -- END of IF parameter -- }
	
  { -- UPDATE USER IDX/DAT RECORDS -- }

  { Generate TEMPORARY new user index }
  FillChar(TookOut,SizeOf(TookOut),' ');
  TookOutCountUser := 0;
  Pipe('|08þ |07Scanning for deleted users ... ',FALSE);
  FOR RecCount := 0 TO (FileSize(UsersIdx)-1) DO
	BEGIN
      ReadFromUsersIdx(UsersIdxIn,RecCount);
	  {---}
	  
	  (*
	  
	  ReadFromUsersDat(UsersDatIn,usersidxin.number);
	  if usersidxin.realname then
	  begin
	  if SearchUser(usersdatin.name,false) > 0 then
	  pipe('match',true);
	  end
	  else
	  begin
	  if SearchUser(usersdatin.realname,true) > 0 then
	  pipe('match',true);
	  end;
	  *)
	  
	  {---}
      IF NOT UsersIdxIn.Deleted THEN
		WriteToNewUsersIdx(UsersIdxIn,UsersIdxIn.Number)
      ELSE
		BEGIN { If deleted }
		  IF NOT IsUpdate THEN
		    TookOut[TookOutCountUser] := {RecCount}UsersIdxIn.Number-1 {LeeW: Changed}
		  ELSE
            TookOut[TookOutCountUser] := -1;
		  Inc(TookOutCountUser);
		END;
	END;
	
  IF (TookOutCountUser = 0) THEN
	BEGIN
	  CloseUsersIdx;
      CloseNewUsersIdx;
      CloseUsersDat;
      CloseNewUsersDat;
      Erase(NewUsersIdx);
	  Erase(NewUsersDat);
      Pipe('None found!',TRUE);
      Window(1,1,80,25);
      GoToXY(1,23);
      Halt;
	END
  ELSE
    Pipe('|07'+IntToStr(TookOutCountUser)+' deleted records found!',TRUE);
	
  { Generate new user data file }
  Pipe('|08þ |07Writing new user data file ... ',FALSE);
  NewRecCount := 0;
  
  ReadFromUsersDat(UsersDatIn,0); { Add default new user configuration account }
  WriteToNewUsersDat(UsersDatIn,0); { ^ }
  
  FOR RecCount := 0 TO (FileSize(NewUsersIdx)-1) DO
	BEGIN
      ReadFromNewUsersIdx(NewUsersIdxIn,RecCount);
      ReadFromUsersDat(UsersDatIn,NewUsersIdxIn.Number); { Read from old USERS.DAT using new index }
      IF NewUsersIdxIn.Number <> 0 THEN
		BEGIN
		  Inc(NewRecCount);
		  WriteToNewUsersDat(UsersDatIn,NewRecCount);
		END;
	END;
  IF (IOResult <> 0) THEN
	Error('Unable to write new user data file!')
  ELSE
	Pipe(Check,TRUE);

  { Close all records }
  CloseUsersIdx;
  CloseNewUsersIdx;
  CloseUsersDat;
  CloseNewUsersDat;

  Pipe('|08þ |07Deleting previous backups ... ',true);
  
  IF FileExist(DatDir+'USER_IDX.BAK') THEN
	BEGIN
      Assign(OldBackupOne,DatDir+'USER_IDX.BAK');
	  Pipe('   |08- |07USER_IDX.BAK ',false);
      {Pipe('Deleting ... ',False);}
      Erase(OldBackupOne);
	  IF IOresult <> 0 THEN
		Error('Unable to erase USER_IDX.BAK!')
	  ELSE
		Pipe(Check,FALSE);
	END;

  Assign(OldBackupTwo,DatDir+'USER_DAT.BAK');
  IF FileExist(DatDir+'USER_DAT.BAK') THEN
	BEGIN
      Assign(OldBackupTwo,DatDir+'USER_DAT.BAK');
	  Pipe(' |07USER_DAT.BAK ',FALSE);
      {Pipe('Deleting ... ',False);}
      Erase(OldBackupTwo);
	  IF IOresult <> 0 THEN
		Error('Unable to erase USER_DAT.BAK!')
	  ELSE
		Pipe(Check,TRUE);
	END;

  Pipe('|08þ |07Backing up user index and data files ... ',true);
  Pipe('   |08- |07USER.IDX ',FALSE);
  Rename(UsersIdx,DatDir+'USER_IDX.BAK');
  IF IOresult <> 0 THEN
	Error('Unable to rename USER.IDX to USER_IDX.BAK!')
  ELSE
	Pipe(Check,FALSE);
  Pipe(' |07USER.DAT ',FALSE);
  Rename(UsersDat,DatDir+'USER_DAT.BAK');
  IF IOresult <> 0 THEN
	Error('Unable to rename USER.DAT to USER_DAT.BAK!')
  ELSE
	Pipe(Check,TRUE);
	
  Pipe('|08þ |07Updating user index and data files ... ',TRUE);
  Pipe('   |08- |07USER.IDX ',FALSE);
  Rename(NewUsersIdx,DatDir+'USERS.IDX');
  IF IOresult <> 0 THEN
	Error('Unable to rename USER_IDX.NEW to USERS.IDX!')
  ELSE
	Pipe(Check,FALSE);
  Pipe(' |07USER.DAT ',FALSE);
  Rename(NewUsersDat,DatDir+'USERS.DAT');
  IF IOresult <> 0 THEN
	Error('Unable to rename USER_DAT.NEW to USERS.DAT!')
  ELSE
	Pipe(Check,TRUE);
	
  Erase(NewUsersIdx); { This new index is not compatible with current RG version; 
						so we'll just delete it and have RG regenerate it on next boot }
  
  { -- END OF USER IDX/DAT RECORDS -- }
  
  { -- UPDATE MSG SCAN RECORDS -- } (* MORE EFFECIENT FIND CODE *)
  
  { Find the first scan record }
  Pipe('|08þ |07Scanning for message scan record files ... ',TRUE);

  Path2SCN := AddSlash(RenegadeDatIn.MsgPath)+'*.SCN';
  {StrPCopy(Path2SCNPChar,Path2SCN);}
  tookoutcountscanrectot := 0;
  scanfilescount := 0;

  {$I-}FindFirst(Path2SCN{PChar},{fa}AnyFile,DirInfo);{$I+}
  
  WHILE (DOSError = 0) DO
	BEGIN	
	  { Initialize }
	  Skip := False;
	  C1   := 0;
	  TookOutCountScanRec := 0; { LeeW: Added }
	  Inc(ScanFilesCount);
	  
	  Pipe('   |08- |07'+DirInfo.Name+' :',TRUE); { Found scan file }
	  Path2SCN := AddSlash(RenegadeDatIn.MsgPath);

	  OpenSCN(Path2SCN+DirInfo.Name,FileErr);
	  IF FileErr THEN
		Error('|08þ |07Unable to open message scan file '+DirInfo.Name+'!');
	  OpenNewSCN(Path2SCN+'SCN.NEW',FileErr);
	  IF FileErr THEN
		Error('|08þ |07Unable to open message scan file SCN.NEW!');

	  { Generate new scan record file }
	  
	  {Pipe('|07þ Startting TO Synch Msgs Scan Records with User Records',TRUE);}
	  
	  Pipe('      |08- |07GENERATE ',FALSE);
	  
	  FOR RecCount := 0 TO FileSize(SCN)-1 DO
		BEGIN
		  { If record was deleted, then skip ... }
		  (*FOR C2 := 0 TO TookOutCount DO*)
			BEGIN
			  IF RecCount = TookOut[RecCount] THEN
				Skip := TRUE
			  ELSE
				Skip := FALSE;
			  {IF Skip THEN
				Break;}
			END;
		  { ... else write it to new record }
		  IF NOT Skip THEN
			BEGIN
			  {Pipe('|08þ |07Kept record #'+IntToStr(C1),TRUE);}
			  ReadFromSCN(SCNIn,RecCount);
			  WriteToNewSCN(SCNIn,C1);
			  Inc(C1);
			  (*Inc(SCNUpdateCount); { LeeW: Added }*)
			END
		  ELSE
			Inc(TookOutCountScanRec);
			{Pipe('Removed record #'+IntToStr(C1),TRUE);}
		END;
		
	  Pipe(Check,FALSE); { Successful generation }
		
	  IF (FileSize(SCN) > FileSize(NewSCN)) THEN 
		BEGIN { Records were removed }
		  { Delete old record and replace with new record }
		  Pipe(' |07DELETE ',FALSE); {}
		  Erase(SCN);
		  Pipe(Check,FALSE); {}
		  CloseSCN;
		  CloseNewSCN;
		  Assign(NewSCN,Path2SCN+'SCN.NEW');
		  Pipe(' |07RENAME ',FALSE);
		  Rename(NewSCN,Path2SCN+DirInfo.Name);
		  IF (IOResult <> 0) THEN
			Error('Unable to rename SCN.NEW to '+DirInfo.Name+'!')
	  	  ELSE
			Pipe(Check+' |07... ('+IntToStr(TookOutCountScanRec)+' '+Plural('record',TookOutCountScanRec)+' removed)',TRUE);
		END
	  ELSE
		BEGIN { No records were removed }
		  Pipe('',TRUE);
		  Pipe('      |08- |07No update required! ',TRUE);
		  {Pipe(Check,TRUE);}
		  { Close all records }
		  CloseSCN;
		  Erase(NewSCN);
		  CloseNewSCN;
		END;
	  Inc(tookoutcountscanrectot,tookoutcountscanrec);
	  {$I-}FindNext(DirInfo);{$I+}
	END;
  
  IF (DOSError <> 0) AND (ScanFilesCount = 0) THEN
	Error('|08þ |07Unable to locate any .SCN files!');
  
  { -- END OF MSG SCAN RECORDS -- }

  Pipe('|08þ |07Finished!',TRUE);
  Pipe('   |08- |07'+IntToStr(TookOutCountUser)+' user records removed|08',TRUE);
  Pipe('   |08- |07'+IntToStr(TookOutCountScanRecTot)+' scan records removed (from '
					+IntToStr(ScanFilesCount)+' scan files)',FALSE);
										
  Window(1,1,80,25);
  GoToXY(1,23);
END.
