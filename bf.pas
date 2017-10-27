{*

===================================================================================

Brainfuck v1.01 (build 172)

Pascal version developed by ajack (aka Adrian Chiang) on 30-Jul-2005.

Questions or comments, please e-mail me at: ajack2001my [at] yahoo.com

- Array is 30001 bytes in size.
- Size of array is 1 byte.
- Nested loops can be 65535 generations into the loop.
- Code size of a brainfuck program is 4MBsin size.

Source code tested successfully with:

  Virtual Pascal v2.1 (build 279)
  Free Pascal 2.0.0

Based on the brainfuck documentation found at:

  http://cydathria.com

Brainfuck is a turing-complete programming language developed by
Urban Mueller:

  http://wuarchive.wustl.edu/~umueller/  (DOWN)


Difference from standard brainfuck implementations:

- Added the '#' (debug) command.  Will stop program and show contents
  of a[0..9] of array.  Must add command line parameter '-debug'
  to work.

v1.01 - Change the BF_LoadProg from using ReadLn to BlockRead as the
        previous version could not load programs that are longer than
        255 characters on a single text line.

===================================================================================

LEGALESSE

This source code is public domain.  The coder is not liable for anything
whatsoever.  The only guarantee it has is that it will take up storage space in
your computer.  Oh! It would be nice if you gave me credit if you use this source
code (in whole or in part).

===================================================================================
*}

PROGRAM Brainfuck;
USES
  SysUtils,  {/* Use this library for the FileExists command */}
  CRT;

CONST
  ASize = 30000;        {* Brainfuck array size *}
  LSize = 65535;        {* Loop command '[', ']' nested loop depth *}
  CSize = 1048576 * 4;  {* Code size is 4MB *}

  ProgVer = '1.01';
  ProgBuild = '172';

VAR
  Debug : Boolean;
  A     : Array [0..ASize] of Byte;
  LP,
  P     : Word;
  L     : Array [0..LSize] of LongInt;
  C     : Array [0..CSize] of Char;
  CEnd  : LongInt;

PROCEDURE PushLoop (CP: LongInt);
BEGIN
  L[LP] := CP;
  Inc (LP);
END;

PROCEDURE PopLoop (VAR CP: LongInt);
BEGIN
  Dec (LP);
  CP := L[LP];
END;

PROCEDURE BF_Init;
VAR
  I : LongInt;
BEGIN
  FOR I := 0 TO ASize DO
    A[I] := 0;
  LP := 0;
END;

PROCEDURE BF_LoadProg;
CONST
  BLen = 8192;
VAR
  FN : String;
  T  : File;
  AR,
  I  : LongInt;
  B  : Array [1..BLen] of Char;
BEGIN
  CEnd := 0;
  FN := UpperCase(ParamStr(2));

  IF FN = '-DEBUG' THEN
    Debug := True
  ELSE
    Debug := False;

  FN := ParamStr(1);
  IF NOT FileExists (FN) THEN
    BEGIN
      WriteLn ('Usage: BF <filename> [-debug]');
      Halt;
    END;
  Assign (T, FN);
  Reset (T, 1);
  BlockRead (T, B, BLen, AR);
  WHILE AR > 0 DO
    BEGIN
      FOR I := 1 TO AR DO
        BEGIN
          IF B[I] IN ['<', '>', '+', '-', '.', ',', '[', ']', '#'] THEN
            BEGIN
              C[CEnd] := B[I];
              Inc (CEnd);
            END;
        END;
      BlockRead (T, B, BLen, AR);
    END;
  Close (T);
  WriteLn ('Program code size is ', CEnd, ' bytes.');
  WriteLn;
END;

PROCEDURE BF_Runtime;
VAR
  I,
  Null,
  CWend,
  CNow : LongInt;

  PROCEDURE _Print (B: Byte);
  BEGIN
    IF B = 10 THEN
      WriteLn
    ELSE
      Write (Char(B));
  END;

  PROCEDURE _GetKey (VAR B: Byte);
  BEGIN
    B := Ord(ReadKey);
    Write (Char(B));
  END;

  PROCEDURE _LoopStart;
  VAR
    Done : Boolean;
  BEGIN
    IF A[P] > 0 THEN
      PushLoop (CNow)
    ELSE
      BEGIN
        CWend := 0;
        Done := False;
        I := CNow + 1;
        WHILE NOT Done DO
          BEGIN
            CASE C[I] OF
              '[' : Inc (CWend);
              ']' : BEGIN
                      Dec (CWend);
                      IF CWend < 0 THEN
                        BEGIN
                          CNow := I;
                          Done := True;
                        END;
                    END;
            END;
            Inc (I);
          END;
      END;
  END;

  PROCEDURE _LoopEnd;
  BEGIN
    IF A[P] > 0 THEN
      BEGIN
        PopLoop (CNow);
        PushLoop (CNow);
      END
    ELSE
      PopLoop (Null);
  END;

  FUNCTION Filler (V, L: LongInt): String;
  VAR
    S : String;
  BEGIN
    Str (V, S);
    WHILE Length (S) < L DO
      S :=  '0' + S;
    Filler := S;
  END;

  PROCEDURE _Debug;
  VAR
    I : Byte;
  BEGIN
    WriteLn ('P=', Filler(P, 5), '   IP=', Filler(CNow, 7));
    WriteLn;
    FOR I := 0 TO 4 DO
      Write ('A[', I, ']=', Filler(A[I], 3), '   ');
    WriteLn;
    FOR I := 5 TO 9 DO
      Write ('A[', I, ']=', Filler(A[I], 3), '   ');
    WriteLn;
    Halt;
  END;

BEGIN
  CNow := 0;
  WHILE CNow <= CEnd DO
    BEGIN
      CASE C[CNow] OF
        '>' : Inc (P);
        '<' : Dec (P);
        '+' : Inc (A[P]);
        '-' : Dec (A[P]);
        '.' : _Print (A[P]);
        ',' : _GetKey (A[P]);
        '[' : _LoopStart;
        ']' : _LoopEnd;
        '#' : IF Debug THEN _Debug;
      END;
      Inc (CNow);
    END;
END;

PROCEDURE BF_DeInit;
BEGIN
END;

PROCEDURE BF_Hello;
BEGIN
  WriteLn ('BF v', ProgVer, ' (Build ', ProgBuild, ') - Brainfuck interpreter.  Created by Adrian Chiang.');
  WriteLn ('(c) Copyright Renegade Demo Group, 2005-2007.  All Rights Reserved.');
  WriteLn;
END;

BEGIN
  BF_Hello;
  BF_Init;
  BF_LoadProg;
  BF_Runtime;
  BF_DeInit;
END.
