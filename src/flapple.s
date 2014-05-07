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

; Sorry, I gotta have some macros.. this is merlin format after all
; You might as well take advantage of your tools :P
CopyPtr       MAC
	lda #<]1      ; load low byte
	sta ]2	; store low byte
	lda #>]1	; load high byte
	sta ]2+1      ; store high byte
	<<<


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

	jsr VBlank
	jmp UndrawBird
UndrawBirdDone
	jmp UpdatePipes
UpdatePipesDone
	jmp HandleInput
HandleInputDone
	jmp DrawBird
DrawBirdDone
	jmp DrawScore
DrawScoreDone
	jmp UpdateGrass
UpdateGrassDone

	jsr FlapBird
	;jsr WaitKey
	lda QuitFlag
	beq GameLoop
	bne Quit


HandleInput
:kloop	lda KEY
	bpl :noKey
:key	sta STROBE
	cmp #"A"
	beq :up
	cmp #"B"
	beq :dn
	lda #1
	sta QuitFlag
:dn	inc BIRD_Y
	bpl :keyDone
:up	dec BIRD_Y
:noKey
:keyDone	jmp HandleInputDone

QuitFlag	db 0	; set to 1 to quit

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


******************************
* Score Routines
*********************
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
	sta Lo01+18
	sta Lo02+18
	jmp DrawScoreDone



	

**************************************************
* Grass 
**************************************************
UpdateGrass	inc GrassState
	lda GrassState
	cmp #4
	bne :noReset
	lda #0
	sta GrassState
:noReset	
	sta TXTPAGE2	
	ldx GrassState
	lda GrassTop,x	; top[0]
	tax
	lda MainAuxMap,x
	sta Lo23
	sta Lo23+2
	sta Lo23+4
	sta Lo23+6
	sta Lo23+8
	sta Lo23+10
	sta Lo23+12
	sta Lo23+14
	sta Lo23+16
	sta Lo23+18
	sta Lo23+20
	sta Lo23+22
	sta Lo23+24
	sta Lo23+26
	sta Lo23+28
	sta Lo23+30
	sta Lo23+32
	sta Lo23+34
	sta Lo23+36
	sta Lo23+38
	ldx GrassState
	lda GrassBot,x	; Bot[0]
	tax
	lda MainAuxMap,x
	sta Lo24
	sta Lo24+2
	sta Lo24+4
	sta Lo24+6
	sta Lo24+8
	sta Lo24+10
	sta Lo24+12
	sta Lo24+14
	sta Lo24+16
	sta Lo24+18
	sta Lo24+20
	sta Lo24+22
	sta Lo24+24
	sta Lo24+26
	sta Lo24+28
	sta Lo24+30
	sta Lo24+32
	sta Lo24+34
	sta Lo24+36
	sta Lo24+38
	ldx GrassState
	lda GrassTop+2,x	; top[2]
	tax
	lda MainAuxMap,x
	sta Lo23+1
	sta Lo23+3
	sta Lo23+5
	sta Lo23+7
	sta Lo23+9
	sta Lo23+11
	sta Lo23+13
	sta Lo23+15
	sta Lo23+17
	sta Lo23+19
	sta Lo23+21
	sta Lo23+23
	sta Lo23+25
	sta Lo23+27
	sta Lo23+29
	sta Lo23+31
	sta Lo23+33
	sta Lo23+35
	sta Lo23+37
	sta Lo23+39
	ldx GrassState
	lda GrassBot+2,x	; Bot[2]
	tax
	lda MainAuxMap,x
	sta Lo24+1
	sta Lo24+3
	sta Lo24+5
	sta Lo24+7
	sta Lo24+9
	sta Lo24+11
	sta Lo24+13
	sta Lo24+15
	sta Lo24+17
	sta Lo24+19
	sta Lo24+21
	sta Lo24+23
	sta Lo24+25
	sta Lo24+27
	sta Lo24+29
	sta Lo24+31
	sta Lo24+33
	sta Lo24+35
	sta Lo24+37
	sta Lo24+39

	sta TXTPAGE1
	ldx GrassState
	lda GrassTop+1,x	; top[1]
	sta Lo23
	sta Lo23+2
	sta Lo23+4
	sta Lo23+6
	sta Lo23+8
	sta Lo23+10
	sta Lo23+12
	sta Lo23+14
	sta Lo23+16
	sta Lo23+18
	sta Lo23+20
	sta Lo23+22
	sta Lo23+24
	sta Lo23+26
	sta Lo23+28
	sta Lo23+30
	sta Lo23+32
	sta Lo23+34
	sta Lo23+36
	sta Lo23+38
	lda GrassBot+1,x	; Bot[1]
	sta Lo24
	sta Lo24+2
	sta Lo24+4
	sta Lo24+6
	sta Lo24+8
	sta Lo24+10
	sta Lo24+12
	sta Lo24+14
	sta Lo24+16
	sta Lo24+18
	sta Lo24+20
	sta Lo24+22
	sta Lo24+24
	sta Lo24+26
	sta Lo24+28
	sta Lo24+30
	sta Lo24+32
	sta Lo24+34
	sta Lo24+36
	sta Lo24+38
	lda GrassTop+3,x	; top[3]
	sta Lo23+1
	sta Lo23+3
	sta Lo23+5
	sta Lo23+7
	sta Lo23+9
	sta Lo23+11
	sta Lo23+13
	sta Lo23+15
	sta Lo23+17
	sta Lo23+19
	sta Lo23+21
	sta Lo23+23
	sta Lo23+25
	sta Lo23+27
	sta Lo23+29
	sta Lo23+31
	sta Lo23+33
	sta Lo23+35
	sta Lo23+37
	sta Lo23+39
	lda GrassBot+3,x	; bot[3]
	sta Lo24+1
	sta Lo24+3
	sta Lo24+5
	sta Lo24+7
	sta Lo24+9
	sta Lo24+11
	sta Lo24+13
	sta Lo24+15
	sta Lo24+17
	sta Lo24+19
	sta Lo24+21
	sta Lo24+23
	sta Lo24+25
	sta Lo24+27
	sta Lo24+29
	sta Lo24+31
	sta Lo24+33
	sta Lo24+35
	sta Lo24+37
	sta Lo24+39
	jmp UpdateGrassDone

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
VBlankGS	lda #$FE
:vblInProgress	cmp RDVBLBAR
	bpl :vblInProgress
:vblWaitForStart	cmp RDVBLBAR
	bmi :vblWaitForStart

	rts



:loop1	lda RDVBLBAR
	bpl :loop1 ; not VBL
	rts
:loop	lda $c019
	bpl :loop ;wait for beginning of VBL interval
	rts





	use util
	use applerom
	use dlrlib
	use pipes
	use numbers
	use sprite	; this is getting to be a lot
	use bird
