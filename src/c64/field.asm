;; -*- mode: asm -*-
;;
;; This file is part of a Supersingular Isogeny Key Encapsulation (SIKE) over P434 for Commodore 64.
;; Copyright (c) 2020 isis lovecruft
;; See LICENSE for licensing information.
;;
;; Authors:
;; - isis agora lovecruft <isis@patternsinthevoid.net>

;; Arithmetic in a finite field of prime order.

;; Written for the ACME Cross-Assembler
;;
;; Build with -Wtype-mismatch to catch mismatches between addrs and immediates.

!cpu 6510                       ; For 6502/6510 with undocumented opcodes
!zone field                     ; Namespacing

;; 73 words prior to the user ROM end ($cfff)
!addr P434_PRIME_ADDR = $cfb6

    * = $c000                   ; Starting program counter on Commodore 64

.field_element_modulus_store_byte:
    STA ($cf,X)                ; Store at $cfb6 (73 bytes offset from $cfff because 6-bit limbs)
    INX
    RTS

    ;; XXX this is big endian, reverse it
field_element_modulus:
    LDX #$b6                    ; Address offset
    LDA #$00                    ; First byte of prime modulus
    JSR .field_element_modulus_store_byte
    LDA #$02                    ; Second byte of prime modulus
    JSR .field_element_modulus_store_byte
    LDA #$34                    ; Third byte
    JSR .field_element_modulus_store_byte
    LDA #$1F                    ; Hopefully you get the idea
    JSR .field_element_modulus_store_byte
    LDA #$27
    JSR .field_element_modulus_store_byte
    LDA #$17
    JSR .field_element_modulus_store_byte
    LDA #$73
    JSR .field_element_modulus_store_byte
    LDA #$44
    JSR .field_element_modulus_store_byte
    LDA #$6C
    JSR .field_element_modulus_store_byte
    LDA #$FC
    JSR .field_element_modulus_store_byte
    LDA #$5F
    JSR .field_element_modulus_store_byte
    LDA #$D6
    JSR .field_element_modulus_store_byte
    LDA #$81
    JSR .field_element_modulus_store_byte
    LDA #$C5
    JSR .field_element_modulus_store_byte
    LDA #$20
    JSR .field_element_modulus_store_byte
    LDA #$56
    JSR .field_element_modulus_store_byte
    LDA #$7B
    JSR .field_element_modulus_store_byte
    LDA #$C6
    JSR .field_element_modulus_store_byte
    LDA #$5C
    JSR .field_element_modulus_store_byte
    LDA #$78
    JSR .field_element_modulus_store_byte
    LDA #$31
    JSR .field_element_modulus_store_byte
    LDA #$58
    JSR .field_element_modulus_store_byte
    LDA #$AE
    JSR .field_element_modulus_store_byte
    LDA #$A3
    JSR .field_element_modulus_store_byte
    LDA #$FD
    JSR .field_element_modulus_store_byte
    LDA #$C1
    JSR .field_element_modulus_store_byte
    LDA #$76
    JSR .field_element_modulus_store_byte
    LDA #$7A
    JSR .field_element_modulus_store_byte
    LDA #$E2
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    JSR .field_element_modulus_store_byte
    LDA #$FF
    RTS

;; Takes a 112-byte (434-bit) hexademical string and stores it as a field element at #FE_LOADED.
field_element_from_string:
    NOP

;; Add two field elements, C = A + B (mod 2*P434_PRIME-1)
;;
;; Inputs
;;  - A, B in [0, 2*P434_PRIME-1]
;;
;; Outputs
;;  - C in [0, 2*P434_PRIME-1]
!macro field_element_add .A, .B, ~.C {
	LDA #$00                    ; Zero the carry
    STA FE_ADD_CARRY

    !for .i, 0, FE_WORDS-1 {    ; Add the field elements
	    LDX .i
        +ct_adc FE_ADD_CARRY (.A,X) (.B,X) FE_ADD_CARRY (.C,X) FE_ADD_TMP1
    }

	LDA #$00                    ; Zero the carry again
    STA FE_ADD_CARRY

	!for .i, 0, FE_WORDS-1 {    ; Subtract any overflow
	    LDX .i
        +ct_sbc FE_ADD_CARRY (.C,X) (P434_PRIME_2,X) FE_ADD_CARRY (.C,X) FE_ADD_TMP1 FE_ADD_TMP2
    }

    LDA #$00
    SUB FE_ADD_CARRY
	STA MASK                    ; MASK = 0x00 - carry
	LDA #$00
    STA FE_ADD_CARRY            ; Zero the carry again
	
    !for .i, 0, FE_WORDS-1 {    ; Conditionally add the overflow back in
        LDX .i
	    LDA (P434_PRIME_2,X)
        AND MASK                ; 2*P434_PRIME & MASK
	    +ct_adc FE_ADD_CARRY (.C,X) A FE_ADD_CARRY (.C,X) FE_ADD_TMP1
    }
}

;; Subtract two field elements, C = A - B (mod 2*P434_PRIME-1)
;;
;; Inputs
;;  - A, B in [0, 2*P434_PRIME-1]
;;
;; Outputs
;;  - C in [0, 2*P434_PRIME-1]
!macro field_element_sub .A, .B, ~.C {
    LDA #$00                    ; Zero the borrow
    STA FE_SUB_BORROW

    !for .i, 0, FE_WORDS-1 {    ; Do the subtraction
	    LDX .i
        +ct_sbc FE_SUB_BORROW (.A,X) (.B,X) FE_SUB_BORROW (.C,X) FE_ADD_TMP1 FE_ADD_TMP2
	    ;; XXX It's prooobably okay to reuse those tmps, right?
    }
	
	LDA #$00
	SUB FE_SUB_BORROW
    STA MASK                    ; MASK = 0x00 - carry
	LDA #$00
    STA FE_SUB_CARRY            ; Zero the borrow again
	
    !for .i, 0, FE_WORDS-1 {
	    LDX .i
	    LDA (P434_PRIME_2,X)
        AND MASK                ; 2*P434_PRIME & MASK
        +ct_adc FE_SUB_BORROW (.C,X) A FE_SUB_BORROW (.C,X)
    }
}
	
!macro field_element_mul .A, .B, ~.C {
	LDX #$00                    ; i = 0
    LDY #$00                    ; j = 0

.j:
    
}
