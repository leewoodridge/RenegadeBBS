{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
everything
}
UNIT SysOp2L;

INTERFACE

PROCEDURE CreditConfiguration;

IMPLEMENTATION

USES
  Common,
  SysOp2; { ConfigHeader }

PROCEDURE CreditConfiguration;
VAR
  Cmd: Char;
BEGIN
  REPEAT
	WITH General DO
	  BEGIN
		Abort := FALSE;
		Next := FALSE;
		ConfigHeader('Credit System Configuration');
		PrintACR('^0(^1A^0) Credits per minute           : ^1'+IntToStr(CreditMinute));
		PrintACR('^0(^1B^0) Credits per public message   : ^1'+IntToStr(CreditPost));
		PrintACR('^0(^1C^0) Credits per private message  : ^1'+IntToStr(CreditEmail));
		PrintACR('^0(^1D^0) Credits per internet e-mail  : ^1'+IntToStr(CreditInternetMail));
		NL;
		PrintACR('^0(^1E^0) No credit free time at logon : ^1'+IntToStr(CreditFreeTime));
		NL;
		LOneK('^2Credit System Configuration [^1A^2-^1E^2,(^1Q^2)uit]: ',Cmd,'QABCDEF',TRUE,TRUE);
		NL;
		CASE Cmd OF
		  'A' : InputIntegerWOC('Credits charged per minute online',CreditMinute,
				[NumbersOnly,NegativeAllowed,{DisplayRange,}InterActiveEdit],-32767,32767);
		  'B' : InputIntegerWOC('Credits charger per public message',CreditPost,
				[NumbersOnly,NegativeAllowed,{DisplayRange,}InterActiveEdit],-32767,32767);
		  'C' : InputIntegerWOC('Credits charged per private message',CreditEmail,
				[NumbersOnly,NegativeAllowed,{DisplayRange,}InterActiveEdit],-32767,32767);
		  'D' : InputIntegerWOC('Credits charged per internet e-mail',CreditInternetMail,
				[NumbersOnly,NegativeAllowed,{DisplayRange,}InterActiveEdit],-32767,32767);
		  'E' : InputIntegerWOC('Minutes to give users without credits at logon',CreditFreeTime,
				[NumbersOnly,NegativeAllowed,{DisplayRange,}InterActiveEdit],-32767,32767);
		END;
	  END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.