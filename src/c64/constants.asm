!cpu 6510
!zone constants 
	
;; Number of words in a field element.
;;
;; 434 bits divided by 8 is 54.25, but we round up to 56 to get a 448-bit
;; element to match existing implementations for 32-bit and 64-bit
;; architectures.  We wouldn't want Commodore 64s to be unable to talk to
;; "modern" CPUs.
FE_WORDS = 56
	
!addr MASK = $cfff
!addr MASK_HIGH = $cffe
!addr MASK_LOW = $cffd
!addr FE_SUB_BORROW = $cffc
!addr FE_ADD_CARRY = $cffb
!addr FE_ADD_TMP2 = $cffa
!addr FE_ADD_TMP1 = $cff9
	
;; XXX should maybe double check these addresses to make sure we're not
;;     crossing page boundaries
!addr FE_ADD_A = FE_ADD_TMP1 - (1 * FE_WORDS) ; Fuckin' fancy assembler parser passing.
!addr FE_ADD_B = FE_ADD_TMP1 - (2 * FE_WORDS)
!addr FE_ADD_C = FE_ADD_TMP1 - (3 * FE_WORDS)
	
;; P434_PRIME = 24439423661345221551909145011457493619085780243761596511325807336205221239331976725970216671828618445898719026692884939342314733567
!addr P434_PRIME = FE_ADD_TMP1 - (4 * FE_WORDS)

	LDA *                       ; Save program counter
    PHA                         ; Push it to the global stack
    * = P434_PRIME              ; Change program couter to location of P434_PRIME
	
	;; Write raw bytes to this offset in the program
!le32 $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $767AFDC1, $FFFFE2FF, $5C787BC6, $AEA33158, $5FD66CFC, $205681C5, $341F0002, $73442717

	PLA                         ; Pull the old program counter back out
	STA MASK                    ; Store it in a junk spot for now
    * = MASK                    ; Restore it

;; 2 * P434_PRIME
!addr P434_PRIME_2 = FE_ADD_TMP1 - (5 * FE_WORDS)

	LDA *                       ; Save program counter
    PHA                         ; Push it to the global stack
    * = P434_PRIME_2            ; Change program couter to location of P434_PRIME_2

	;; Write raw bytes to this offset in the program
!le32 $FFFFFFFF, $FFFFFFFE, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $ECF5FB82, $FFFFC5FF, $B8F0F78C, $5D4762B1, $BFADD9F8, $40AC038A, $683E0004, $E6884E2E

	PLA                         ; Pull the old program counter back out
	STA MASK                    ; Store it in a junk spot for now
    * = MASK                    ; Restore it
	
;; Number of field elements for Alice's 2-isogenisation strategy.
ALICE_ELEMENTS = 108
;; Number of field elements for Bob's 3-isogenisation strategy
BOB_ELEMENTS = 137
