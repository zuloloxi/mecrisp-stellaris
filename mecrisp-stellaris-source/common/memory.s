@
@    Mecrisp-Stellaris - A native code Forth implementation for ARM-Cortex M microcontrollers
@    Copyright (C) 2013  Matthias Koch
@
@    This program is free software: you can redistribute it and/or modify
@    it under the terms of the GNU General Public License as published by
@    the Free Software Foundation, either version 3 of the License, or
@    (at your option) any later version.
@
@    This program is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@    GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License
@    along with this program.  If not, see <http://www.gnu.org/licenses/>.
@

@ Speicherzugriffe aller Art
@ Memory access


@------------------------------------------------------------------------------
  Wortbirne Flag_visible, "move"  @ Move some bytes around. This can cope with overlapping memory areas.
move:  @ ( Quelladdr Zieladdr Byteanzahl -- ) ( Source Destination Count -- )
@------------------------------------------------------------------------------

  push {r0, r1, r2, lr}

  popda r1 @ Count
  popda r2 @ Destination address
  @ TOS:     Source address

  @ Count > 0 ?
  cmp r1, #0
  beq 3f @ Nothing to do if count is zero.

  @ Compare source and destination address to find out which direction to copy.
  cmp r2, tos
  beq 3f @ If source and destionation are the same, nothing to do.
  blo 2f

  subs tos, #1
  subs r2, #1

1:@ Source > Destination --> Backward move
  ldrb r0, [tos, r1]
  strb r0, [r2, r1]
  subs r1, #1
  bne 1b
  b 3f

2:@ Source < Destination --> Forward move
  ldrb r0, [tos]
  strb r0, [r2]
  adds tos, #1
  adds r2, #1
  subs r1, #1
  bne 2b

3:drop
  pop {r0, r1, r2, pc}

@------------------------------------------------------------------------------
  Wortbirne Flag_visible, "fill"  @ Fill memory with given byte.
  @ ( Destination Count Filling -- )
@------------------------------------------------------------------------------
  @ 6.1.1540 FILL CORE ( c-addr u char -- ) If u is greater than zero, store char in each of u consecutive characters of memory beginning at c-addr. 

  popda r0 @ Filling byte
  popda r1 @ Count
  @ TOS      Destination

  cmp r1, #0
  beq 2f

1:subs r1, #1
  strb r0, [tos, r1]
  bne 1b

2:drop
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "@" @ ( 32-addr -- x )
                              @ Loads the cell at 'addr'.
@ -----------------------------------------------------------------------------
  ldr tos, [tos]
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline|Flag_opcodierbar_Speicherschreiben, "!" @ ( x 32-addr -- )
@ Given a value 'x' and a cell-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  str w, [tos]     @ Popping both saves a cycle.
  movs tos, x
  bx lr
  str tos, [r0] @ For opcoding with one constant
  str r1, [r0]  @ For opcoding with two constants

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "+!" @ ( x 32-addr -- )
                               @ Adds 'x' to the memory cell at 'addr'.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldr y, [tos]       @ Load the current cell value
  adds y, w            @ Do the add
  str y, [tos]       @ Store it back
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "h@" @ ( 16-addr -- x )
                              @ Loads the half-word at 'addr'.
@ -----------------------------------------------------------------------------
  ldrh tos, [tos]
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline|Flag_opcodierbar_Speicherschreiben, "h!" @ ( x 16-addr -- )
@ Given a value 'x' and an 16-bit-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  strh w, [tos]     @ Popping both saves a cycle.
  movs tos, x
  bx lr
  strh tos, [r0] @ For opcoding with one constant
  strh r1, [r0]  @ For opcoding with two constants

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "h+!" @ ( x 16-addr -- )
                                @ Adds 'x' to the memory cell at 'addr'.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrh y, [tos]       @ Load the current cell value
  adds y, w            @ Do the add
  strh y, [tos]       @ Store it back
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "c@" @ ( 8-addr -- x )
                              @ Loads the byte at 'addr'.
@ -----------------------------------------------------------------------------
  ldrb tos, [tos]
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline|Flag_opcodierbar_Speicherschreiben, "c!" @ ( x 8-addr -- )
@ Given a value 'x' and an 8-bit-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  strb w, [tos]     @ Popping both saves a cycle.
  movs tos, x
  bx lr
  strb tos, [r0] @ For opcoding with one constant
  strb r1, [r0]  @ For opcoding with two constants

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "c+!" @ ( x 8-addr -- )
                               @ Adds 'x' to the memory cell at 'addr'.
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrb y, [tos]       @ Load the current cell value
  adds y, w            @ Do the add
  strb y, [tos]       @ Store it back
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "bis!" @ ( x 32-addr -- )  Set bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldr y, [tos] @ Alten Inhalt laden
  orrs y, w     @ Hinzuverodern
  str y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "bic!" @ ( x 32-addr -- )  Clear bits
  @ Löscht die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldr y, [tos] @ Alten Inhalt laden
  bics y, w     @ Bits löschen
  str y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "xor!" @ ( x 32-addr -- )  Toggle bits
  @ Wechselt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldr y, [tos] @ Alten Inhalt laden
  eors y, w     @ Bits umkehren
  str y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "bit@" @ ( x 32-addr -- )  Check bits
  @ Prüft, ob Bits in der Speicherstelle gesetzt sind
@ -----------------------------------------------------------------------------
  ldm psp!, {w}  @ Bitmaske holen
  ldr tos, [tos] @ Speicherinhalt holen
  ands tos, w    @ Bleibt nach AND etwas über ?

  .ifdef m0core
  beq 1f
  movs tos, #0
  mvns tos, tos
1:bx lr
  .else
  it ne
  movne tos, #-1 @ Bleibt etwas über, mache ein ordentliches true-Flag daraus.
  bx lr
  .endif

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "hbis!" @ ( x 16-addr -- )  Set bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrh y, [tos] @ Alten Inhalt laden
  orrs y, w     @ Hinzuverodern
  strh y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "hbic!" @ ( x 16-addr -- )  Clear bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrh y, [tos] @ Alten Inhalt laden
  bics y, w     @ Hinzuverodern
  strh y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "hxor!" @ ( x 16-addr -- )  Toggle bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrh y, [tos] @ Alten Inhalt laden
  eors y, w     @ Hinzuverodern
  strh y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "hbit@" @ ( x 16-addr -- )  Check bits
  @ Prüft, ob Bits in der Speicherstelle gesetzt sind
@ -----------------------------------------------------------------------------
  ldm psp!, {w}  @ Bitmaske holen
  ldrh tos, [tos] @ Speicherinhalt holen
  ands tos, w    @ Bleibt nach AND etwas über ?

  .ifdef m0core
  beq 1f
  movs tos, #0
  mvns tos, tos
1:bx lr
  .else
  it ne
  movne tos, #-1 @ Bleibt etwas über, mache ein ordentliches true-Flag daraus.
  bx lr
  .endif

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "cbis!" @ ( x 8-addr -- )  Set bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrb y, [tos] @ Alten Inhalt laden
  orrs y, w     @ Hinzuverodern
  strb y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "cbic!" @ ( x 8-addr -- )  Clear bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrb y, [tos] @ Alten Inhalt laden
  bics y, w     @ Hinzuverodern
  strb y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "cxor!" @ ( x 8-addr -- )  Toggle bits
  @ Setzt die Bits in der Speicherstelle
@ -----------------------------------------------------------------------------
  ldm psp!, {w, x} @ X is the new TOS after the store completes.
  ldrb y, [tos] @ Alten Inhalt laden
  eors y, w     @ Hinzuverodern
  strb y, [tos] @ Zurückschreiben
  movs tos, x
  bx lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_inline, "cbit@" @ ( x 8-addr -- )  Check bits
  @ Prüft, ob Bits in der Speicherstelle gesetzt sind
@ -----------------------------------------------------------------------------
  ldm psp!, {w}  @ Bitmaske holen
  ldrb tos, [tos] @ Speicherinhalt holen
  ands tos, w    @ Bleibt nach AND etwas über ?

  .ifdef m0core
  beq 1f
  movs tos, #0
  mvns tos, tos
1:bx lr
  .else
  it ne
  movne tos, #-1 @ Bleibt etwas über, mache ein ordentliches true-Flag daraus.
  bx lr
  .endif
