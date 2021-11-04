{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R-,S+,V-}
{
Lee Woodridge
 10/20/2021 - Color config now uses pipe codes instead of caret codes
 updating color codes
 switched out onek for lonek to display prompt
}
UNIT SysOp2H;

INTERFACE

procedure GetPipeColor (VAR ColorVar: Byte; s: STRING);
PROCEDURE NetworkConfiguration;

IMPLEMENTATION

USES
  Common,
  NodeList,
  TimeFunc; { ZeroPad }
  
  procedure GetPipeColor (VAR ColorVar: Byte; s: STRING);
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
    InputByteWOC('New '+s+' color',TempColor,[NumbersOnly],0,15); (* Suppress Error *)
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
      Print('%CL^1Network Configuration:');
      NL;
      PrintACR('^0A. Net addresses');
      PrintACR('^0B. Origin line     : ^1'+Origin);
      NL;
      PrintACR(PadLeftStr('^0C. Strip IFNA kludge lines : ^1'+ShowYesNo(SKludge),39)+
               PadLeftStr('^01. Color of standard text : |'+ZeroPad(IntToStr(Text_Color))+'Text',39));
      PrintACR(PadLeftStr('^0D. Strip SEEN-BY lines     : ^1'+ShowYesNo(SSeenBy),39)+
               PadLeftStr('^02. Color of quoted text   : |'+ZeroPad(IntToStr(Quote_Color))+'Quoted',39));
      PrintACR(PadLeftStr('^0E. Strip origin lines      : ^1'+ShowYesNo(SOrigin),39)+
               PadLeftStr('^03. Color of tear line     : |'+ZeroPad(IntToStr(Tear_Color))+'Tear',39));
      PrintACR(PadLeftStr('^0F. Add tear/origin line    : ^1'+ShowYesNo(AddTear),39)+
               PadLeftStr('^04. Color of origin line   : |'+ZeroPad(IntToStr(Origin_Color))+'Origin',39));
      NL;
      PrintACR('^0G. Default Echomail path   : ^1'+DefEchoPath);
      PrintACR('^0H. Netmail path            : ^1'+NetMailPath);
      PrintACR('^0I. Netmail attributes      : ^1'+NetMail_Attr(NetAttribute));
      PrintACR('^0J. UUCP gate address       : ^1'+PadLeftStr('^1'+IntToStr(AKA[20].Zone)+':'+IntToStr(AKA[20].Net)+
                                                       '/'+IntToStr(AKA[20].Node)+'.'+IntToStr(AKA[20].Point),20));
      LOneK('%LFEnter selection [^1A^2-^1J^2,^11^2-^14^2,^1Q^2=^1Quit^2]: ',Cmd,'QABCDEFGHIJ1234'{^M},TRUE,TRUE);
      CASE Cmd OF
        'A' : BEGIN
                REPEAT
                  Abort := FALSE;
                  Next := FALSE;
                  Print('%CL^1Network Addresses:^0');
                  NL;
                  FOR Counter := 0 TO 19 DO
                  BEGIN
                    Prompt('^0'+Chr(Counter + 65)+'. Address #'+PadLeftInt(Counter,2)+' : '+
                    PadLeftStr('^1'+IntToStr(AKA[Counter].Zone)+
                        ':'+IntToStr(AKA[Counter].Net)+
                        '/'+IntToStr(AKA[Counter].Node)+
                        '.'+IntToStr(AKA[Counter].Point),20));
                    IF (Odd(Counter)) THEN
                      NL;
                  END;
                  LOneK('%LFEnter selection [^1A^2-^1T^2,^1<CR>^2=^1Quit^2]: ',Cmd,^M'ABCDEFGHIJKLMNOPQRST',TRUE,TRUE);
                  IF (Cmd IN ['A'..'T']) THEN
                    GetNewAddr('%LFEnter new network address (^1Z^2:^1N^2/^1N^2.^1P^2 format): ',30,
                                AKA[(Ord(Cmd) - 65)].Zone,
                                AKA[(Ord(Cmd) - 65)].Net,
                                AKA[(Ord(Cmd) - 65)].Node,
                                AKA[(Ord(Cmd) - 65)].Point);
                UNTIL (Cmd = ^M) OR (HangUp);
                Cmd := #0;
              END;
        'B' : InputWN1('%LF^0Enter new origin line:%LF^2: ',Origin,50,[],Changed);
        'C' : SKludge := NOT SKludge;
        'D' : SSeenBy := NOT SSeenBy;
        'E' : SOrigin := NOT SOrigin;
        'F' : AddTear := NOT AddTear;
        'G' : InputPath('%LF^0Enter new default echomail path (^1End with a ^0"^1\^0"):%LF^2:',DefEchoPath,TRUE,FALSE,Changed);
        'H' : InputPath('%LF^0Enter new netmail path (^1End with a ^0"^1\^0"):%LF^2:',NetMailPath,TRUE,FALSE,Changed);
        'I' : BEGIN
                REPEAT
                  Print('%LF^0Netmail attributes: ^1'+NetMail_Attr(NetAttribute)+'^0');
                  LOneK('%LFToggle attributes (CHIKLP) [?]Help [Q]uit: ',Cmd,'QPCKHIL?',TRUE,TRUE);
                  CASE Cmd OF
                    'C','H','I','K','L','P' :
                           ToggleNetAttrS(Cmd,NetAttribute);
                    '?' : BEGIN
                            NL;
                            LCmds(22,3,'Crash mail','Hold');
                            LCmds(22,3,'In-Transit','Kill-Sent');
                            LCmds(22,3,'Local','Private');
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
                {
				Prompt('%LF^1Colors: ');
                ShowColors;
				}
				GetPipeColor(Text_Color,'standard text');
                {InputByteWC('%LFNew standard text color',Text_Color,[DisplayValue,NumbersOnly],0,9,Changed);}
              END;
        '2' : BEGIN
				{
                Prompt('%LF^1Colors: ');
                ShowColors;
				}
				GetPipeColor(Quote_Color,'quoted text');
                {InputByteWC('%LFNew quoted text color',Quote_Color,[DisplayValue,NumbersOnly],0,9,Changed);}
              END;
        '3' : BEGIN
                {
				Prompt('%LF^1Colors: ');
                ShowColors;
				}
				GetPipeColor(Tear_Color,'tear line');
                {InputByteWC('%LFNew tear line color',Tear_Color,[DisplayValue,NumbersOnly],0,9,Changed);}
              END;
        '4' : BEGIN
				{
                Prompt('%LF^1Colors: ');
                ShowColors;
				}
				GetPipeColor(Origin_Color,'origin line');
                {InputByteWC('%LFNew origin line color',Origin_Color,[DisplayValue,NumbersOnly],0,9,Changed);}
              END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.