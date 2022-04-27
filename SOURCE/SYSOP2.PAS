{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
{
Lee Woodridge
 09/24/2021 - Added ConfigHeader('MENU TITLE'); procedure
 10/21updating color codes
}
UNIT SysOp2; { System Configuration Main Menu }

INTERFACE

PROCEDURE ConfigHeader(s: STRING; b: BYTE); { LeeW: Added - Standardized header for all system configuration menus }
PROCEDURE HL; { LeeW: Added - Horizontal line to User.LineLen ** MOVE TO COMMON??? }
PROCEDURE SystemConfigurationEditor;

IMPLEMENTATION

USES
  Common,
  CRT,
  Maint,
  SysOp2A, { Main BBS }
  SysOp2B, { Modem/Node }
  SysOp2C, {  }
  SysOp2D, { Variables }
  SysOp2E, { Toggles }
  SysOp2F, {  }
  SysOp2G, {  }
  SysOp2H, {  }
  SysOp2I, {  }
  SysOp2J, { Color scheme }
  SysOp2K, {  }
  SysOp2L, { Credit System }
  SysOp2M, { New User Toggles }
  SysOp2N, { SysOp Macros }
  SysOp2O; { GetSecRange }
  
  
  PROCEDURE ConfigHeader(s: STRING; b: BYTE);
  VAR
    PageNum: STRING[3];
  BEGIN
    CLS;
    Prompt('^5'+#196+#243+' ^4'+s+'^5 '+#242);
    REPEAT
      Prompt(#196);
    UNTIL WhereX = ThisUser.LineLen-8;
    IF (b <> 0) THEN
      BEGIN
        PageNum := IntToStr(b);
        Print('^5'+#243+' ^4'+PageNum[1]+'^5/^4'+PageNum[2]+'^5 '+#242#196);
      END
    ELSE
      Print(#196#196#196#196#196#196#196#196);
    NL;
  END;
  
  PROCEDURE HL;
  BEGIN
    Prompt('^5');
    REPEAT
      Prompt(#196);
    UNTIL WhereX = ThisUser.LineLen;
    NL;
  END;

PROCEDURE SystemConfigurationEditor;
VAR
  Cmd: Char;
BEGIN
  REPEAT
    SaveGeneral(TRUE);
    WITH General DO
      BEGIN
        Abort := FALSE;
        Next := FALSE;
        ConfigHeader('System Configuration',0);
        PrintACR(PadLeftStr('^0(^1A^0) Main BBS Configuration',39)+
                 PadLeftStr('^0(^1B^0) Modem/Node Configuration',39));
        PrintACR(PadLeftStr('^0(^1C^0) System ACS Settings',39)+
                 PadLeftStr('^0(^1D^0) System Variables',39));
        PrintACR(PadLeftStr('^0(^1E^0) System Toggles',39)+
                 PadLeftStr('^0(^1F^0) File System Configuration',39));
        PrintACR(PadLeftStr('^0(^1G^0) Subscription/Validation System',39)+
                 PadLeftStr('^0(^1H^0) Network Mail Configuration',39));
        PrintACR(PadLeftStr('^0(^1I^0) Offline Mail Configuration',39)+
                 PadLeftStr('^0(^1J^0) Color Configuration',39));
        PrintACR(PadLeftStr('^0(^1K^0) Archive Configuration',39)+
                 PadLeftStr('^0(^1L^0) Credit System Configuration',39));
        PrintACR(PadLeftStr('^0(^1M^0) New User Question Toggles',39)+
                 PadLeftStr('^0(^1N^0) SysOp Macros',39));
        NL;
        PrintACR(PadLeftStr('^0(^11^0) Time allowed per '+AOnOff(General.PerCall,'call','day'),39)+
                 PadLeftStr('^0(^12^0) Max calls per day',39));
        PrintACR(PadLeftStr('^0(^13^0) UL/DL # files ratio',39)+
                 PadLeftStr('^0(^14^0) UL/DL K-bytes ratio',39));
        PrintACR(PadLeftStr('^0(^15^0) Post/Call ratio',39)+
                 PadLeftStr('^0(^16^0) Max downloads per day',39));
        PrintACR(PadLeftStr('^0(^17^0) Max download kbytes per day',39)+
                 PadLeftStr('^0(^18^0) Update System Averages',39));
        NL;
        InputChar('^2Configuration Menu [^1A^2-^1N^2,^11^2-^18^2,(^1Q^2)uit]: ',Cmd,'QABCDEFGHIJKLMN12345678'{^M},[CapAll]);
        CASE Cmd OF
          'A' : MainBBSConfiguration;
          'B' : ModemConfiguration;
          'C' : SystemACSSettings;
          'D' : SystemGeneralVariables;
          'E' : SystemFlaggedFunctions;
          'F' : FileAreaConfiguration;
          'G' : ValidationEditor;
          'H' : NetworkConfiguration;
          'I' : OffLineMailConfiguration;
          'J' : ColorConfiguration;
          'K' : ArchiveConfiguration;
          'L' : CreditConfiguration;
          'M' : NewUserTogglesConfiguration;
          'N' : IF (InCom) THEN
                  Messages(9,0,'') {"This can only be changed locally"}
                ELSE
                  SysOpMacroConfiguration;
          '1' : GetSecRange(1,TimeAllow);
          '2' : GetSecRange(2,CallAllow);
          '3' : GetSecRange(3,DLRatio);
          '4' : GetSecRange(4,DLKratio);
          '5' : GetSecRange(5,PostRatio);
          '6' : GetSecRange(6,DLOneDay);
          '7' : GetSecRange(7,DLKOneDay);
          '8' : UpdateGeneral;
        END;
      END;
    SaveGeneral(FALSE);
  UNTIL (Cmd = 'Q') OR (HangUp);
END;
END.