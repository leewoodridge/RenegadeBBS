{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 10/20/2021 - Color config now uses pipe codes instead of caret codes
 updating color codes
 switched out onek for lonek to display prompt
}
UNIT SysOp2H;

INTERFACE

PROCEDURE GetPipeColor (VAR ColorVar: Byte; s: STRING);
PROCEDURE NetworkConfiguration;

IMPLEMENTATION

USES
  Common,
  NodeList,
  SysOp2, { ConfigHeader }
  TimeFunc; { ZeroPad }
  
  PROCEDURE GetPipeColor (VAR ColorVar: Byte; s: STRING);
  CONST
    ColorName: ARRAY[0..7] OF STRING[7] = ('Black','Blue','Green','Cyan','Red','Magenta','Yellow','White');
  VAR
    TempColor,
    Counter: Byte;
  BEGIN
    SetC(7);
    NL;
    FOR Counter := 0 TO 7 DO
      BEGIN
        SetC(7);
        Prompt('('+IntToStr(Counter)+') ');
        SetC(Counter);
        Prompt(PadLeftStr(ColorName[Counter],12));
        SetC(7);
        Prompt(PadLeftStr('('+IntToStr(Counter+8)+') ',5));
        SetC(Counter+8);
        Print(PadLeftStr(ColorName[Counter]+'!',9));
      END;
    NL;
    InputByte('New '+s+' color',TempColor,[NumbersOnly],0,15,Changed); (* Suppress Error *)
    IF (TempColor IN [0..15]) THEN
      BEGIN
        ColorVar := TempColor;
        lRGLngStr(155,FALSE); {"Saved!"}
      END(*
    ELSE
      BEGIN
        lRGLngStr(154,FALSE); {"Aborted!"}
      END*);
    SetC(7);
  END;

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
      {
      Print('%CL^1Network Configuration:');
      NL;}
      ConfigHeader('Network Mail Configuration');
      PrintACR('^0(^1A^0) Net Addresses ...');
      PrintACR('^0(^1B^0) Origin Line     : ^1'+Origin);
      NL;
      PrintACR(PadLeftStr('^0(^1C^0) Strip IFNA Kludge Lines : ^1'+ShowYesNo(SKludge),39)+
               PadLeftStr('^0(^11^0) Standard Text Color : |'+ZeroPad(IntToStr(Text_Color))+'Text',39));
      PrintACR(PadLeftStr('^0(^1D^0) Strip SEEN-BY Lines     : ^1'+ShowYesNo(SSeenBy),39)+
               PadLeftStr('^0(^12^0) Quoted Text Color   : |'+ZeroPad(IntToStr(Quote_Color))+'Quoted',39));
      PrintACR(PadLeftStr('^0(^1E^0) Strip Origin Lines      : ^1'+ShowYesNo(SOrigin),39)+
               PadLeftStr('^0(^13^0) Tear Line Color     : |'+ZeroPad(IntToStr(Tear_Color))+'Tear',39));
      PrintACR(PadLeftStr('^0(^1F^0) Add Tear/Origin Line    : ^1'+ShowYesNo(AddTear),39)+
               PadLeftStr('^0(^14^0) Origin Line Color   : |'+ZeroPad(IntToStr(Origin_Color))+'Origin',39));
      NL;
      PrintACR('^0(^1G^0) Default EchoMail Path   : ^1'+DefEchoPath);
      PrintACR('^0(^1H^0) Default NetMail Path    : ^1'+NetMailPath);
      PrintACR('^0(^1I^0) NetMail Attributes      : ^1'+NetMail_Attr(NetAttribute));
      PrintACR('^0(^1J^0) UUCP Gate Address       : ^1'+PadLeftStr('^1'+IntToStr(AKA[20].Zone)+':'+IntToStr(AKA[20].Net)+
                                                                   '/'+IntToStr(AKA[20].Node)+'.'+IntToStr(AKA[20].Point),20));
      InputChar('%LFEnter selection [^1A^2-^1J^2,^11^2-^14^2,^1Q^2=^1Quit^2]: ',Cmd,'QABCDEFGHIJ1234'{^M},[CapAll]);
      CASE Cmd OF
        'A' : BEGIN
                REPEAT
                  Abort := FALSE;
                  Next := FALSE;
                { Print('%CL^1Network Addresses:^0');
                  NL; }
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
                  InputChar('%LF^2Network Mail Addresses [^1A^2-^1T^2,<^1CR^2>Quit]: ',Cmd,^M'ABCDEFGHIJKLMNOPQRST',[CapAll]);
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
                  Print('%LF^0Netmail attributes: ^1'+NetMail_Attr(NetAttribute)+'^0');
                  InputChar('%LFToggle attributes (CHIKLP) [?]Help [Q]uit: ',Cmd,'QPCKHIL?',[CapAll]);
                  CASE Cmd OF
                    'C','H','I','K','L','P' :
                           ToggleNetAttrS(Cmd,NetAttribute);
                    '?' : BEGIN
                            NL;
                            LCmds(22,1,'Crash mail','Hold');
                            LCmds(22,1,'In-Transit','Kill-Sent');
                            LCmds(22,1,'Local','Private');
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
        '1' : BEGIN
                GetPipeColor(Text_Color,'standard text');
              END;
        '2' : BEGIN
                GetPipeColor(Quote_Color,'quoted text');
              END;
        '3' : BEGIN
                GetPipeColor(Tear_Color,'tear line');
              END;
        '4' : BEGIN
                GetPipeColor(Origin_Color,'origin line');
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.