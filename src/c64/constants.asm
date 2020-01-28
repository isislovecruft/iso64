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
!addr FE_ADD_CARRY = $cffe
!addr FE_ADD_TMP2 = $cffd
!addr FE_ADD_TMP1 = $cffc
	
;; XXX should maybe double check these addresses to make sure we're not
;;     crossing page boundaries
!addr FE_ADD_A = FE_ADD_TMP1 - (3 * FE_WORDS) ; Fuckin' fancy assembler parser passing.
!addr FE_ADD_B = FE_ADD_TMP1 - (2 * FE_WORDS)
!addr FE_ADD_C = FE_ADD_TMP1 - (1 * FE_WORDS)


;; Number of field elements for Alice's 2-isogenisation strategy.
ALICE_ELEMENTS = 108
;; Number of field elements for Bob's 3-isogenisation strategy
BOB_ELEMENTS = 137
