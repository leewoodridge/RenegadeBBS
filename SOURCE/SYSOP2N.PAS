
{	  (                                       	}
{	 )\ )                           (         	}
{	(()/(  (         (  (  (     )  )\ )  (		}
{	 \(_))))\ (     ))\ )\))( ( /( (()/( ))\	}
{	(_)) /((_))\ ) /((_|(_))\ )(_)) ((_))(( )	}
{	| _ \_)) _(_/((_)) \( )(_|(_)_  _| (_))/	}
{	|   / -_) ' \)) -_)/ _` |/ _` / _` / -_)	}
{	|_|_\___|_||_|\___|\__, |\__,_\__,_\___|	}
{	------------------ |___/ ----------------	}
{	B U L L E T I N   B O A R D   S Y S T E M	}
{	-----------------------------------------	}
{
	[DONE]
	 - 
	[TO-DO]
	 - 
}

UNIT SysOp2N; { SysOp Macros }

INTERFACE

PROCEDURE SysOpMacroConfiguration;

IMPLEMENTATION

USES
  Common,
  SysOp2;
  
PROCEDURE SysOpMacroConfiguration;
VAR
  TempB: Byte;
  Cmd: Char;
  
  PROCEDURE DisplayMacro(CONST S: AStr; MaxLen: Byte);
  VAR
	TempStr: AStr;
	Counter: Byte;
  BEGIN
	TempStr := '';
	FOR Counter := 1 TO Length(S) DO
	  IF (S[Counter] >= ' ') THEN
		TempStr := TempStr + S[Counter]
	  ELSE
		TempStr := TempStr + '^1^'+Chr(Ord(S[Counter]) + 64)+'^0';
	Prompt('^1"^0'+TempStr+'^1"');
  END;

  PROCEDURE RecordMacro(MacroNum: Byte);
  VAR
	S: AStr;
	C: Char;
	Counter: Byte;
  BEGIN
	CLS;
	Print('Enter your F'+IntToStr(MacroNum + 1)+' macro now, up to a maximum of 100 characters. Press CTRL+Z when finished.');
	NL;
	S := '';
	Counter := 1;
	REPEAT
	  C := Char(GetKey);
	  IF (C = ^H) THEN
		BEGIN
		  C := #0;
		  IF (Counter >= 2) THEN
			BEGIN
			  BackSpace;
			  Dec(Counter);
			  IF (S[Counter] < #32) THEN
				BackSpace;
			END;
		END;
	  IF (Counter <= 100) AND (C <> #0) THEN
		BEGIN
		  IF (C IN [#32..#255]) THEN
			BEGIN
			  OutKey(C);
			  S[Counter] := C;
			  Inc(Counter);
			END
		  ELSE IF (C IN [^A,^B,^C,^D,^E,^F,^G,^H,^I,^J,^K,^L,^M,^N,^P,^Q,^R,^S,^T,^U,^V,^W,^X,^Y,#27,#28,#29,#30,#31]) THEN
			BEGIN
			  IF (C = ^M) THEN
				NL
			  ELSE
				Prompt('^1^'+Chr(Ord(C) + 64)+'^0');
				S[Counter] := C;
				Inc(Counter);
			END;
		END;
	UNTIL ((C = ^Z) OR (HangUp));
	S[0] := Chr(Counter - 1);
	CLS;
	Print('^1Your F'+IntToStr(MacroNum + 1)+' macro has been recorded as:');
	DisplayMacro(S,160);
	Com_Flush_Recv;
	NL;
	IF (NOT PYNQ('Is this correct? ',0,FALSE)) THEN
	  lRGLngStr(154,FALSE) {Print('^8Aborted!')}
	ELSE
	  BEGIN
		General.Macro[MacroNum] := S;
		lRGLngStr(155,FALSE); {Print('^9Saved!');}
	  END;
	PauseScr(FALSE);
  END;

BEGIN
  REPEAT
	WITH General DO
	  BEGIN
		Abort := FALSE;
		Next := FALSE;
		ConfigHeader('SysOp Macro Configuration');
		FOR TempB := 0 TO 8 DO
		  BEGIN
			Prompt('^0(^1'+IntToStr(TempB+1)+'^0) F'+IntToStr(TempB+1)+' Macro  : ^1');
			DisplayMacro(Macro[TempB],61);
			NL;
		  END;
		Prompt('^0(^10^0) F10 Macro : ^1');
		DisplayMacro(Macro[9],61);
		NL;
		NL;
		LOneK('^2SysOp Macro Configuration [^11^2-^10^2,(^1Q^2)uit]: ',Cmd,'Q1234567890',TRUE,TRUE);
		  CASE Cmd OF
			'1'..'9' : RecordMacro(Ord(Cmd) - Ord('1'));
			'0' : RecordMacro(9);
		  END;
	  END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.