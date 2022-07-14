{
LeeW: search for ** to find proposed changes to data files
TODO: add user flag to force password change next logon 
10/07/2021 - Updated names of user flags so they're intuitive; ARFlags, ACFlags, S(tatus)Flags
12/02/2021 - Combined GeneralRec lightbar booleans, all lightbars either on or off now
03/13/2022 - Combined user statusflags msg & file lightbars into 1 - lightbars
}
CONST
  Build = '1.25';

{$IFDEF MSDOS}
  OS = '/DOS';
{$ENDIF}

{$IFDEF WIN32}
  OS = 'WIN32';
{$ENDIF}

{$IFDEF OS/2}
  OS = 'OS/2';
{$ENDIF}

  Ver = Build + OS;
  MaxProtocols = 120;
  MaxEvents = 10;
  MaxArcs = 8;
  MaxCmds = 200;
  MaxMenus = 200; { LeeW: Increased from 100 }
  MaxResultCodes = 20;
  MaxExtDesc = 99;
  MaxFileAreas = 32767;
  MaxMsgAreas = 32767;
  MaxConfigurable = 1024;
  MaxVotes = 25;
  MaxChoices = 25;
  MaxSchemes = 255;
  MaxValKeys = 92;
  MaxConfKeys = 27;

TYPE
  ASTR = STRING[160];
  STR1 = STRING[1];
  STR2 = STRING[2];
  STR3 = STRING[3];
  STR4 = STRING[4];
  STR5 = STRING[5];
  STR7 = STRING[7];
  STR8 = STRING[8];
  STR9 = STRING[9];
  STR11 = STRING[11];
  STR10 = STRING[10];
  STR12 = STRING[12];
  STR15 = STRING[15];
  STR20 = STRING[20];
  STR26 = STRING[26];
  STR30 = STRING[30];
  STR35 = STRING[35];
  STR36 = STRING[36];
  STR40 = STRING[40];
  STR50 = STRING[50];
  STR52 = STRING[52];
  STR65 = STRING[65];
  STR74 = STRING[74];
  STR78 = STRING[78];
  STR160 = STRING[160];

  UnixTime = LongInt; { Seconds since 01-01-70 }

  ACString = STRING[20]; { Access condition string }

  ARFlagType = '@'..'Z'; { AR flags }

  ARFlagSet = SET OF ARFlagType; { Set of AR flags }

  ACFlagType =
   (RLogon,                       { L - Limited to one call per day }
    RChat,                        { C - No SysOp paging }
    RValidate,                    { V - Posts are unvalidated }
    RUserList,                    { U - Can't list users }
    RAMsg,                        { A - Can't leave automsg }
    RPostAn,                      { * - Can't post anonymously }
    RPost,                        { P - Can't post publicly }
    REmail,                       { E - Can't send private mail }
    RVoting,                      { K - Can't vote }
    RMsg,                         { M - Forced email deletion }

    VT100,                        { Supports VT00 }
    HotKey,                       { hotkey input mode }
    Avatar,                       { Supports Avatar }
    Pause,                        { screen pausing }
    Novice,                       { user requires novice help }
    ANSI,                         { Supports ANSI }
    Color,                        { Supports color }
    Alert,                        { Alert SysOp upon login }
    SMW,                          { Short message(s) waiting }
    NoMail,                       { Mailbox is closed }
                                  { ** ^ ALL THESE MIDDLE ONES SHOULDN"T BE HERE -- MOVE }

    FNoDLRatio,                   { 1 - No UL/DL ratio }
    FNoPostRatio,                 { 2 - No post/call ratio }
    FNoCredits,                   { 3 - No credits checking }
    FNoDeletion);                 { 4 - Protected from deletion }

  ACFlagSet = SET OF ACFlagType;

  StatusFlagType =
    (LockedOut,                   { Is user locked out }
    Deleted,                      { Is user deleted }
    TrapActivity,                 { Is users activity being logged }
    TrapSeparate,                 { Is activity log separate file }
    ChatAuto,                     { Is users chat being logged }
    ChatSeparate,                 { Is chat log separate file }
    SLogSeparate,                 { Is users SysOp log entries separate file }
    
    CLSMsg,                       { Is user clearing screen between messages }
    RIP,                          { if RIP graphics can be used }
    FSEditor,                     { Is user using full-screen editor }
    AutoDetect,                   { Is user having emulation auto-detected }
    LightBars, { LeeW: Was FileAreaLightBar -- they're all combined into 1 now }
    
{
 ** ONLY FLAGS RELATED TO USER ACCOUNT STATUS SHOULD BE HERE -- MOVE CLSMSG,RIP,FSEditor,
 AutoDetect,lightbars OUT!!!
 ALSO alert SHOULD BE HERE
}
    UnUsedStatusFlag0, { LeeW: Was MsgAreaLightBar }
    UnUsedStatusFlag1,
    UnUsedStatusFlag2,
    UnUsedStatusFlag3
  );

  StatusFlagSet = SET OF StatusFlagType;

  ANonTyp =
   (ATNo,       { Anonymous posts not allowed }
    ATYes,      { Anonymous posts allowed }
    ATForced,   { Forced anonymous }
    ATDearAbby, { "Dear Abby"  }
    ATAnyName); { Post under any name }

  NetAttr =
    (Private,
     Crash,
     Recd,
     NSent,
     FileAttach,
     Intransit,
     Orphan,
     KillSent,
     Local,
     Hold,
     Unused,
     FileRequest,
     ReturnReceiptRequest,
     IsReturnReceipt,
     AuditRequest,
     FileUpdateRequest);

  NetAttribs = SET OF NetAttr;

  SecurityRangeType = ARRAY [0..255] OF LongInt; { Access tables }

  UserIDXRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { USERS.IDX : Sorted names listing }
    Name: STRING[36]; { Users handle or real name }
    Number,           { Users number }
    Left,             { Alphabetical sorting }
    Right: Integer;   { ^ }
    RealName,         { Is this the users real name? }
    Deleted: Boolean; { Is user deleted? }
  END;

  UserRec{ordType} = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { USERS.DAT : User records }
    Name,                        { User name }
    RealName: STRING[36];        { Real name }
    Street,                      { Street address }
(*  Country: STRING[45];         { Country } **)  
    CityState: STRING[30];       { City and state }
    CallerID: STRING[20];        { Caller ID/IP }
    ZipCode: STRING[10];         { Zip code }
    PH: STRING[12];              { Phone number }
    ForgotPWAnswer: STRING[40];  { Forgot password answer }
    UsrDefStr:                   { Answers to SysOp definable strings }
      ARRAY [1..3] OF STRING[35]; 
    Note: STRING[35];            { SysOp note }
    LockedFile: STRING[8];       { Lockout file filename }
    Vote: ARRAY [1..25] OF Byte; { Voting data }
    Sex,                         { Gender }
    Subscription,                { Subscription level }
    ExpireTo,                    { Subscription level to expire to }
    LastConf,                    { Last conference }
    UnUsedChar1,                 { / }
    UnUsedChar2: Char;           { / }

    SL,                          { SL }
    DSL,                         { DSL }
    Waiting,                     { Mail waiting? }
    LineLen,                     { Line length (columns) }
    PageLen,                     { Page length (rows) }
    OnToday,                     { Calls today }
    Illegal,                     { Illegal logons }
    DefArcType,                  { Default archive type (for QWK) }
    ColorScheme,                 { Color scheme number }
    UserStartMenu,               { Start menu number }
    UnUsedByte1,                 { / }
    UnUsedByte2: Byte;           { / }
    
    BirthDate,                   { Birth date }
    FirstOn,                     { First online date }
    LastOn,                      { Last online date }
    TTimeOn,                     { Total time online }
    LastQWK,                     { Last QWK packet date }
    Expiration,                  { Subscription expiration date }
    UnUsedUnixTime1,             { / }
    UnUsedUnixTime2: UnixTime;   { / }

    UserID,                      { Permanent user ID }
    TLToday,                     { Minutes left today }
    ForUsr,                      { Forward mail to user number }
    LastMsgArea,                 { Last message area number }
    LastFileArea,                { Last file area number }
    UnUsedInteger1,              { / }
    UnUsedInteger2: Integer;     { / }

    PasswordChanged,             { Number of days since last password change }
    UnUsedWord1,                 { / }
    UnUsedWord2: Word;           { / }
    
    lCredit,                     { Credits }
    Debit,                       { Debits }
    PW,                          { Password }
    Uploads,                     { Total uploads (# of files) }
    Downloads,                   { Total downloads (# of files) }
    UK,                          { Total uploaded (kB) }
    DK,                          { Total downloaded (kB) }
    LoggedOn,                    { Total calls }
    MsgPost,                     { Total public messages posted }
    EmailSent,                   { Total private messages sent }
    FeedBack,                    { Total SysOp feedback sent }
    TimeBank,                    { Minutes in timebank }
    TimeBankAdd,                 { Minutes added to timebank today }
    DLKToday,                    { Downloads today (kB) }
    DLToday,                     { Downloads today (# of files) }
(*
    ULKToday,                    { Uploads today (kB) }
    ULToday,                     { Uploads today (# of files) }
**)
    FilePoints,                  { File points }
    TimeBankWith,                { Minutes withdrawn from timebank today }
    UnUsedLongInt1,              { / }
    UnUsedLongInt2: LongInt;     { / }

    TeleConfEcho,                { TeleConference echo? } (**REMOVE--UNUSEDor will be when teleconf finished**)
    TeleConfInt,                 { TeleConference interrupt? } (**REMOVE--UNUSED**)
    GetOwnQWK,                   { Own messages in QWK? }
    ScanFilesQWK,                { New files in QWK? }
    PrivateQWK,                  { Private mail in QWK? }
    UnUsedBoolean1,              { / }
    UnUsedBoolean2: Boolean;     { / }

    ARFlags: ARFlagSet;          { AR flags }
    ACFlags: ACFlagSet;          { AC flags }
    SFlags: StatusFlagSet;       { Status flags }
  END; { END OF USERREC }
  
  MsgStatusR =(
    MDeleted,
    Sent,
    Unvalidated,
    Permanent,
    AllowMCI,
    NetMail,
    Prvt,
    Junked);

  FromToInfo = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { from/to information for mheaderrec }
    Anon: Byte;       { Anonymous? }
    UserNum: Word;    { User number }
    A1S: STRING[36];  { Posted as }
    Real: STRING[36]; { Real name }
    Name: STRING[36]; { User name }
    Zone,
    Net,
    Node,
    Point: Word;
  END;

  MHeaderRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    From,                      { Sender } 
    MTO: FromToInfo;           { Receiver }
    Pointer: LongInt;          { starting record OF text }
    TextSize: Word;            { size OF text }
    ReplyTo: Word;             { ORIGINAL + REPLYTO = CURRENT }
    Date: UnixTime;            { Date and time }
    DayOfWeek: Byte;           { message day OF week }
    Status: SET OF MsgStatusR; { message status flags }
    Replies: Word;             { times replied to }
    Subject: STRING[40];       { Message subject }
    OriginDate: STRING[19];    { date OF echo/group msgs }
    FileAttached: Byte;        { Is there a file attached? 0=No, 1=Yes&Del, 2=Yes&Save }
    NetAttribute: NetAttribs;  { NetMail attributes }
    Res: ARRAY [1..2] OF Byte; { Reserved }
  END;

  HistoryRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { HISTORY.DAT : Summary logs }
    Date: UnixTime;
    Active,
    Callers,
    NewUsers,
    Posts,
    Email,
    FeedBack,
    Errors,
    Uploads,
    Downloads,
    UK,
    DK: LongInt;
    UserBaud: ARRAY [0..20] OF LongInt;
  END;

  FileArcInfoRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { Archive configuration records }
    Active: Boolean;     { Is this archiver active? }
    Ext: STRING[3];      { File extension }
    ListLine,            { /X for internal; X: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH }
    ArcLine,             { Compression command }
    UnArcLine,           { DeCompression command }
    TestLine,            { Integrity test command }
    CmtLine: STRING[25]; { Comment add command }
    SuccLevel: Integer;  { Success errorlevel; -1=Ignore results }
  END;

  ModemFlagType =( { MODEM.DAT | Status flags }
    LockedPort, { COM port locked at constant rate }
    XOnXOff,    { XON/XOFF (software) flow control }
    CTSRTS);    { CTS/RTS (hardware) flow control }

  MFlagSet = SET OF ModemFlagType;

  LineRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    InitBaud: LongInt;           { initialization baud }
    ComPort: Byte;               { COM port number }
    MFlags: MFlagSet;            { status flags }
    Init,                        { init STRING }
    Answer,                      { answer STRING or blank }
    Hangup,                      { hangup STRING }
    Offhook: STRING[30];         { phone off-hook STRING }
    DoorPath,                    { door drop files written to }
    TeleConfNormal,              { Teleconferencing strings } (** REMOVE ALL OF THESE -- IN MAIN LNG NOW! *)
    TeleConfAnon,                { ^ }
    TeleConfGlobal,              { ^ }
    TeleConfPrivate: STRING[40]; { ^ }
    Ok,                          { Modem strings }
    Ring,                        { ^ }
    Reliable,                    { ^ }
    CallerID,                    { ^ }
    NoCarrier: STRING[20];       { ^ }
    Connect:                     { 300,   600,   1200,  2400,  4800,  7200,  9600,  12000, 14400, 16800, 19200,
                                   21600, 24000, 26400, 28800, 31200, 33600, 38400, 57600, 115200 + 2 extra }
      ARRAY [1..22] OF STRING[20];
    UseCallerID: Boolean;        { Insert Caller ID into sysop note? } (** THIS ISN'T USED -- REMOVE! *)
    LogonACS: ACString;          { ACS for this node }
    IRQ,                         { Functional MCI: %E = IRQ }
    Address: STRING[10];         { Functional MCI: %C = Comport address }
    AnswerOnRing: Byte;          { Answer after how many rings? }
    MultiRing: Boolean;          { Answer Ringmaster or some other type OF multiple-ring system ONLY }
    NodeTelnetURL: STRING[65];   { Telnet URL } (** WHY IS THIS HERE? -- DELETE AND MOVE TO GENERALREC **)
  END;

  ValidationRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    Key,                     { Key '!' to '~' }
    ExpireTo: Char;          { Validation level to expire to }
    Description: STRING[30]; { Validation level description }
    UserMsg: STRING[78];     { Message sent to user upon validation }
    NewSL,                   { New SL }
    NewDSL,                  { New DSL }
    NewMenu: Byte;           { User start menu }
    Expiration: Word;        { Days until expiration }
    NewFP,                   { Filepoints given }
    NewCredit: LongInt;      { Credit given }
    SoftAR,                  { Soft AR flag upgrade? T=Update, F=Replace }
    SoftAC: Boolean;         { Soft AC flag upgrade? T=Update, F=Replace }
    NewAR: ARFlagSet;        { New AR flags }
    NewAC: ACFlagSet;        { New AC flags }
  END;

  GeneralRec{ordType} = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { RENEGADE.DAT }
    ForgotPWQuestion: STRING[70];   { Forgot password question }
    QWKWelcome,                     { QWK: Welcome file name }
    QWKNews,                        { QWK: News file name }
    QWKGoodbye,                     { QWK: Goodbye file name }
    Origin: STRING[50];             { Default origin line }
    DataPath,                       { Data files path }
    MiscPath,                       { Miscellaneous (Art) files path }
    LogsPath,                       { Log files path }
    MsgPath,                        { Message area data files path }
    NodePath,                       { NetMail nodelist (V7) path }
    TempPath,                       { Temporary files path }
    ProtPath,                       { Protocols path }
    ArcsPath,                       { Archivers path }
    TextPath,                       { Text path - language files, quotes, taglines }
    FileAttachPath,                 { File attachments path }
    QWKLocalPath,                   { QWK: Path for local usage }
    DefEchoPath,                    { Default EchoMail path }
    NetMailPath,                    { Default NetMail path }
    BBSName: STRING[40];            { BBS name }
    SysOpName: STRING[30];          { SysOps name }
    Version: STRING[20];            { Renegade BBS version }
    BBSPhone: STRING[12];           { BBS phone number }
(*  BBSTelnetURL: STRING[65];       { BBS telnet URL } **)
    LastDate: STRING[10];           { Last system date }
    PacketName,                     { QWK: Packet name }
    BulletPrefix: STRING[8];        { default bulletins filename }
    SysOpPW,                        { SysOp password }
    NewUserPW,                      { New user password }
    MinBaudOverride: STRING[20];    { Override minimum baud rate password }
    { ACS }
    QWKNetworkACS,                  { QWK network REP ACS }
    LastOnDatACS,                   {  }
    SOP,                            { SysOp }
    CSOP,                           { Co-SysOp }
    MSOP,                           { Message SysOp }
    FSOP,                           { File SysOp }
    SPW,                            { SysOp PW at logon }
    AddChoice,                      { Add voting choices acs }
    NormPubPost,                    { make normal public posts }
    NormPrivPost,                   { send normal e-mail }
    AnonPubRead,                    { see who posted public anon }
    AnonPrivRead,                   { see who sent anon e-mail }
    AnonPubPost,                    { make anon posts }
    AnonPrivPost,                   { send anon e-mail }
    SeeUnval,                       { see unvalidated files }
    DLUnval,                        { DL unvalidated files }
    NoDLRatio,                      { no UL/DL ratio }
    NoPostRatio,                    { no post/call ratio }
    NoFileCredits,                  { no file credits checking }
    ULValReq,                       { uploads require validation }
    TeleConfMCI,                    { ACS access for MCI codes while teleconfin' }
    OverrideChat,                   { override chat hours }
    NetMailACS,                     { do they have access to netmail? }
    Invisible,                      { Invisible mode? }
    FileAttachACS,                  { ACS to attach files to messages }
    ChangeVote,                     { ACS to change their vote }
    UnUsedACS1,                     { / }
    UnUsedACS2: ACString;           { / }
    
    MaxPrivPost,                    { max email can send per call }
    MaxFBack,                       { max feedback per call }
    MaxPubPost,                     { max posts per call }
    MaxChat,                        { max sysop pages per call }
    MaxWaiting,                     { max mail waiting }
    CSMaxWaiting,                   { max mail waiting for Co-SysOp + }
    MaxMassMailList,                {  }
    MaxLogonTries,                  { tries allowed for PW's at logon }
    SysOpColor,                     { SysOp chat color }
    UserColor,                      { User char color }
    SliceTimer,                     {  }
    MaxBatchDLFiles,                {  }
    MaxBatchULFiles,                {  }
    Text_Color,                     { Color of message standard text }
    Quote_Color,                    { Color of message quoted text }
    Tear_Color,                     { Color of message tear line }
    Origin_Color,                   { Color of message origin line }
    BackSysOpLogs,                  { Number of days to keep SysOp logs }
    EventWarningTime,               { Minutes before warning user of upcoming event }
    WFCBlankTime,                   { Minutes before blanking out WFC menu }
    AlertBeep,                      { time between alert beeps - Was Integer }
    FileCreditComp,                 { file credit compensation ratio }
    FileCreditCompBaseSize,         { file credit area compensation size }
    ULRefund,                       { percent OF time to refund on ULs }
    GlobalMenu,                     { Menu # }
    AllStartMenu,                   { ^ }
    ShuttleLogonMenu,               { ^ }
    NewUserInformationMenu,         { ^ }
    FileListingMenu,                { ^ }
    MessageReadMenu,                { ^ }
    CurWindow,                      { Type of SysOp window in use }
    SwapTo,                         { Swap to where? }
    UnUsedByte1,                    { / }
    UnUsedByte2: Byte;              { / }
    
    lLowTime,                       { SysOp chat hours start time }
    HiTime,                         { SysOp chat hours end time }
    DLLowTime,                      { Download hours start time }
    DLHiTime,                       { Download hours end time }
    MinBaudLowTime,                 { Minimum baud caller hours start time }
    MinBaudHiTime,                  { Minimum baud caller hours end time }
    MinBaudDLLowTime,               { Minimum baud download hours start time }
    MinBaudDLHiTime,                { Minimum baud download hours end time }
    NewApp,                         { send new user application to # }
    TimeOutBell,                    { Minutes before timeout warning beep }
    TimeOut,                        { Minutes before timeout logoff }
    ToSysOpDir,                     { "To SysOp" file area }
    CreditMinute,                   { Credits per minute }
    CreditPost,                     { Credits per post }
    CreditEmail,                    { Credits per e-mail }
    CreditFreeTime,                 { Amount of "free" time given to users with no credits at logon }
    NumUsers,                       { Number of users }
    PasswordChange,                 { Mandatory password change every X days }
    RewardRatio,                    { Percentage of file points to reward back }
    CreditInternetMail,             { Credits per internet e-mail }
    BirthDateCheck,                 { Check users birthdate every # logons }
    UnUsedInteger1,                 { / }
    UnUsedInteger2: Integer;        { / }
    
    MaxQWKTotal,                    { Maximum messages in a QWK packet }
    MaxQWKBase,                     { Maximum messages per area }
    DaysOnline,                     { Days online }
    UnUsedWord1,                    { / }
    UnUsedWord2: Word;              { / }
    
    MinimumBaud,                    { Minimum baud rate to logon }
    MinimumDLBaud,                  { Minimum baud rate to download }
    MaxDepositEver,                 { Maximum minutes allowed in time bank }
    MaxDepositPerDay,               { Maximum minutes allowed for daily deposit }
    MaxWithdrawalPerDay,            { Maximum minutes allowed for daily withdrawal }
    CallerNum,                      { system caller number }
    RegNumber,                      { registration number }                 (** UNUSED -- DELETE? **)
    TotalCalls,                     { incase different from callernum }
    TotalUsage,                     { total usage in minutes }
    TotalPosts,                     { total number OF posts }
    TotalDloads,                    { total number OF dloads }
    TotalUloads,                    { total number OF uloads }
    MinResume,                      { min K to allow resume-later }
    MaxInTemp,                      { max K allowed in TEMP }
    MinSpaceForPost,                { Minimum drive space required for posts }
    MinSpaceForUpload,              { Minimum drive space required for uploads }
    UnUsedLongInt1,                 { / }
    UnUsedLongInt2: LongInt;        { / }
    
    AllowAlias,                     { Allow handles? }
    PhonePW,                        { phone number password in logon? }
    LocalSec,                       { use local security? }
    GlobalTrap,                     { trap everyone's activity? }
    AutoChatOpen,                   { automatically open chat buffer? }
    AutoMInLogon,                   { Auto-message during logon? }
    BullInLogon,                    { bulletins at logon? }
    YourInfoInLogon,                { "Your Info" at logon? }
    OffHookLocalLogon,              { phone off-hook for local logons? }
    ForceVoting,                    { Is voting mandatory? } (* NOT HOOKED UP, BUT I INTEND TO *)
    CompressBases,                  { "compress" file/msg area numbers? }
    SearchDup,                      { Search for dupes on UL? }
    ForceBatchDL,                   {  }
    ForceBatchUL,                   {  }
    LogonQuote,                     { Display random quote during logon? }
    UserAddQuote,                   { Prompt user to add quote -- LeeW: make this during logon only, will add acs later}
    StripCLog,                      { strip colors from SysOp log? }
    SKludge,                        { Show kludge lines? }
    SSeenby,                        { Show seen-by lines? }
    SOrigin,                        { Show origin line? }
    AddTear,                        { Show tear line? }
    ShuttleLog,                     { Use shuttle logon? }
    ClosedSystem,                   { Allow new users? }
    SwapShell,                      { Swap on shell? }
    UseEMS,                         { Use EMS for overlay? }
    UseBios,                        { Use BIOS for video output? }
    UseIEMSI,                       { Use IEMSI handshakes? }
    ULDLRatio,                      { Are UL/DL ratios active? }
    FileCreditRatio,                { use auto file-credit compensation? }
    ValidateAllFiles,               { validate files automatically? }
    FileDIZ,                        { Search for and import FILE_ID.DIZ? }
    SysOpPword,                     { check for sysop password? }
    TrapTeleConf,                   { Trap teleconferencing to ROOMx.TRP? }
    IsTopWindow,                    { is window at top OF screen? }
    ReCompress,                     { recompress like archives? }
    RewardSystem,                   { use file rewarding system? }
    TrapGroup,                      { record group chats? } (** UNUSED -- REMOVE THIS! or implement??**)
    QWKTimeIgnore,                  { ignore time remaining for qwk download? }
    NetworkMode,                    { Network mode ? }
    WindowOn,                       { is the sysop window on? }
    ChatCall,                       { Whether system keeps beeping after chat}
    DailyLimits,                    { Daily file limits }
    MultiNode,                      { MultiNode mode }
    PerCall,                        { time limits are per call or per day?}
    TestUploads,                    { perform integrity tests on uploads? }
    UseLightBars,                   { use LightBars? }
    UnUsedBoolean0,                 { / }
    UnUsedBoolean1,                 { / }
    UnUsedBoolean2: Boolean;        { / }

    FileArcInfo:                    { archive specs }
      ARRAY [1..MaxArcs] OF FileArcInfoRecordType;

    FileArcComment:                 { BBS comment files for archives }
      ARRAY [1..3] OF STRING[40];

    Aka:                            { 20 Addresses + 21st for UUCP address }
      ARRAY [0..20] OF {$IFDEF WIN32} PACKED {$ENDIF} RECORD 
        Zone,                           
        Net,
        Node,
        Point: Word;
      END;

    NewUserToggles:                 { OLD Toggles for new user application questions ** UNUSED -- REMOVE **}
      ARRAY [1..20] OF Byte;

    Macro:                          { SysOp macros }
      ARRAY [0..9] OF STRING[100];
      
    NetAttribute: NetAttribs;       { Default NetMail attributes }

    TimeAllow,                      { Time allowance }
    CallAllow,                      { Call allowance }
    DLRatio,                        { File ratio (#) }
    DLKRatio,                       { File ratio (kB) }
    PostRatio,                      { Posts per call ratio }
    DLOneday,                       { Max daily downloads (#) }
    DLKOneDay: SecurityRangeType;   { Max daily downloads (kB) }
    
    { ** FIELDS BELOW HAVE BEEN ADDED AFTER V1.25 ** }
    
    NewUserQToggles:                { Toggles for new user application questions }
      ARRAY [1..30] OF Boolean;
    OneLinersNewTop,                { Newest OneLiners on top? }
    LogonLastCallers,               { Display Last Callers Information During Logon }
    LogonOneLiners,                 { OneLiners during logon? }
    LogonVoting: Boolean;           { Prompt user to vote on topics during logon? (or force if mandatory) }
    AddQuoteACS,                    { Add A Quote ACS }
    AddOneLinerACS: ACString;       { Add A OneLiner ACS }
    TopFilesDownload,               { Prompt user to download top files? }
    TimeStampLogs,                  { Apply TimeStamp To Log Files? }
    DefSplitChat: Boolean;          { Use split chat as default? }
    
    (*
    { ** THINGS I INTEND TO IMPLEMENT ** }
    
    DefNumOneLiners: SmallInt;      { Default Number Of OneLiners To Display If MenuOption = 0 }
    DefNumLastCallers: SmallInt;    { Default Number Of LastCallers To Display If MenuOption = 0}
    
    NewAppMsgMandatory: Boolean;    { Are we forcing new user to send message to SysOp or just prompting? }
    MaxAnswerAttempts: Byte;        { Max answer attempts for questions before giving up }
    *)
    
  END; { END OF GENERALREC }

  ShortMessageRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { SHORTMSG.DAT : One-line messages }
    Msg: AStr;       {  }
    Destin: Integer; {  }
  END;

  VotingRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { VOTING.DAT : Voting records }
    Question1,                  { Voting Question 1 }
    Question2: STRING[60];      { Voting Question 2 }
    ACS: ACString;              { ACS required to vote on this }
    ChoiceNumber: Byte;         { number OF choices }
    NumVotedQuestion: Integer;  { number OF votes on it }
    CreatedBy: STRING[36];      { who created it }
(*  QDateAdded: DateTime;       { Date & Time Question Added } **)
    AddAnswersACS: ACString;    { ACS required to add choices }
    Answers: ARRAY [1..25] OF {$IFDEF WIN32} PACKED {$ENDIF} RECORD
      Answer1,                  { answer description }
      Answer2: STRING[65];      { answer description #2 }
(*    
      AnswerAuthor: STRING[36]; { Author Of Answer }
      ADateAdded: DateTime;     { Date & Time Answer Added }
**)  
      NumVotedAnswer: Integer;  { # user's who picked this answer }
    END;
  END;

  MessageAreaFlagType =(
    MARealName,  { whether real names are forced }
    MAUnHidden,  { whether *VISIBLE* to users w/o access }
    MAFilter,    { whether to filter ANSI/8-bit ASCII }
    MAPrivate,   { allow private messages }
    MAForceRead, { force the reading of this area }
    MAQuote,     { Allow Quote/Tagline to messages posted in this area ** RENAME THIS MATagLine **}
    MASKludge,   { strip IFNA kludge lines }
    MASSeenBy,   { strip SEEN-BY lines }
    MASOrigin,   { strip origin lines }
    MAAddTear,   { add tear/origin lines }
    MAInternet,  { if internet message area }
    MAScanOut);  { Needs to be scanned out by renemail }

  MAFlagSet = SET OF MessageAreaFlagType;

  MessageAreaRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { MBASES.DAT : Message area records }
    Name: STRING[40];       { Message area name }
    FileName: STRING[8];    { HDR/DAT data filename }
    MsgPath: STRING[40];    { messages pathname   } (** NOT USED -- DELETE **)
    ACS,                    { Access ACS }
    PostACS,                { Post ACS }
    MCIACS,                 { MCI ACS }
    SysOpACS: ACString;     { SysOp ACS }
    MaxMsgs: Word;          { Maximum Messages }
    Anonymous: AnonTyp;     { Anonymous type }
    Password: STRING[20];   { Password }
    MAFlags: MAFlagSet;     { Area flags }
    MAType: Integer;        { Area type (0=Local,1=Echo,3=QWK) }
    Origin: STRING[50];     { Origin line }
    Text_Color,             { Color of standard text } {**CHANGE THESE TO STRING[6] "|00|00" **}
    Quote_Color,            { Color of quoted text }
    Tear_Color,             { Color of tear line }
    Origin_Color,           { Color of origin line }
    MessageReadMenu: Byte;  {  }
    QuoteStart,             {  }
    QuoteEnd: STRING[70];   {  }
    PrePostFile: STRING[8]; {  }
    AKA: Byte;              { alternate address }
    QWKIndex: Word;         { QWK indexing number }
  END;

  FileAreaFlagType =(
    FANoRatio,      { File area has no ratio }
    FAUnHidden,     { Visible to users without access? }
    FADirDLPath,    { if *.DIR file stored in DLPATH }
    FAShowName,     { Show uploaders username }
    FAUseGIFSpecs,  { whether to use GifSpecs }
    FACDROM,        { Area is read only, no sorting or ul scanning }
    FAShowDate,     { Show date uploaded in listings }
    FANoDupeCheck); { No dupe check on this area }

  FAFlagSet = SET OF FileAreaFlagType;

  FileAreaRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { FBASES.DAT  : File area records }
    AreaName: STRING[40]; { area description  }
    FileName: STRING[8];  { filename + ".DIR" }
    DLPath,               { download path     }
    ULPath: STRING[40];   { upload path       }
    MaxFiles: Integer;    { max files allowed - VerbRec Limit would allow up to LongInt Value or Maximum 433835}
    Password: STRING[20]; { password required }
    ArcType,              { Wanted archive type (1..255,0=Inactive) }
    CmtType: Byte;        { Wanted comment type (1..3,0=Inactive) }
    ACS,                  { access requirements }
    ULACS,                { upload requirements }
    DLACS: ACString;      { download requirements }
    FAFlags: FAFlagSet;   { file area status vars }
  END;

  FileInfoFlagType =
   (FINotVal,        { If file is not validated }
    FIIsRequest,     { If file is REQUEST }
    FIResumeLater,   { If file is RESUME-LATER }
    FIHatched,       { Has file been hatched? }
    FIOwnerCredited, {  }
    FIUnusedFlag1,
    FIUnusedFlag2,
    FIUnusedFlag3);

  FIFlagSet = SET OF FileInfoFlagType;

  FileInfoRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { *.DIR : File records }
    FileName: STRING[12];    { Filename }
    Description: STRING[50]; { File description }
    FilePoints: Integer;     { File points }
    Downloaded: LongInt;     { Number of downloads }
    FileSize: LongInt;       { File size (Bytes) }
    OwnerNum: Integer;       { Uploader user number }
    OwnerName: STRING[36];   { Uploader user name }
    FileDate: UnixTime;      { Date uploaded }
    VPointer: LongInt;       { Pointer to verbose description (-1 = None) }
    VTextSize: Integer;      { Verbose description textsize (50 Bytes * 99 Lines = 4950 max) }
    FIFlags: FIFlagSet;      { File status }
  END;

  LastCallerRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { LASTON.DAT : Last few callers records }
    Node: Byte;           { Node number }
    UserName: STRING[36]; { Callers username }
    Location: STRING[30]; { Callers location }
    Caller,               { System caller number }
    UserID,               { User ID number }
    Speed: LongInt;       { Connection speed (0=Local) }
    LogonTime,            { Time logged on }
    LogoffTime: UnixTime; { Time logged off }
    NewUser,              { Was user new? }
    Invisible: Boolean;   { Was user invisible? }
    Uploads,              { Uploads }
    Downloads,            { Downloads }
    MsgRead,              { Messages read }
    MsgPost,              { Messages posted }
    EmailSent,            { E-Mails sent }
    FeedbackSent: Word;   { Feedback sent }
    UK,                   { kBytes uploaded }
    DK: LongInt;          { kBytes downloaded }
    Reserved:             { Reserved }
      ARRAY [1..17] OF Byte; 
  END;

  EventFlagType =
   (EventIsExternal,
    EventIsActive,
    EventIsErrorLevel,
    EventIsShell,
    EventIsPackMsgAreas,
    EventIsSortFiles,
    EventIsFilesBBS,
    EventIsLogon,
    EventIsChat,
    EventIsOffHook,
    EventIsMonthly,
    EventIsPermission,
    EventIsSoft,
    EventIsMissed,
    BaudIsActive,
    ACSIsActive,
    TimeIsActive,
    ARisActive,
    SetARisActive,
    ClearARisActive,
    InRatioIsActive);

  EFlagSet = SET OF EventFlagType;

  EventDaysType  = SET OF 0..6; { Event days }

  EventRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { Events > EVENTS.DAT}
    EventDescription: STRING[30]; { Description of the Event }
    EventDayOfMonth: BYTE;        { If monthly, the Day of Month }
    EventDays: EventDaysType;     { If Daily, the Days Active }
    EventStartTime,               { Start Time in Min from Mid. }
    EventFinishTime: WORD;        { Finish Time }
    EventQualMsg,                 { Msg/Path if he qualifies }
    EventNotQualMsg: STRING[64];  { Msg/Path if he doesn't }
    EventPreTime: BYTE;           { Min. B4 event to rest. Call }
    EventNode: Byte;              {  }
    EventLastDate: UnixTime;      { Last Date Executed }
    EventErrorLevel: BYTE;        { For Ext Event ErrorLevel }
    EventShellPath: STRING[8];    { File for Ext Event Shell }
    LoBaud,                       { Low baud rate limit }
    HiBaud: LongInt;              { High baud rate limit }
    EventACS: ACString;           { Event ACS }
    MaxTimeAllowed: WORD;         { Max Time per user this event }
    SetARFlag,                    { AR flag to set }
    ClearARFlag: CHAR;            { AR flag to clear }
    EFlags: EFlagSet;             { Kinds of Events Supported}   { Changed }
  END;

  ProtocolFlagType =(
    ProtActive,
    ProtIsBatch,
    ProtIsResume,
    ProtXferOkCode,
    ProtBiDirectional,
    ProtReliable);

  PRFlagSet = SET OF ProtocolFlagType;

  ProtocolCodeType = ARRAY [1..6] OF STRING[6];

  ProtocolRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { PROTOCOL.DAT }
    PRFlags: PRFlagSet;       { Protocol Flags }
    CKeys: STRING[14];        { Command Keys }
    Description: STRING[40];  { Description }
    ACS: ACString;            { User Access STRING }
    TempLog,                  { Utilized for Batch DL's - Temporary Log File }
    DLoadLog,                 { Utilized for Batch DL's - Permanent Log Files }
    ULoadLog,                 { Not Utilized }
    DLFList: STRING[25];      { Utilized for Batch DL's - DL File Lists }
    DLCmd,                    { DL Command Line }
    ULCmd: STRING[76];        { UL Command Line }
    DLCode,                   { DL Status/Return codes }
    ULCode: ProtocolCodeType; { UL StAtus/Return codes }
    EnvCmd: STRING[60];       { Environment Setup Cmd }
    MaxChrs,                  { Utilized for Batch DL's - Max chrs in cmdline }
    TempLogPF,                { Utilized for Batch DL's - Position in log for DL Status }
    TempLogPS: Byte;          { Utilized for Batch DL's - Position in log for file data }
  END;

  ConferenceRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { CONFRENC.DAT : Conference data }
    Key: Char;        { key '@' to 'Z' }
    Name: STRING[30]; { name of conference }
    ACS: ACString;    { access requirement }
  END;

  NodeFlagType =
   (NActive,     { Is this node active? }
    NAvail,      { Is this node's user available? }
    NUpdate,     { This node should re-read it's user }
    NHangup,     { Hangup on this node }
    NRecycle,    { Recycle this node to the OS }
    NInvisible); { This node is Invisible } {** REMOVING THIS???}

  NodeFlagSet = SET OF NodeFlagType;

  NodeRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { MULTNODE.DAT }
    User: Word;               { What user number }
    UserName: STRING[36];     { User's name }
    CityState: STRING[30];    { User's location }
    Sex: Char;                { User's sex }
    Age: Byte;                { User's age }
    LogonTime: UnixTime;      { What time they logged on }
    GroupChat: Boolean;       { Are we in MultiNode Chat }
    ActivityDesc: STRING[50]; { Activity STRING }
    Status: NodeFlagSet;      {  }
    Room: Byte;               { What room are they in? }
    Channel: Word;            { What channel are they in? } {**do we need BOTH room and channel??}
    Invited,                  { Invited to ... }
    Booted,                   { Banned from ... }
    Forget:                   { Ignoring ... }
      ARRAY [0..31] OF SET OF 0..7;
  END;

  RoomRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { ROOM.DAT }
    Topic: STRING[40];  { Room topic }
    Anonymous: Boolean; { Is room anonymous? }
    Private: Boolean;   { Is room private? }
    Occupied: Boolean;  { Is anyone in here? }
    Moderator: Word;    { Who's the moderator? }
  END;

  ScanRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { *.SCN files / MESSAGES }
    NewScan: Boolean;   { Scan this area? }
    LastRead: UnixTime; { Last read date }
  END;

  SchemeRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { SCHEME.DAT }
    Description: STRING[30]; { Color scheme description }
    Color:                   { Colors in scheme }
      ARRAY [1..200] OF Byte;
  END;

  {   1 - 10 SYSTEM COLORS
     11 -    FILE LIST COLORS
     28 -    MSG LIST COLORS
     45 -    FILE AREA LIST COLORS
     55 -    MSG AREA LIST COLORS
     65 -    USER LIST COLORS
     80 -    WHO'S ONLINE COLORS
    100 -    LAST ON COLORS
    115 -    QWK COLORS
    135 -    EMAIL COLORS
  }

  BBSListRecordType = {$IFDEF WIN32} PACKED {$ENDIF} RECORD { *.BBS file records }
    RecordNum: LongInt;       { Number OF the Record For Edit }
    UserID: LongInt;          { User ID OF person adding this }
    BBSName: STRING[30];      { Name OF BBS }
    SysOpName: STRING[30];    { SysOp OF BBS }
    TelnetURL: STRING[60];    { Telnet URL }
    WebSiteURL: STRING[60];   { Web Site URL }
    PhoneNumber: STRING[20];  { Phone number OF BBS }
    Software: STRING[8];      { Software used by BBS }
    Speed: STRING[8];         { Highest connect speed OF BBS }
    Description: STRING[60];  { Description OF BBS }
    Description2: STRING[60]; { Second line OF description }
    DateAdded: UnixTime;      { Date entry was added }
    DateEdited: UnixTime;     { Date entry was last edited }
    XA: STRING[8];            { SysOp definable A }
    XB: STRING[30];           { sysop definable B }
    XC: STRING[30];           { sysop definable C }
    XD: STRING[40];           { sysop definable D }
    XE: STRING[60];           { sysop definable E }
    XF: STRING[60];           { sysop definable F }
  END;

  MenuFlagType =
    (ClrScrBefore,      { C: clear screen before menu display }
     DontCenter,        { D: don't center the menu titles! }
     NoMenuTitle,       { T: no menu title displayed }
     NoMenuPrompt,      { N: no menu prompt whatsoever? }
     ForcePause,        { P: force a pause before menu display? }
     AutoTime,          { A: is time displayed automatically? }
     ForceLine,         { F: Force full line input }
     NoGenericAnsi,     { 1: DO NOT generate generic prompt if ANSI }
     NoGenericAvatar,   { 2: DO NOT generate generic prompt if AVT }
     NoGenericRIP,      { 3: DO NOT generate generic prompt if RIP }
     NoGlobalDisplayed, { 4: DO NOT display the global commands! }
     NoGlobalUsed);     { 5: DO NOT use global commands! }

  MenuFlagSet = SET OF MenuFlagType;

  CmdFlagType =
     (Hidden,    { H: Command is always hidden }
      UnHidden); { U: Command is always visible }

  CmdFlagSet = SET OF CmdFlagType;

  MenuRec = {$IFDEF WIN32} PACKED {$ENDIF} RECORD
    LDesc:                        { Menu Or Command Long Description ARRAY }
      ARRAY [1..3] OF STRING[100];    
    ACS: ACString;                { Access Requirements }
    NodeActivityDesc: STRING[50]; { Node activity description }
    CASE Menu: Boolean OF         { Menu Or Command - Variant section}
      TRUE:
        (MenuFlags: MenuFlagSet;  { Menu Flag SET }
         LongMenu: STRING[12];    { Displayed In Place OF Long Description }
         MenuNum: Byte;           { Menu Number }
         MenuPrompt: STRING[120]; { Menu Prompt }
         Password: STRING[20];    { Menu Password }
         FallBack: Byte;          { Menu Fallback Number }
         Directive: STRING[12];   { Short desc? }
         ForceHelpLevel: Byte;    { Menu Forced Help Level }
         GenCols: Byte;           { Generic Menus: # OF Columns }
         GCol:                    { Generic Menus: Colors }
           ARRAY [1..3] OF Byte);
      FALSE:
        (CmdFlags: CmdFlagSet;    { Command Flag SET }
         SDesc: STRING[35];       { Command Short Description }
         CKeys: STRING[14];       { Command Execution Keys }
         CmdKeys: STRING[2];      { Command Keys: Type OF Command }
         Options: STRING[50]);    { MString: Command Data }
    END;
