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

;; Multiply two field elements .A and .B into .C = .A * .B, unreduced modulo the prime.
;;
;; The bitlength of .A and .B should be FE_WORDS times the size of a
;; word (8-bits, obviously).
;;
;; We assume that we have at least 2 * FE_WORDS - 1 words in .C.
!macro field_element_mul .A, .B, ~.C {
	LDA #0
    STA FE_MUL_CARRY            ; Zero the carry

	!for .i, 0, FE_WORDS-1 {
        !for .j, 0, .i {
	        LDA .i              ; XXX do these need to be #.i, etc.?
            SBC .j
	        TAX                 ; X = i-j
	        LDY .j              ; Y = j
            +ct_mul (.A,Y) (.B,X) FE_MUL_RESULT+1 FE_MUL_RESULT
	        +ct_adc #0           FE_MUL_RESULT   FE_MUL_V FE_MUL_CARRY FE_MUL_V FE_MUL_TMP
	        +ct_adc FE_MUL_CARRY FE_MUL_RESULT+1 FE_MUL_U FE_MUL_CARRY FE_MUL_U FE_MUL_TMP
	        LDA FE_MUL_T        ; T = T + carry
	        CLC
            ADC FE_MUL_CARRY
        }
	    LDX .i
	    LDA FE_MUL_V
        STA .c,X                ; C[i] = V
	    LDA FE_MUL_U
        STA FE_MUL_V            ; V = U
	    LDA FE_MUL_T
        STA FE_MUL_U            ; U = T
        LDA #0
        STA FE_MUL_T            ; T = 0
    }

	!for .i, 0, 2*FE_WORDS-1 {
        !for .j, .i-FE_WORDS+1, FE_WORDS {
	        LDA .i
            SBC .j
	        TAX                 ; X = i-j
	        LDY .j              ; Y = j
            +ct_mul (.A,Y) (.B,X) FE_MUL_RESULT+1 FE_MUL_RESULT
            +ct_mul (.A,Y) (.B,X) FE_MUL_RESULT+1 FE_MUL_RESULT
	        +ct_adc FE_MUL_CARRY FE_MUL_RESULT   FE_MUL_V FE_MUL_CARRY FE_MUL_V FE_MUL_TMP
	        +ct_adc FE_MUL_CARRY FE_MUL_RESULT+1 FE_MUL_U FE_MUL_CARRY FE_MUL_U FE_MUL_TMP
	        LDA FE_MUL_T        ; T = T + carry
	        CLC
            ADC FE_MUL_CARRY
        }
	    LDX .i
	    LDA FE_MUL_V
        STA .c,X                ; C[i] = V
	    LDA FE_MUL_U
        STA FE_MUL_V            ; V = U
	    LDA FE_MUL_T
        STA FE_MUL_U            ; U = T
        LDA #0
        STA FE_MUL_T            ; T = 0
    }

	LDX #2*FE_WORDS-1
    LDA FE_MUL_V
    STA .c,X                    ; C[2*FE_WORDS-1] = V
}

;; Montgomery reduce a field element .A by the P434 prime modulus and store it in .B.
!macro field_element_rdc .A ~.B {
	LDA #0
    STA FE_RDC_CARRY            ; Zero the carry

	;; COUNT = ZERO_WORDS, i.e. the number of least significant words in
	;; P434_PRIME_PLUS_1 which are 0.
    LDA ZERO_WORDS
	STA FE_RDC_COUNT

	!for .i, 0, FE_WORDS {      ; Zero out the result
	    LDX .i
	    LDA #0
        STA (.B,X)
    }

	;; Multiply by the P434 prime.
    !for .i, 0, FE_WORDS {
        LDA .i
        SBC ZERO_WORDS
        CLC
        ADC 1
        STA FE_RDC_SKIP    ; FE_RDC_SKIP = .i - ZERO_WORDS + 1
        !for .j, 0, FE_RDC_SKIP {
	        LDA .i
            SBC .j
	        TAX                 ; X = i-j
	        LDY .j              ; Y = j

	        ;; Exploit the structure of the P434 prime, where if we add 1 we get
            ;; a number whose first 192 bits are 0s.
            +ct_mul (.B,Y) (P434_PRIME_PLUS_1,X) FE_RDC_RESULT+1 FE_RDC_RESULT
            +ct_adc #0           FE_RDC_RESULT   FE_RDC_V FE_RDC_CARRY FE_RDC_V FE_RDC_TMP
            +ct_adc FE_RDC_CARRY FE_RDC_RESULT+1 FE_RDC_U FE_RDC_CARRY FE_RDC_U FE_RDC_TMP
            LDA FE_RDC_T        ; T = T + carry
            CLC
            ADC FE_RDC_CARRY
        }
	    LDX .i
	    +ct_adc #0           FE_RDC_V (.A,X) FE_RDC_CARRY FE_RDC_V
        +ct_adc FE_RDC_CARRY FE_RDC_U #0     FE_RDC_CARRY FE_RDC_U
        LDA FE_RDC_T            ; T = T + carry
        CLC
        ADC FE_RDC_CARRY
	    LDX .i
        LDA FE_RDC_V
        STA (.B,X)              ; B[i] = V
	    LDA FE_RDC_U
        STA FE_RDC_V            ; V = U
	    LDA FE_RDC_T
        STA FE_RDC_U            ; U = T
        LDA #0
        STA FE_RDC_T            ; T = 0
    }
	;; Multiply by the 192 0-bits of the modulus
	!for .i, FE_WORDS, 2*FE_WORDS-1 {
	    ;; XXX rewrite the !if to use BEQ on the zero flag
	    !if FE_RDC_COUNT > 0 {
	        LDA FE_RDC_COUNT
            SBC #1
            STA FE_RDC_COUNT
        }
	    !for .j, .i-FE_WORDS+1, FE_WORDS-FE_RDC_COUNT {
	        LDA .i
            SBC .j
	        TAX                 ; X = i-j
	        LDY .j              ; Y = j

            +ct_mul (.B,Y) (P434_PRIME_PLUS_ONE,X) FE_RDC_RESULT+1 FE_RDC_RESULT
	        +ct_adc #0           FE_RDC_RESULT   FE_RDC_V FE_RDC_CARRY FE_RDC_V FE_RDC_TMP
            +ct_adc FE_RDC_CARRY FE_RDC_RESULT+1 FE_RDC_U FE_RDC_CARRY FE_RDC_U FE_RDC_TMP
            LDA FE_RDC_T
            CLC
            ADC FE_RDC_CARRY
        }
	    LDX .i
	    +ct_adc #0           FE_RDC_V (.A,X) FE_RDC_CARRY FE_RDC_V FE_RDC_TMP
        +ct_adc FE_RDC_CARRY FE_RDC_U #0     FE_RDC_CARRY FE_RDC_U FE_RDC_TMP
        LDA FE_RDC_T
        CLC
        ADC FE_RDC_CARRY
	    LDA .i
	    SEC
	    SBC FE_WORDS
	    TAX
        LDA FE_RDC_V
        STA (.B,X)              ; B[i-FE_WORDS] = V
	    LDA FE_RDC_U
        STA FE_RDC_V            ; V = U
	    LDA FE_RDC_T
        STA FE_RDC_U            ; U = T
        LDA #0
        STA FE_RDC_T            ; T = 0
    }
	;; Deal with the final carry flag
	;; 111 = 2 * FE_WORDS - 1
	+ct_adc #0 FE_RDC_V .B+111 FE_RDC_CARRY FE_RDC_V FE_RDC_TMP
	;; 55 = FE_WORDS - 1
    LDX 55
    LDA FE_RDC_V
    STA (.B,X)                  ; B[55] = V
}

	;; XXX Check SBCs we might need to SEC first

;; Square the field element .A and store it in .B.
!macro field_element_sqr .A ~.B {
    +field_element_mul .A .A FE_SQR_TMP
    +field_element_rdc FE_SQR_TMP .B
}

;; Copy the field element .A to .B.
!macro field_element_copy .A ~.B {
    !for .i, 0, FE_WORDS {
        LDX .i
	    LDA (.A,X)
        STA (.B,X)
    }
}

;; Modular negation for the field element .A, computes -.A (mod P434_PRIME)
;; and stores it in .B.
;;
;; A must be in [0, 2*P434_PRIME-1], output is in the same range.
!macro field_element_neg .A ~.B {
    +field_element_sub .A P434_PRIME_2 .B
}

test_field_element_mul:

