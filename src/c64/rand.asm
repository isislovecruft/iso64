    ;; Randomness generation

    ;; !to "rand.o", cbm               ; Direct the assembler to output to this file
!zone rand                      ; Namespacing
	
    ;; Jump into the BASIC ROM and call RND(accumulator)
	;; 
    ;; To call the RND function from 6502/6510, execute JSR $E09A. The value held
	;; in the accumulator when you call the routine determines what RND() does. If
	;; the accumulator holds a negative byte value ($80-$FF), then the value in
	;; floating point accumulator 1 (FAC1) is used as the seed. If the accumulator
	;; holds zero, RND uses values from timer A and the time-of-day clock, just as
	;; in BASIC. If the accumulator value is positive ($00-$7F), then the seed
	;; value in locations $8B-$8F is used.
    ;;
    ;; Thus, your choices for 6502/6510 are essentially the same as for BASIC,
	;; except that the system variable TI is not available as an argument. An
	;; alternative to using TI is to load the byte values from the software clock
	;; ($A0-A2) directly into the seed addresses ($8B-8F), thus giving a fairly
	;; random seed. If you'd rather not bother with loading the accumulator, you
	;; can perform JSR $E0BE to go directly to the routine which uses the stored
	;; seed value.
	;; 
    ;; As you probably know from using RND in BASIC, the function always returns a
	;; floating point number between 0 and 1. In machine language, it is usually
	;; more convenient to use a single byte value in the range 0-255. Unfortunately,
    ;; some of the randomness of the BASIC floating point number comes from
	;; scrambling the bytes in FAC1; this is lost when single bytes are used. One
	;; alternative is to convert the floating point number to an integer and use
	;; one or more bytes of the integer. But this is somewhat awkward. Nonrepeating
	;; random numbers involving all possible single byte values seem to be produced
	;; in locations $63 and $64 of FAC1 after a call to $E09A with the accumulator
	;; set appropriately. The values found in locations $62 and $65 do not include
	;; all the values from 0-255 and therefore should not be used.
	;; 
    ;; Inputs
    ;;   - .seed is a !byte to be used as a seed, as described above.
	;; 
    ;; Outputs
    ;;   - $63 and $64 of the floating point accumulator, FAC1, contain
    ;;     random bytes in [0, 255]
!macro rand_basic_rnd .seed {
    ;; XXX need way to enable and then disable BASIC ROM (and other ROMs)
	STA .seed
    JSR $E09A                   ; Execute RND() in the BASIC ROM
}
	
	;; The only mode currently supported is using the system clock as a seed.
rand_basic_rnd_system_clock:
    +rand_basic_rnd $00
    RTS
	
    ;; The c64's SID chip also has the ability to generate random values and is very
	;; easy to use. All you need to do is select the noise waveform for the SID's
	;; voice 3 oscillator and set voice 3's frequency to some nonzero value (the
	;; higher the frequency, the faster the random numbers are generated). It is
	;; not necessary to gate (turn on) the voice. Once this is done, random values
	;; appear in location $D41B.
rand_sid:
    LDA #$FF                    ;; Maximum frequency value
    STA $D40E                   ;; Voice 3 frequency low byte
    STA $D40F                   ;; Voice 3 frequency high byte
    LDA #$80                    ;; Noise waveform, gate bit off
    STA $D412                   ;; Voice 3 control register
    RTS
    ;; XXX we should test the randomness generated at different frequencies
