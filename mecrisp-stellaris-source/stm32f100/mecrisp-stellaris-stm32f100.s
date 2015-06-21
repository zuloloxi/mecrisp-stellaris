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

.syntax unified
.cpu cortex-m3
.thumb

@ -----------------------------------------------------------------------------
@ Swiches for capabilities of this chip
@ -----------------------------------------------------------------------------

@ Not available: .equ charkommaavailable, 1

@ -----------------------------------------------------------------------------
@ Start with some essential macro definitions
@ -----------------------------------------------------------------------------

.include "../common/datastackandmacros.s"

@ -----------------------------------------------------------------------------
@ Speicherkarte für Flash und RAM
@ Memory map for Flash and RAM
@ -----------------------------------------------------------------------------

@ Konstanten für die Größe des Ram-Speichers

.equ RamAnfang, 0x20000000 @ Start of RAM          Porting: Change this !
.equ RamEnde,   0x20002000 @ End   of RAM.   8 kb. Porting: Change this !

@ Konstanten für die Größe und Aufteilung des Flash-Speichers

.equ Kernschutzadresse,     0x00004000 @ Darunter wird niemals etwas geschrieben ! Mecrisp core never writes flash below this address.
.equ FlashDictionaryAnfang, 0x00004000 @ 16 kb für den Kern reserviert...           16 kb Flash reserved for core.
.equ FlashDictionaryEnde,   0x00020000 @ 112 kb Platz für das Flash-Dictionary     112 kb Flash available. Porting: Change this !
.equ Backlinkgrenze,        RamAnfang  @ Ab dem Ram-Start.


@ -----------------------------------------------------------------------------
@ Anfang im Flash - Interruptvektortabelle ganz zu Beginn
@ Flash start - Vector table has to be placed here
@ -----------------------------------------------------------------------------
.text    @ Hier beginnt das Vergnügen mit der Stackadresse und der Einsprungadresse
.include "vectors.s" @ You have to change vectors for Porting !

@ -----------------------------------------------------------------------------
@ Include the Forth core of Mecrisp-Stellaris
@ -----------------------------------------------------------------------------

.include "../common/forth-core.s"

@ -----------------------------------------------------------------------------
Reset: @ Einsprung zu Beginn
@ -----------------------------------------------------------------------------
   @ Initialisierungen der Hardware, habe und brauche noch keinen Datenstack dafür
   @ Initialisations for Terminal hardware, without Datastack.
   bl uart_init

Reset_Inneneinsprung:
   @ Return stack pointer already set up. Time to set data stack pointer !
   @ Normaler Stackpointer bereits gesetzt. Setze den Datenstackpointer:
   ldr psp, =datenstackanfang

   @ TOS setzen, um Pufferunterläufe gut erkennen zu können
   @ TOS magic number to see spurious stack underflows in .s
   @ ldr tos, =0xAFFEBEEF
   movs tos, #42

   @ Vorbereitungen für die Flash-Pointer
   @ Catch the pointers for Flash dictionary
   .include "../common/catchflashpointers.s"

   writeln "Mecrisp-Stellaris 1.1 for STM32F100 by Matthias Koch"

   @ Genauso wie in quit. Hier nochmal, damit quit nicht nach dem Init-Einsprung nochmal tätig wird.
   @ Exactly like the initialisations in quit. Here again because quit should not be executed after running "init".
   ldr r0, =base
   movs r1, #10
   str r1, [r0]

   ldr r0, =state
   movs r1, #0
   str r1, [r0]

   ldr r0, =konstantenfaltungszeiger
   movs r1, #0
   str r1, [r0]

   @ Suche nach der init-Definition:
   @ Search for current init definition in dictionary:
   ldr r0, =init_name
   pushda r0
   bl find
   drop @ Flags brauche ich nicht No need for flags
   cmp tos, #0
   beq 1f
     @ Gefunden ! Found !
     bl execute
     b.n quit_innenschleife
1:
   drop @ Die 0-Adresse von find. Wird hier heruntergeworfen, damit der Startwert AFFEBEEF erhalten bleibt !
   b.n quit @ Drop 0-address of find to keep magic TOS value intact.

init_name: .byte 4, 105, 110, 105, 116, 0 @ "init"

.ltorg @ Ein letztes Mal Konstanten schreiben


