;; -*- mode: asm -*-
;;
;; This file is part of a Supersingular Isogeny Key Encapsulation (SIKE) over P434 for Commodore 64.
;; Copyright (c) 2020 isis lovecruft
;; See LICENSE for licensing information.
;;
;; Authors:
;; - isis agora lovecruft <isis@patternsinthevoid.net>
	
;; Supersingular-isogeny key encapsulation over the P434 Galois field in 6502/6510 assembly for Commodore 64.

!cpu 6510 	                    ; For 6502/6510 with undocumented opcodes
!zone sike                      ; Namespacing
!to "sike", cbm                 ; Direct the assembler to output to this file, and store a c64-style program counter
* = $cf00                       ; Set the program counter

	;; Assemble and include the other source files
!source "constants.asm"	
!source "subtle.asm"
!source "field.asm"
!source "rand.asm"
