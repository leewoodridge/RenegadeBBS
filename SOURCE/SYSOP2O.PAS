{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2O;

INTERFACE

USES
  Common;

PROCEDURE GetSecRange(CONST DisplayType: LongInt; VAR Sec: SecurityRangeType);

IMPLEMENTATION

PROCEDURE GetSecRange(CONST DisplayType: LongInt; VAR Sec: SecurityRangeType);
VAR
  Cmd: Char;
  Counter: Byte;
  DisplayValue,
  FromValue,
  ToValue: Integer;
  NewValue: LongInt;

  PROCEDURE ShowSecRange(Start: Byte);
  VAR
    TempStr: AStr;
    LineNum,
    Counter1: Byte;
    SecNum: Integer;
  BEGIN
    Abort := FALSE;
    Next := FALSE;
    LineNum := 0;
    REPEAT
      TempStr := '';
      FOR Counter1 := 0 TO 7 DO
      BEGIN
        SecNum := Start + LineNum + Counter1 * 20;
        IF (SecNum <= 255) THEN
        BEGIN
          TempStr := TempStr + '^0'+PadLeftInt(SecNum,3)+':^1'+PadLeftInt(Sec[SecNum],5);
          IF (Counter1 <> 7) THEN
            TempStr := TempStr + ' ';
        END;
      END;
      PrintACR(TempStr);
      Inc(LineNum);
    UNTIL (LineNum > 19) OR (Abort) OR (HangUp);
  END;

BEGIN
  Abort := FALSE;
  Next := FALSE;
  DisplayValue := 0;
  REPEAT
    CLS;
    CASE DisplayType OF
      1 : Print('^1Time limitations:^0');
      2 : Print('^1Call allowance per day:^0');
      3 : Print('^1UL/DL # files ratio (# files can DL per UL):^0');
      4 : Print('^1UL/DL K-bytes ratio (#k can DL per 1k UL):^0');
      5 : Print('^1Post/Call ratio (posts per 100 calls) to have Z ACS flag set:^0');
      6 : Print('^1Maximum number of downloads in one day:^0');
      7 : Print('^1Maximum amount of downloads (in kbytes) in one day:^0');
    END;
    NL;
    ShowSecRange(DisplayValue);
    LOneK('%LFRange settings [^1S^2=^1Set^2,^1T^2=^1Toggle^2,^1Q^2=^1Quit^2]: ',Cmd,'QST'^M,TRUE,TRUE);
    CASE Cmd OF
      'S' : BEGIN
              FromValue := -1;
              InputIntegerWOC('%LFFrom?',FromValue,[NumbersOnly],0,255);
              IF (FromValue >= 0) AND (FromValue <= 255) THEN
              BEGIN
                ToValue := -1;
                InputIntegerWOC('%LFTo?',ToValue,[NumbersOnly],0,255);
                IF (ToValue >= 0) AND (ToValue <= 255) THEN
                BEGIN
                  NewValue := -1;
                  InputLongIntWOC('%LFValue to set?',NewValue,[NumbersOnly],0,32767);
                  IF (NewValue >= 0) AND (NewValue <= 32767) THEN
                    FOR Counter := FromValue TO ToValue DO
                      Sec[Counter] := NewValue;
                END;
              END;
            END;
      'T' : IF (DisplayValue = 0) THEN
              DisplayValue := 160
            ELSE
              DisplayValue := 0;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
