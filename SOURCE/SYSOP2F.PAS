{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
indent
}
UNIT SysOp2F;

INTERFACE

PROCEDURE FileAreaConfiguration;

IMPLEMENTATION

USES
  SysOp2, {ConfigHeader}
  Common;

PROCEDURE FileAreaConfiguration;
VAR
  Cmd: Char;
BEGIN
  REPEAT
    WITH General DO
      BEGIN
        Abort := FALSE;
        Next := FALSE;
        ConfigHeader('File System Configuration',0,0);
      { Print('%CL^1File Area Configuration:');
        NL; }
        PrintACR('^0(^1A^0) Upload/download ratio system    : ^1'+ShowOnOff(ULDLRatio));
        PrintACR('^0(^1B^0) File point system               : ^1'+ShowOnOff(FileCreditRatio));
        PrintACR('^0(^1C^0) Daily download limits           : ^1'+ShowOnOff(DailyLimits));
        PrintACR('^0(^1D^0) Test and convert uploads        : ^1'+ShowOnOff(TestUploads));
        PrintACR('^0(^1E^0) File point rewarding system     : ^1'+ShowOnOff(RewardSystem));
        PrintACR('^0(^1F^0) Search for/Use FILE_ID.DIZ      : ^1'+ShowOnOff(FileDiz)); {LeeW: Also DESC.SDI}
        PrintACR('^0(^1G^0) Recompress like archives        : ^1'+ShowOnOff(Recompress));
        PrintACR('^0(^1H^0) Credit reward compensation ratio: ^1'+IntToStr(RewardRatio)+'%');
        PrintACR('^0(^1I^0) File point compensation ratio   : ^1'+IntToStr(FileCreditComp)+' to 1');
        PrintACR('^0(^1J^0) Area file size per 1 file point : ^1'+IntToStr(FileCreditCompBaseSize)+'k');
        PrintACR('^0(^1K^0) Upload time refund percent      : ^1'+IntToStr(ULRefund)+'%');
        PrintACR('^0(^1L^0) "To-SysOp" file area            : ^1'+AOnOff(ToSysOpDir = 0,'*None*',IntToStr(ToSysOpDir)));
        PrintACR('^0(^1M^0) Auto-validate ALL files ULed?   : ^1'+ShowYesNo(ValidateAllFiles));
        PrintACR('^0(^1N^0) Max k-bytes allowed in temp dir : ^1'+IntToStr(MaxInTemp));
        PrintACR('^0(^1O^0) Min k-bytes to save for resume  : ^1'+IntToStr(MinResume));
        PrintACR('^0(^1P^0) Max batch download files        : ^1'+IntToStr(MaxBatchDLFiles));
        PrintACR('^0(^1R^0) Max batch upload files          : ^1'+IntToStr(MaxBatchUlFiles));
        PrintACR('^0(^1S^0) UL duplicate file search        : ^1'+ShowOnOff(SearchDup));
        PrintACR('^0(^1T^0) Force batch download at login   : ^1'+ShowOnOff(ForceBatchDL));
        PrintACR('^0(^1U^0) Force batch upload at login     : ^1'+ShowOnOff(ForceBatchUL));
        NL;
        InputChar('Enter selection [^1A^2-^1P^2,^1R^2-^1U^2,^1Q^2=^1Quit^2]: ',Cmd,'QABCDEFGHIJKLMNOPRSTU'^M,[CapAll]);
        CASE Cmd OF
          'A' : ULDLRatio := NOT ULDLRatio;
          'B' : FileCreditRatio := NOT FileCreditRatio;
          'C' : DailyLimits := NOT DailyLimits;
          'D' : TestUploads := NOT TestUploads;
          'E' : RewardSystem := NOT RewardSystem;
          'F' : FileDiz := NOT FileDiz;
          'G' : Recompress := NOT Recompress;
          'H' : InputInteger('%LFNew percentage of file credits to reward',RewardRatio,[InteractiveEdit,
                             NumbersOnly],0,100,Changed);
          'I' : InputByte('%LFNew file point compensation ratio',FileCreditComp,[InteractiveEdit,
                          NumbersOnly],0,100,Changed);
          'J' : InputByte('%LFNew area file size per 1 file Point',FileCreditCompBaseSize,[InteractiveEdit,
                          NumbersOnly],0,255,Changed);
          'K' : InputByte('%LFNew upload time refund percent',ULRefund,[InteractiveEdit,
                          NumbersOnly],0,100,Changed);
          'L' : InputInteger('%LFNew "To-SysOp" file area (0=None)',ToSysOpDir,[InteractiveEdit,
                             NumbersOnly],0,NumFileAreas,Changed);
          'M' : ValidateAllFiles := NOT ValidateAllFiles;
          'N' : InputLongInt('%LFNew max k-bytes',MaxInTemp,[InteractiveEdit,
                             NumbersOnly],0,2097151,Changed);
          'O' : InputLongInt('%LFNew min resume k-bytes',MinResume,[InteractiveEdit,
                             NumbersOnly],0,2097151,Changed);
          'P' : InputByte('%LFNew max batch download files',MaxBatchDLFiles,[InteractiveEdit,
                          NumbersOnly],1,255,Changed);
          'R' : InputByte('%LFNew max batch upload files',MaxBatchULFiles,[InteractiveEdit,
                          NumbersOnly],1,255,Changed);
          'S' : SearchDup := NOT SearchDup;
          'T' : ForceBatchDL := NOT ForceBatchDL;
          'U' : ForceBatchUL := NOT ForceBatchUL;
        END;
      END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.