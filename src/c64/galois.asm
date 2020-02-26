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
