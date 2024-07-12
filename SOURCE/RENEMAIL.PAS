PROGRAM Renemail;

{$A+,I-,E-,F+}

(* {A+,B-,D-,E-,F+,G+,N-,R-,S-,V-,I-} *)

uses crt, dos, timefunc;

{$I RECORDS.INC}

type
  fidorecord = record
    FromUserName : string[35];
    ToUserName   : string[35];
    Subject      : string[71];
    DateTime     : string[19];
    TimesRead    : word;
    DestNode     : word;
    OrigNode     : word;
    Cost         : word;
    OrigNet      : word;
    DestNet      : word;
    Filler       : array[1..8] of char;
    Replyto      : word;
    Attribute    : word;
    NextReply    : word;
  end;

var
   
    Lasterror :integer;
    header : fidorecord;
    dt : datetime;
    msgtfile : file;
    hiwaterf : file of longint;
    statusf : file of generalrecordtype;
    statusr : generalrecordtype;
    boardf : file of MessageAreaRecordType;
    boardr : MessageAreaRecordType;
    msghdrf : file of mheaderrec;
    msghdr : mheaderrec;
    msgtxtf : file;
    uf : file of UserRecordType;
    user : UserRecordType;
    sf : file of UserIDXRec;
    toi, fromi, subjecti, datetime : string;
    i, j, lines, board, textsize,
    msglength, msgpointer : integer;
    msgnumber,highest,fi,lowest : longint;
    c : char;
    Year, Month, MDay, WDay, attribute : Word;
    ispm : boolean;
    dirinfo : searchrec;
    s, s3,startdir, nos, datapath, msgpath, netmailpath : string [81];
    msgtxt : string [255];
    buffer : array [1..32767] of char;
    fcb : array [1..37] of char;
    regs : registers;
    x : byte;

const
  netmailonly : boolean = FALSE;
  isnetmail : boolean = FALSE;
  fastpurge : boolean = TRUE;
  process_netmail : boolean = TRUE;
  purge_netmail : boolean = TRUE;
  absolute_scan : boolean = FALSE;
  ignore_1msg : boolean = TRUE;

function Usename(b:byte; s:astr):string;
begin
  case b of
    1,
    2:s:='Anonymous';
    3:s:='Abby';
    4:s:='Problemed Person';
  end;
  Usename:=s;
end;

function existdir(fn:string):boolean;
var dirinfo:searchrec;
begin
  while (fn[length(fn)] = '\') do
    dec(fn[0]);
  findfirst(fn,anyfile,dirinfo);
  existdir:=(doserror=0) and (dirinfo.attr and $10=$10);
end;

function StrPas(Str: String): String; assembler;
asm
	PUSH	DS
	CLD
	LES	DI,Str
	MOV	CX,0FFFFH
	XOR	AL,AL
	REPNE	SCASB
	NOT	CX
	DEC	CX
	LDS	SI,Str
	LES	DI,@Result
	MOV	AL,CL
	STOSB
	REP	MOVSB
	POP	DS
end;

function stripname(s:astr):astr;
var
  n:integer;
begin
  n := length(s);
  while (n > 0) and (pos(s[n],':\/') = 0) do
    dec(n);
  delete(s,1,n);
  stripname := s;
end;

function allcaps (const s : string) : string;
var
  q : integer;
begin
  allcaps [0] := s [0];
  for q := 1 to length (s) do
    allcaps [q] := upcase (s [q]);
end;

function caps (s : string) : string;
var
  i : integer;
begin
  for i := 1 to length (s) do
    if (s [i] in ['A'..'Z']) then
       s [i] := chr (ord (s [i]) + 32);

  for i := 1 to length (s) do
    if (not (s [i] in ['A'..'Z', 'a'..'z', chr (39) ]) ) then
      if (s [i + 1] in ['a'..'z']) then
         s [i + 1] := upcase (s [i + 1]);
  s [1] := upcase (s [1]);
  caps := s;
end;

function searchuser(Uname:string): word;
var
  Current:integer;
  Done:boolean;
  IndexR:useridxrec;
begin
  reset(sf);
  if (IOResult > 0) then
    exit;

  Uname := Allcaps(UName);

  Current := 0;
  Done := FALSE;

  if (filesize(sf) > 0) then
    repeat
      seek(sf, Current);
      read(sf, IndexR);
      if (Uname < IndexR.Name) then
        Current := IndexR.Left
      else
        if (Uname > IndexR.Name) then
          Current := IndexR.Right
        else
          Done := TRUE;
    until (Current = -1) or (Done);

  close(sf);

  if (Done) and not (IndexR.Deleted) then
    SearchUser := IndexR.Number
  else
    SearchUser := 0;

  Lasterror := IOResult;
end;

function stripcolor (o : string) : string;
var i,j : byte;
    s : string;
begin
  i := 0;
  s := '';
  while (i < length (o) ) do begin
    inc (i);
    case o [i] of
     #128..#255:if (mafilter in boardr.maflags) then
                  s := s + chr(ord(o[i]) and 128)
                else
                  s := s + o[i];
     '^' : if o [i + 1] in [#0..#9, '0'..'9'] then
              inc (i) else s := s + '^';
     '|' : if (mafilter in boardr.maflags) and (o[i + 1] in ['0'..'9']) then
              begin
                j:=0;
                while (o [i + 1] in ['0'..'9']) and (i <= length (o) )
                  and (j<=2) do begin
                    inc (i);
                    inc (j)
                  end
              end
           else
              s := s + '|'
      else s := s + o [i];
    end;
  end;
  stripcolor := s;
end;



FUNCTION IntToString(L: LongInt): STRING;
VAR
  S: STRING[11];
BEGIN
  Str(L,S);
  IntToString := S;
END;

FUNCTION CenterStr(S: STRING): STRING;
VAR
  Counter1: Byte;
BEGIN
  Counter1 := ((80 - Length(S)) DIV 2);
  Move(S[1],S[Counter1 + 1],Length(S));
  Inc(S[0],Counter1);
  FillChar(S[1],Counter1,#32);
  CenterStr := S;
END;

PROCEDURE WriteCharXY(C: Char; X,Y,FColor,Bcolor: Byte);
BEGIN
  TextColor(FColor);
  TextBackGround(Black);
  GotoXY(X,Y);
  Write(C);
END;

PROCEDURE WriteStrXY(S: STRING; X,Y,FColor,Bcolor: Byte);
BEGIN
  TextColor(FColor);
  TextBackGround(Black);
  GotoXY(X,Y);
  Write(S);
END;

PROCEDURE DisplayMain(FColor,Bcolor: Byte);
VAR
  X,
  Y: Byte;
  Year, Month, MDay, WDay: Word;

BEGIN
  ClrScr;
FColor:=8;
  Window(1,1,80,24);
  TextColor(FColor);
  TextBackGround(Black);
  ClrScr;
  Window(1,1,80,25);
  WriteCharXY(#201,1,1,FColor,Black);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,1,FColor,Black);
  WriteCharXY(#187,80,1,FColor,Black);
  FOR Y := 2 TO 3 DO
  BEGIN
    WriteCharXY(#186,1,Y,FColor,Black);
    WriteCharXY(#186,80,Y,FColor,Black);
  END;
  WriteCharXY(#204,1,4,FColor,Black);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,4,FColor,Black);
  WriteCharXY(#185,80,4,FColor,Black);
  GetDate(Year,Month,MDay,WDay);
  WriteStrXY(CenterStr('Renegade Echomail Interface v'+Ver),2,2,11,Black);
  WriteStrXY(CenterStr('Copyright (c) 1991-'+IntToString(Year)+' The Renegade Development Team'),2,3,3,Black);
  FOR Y := 5 TO 21 DO
  BEGIN
    WriteCharXY(#186,1,Y,FColor,Black);
    WriteCharXY(#186,80,Y,FColor,Black);
  END;
  WriteCharXY(#204,1,22,FColor,Black);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,22,FColor,Black);
  WriteCharXY(#185,80,22,FColor,Black);
  WriteCharXY(#186,1,23,FColor,Black);
  WriteStrXY('Message: ',3,23,8,Black);
  WriteStrXY('None',12,23,15,Black);
WriteCharXY(#186,80,23,FColor,Black);
  WriteCharXY(#200,1,24,FColor,Black);
  FOR X := 2 TO 79 DO
    WriteCharXY(#205,X,24,FColor,Black);
  WriteCharXY(#188,80,24,FColor,Black);
  Window(2,5,78,21);
  GoToXY(1,1);
END;

PROCEDURE DisplayHelp(FColor,Bcolor: Byte);
BEGIN
FColor:=7;
  WriteStrXY('Commands:',16,2,White,Black);
  WriteStrXY('-T  ',27,2,14,Black);
  WriteStrXY('Toss Incoming Messages',31,2,FColor,Black);
  WriteStrXY('-R  ',27,3,14,Black);
  WriteStrXY('Toss & Purge Messages At The Same Time',31,3,FColor,Black);
  WriteStrXY('-S  ',27,4,14,Black);
  WriteStrXY('Scan For Outbound Messages',31,4,FColor,Black);
  WriteStrXY('-P  ',27,5,14,Black);
  WriteStrXY('Purge EchoMail Directories',31,5,FColor,Black);
  WriteStrXY('-X  ',27,6,14,Black);
  WriteStrXY('Export [database] Messages To [path]',31,6,FColor,Black);
  WriteStrXY('       (ex: RENEMAIL -X METGEN D:\TEMP)',27,7,08,Black);
  WriteStrXY('Options:',16,9,White,Black);
  WriteStrXY('-A  ',31,9,14,Black);
  WriteStrXY('Absolute Scan Of ALL Message Areas',35,9,FColor,Black);
  WriteStrXY('-D  ',31,10,14,Black);
  WriteStrXY('Do NOT Delete Netmail',35,10,FColor,Black);
  WriteStrXY('-F  ',31,11,14,Black);
  WriteStrXY('Do NOT Use Fast Message Purging',35,11,FColor,Black);
  WriteStrXY('-I  ',31,12,14,Black);
  WriteStrXY('Import 1.MSG',35,12,FColor,Black);
  WriteStrXY('-N  ',31,13,14,Black);
  WriteStrXY('Do NOT Import Netmail',35,13,FColor,Black);
  WriteStrXY('-O  ',31,14,14,Black);
  WriteStrXY('Import ONLY Netmail',35,14,FColor,Black);
  GoToXY(1,1);
END;

PROCEDURE ErrorStrXY(S: STRING; X,Y,FColor,Bcolor: Byte);
VAR
  SaveX,
  SaveY: Byte;
BEGIN
  SaveX := WhereX;
  SaveY := WhereY;
  Window(1,1,80,25);
  GoToXY(X,Y);
  TextColor(FColor);
  TextBackGround(Black);
  Write(S);
  Window(2,5,78,21);
  GoToXY(SaveX,SaveY);
END;

PROCEDURE HaltErrorStrXY(S: STRING; X,Y,FColor,Bcolor,HaltNum: Byte);
BEGIN
  DisplayHelp(White,Black);
  Window(1,1,80,25);
  GoToXY(X,Y);
  TextColor(12);
  TextBackGround(Black);
  Write(S);
  GotoXY(1,25);
  Halt(HaltNum);
END;




procedure aborterror(const s:string);
begin
  writeln(s);
  halt(2);
end;

  function value (s : string) : longint;
  var i : longint;
  j : integer;
  begin
   val (s, i, j);
   if (j <> 0) then begin
      s[0]:=chr(j-1);
      val (s, i, j)
    end;
    value := i;
    if (s = '') then value := 0;
  end;

  function cstr (i : longint) : string;
  var c : string [16];
  begin
    str (i, c);
    cstr := c;
  end;

  procedure getmsglst (const dir : string);
  var hiwater : longint;
  begin
      hiwater := 1;
      if not isnetmail then
        begin
          assign (hiwaterf, dir + 'HI_WATER.MRK');
          reset (hiwaterf);
          if ioresult <> 0 then
            begin
               rewrite (hiwaterf);
               write (hiwaterf, hiwater);
               if ioresult <> 0 then
                 aborterror('error creating ' + dir + '\HI_WATER.MRK');
            end
          else
            begin
              read (hiwaterf, hiwater);
              i := ioresult;
              findfirst (dir + cstr (hiwater) + '.MSG', 0, dirinfo);
              if doserror <> 0 then hiwater := 1;
            end;
            close (hiwaterf);
        end;
      findfirst (dir + '*.MSG', 0, dirinfo);
      highest := 1;
      lowest := 999999;
      while doserror = 0 do
        begin
          fi := value (dirinfo.name);
          if fi < lowest then lowest := fi;
          if fi > highest then highest := fi;
          findnext (dirinfo);
        end;

      if hiwater <= highest then
        if hiwater > 1 then
          lowest := hiwater + 1;

      if (ignore_1msg) then
        if (lowest = 1) and (highest > 1) then
          lowest := 2;
    Lasterror := IOResult;
  end;

  procedure getpaths;

     procedure badpath(const s:string);
     begin
       writeln('The ',s,' path is bad.  Please correct it.');
       halt;
     end;

  begin
    s := fsearch ('RENEGADE.DAT', getenv ('PATH') );
    assign (statusf, s);
    reset (statusf);
    if (ioresult <> 0) or (s = '') then
      begin
        writeln ('RENEGADE.DAT must be in the current directory or the path.');
        halt (1);
      end;
    read (statusf, statusr);
    datapath := statusr.datapath;
    if not (existdir(datapath)) then
      badpath('DATA');
    netmailpath := statusr.netmailpath;
    if not (existdir(netmailpath)) then
      badpath('NETMAIL');
    msgpath := statusr.msgpath;
    if not (existdir(msgpath)) then
      badpath('MSGS');
    close (statusf);
    if ioresult <> 0 then
      aborterror('error reading from RENEGADE.DAT');
  end;

  procedure updatehiwater (const dir:string; x:longint);
  begin
     assign (hiwaterf, dir + 'HI_WATER.MRK');
     rewrite (hiwaterf);
     write (hiwaterf, x);
     close (hiwaterf);
     i := ioresult;
  end;

  procedure purgedir (const dir : string);
  var purged : boolean;
  begin
{$IFDEF MSDOS}
    if fastpurge then
      begin
        chdir (copy (dir, 1, length (dir) - 1) );
        if (IOResult <> 0) then
          exit;
        if (dir[2] = ':') then
          fcb [1] := chr(ord(dir[1]) - 64)
        else
          fcb [1] := chr(ord(startdir[1]) - 64);
        regs.ds := seg (fcb);
        regs.dx := ofs (fcb);
        regs.ax := $1300;
        msdos (regs);
        purged := (lo (regs.ax) = 0);
      end
    else
      begin
{$ENDIF}
        purged := TRUE;
        findfirst (dir + '*.MSG', 0, dirinfo);
        if doserror <> 0 then
          purged := FALSE
        else
          while doserror = 0 do
            begin
              assign (hiwaterf, dir + dirinfo.name);
              erase (hiwaterf);
              i := ioresult;
              findnext (dirinfo);
             end;
{$IFDEF MSDOS}
      end;
{$ENDIF}
      if not purged then write ('No messages')
         else write ('Purged');
      updatehiwater (dir, 1);
  end;

  function readmsg (x:longint ; const dir:string) : boolean;
  var
    q : boolean;
  begin
    assign (msgtfile, dir + cstr (x) + '.MSG');
    reset (msgtfile, 1);
    q := FALSE;
    if ioresult = 0 then
      begin
        if filesize (msgtfile) >= sizeof(header) then
          begin
          blockread (msgtfile, header, sizeof(header));

          s := StrPas(Header.FromUserName);

          if ((header.attribute and 16) = 16) then
            MsgHdr.fileattached := 1;

          MsgHdr.from.a1s := s;
          MsgHdr.from.real := s;
          MsgHdr.from.name := s;

          s := StrPas(Header.ToUserName);

          MsgHdr.mto.a1s := s;
          MsgHdr.mto.real := s;
          MsgHdr.mto.name := s;

          MsgHdr.Subject := StrPas(Header.Subject);

          MsgHdr.OriginDate := StrPas(Header.DateTime);

          q := TRUE;

          if (Header.Attribute and 1 = 1) then
            msghdr.status := [Sent, Prvt]
          else
            msghdr.status := [Sent];

          if isnetmail then
            begin
              q:=FALSE;
              msghdr.from.node := Header.OrigNode;
              msghdr.from.net := Header.OrigNet;
              msghdr.mto.node := Header.DestNode;
              msghdr.mto.net := Header.DestNet;
              msghdr.from.point := 0;
              msghdr.mto.point := 0;
              msghdr.from.zone := 0;
              msghdr.mto.zone := 0;
              if (Header.Attribute and 256 = 0) and
                 (Header.Attribute and 4 = 0) then
                for i := 0 to 19 do
                    if (msghdr.mto.node = statusr.aka[i].node) and
                       (msghdr.mto.net = statusr.aka[i].net) then
                        begin
                          msghdr.mto.zone := statusr.aka[i].zone;
                          msghdr.from.zone := statusr.aka[i].zone;
                          q := TRUE;
                        end;
            end;

        if q then
          begin
            if (filesize(msgtfile) - 190) <= sizeof(buffer) then
              x := filesize(msgtfile) - 190
            else
              x := sizeof(buffer);
            blockread (msgtfile, buffer, x, msglength);
            msgpointer := 0;
            nos := '';
            while (msgpointer < msglength) do begin
              msgtxt := nos;
              repeat
               inc (msgpointer);
               c := buffer [msgpointer];
               if not (c in [#0, #10, #13, #141]) then
                 if (length(msgtxt) < 255) then  {msgtxt := msgtxt + c;}
                  begin
                   inc(msgtxt[0]);
                   msgtxt[length(msgtxt)] := c;
                  end;
              until (
                    (nos = #13) or (c in [#13,#141])
                    or
                    ((length(msgtxt) > 79) and (pos(#27, msgtxt) = 0))
                    or
                    (length(msgtxt) = 254)
                    or
                    (msgpointer >= msglength)
                    );
                    if length (msgtxt) = 254 then
                       msgtxt := msgtxt + #29;
                    i := pos('TOPT ', msgtxt);
                    if i>0 then q:=false;
              end;
          end;
       end;
       if isnetmail then
         if q and purge_netmail then
            begin
              close (msgtfile);
              erase (msgtfile)
            end
         else if q then
           begin
             Header.Attribute := 260;
             seek (msgtfile, 0);
             blockwrite (msgtfile, header, sizeof(Header));
           end;
       if not (isnetmail and q and purge_netmail) then
        begin
         close(msgtfile);
         if (pos ('-R', allcaps (paramstr (1) ) ) > 0) then erase(msgtfile);
        end;

    end;
    readmsg := q;
    i := ioresult;
  end;

  procedure nextboard(Scanning:boolean);
  var
    GoodBoard,s4:boolean;
    eelog : text;

  begin
    if board = 0 then
      begin
        i := ioresult;
        assign (boardf, datapath + 'MBASES.DAT');
        reset (boardf);
        i := ioresult;
        if i <> 0 then
          begin
            writeln (i,':Problem accessing ' + datapath + 'MBASES.DAT. Please fix.');
            halt (1);
          end;
      end;

    if board = filesize (boardf) then
      begin
        board := 32767;
        exit;
      end;

    boardr.matype := 0;  boardr.maflags := []; GoodBoard := FALSE;

    s4 := false;
    while not GoodBoard and (board < filesize(boardf)) do
      begin
        read (boardf, boardr);
     GoodBoard := (boardr.matype = 1) and
                  (not scanning or (absolute_scan or (mascanout in boardr.maflags)));

    if pos ('-X', allcaps (paramstr (1) ) ) >0 then
     begin
       GoodBoard := (boardr.matype = 1) and
                    (boardr.filename=allcaps(paramstr(2)));
     end;
    inc(board);

      end;

    if (not GoodBoard) then
      board := 32767
    else
      if scanning and (mascanout in boardr.maflags) then
        begin
          seek(boardf, board - 1);
          boardr.maflags := boardr.maflags - [mascanout];
          write(boardf, boardr);
        end;

  end;

  procedure toss;
  var i,j:word;
      z:string [20];
      istossed:boolean;
      left, right, gap, oldgap : integer;
  begin
       istossed:=false;
       msghdr.from.anon := 0;
       msghdr.from.usernum := 0;
       msghdr.mto.anon := 0;
       msghdr.mto.usernum := 0;
       msghdr.replyto := 0;
       msghdr.replies := 0;
       msghdr.fileattached := 0;

       getdayofweek (msghdr.dayofweek);
       msghdr.date := getpackdatetime;
       getmsglst (boardr.msgpath);
       if isnetmail and (highest > 1) then lowest := 1;

       if (lowest <= highest) and ((highest > 1) or isnetmail) then begin

          assign (msghdrf, msgpath + boardr.filename + '.HDR');
          reset (msghdrf);
          if (ioresult = 2) then rewrite (msghdrf);

          assign (msgtxtf, msgpath + boardr.filename + '.DAT');
          reset (msgtxtf, 1);
          if (ioresult = 2) then rewrite (msgtxtf, 1);

          seek (msghdrf, filesize (msghdrf) );
          seek (msgtxtf, filesize (msgtxtf) );

          if ioresult <> 0 then
            aborterror('error accessing ' + msgpath + boardr.filename + '.*');

          for msgnumber := lowest to highest do begin
              write (msgnumber : 7);
              if readmsg (msgnumber, boardr.msgpath) then
                with msghdr do begin
                  inc (date);
                  pointer := filesize (msgtxtf) + 1;
                  textsize := 0;
                  msgpointer := 0;
                  nos := '';
                  while (msgpointer < msglength) do begin
                    msgtxt := nos;
                    repeat
                      inc (msgpointer);
                      c := buffer [msgpointer];
                      if not (c in [#0, #10, #13, #141]) then
                        if (length(msgtxt) < 255) then  {msgtxt := msgtxt + c;}
                          begin
                            inc(msgtxt[0]);
                            msgtxt[length(msgtxt)] := c;
                          end;
                    until (
                          (nos = #13) or (c in [#13,#141])
                          or
                          ((length(msgtxt) > 79) and (pos(#27, msgtxt) = 0))
                          or
                          (length(msgtxt) = 254)
                          or
                          (msgpointer >= msglength)
                          );

                    if length (msgtxt) = 254 then
                       msgtxt := msgtxt + #29;

                    i := pos('INTL ', msgtxt);
                    if (i > 0) then
                      begin
                        inc(i, 6);
                        for j := 1 to 8 do
                          begin
                            z := '';
                            while (msgtxt[i] in ['0'..'9']) and (i <= length(msgtxt)) do
                              begin
                                z := z + msgtxt[i];
                                inc(i);
                              end;
                            case j of
                              1:msghdr.mto.zone := value(z);
                              2:msghdr.mto.net := value(z);
                              3:msghdr.mto.node := value(z);
                              4:msghdr.mto.point := value(z);
                              5:msghdr.from.zone := value(z);
                              6:msghdr.from.net := value(z);
                              7:msghdr.from.node := value(z);
                              8:msghdr.from.point := value(z);
                            end;
                            if (j = 3) and (msgtxt[i] <> '.') then
                              inc(j);
                            if (j = 7) and (msgtxt[i] <> '.') then
                              break;
                            inc(i);
                          end;
                      end;
                    i := pos('FMPT ', msgtxt);
                    if (i > 0) then
                      begin
                        inc(i, 6);
                        z := '';
                        while (msgtxt[i] in ['0'..'9']) and (i <= length(msgtxt)) do
                         begin
                          z := z + msgtxt[i];
                          inc(i);
                         end;
                        msghdr.from.point := value(z);
                      end;

                    if (length (msgtxt) > 79) then
                      begin
                        i := length (msgtxt);
                        while (msgtxt [i] = ' ') and (i > 1) do
                          dec (i);
                        while (i > 65) and (msgtxt [i] <> ' ') do
                          dec (i);

                        nos[0] := chr(length(msgtxt) - i);
                        move(msgtxt[i + 1], nos[1], length(msgtxt) - i);
                        msgtxt[0] := chr(i - 1);

                      end
                    else
                      nos := '';

                    if ( (msgtxt [1] = #1) and (maskludge in boardr.maflags) ) or
                       ( (pos ('SEEN-BY', msgtxt) > 0) and (masseenby in boardr.maflags) ) or
                       ( (pos ('* Origin:', msgtxt) > 0) and (masorigin in boardr.maflags) ) then
                       msgtxt := ''
                    else begin
                       inc (msghdr.textsize, length (msgtxt) + 1);
                       blockwrite (msgtxtf, msgtxt, length (msgtxt) + 1);
                    end;
                  end;
                  if isnetmail then begin
                     istossed:=true;
                     msghdr.status := msghdr.status + [netmail];
                     msghdr.mto.usernum := SearchUser(msghdr.mto.a1s);
                     if msghdr.mto.usernum = 0 then
                       msghdr.mto.usernum := 1;
                     seek (uf, msghdr.mto.usernum);
                     read (uf, user);
                     inc (user.waiting);
                     seek (uf, msghdr.mto.usernum);
                     write (uf, user);
                  end;
                  write (msghdrf, msghdr);
                end;
              if msgnumber < highest then write (#8#8#8#8#8#8#8);
              i := ioresult;
          end;
          close (msghdrf);
          close (msgtxtf);
          if not isnetmail then
           updatehiwater (boardr.msgpath, highest)
           else
           begin
            if istossed then
             begin
               assign(msgtxtf,'renemail.net');
               rewrite(msgtxtf);
               close(msgtxtf);
             end;
           end;   
       end else write ('No messages');
    Lasterror := IOResult;
  end;

  procedure scan;
  var rgmsgnumber : longint;
      highestwritten : longint;
      rescan : longint;
      db : text;
      zero : string;
      AnsiOn,
      scanned : boolean;
  begin
       AnsiOn := FALSE;
       scanned := FALSE;
       getmsglst (boardr.msgpath);
       msgnumber := highest;
       if (not existdir(boardr.msgpath)) then
         begin
           writeln('WARNING: Cannot access ', boardr.msgpath);
           exit;
         end;

       assign (msghdrf, msgpath + boardr.filename + '.HDR');
       reset (msghdrf);
       if ioresult <> 0 then exit;

       assign (msgtxtf, msgpath + boardr.filename + '.DAT');
       reset (msgtxtf, 1);
       if ioresult <> 0 then begin close (msghdrf); exit; end;

       rescan:=0;
       for rgmsgnumber := 1 to filesize (msghdrf) do begin
           seek (msghdrf, rgmsgnumber - 1);
           read (msghdrf, msghdr);
           if (not (sent in msghdr.status) and (ioresult = 0) and
              not (mdeleted in msghdr.status) and
              not (isnetmail and not (netmail in msghdr.status)) and
              not (unvalidated in msghdr.status) and
              (pos ('-X', allcaps (paramstr (1) ) ) = 0)) or
              ((ioresult = 0) and
              not (mdeleted in msghdr.status) and
              not (unvalidated in msghdr.status) and
              (pos ('-X', allcaps (paramstr (1) ) ) > 0)) then
              begin
              scanned := TRUE;
              inc (msgnumber);
              if (pos ('-X', allcaps (paramstr (1) ) ) > 0) then
              begin
                zero:='';
                assign (msgtfile, paramstr(3)+'\' + zero+cstr (msgnumber) + '.MSG');
                rescan:=rescan+1;
              end
              else
                assign (msgtfile, boardr.msgpath + cstr (msgnumber) + '.MSG');
              rewrite (msgtfile, 1);
              write (rgmsgnumber : 7);

              msghdr.status := msghdr.status + [sent];

              if isnetmail then
                msghdr.status := msghdr.status + [mdeleted];

              seek (msghdrf, rgmsgnumber - 1);
              if (pos ('-X', allcaps (paramstr (1) ) ) = 0) then
               write (msghdrf, msghdr);

              if (marealname in boardr.maflags) then
                s := caps (msghdr.from.real)
              else
                s := caps (msghdr.from.a1s);

              s := usename(msghdr.from.anon, s);

              fillchar(Header,sizeof(Header),#0);

              move(s[1],Header.FromUserName[0],length(s));

              if (marealname in boardr.maflags) then
                s := caps (msghdr.mto.real)
              else
                s := caps (msghdr.mto.a1s);

              s := usename(msghdr.mto.anon, s);

              move(s[1],Header.ToUserName[0],length(s));

              MsgHdr.Subject := stripcolor(MsgHdr.Subject);

              if (not isnetmail) and (msghdr.fileattached > 0) then
                MsgHdr.Subject := StripName(MsgHdr.Subject);

              move(MsgHdr.Subject[1],Header.Subject[0],length(MsgHdr.Subject));

              packtodate (dt, msghdr.date);
              with dt do begin
               s := cstr (day);
                if length (s) < 2 then s := '0' + s;
               s := s + ' ' + copy ('JanFebMarAprMayJunJulAugSepOctNovDec', (month - 1) * 3 + 1, 3) + ' ';
               s := s + copy (cstr (year), 3, 2) + '  ';
               nos := cstr (hour);
               if length (nos) < 2 then nos := '0' + nos;
               s := s + nos + ':';
               nos := cstr (min);
               if length (nos) < 2 then nos := '0' + nos;
               s := s + nos + ':';
               nos := cstr (sec);
              end;
              if length (nos) < 2 then nos := '0' + nos;
              s := s + nos;

              move(s[1],Header.DateTime[0],length(s));

              if isnetmail then begin
                 Header.OrigNet := msghdr.from.net;
                 Header.OrigNode := msghdr.from.node;
                 Header.DestNet := msghdr.mto.net;
                 Header.DestNode := msghdr.mto.node;
              end else begin
                 Header.OrigNet := statusr.aka [boardr.aka].net;
                 Header.OrigNode := statusr.aka [boardr.aka].node;
                 Header.DestNet := 0;
                 Header.DestNode := 0;
              end;

              if isnetmail then
                Header.Attribute := word(msghdr.netattribute)
                {word(statusr.netattribute)}
              else
                if (prvt in msghdr.status) then
                  Header.Attribute := 257
                else
                  Header.Attribute := 256;

              if (msghdr.fileattached > 0) then
                Header.Attribute := Header.Attribute + 16;

              blockwrite (msgtfile, header, sizeof(Header));
              seek (msgtxtf, msghdr.pointer - 1);

              if isnetmail then
               begin
                s := #1'INTL ' + cstr (msghdr.mto.zone) + ':' + cstr (msghdr.mto.net) + '/' + cstr (msghdr.mto.node);
                s := s + ' ' + cstr (msghdr.from.zone) + ':' + cstr (msghdr.from.net) + '/' + cstr (msghdr.from.node);
                s := s + #13;
                blockwrite (msgtfile, s [1], length (s) );
                if msghdr.mto.point >0 then
                  begin
                    s := #1'TOPT ' + cstr(msghdr.mto.point)+ #13;
                    blockwrite (msgtfile, s [1], length (s) );
                  end;
                if msghdr.from.point > 0 then
                  begin
                    s := #1'FMPT ' + cstr(msghdr.from.point) + #13;
                    blockwrite (msgtfile, s [1], length (s) );
                  end;
               end;

              j := 0;
              if (msghdr.textsize) > 0 then
              repeat
                blockread (msgtxtf, s [0], 1);
                blockread (msgtxtf, s [1], ord (s [0]) );
                inc (j, length (s) + 1);
                while pos(#0,s) > 0 do
                  delete(s,pos(#0,s),1);
                if s [length (s) ] = #29 then
                  dec(s[0])
                else
                  if pos (#27, s) = 0 then
                    s := stripcolor(s)
                  else
                    AnsiOn := TRUE;
                s := s + #13;
                if length(s)<81 then
                 blockwrite (msgtfile, s [1], length (s) );
              until (j >= msghdr.textsize) or (j>16383);
              close (msgtfile);
              write (#8#8#8#8#8#8#8);
           end;
           highestwritten := msgnumber;
       end;
       i := ioresult;

       if not isnetmail and scanned and
         (pos ('-X', allcaps (paramstr (1) ) ) = 0) then
         begin
           updatehiwater (boardr.msgpath, highestwritten);
         end;
       close (msghdrf);
       close (msgtxtf);
       if not scanned then write ('No messages');
    Lasterror := IOResult;
  end;

begin
  Randomize;
  getdir (0, startdir);
  for x := 1 to 37 do
     fcb [x] := ' ';
  fcb [1] := chr (ord (startdir [1]) - 64);
  fcb [2] := '*';
  fcb [10] := 'M';
  fcb [11] := 'S';
  fcb [12] := 'G';
  filemode := 66;
  msghdr.from.zone := 0;
  msghdr.from.point := 0;
  GetDate(Year,Month,MDay,WDay);
  clrscr;

  if paramstr (1) = '' then
    begin
DisplayMain(White,Black);
DisplayHelp(White,Black);
  if paramstr (1) = '' then
    HaltErrorStrXY('No Command Line Parameters Specified!',12,23,Red + 128,Black,1);
   end;
  assign (sf,'RENEMAIL.!!!');
  if ioresult=0 then
   begin
     rewrite(sf);
     close(sf);
   end;
  for i := 1 to paramcount do
      if (pos ('-N', allcaps (paramstr (i) ) ) > 0) or
         (pos ('-X', allcaps (paramstr (i) ) ) > 0) then
         process_netmail := FALSE
      else
         if pos ('-F', allcaps (paramstr (i) ) ) > 0 then
            fastpurge := FALSE
         else
            if pos ('-D', allcaps (paramstr (i) ) ) > 0 then
               purge_netmail := FALSE
            else
              if pos ('-B', allcaps (paramstr (i) ) ) > 0 then
                 directvideo := FALSE
              else
                if pos ('-O', allcaps (paramstr (i) ) ) > 0 then
                   netmailonly := TRUE
                else
                  if pos ('-A', allcaps (paramstr (i) ) ) > 0 then
                     absolute_scan := TRUE
                  else
                    if pos ('-I', allcaps (paramstr (i) ) ) > 0 then
                       ignore_1msg := FALSE;
  board := 0;
  getpaths;

  if process_netmail then
    begin
       boardr.msgpath := netmailpath;
       boardr.filename := 'EMAIL';
       boardr.maflags := [maskludge];
       assign (uf, datapath + 'users.dat');
       reset (uf);
       if ioresult <> 0 then
         aborterror('Cannot find users.dat in your DATA directory');
       assign (sf, datapath + 'users.idx');
       reset (sf);
       if ioresult <> 0 then
         aborterror('Cannot find users.idx in your DATA directory');

       isnetmail := TRUE;
       textcolor (3);
       write ('Processing: ');
       textcolor (14);
       write (' NETMAIL - ');
       textcolor (11);
       if pos ('-T', allcaps (paramstr (1) ) ) > 0 then toss;
       if pos ('-R', allcaps (paramstr (1) ) ) > 0 then toss;
       if pos ('-S', allcaps (paramstr (1) ) ) > 0 then scan;
       if pos ('-X', allcaps (paramstr (1) ) ) > 0 then scan;
       close (uf);
       close (sf);
       Lasterror := IOResult;
       writeln;
       isnetmail := FALSE;
    end;

  if netmailonly then halt;

  while board <> 32767 do begin
       if (pos ('-S', allcaps (paramstr (1) ) ) > 0) then
           nextboard(true)
        else
           nextboard(false);
       if board <> 32767 then begin
       textcolor (3);
       write ('Processing: ');
       textcolor (14);
       write (boardr.filename : 8, ' - ');
       textcolor (11);
       if pos ('-P', allcaps (paramstr (1) ) ) > 0 then purgedir (boardr.msgpath)
          else if (pos ('-T', allcaps (paramstr (1) ) ) > 0) or
                  (pos ('-R', allcaps (paramstr (1) ) ) > 0) then toss
          else if (pos ('-S', allcaps (paramstr (1) ) ) > 0) or
                  (pos ('-X', allcaps (paramstr (1) ) ) > 0) then scan;
        writeln;
    end else close (boardf)
  end;
  chdir (startdir);
  assign(sf,'RENEMAIL.!!!');
  erase (sf);
end.
