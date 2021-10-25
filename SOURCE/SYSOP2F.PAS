{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2F;

INTERFACE

PROCEDURE FileAreaConfiguration;

IMPLEMENTATION

USES
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
      Print('%CL^1File Area Configuration:');
      NL;
      PrintACR('^0A. Upload/download ratio system    : ^1'+ShowOnOff(ULDLRatio));
      PrintACR('^0B. File point system               : ^1'+ShowOnOff(FileCreditRatio));
      PrintACR('^0C. Daily download limits           : ^1'+ShowOnOff(DailyLimits));
      PrintACR('^0D. Test and convert uploads        : ^1'+ShowOnOff(TestUploads));
      PrintACR('^0E. File point rewarding system     : ^1'+ShowOnOff(RewardSystem));
      PrintACR('^0F. Search for/Use FILE_ID.DIZ      : ^1'+ShowOnOff(FileDiz));
      PrintACR('^0G. Recompress like archives        : ^1'+ShowOnOff(Recompress));
      PrintACR('^0H. Credit reward compensation ratio: ^1'+IntToStr(RewardRatio)+'%');
      PrintACR('^0I. File point compensation ratio   : ^1'+IntToStr(FileCreditComp)+' to 1');
      PrintACR('^0J. Area file size per 1 file point : ^1'+IntToStr(FileCreditCompBaseSize)+'k');
      PrintACR('^0K. Upload time refund percent      : ^1'+IntToStr(ULRefund)+'%');
      PrintACR('^0L. "To-SysOp" file area            : ^1'+AOnOff(ToSysOpDir = 0,'*None*',IntToStr(ToSysOpDir)));
      PrintACR('^0M. Auto-validate ALL files ULed?   : ^1'+ShowYesNo(ValidateAllFiles));
      PrintACR('^0N. Max k-bytes allowed in temp dir : ^1'+IntToStr(MaxInTemp));
      PrintACR('^0O. Min k-bytes to save for resume  : ^1'+IntToStr(MinResume));
      PrintACR('^0P. Max batch download files        : ^1'+IntToStr(MaxBatchDLFiles));
      PrintACR('^0R. Max batch upload files          : ^1'+IntToStr(MaxBatchUlFiles));
      PrintACR('^0S. UL duplicate file search        : ^1'+ShowOnOff(SearchDup));
      PrintACR('^0T. Force batch download at login   : ^1'+ShowOnOff(ForceBatchDL));
      PrintACR('^0U. Force batch upload at login     : ^1'+ShowOnOff(ForceBatchUL));
      NL;
      Prt('Enter selection [^1A^2-^1P^2,^1R^2-^1U^2,^1Q^2=^1Quit^2]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTU'^M,TRUE,TRUE);
      CASE Cmd OF
        'A' : ULDLRatio := NOT ULDLRatio;
        'B' : FileCreditRatio := NOT FileCreditRatio;
        'C' : DailyLimits := NOT DailyLimits;
        'D' : TestUploads := NOT TestUploads;
        'E' : RewardSystem := NOT RewardSystem;
        'F' : FileDiz := NOT FileDiz;
        'G' : Recompress := NOT Recompress;
        'H' : InputIntegerWOC('%LFNew percentage of file credits to reward',RewardRatio,[DisplayValue,NumbersOnly],0,100);
        'I' : InputByteWOC('%LFNew file point compensation ratio',FileCreditComp,[DisplayValue,Numbersonly],0,100);
        'J' : InputByteWOC('%LFNew area file size per 1 file Point',FileCreditCompBaseSize,[DisplayValue,NumbersOnly],0,255);
        'K' : InputByteWOC('%LFNew upload time refund percent',ULRefund,[DisplayValue,NumbersOnly],0,100);
        'L' : InputIntegerWOC('%LFNew "To-SysOp" file area (0=None)',ToSysOpDir,[DisplayValue,NumbersOnly],0,NumFileAreas);
        'M' : ValidateAllFiles := NOT ValidateAllFiles;
        'N' : InputLongIntWOC('%LFNew max k-bytes',MaxInTemp,[DisplayValue,NumbersOnly],0,2097151);
        'O' : InputLongIntWOC('%LFNew min resume k-bytes',MinResume,[DisplayValue,NumbersOnly],0,2097151);
        'P' : InputByteWOC('%LFNew max batch download files',MaxBatchDLFiles,[DisplayValue,NumbersOnly],1,255);
        'R' : InputByteWOC('%LFNew max batch upload files',MaxBatchULFiles,[DisplayValue,NumbersOnly],1,255);
        'S' : SearchDup := NOT SearchDup;
        'T' : ForceBatchDL := NOT ForceBatchDL;
        'U' : ForceBatchUL := NOT ForceBatchUL;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
