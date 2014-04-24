****************************************
* Flapple Bird                         *
*                                      *
*  Dagen Brock <dagenbrock@gmail.com>  *
*  2014-04-17                          *
****************************************
	lst off
	org $2000	; start at $2000 (all ProDOS8 system files)
	dsk f	; tell compiler what name for output file ("f", temporarily)
	typ $ff	; set P8 type ($ff = "SYS") for output file
	xc  off	; @todo force 6502?
	xc  off
MLI	equ $bf00




Main	
	jsr DetectIIgs
	jsr InitState	;@todo: IIc vblank code

	
	jsr VBlank
	jsr DL_SetDLRMode
	
	lda #$77
	jsr DL_Clear


GameLoop	
	; handle input
	; draw grass
	; wait vblank
	; undraw player
	; update pipes / draw
	; update player / draw (w/collision)
	; update score
	jsr UpdatePipes
	jsr UpdateGrass
	jsr VBlank
*jsr WaitKey



:kloop	lda KEY
	bpl :noKey
:key	sta STROBE
	bmi Quit
:noKey	bpl GameLoop




Quit	jsr MLI	; first actual command, call ProDOS vector
	dfb $65	; with "quit" request ($65)
	da QuitParm
	bcs Error
	brk $00	; shouldn't ever  here!

QuitParm	dfb 4	; number of parameters
	dfb 0	; standard quit type
	da $0000	; not needed when using standard quit
	dfb 0	; not used
	da $0000	; not used


Error	brk $00	; shouldn't be here either


**************************************************
* Pipes 
*
**************************************************
PipeInterval	equ #60	; game ticks to spawn new pipe
PipeSpawn	db 0	; our counter
PipeSpawnSema db 0	; points to next spot (even if currently unavailable)
MaxPipes	equ 2
TopPipes	hex 00,00,00,00
	lst on
BotPipes	hex 00,00,00,00
	lst off
BotPipeMin	equ 3
BotPipeMax    equ 8
	
PipeSpr_Main
	hex 55,e5,e5,c5,e5,c5,c5,c5,c5,45,c5,45,45,55,77
	hex 55,5e,5e,5c,5e,5c,5c,5c,5c,54,5c,54,54,55,77
	hex 77,55,ee,ee,cc,ee,cc,cc,44,cc,44,44,55,77,77


PipeSpr_Aux
	hex aa,7a,7a,6a,7a,6a,6a,6a,6a,2a,6a,2a,2a,aa,bb
	hex aa,a7,a7,a6,a7,a6,a6,a6,a6,a2,a6,a2,a2,aa,bb
	hex bb,aa,77,77,66,77,66,66,22,66,22,22,aa,bb,bb

* pipe min  =  15x6 pixels  =  15x3 bytes
* playfield =  80x48 pixels =  80x24 bytes
*   - grass =	 80x44 pixels =  80x22 bytes
* we'll make the pipes sit on a 95x22 space
* we don't care about screen pixel X/Y though we could translate
* the drawing routine will handle it, and we will do collision
* in the bird drawing routine
UpdatePipes	inc PipeSpawn
	lda PipeSpawn
	cmp #PipeInterval
	bne :noSpawn
	jsr SpawnPipe
	lda #0
	sta PipeSpawn
:noSpawn	jsr MoveDrawPipes


	rts

MoveDrawPipes	lda BotPipes
	beq :noP1
	dec BotPipes
	ldy BotPipes+1
	jsr DrawPipe
:noP1
	lda BotPipes+2
	beq :noP2
	dec BotPipes+2
	ldy BotPipes+3
	jsr DrawPipe

:noP2	rts

SRCPTR	equz  $00
DSTPTR	equz  $02
RCLIP	equ #40
PIPEUNDERVAL	db 0
* A=x Y=(byte)y
DrawPipeSimple 
	tax
	cpx #95-12
	bcc :notOver
:OVER	sec	; clipped on the right.. maybe left too
	sbc #16
	lsr
	bcc :evenR
:oddR	jsr DrawPipeOddR
	rts
:evenR	jsr DrawPipeEvenR
	rts
:notOver	cpx #16
	bcs :notUnder
:UNDER			; X = 0-16	
	stx PIPEUNDERVAL	; we're going to flip it around
	lda #16		; and move backwards from 0.  
	sec
	sbc PIPEUNDERVAL
	pha
	lsr
	sta PIPEUNDERVAL
	lda #0
	sec
	sbc PIPEUNDERVAL
	tax 
	pla
	lsr
	bcc :evenL
:oddL	dex	; downshift * 1
	txa	
	jsr DrawPipeOddL
	rts
:evenL	txa
	jsr DrawPipeEvenL
	rts

:notUnder		; in screen bounds so give real memory x offset
	sec
	sbc #16
	lsr
	bcc :even
:odd	;txa
	jsr DrawPipeOdd
	rts
:even	;txa
	jsr DrawPipeEven
	rts

* A=x(screenmemX) x=x(full96) Y=(byte)y
DrawPipeOdd	tax	
	sta TXTPAGE1
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop

	sta TXTPAGE2
	pla	;\
	tay	; >- restore
	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts

DrawPipeEven	tax
	sta TXTPAGE2
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop

	sta TXTPAGE1
	pla	;\
	tay	; >- restore
*	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts

* A=x(screenmemX) x=x(full96) Y=(byte)y
DrawPipeOddR	tax	
	sta TXTPAGE1
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	cpy #RCLIP	; this works for underflow too (?) i think	
	bcs :l1_break
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop
:l1_break

	sta TXTPAGE2
	pla	;\
	tay	; >- restore
	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	cpy #RCLIP
	bcs :l2_break
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
:l2_break	rts

DrawPipeEvenR	tax
	sta TXTPAGE2
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	cpy #RCLIP
	bcs :l1_break
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop

:l1_break	sta TXTPAGE1
	pla	;\
	tay	; >- restore
*	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	iny	; can check this for clipping?
	cpy #RCLIP
	bcs :l2_break
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
:l2_break	rts

* A=x(screenmemX) x=x(full96) Y=(byte)y
DrawPipeOddL	
	tax	
	sta TXTPAGE1
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #RCLIP
	bcs :l1_skip
	lda PipeSpr_Main,x
	sta (DSTPTR),y
:l1_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop


	sta TXTPAGE2
	pla	;\
	tay	; >- restore
	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	cpy #RCLIP
	bcs :l2_skip
	lda PipeSpr_Aux,x
	sta (DSTPTR),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts

DrawPipeEvenL	tax
	sta TXTPAGE2
	tya
	asl	; *2
	tay
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #RCLIP
	bcs :l1_skip
	lda PipeSpr_Aux,x
	sta (DSTPTR),y
:l1_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop

	sta TXTPAGE1
	pla	;\
	tay	; >- restore
*	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	cpy #RCLIP
	bcs :l2_skip
	lda PipeSpr_Main,x
	sta (DSTPTR),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts


* A=x Y=(byte)y
DrawPipe	;jsr _storeReg
	jsr DrawPipeSimple
	rts



	jsr _loadReg
	tay	;store?	
	lsr
	bcc DrawBlipEven
DrawBlipOdd   sta TXTPAGE1
	sec
	sbc #$08
	tax
	lda #$11
	sta Lo15,x
	cpx #40	;test---
	bcs :noUndraw	
	sta TXTPAGE2
	lda #$BB
	sta Lo15+1,x
:noUndraw	rts
DrawBlipEven	sta TXTPAGE2
	sec
	sbc #$08
	tax
	lda #$88
	sta Lo15,x
	cpx #40	;test---
	bcs :noUndraw
	sta TXTPAGE1
	lda #$77
	sta Lo15,x
:noUndraw	rts

SpawnPipe	lda PipeSpawnSema
	asl	; convert to word index
	tax
	jsr GetRand	; Build Y Value
	and #$0F	; @todo - this doesn't check bounds.. just for testing
	lsr	; even smaller
	sta TopPipes+1,x
	lda #22
	sec
	sbc TopPipes+1,x
	sta BotPipes+1,x
	lda #95	; Build X Value ;)
	sta TopPipes,x  
	sta BotPipes,x
	inc PipeSpawnSema
	lda PipeSpawnSema
	cmp #MaxPipes
	bne :done
	lda #0	; flip our semaphore/counter to 0
	sta PipeSpawnSema
:done	rts

**************************************************
* Grass 
**************************************************
UpdateGrass	inc GrassState
	lda GrassState
	cmp #4
	bne :noReset
	lda #0
	sta GrassState
:noReset	sta TXTPAGE2
	ldx GrassState
	lda GrassTop,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp1	sta Lo23,x
	inx
	inx
	cpx #40
	bcc :lp1
	ldx GrassState
	lda GrassTop+2,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp2	sta Lo23+1,x
	inx 
	inx
	cpx #40
	bcc :lp2	

	sta TXTPAGE1
	ldx GrassState
	lda GrassTop+1,x
	ldx #0
:lp3	sta Lo23,x
	inx
	inx
	cpx #40
	bcc :lp3
	ldx GrassState
	lda GrassTop+3,x
	ldx #0
:lp4	sta Lo23+1,x
	inx 
	inx
	cpx #40
	bcc :lp4
:bottom	sta TXTPAGE2
	ldx GrassState
	lda GrassBot,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp5	sta Lo24,x
	inx
	inx
	cpx #40
	bcc :lp5
	ldx GrassState
	lda GrassBot+2,x
	tax
	lda MainAuxMap,x
	ldx #0
:lp6	sta Lo24+1,x
	inx 
	inx
	cpx #40
	bcc :lp6	

	sta TXTPAGE1
	ldx GrassState
	lda GrassBot+1,x
	ldx #0
:lp7	sta Lo24,x
	inx
	inx
	cpx #40
	bcc :lp7
	ldx GrassState
	lda GrassBot+3,x
	ldx #0
:lp8	sta Lo24+1,x
	inx 
	inx
	cpx #40
	bcc :lp8
	rts

GrassState	db  00
GrassTop	hex CE,CE,4E,4E,CE,CE,4E,4E
GrassBot	hex 4C,44,44,4C,4C,44,44,4C

WaitKey
:kloop	lda KEY
	bpl :kloop
	sta STROBE
	rts

WaitSmart
:kloop	lda KEY
	bpl :kloop
	sta STROBE
	rts

_WaitSmartMode db 0	;0 = no pause until magickey
		;1 = always pause

**************************************************
* See if we're running on a IIgs
* From Apple II Technote: 
*   Miscellaneous #7
*   Apple II Family Identification
**************************************************
DetectIIgs	
	sec        ;Set carry bit (flag)
	jsr $FE1F    ;Call to the monitor
	bcs :oldmachine    ;If carry is still set, then old machine
*	bcc :newmachine    ;If carry is clear, then new machine
:newmachine   lda #1
	sta GMachineIIgs
	rts
:oldmachine	lda #0
	sta GMachineIIgs
	rts

InitState
	lda GMachineIIgs
	beq :IIe
	rts
:IIe	rts	

GMachineIIgs  dw 0

VBlankSafe	
*	pha
*	phx
*	phy
	jsr VBlank
*	ply
*	plx
*	pla
	rts

VBlank	lda _vblType
	bne :IIc
	jsr VBlankNormal
	rts
:IIc	rts

_vblType	db 0	; 0 - normal, 1 - IIc

**************************************************
* Wait for vertical blanking interval - IIe/IIgs
**************************************************
VBlankNormal
:loop1	lda RDVBLBAR
	bpl :loop1 ; not VBL
:loop	lda $c019
	bmi :loop ;wait for beginning of VBL interval
	rts
	

	use applerom
	use dlrlib
	use util
