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
*  DrawPipeOdd   - draw odd aligned pipes, full or clipped right
*  DrawPipeEven  - draw even aligned pipes, full or clipped right
*  DrawPipeOddL  - draw odd aligned pipes / clipped left
*  DrawPipeEvenL - draw even aligned pipes / clipped left
*
**************************************************

** DEPRECATED, but this is the "linear" format
*PipeSpr_Main	hex 55,e5,e5,c5,e5,c5,c5,c5,c5,45,c5,45,45,55,77
*	hex 55,5e,5e,5c,5e,5c,5c,5c,5c,54,5c,54,54,55,77
*	hex 77,55,ee,ee,cc,ee,cc,cc,44,cc,44,44,55,77,77
	
*PipeSpr_Aux	hex aa,7a,7a,6a,7a,6a,6a,6a,6a,2a,6a,2a,2a,aa,bb
*	hex aa,a7,a7,a6,a7,a6,a6,a6,a6,a2,a6,a2,a2,aa,bb
*	hex bb,aa,77,77,66,77,66,66,22,66,22,22,aa,bb,bb

** "interleave" format
PipeBody_Main_E hex 55,ee,ee,cc,cc,44,77
PipeBody_Main_O hex 77,ee,cc,cc,44,44,55,77
PipeBody_Aux_E hex bb,77,66,66,22,22,aa,bb
PipeBody_Aux_O hex aa,77,77,66,66,22,bb

PipeInterval	equ #75	; game ticks to spawn new pipe
PipeSpawn	db #45	; our counter, starting point for spawning
PipeSpawnSema db 0	; points to next spot (even if currently unavailable)
MaxPipes	equ 2
TopPipes	ds MaxPipes*2	; Space for pipe X,Y
BotPipes	ds MaxPipes*2	; "
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

PipeXScore    equ 50	; pipe at this value causes score increase
ScoreLo	db 0	; 0-99
ScoreHi	db 0	; hundreds, not shown on screen

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




DrawPipes
	lda #PIPE_TOP	; =0
	sta PIPE_T_B

	lda TopPipes	;TopPipes[0]
	beq :noTP0
	sta PIPE_X_FULL
	ldy TopPipes+1
	sty PIPE_Y
	jsr DrawPipe
:noTP0
	lda TopPipes+2 ;TopPipes[0]
	beq :noTP1
	sta PIPE_X_FULL
	ldy TopPipes+3
	sty PIPE_Y
	jsr DrawPipe
:noTP1
	inc PIPE_T_B	; =1 now (see above)

	lda BotPipes	;BotPipes[0]
	beq :noBP0
	sta PIPE_X_FULL
	ldy BotPipes+1
	sty PIPE_Y
	jsr DrawPipe
:noBP0
	lda BotPipes+2	;BotPipes[1]
	beq :noBP1
	sta PIPE_X_FULL
	ldy BotPipes+3
	sty PIPE_Y
	jsr DrawPipe
:noBP1
	jmp DrawPipesDone


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
	lda PIPE_Y
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
:oddR	jmp DrawPipeOddR
:evenR	jmp DrawPipeEvenR
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
	jmp DrawPipeOddL
:evenL	txa
	sta PIPE_X_IDX
	jmp DrawPipeEvenL

:NOCLIP	lda PIPE_X_FULL
	sec 
	sbc #16
	lsr
	sta PIPE_X_IDX
	bcc :even
:odd	jmp DrawPipeOdd
:even	jmp DrawPipeEven
DrawPipeDone	rts


DrawPipeOddL	
	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	lda PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; optimized by hand, not perfect, but big help
	clc
	adc #PIPE_WIDTH/2
	tax	;stash for below loop
	tay	
		;col 14 (rightmost)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$77
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	dey	;col 12
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	dey	;col 10
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	dey	;col 8
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	dey	;col 6
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	dey	;col 4
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
	dey	;col 2
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$E5
	sta (PIPE_DP),y
	dey	;col 0 (final! leftmost)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP
	sta TXTPAGE2
	txa
	tay
		;col 13
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	dey	;col 11
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	dey	;col 9
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$2A
	sta (PIPE_DP),y
	dey	;col 7
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	dey	;col 5
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	dey	;col 3
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	dey	;col 1
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
:RCLIP2

*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	
	;lda #0
		
	sta PIPE_BODY_TOP	; 0 from above
	sta PIPE_Y_IDX              ; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOddL
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOddL



DrawPipeEvenL	
	jsr SetPipeCapPtrs
	sta TXTPAGE2	
	lda PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; optimized by hand, not perfect, but big help
	clc
	adc #PIPE_WIDTH/2
	tax	;stash for below loop
	tay	
		;col 14 (rightmost)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$BB
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	dey	;col 12
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	dey	;col 10
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	dey	;col 8
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	dey	;col 6
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	dey	;col 4
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
	dey	;col 2
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$7A
	sta (PIPE_DP),y
	dey	;col 0 (final! leftmost)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP
	sta TXTPAGE1
	txa
	tay
	dey
		;col 13
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	dey	;col 11
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	dey	;col 9
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$45
	sta (PIPE_DP),y
	dey	;col 7
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	dey	;col 5
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	dey	;col 3
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	dey	;col 1
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
:RCLIP2


*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEvenL  
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEvenL


DrawPipeOdd	jsr SetPipeCapPtrs
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; for this "odd" routine, we add 1 for TXTPAGE2

			; optimized by hand, not perfect, but big help
		;col 0
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	iny	;col 2
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
	iny	;col 4
	sta (PIPE_DP2),y
	lda #$E5
	sta (PIPE_DP),y
	iny	;col 6
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 8
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	iny	;col 10
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 12
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	iny	;col 14 (final!)
	lda #$77
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP

	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	iny	; TXTPAGE2 is +1 in "odd" mode
		;col 1
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
	iny	;col 3
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 5
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	iny	;col 7
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 9
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	iny	;col 11
	sta (PIPE_DP2),y
	lda #$2A
	sta (PIPE_DP),y
	iny	;col 13
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP2
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOdd
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOdd

DrawPipeOddR	jsr SetPipeCapPtrs
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; for this "odd" routine, we add 1 for TXTPAGE2

			; optimized by hand, not perfect, but big help
		;col 0
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	iny	;col 2
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
	iny	;col 4
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$E5
	sta (PIPE_DP),y
	iny	;col 6
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 8
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	iny	;col 10
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 12
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	iny	;col 14 (final!)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$77
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP

	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	iny	; TXTPAGE2 is +1 in "odd" mode
		;col 1
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
	iny	;col 3
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 5
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	iny	;col 7
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 9
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	iny	;col 11
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$2A
	sta (PIPE_DP),y
	iny	;col 13
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP2
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOddR
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyOddR



DrawPipeEven	jsr SetPipeCapPtrs
	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; optimized by hand, not perfect, but big help
		;col 0
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	iny	;col 2
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
	iny	;col 4
	sta (PIPE_DP2),y
	lda #$7A
	sta (PIPE_DP),y
	iny	;col 6
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 8
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	iny	;col 10
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 12
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	iny	;col 14 (final!)
	lda #$BB
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
		;col 1
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
	iny	;col 3
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 5
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	iny	;col 7
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 9
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	iny	;col 11
	sta (PIPE_DP2),y
	lda #$45
	sta (PIPE_DP),y
	iny	;col 13
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP2

* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEven
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEven



DrawPipeEvenR	jsr SetPipeCapPtrs
	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
			; optimized by hand, not perfect, but big help
		;col 0
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$AA
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
	iny	;col 2
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$7A
	sta (PIPE_DP),y
	lda #$A7
	sta (PIPE_DP2),y
	iny	;col 4
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$7A
	sta (PIPE_DP),y
	iny	;col 6
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$6A
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 8
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP2),y
	lda #$6A
	sta (PIPE_DP),y
	iny	;col 10
	cpy #PIPE_RCLIP
	bcs :RCLIP
	sta (PIPE_DP),y
	lda #$A6
	sta (PIPE_DP2),y
	iny	;col 12
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$2A
	sta (PIPE_DP),y
	lda #$A2
	sta (PIPE_DP2),y
	iny	;col 14 (final!)
	cpy #PIPE_RCLIP
	bcs :RCLIP
	lda #$BB
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
		;col 1
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$E5
	sta (PIPE_DP),y
	lda #$5E
	sta (PIPE_DP2),y
	iny	;col 3
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$C5
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 5
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$C5
	sta (PIPE_DP),y
	iny	;col 7
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP),y
	lda #$5C
	sta (PIPE_DP2),y
	iny	;col 9
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$45
	sta (PIPE_DP),y
	lda #$54
	sta (PIPE_DP2),y
	iny	;col 11
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	sta (PIPE_DP2),y
	lda #$45
	sta (PIPE_DP),y
	iny	;col 13
	cpy #PIPE_RCLIP
	bcs :RCLIP2
	lda #$55
	sta (PIPE_DP),y
	sta (PIPE_DP2),y
:RCLIP2

* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
:doTop	
	lda #0
	sta PIPE_BODY_TOP
	sta PIPE_Y_IDX	; current line
	lda PIPE_Y
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEvenR
:doBottom	
	ldy PIPE_Y
	iny
	iny
	sty PIPE_BODY_TOP
	tya
	asl		; *2 
	sta PIPE_Y_IDX	; current line
	lda #22
	sta PIPE_BODY_BOT
	jmp DrawPipeBodyEvenR


*****************************************
*** Draw Body - Even Full 
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
*** Version 3 - FULL OPTIMIZATION
	ldy PIPE_X_IDX
	lda #$55	; PipeBody_Main_E
	sta (PIPE_DP),y
	iny
	lda #$EE
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$CC
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$44
	sta (PIPE_DP),y
	iny
	lda #$77
	sta (PIPE_DP),y



	sta TXTPAGE2
*** Version 3 - FULL OPTIMIZATION
	ldy PIPE_X_IDX
	;lda #$BB	; PipeBody_Aux_E
	;sta (PIPE_DP),y
	iny
	lda #$77
	sta (PIPE_DP),y
	iny
	lda #$66
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$22
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$AA
	sta (PIPE_DP),y
	iny
	lda #$BB
	sta (PIPE_DP),y

	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop

:done	jmp DrawPipeDone

*****************************************
*** Draw Body - Even Right version
DrawPipeBodyEvenR
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

:done	jmp DrawPipeDone


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
	jmp DrawPipeDone


****************************************
*** Draw Body - Odd Full version
DrawPipeBodyOdd
:loop	lda PIPE_Y_IDX
	tay
	lsr	; /2
	cmp PIPE_BODY_BOT
	bcs :done

	lda LoLineTable,y
	sta PIPE_DP
	lda LoLineTable+1,y
	sta PIPE_DP+1	; pointer to line on screen
	
	sta TXTPAGE1
*** Version 3 - FULL OPTIMIZATION
	ldy PIPE_X_IDX
	;lda #$77	; PipeBody_Main_O
	;sta (PIPE_DP),y
	iny
	lda #$EE
	sta (PIPE_DP),y
	iny
	lda #$CC
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$44
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$55
	sta (PIPE_DP),y
	iny
	lda #$77
	sta (PIPE_DP),y


	sta TXTPAGE2
*** Version 3 - FULL OPTIMIZATION
	ldy PIPE_X_IDX
	iny
	lda #$AA	; PipeBody_Aux_O
	sta (PIPE_DP),y
	iny
	lda #$77
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$66
	sta (PIPE_DP),y
	iny
	sta (PIPE_DP),y
	iny
	lda #$22
	sta (PIPE_DP),y
	iny
	lda #$BB
	sta (PIPE_DP),y

	inc PIPE_Y_IDX
	inc PIPE_Y_IDX
	jmp :loop
	;sec
	;bcs :loop
:done	jmp DrawPipeDone


****************************************
*** Draw Body - Odd Full & Right version
DrawPipeBodyOddR
:loop	lda PIPE_Y_IDX
	tay
	lsr	; /2
	cmp PIPE_BODY_BOT
	bcs :done

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
	tay	;\_ skip col 0 (bg color)
	iny	;/
	ldx #PIPE_WIDTH/2+1
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
:done	jmp DrawPipeDone



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

:done	jmp DrawPipeDone


