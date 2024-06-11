{$A+,B-,D+,E-,F+,I-,L+,N-,O+,R+,S-,V-}
{
 04/18/2022 - gutted this, some parts moved to common2
}

UNIT MyIO;

INTERFACE

TYPE
  WindowRec = ARRAY[0..8000] OF Byte;
  ScreenType = ARRAY [0..3999] OF Byte;

VAR
  Wind: WindowRec;
  MonitorType: Byte ABSOLUTE $0000:$0449;
  ScreenAddr: ScreenType ABSOLUTE $B800:$0000;
  ScreenSize: Integer;
  MaxDisplayRows,
  MaxDisplayCols: Byte;

PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer);
PROCEDURE Cursor(b: BOOLEAN);
PROCEDURE SaveScreen(VAR Wind: WindowRec);
PROCEDURE RemoveWindow(VAR Wind: WindowRec);

IMPLEMENTATION

USES
  CRT;

PROCEDURE Cursor(b: BOOLEAN); ASSEMBLER;
ASM
  cmp b, 1
  je @turnon
  mov ch, 9
  mov cl, 0
  jmp @goforit
  @turnon:
  mov ch, 6
  mov cl, 7
  @goforit:
  mov ah,1
  int 10h
END;

PROCEDURE SaveScreen(VAR Wind: WindowRec);
BEGIN
  Move(ScreenAddr[0],Wind[0],ScreenSize);
END;

PROCEDURE RemoveWindow(VAR Wind: WindowRec);
BEGIN
  Move(Wind[0],ScreenAddr[0],ScreenSize);
END;

PROCEDURE Update_Logo(VAR Addr1,Addr2; BlkLen: Integer);
BEGIN
  INLINE (
    $1E/
    $C5/$B6/ADDR1/
    $C4/$BE/ADDR2/
    $8B/$8E/BLKLEN/
    $E3/$5B/
    $8B/$D7/
    $33/$C0/
    $FC/
    $AC/
    $3C/$20/
    $72/$05/
    $AB/
    $E2/$F8/
    $EB/$4C/
    $3C/$10/
    $73/$07/
    $80/$E4/$F0/
    $0A/$E0/
    $EB/$F1/
    $3C/$18/
    $74/$13/
    $73/$19/
    $2C/$10/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $80/$E4/$8F/
    $0A/$E0/
    $EB/$DA/
    $81/$C2/$A0/$00/
    $8B/$FA/
    $EB/$D2/
    $3C/$1B/
    $72/$07/
    $75/$CC/
    $80/$F4/$80/
    $EB/$C7/
    $3C/$19/
    $8B/$D9/
    $AC/
    $8A/$C8/
    $B0/$20/
    $74/$02/
    $AC/
    $4B/
    $32/$ED/
    $41/
    $F3/$AB/
    $8B/$CB/
    $49/
    $E0/$AA/
    $1F);
END;

END.
