**************************************************
* Pipe Drawing Routines
* These are custom built to draw pipes that 
* move right-to-left only.  There is no undraw.
* It simply copies a blue pixel in the area to the
* right of the column to restore the background.
*
* Due to DLR resolution mapping (same as 80-col
* text mode) I have implemented some *slightly*
* optimized code, in the sense that it handles
* the following drawing operations as distinct
* routines:
*  DrawPipeOdd   - draw odd aligned pipes
*  DrawPipeEven  - draw even aligned pipes
*  DrawPipeOddR  - draw odd aligned pipes / clipped right
*  DrawPipeEvenR - draw even aligned pipes / clipped right
*  DrawPipeOddL  - draw odd aligned pipes / clipped right
*  DrawPipeEvenL - draw even aligned pipes / clipped right
*
* YAY ISN'T DLR FUN?
*		>:(
*
**************************************************
PipeSpr_Main
	hex 55,e5,e5,c5,e5,c5,c5,c5,c5,45,c5,45,45,55,77
	hex 55,5e,5e,5c,5e,5c,5c,5c,5c,54,5c,54,54,55,77
	hex 77,55,ee,ee,cc,ee,cc,cc,44,cc,44,44,55,77,77
	
PipeBody_Main_E hex 55,ee,ee,cc,cc,44,77
PipeBody_Main_O hex 77,ee,cc,cc,44,44,55,77

PipeSpr_Aux
	hex aa,7a,7a,6a,7a,6a,6a,6a,6a,2a,6a,2a,2a,aa,bb
	hex aa,a7,a7,a6,a7,a6,a6,a6,a6,a2,a6,a2,a2,aa,bb
	hex bb,aa,77,77,66,77,66,66,22,66,22,22,aa,bb,bb
PipeBody_Aux_E hex bb,77,66,66,22,22,aa,bb
PipeBody_Aux_O hex aa,77,77,66,66,22,bb

PipeInterval	equ #60	; game ticks to spawn new pipe
PipeSpawn	db 0	; our counter
PipeSpawnSema db 0	; points to next spot (even if currently unavailable)
MaxPipes	equ 2
TopPipes	hex 00,00,00,00
BotPipes	hex 00,00,00,00
BotPipeMin	equ 3
BotPipeMax    equ 8

PIPE_SP	equz  $00
PIPE_DP	equz  $02
PIPE_DP2	equz  $04
PIPE_RCLIP	equ #40
PIPE_WIDTH	equ #15
PIPE_UNDERVAL	db 0

PIPE_X_FULL	db 0	; the 0-96? X value (screen = 16-95)
PIPE_X_IDX	db 0	; MEMORY DLR X index, 0-39 
PIPE_Y	db 0	; MEMORY DLR Y index, 0-24
PIPE_Y_IDX	db 0	; Y*2 for lookups in Lo-Res line table 
PIPE_T_B	db 0	; TOP = 0, BOTTOM = 1 (non-zero)
PIPE_BODY_TOP db 0	; Y val 
PIPE_BODY_BOT db 0	; Y val 
PIPE_EVEN_ODD db 0	; 0=even, Y=odd 

PIPE_TOP	equ 0	; enum for top pipe type
PIPE_BOT	equ 1	; enum for bottom pipe type


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
:noSpawn	
MoveDrawPipes	
	jsr MovePipes
	jsr DrawPipes
	jmp UpdatePipesDone
	

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


MovePipes
	ldx #2	;MaxPipes*2?
:loop	lda BotPipes,x
	beq :noPipe
	dec BotPipes,x
	dec TopPipes,x
	cmp #PipeXScore+1	; A should still be set
	bne :noScore
:ScoreUp	sed
	lda ScoreLo
	clc
	adc #1
	sta ScoreLo
	bcc :noFlip
	lda ScoreHi
	adc #0
	sta ScoreHi
:noFlip	cld

:noScore
:noPipe	dex
	dex
	bpl :loop
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


* Used by all of the routines that draw the pipe caps
SetPipeCapPtrs
	ldy PIPE_Y_IDX
	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen
	lda LoLineTable+2,y
	sta PIPE_DP2
	lda LoLineTable+3,y
	sta PIPE_DP2+1	; pointer to line on screen
	rts


* A=x Y=(byte)y X=pipe top/bottom
DrawPipe
	stx PIPE_T_B
	sta PIPE_X_FULL
	sty PIPE_Y
	
	tya
	asl	; *2
	sta PIPE_Y_IDX

	lda PIPE_X_FULL
	cmp #95-12
	bcc :notOver
:OVER	sec	; clipped on the right.. maybe left too
	sbc #16
	lsr
	sta PIPE_X_IDX
	bcc :evenR
:oddR	jsr DrawPipeOddR
	rts
:evenR	jsr DrawPipeEvenR
	rts
:notOver	cmp #16
	bcs :NOCLIP
:UNDER			; X = 0-16	
	sta PIPE_UNDERVAL	; we're going to flip it around
	lda #16		; and move backwards from 0.  
	sec
	sbc PIPE_UNDERVAL
	pha
	lsr
	sta PIPE_UNDERVAL
	lda #0
	sec
	sbc PIPE_UNDERVAL
	tax 
	pla
	lsr
	bcc :evenL
:oddL	dex	; downshift * 1
	txa	
	sta PIPE_X_IDX
	jsr DrawPipeOddL
	rts
:evenL	txa
	sta PIPE_X_IDX
	jsr DrawPipeEvenL
	rts

:NOCLIP	lda PIPE_X_FULL
	sec 
	sbc #16
	lsr
	sta PIPE_X_IDX
	bcc :even
:odd	
	jsr DrawPipeOdd
	rts
:even
	jsr DrawPipeEven
	rts


DrawPipeOddL	
	jsr SetPipeCapPtrs
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
:l1_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop


	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	;-- pixel after - fun mapping
	ldx #1
:l2_loop	cpy #PIPE_RCLIP
	bcs :l2_skip
	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop

*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeOddTL
	rts
:doBottom	jsr DrawPipeOddBL
	rts



DrawPipeEvenL	
	jsr SetPipeCapPtrs
	sta TXTPAGE2	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y
:l1_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop

	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l2_loop	cpy #PIPE_RCLIP
	bcs :l2_skip
	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop


*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeEvenTL
	rts
:doBottom	jsr DrawPipeEvenBL
	rts


DrawPipeOdd	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502



	ldx #0
:l1_loop	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop

	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	;-- pixel after - fun mapping
	ldx #1
:l2_loop	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeOddT
	rts
:doBottom	jsr DrawPipeOddB
	rts

****************************************
*** Draw Body - Top Full & Right version
DrawPipeOddT  
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyOdd
	rts

*******************************************
*** Draw Body - Bottom Full & Right version
DrawPipeOddB
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyOdd
	rts


****************************************
*** Draw Body - Odd Full & Right version
DrawPipeBodyOdd
:loop	lda PIPE_Y_IDX
	tay
	lsr	; /2
	cmp PIPE_BODY_BOT
	bcs :done
	;ldy PIPE_Y_IDX	; revert to table-lookup form

	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen
	

	sta TXTPAGE1

*** Version 2.1
	lda PIPE_X_IDX
	clc
	adc #PIPE_WIDTH/2
	pha	;PHA for below loop
	tay	
	ldx #PIPE_WIDTH/2
:oddLoop	cpy #PIPE_RCLIP
	bcs :oddBreak
	lda PipeBody_Main_O,x
	sta (PIPE_DP),y
:oddBreak
	dey
	dex
	bne :oddLoop	; we can skip the first pixel, transparent

	sta TXTPAGE2
*** Version 2.1
	pla
	tay	;PHA from above
	ldx #PIPE_WIDTH/2-1
:evenLoop	cpy #PIPE_RCLIP
	bcs :evenBreak
	lda PipeBody_Aux_O,x
	sta (PIPE_DP),y
:evenBreak
	dey
	dex
	bpl :evenLoop

	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop
	;sec
	;bcs :loop
:done	rts


****************************************
*** Draw Body - Top Full & Right version
DrawPipeEvenT  
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyEven
	rts


*******************************************
*** Draw Body Even - Bottom Full & Right version
DrawPipeEvenB
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyEven
	rts

************************************
*** Draw Body - Odd Top Left version
DrawPipeOddTL
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX              ; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyOddL
	rts

****************************************
*** Draw Body - Top Full & Right version
DrawPipeEvenTL  
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyEvenL  
	rts

***************************************
*** Draw Body - Odd Bottom Left version
DrawPipeOddBL
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyOddL
	rts

***************************************
*** Draw Body - Odd Bottom Left version
DrawPipeEvenBL
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jsr DrawPipeBodyEvenL
	rts


DrawPipeEven	jsr SetPipeCapPtrs
	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop

	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l2_loop	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeEvenT
	rts
:doBottom	jsr DrawPipeEvenB
	rts

*****************************************
*** Draw Body - Even Full & Right version
DrawPipeBodyEven
:loop	lda PIPE_Y_IDX
	lsr	; /2
	cmp PIPE_BODY_BOT
	bcs :done
	ldy PIPE_Y_IDX	; revert to table-lookup form

	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen
	
	sta TXTPAGE1
*** Version 2.1
	lda PIPE_X_IDX
	clc
	adc #PIPE_WIDTH/2-1
	pha	;PHA for below loop
	tay	
	ldx #PIPE_WIDTH/2-1
:oddLoop	cpy #PIPE_RCLIP
	bcs :oddBreak
	lda PipeBody_Main_E,x
	sta (PIPE_DP),y
:oddBreak
	dey
	dex
	bpl :oddLoop	


	sta TXTPAGE2
*** Version 2.1
	pla
	tay	;PHA from above
	iny
	ldx #PIPE_WIDTH/2
:evenLoop	cpy #PIPE_RCLIP
	bcs :evenBreak
	lda PipeBody_Aux_E,x
	sta (PIPE_DP),y
:evenBreak
	dey
	dex
	bpl :evenLoop
	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop

:done	rts





DrawPipeOddR
	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	ldy PIPE_X_IDX	; y= x offset... yay dp indexing on 6502
	ldx #0
:l1_loop
	cpy #PIPE_RCLIP ;this works for underflow too (?) i think	
	bcs :l1_break
	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop
:l1_break

	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	;-- pixel after - fun mapping
	ldx #1
:l2_loop	
	cpy #PIPE_RCLIP
	bcs :l2_break

	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y

	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_break	

*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeOddT
	rts
:doBottom	jsr DrawPipeOddB
	rts

DrawPipeEvenR
	jsr SetPipeCapPtrs
	sta TXTPAGE2	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (PIPE_DP),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	cpy #PIPE_RCLIP
	bcs :l1_break
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop

:l1_break	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l2_loop
	cpy #PIPE_RCLIP
	bcs :l2_break
	lda PipeSpr_Main,x
	sta (PIPE_DP),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (PIPE_DP2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_break	

* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	jsr DrawPipeEvenT
	rts
:doBottom	jsr DrawPipeEvenB
	rts

********************************
*** Draw Body - Even Left version
DrawPipeBodyEvenL
:loop	lda PIPE_Y_IDX
	lsr	; *2
	cmp PIPE_BODY_BOT
	beq :done
	ldy PIPE_Y_IDX

	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen

	sta TXTPAGE2
	lda PIPE_X_IDX
	clc
	adc #PIPE_WIDTH/2
	bmi :done
	pha	;PHA for below loop
	tay	
	ldx #PIPE_WIDTH/2
	
:evenLoop	lda PipeBody_Aux_E,x
	sta (PIPE_DP),y
	dex
	dey
	bpl :evenLoop

	sta TXTPAGE1
	pla	;PLA from above
	tay	
	ldx #PIPE_WIDTH/2

:oddLoop	lda PipeBody_Main_E,x
	sta (PIPE_DP),y
	dex
	dey
	bpl :oddLoop


	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop
:done
	rts



********************************
*** Draw Body - Odd Left version
DrawPipeBodyOddL
:loop	lda PIPE_Y_IDX
	lsr	; *2
	cmp PIPE_BODY_BOT
	beq :done
	ldy PIPE_Y_IDX

	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen


	sta TXTPAGE1
	lda PIPE_X_IDX
	clc
	adc #PIPE_WIDTH/2
	bmi :done
	pha	;PHA for below loop
	tay	
	ldx #PIPE_WIDTH/2
	
:evenLoop	lda PipeBody_Main_O,x
	sta (PIPE_DP),y
	dex
	dey
	bpl :evenLoop


	sta TXTPAGE2
	pla	;PLA from above
	tay	
	ldx #PIPE_WIDTH/2-1

:oddLoop	lda PipeBody_Aux_O,x
	sta (PIPE_DP),y
	dex
	dey
	bpl :oddLoop

	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop

:done	rts


