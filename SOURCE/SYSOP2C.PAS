{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

UNIT SysOp2C;

INTERFACE

PROCEDURE SystemACSSettings;

IMPLEMENTATION

USES
  Common;

PROCEDURE SystemACSSettings;
VAR
  TempACS: ACString;
  Cmd: Char;
  Changed: Boolean;
BEGIN
  REPEAT
    WITH General DO
    BEGIN
      Abort := FALSE;
      Next := FALSE;
      MCIAllowed := FALSE;
      CLS;
      Print('^1System ACS Settings:');
      NL;
      PrintACR('^0A. Full SysOp       : ^1'+PadLeftStr(SOp,18)+
               '^0B. Full Co-SysOp    : ^1'+CSOp);
      PrintACR('^0C. Msg Area SysOp   : ^1'+PadLeftStr(MSOp,18)+
               '^0D. File Area SysOp  : ^1'+FSOp);
      PrintACR('^0E. Change a vote    : ^1'+PadLeftStr(ChangeVote,18)+
               '^0F. Add voting choice: ^1'+AddChoice);
      PrintACR('^0G. Post public      : ^1'+PadLeftStr(NormPubPost,18)+
               '^0H. Send e-mail      : ^1'+NormPrivPost);
      PrintACR('^0I. See anon pub post: ^1'+PadLeftStr(AnonPubRead,18)+
               '^0J. See anon E-mail  : ^1'+AnonPrivRead);
      PrintACR('^0K. Global Anon post : ^1'+PadLeftStr(AnonPubPost,18)+
               '^0L. E-mail anon      : ^1'+AnonPrivPost);
      PrintACR('^0M. See unval. files : ^1'+PadLeftStr(SeeUnVal,18)+
               '^0N. DL unval. files  : ^1'+DLUnVal);
      PrintACR('^0O. No UL/DL ratio   : ^1'+PadLeftStr(NoDLRatio,18)+
               '^0P. No PostCall ratio: ^1'+NoPostRatio);
      PrintACR('^0R. No DL credits chk: ^1'+PadLeftStr(NoFileCredits,18)+
               '^0S. ULs auto-credited: ^1'+ULValReq);
      PrintACR('^0T. MCI in TeleConf  : ^1'+PadLeftStr(TeleConfMCI,18)+
               '^0U. Chat at any hour : ^1'+OverRideChat);
      PrintACR('^0V. Send Netmail     : ^1'+PadLeftStr(NetMailACS,18)+
               '^0W. "Invisible" Mode : ^1'+Invisible);
      PrintACR('^0X. Mail file attach : ^1'+PadLeftStr(FileAttachACS,18)+
               '^0Y. SysOp PW at logon: ^1'+SPW);
      PrintACR('^0Z. Last On Add      : ^1'+PadLeftStr(LastOnDatACS,18));
      MCIAllowed := TRUE;
      NL;
      Prt('Enter selection [^1A^2-^1P^2,^1R^2-^1Z^2,^1Q^2=^1Quit^2]: ');
      OneK(Cmd,'QABCDEFGHIJKLMNOPRSTUVWXYZ'^M,TRUE,TRUE);
      IF (Cmd IN ['A'..'P','R'..'Z']) THEN
      BEGIN
        CASE Cmd OF
          'A' : TempACS := SOp;
          'B' : TempACS := CSOp;
          'C' : TempACS := MSOp;
          'D' : TempACS := FSOp;
          'E' : TempACS := ChangeVote;
          'F' : TempACS := AddChoice;
          'G' : TempACS := NormPubPost;
          'H' : TempACS := NormPrivPost;
          'I' : TempACS := AnonPubRead;
          'J' : TempACS := AnonPrivRead;
          'K' : TempACS := AnonPubPost;
          'L' : TempACS := AnonPrivPost;
          'M' : TempACS := SeeUnVal;
          'N' : TempACS := DLUnVal;
          'O' : TempACS := NoDLRatio;
          'P' : TempACS := NoPostRatio;
          'R' : TempACS := NoFileCredits;
          'S' : TempACS := ULValReq;
          'T' : TempACS := TeleConfMCI;
          'U' : TempACS := OverRideChat;
          'V' : TempACS := NetMailACS;
          'W' : TempACS := Invisible;
          'X' : TempACS := FileAttachACS;
          'Y' : TempACS := SPW;
          'Z' : TempACS := LastOnDatACS;
        END;
        InputWN1('%LFNew ACS: ',TempACS,(SizeOf(ACString) - 1),[InterActiveEdit],Changed);
        CASE Cmd OF
          'A' : SOp := TempACS;
          'B' : CSOp := TempACS;
          'C' : MSOp := TempACS;
          'D' : FSOp := TempACS;
          'E' : ChangeVote := TempACS;
          'F' : AddChoice := TempACS;
          'G' : NormPubPost := TempACS;
          'H' : NormPrivPost := TempACS;
          'I' : AnonPubRead := TempACS;
          'J' : AnonPrivRead := TempACS;
          'K' : AnonPubPost := TempACS;
          'L' : AnonPrivPost := TempACS;
          'M' : SeeUnVal := TempACS;
          'N' : DLUnVal := TempACS;
          'O' : NoDLRatio := TempACS;
          'P' : NoPostRatio := TempACS;
          'R' : NoFileCredits := TempACS;
          'S' : ULValReq := TempACS;
          'T' : TeleConfMCI := TempACS;
          'U' : OverRideChat := TempACS;
          'V' : NetMailACS := TempACS;
          'W' : Invisible := TempACS;
          'X' : FileAttachACS := TempACS;
          'Y' : SPW := TempACS;
          'Z' : LastOnDatACS := TempACS;
        END;
      END;
    END;
  UNTIL (Cmd = 'Q') OR (HangUp);
END;

END.
