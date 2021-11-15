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
        ConfigHeader('Offline Mail Configuration');
        PrintACR('^0(^1A^0) QWK/REP Packet name  : ^1'+PacketName);
        PrintACR('^0(^1B^0) Welcome screen name  : ^1'+QWKWelcome);
        PrintACR('^0(^1C^0) News file name       : ^1'+QWKNews);
        PrintACR('^0(^1D^0) Goodbye file name    : ^1'+QWKGoodbye);
        PrintACR('^0(^1E^0) Local QWK/REP path   : ^1'+QWKLocalPath);
        PrintACR('^0(^1F^0) Ignore time for DL   : ^1'+ShowOnOff(QWKTimeIgnore));
        PrintACR('^0(^1G^0) Max total messages   : ^1'+IntToStr(MaxQWKTotal));
        PrintACR('^0(^1H^0) Max msgs per base    : ^1'+IntToStr(MaxQWKBase));
        PrintACR('^0(^1I^0) ACS for Network .REP : ^1'+QWKNetworkACS);
        NL;
        LOneK('^2Offline Mail Configuration [^1A^2-^1I^2,(^1Q^2)uit]: ',Cmd,'QABCDEFGHI'^M,TRUE,TRUE);
        CASE Cmd OF
          'A' : InputWN1('%LF^2QWK Packet name: ',PacketName,(SizeOf(PacketName) - 1),[InterActiveEdit],Changed);
          'B' : InputWN1('%LF^2Welcome screen file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKWelcome,(SizeOf(QWKWelcome) - 1),[CapAll,InterActiveEdit],Changed);
          'C' : InputWN1('%LF^2News file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKNews,(SizeOf(QWKNews) - 1),[CapAll,InterActiveEdit],Changed);
          'D' : InputWN1('%LF^2Goodbye file "^1D:\PATH\FILENAME^2" (No ".EXT") :%LF',
                         QWKGoodbye,(SizeOf(QWKGoodBye) - 1),[CapAll,InterActiveEdit],Changed);
          'E' : InputPath('%LF^2Enter local QWK reader path :%LF',QWKLocalPath,TRUE,FALSE,Changed);
          'F' : QWKTimeIgnore := NOT QWKTimeIgnore;
          'G' : InputWordWOC('%LF^2Maximum total messages in a QWK packet : ',MaxQWKTotal,[DisplayValue,NumbersOnly],0,65535);
          'H' : InputWordWOC('%LF^2Maximum messages per base in a packet : ',MaxQWKBase,[DisplayValue,NumbersOnly],0,65535);
          'I' : InputWN1('%LF^2New ACS : ',QWKNetworkACS,(SizeOf(QWKNetworkACS) - 1),[InterActiveEdit],Changed);
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.