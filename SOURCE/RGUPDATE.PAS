{$M 49152,0,65536}
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
     - COMPATIABLE WITH 1.25
    [TO DO]
     - 
}
PROGRAM RGUPDATE; { RENEGADE UPDATE UTILITY }

USES
  CRT,
  DOS,
  TimeFunc;

{$I RECORDS.INC}

CONST
  DYNY: BOOLEAN = FALSE;

TYPE
  OldGeneralRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { GENERAL RECORDS | RENEGADE.DAT }
    ForgotPWQuestion: STRING[70];      {  }
    QWKWelcome,                        { QWK welcome file name }
    QWKNews,                           { QWK news file name }
    QWKGoodbye,                        { QWK goodbye file name }
    Origin: STRING[50];                { Default Origin line }
    DataPath,                          { DATA path }
    MiscPath,                          { MISC path }
    LogsPath,                          { LOGS path }
    MsgPath,                           { MSGS path }
    NodePath,                          { NODE list path }
    TempPath,                          { TEMP path }
    ProtPath,                          { PROT path }
    ArcsPath,                          { ARCS path }
    TextPath,                         { MULT path }
    FileAttachPath,                    { directory for file attaches }
    QWKLocalPath,                      { QWK path for local usage }
    DefEchoPath,                       { default echomail path }
    NetmailPath,                       { path to netmail }
    BBSName: STRING[40];               { BBS name }
    SysOpName: STRING[30];             { SysOp's name }
    Version: STRING[20];
    BBSPhone: STRING[12];              { BBS phone number }
    LastDate: STRING[10];              { last system date }
    PacketName,                        { QWK packet name }
    BulletPrefix: STRING[8];           { default bulletins filename }
    { ACS }
    SysOpPW,                           { SysOp password }
    NewUserPW,                         { newuser password }
    MinBaudOverride,                   { override minimum baud rate }
    QWKNetworkACS,                     { QWK network REP ACS }
    LastOnDatACS,
    SOP,                               { SysOp }
    CSOP,                              { Co-SysOp }
    MSOP,                              { Message SysOp }
    FSOP,                              { File SysOp }
    SPW,                               { SysOp PW at logon }
    AddChoice,                         { Add voting choices acs }
    NormPubPost,                       { make normal public posts }
    NormPrivPost,                      { send normal e-mail }
    AnonPubRead,                       { see who posted public anon }
    AnonPrivRead,                      { see who sent anon e-mail }
    AnonPubPost,                       { make anon posts }
    AnonPrivPost,                      { send anon e-mail }
    SeeUnval,                          { see unvalidated files }
    DLUnval,                           { DL unvalidated files }
    NoDLRatio,                         { no UL/DL ratio }
    NoPostRatio,                       { no post/call ratio }
    NoFileCredits,                     { no file credits checking }
    ULValReq,                          { uploads require validation }
    TeleConfMCI,                       { ACS access for MCI codes while teleconfin' }
    OverrideChat,                      { override chat hours }
    NetMailACS,                        { do they have access to netmail? }
    Invisible,                         { Invisible mode? }
    FileAttachACS,                     { ACS to attach files to messages }
    ChangeVote,                        { ACS to change their vote }
    UnUsedACS1,
    UnUsedACS2: ACString;
    MaxPrivPost,                       { max email can send per call }
    MaxFBack,                          { max feedback per call }
    MaxPubPost,                        { max posts per call }
    MaxChat,                           { max sysop pages per call }
    MaxWaiting,                        { max mail waiting }
    CSMaxWaiting,                      { max mail waiting for Co-SysOp + }
    MaxMassMailList,
    MaxLogonTries,                     { tries allowed for PW's at logon }
    SysOpColor,                        { SysOp color in chat mode }
    UserColor,                         { user color in chat mode }
    SliceTimer,
    MaxBatchDLFiles,
    MaxBatchULFiles,
    Text_Color,                        { color OF standard text }
    Quote_Color,                       { color OF quoted text }
    Tear_Color,                        { color OF tear line }
    Origin_Color,                      { color OF origin line }
    BackSysOpLogs,                     { days to keep SYSOP##.LOG }
    EventWarningTime,                  { minutes before event to warn user }
    WFCBlankTime,                      { minutes before blanking WFC menu }
    AlertBeep,                         { time between alert beeps - Was Integer }
    FileCreditComp,                    { file credit compensation ratio }
    FileCreditCompBaseSize,            { file credit area compensation size }
    ULRefund,                          { percent OF time to refund on ULs }
    GlobalMenu,
    AllStartMenu,
    ShuttleLogonMenu,
    NewUserInformationMenu,
    FileListingMenu,
    MessageReadMenu,
    CurWindow,                         { type OF SysOp window in use }
    SwapTo,                            { Swap where?    }
    UnUsedByte1,
    UnUsedByte2: Byte;
    lLowTime,                          { SysOp begin minute (in minutes) }
    HiTime,                            { SysOp END time }
    DLLowTime,                         { normal downloading hours begin.. }
    DLHiTime,                          { ..and END }
    MinBaudLowTime,                    { minimum baud calling hours begin.. }
    MinBaudHiTime,                     { ..and END }
    MinBaudDLLowTime,                  { minimum baud downloading hours begin.. }
    MinBaudDLHiTime,                   { ..and END }
    NewApp,                            { send new user application to # }
    TimeOutBell,                       { minutes before timeout beep }
    TimeOut,                           { minutes before timeout }
    ToSysOpDir,                        { SysOp file area }
    CreditMinute,                      { Credits per minute }
    CreditPost,                        { Credits per post }
    CreditEmail,                       { Credits per Email sent }
    CreditFreeTime,                    { Amount OF "Free" time given to user at logon }
    NumUsers,                          { number OF users }
    PasswordChange,                    { change password at least every x days }
    RewardRatio,                       { % OF file points to reward back }
    CreditInternetMail,                { cost for Internet mail }
    BirthDateCheck,                    { check user's birthdate every xx logons }
    UnUsedInteger1,
    UnUsedInteger2: Integer;
    MaxQWKTotal,                       { max msgs in a packet, period }
    MaxQWKBase,                        { max msgs in a area }
    DaysOnline,                        { days online }
    UnUsedWord1,
    UnUsedWord2: Word;
    MinimumBaud,                       { minimum baud rate to logon }
    MinimumDLBaud,                     { minimum baud rate to download }
    MaxDepositEver,
    MaxDepositPerDay,
    MaxWithdrawalPerDay,
    CallerNum,                         { system caller number }
    RegNumber,                         { registration number }
    TotalCalls,                        { incase different from callernum }
    TotalUsage,                        { total usage in minutes }
    TotalPosts,                        { total number OF posts }
    TotalDloads,                       { total number OF dloads }
    TotalUloads,                       { total number OF uloads }
    MinResume,                         { min K to allow resume-later }
    MaxInTemp,                         { max K allowed in TEMP }
    MinSpaceForPost,                   { minimum drive space left to post }
    MinSpaceForUpload,                 { minimum drive space left to upload }
    UnUsedLongInt1,
    UnUsedLongInt2: LongInt;
    AllowAlias,                        { allow handles? }
    PhonePW,                           { phone number password in logon? }
    LocalSec,                          { use local security? }
    GlobalTrap,                        { trap everyone's activity? }
    AutoChatOpen,                      { automatically open chat buffer? }
    { Logon Toggles }
    AutoMInLogon,                      { Auto-Message at logon? }
    BullInLogon,                       { bulletins at logon? }
    YourInfoInLogon,                   { "Your Info" at logon? }
    OffHookLocalLogon,                 { phone off-hook for local logons? }
    ForceVoting,                       { manditory voting? }
    CompressBases,                     { "compress" file/msg area numbers? }
    SearchDup,                         { search for dupes files when UL? }
    ForceBatchDL,
    ForceBatchUL,
    LogonQuote,
    UserAddQuote,
    StripCLog,                         { strip colors from SysOp log? }
    SKludge,                           { show kludge lines? }
    SSeenby,                           { show SEEN-BY lines? }
    SOrigin,                           { show origin line? }
    AddTear,                           { show tear line? }
    ShuttleLog,                        { Use Shuttle Logon? }
    ClosedSystem,                      { Allow new users? }
    SwapShell,                         { Swap on shell? }
    UseEMS,                            { use EMS for overlay }
    UseBios,                           { use BIOS for video output }
    UseIEMSI,                          { use IEMSI }
    ULDLRatio,                         { use UL/DL ratios? }
    FileCreditRatio,                   { use auto file-credit compensation? }
    ValidateAllFiles,                  { validate files automatically? }
    FileDiz,                           { Search/Import file_id.diz }
    SysOpPword,                        { check for sysop password? }
    TrapTeleConf,                      { Trap teleconferencing to ROOMx.TRP? }
    IsTopWindow,                       { is window at top OF screen? }
    ReCompress,                        { recompress like archives? }
    RewardSystem,                      { use file rewarding system? }
    TrapGroup,                         { record group chats? }
    QWKTimeIgnore,                     { ignore time remaining for qwk download? }
    NetworkMode,                       { Network mode ? }
    WindowOn,                          { is the sysop window on? }
    ChatCall,                          { Whether system keeps beeping after chat}
    DailyLimits,                       { Daily file limits on/off }
    MultiNode,                         { enable multinode support }
    PerCall,                           { time limits are per call or per day?}
    TestUploads,                       { perform integrity tests on uploads? }
    UseLightBars,
    UnUsedBoolean0,
    UnUsedBoolean1,
    UnUsedBoolean2: Boolean;
    FileArcInfo:                       { archive specs }
      ARRAY [1..MaxArcs] OF FileArcInfoRecordType;
    FileArcComment:                    { BBS comment files for archives }
      ARRAY [1..3] OF STRING[40];
    Aka:                               { 20 Addresses } { 21st is for UUCP address }
      ARRAY [0..20] OF {$IFDEF WIN32} PACKED {$ENDIF} RECORD
      Zone,
      Net,
      Node,
      Point: Word;
    END;
    NewUserToggles:
	  ARRAY [1..20] OF Byte;
    Macro:                             { sysop macros }
	  ARRAY [0..9] OF STRING[100]; 
    Netattribute: NetAttribs;          { default netmail attribute }
    TimeAllow,                         { time allowance }
    CallAllow,                         { call allowance }
    DLRatio,                           { # ULs/# DLs ratios }
    DLKRatio,                          { DLk/ULk ratios }
    PostRatio,                         { posts per call ratio }
    DLOneday,                          { Max number OF dload files in one day}
    DLKOneDay: SecurityRangeType;      { Max k downloaded in one day}

    (*  
    Logon_OneLiners,                { OneLiners during logon? }
    Logon_OneLiners_Add,            { Prompt user to add a OneLiner during logon? }
    Logon_Voting: Boolean;          { Prompt user to vote on unvoted topics during logon? }
    
    AddQuoteACS,                    { Add A Quote }
    AddOneLinerACS: ACString;       { Add A OneLiner }
    
    Logon_LastCallers: Boolean;     { Display Last Callers Information During Logon }
    DefNumOneLiners: Integer;       { Default Number Of OneLiners To Display If MenuOption = 0 }
    DefNumLastCallers: Integer;     { Default Number Of LastCallers To Display If MenuOption = 0}
    TimeStampLogs: Boolean;         { Apply TimeStamp To Log Files? }
    
    DefSplitChat: Boolean;          { Use split chat as default? }
    
    NewAppMsgMandatory: Boolean;    { Are we forcing new user to send message to SysOp or just prompting? }
    MaxAnswerAttempts: Byte;        { Max answer attempts for questions before giving up } {**BYTE! DAMNIT***}
    *)
  END;
  
  OldACFlagType =(
    OldRLogon,                       { L - Limited to one call a day }
    OldRChat,                        { C - No SysOp paging }
    OldRValidate,                    { V - Posts are unvalidated }
    OldRUserList,                    { U - Can't list users }
    OldRAMsg,                        { A - Can't leave automsg }
    OldRPostAn,                      { * - Can't post anonymously }
    OldRPost,                        { P - Can't post }
    OldREmail,                       { E - Can't send email }
    OldRVoting,                      { K - Can't use voting booth }
    OldRMsg,                         { M - Force email deletion }

    OldVT100,                        { Supports VT00 }
    OldHotKey,                       { hotkey input mode }
    OldAvatar,                       { Supports Avatar }
    OldPause,                        { screen pausing }
    OldNovice,                       { user requires novice help }
    OldANSI,                         { Supports ANSI }
    OldColor,                        { Supports color }
    OldAlert,                        { Alert SysOp upon login }
    OldSMW,                          { Short message(s) waiting }
    OldNoMail,                       { Mailbox is closed }

    OldFNoDLRatio,                   { 1 - No UL/DL ratio }
    OldFNoPostRatio,                 { 2 - No post/call ratio }
    OldFNoCredits,                   { 3 - No credits checking }
    OldFNoDeletion);                 { 4 - Protected from deletion }

  OldACFlagSet = SET OF OldACFlagType;

  OldStatusFlagType =(
    OldLockedOut,                    { if locked out }
    OldDeleted,                      { if deleted }
    OldTrapActivity,                 { if trapping users activity }
    OldTrapSeparate,                 { if trap to seperate TRAP file }
    OldChatAuto,                     { if auto chat trapping }
    OldChatSeparate,                 { if separate chat file to trap to }
    OldSLogSeparate,                 { if separate SysOp log }
    OldCLSMsg,                       { if clear-screens }
    OldRIP,                          { if RIP graphics can be used }
    OldFSEditor,                     { if Full Screen Editor }
    OldAutoDetect,                   { Use auto-detected emulation }
    OldFileAreaLightBar,
    OldMsgAreaLightBar,
    OldUnUsedStatusFlag1,
    OldUnUsedStatusFlag2,
    OldUnUsedStatusFlag3
  );

  OldStatusFlagSet = SET OF OldStatusFlagType;

  OldUserRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { USER RECORDS | USERS.DAT }
    Name,                         { system name        }
    RealName: STRING[36];         { real name          }
    Street,                       { street address     }
    CityState: STRING[30];        { city, state        }
    CallerID: STRING[20];         { caller ID STRING   }
    ZipCode: STRING[10];          { zipcode            }
    PH: STRING[12];               { phone #            }
    ForgotPWAnswer: STRING[40];   {  }
    UsrDefStr: 
      ARRAY [1..3] OF STRING[35]; { definable strings  }
    Note: STRING[35];             { SysOp note         }
    LockedFile: STRING[8];        { print lockout msg  }
    Vote: ARRAY [1..25] OF Byte;  { voting data        }
    Sex,                          { gender             }
    Subscription,                 { their subscription }
    ExpireTo,                     { level to expire to }
    LastConf,                     { last conference in }
    UnUsedChar1,
    UnUsedChar2: Char;
    SL,                           { SL                 }
    DSL,                          { DSL                }
    Waiting,                      { mail waiting       }
    LineLen,                      { line length        }
    PageLen,                      { page length        }
    OnToday,                      { # times on today   }
    Illegal,                      { # illegal logons   }
    DefArcType,                   { QWK archive type   }
    ColorScheme,                  { Color scheme #     }
    UserStartMenu,                { menu to start at   }
    UnUsedByte1,
    UnUsedByte2: Byte;
    BirthDate,                    { Birth date         }
    FirstOn,                      { First On Date      }
    LastOn,                       { Last On Date       }
    TTimeOn,                      { total time on      }
    LastQWK,                      { last qwk packet    }
    Expiration,                   { Expiration date    }
    UnUsedUnixTime1,
    UnUsedUnixTime2: UnixTime;
    UserID,                       { Permanent userid   }
    TLToday,                      { # min left today   }
    ForUsr,                       { forward mail to    }
    LastMsgArea,                  { # last msg area    }
    LastFileArea,                 { # last file area   }
    UnUsedInteger1,
    UnUsedInteger2: Integer;
    PasswordChanged,              { Numeric date pw changed - was UnixTime }
    UnUsedWord1,
    UnUsedWord2: Word;
    lCredit,                      { Amount OF credit   }
    Debit,                        { Amount OF debit    }
    PW,                           { password           }
    Uploads,                      { # OF DLs           }
    Downloads,                    { # OF DLs           }
    UK,                           { UL k               }
    DK,                           { DL k               }
    LoggedOn,                     { # times on         }
    MsgPost,                      { # message posts    }
    EmailSent,                    { # email sent       }
    FeedBack,                     { # feedback sent    }
    TimeBank,                     { # mins in bank     }
    TimeBankAdd,                  { # added today      }
    DLKToday,                     { # kbytes dl today  }
    DLToday,                      { # files dl today   }
    FilePoints,                   {  }
    TimeBankWith,                 { Time withdrawn     }
    UnUsedLongInt1,
    UnUsedLongInt2: LongInt;
    TeleConfEcho,                 { Teleconf echo?     }
    TeleConfInt,                  { Teleconf interrupt }
    GetOwnQWK,                    { Get own messages   }
    ScanFilesQWK,                 { new files in qwk   }
    PrivateQWK,                   { private mail qwk   }
    UnUsedBoolean1,
    UnUsedBoolean2: Boolean;
    ARFlags: ARFlagSet;           { AR flags           }
    OldACFlags: OldACFlagSet;     { flags              }
    OldSFlags: OldStatusFlagSet;  { status flags       }
  END;
  
FUNCTION SqOutSp(s:STRING):STRING;
BEGIN
  WHILE (Pos(' ',s)>0) DO
	Delete(s,Pos(' ',s),1);
  SqOutSp:=s;
END;

FUNCTION Exist(fn: AStr): Boolean;
VAR
  SRec: SearchRec;
BEGIN
  FindFirst(SqOutSp(fn),AnyFile,SRec);
  Exist := (DOSError = 0);
END;

FUNCTION SYN(B: BOOLEAN): STRING;
BEGIN
  IF (B) THEN
    SYN := 'Yes'
  ELSE
    SYN := 'No ';
END;

FUNCTION YN: BOOLEAN;
VAR
  C: CHAR;
BEGIN
  Write(SQOutSp(SYN(DYNY)));
  REPEAT
    C := UpCase(Char(ReadKey));
  UNTIL (C IN ['Y','N',^M]);
  IF (DYNY) AND (C <> 'N') THEN
    C := 'Y';
  IF (DYNY) AND (C = 'N') THEN
    Write(#8#8#8'No ')
  ELSE IF (NOT DYNY) AND (C = 'Y') THEN
    Write(#8#8'Yes');
  WriteLn;
  YN := (C = 'Y');
  DYNY := FALSE;
END;

FUNCTION PYNQ(CONST S: AStr): BOOLEAN;
BEGIN
  Write(S);
  PYNQ := YN;
END;

PROCEDURE ChangeLength(S: STRING; VAR S1,S2: STRING);
VAR
  TempStr: STRING;
  Counter: Byte;
BEGIN
  IF (Length(S) <= 60) THEN
	BEGIN
      S1 := S;
      S2 := '';
	END
  ELSE
	BEGIN
      TempStr := Copy(S,1,65);
      IF (TempStr[65] <> ' ') THEN
		BEGIN
          Counter := 65;
		  WHILE (TempStr[Counter] <> ' ') DO
			BEGIN
			  Dec(TempStr[0]);
			  Dec(Counter);
			END;
		  Dec(TempStr[0]);
		  S1 := TempStr;
		  S2 := Copy(S,(Counter + 1),Length(S));
		END
      ELSE
		BEGIN
		  S1 := Copy(S,1,64);
		  S2 := Copy(S,66,Length(S));
		END;
	END;
END;

PROCEDURE Kill(CONST FileName: AStr);
VAR
  F: FILE;
BEGIN
  Assign(F,FileName);
  Erase(F);
END;

PROCEDURE ConvertGeneralRec;
VAR
  OldGeneralFile: FILE OF OldGeneralRecordType;
  GeneralFile: FILE OF GeneralRecordType;
  OldGeneral: OldGeneralRecordType;
  General: GeneralRecordType;
  Counter: Integer;
BEGIN
  Write('Converting "RENEGADE.DAT" file ... ');
  Assign(OldGeneralFile,'RENEGADE.DAT');
  Reset(OldGeneralFile);
  Assign(GeneralFile,'RENEGADE.NEW');
  ReWrite(GeneralFile);
  Seek(OldGeneralFile,0);
  Read(OldGeneralFile,OldGeneral);
  WITH General DO
  BEGIN
    ForgotPWQuestion := OldGeneral.ForgotPWQuestion;
    QWKWelcome := OldGeneral.QWKWelcome;
    QWKNews := OldGeneral.QWKNews;
    QWKGoodbye := OldGeneral.QWKGoodbye;
    Origin := OldGeneral.Origin;
    DataPath := OldGeneral.DataPath;
    MiscPath := OldGeneral.MiscPath;
    LogsPath := OldGeneral.LogsPath;
    MsgPath := OldGeneral.MsgPath;
    NodePath := OldGeneral.NodePath;
    TempPath := OldGeneral.TempPath;
    ProtPath := OldGeneral.ProtPath;
    ArcsPath := OldGeneral.ArcsPath;
    TextPath := OldGeneral.TextPath; {Remove? Same as data}
    FileAttachPath := OldGeneral.FileAttachPath;
    QWKLocalPath := OldGeneral.QWKLocalPath;
    DefEchoPath := OldGeneral.DefEchoPath;
    NetMailPath := OldGeneral.NetMailPath;
    BBSName := OldGeneral.BBSName;
    SysOpName := OldGeneral.SysOpName;
    Version := OldGeneral.Version; {LeeW: Update this!}
    BBSPhone := OldGeneral.BBSPhone;
    LastDate := OldGeneral.LastDate;
    PacketName := OldGeneral.PacketName;
    BulletPrefix := OldGeneral.BulletPrefix;
    SysOpPW := OldGeneral.SysOpPW;
    NewUserPW := OldGeneral.NewUserPW;
    MinBaudOverride := OldGeneral.MinBaudOverride;
    QWKNetworkACS := OldGeneral.QWKNetworkACS;
    LastOnDatACS := OldGeneral.LastOnDatACS;
    SOP := OldGeneral.SOP;
    CSOP := OldGeneral.CSOP;
    MSOP := OldGeneral.MSOP;
    FSOP := OldGeneral.FSOP;
    SPW := OldGeneral.SPW;
    AddChoice := OldGeneral.AddChoice;
    NormPubPost := OldGeneral.NormPubPost;
    NormPrivPost := OldGeneral.NormPrivPost;
    AnonPubRead := OldGeneral.AnonPubRead;
    AnonPrivRead := OldGeneral.AnonPrivRead;
    AnonPubPost := OldGeneral.AnonPubPost;
    AnonPrivPost := OldGeneral.AnonPrivPost;
    SeeUnval := OldGeneral.SeeUnval;
    DLUnval := OldGeneral.DLUnval;
    NoDLRatio := OldGeneral.NoDLRatio;
    NoPostRatio := OldGeneral.NoPostRatio;
    NoFileCredits := OldGeneral.NoFileCredits;
    ULValReq := OldGeneral.ULValReq;
    TeleConfMCI := OldGeneral.TeleConfMCI;
    OverrideChat := OldGeneral.OverrideChat;
    NetMailACS := OldGeneral.NetMailACS;
    Invisible := OldGeneral.Invisible; {Remove?}
    FileAttachACS := OldGeneral.FileAttachACS;
    ChangeVote := OldGeneral.ChangeVote;    
    UnUsedACS1 := OldGeneral.UnUsedACS1;
    UnUsedACS2 := OldGeneral.UnUsedACS2;
    MaxPrivPost := OldGeneral.MaxPrivPost;
    MaxFBack := OldGeneral.MaxFBack;
    MaxPubPost := OldGeneral.MaxPubPost;
    MaxChat := OldGeneral.MaxChat;
    MaxWaiting := OldGeneral.MaxWaiting;
    CSMaxWaiting := OldGeneral.CSMaxWaiting;
    MaxMassMailList := OldGeneral.MaxMassMailList;
    MaxLogonTries := OldGeneral.MaxLogonTries;
    SysOpColor := OldGeneral.SysOpColor; {}
    UserColor := OldGeneral.UserColor; {Should be in color config? & ^}
    SliceTimer := OldGeneral.SliceTimer;
    MaxBatchDLFiles := OldGeneral.MaxBatchDLFiles;
    MaxBatchULFiles := OldGeneral.MaxBatchULFiles;
    Text_Color := OldGeneral.Text_Color;
    Quote_Color := OldGeneral.Quote_Color;
    Tear_Color := OldGeneral.Tear_Color;
    Origin_Color := OldGeneral.Origin_Color;
    BackSysOpLogs := OldGeneral.BackSysOpLogs;
    EventWarningTime := OldGeneral.EventWarningTime;
    WFCBlankTime := OldGeneral.WFCBlankTime;
    AlertBeep := OldGeneral.AlertBeep;
    FileCreditComp := OldGeneral.FileCreditComp;
    FileCreditCompBaseSize := OldGeneral.FileCreditCompBaseSize;
    ULRefund := OldGeneral.ULRefund;
    GlobalMenu := OldGeneral.GlobalMenu;
    AllStartMenu := OldGeneral.AllStartMenu;
    ShuttleLogonMenu := OldGeneral.ShuttleLogonMenu;
    NewUserInformationMenu := OldGeneral.NewUserInformationMenu;
    FileListingMenu := OldGeneral.FileListingMenu;
    MessageReadMenu := OldGeneral.MessageReadMenu;
    CurWindow := OldGeneral.CurWindow;
    SwapTo := OldGeneral.SwapTo;
    UnUsedByte1 := OldGeneral.UnUsedByte1;
    UnUsedByte2 := OldGeneral.UnUsedByte2;
    lLowTime{ChatHoursStart} := OldGeneral.{ChatHoursStart}lLowTime;
    HiTime{ChatHoursEnd} := OldGeneral.{ChatHoursEnd}HiTime;
    DLLowTime := OldGeneral.DLLowTime;
    DLHiTime := OldGeneral.DLHiTime;
    MinBaudLowTime := OldGeneral.MinBaudLowTime;
    MinBaudHiTime := OldGeneral.MinBaudHiTime;
    MinBaudDLLowTime := OldGeneral.MinBaudDLLowTime;
    MinBaudDLHiTime := OldGeneral.MinBaudDLHiTime;
    NewApp := OldGeneral.NewApp;
    TimeOutBell := OldGeneral.TimeOutBell;
    TimeOut := OldGeneral.TimeOut;
    ToSysOpDir := OldGeneral.ToSysOpDir;
    CreditMinute := OldGeneral.CreditMinute;
    CreditPost := OldGeneral.CreditPost;
    CreditEmail := OldGeneral.CreditEmail;
    CreditFreeTime := OldGeneral.CreditFreeTime;
    NumUsers := OldGeneral.NumUsers;
    PasswordChange := OldGeneral.PasswordChange;
    RewardRatio := OldGeneral.RewardRatio;
    CreditInternetMail := OldGeneral.CreditInternetMail;
    BirthDateCheck := OldGeneral.BirthDateCheck;
    UnUsedInteger1 := OldGeneral.UnUsedInteger1;
    UnUsedInteger2 := OldGeneral.UnUsedInteger2;
    MaxQWKTotal := OldGeneral.MaxQWKTotal;
    MaxQWKBase := OldGeneral.MaxQWKBase;
    DaysOnline := OldGeneral.DaysOnline;
    UnUsedWord1 := OldGeneral.UnUsedWord1;
    UnUsedWord2 := OldGeneral.UnUsedWord2;
    MinimumBaud := OldGeneral.MinimumBaud;
    MinimumDLBaud := OldGeneral.MinimumDLBaud;
    MaxDepositEver := OldGeneral.MaxDepositEver;
    MaxDepositPerDay := OldGeneral.MaxDepositPerDay;
    MaxWithdrawalPerDay := OldGeneral.MaxWithdrawalPerDay;
    CallerNum := OldGeneral.CallerNum;
    RegNumber := OldGeneral.RegNumber; {is this used?}
    TotalCalls := OldGeneral.TotalCalls;
    TotalUsage := OldGeneral.TotalUsage;
    TotalPosts := OldGeneral.TotalPosts;
    TotalDloads := OldGeneral.TotalDloads;
    TotalUloads := OldGeneral.TotalUloads;
    MinResume := OldGeneral.MinResume;
    MaxInTemp := OldGeneral.MaxInTemp;
    MinSpaceForPost := OldGeneral.MinSpaceForPost;
    MinSpaceForUpload := OldGeneral.MinSpaceForUpload;
    UnUsedLongInt1 := OldGeneral.UnUsedLongInt1;
    UnUsedLongInt2 := OldGeneral.UnUsedLongInt2;
    AllowAlias := OldGeneral.AllowAlias;
    PhonePW := OldGeneral.PhonePW;
    LocalSec := OldGeneral.LocalSec;
    GlobalTrap{TrapActivity} := OldGeneral.{TrapActivity}GlobalTrap;
    AutoChatOpen{TrapChat} := OldGeneral.{TrapChat}AutoChatOpen;
    AutoMInLogon{Logon_AutoMessage} := OldGeneral.{Logon_AutoMessage}AutoMInLogon;
    BullInLogon{Logon_Bulletins} := OldGeneral.{Logon_Bulletins}BullInLogon;
    YourInfoInLogon{Logon_YourInfo} := OldGeneral.{Logon_YourInfo}YourInfoInLogon;
    OffHookLocalLogon := OldGeneral.OffHookLocalLogon;
    ForceVoting := OldGeneral.ForceVoting;
    CompressBases := OldGeneral.CompressBases;
    SearchDup := OldGeneral.SearchDup;
    ForceBatchDL := OldGeneral.ForceBatchDL;
    ForceBatchUL := OldGeneral.ForceBatchUL;
    LogonQuote := OldGeneral.LogonQuote; {naming convention?}
    UserAddQuote{Logon_Quote_Add} := OldGeneral.{Logon_Quote_Add}UserAddQuote;
    StripCLog := OldGeneral.StripCLog;
    SKludge := OldGeneral.SKludge;
    SSeenby := OldGeneral.SSeenby;
    SOrigin := OldGeneral.SOrigin;
    AddTear := OldGeneral.AddTear;
    ShuttleLog := OldGeneral.ShuttleLog;
    ClosedSystem := OldGeneral.ClosedSystem;
    SwapShell := OldGeneral.SwapShell;
    UseEMS := OldGeneral.UseEMS;
    UseBIOS := OldGeneral.UseBIOS;
    UseIEMSI := OldGeneral.UseIEMSI;
    ULDLRatio := OldGeneral.ULDLRatio;
    FileCreditRatio := OldGeneral.FileCreditRatio;
    ValidateAllFiles := OldGeneral.ValidateAllFiles;
    FileDiz := OldGeneral.FileDiz;
    SysOpPword := OldGeneral.SysOpPword; {nc}
    TrapTeleConf := OldGeneral.TrapTeleConf;
    IsTopWindow := OldGeneral.IsTopWindow;
    ReCompress := OldGeneral.ReCompress;
    RewardSystem := OldGeneral.RewardSystem;
    TrapGroup := OldGeneral.TrapGroup; {used?}
    QWKTimeIgnore := OldGeneral.QWKTimeIgnore; {used?}
    NetworkMode := OldGeneral.NetworkMode;
    WindowOn := OldGeneral.WindowOn;
    ChatCall := OldGeneral.ChatCall;
    DailyLimits := OldGeneral.DailyLimits;
    MultiNode := OldGeneral.MultiNode;
    PerCall := OldGeneral.PerCall;
    TestUploads := OldGeneral.TestUploads;
    UseLightBars := OldGeneral.UseLightBars;
    UnUsedBoolean0 := OldGeneral.UnUsedBoolean0;
    UnUsedBoolean1 := OldGeneral.UnUsedBoolean1;
    UnUsedBoolean2 := OldGeneral.UnUsedBoolean2;
    FOR Counter := 1 TO MaxArcs DO
      FileArcInfo[Counter] := OldGeneral.FileArcInfo[Counter];
    FOR Counter := 1 TO 3 DO
      FileArcComment[Counter] := OldGeneral.FileArcComment[Counter];
    FOR Counter := 0 TO 20 DO
      WITH AKA[Counter] DO
        BEGIN
          Zone := OldGeneral.AKA[Counter].Zone;
          Net := OldGeneral.AKA[Counter].Net;
          Node := OldGeneral.AKA[Counter].Node;
          Point := OldGeneral.AKA[Counter].Point;
        END;
    FOR Counter := 1 TO 20 DO
      NewUserToggles[Counter] := OldGeneral.NewUserToggles[Counter];
    FOR Counter := 0 TO 9 DO
      Macro[Counter] := OldGeneral.Macro[Counter];
    NetAttribute := OldGeneral.NetAttribute;
    TimeAllow := OldGeneral.TimeAllow;
    CallAllow := OldGeneral.CallAllow;
    DLRatio := OldGeneral.DLRatio;
    DLKRatio := OldGeneral.DLKRatio;
    PostRatio := OldGeneral.PostRatio;
    DLOneday := OldGeneral.DLOneDay;
    DLKOneDay := OldGeneral.DLKOneDay;
    (*
    Logon_OneLiners := OldGeneral.Logon_OneLiners;
    Logon_OneLiners_Add := OldGeneral.Logon_OneLiners_Add;
    Logon_Voting := OldGeneral.Logon_Voting;
    AddQuoteACS := OldGeneral.AddQuoteACS;
    AddOneLinerACS := OldGeneral.AddOneLinerACS;
    Logon_LastCallers := OldGeneral.Logon_LastCallers;
    DefNumOneLiners := OldGeneral.DefNumOneLiners;
    DefNumLastCallers := OldGeneral.DefNumLastCallers;
    TimeStampLogs := OldGeneral.TimeStampLogs;
    DefSplitChat := OldGeneral.DefSplitChat;
    NewAppMsgMandatory := OldGeneral.NewAppMsgMandatory;
    MaxAnswerAttempts := OldGeneral.MaxAnswerAttempts;
    *)
  END;
  Seek(GeneralFile,0);
  Write(GeneralFile,General);
  Close(OldGeneralFile);
  Close(GeneralFile);
  Assign(OldGeneralFile,'RENEGADE.DAT');
  Erase(OldGeneralFile);
  Assign(GeneralFile,'RENEGADE.NEW');
  ReName(GeneralFile,'RENEGADE.DAT');
  WriteLn('Done');
END;

PROCEDURE ConvertUserRec(OldGeneral: OldGeneralRecordType);
VAR
  OldUserFile: FILE OF OldUserRecordType;
  UserFile: FILE OF UserRecordType;
  OldUser: OldUserRecordType;
  User: UserRecordType;
  Counter,
  Counter1: Integer;
  { Adding ... }
  Country: STRING[50];
BEGIN
  Write('Converting "USERS.DAT" file ... ');
  Assign(OldUserFile,OldGeneral.DataPath+'USERS.DAT');
  Reset(OldUserFile);
  Assign(UserFile,OldGeneral.DataPath+'USERS.NEW');
  ReWrite(UserFile);
  Counter := 0;
  WHILE (Counter <= (FileSize(OldUserFile) - 1)) DO
    BEGIN
      Seek(OldUserFile,Counter);
      Read(OldUserFile,OldUser);
      WITH User DO
        BEGIN
          Name := OldUser.Name;
          RealName := OldUser.RealName;
          {Country := OldUser.Country;}
          Street := OldUser.Street;
          CityState := OldUser.CityState;
          CallerID := OldUser.CallerID;
          ZipCode := OldUser.ZipCode;
          PH := OldUser.PH;
          ForgotPWAnswer := OldUser.ForgotPWAnswer;
          FOR Counter1 := 1 TO 3 DO
            UsrDefStr[Counter1] := OldUser.UsrDefStr[Counter1];
          Note := OldUser.Note;
          LockedFile := OldUser.LockedFile;
          FOR Counter1 := 1 TO 25 DO
            Vote[Counter1] := OldUser.Vote[Counter1];
          Sex := OldUser.Sex;
          Subscription := OldUser.SubScription;
          ExpireTo := OldUser.ExpireTo;
          LastConf := OldUser.LastConf;
          UnUsedChar1 := ' ';
          UnUsedChar2 := ' ';
          SL := OldUser.SL;
          DSL := OldUser.DSL;
          Waiting := OldUser.Waiting;
          LineLen := OldUser.LineLen;
          PageLen := OldUser.PageLen;
          OnToday := OldUser.OnToday;
          Illegal := OldUser.Illegal;
          DefArcType := OldUser.DefArcType;
          ColorScheme := OldUser.ColorScheme;
          UserStartMenu := OldUser.UserStartMenu;
          UnUsedByte1 := 0;
          UnUsedByte2 := 0;
          BirthDate := OldUser.BirthDate;
          FirstOn := OldUser.FirstOn;
          LastOn := OldUser.LastOn;
          TTimeOn := OldUser.TTimeOn;
          LastQWK := OldUser.LastQWK;
          Expiration := OldUser.Expiration;
          UnUsedUnixTime1 := 0;
          UnUsedUnixTime2 := 0;
          UserID := OldUser.UserID;
          TLToday := OldUser.TLToday;
          ForUsr := OldUser.ForUsr;
          LastMsgArea := OldUser.LastMsgArea;
          LastFileArea := OldUser.LastFileArea;
          UnUsedInteger1 := 0;
          UnUsedInteger2 := 0;
          PasswordChanged := OldUser.PasswordChanged;
          UnUsedWord1 := 0;
          UnUsedWord2 := 0;
          LCredit := OldUser.LCredit;
          Debit := OldUser.Debit;
          PW := OldUser.PW;
          Uploads := OldUser.Uploads;
          Downloads := OldUser.Downloads;
          UK := OldUser.UK;
          DK := OldUser.DK;
          LoggedOn := OldUser.LoggedOn;
          MsgPost := OldUser.MsgPost;
          EmailSent := OldUser.EmailSent;
          FeedBack := OldUser.FeedBack;
          TimeBank := OldUser.TimeBank;
          TimeBankAdd := OldUser.TimeBankAdd;
          DLKToday := OldUser.DLKToday;
          DLToday := OldUser.DLToday;
          FilePoints := OldUser.FilePoints;
          TimeBankWith := OldUser.TimeBankWith;
          UnUsedLongInt1 := 0;
          UnUsedLongInt2 := 0;
          TeleConfEcho := OldUser.TeleConfEcho;
          TeleConfInt := OldUser.TeleConfInt;
          GetOwnQWK := OldUser.GetOwnQWK;
          ScanFilesQWK := OldUser.ScanFilesQWK;
          PrivateQWK := OldUser.PrivateQWK;
          UnUsedBoolean1 := FALSE;
          UnUsedBoolean2 := FALSE;
          ARFlags := OldUser.ARFlags;
          ACFlags := [];

          IF (OldRLogon IN OldUser.OldACFlags) THEN
            Include(ACFlags,RLogon);
          IF (OldRChat IN OldUser.OldACFlags) THEN
            Include(ACFlags,RChat);
          IF (OldRValidate IN OldUser.OldACFlags) THEN
            Include(ACFlags,RValidate);
          IF (OldRUserList IN OldUser.OldACFlags) THEN
            Include(ACFlags,RUserList);
          IF (OldRAMsg IN OldUser.OldACFlags) THEN
            Include(ACFlags,RAMsg);
          IF (OldRPostAn IN OldUser.OldACFlags) THEN
            Include(ACFlags,RPostAn);
          IF (OldRPost IN OldUser.OldACFlags) THEN
            Include(ACFlags,RPost);
          IF (OldREmail IN OldUser.OldACFlags) THEN
            Include(ACFlags,REmail);
          IF (OldRVoting IN OldUser.OldACFlags) THEN
            Include(ACFlags,RVoting);
          IF (OldRMsg IN OldUser.OldACFlags) THEN
            Include(ACFlags,RMsg);
          IF (OldVT100 IN OldUser.OldACFlags) THEN
            Include(ACFlags,VT100);
          IF (OldHotKey IN OldUser.OldACFlags) THEN
            Include(ACFlags,HotKey);
          IF (OldAvatar IN OldUser.OldACFlags) THEN
            Include(ACFlags,Avatar);
          IF (OldPause IN OldUser.OldACFlags) THEN
            Include(ACFlags,Pause);
          IF (OldNovice IN OldUser.OldACFlags) THEN
            Include(ACFlags,Novice);
          IF (OldANSI IN OldUser.OldACFlags) THEN
            Include(ACFlags,ANSI);
          IF (OldColor IN OldUser.OldACFlags) THEN
            Include(ACFlags,Color);
          IF (OldAlert IN OldUser.OldACFlags) THEN
            Include(ACFlags,Alert);
          IF (OldSMW IN OldUser.OldACFlags) THEN
            Include(ACFlags,SMW);
          IF (OldNoMail IN OldUser.OldACFlags) THEN
            Include(ACFlags,NoMail);
          IF (OldFNoDLRatio IN OldUser.OldACFlags) THEN
            Include(ACFlags,FNoDLRatio);
          IF (OldFNoPostRatio IN OldUser.OldACFlags) THEN
            Include(ACFlags,FNoPostRatio);
          IF (OldFNoCredits IN OldUser.OldACFlags) THEN
            Include(ACFlags,FNoCredits);
          IF (OldFNoDeletion IN OldUser.OldACFlags) THEN
            Include(ACFlags,FNoDeletion);

          SFlags := [];
          
          IF (OldLockedOut IN OldUser.OldSFlags) THEN
            Include(SFlags,LockedOut);
          IF (OldDeleted IN OldUser.OldSFlags) THEN
            Include(SFlags,Deleted);
          IF (OldTrapActivity IN OldUser.OldSFlags) THEN
            Include(SFlags,TrapActivity);
          IF (OldTrapSeparate IN OldUser.OldSFlags) THEN
            Include(SFlags,TrapSeparate);
          IF (OldChatAuto IN OldUser.OldSFlags) THEN
            Include(SFlags,ChatAuto);
          IF (OldChatSeparate IN OldUser.OldSFlags) THEN
            Include(SFlags,ChatSeparate);
          IF (OldSLogSeparate IN OldUser.OldSFlags) THEN
            Include(SFlags,SLogSeparate);
          IF (OldCLSMsg IN OldUser.OldSFlags) THEN
            Include(SFlags,CLSMsg);
          IF (OldRIP IN OldUser.OldSFlags) THEN
            Include(SFlags,RIP);
          IF (OldFSEditor IN OldUser.OldSFlags) THEN
            Include(SFlags,FSEditor);
          IF (OldAutoDetect IN OldUser.OldSFlags) THEN
            Include(SFlags,AutoDetect);
          IF (OldFileAreaLightBar IN OldUser.OldSFlags) THEN
            Include(SFlags,FileAreaLightBar);
          IF (OldMsgAreaLightBar IN OldUser.OldSFlags) THEN
            Include(SFlags,MsgAreaLightBar);
        END;
    Write(UserFile,User);
    Inc(Counter);
  END;
  Close(OldUserFile);
  Close(UserFile);
  Assign(OldUserFile,OldGeneral.DataPath+'USERS.DAT');
  Erase(OldUserFile);
  Assign(UserFile,OldGeneral.DataPath+'USERS.NEW');
  Rename(UserFile,OldGeneral.DataPath+'USERS.DAT');
  WriteLn('Done');
END;

VAR
  OldGeneralFile: FILE OF OldGeneralRecordType;
  OldGeneral: OldGeneralRecordType;
BEGIN
  ClrScr;
  WriteLn('Renegade Upgrade Utility (v1.XX to v1.XX)');  (* <-- UPDATE THIS WITH VERSION *)
  WriteLn;
  Writeln('This utility will upgrade your Renegade BBS from');
  WriteLn('Version 1.XX to Version 1.XX');   (* <-- UPDATE THIS WITH VERSION *)
  WriteLn;
  IF PYNQ('Do you want to continue? ') THEN
    BEGIN
      WriteLn;
      Write('Reading "RENEGADE.DAT" file ... ');
      Assign(OldGeneralFile,'RENEGADE.DAT');
      Reset(OldGeneralFile);
      Seek(OldGeneralFile,0);
      Read(OldGeneralFile,OldGeneral);
      Close(OldGeneralFile);
      WriteLn('Done');
      WriteLn;
      IF (Exist(OldGeneral.DataPath+'BATCHDL.DAT')) THEN
        BEGIN
          Write('Deleting "BATCHDL.DAT" file ... ');
          Kill(OldGeneral.DataPath+'BATCHDL.DAT');
          WriteLn('Done');
        END;
      ConvertUserRec(OldGeneral);
      ConvertGeneralRec;
    END;
END.