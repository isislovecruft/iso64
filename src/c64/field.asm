    ;; XXX copyright and licence go here
	
    ;; Arithmetic in a finite field of prime order.

	;; Written for the ACME Cross-Assembler
	;; 
    ;; Build with -Wtype-mismatch to catch mismatches between addrs and immediates.

!cpu 6510 	                    ; For 6502/6510 with undocumented opcodes
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

!addr MASK = $cfff              ; XXX move to constants.asm

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

!addr FE_ADD_TMP = $cff9        ; XXX move to constants.asm
!addr FE_ADD_CARRYOUT = $cffa
!addr FE_ADD_CARRYIN = $cffb
!addr FE_ADD_A_BYTE = $cffc
!addr FE_ADD_B_BYTE = $cffd
!addr FE_ADD_C_BYTE = $cffe

;; Add two field elements, C = A + B (mod P434_PRIME)
!macro field_element_add .A, .B, .C {
    !for i, 0, FE_WORDS / 2 {
	    STA (.C,i)
        LDA FE_ADD_C_BYTE
        STA (.B,i)
        LDA FE_ADD_B_BYTE
        STA (.A,i)
        LDA FE_ADD_A_BYTE
	    STA #$00                ; Zero the carries
        LDA FE_ADD_CARRYIN
        STA #$00
        LDA FE_ADD_CARRYOUT
        +ct_adc FE_ADD_CARRYIN FE_ADD_A_BYTE FE_ADD_B_BYTE FE_ADD_CARRYOUT FE_ADD_C_BYTE FE_ADD_TMP
        ;; XXX Probably I did not need to do this in constant time since we're
        ;;     always swapping, but fuck it, I have a constant time hammer.
        +ct_swap FE_ADD_CARRYIN FE_ADD_CARRYOUT #$01
    }
}
	
;; Subtract two field elements.
field_element_sub:
    NOP
