**********************************************************
*                                                        *
*                      D A C 5 2 2                       *
*                                                        *
*           Michael J. Mahon - April 19, 1993            *
*                                                        *
*                   Copyright (c) 1993                   *
*                                                        *
*  Plays sounds through the Apple speaker by simulating  *
*  a 5-bit D/A converter in software.  The sample rate   *
*  is assumed to be 11.025 KHz.  The sound start address *
*  is in "start" and the ending address is in "end".     *
*                                                        *
*  Sounds are encoded as a stream of bytes.  Each byte   *
*  is an 8-bit unsigned sample.  The 5 high-order bits   *
*  of each byte are used to select the duty cycle (ratio *
*  of "on" time to "off" time) of a pulse train having a *
*  constant period of 46 cycles.  This corresponds to a  *
*  "carrier" frequency of 22.05 KHz., twice the sample   *
*  rate.  The intention is that this frequency is high   *
*  enough so that most people will not hear it as noise  *
*  obscuring the sampled sound.                          *
*                                                        *
*  It works by using each sampled byte to select one of  *
*  16 duty cycle "generators," each of which can produce *
*  two duty cycles within one cycle of each other, con-  *
*  trolled by the state of the processor's overflow flag.*
*  This flag is set by the fifth most-significant bit of *
*  the sample byte, so there are 32 distinct duty cycles *
*  ranging from 6 to 37 cycles.  This implements a 5-bit *
*  digital-to-analog converter (DAC) in software.  Each  *
*  generator generates two identical pulses for a total  *
*  time of 92 cycles, a reasonably close approximation   *
*  to 11.025 KHz.  (Actually, 11.092 KHz.)  Since the    *
*  pulse rep rate is 22 KHz, there is almost no 11 KHz.  *
*  noise present.  (Those of you who can hear 22 KHz.,   *
*  however, will hear PLENTY!)                           *
*                                                        *
**********************************************************

start equ 6 ; Address of first sound byte
end equ 8 ; Address of last sound byte
ztrash equ $FD ; Trashable page zero byte
ptr equ $FE ; $FE.$FF = ptr to byte
spkr equ $C030 ; Speaker toggle address

* Macro definitions

cinc mac  ; Conditional inc (8 cycles)
 beq *+4 ; If eq, branch to inc.
 nop  ; Else kill 2 cycles and
 dfb $AD ;  "lda xxxx" to skip inc
 inc ]1
 eom

vtoggle mac  ; Trim delay & toggle spkr.
 bvs *+2 ; 3 cyc if V set
 sta spkr ; <====================
 bvc *+2 ; 3 cyc if V off
 eom

align mac  ; If splitting, align 0 mod arg
 do split ; Align only if splitting
 ds *+]1-1/]1*]1-*
 fin
 eom

gentail mac  ; Gen 2nd pulse (3 cycles)
 do split ; Align only if splitting
 jmp *+63/64*64
 ds *+63/64*64-*
 else
 kill3
 fin
 sta spkr ; <====================
 eom

kill3 mac
 sta ztrash ; Kill 3 cycles
 eom

kill7 mac
 pha  ; Kill 7 cycles
 pla
 eom

* Compile-time flags

 cyc  ; Print cycles.
 lstdo off ; Don't print false do's.
 tr on ; Only print first 3 bytes.
split equ 0 ; 1 to split; 0 to not split

* org $4000 ; page boundary
 ds \
entry php  ; Save interrupt state
 sei  ;   and disable.
 ldx #0 ; Set up fetch address
 stx ptr
 lda start+1
 sta ptr+1
 ldy start
 lda (end,x) ; Save last byte
 pha
 txa  ;  and set it
 sta (end,x) ;   to 0.
 jmp gen0 ; Get things going...

genlo dfb gen0 ; Lo vector bytes
 dfb gen1
 dfb gen2
 dfb gen3
 dfb gen4
 dfb gen5
 dfb gen6
 dfb gen7
 dfb gen8
 dfb gen9
 dfb gen10
 dfb gen11
 dfb gen12
 dfb gen13
 dfb gen14
 dfb gen15

genhi dfb >gen0 ; Hi vector bytes
 dfb >gen1
 dfb >gen2
 dfb >gen3
 dfb >gen4
 dfb >gen5
 dfb >gen6
 dfb >gen7
 dfb >gen8
 dfb >gen9
 dfb >gen10
 dfb >gen11
 dfb >gen12
 dfb >gen13
 dfb >gen14
 dfb >gen15

checkend lda ptr+1 ; Check for end
 cmp end+1 ;  of sound...
 bcc cont
 cpy end
 bcc gen00 ; Generate "0" pulses
 pla  ; Restore last byte,
 sta (end,x)
 plp  ;  pop interrupt state,
 rts  ;   and return...

cont nop  ; Compensate for
 kill3 ;  skipped CPX/BCC...
gen00 nop
 nop
 nop
 nop
 sta spkr ; <---- start: 6 cyc.
 vtoggle ; <====== end: 40 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 kill7
 kill7
 kill3
 kill3
 jmp gen0 ; Go to gen0...

 align 256 ; Page boundary if splitting...
gen0 sta spkr ; <==== start: 6/7 cyc.
 vtoggle ; <====== end: 40/39 cyc.
 lda (ptr),y ; Re-fetch the byte
 beq ckend ; If 0, check for end.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 gentail ; <==== start: 6/7 cyc.
 vtoggle ; <====== end: 40/39 cyc.
 tax
 lda genlo,x ; Switch addr low
 sta sw0+1
 lda genhi,x ; Switch addr high
 sta sw0+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
 nop
sw0 jmp * ; Switch to next gen.

ckend jmp checkend ; Relay jump.

 align 64
gen1 sta spkr ; <==== start: 8/9 cyc.
 iny  ; Next sound byte.
 vtoggle ; <====== end: 38/37 cyc.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 nop
 gentail ; <==== start: 8/9 cyc.
 nop
 vtoggle ; <====== end: 38/37 cyc.
 lda genlo,x ; Switch addr low
 sta sw1+1
 lda genhi,x ; Switch addr high
 sta sw1+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
 nop
sw1 jmp * ; Switch to next gen.

 align 64
gen2 sta spkr ; <==== start: 10/11 cyc.
 nop
 iny  ; Next sound byte.
 vtoggle ; <====== end: 36/35 cyc.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 gentail ; <==== start: 10/11 cyc.
 lda genlo,x ; Switch addr low
 vtoggle ; <====== end: 36/35 cyc.
 sta sw2+1
 lda genhi,x ; Switch addr high
 sta sw2+2
 lda #0
 adc #$7F ; Copy carry to overflow
 kill7
 kill3
sw2 jmp * ; Switch to next gen.

 align 64
gen3 sta spkr ; <==== start: 12/13 cyc.
 iny  ; Next sound byte.
 nop
 nop
 vtoggle ; <====== end: 34/33 cyc.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 kill3
 gentail ; <==== start: 12/13 cyc.
 tax
 lda genlo,x ; Switch addr low
 vtoggle ; <====== end: 34/33 cyc.
 sta sw3+1
 lda genhi,x ; Switch addr high
 sta sw3+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
 nop
sw3 jmp * ; Switch to next gen.

 align 64
gen4 sta spkr ; <==== start: 14/15 cyc.
 iny  ; Next sound byte.
 nop
 nop
 nop
 vtoggle ; <====== end: 32/31 cyc.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 kill3
 gentail ; <==== start: 14/15 cyc.
 lsr  ; Low bit to carry
 tax
 lda genlo,x ; Switch addr low
 vtoggle ; <====== end: 32/31 cyc.
 sta sw4+1
 lda genhi,x ; Switch addr high
 sta sw4+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
sw4 jmp * ; Switch to next gen.

 align 64
gen5 sta spkr ; <==== start: 16/17 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 vtoggle ; <====== end: 30/29 cyc.
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 nop
 gentail ; <==== start: 16/17 cyc.
 lda genlo,x ; Switch addr low
 sta sw5+1
 nop
 vtoggle ; <====== end: 30/29 cyc.
 lda genhi,x ; Switch addr high
 sta sw5+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
 nop
sw5 jmp * ; Switch to next gen.

 align 64
gen6 sta spkr ; <==== start: 18/19 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 nop
 vtoggle ; <====== end: 28/27 cyc.
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 gentail ; <==== start: 18/19 cyc.
 lda genlo,x ; Switch addr low
 sta sw6+1
 lda genhi,x ; Switch addr high
 vtoggle ; <====== end: 28/27 cyc.
 sta sw6+2
 lda #0
 adc #$7F ; Copy carry to overflow
 kill7
 kill3
sw6 jmp * ; Switch to next gen.

 align 64
gen7 sta spkr ; <==== start: 20/21 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 nop
 nop
 vtoggle ; <====== end: 26/25 cyc.
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 kill3
 gentail ; <==== start: 20/21 cyc.
 tax
 lda genlo,x ; Switch addr low
 sta sw7+1
 lda genhi,x ; Switch addr high
 vtoggle ; <====== end: 26/25 cyc.
 sta sw7+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
 nop
sw7 jmp * ; Switch to next gen.

 align 64
gen8 sta spkr ; <==== start: 22/23 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 nop
 nop
 nop
 vtoggle ; <====== end: 24/23 cyc.
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 kill3
 gentail ; <==== start: 22/23 cyc.
 lsr  ; Low bit to carry
 tax
 lda genlo,x ; Switch addr low
 sta sw8+1
 lda genhi,x ; Switch addr high
 vtoggle ; <====== end: 24/23 cyc.
 sta sw8+2
 lda #0
 adc #$7F ; Copy carry to overflow
 nop
 nop
 nop
sw8 jmp * ; Switch to next gen.

 align 64
gen9 sta spkr ; <==== start: 24/25 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 kill3
 vtoggle ; <====== end: 22/21 cyc.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 nop
 gentail ; <==== start: 24/25 cyc.
 lda genlo,x ; Switch addr low
 sta sw9+1
 lda genhi,x ; Switch addr high
 sta sw9+2
 nop
 vtoggle ; <====== end: 22/21 cyc.
 nop
 nop
 nop
 nop
 lda #0
 adc #$7F ; Copy carry to overflow
sw9 jmp * ; Switch to next gen.

 align 64
gen10 sta spkr ; <==== start: 26/27 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 kill3
 vtoggle ; <====== end: 20/19 cyc.
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 nop
 gentail ; <==== start: 26/27 cyc.
 lda genlo,x ; Switch addr low
 sta sw10+1
 lda genhi,x ; Switch addr high
 sta sw10+2
 nop
 nop
 vtoggle ; <====== end: 20/19 cyc.
 nop
 nop
 nop
 lda #0
 adc #$7F ; Copy carry to overflow
sw10 jmp * ; Switch to next gen.

 align 64
gen11 sta spkr ; <==== start: 28/29 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 kill3
 vtoggle ; <====== end: 18/17 cyc.
 lsr
 lsr  ; Low bit to carry
 tax
 nop
 gentail ; <==== start: 28/29 cyc.
 lda genlo,x ; Switch addr low
 sta sw11+1
 lda genhi,x ; Switch addr high
 sta sw11+2
 nop
 nop
 nop
 vtoggle ; <====== end: 18/17 cyc.
 nop
 nop
 lda #0
 adc #$7F ; Copy carry to overflow
sw11 jmp * ; Switch to next gen.

 align 64
gen12 sta spkr ; <==== start: 30/31 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 kill3
 vtoggle ; <====== end: 16/15 cyc.
 lsr  ; Low bit to carry
 tax
 nop
 gentail ; <==== start: 30/31 cyc.
 lda genlo,x ; Switch addr low
 sta sw12+1
 lda genhi,x ; Switch addr high
 sta sw12+2
 nop
 nop
 nop
 nop
 vtoggle ; <====== end: 16/15 cyc.
 nop
 lda #0
 adc #$7F ; Copy carry to overflow
sw12 jmp * ; Switch to next gen.

 align 64
gen13 sta spkr ; <==== start: 32/33 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 kill3
 vtoggle ; <====== end: 14/13 cyc.
 tax
 nop
 gentail ; <==== start: 32/33 cyc.
 lda genlo,x ; Switch addr low
 sta sw13+1
 lda genhi,x ; Switch addr high
 sta sw13+2
 nop
 nop
 nop
 nop
 nop
 vtoggle ; <====== end: 14/13 cyc.
 lda #0
 adc #$7F ; Copy carry to overflow
sw13 jmp * ; Switch to next gen.

 align 64
gen14 sta spkr ; <==== start: 34/35 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 vtoggle ; <====== end: 12/11 cyc.
 nop
 gentail ; <==== start: 34/35 cyc.
 lda genlo,x ; Switch addr low
 sta sw14+1
 lda genhi,x ; Switch addr high
 sta sw14+2
 nop
 nop
 nop
 nop
 nop
 lda #0
 vtoggle ; <====== end: 12/11 cyc.
 adc #$7F ; Copy carry to overflow
sw14 jmp * ; Switch to next gen.

 align 64
gen15 sta spkr ; <==== start: 36/37 cyc.
 iny  ; Next sound byte.
 cinc ptr+1 ; (next page)
 lda (ptr),y ; Fetch sound byte.
 lsr
 lsr
 lsr
 lsr  ; Low bit to carry
 tax
 kill3
 nop
 vtoggle ; <====== end: 10/9 cyc.
 gentail ; <==== start: 36/37 cyc.
 lda genlo,x ; Switch addr low
 sta sw15+1
 lda genhi,x ; Switch addr high
 sta sw15+2
 kill7
 kill3
 lda #0
 adc #$7F ; Copy carry (too soon!)
 vtoggle ; <====== end: 10/9 cyc.
sw15 jmp * ; Switch to next gen.
 align
