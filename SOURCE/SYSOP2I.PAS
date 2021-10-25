{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2I;

INTERFACE

PROCEDURE OfflineMailConfiguration;

IMPLEMENTATION

USES
  Common;

PROCEDURE OfflineMailConfiguration;
VAR
  Cmd: CHAR;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      Print('%CL^1Offline Mail Configuration:');
      NL;
      PrintACR('^0A. QWK/REP Packet name : ^1'+PacketName);
      PrintACR('^0B. Welcome screen name : ^1'+QWKWelcome);
      PrintACR('^0C. News file name      : ^1'+QWKNews);
      PrintACR('^0D. Goodbye file name   : ^1'+QWKGoodbye);
      PrintACR('^0E. Local QWK/REP path  : ^1'+QWKLocalPath);
      PrintACR('^0F. Ignore time for DL  : ^1'+ShowOnOff(QWKTimeIgnore));
      PrintACR('^0G. Max total messages  : ^1'+IntToStr(MaxQWKTotal));
      PrintACR('^0H. Max msgs per base   : ^1'+IntToStr(MaxQWKBase));
      PrintACR('^0I. ACS for Network .REP: ^1'+QWKNetworkACS);
      Prt('%LFEnter selection [^1A^2-^1I^2,^1Q^2=^1Quit^2]: ');
      OneK(Cmd,'QABCDEFGHI'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : InputWN1('%LFQWK Packet name: ',PacketName,(SizeOf(PacketName) - 1),[InterActiveEdit],Changed);
        'B' : InputWN1('%LF^0Welcome screen file d:\path\name (^1Do not enter ^0"^1.EXT^0"):%LF^2: ',
                       QWKWelcome,(SizeOf(QWKWelcome) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'C' : InputWN1('%LF^0News file d:\path\name (^1Do not enter ^0"^1.EXT^0"):%LF^2: ',QWKNews,(SizeOf(QWKNews) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'D' : InputWN1('%LF^0Goodbye file d:\path\name (^1Do not enter ^0"^1.EXT^0"):%LF^2: ',
                       QWKGoodbye,(SizeOf(QWKGoodBye) - 1),
                       [UpperOnly,InterActiveEdit],Changed);
        'E' : InputPath('%LF^0Enter local QWK reader path (^1End with a ^0"^1\^0"):%LF^2:',QWKLocalPath,TRUE,FALSE,Changed);
        'F' : QWKTimeIgnore := NOT QWKTimeIgnore;
        'G' : InputWordWOC('%LFMaximum total messages in a QWK packet',MaxQWKTotal,[DisplayValue,NumbersOnly],0,65535);
        'H' : InputWordWOC('%LFMaximum messages per base in a packet',MaxQWKBase,[DisplayValue,NumbersOnly],0,65535);
        'I' : InputWN1('%LFNew ACS: ',QWKNetworkACS,(SizeOf(QWKNetworkACS) - 1),[InterActiveEdit],Changed);
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
