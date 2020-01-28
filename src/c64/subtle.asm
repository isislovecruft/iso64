;; -*- mode: asm -*-
;;
;; This file is part of a Supersingular Isogeny Key Encapsulation (SIKE) over P434 for Commodore 64.
;; Copyright (c) 2020 isis lovecruft
;; See LICENSE for licensing information.
;;
;; Authors:
;; - isis agora lovecruft <isis@patternsinthevoid.net>

;; Constant time utilities.

!cpu 6510                       ; For 6502/6510 with undocumented opcodes
!zone subtle                    ; Namespacing

;; Returns .c = 0xff iff a < b and 0x00 otherwise.
!macro ct_lt .a, .b, ~.c {
    LDA .a                      ; a
    SUB .b                      ; a-b
    EOR .a                      ; (a-b)^a
    STA .c                      ; c = (a-b)^a
    LDA .a                      ; a
    EOR .b                      ; a^b
    ORA .c                      ; (a^b)|((a-b)^a)
    EOR .a                      ; a^((a^b)|((a-b)^a))
    ROR #$07                    ; (a^((a^b)|((a-b)^a))) >> 7
    STA .c                      ; c = (a^((a^b)|((a-b)^a))) >> 7
    LDA #$00                    ; 0x00
    SUB .c                      ; 0x00 - ((a^((a^b)|((a-b)^a))) >> 7)
    STA .c                      ; c = 0x00 - ((a^((a^b)|((a-b)^a))) >> 7)
}

;; Returns .c = 0xff if a == 0 and 0x00 otherwise.
!macro ct_is_zero .a, ~.c {
    LDA .a
    EOR #$FF                    ; Bitwise-NOT .a to contain its two's-complement
    TAX
    LDA .a
    SUB #$01                    ; a - 1
    AND X                       ; ~a & (a -1)
    STA .c                      ; c = ~a & (a -1)
    LDA #$00                    ; 0x00
    SUB .c                      ; 0x00 - (~a & (a -1))
    STA .c                      ; c = 0x00 - (~a & (a -1))
}

;; Constant-time conditional selection. If c = 0, set r = a, otherwise if c = 1, set r = b.
!macro ct_select .a, .b, .c, ~.r {
    LDA #$00                    ; 0x00 - { 0, => MASK = 00000000 (0)   if c=0 and
    SUB .c                      ;        { 1, => MASK = 11111111 (-1)  if c=1
    STA MASK
    LDA .a
    EOR .b                      ; a^b
    AND MASK                    ; MASK&(a^b)
    EOR .a                      ; a^(MASK&(a^b))
    STA .r
}

;; Constant-time conditional assignment. If c = 0, a remains unchanged, otherwise if c = 1, then a = b.
!macro ct_assign ~.a, .b, .c {
    +ct_select .a, .b, .c, .a
}

;; Constant-time conditional swap. If c = 0, a and b remain unchanged. If c = 1, a and b are swapped.
!macro ct_swap ~.a, ~.b, .c {
    LDA .a
    PHA                         ; Push the tmp variable to the stack
    +ct_assign .a, .b, .c
    PLA                         ; Pull it back out into the accumulator
    +ct_assign .b, A, .c
}

;; 8-bit subtraction with carry in constant time.
!macro ct_sbc .borrowin, .minuend, .subtrahend, ~.borrowout, ~.differenceout, ~.tmp1, ~.tmp2 {
    LDA .minuend
    SBC .subtrahend             ; XXX should this be SUB instead since we're manually handling the borrow?
    STA .tmp1                   ; tmp1 = minuend - subtrahend
    +ct_lt .minuend .subtrahend MASK
    LDA MASK
    ;; XXX can save four instructions here if we modify the macro to not do (0 - (a >> 7)) at the end
    ROR #$07                    ; MASK is 1 iff minuend < subtrahend, 0 otherwise
    STA MASK
    +ct_is_zero .tmp1 .tmp2     ; tmp2 = 0xFF iff (minuend - subtrahend) == 0
    LDA .borrowin
    AND .tmp2
    STA .tmp2                   ; tmp2 = borrowin & ct_is_zero(minuend - subtrahend)
    LDA MASK
    ORA .tmp2
    STA .borrowout
    LDA .tmp1
    SUB .borrowin
    STA .differenceout
}

;; 8-bit addition with carry in constant time.
!macro ct_adc .carryin, .addend1, .addend2, ~.carryout, ~.sumout, ~.tmp1 {
    CLC
    LDA .addend1
    ADC .carryin                ; XXX should this be ADD instead since we're manually handling the carry?
    STA .tmp1                   ; tmp1 = addend1 + carryin
    LDA .addend2
    ADC .tmp1
    STA .sumout                 ; sumout = addend2 + addend1 + carryin
    +ct_lt .tmp1 .carryin MASK
    LDA MASK
    +ct_lt .sumout .tmp1 MASK
    ORA MASK                    ; carryout = ((tmp1 < carryin) | (sumout < tmp1)) >> 7
    ROR #$07
    STA .carryout
}
