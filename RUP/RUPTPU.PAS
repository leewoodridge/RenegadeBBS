UNIT RUPTPU;

INTERFACE

USES CRT, DOS, {WinDOS,} Strings, Runtime;

{$I RECORDS.INC}

FUNCTION  AddSlash(Str: String): String;
{*** RENEGADE.DAT ******************************************************}
PROCEDURE OpenRenegadeDat(Path: String; var err : boolean);
PROCEDURE ReadFromRenegadeDat(VAR RenegadeDatIn: GeneralRec);
PROCEDURE WriteToRenegadeDat(VAR RenegadeDatIn: GeneralRec);
PROCEDURE CloseRenegadeDat;
{*** USERS.DAT *********************************************************}
PROCEDURE OpenUsersDat(Path: String; var err : boolean);
PROCEDURE ReadFromUsersDat(VAR UsersDatIn: UserRec; Rec: Integer);
PROCEDURE WriteToUsersDat(VAR UsersDatIn: UserRec; Rec: Integer);
PROCEDURE CloseUsersDat;
{*** USERS.IDX *********************************************************}
PROCEDURE OpenUsersIdx(Path: String; var err : boolean);
PROCEDURE ReadFromUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE WriteToUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE CloseUsersIdx;
{*** USERS.NEW *********************************************************}
PROCEDURE OpenNewUsersDat(Path: String; var err : boolean);
PROCEDURE ReadFromNewUsersDat(VAR NewUsersDatIn: UserRec; Rec: Integer);
PROCEDURE WriteToNewUsersDat(VAR NewUsersDatIn: UserRec; Rec: Integer);
PROCEDURE CloseNewUsersDat;
{*** USER_New.Idx ******************************************************}
PROCEDURE OpenNewUsersIdx(Path: String; var err : boolean);
PROCEDURE ReadFromNewUsersIdx(VAR NewUsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE WriteToNewUsersIdx(VAR NewUsersIdxIn: UserIdxRec; Rec: Integer);
PROCEDURE CloseNewUsersIdx;
{*** *.SCN ** OLD ******************************************************}
PROCEDURE OpenSCN(Path_FileName: String; var err : boolean);
PROCEDURE ReadFromSCN(VAR ScnIn: ScanRec; Rec: Integer);
PROCEDURE CloseSCN;
{*** *.SCN ** NEW ******************************************************}
PROCEDURE OpenNewSCN(Path_FileName: String; var err : boolean);
PROCEDURE WriteToNewSCN(VAR NewScnIn: ScanRec; Rec: Integer);
PROCEDURE CloseNewSCN;

VAR
   RenegadeDat : FILE Of GeneralRec;

   UsersIdx    : FILE OF UserIdxRec;
   UsersDat    : FILE OF UserRec;

   NewUsersIdx : FILE OF UserIdxRec;
   NewUsersDat : FILE OF UserRec;

   Scn         : FILE OF ScanRec;
   NewScn      : FILE OF ScanRec;

   DirInfo     : SearchRec;

IMPLEMENTATION

FUNCTION  AddSlash(Str: String): String;
BEGIN
  IF Str <> '' THEN
    BEGIN
      IF Str[Length(Str)] <> '\' THEN
		AddSlash := Str + '\'
	  ELSE
		AddSlash := Str;
    END
  ELSE AddSlash := '';
END;

{*** RENEGADE.DAT ******************************************************}
PROCEDURE OpenRenegadeDat(Path: String; var err : boolean);
BEGIN
   Assign(RenegadeDat,AddSlash(Path) + 'RENEGADE.DAT');
   {$I-}Reset(RenegadeDat);{$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromRenegadeDat(VAR RenegadeDatIn: GeneralRec);
BEGIN
   Seek(RenegadeDat,0);
   Read(RenegadeDat,RenegadeDatIn);
END;
PROCEDURE WriteToRenegadeDat(VAR RenegadeDatIn: GeneralRec);
BEGIN
   Seek(RenegadeDat,0);
   Write(RenegadeDat,RenegadeDatIn);
END;
PROCEDURE CloseRenegadeDat;
BEGIN
   Close(RenegadeDat);
END;

{*** USERS.DAT *********************************************************}
PROCEDURE OpenUsersDat(Path: String; var err : boolean);
BEGIN
   Assign(UsersDat,AddSlash(Path) + 'users.dat');
   {$I-} Reset(UsersDat); {$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromUsersDat(VAR UsersDatIn: UserRec; Rec: Integer);
BEGIN
   Seek(UsersDat,Rec);
   Read(UsersDat,UsersDatIn);
END;
PROCEDURE WriteToUsersDat(VAR UsersDatIn: UserRec; Rec: Integer);
BEGIN
   Seek(UsersDat,Rec);
   Write(UsersDat,UsersDatIn);
END;
PROCEDURE CloseUsersDat;
BEGIN
   Close(UsersDat);
END;

{*** USERS.IDX *********************************************************}
PROCEDURE OpenUsersIdx(Path: String; var err : boolean);
BEGIN
   Assign(UsersIdx,AddSlash(Path) + 'users.idx');
   {$I-} Reset(UsersIdx); {$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(UsersIdx,Rec);
   Read(UsersIdx,UsersIdxIn);
END;
PROCEDURE WriteToUsersIdx(VAR UsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(UsersIdx,Rec);
   Write(UsersIdx,UsersIdxIn);
END;
PROCEDURE CloseUsersIdx;
BEGIN
   Close(UsersIdx);
END;

{*** USERS.NEW *********************************************************}
PROCEDURE OpenNewUsersDat(Path: String; var err : boolean);
BEGIN
   Assign(NewUsersDat,AddSlash(Path) + 'user_dat.new');
   {$I-}Rewrite(NewUsersDat);{$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromNewUsersDat(VAR NewUsersDatIn: UserRec; Rec: Integer);
BEGIN
   Seek(NewUsersDat,Rec);
   Read(NewUsersDat,NewUsersDatIn);
END;
PROCEDURE WriteToNewUsersDat(VAR NewUsersDatIn: UserRec; Rec: Integer);
BEGIN
   Seek(NewUsersDat,Rec);
   Write(NewUsersDat,NewUsersDatIn);
END;
PROCEDURE CloseNewUsersDat;
BEGIN
   Close(NewUsersDat);
END;

{*** USER_New.Idx ******************************************************}
PROCEDURE OpenNewUsersIdx(Path: String; var err : boolean);
BEGIN
   Assign(NewUsersIdx,AddSlash(Path) + 'user_idx.new');
   {$I-}Rewrite(NewUsersIdx); {$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromNewUsersIdx(VAR NewUsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(NewUsersIdx,Rec);
   Read(NewUsersIdx,NewUsersIdxIn);
END;
PROCEDURE WriteToNewUsersIdx(VAR NewUsersIdxIn: UserIdxRec; Rec: Integer);
BEGIN
   Seek(NewUsersIdx,Rec);
   Write(NewUsersIdx,NewUsersIdxIn);
END;
PROCEDURE CloseNewUsersIdx;
BEGIN
   Close(NewUsersIdx);
END;

{*** *.SCN ** OLD ******************************************************}
PROCEDURE OpenSCN(Path_FileName : String; var err : boolean);
BEGIN
   Assign(Scn,Path_FileName);
   {$I-} Reset(Scn); {$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE ReadFromSCN(Var ScnIn : ScanRec; Rec: Integer);
BEGIN
   Seek(Scn,Rec);
   Read(Scn,ScnIn);
END;
PROCEDURE CloseScn;
BEGIN
   Close(Scn);
END;

{*** *.SCN ** NEW ******************************************************}
PROCEDURE OpenNewSCN(Path_FileName : String; var err : boolean);
BEGIN
   Assign(NewScn,Path_FileName);
   {$I-} Rewrite(NewScn); {$I+}
   if ioresult <> 0 then Err := True
   else err := false;
END;
PROCEDURE WriteToNewSCN(Var NewScnIn : ScanRec; Rec: Integer);
BEGIN
   Seek(NewScn,Rec);
   Write(NewScn,NewScnIn);
END;
PROCEDURE CloseNewScn;
BEGIN
   Close(NewScn);
END;

END.

