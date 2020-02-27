;; -*- mode: asm -*-
;;
;; This file is part of a Supersingular Isogeny Key Encapsulation (SIKE) over P434 for Commodore 64.
;; Copyright (c) 2020 isis lovecruft
;; See LICENSE for licensing information.
;;
;; Authors:
;; - isis agora lovecruft <isis@patternsinthevoid.net>
	
;; Arithmetic for elements in GF(p434^2).
;;
;; Elements (x + yi) over DF(p434^2) consist of two coefficients, x and y, from GF(p434).
	
;; GF(p434^2) squaring via Montgomery arithmetic, .B = .A^2.
!macro field_element_2_sqr .A0, A1, ~.B0, ~.B1 {
    +field_element_add .A0 .A1 FE2_SQR_TMP1                   ; t1 = a0 + a1
    +field_element_sub .A0 .A1 FE2_SQR_TMP2                   ; t2 = a0 - a1
    +field_element_mul FE2_SQR_TMP1 FE2_SQR_TMP2 FE2_SQR_TMP3 ; t3 = (a0+a1)(a0-a1)
    +field_element_rdc FE2_SQR_TMP3 .B0                       ; b0 = (a0+a1)(a0-a1)(R^-1) (mod P434)
    +field_element_add .A0 .A0 FE2_SQR_TMP1                   ; t1 = 2  * a0
    +field_element_mul FE2_SQR_TMP1 .A1 FE2_SQR_TMP2          ; t2 = (2a0)(a1)
    +field_element_rdc FE2_SQR_TMP2 .B1                       ; b1 = (2a0)(a1)(R^-1) (mod P434)
}
	
;; GF(p434^2) multiplication via Montgomery arithmetic, .C = .A * .B.
;;
;; .A = .A0+.A1*i and .B = .B0+.B1*i where .A0, .A1, .B0, .B1 are all in [0, 2*P434_PRIME-1].
!macro field_element_2_mul .A0, .A1, .B0, .B1, ~.C0, ~.C1 {
    +field_element_add .A0 .A1 FE2_MUL_TMP1                   ; t1 = a0 + a1
    +field_element_add .B0 .B1 FE2_MUL_TMP2                   ; t2 = b0 + b1
    +field_element_mul .A0 .B0 FE2_MUL_TMP3                   ; t3 = a0 * b0
    +field_element_mul .A1 .B1 FE2_MUL_TMP4                   ; t4 = a1 * b1
    +field_element_mul FE2_MUL_TMP1 FE2_MUL_TMP2 FE2_MUL_TMP5 ; t5 = (a0+a1)(b0+b1)
    +field_element_dsb FE2_MUL_TMP3 FE2_MUL_TMP4 FE2_MUL_TMP5 ; t5 = (a0+a1)(b0+b1) - a0*b0 - a1*b1
    +field_element_sub FE2_MUL_TMP3 FE2_MUL_TMP4 FE2_MUL_TMP3 ; t3 = a0*b0 - a1*b1
	
    ;; If a0*b0 < 0 then FE_SUB_BORROW is 0xFF, elif >= 0 then FE_SUB_BORROW is 0x00, which we use as a mask.
    !for .i, 0, FE_WORDS {
        LDX .i
        LDA (P434_PRIME,X)
        AND FE_SUB_BORROW
        STA (FE2_MUL_TMP1,X)
    }
    +field_element_rdc FE2_MUL_TMP5 .C1                       ; c1 = (a0+a1)(b0+b1) - a0*b0 - a1*b1 (mod p434)
    +field_element_add FE2_MUL_TMP3 FE2_MUL_TMP1 FE_MUL_TMP2  ; t2 = a0*b0 - a1*b1 + (P434 & mask)
    +field_element_rdc FE2_MUL_TMP2 .C0                       ; c0 = a0*b0 - a1*b1 + (P434 & mask) (mod p434)
}
	
;; GF(p434^2) element inversion via Montgomery arithmetic, .B = (.A0-.A1*i)/(.A0^2+.A1^2).
!macro field_element_2_inv .A0, .A1, ~.B0, ~.B1 {
    +field_element_sqr .A0 FE2_INV_TMP1                       ; t1 = a0^2
    +field_element_sqr .A1 FE2_INV_TMP2                       ; t2 = a1^2
    +field_element_add FE2_INV_TMP1 FE2_INV_TMP2 FE2_INV_TMP3 ; t3 = a0^2 + a1^2
    +field_element_inv FE2_INV_TMP3 FE2_INV_TMP2              ; t2 = 1/(a0^2 + a1^2)
    +field_element_neg .A1 FE2_INV_TMP3                       ; t3 = 1/a = a0-a1*i
    +field_element_mul .A0 FE2_INV_TMP2 FE2_INV_TMP1          ; t1 = a0/(a0^2+a1^2)
    +field_element_rdc FE2_INV_TMP1 .B0                       ; b0 = a0/(a0^2+a1^2) (mod p434)
    +field_element_mul FE2_INV_TMP3 FE2_INV_TMP2 FE2_INV_TMP1 ; t1 = (a0-a1*i)/(a0^2+a1^2)
    +field_element_rdc FE2_INV_TMP1 .B1                       ; b1 = (a0-a1*i)/(a0^2+a1^2) (mod p434)
}
