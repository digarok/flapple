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

*	jsr PipeTester


GameLoop	
	; handle input
	; draw grass
	; wait vblank
	; undraw player
	; update pipes / draw
	; update player / draw (w/collision)
	; update score
	jsr UpdatePipes
	jsr DrawScore
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
PipeXScore    equ 50
ScoreLo	db 0
ScoreHi	db 0

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

MoveDrawPipes	
	jsr DrawPipes
	jsr MovePipes
	rts

MovePipes
	ldx #0
:loop	lda BotPipes,x
	beq :noPipe
	dec BotPipes,x
	dec TopPipes,x
	lda TopPipes,x
	cmp #PipeXScore
	bne :noScore
	jsr ScoreUp
:noScore
:noPipe	inx
	inx
	cpx #4
	bcc :loop
	rts


DrawPipes	
	lda BotPipes
	beq :noP1
	ldx #PIPE_BOT
	ldy BotPipes+1
	jsr DrawPipe
	ldx #PIPE_TOP
	lda TopPipes
	ldy TopPipes+1
	jsr DrawPipe
:noP1
	lda BotPipes+2
	beq :noP2
	ldx #PIPE_BOT
	ldy BotPipes+3
	jsr DrawPipe
	ldx #PIPE_TOP
	lda TopPipes+2
	ldy TopPipes+3
	jsr DrawPipe
:noP2	
	rts

** Draw the Score - @todo - handle > 99
DrawScore	lda ScoreLo
	and #$0F
	ldy #21
	jsr DrawNum
	lda ScoreLo
	lsr
	lsr
	lsr
	lsr
	tax
	ldy #19
	jsr DrawNum
	lda #$FF
	sta TXTPAGE1
	ldx #18
	sta Lo01,x
	sta Lo02,x
	rts

ScoreUp	sed
	lda ScoreLo
	clc
	adc #1
	sta ScoreLo
	bcc :noFlip
	lda ScoreHi
	adc #0
	sta ScoreHi
:noFlip	cld
	rts

SpawnPipe	lda PipeSpawnSema
	asl	; convert to word index
	tax
	jsr GetRand	; Build Y Value
	and #$0F	; @todo - this doesn't check bounds.. just for testing
	lsr	; even smaller
	sta TopPipes+1,x
	clc
	adc #10
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
	sec	;Set carry bit (flag)
	jsr $FE1F	;Call to the monitor
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



**** 
*  TEST CODE  @Todo: remove
***
PipeTester	ldx #PIPE_BOT
	lda #20+16
	ldy #15
	jsr DrawPipe

	jsr WaitKey
	ldx #PIPE_BOT
              lda #45+16
              ldy #15
              jsr DrawPipe
	jsr WaitKey

	ldx #PIPE_TOP
	lda #20+16
	ldy #8
	jsr DrawPipe

	jsr WaitKey
	ldx #PIPE_TOP
              lda #45+16
              ldy #1
              jsr DrawPipe
	jsr WaitKey





	use util
	use applerom
	use dlrlib
	use pipes
	use bird
	use numbers
