{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
 10/20/2021 - Color config now uses byte color instead of caret codes
            - Aesthetic changes
            - code cleanup
}
UNIT SysOp2H;

INTERFACE

PROCEDURE NetworkConfiguration;

IMPLEMENTATION

USES
  Common,
  NodeList,
  SysOp2, { ConfigHeader }
  SysOp2J; { GetColor }

PROCEDURE NetworkConfiguration;
VAR
  Cmd: Char;
  Counter: Byte;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
      BEGIN
        Abort := FALSE;
        Next := FALSE;
        ConfigHeader('Network Mail Configuration');
        PrintACR('^0(^1A^0) Net Addresses ...');
        PrintACR('^0(^1B^0) Origin Line     : ^1'+Origin);
        NL;
        PrintACR(PadLeftStr('^0(^1C^0) Strip IFNA Kludge Lines : ^1'+ShowYesNo(SKludge),39)+
               PadLeftStr('^0(^11^0) Standard Text Color : ',26)+#29);
        SetC(Text_Color); PrintACR('Text');
        PrintACR(PadLeftStr('^0(^1D^0) Strip SEEN-BY Lines     : ^1'+ShowYesNo(SSeenBy),39)+
               PadLeftStr('^0(^12^0) Quoted Text Color   : ',26)+#29);
        SetC(Quote_Color); PrintACR('Quote');
        PrintACR(PadLeftStr('^0(^1E^0) Strip Origin Lines      : ^1'+ShowYesNo(SOrigin),39)+
               PadLeftStr('^0(^13^0) Tear Line Color     : ',26)+#29);
        SetC(Tear_Color); PrintACR('Tear');
        PrintACR(PadLeftStr('^0(^1F^0) Add Tear/Origin Line    : ^1'+ShowYesNo(AddTear),39)+
               PadLeftStr('^0(^14^0) Origin Line Color   : ',26)+#29);
        SetC(Origin_Color); PrintACR('Origin');
        NL;
        PrintACR('^0(^1G^0) Default EchoMail Path   : ^1'+DefEchoPath);
        PrintACR('^0(^1H^0) Default NetMail Path    : ^1'+NetMailPath);
        PrintACR('^0(^1I^0) NetMail Attributes      : ^1'+NetMail_Attr(NetAttribute));
        PrintACR('^0(^1J^0) UUCP Gate Address       : ^1'+PadLeftStr('^1'+IntToStr(AKA[20].Zone)+':'+IntToStr(AKA[20].Net)+
                                                                     '/'+IntToStr(AKA[20].Node)+'.'+IntToStr(AKA[20].Point)
                                                                     ,20));
        NL;
        InputChar('Network Mail Configuration [^1A^2-^1J^2,^11^2-^14^2,(^1Q^2)uit]: ',Cmd,'QABCDEFGHIJ1234',
                  [CapAll]);
        CASE Cmd OF
          'A' : BEGIN
                  REPEAT
                    Abort := FALSE;
                    Next := FALSE;
                    ConfigHeader('Network Mail Addresses');
                    FOR Counter := 0 TO 19 DO
                      BEGIN
                        Prompt(PadLeftStr('^0(^1'+Chr(Counter + 65)+'^0) Address #'+PadLeftInt(Counter,2)+' :^1'+
                               ' '+IntToStr(AKA[Counter].Zone)+
                               ':'+IntToStr(AKA[Counter].Net)+
                               '/'+IntToStr(AKA[Counter].Node)+
                               '.'+IntToStr(AKA[Counter].Point),39));
                        IF (Odd(Counter)) THEN
                          NL;
                      END;
                    InputChar('%LF^2Network Mail Addresses [^1A^2-^1T^2,<^1CR^2>Quit]: ',Cmd,^M'ABCDEFGHIJKLMNOPQRST',
                              [CapAll]);
                    IF (Cmd IN ['A'..'T']) THEN
                      GetNewAddr('%LF^2Enter Network Address (^1Z^2:^1N^2/^1N^2.^1P^2): ',30,
                                 AKA[(Ord(Cmd) - 65)].Zone,
                                 AKA[(Ord(Cmd) - 65)].Net,
                                 AKA[(Ord(Cmd) - 65)].Node,
                                 AKA[(Ord(Cmd) - 65)].Point);
                  UNTIL (Cmd = ^M) OR (HangUp);
                  Cmd := #0;
                END;
          'B' : InputString('%LF^2Enter Origin Line: ',Origin,50,[InteractiveEdit],Changed);
          'C' : SKludge := NOT SKludge;
          'D' : SSeenBy := NOT SSeenBy;
          'E' : SOrigin := NOT SOrigin;
          'F' : AddTear := NOT AddTear;
          'G' : InputPath('%LF^2Enter Default EchoMail Path: ',DefEchoPath,TRUE,FALSE,Changed);
          'H' : InputPath('%LF^2Enter Default NetMail Path: ',NetMailPath,TRUE,FALSE,Changed);
          'I' : BEGIN
                  REPEAT
                    Print('%LF^0Netmail Attributes: ^1'+NetMail_Attr(NetAttribute)+'^0');
                    InputChar('%LFToggle Attributes [^1CHIKLP^2,(^1?^2)Help,(^1Q^2)uit]: ',Cmd,'QPCKHIL?',[CapAll]);
                    CASE Cmd OF
                      'C','H','I','K','L','P' :
                            ToggleNetAttrS(Cmd,NetAttribute);
                      '?' : BEGIN
                              NL;
                              LCmds(11,1,'Crash Mail','Hold');
                              LCmds(11,1,'In-Transit','Kill-Sent');
                              LCmds(11,1,'Local','Private');
                            END;
                    END;
                  UNTIL (Cmd = 'Q') OR (HangUp);
                  Cmd := #0;
                END;
          'J' : GetNewAddr('%LFEnter new UUCP Gate Address (^1Z^2:^1N^2/^1N^2.^1P^2 format): ',30,
                           AKA[20].Zone,
                           AKA[20].Net,
                           AKA[20].Node,
                           AKA[20].Point);
          '1' : Text_Color := GetColor;
          '2' : Quote_Color := GetColor;
          '3' : Tear_Color := GetColor;
          '4' : Origin_Color := GetColor;
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.