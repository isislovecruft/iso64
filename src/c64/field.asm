	;; XXX copyright and licence go here
	
    ;; Arithmetic in a finite field of prime order.

	;; Written for the ACME Cross-Assembler
	;; 
    ;; Build with -Wtype-mismatch to catch mismatches between addrs and immediates.

!cpu 6510 	                    ; For 6502/6510 with undocumented opcodes
    ;; !to "field.o", plain            ; Direct the assembler to output to this file
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

;; Add two field elements.
field_element_add:
    NOP
	
;; Subtract two field elements.
field_element_sub:
    NOP
