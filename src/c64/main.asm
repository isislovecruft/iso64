	;; Supersingular-isogeny key encapsulation in 6502/6510 assembly

	!zone sike
	!to "sike", cbm             ; Direct the assembler to output to this file, and store a c64-style program counter
    * = $cf00                   ; Set the program counter

	;; Assemble and include the other source files
    ;; !source "constants.asm"	
!source "field.asm"
!source "rand.asm"
