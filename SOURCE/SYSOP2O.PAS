{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
 - There's got to be a better way to do page numbering than "StrToInt(Copy(IntToStr(DisplayValue),1,1))+1" ...
}
UNIT SysOp2O;

INTERFACE

USES
  Common,
  SysOp2; {ConfigHeader,HL}

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
      FOR Counter1 := 0 TO 5 DO
        BEGIN
          SecNum := Start + LineNum + Counter1 * 18;
          IF (SecNum <= 255) THEN
            BEGIN
              TempStr := TempStr + ' ^1'+PadLeftInt(SecNum,4)+' ^0'+PadLeftInt(Sec[SecNum],6);
              IF (Counter1 <> 7) THEN
                TempStr := TempStr + ' ';
            END;
        END;
      PrintACR(TempStr);
      Inc(LineNum);
    UNTIL (LineNum > 17) OR (Abort) OR (HangUp);
  END;

BEGIN
  Abort := FALSE;
  Next := FALSE;
  DisplayValue := 0;
  REPEAT
    CASE DisplayType OF
      1 : ConfigHeader('Maximum Time Per '+AOnOff(General.PerCall,'Call','Day'),StrToInt(Copy(IntToStr(DisplayValue)
                       ,1,1))+1,3);
      2 : ConfigHeader('Maximum Calls Per Day',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
      3 : ConfigHeader('Maximum Download Ratio ^5(^4# DL Per 1 UL^5)',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
      4 : ConfigHeader('Maximum Download Ratio ^5(^4kB DL Per 1kB UL^5)',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
      5 : ConfigHeader('Minimum Posts Per 100 Calls For "ZZ" ACS Flag',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
      6 : ConfigHeader('Maximum Downloads Per Day ^5(^4#^5)',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
      7 : ConfigHeader('Maximum Downloads Per Day ^5(^4kB^5)',StrToInt(Copy(IntToStr(DisplayValue),1,1))+1,3);
    END;
    PrintACR('^5<^4SL ^5/ ^4Value^5> <^4SL ^5/ ^4Value^5> <^4SL ^5/ ^4Value^5> ...');
    HL;
    ShowSecRange(DisplayValue);
    NL;
    InputChar('Modify Values [(^1S^2)et,<^1CR^2>Page,(^1Q^2)uit]: ',Cmd,'QS'^M,[CapAll]);
    CASE Cmd OF
      'S' : BEGIN
              FromValue := -1;
              InputInteger('%LFEnter Lowest SL',FromValue,[NumbersOnly],0,255,Changed);
              IF (FromValue >= 0) AND (FromValue <= 255) THEN
                BEGIN
                  ToValue := -1;
                  InputInteger('%LFEnter Highest SL',ToValue,[NumbersOnly],0,255,Changed);
                  IF (ToValue >= 0) AND (ToValue <= 255) THEN
                    BEGIN
                      NewValue := -1;
                      InputLongInt('%LFEnter New Value',NewValue,[NumbersOnly],0,32767,Changed);
                      IF (NewValue >= 0) AND (NewValue <= 32767) THEN
                        FOR Counter := FromValue TO ToValue DO
                          Sec[Counter] := NewValue;
                    END;
                END;
            END;
      ^M  : CASE DisplayValue OF
              0   : DisplayValue := 108;
              108 : DisplayValue := 216;
              216 : DisplayValue := 0;
            END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.