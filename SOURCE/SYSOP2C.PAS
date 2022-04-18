{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
indented
aesthetics
04/15/2022 added quote and onliner acs
}
UNIT SysOp2C;

INTERFACE

PROCEDURE SystemACSSettings;

IMPLEMENTATION

USES
  Common,
  SysOp2; {ConfigHeader}

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
        ConfigHeader('ACS Settings');
        PrintACR(PadLeftStr('^0(^1A^0) Full SysOp       : ^1'+SOp,39)+' '+
                 PadLeftStr('^0(^1B^0) Full Co-SysOp    : ^1'+CSOp,39));
        PrintACR(PadLeftStr('^0(^1C^0) Msg Area SysOp   : ^1'+MSOp,39)+' '+
                 PadLeftStr('^0(^1D^0) File Area SysOp  : ^1'+FSOp,39));
        PrintACR(PadLeftStr('^0(^1E^0) Change Vote      : ^1'+ChangeVote,39)+' '+
                 PadLeftStr('^0(^1F^0) Add Voting Choice: ^1'+AddChoice,39));
        PrintACR(PadLeftStr('^0(^1G^0) Post Publicly    : ^1'+NormPubPost,39)+' '+
                 PadLeftStr('^0(^1H^0) Send Priv Mail   : ^1'+NormPrivPost,39));
        PrintACR(PadLeftStr('^0(^1I^0) See Anon pub post: ^1'+AnonPubRead,39)+' '+
                 PadLeftStr('^0(^1J^0) See Anon E-mail  : ^1'+AnonPrivRead,39));
        PrintACR(PadLeftStr('^0(^1K^0) Global Anon Post : ^1'+AnonPubPost,39)+' '+
                 PadLeftStr('^0(^1L^0) E-mail anon      : ^1'+AnonPrivPost,39));
        PrintACR(PadLeftStr('^0(^1M^0) See unval. files : ^1'+SeeUnVal,39)+' '+
                 PadLeftStr('^0(^1N^0) DL unval. files  : ^1'+DLUnVal,39));
        PrintACR(PadLeftStr('^0(^1O^0) No UL/DL Ratio   : ^1'+NoDLRatio,39)+' '+
                 PadLeftStr('^0(^1P^0) No PostCall ratio: ^1'+NoPostRatio,39));
        PrintACR(PadLeftStr('^0(^1R^0) No DL credits chk: ^1'+NoFileCredits,39)+' '+
                 PadLeftStr('^0(^1S^0) Auto-Credit ULs  : ^1'+ULValReq,39));
        PrintACR(PadLeftStr('^0(^1T^0) MCIs in TeleConf : ^1'+TeleConfMCI,39)+' '+
                 PadLeftStr('^0(^1U^0) Chat at any hour : ^1'+OverRideChat,39));
        PrintACR(PadLeftStr('^0(^1V^0) Send Netmail     : ^1'+NetMailACS,39)+' '+
                 PadLeftStr('^0(^1W^0) "Invisible" Mode : ^1'+Invisible,39));
        PrintACR(PadLeftStr('^0(^1X^0) Mail file attach : ^1'+FileAttachACS,39)+' '+
                 PadLeftStr('^0(^1Y^0) SysOp PW at logon: ^1'+SPW,39));
        PrintACR(PadLeftStr('^0(^1Z^0) Last On Add      : ^1'+LastOnDatACS,39)+' '+
                 PadLeftStr('^0(^1!^0) Add Quote        : ^1'+AddQuoteACS,39));
        PrintACR(PadLeftStr('^0(^1@^0) Add OneLiner     : ^1'+AddOneLinerACS,39){+' '+}
                 );
        
      { PrintACR(PadLeftStr('^0(^1^0) : ^1'+ACSVAR,39)+' '+
                 PadLeftStr('^0(^1^0) : ^1'+ACSVAR,39)); }
        
        MCIAllowed := TRUE;
        NL;
        InputChar('ACS Configuration [^1A^2-^1P^2,^1R^2-^1Z^2,(^1Q^2)uit]: ',Cmd,
              'QABCDEFGHIJKLMNOPRSTUVWXYZ!@'{^M},[CapAll]);
        IF (Cmd <> 'Q'{IN ['A'..'P','R'..'Z']}) THEN
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
            if cmd = '!' then
            InputString('%LFNew ACS: ',AddQuoteACS,(SizeOf(ACString)-1),[InterActiveEdit],Changed)
            else if cmd = '@' then
            InputString('%LFNew ACS: ',AddOneLinerACS,(SizeOf(ACString)-1),[InterActiveEdit],Changed)
            else
            InputString('%LFNew ACS: ',TempACS,(SizeOf(ACString)-1),[InterActiveEdit],Changed);
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