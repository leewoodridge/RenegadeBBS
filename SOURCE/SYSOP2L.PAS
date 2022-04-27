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
        ConfigHeader('Credit System Configuration',0);
        PrintACR('^0(^1A^0) Credits Per Minute           : ^1'+IntToStr(CreditMinute));
        PrintACR('^0(^1B^0) Credits Per Public Message   : ^1'+IntToStr(CreditPost));
        PrintACR('^0(^1C^0) Credits Per Private Message  : ^1'+IntToStr(CreditEmail));
        PrintACR('^0(^1D^0) Credits Per Internet E-Mail  : ^1'+IntToStr(CreditInternetMail));
        NL;
        PrintACR('^0(^1E^0) No Credit Free Time At Logon : ^1'+IntToStr(CreditFreeTime));
        NL;
        InputChar('^2Credit System Configuration [^1A^2-^1E^2,(^1Q^2)uit]: ',Cmd,'QABCDEF',[CapAll]);
        NL;
        CASE Cmd OF
          'A' : InputInteger('Charge/reward how many credits per minute online?',CreditMinute,
                [NumbersOnly,AllowNegative,InterActiveEdit],-32767,32767,Changed);
          'B' : InputInteger('Charge/reward how many credits per public message?',CreditPost,
                [NumbersOnly,AllowNegative,InterActiveEdit],-32767,32767,Changed);
          'C' : InputInteger('Charge/reward how many credits per private message?',CreditEmail,
                [NumbersOnly,AllowNegative,InterActiveEdit],-32767,32767,Changed);
          'D' : InputInteger('Charge/reward how many credits per internet e-mail?',CreditInternetMail,
                [NumbersOnly,AllowNegative,InterActiveEdit],-32767,32767,Changed);
          'E' : InputInteger('Give how many minutes to users without credits at logon?',CreditFreeTime,
                [NumbersOnly,{AllowNegative,}InterActiveEdit],-32767,32767,Changed);
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.