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
    STA FE_SUB_BORROW           ; Zero the borrow again

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
;;
;; Nota bene this is not a *full* reduction modulo the group order (i.e. P434_PRIME) but
;; rather modulo the Montgomery modulus (R = 2^448), s.t. .B = .A/R (mod 2*P434_PRIME).
;; The result, .B, will be in the range [0, 2*P434_PRIME-1] if the input, .A, is s.t.
;; .A < 2^448 * P434_PRIME, and .A is also assumed to be in Montgomery representation.
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
!macro field_element_cpy .A ~.B {
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

;; "Double" subtraction for elements in GF(p434).
!macro field_element_dsb {
    NOP
}

;; Compute .B = .A^(p434 - 3)/4 using Montgomery arithmetic.
;;
;; Caveat emptor: this takes 422 multiplications and a similar number of reductions.
;; Don't do this, if at all possible.
!macro field_element_pow34 .A, ~.B {
    ;; Precompute multiplication tables
	+field_element_sqr .A FE_INV_TMP1                               ; tmp1  = a^2
    +field_element_mul .A FE_INV_TMP1 FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE0   ; t0  = a^3
    +field_element_mul FE_INV_TABLE0  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE1   ; t1  = a^5
    +field_element_mul FE_INV_TABLE1  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE2   ; t2  = a^7
    +field_element_mul FE_INV_TABLE2  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE3   ; t3  = a^9
    +field_element_mul FE_INV_TABLE3  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE5   ; t5  = a^13
    +field_element_mul FE_INV_TABLE5  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE6   ; t6  = a^15
    +field_element_mul FE_INV_TABLE6  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE7   ; t7  = a^17
    +field_element_mul FE_INV_TABLE7  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE9   ; t9  = a^21
    +field_element_mul FE_INV_TABLE9  FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE10  ; t10 = a^23
    +field_element_mul FE_INV_TABLE10 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE12  ; t12 = a^27
    +field_element_mul FE_INV_TABLE12 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE13  ; t13 = a^29
    +field_element_mul FE_INV_TABLE13 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE14  ; t14 = a^31
    +field_element_mul FE_INV_TABLE14 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE15  ; t15 = a^33
    +field_element_mul FE_INV_TABLE15 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE16  ; t16 = a^35
    +field_element_mul FE_INV_TABLE16 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE19  ; t19 = a^41
    +field_element_mul FE_INV_TABLE19 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE20  ; t20 = a^43
    +field_element_mul FE_INV_TABLE20 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE21  ; t21 = a^45
    +field_element_mul FE_INV_TABLE21 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE22  ; t22 = a^47
    +field_element_mul FE_INV_TABLE22 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE23  ; t23 = a^49
    +field_element_mul FE_INV_TABLE23 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE24  ; t24 = a^51
    +field_element_mul FE_INV_TABLE24 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE25  ; t25 = a^53
    +field_element_mul FE_INV_TABLE25 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE26  ; t26 = a^55
    +field_element_mul FE_INV_TABLE26 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE28  ; t28 = a^59
    +field_element_mul FE_INV_TABLE28 FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TMP3
    +field_element_mul FE_INV_TMP3    FE_INV_TMP1   FE_INV_TMP2
	+field_element_rdc                FE_INV_TMP2   FE_INV_TABLE30  ; t30 = a^63

	+field_element_cpy .A FE_INV_TMP1                             ; tmp1 = a
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ; tmp2 = a^2
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ; tmp1 = a^4
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ; tmp2 = a^8
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ; tmp1 = a^16
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ; tmp2 = a^32
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ; ...  = a^64
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^128

	+field_element_mul FE_INV_TABLE5  FE_INV_TMP2 FE_INV_TMP1     ;*a^13 = a^141
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^141 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^282
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^564
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^1128
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^2256
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^4512
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^9024
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^18048
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^36096
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^72192
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^144384

	+field_element_mul FE_INV_TABLE14 FE_INV_TMP2 FE_INV_TMP1     ;*a^31 = a^144415
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^144415 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^288830
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^577660
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^1155320
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^2310640
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^4621280
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^9242560

	+field_element_mul FE_INV_TABLE3  FE_INV_TMP2 FE_INV_TMP1     ;*a^9  = a^9242569
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^9242569 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^18485138
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^36970276
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^73940552
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^147881104
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^295762208
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^591524416

	+field_element_mul FE_INV_TABLE23 FE_INV_TMP2 FE_INV_TMP1     ;*a^49 = a^591524465
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^591524465 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^1183048930
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^2366097860
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^4732195720
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^9464391440
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^18928782880
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^37857565760

	+field_element_mul FE_INV_TABLE13 FE_INV_TMP2 FE_INV_TMP1     ;*a^29 = a^37857565789
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^37857565789 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^75715131578
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^151430263156
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^302860526312
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^605721052624
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^1211442105248
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^2422884210496

	+field_element_mul FE_INV_TABLE24 FE_INV_TMP2 FE_INV_TMP1     ;*a^51 = a^2422884210547
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^2422884210547 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^4845768421094
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^9691536842188
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^19383073684376
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^38766147368752
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^77532294737504
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^155064589475008

	+field_element_mul FE_INV_TABLE7  FE_INV_TMP2 FE_INV_TMP1     ;*a^17 = a^155064589475025
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^155064589475025 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^310129178950050
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^620258357900100
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1240516715800200
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2481033431600400
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^4962066863200800
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^9924133726401600
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^19848267452803200
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^39696534905606400

	+field_element_mul FE_INV_TABLE12 FE_INV_TMP1 FE_INV_TMP2     ;*a^27 = a^39696534905606427
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^39696534905606427 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^79393069811212854
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^158786139622425708
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^317572279244851416
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^635144558489702832
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1270289116979405664
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2540578233958811328
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5081156467917622656
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^10162312935835245312

	+field_element_mul FE_INV_TABLE30 FE_INV_TMP1 FE_INV_TMP2     ;*a^63 = a^10162312935835245375
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^10162312935835245375 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^20324625871670490750
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^40649251743340981500
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^81298503486681963000
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^162597006973363926000
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^325194013946727852000
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^650388027893455704000

	+field_element_mul FE_INV_TABLE1  FE_INV_TMP1 FE_INV_TMP2     ;*a^5  = a^650388027893455704005
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^650388027893455704005 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1300776055786911408010
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2601552111573822816020
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5203104223147645632040
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^10406208446295291264080
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^20812416892590582528160
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^41624833785181165056320

	+field_element_mul FE_INV_TABLE30 FE_INV_TMP1 FE_INV_TMP2     ;*a^63 = a^41624833785181165056383
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^41624833785181165056383 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^83249667570362330112766
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^166499335140724660225532
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^332998670281449320451064
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^665997340562898640902128
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1331994681125797281804256
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2663989362251594563608512
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5327978724503189127217024

	+field_element_mul FE_INV_TABLE21 FE_INV_TMP2 FE_INV_TMP1     ;*a^45 = a^5327978724503189127217069
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^5327978724503189127217069 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^10655957449006378254434138
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^21311914898012756508868276
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^42623829796025513017736552
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^85247659592051026035473104
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^170495319184102052070946208
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^340990638368204104141892416
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^681981276736408208283784832
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1363962553472816416567569664
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2727925106945632833135139328

	+field_element_mul FE_INV_TABLE2  FE_INV_TMP1 FE_INV_TMP2     ;*a^7  = a^2727925106945632833135139335
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^2727925106945632833135139335 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5455850213891265666270278670
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^10911700427782531332540557340
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^21823400855565062665081114680
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^43646801711130125330162229360
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^87293603422260250660324458720
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^174587206844520501320648917440
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^349174413689041002641297834880
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^698348827378082005282595669760
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1396697654756164010565191339520

	+field_element_mul FE_INV_TABLE19 FE_INV_TMP2 FE_INV_TMP1     ;*a^41 = a^1396697654756164010565191339561
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^1396697654756164010565191339561 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2793395309512328021130382679122
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5586790619024656042260765358244
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^11173581238049312084521530716488
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^22347162476098624169043061432976
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^44694324952197248338086122865952
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^89388649904394496676172245731904
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^178777299808788993352344491463808
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^357554599617577986704688982927616
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^715109199235155973409377965855232

	+field_element_mul FE_INV_TABLE1  FE_INV_TMP1 FE_INV_TMP2     ;*a^5  = a^715109199235155973409377965855237
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^715109199235155973409377965855237 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1430218398470311946818755931710474
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2860436796940623893637511863420948
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5720873593881247787275023726841896
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^11441747187762495574550047453683792
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^22883494375524991149100094907367584
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^45766988751049982298200189814735168
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^91533977502099964596400379629470336

	+field_element_mul FE_INV_TABLE24 FE_INV_TMP2 FE_INV_TMP1     ;*a^51 = a^91533977502099964596400379629470387
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^91533977502099964596400379629470387 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^183067955004199929192800759258940774
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^366135910008399858385601518517881548
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^732271820016799716771203037035763096
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1464543640033599433542406074071526192
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2929087280067198867084812148143052384
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5858174560134397734169624296286104768

	+field_element_mul FE_INV_TABLE26 FE_INV_TMP2 FE_INV_TMP1     ;*a^55 = a^5858174560134397734169624296286104823
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^5858174560134397734169624296286104823 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^11716349120268795468339248592572209646
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^23432698240537590936678497185144419292
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^46865396481075181873356994370288838584
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^93730792962150363746713988740577677168
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^187461585924300727493427977481155354336
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^374923171848601454986855954962310708672

	+field_element_mul FE_INV_TABLE16 FE_INV_TMP2 FE_INV_TMP1     ;*a^35 = a^374923171848601454986855954962310708707
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^374923171848601454986855954962310708707 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^749846343697202909973711909924621417414
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1499692687394405819947423819849242834828
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^2999385374788811639894847639698485669656
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^5998770749577623279789695279396971339312
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^11997541499155246559579390558793942678624
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^23995082998310493119158781117587885357248
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^47990165996620986238317562235175770714496

	+field_element_mul FE_INV_TABLE10 FE_INV_TMP1 FE_INV_TMP2     ;*a^23 = a^47990165996620986238317562235175770714519
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^47990165996620986238317562235175770714519 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^95980331993241972476635124470351541429038
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^191960663986483944953270248940703082858076
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^383921327972967889906540497881406165716152
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^767842655945935779813080995762812331432304
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1535685311891871559626161991525624662864608
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3071370623783743119252323983051249325729216
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6142741247567486238504647966102498651458432

	+field_element_mul FE_INV_TABLE6  FE_INV_TMP2 FE_INV_TMP1     ;*a^15 = a^6142741247567486238504647966102498651458447
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^6142741247567486238504647966102498651458447 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^12285482495134972477009295932204997302916894
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^24570964990269944954018591864409994605833788
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^49141929980539889908037183728819989211667576
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^98283859961079779816074367457639978423335152
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^196567719922159559632148734915279956846670304
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^393135439844319119264297469830559913693340608
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^786270879688638238528594939661119827386681216

	+field_element_mul FE_INV_TABLE0  FE_INV_TMP1 FE_INV_TMP2     ;*a^3  = a^786270879688638238528594939661119827386681219
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^786270879688638238528594939661119827386681219 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1572541759377276477057189879322239654773362438
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3145083518754552954114379758644479309546724876
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6290167037509105908228759517288958619093449752
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^12580334075018211816457519034577917238186899504
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^25160668150036423632915038069155834476373799008
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^50321336300072847265830076138311668952747598016
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^100642672600145694531660152276623337905495196032
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^201285345200291389063320304553246675810990392064
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^402570690400582778126640609106493351621980784128

	+field_element_mul FE_INV_TABLE20 FE_INV_TMP2 FE_INV_TMP1     ;*a^43 = a^402570690400582778126640609106493351621980784171
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^402570690400582778126640609106493351621980784171 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^805141380801165556253281218212986703243961568342
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1610282761602331112506562436425973406487923136684
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3220565523204662225013124872851946812975846273368
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6441131046409324450026249745703893625951692546736
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^12882262092818648900052499491407787251903385093472
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^25764524185637297800104998982815574503806770186944
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^51529048371274595600209997965631149007613540373888
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^103058096742549191200419995931262298015227080747776

	+field_element_mul FE_INV_TABLE9  FE_INV_TMP2 FE_INV_TMP1     ;*a^21 = a^103058096742549191200419995931262298015227080747797
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^103058096742549191200419995931262298015227080747797 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^206116193485098382400839991862524596030454161495594
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^412232386970196764801679983725049192060908322991188
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^824464773940393529603359967450098384121816645982376
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1648929547880787059206719934900196768243633291964752
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3297859095761574118413439869800393536487266583929504
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6595718191523148236826879739600787072974533167859008

	+field_element_mul FE_INV_TABLE25 FE_INV_TMP2 FE_INV_TMP1     ;*a^53 = a^6595718191523148236826879739600787072974533167859061
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^6595718191523148236826879739600787072974533167859061 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^13191436383046296473653759479201574145949066335718122
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^26382872766092592947307518958403148291898132671436244
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^52765745532185185894615037916806296583796265342872488
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^105531491064370371789230075833612593167592530685744976
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^211062982128740743578460151667225186335185061371489952
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^422125964257481487156920303334450372670370122742979904
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^844251928514962974313840606668900745340740245485959808
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1688503857029925948627681213337801490681480490971919616
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3377007714059851897255362426675602981362960981943839232

	+field_element_mul FE_INV_TABLE30 FE_INV_TMP1 FE_INV_TMP2     ;*a^63 = a^3377007714059851897255362426675602981362960981943839295
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^3377007714059851897255362426675602981362960981943839295 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6754015428119703794510724853351205962725921963887678590
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^13508030856239407589021449706702411925451843927775357180
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^27016061712478815178042899413404823850903687855550714360
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^54032123424957630356085798826809647701807375711101428720
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^108064246849915260712171597653619295403614751422202857440
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^216128493699830521424343195307238590807229502844405714880

	+field_element_mul FE_INV_TABLE26 FE_INV_TMP1 FE_INV_TMP2     ;*a^55 = a^216128493699830521424343195307238590807229502844405714935
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^216128493699830521424343195307238590807229502844405714935 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^432256987399661042848686390614477181614459005688811429870
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^864513974799322085697372781228954363228918011377622859740
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1729027949598644171394745562457908726457836022755245719480
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3458055899197288342789491124915817452915672045510491438960
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^6916111798394576685578982249831634905831344091020982877920
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^13832223596789153371157964499663269811662688182041965755840

	+field_element_mul .A             FE_INV_TMP1 FE_INV_TMP2     ;*a^1  = a^13832223596789153371157964499663269811662688182041965755841
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^13832223596789153371157964499663269811662688182041965755841 (mod p434)

	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^27664447193578306742315928999326539623325376364083931511682
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^55328894387156613484631857998653079246650752728167863023364
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^110657788774313226969263715997306158493301505456335726046728
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^221315577548626453938527431994612316986603010912671452093456
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^442631155097252907877054863989224633973206021825342904186912
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^885262310194505815754109727978449267946412043650685808373824
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1770524620389011631508219455956898535892824087301371616747648

	+field_element_mul FE_INV_TABLE28 FE_INV_TMP2 FE_INV_TMP1     ;*a^59 = a^1770524620389011631508219455956898535892824087301371616747707
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^1770524620389011631508219455956898535892824087301371616747707 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3541049240778023263016438911913797071785648174602743233495414
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^7082098481556046526032877823827594143571296349205486466990828
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^14164196963112093052065755647655188287142592698410972933981656
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^28328393926224186104131511295310376574285185396821945867963312
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^56656787852448372208263022590620753148570370793643891735926624
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^113313575704896744416526045181241506297140741587287783471853248

	+field_element_mul FE_INV_TABLE6  FE_INV_TMP2 FE_INV_TMP1     ;*a^15 = a^113313575704896744416526045181241506297140741587287783471853254
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^113313575704896744416526045181241506297140741587287783471853254 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^226627151409793488833052090362483012594281483174575566943706508
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^453254302819586977666104180724966025188562966349151133887413016
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^906508605639173955332208361449932050377125932698302267774826032
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1813017211278347910664416722899864100754251865396604535549652064
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3626034422556695821328833445799728201508503730793209071099304128
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^7252068845113391642657666891599456403017007461586418142198608256

	+field_element_mul FE_INV_TABLE10 FE_INV_TMP2 FE_INV_TMP1     ;*a^23 = a^7252068845113391642657666891599456403017007461586418142198608279
	+field_element_rdc                FE_INV_TMP1 FE_INV_TMP2     ;      = a^7252068845113391642657666891599456403017007461586418142198608279 (mod p434)

	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^14504137690226783285315333783198912806034014923172836284397216558
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^29008275380453566570630667566397825612068029846345672568794433116
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^58016550760907133141261335132795651224136059692691345137588866232
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^116033101521814266282522670265591302448272119385382690275177732464
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^232066203043628532565045340531182604896544238770765380550355464928
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^464132406087257065130090681062365209793088477541530761100710929856
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^928264812174514130260181362124730419586176955083061522201421859712
	+field_element_sqr FE_INV_TMP1 FE_INV_TMP2                    ;      = a^1856529624349028260520362724249460839172353910166123044402843719424
	+field_element_sqr FE_INV_TMP2 FE_INV_TMP1                    ;      = a^3713059248698056521040725448498921678344707820332246088805687438848

	+field_element_mul FE_INV_TABLE22 FE_INV_TMP1 FE_INV_TMP2     ;*a^47 = a^3713059248698056521040725448498921678344707820332246088805687438895
	+field_element_rdc                FE_INV_TMP2 FE_INV_TMP1     ;      = a^3713059248698056521040725448498921678344707820332246088805687438895 (mod p434)

	!for .i, 0, 34 {
        !for .j, 0, 5 {
	        +field_element_sqr FE_INV_TMP1 FE_INV_TMP2            ; 35*6 = 210 additional squarings
	        +field_element_sqr FE_INV_TMP2 FE_INV_TMP1            ; 35*1 =  35 additional multiplications
	        +field_element_sqr FE_INV_TMP1 FE_INV_TMP2            ;
	        +field_element_sqr FE_INV_TMP2 FE_INV_TMP1            ;
	        +field_element_sqr FE_INV_TMP1 FE_INV_TMP2            ;
	        +field_element_sqr FE_INV_TMP2 FE_INV_TMP1            ;
        }
        +field_element_mul FE_INV_TABLE30 FE_INV_TMP1 FE_INV_TMP2 ;*a^63
        +field_element_rdc                FE_INV_TMP2 FE_INV_TMP1 ;       (mod p434)
        ;; = a^6109855915336305387977286252864373404771445060940399127831451834051305309832994181492554167957154611474679756673221234835578683391
        ;; = a^{(24439423661345221551909145011457493619085780243761596511325807336205221239331976725970216671828618445898719026692884939342314733567 - 3)/4}
    }
    ;; big numnum, smol compute
}

;; Field element inversion in GF(p434), .B = R/.A (mod p434).
;;
!macro field_element_inv .A, ~.B {
    +field_element_cpy   .A FE_INV_TMP4
    +field_element_pow34 FE_INV_TMP4 .B                           ; b = a^{(p434-3)/4}
    +field_element_sqr   .B FE_INV_TMP4                           ;
    +field_element_sqr   FE_INV_TMP4 .B                           ; b = a^(p434-3)
    +field_element_mul   .A .B FE_INV_TMP4
    +field_element_rdc   FE_INV_TMP4 .B
}

test_field_element_mul:

