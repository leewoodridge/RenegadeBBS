{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2I;

INTERFACE

PROCEDURE OfflineMailConfiguration;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader}

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
        ConfigHeader('Offline Mail Configuration',0,0);
        PrintACR('^0(^1A^0) QWK/REP Packet Name   : ^1'+PacketName);
        PrintACR('^0(^1B^0) Welcome File          : ^1'+QWKWelcome);
        PrintACR('^0(^1C^0) News File             : ^1'+QWKNews);
        PrintACR('^0(^1D^0) Goodbye File          : ^1'+QWKGoodbye);
        PrintACR('^0(^1E^0) Local QWK/REP Path    : ^1'+QWKLocalPath);
        PrintACR('^0(^1F^0) Ignore Download Time  : ^1'+ShowYesNo(QWKTimeIgnore));
        PrintACR('^0(^1G^0) Max Messages Total    : ^1'+IntToStr(MaxQWKTotal));
        PrintACR('^0(^1H^0) Max Messages Per Base : ^1'+IntToStr(MaxQWKBase));
        PrintACR('^0(^1I^0) ACS For Network .REP  : ^1'+QWKNetworkACS);
        NL;
        InputChar('^2Offline Mail Configuration [^1A^2-^1I^2,(^1Q^2)uit]: ',Cmd,'QABCDEFGHI'^M,[CapAll]);
        CASE Cmd OF
          'A' : InputString('%LF^2QWK Packet name: ',PacketName,(SizeOf(PacketName) - 1),[InterActiveEdit],Changed);
          'B' : InputString('%LF^2Welcome screen file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKWelcome,(SizeOf(QWKWelcome) - 1),[CapAll,InterActiveEdit],Changed);
          'C' : InputString('%LF^2News file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKNews,(SizeOf(QWKNews) - 1),[CapAll,InterActiveEdit],Changed);
          'D' : InputString('%LF^2Goodbye file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKGoodbye,(SizeOf(QWKGoodBye) - 1),[CapAll,InterActiveEdit],Changed);
          'E' : InputPath('%LF^2Enter local QWK reader path :%LF',QWKLocalPath,TRUE,FALSE,Changed);
          'F' : QWKTimeIgnore := NOT QWKTimeIgnore;
          'G' : InputWord('%LF^2Maximum total messages in a QWK packet',
                             MaxQWKTotal,[InterActiveEdit,NumbersOnly],0,65535,Changed);
          'H' : InputWord('%LF^2Maximum messages per base in a packet',
                             MaxQWKBase,[InterActiveEdit,NumbersOnly],0,65535,Changed);
          'I' : InputString('%LF^2New ACS : ',QWKNetworkACS,(SizeOf(QWKNetworkACS) - 1),[InterActiveEdit],Changed);
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.