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


SRCPTR	equz  $00
DSTPTR	equz  $02
DSTPTR2	equz  $04
PIPE_RCLIP	equ #40
PIPE_UNDERVAL	db 0

PIPE_X_FULL	db 0	; the 0-96? X value (screen = 16-95)
PIPE_X_IDX	db 0	; MEMORY DLR X index, 0-39 
PIPE_Y	db 0	; MEMORY DLR Y index, 0-24
PIPE_Y_IDX	db 0	; Y*2 for lookups in Lo-Res line table 
PIPE_T_B	db 0	; TOP = 0, BOTTOM = 1 (non-zero)
PIPE_TOP	equ 0	; enum for top pipe type
PIPE_BOT	equ 1	; enum for bottom pipe type

* A=x Y=(byte)y
DrawPipe	
	sta PIPE_X_FULL
	tax	
	sty PIPE_Y
	tya
	asl	; *2
	sta PIPE_Y_IDX
	txa
	cpx #95-12
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
:notOver	cpx #16
	bcs :notUnder
:UNDER			; X = 0-16	
	stx PIPE_UNDERVAL	; we're going to flip it around
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
	lda LoLineTable+2,y
	sta DSTPTR2
	lda LoLineTable+3,y
	sta DSTPTR2+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
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
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y
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
	lda LoLineTable+2,y
	sta DSTPTR2
	lda LoLineTable+3,y
	sta DSTPTR2+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y
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
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts

SetPipeCapPtrs
	ldy PIPE_Y_IDX
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	lda LoLineTable+2,y
	sta DSTPTR2
	lda LoLineTable+3,y
	sta DSTPTR2+1	; pointer to line on screen
	rts


* A=x(screenmemX) x=x(full96) Y=(byte)y
DrawPipeOddR	
	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop
	cpy #PIPE_RCLIP ;this works for underflow too (?) i think	
	bcs :l1_break

	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
	

	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop
:l1_break

	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	;-- pixel after - fun mapping
	ldx #1
:l1a_loop	
	cpy #PIPE_RCLIP
	bcs :l2_break

	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y

	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
:l2_break	
	rts

DrawPipeEvenR	
	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	cpy #PIPE_RCLIP
	bcs :l1_break
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1_loop

:l1_break	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l1a_loop
	cpy #PIPE_RCLIP
	bcs :l2_break
	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
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
	lda LoLineTable+2,y
	sta DSTPTR2
	lda LoLineTable+3,y
	sta DSTPTR2+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
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
:l1a_loop	cpy #PIPE_RCLIP
	bcs :l2_skip
	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y
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
	lda LoLineTable+2,y
	sta DSTPTR2
	lda LoLineTable+3,y
	sta DSTPTR2+1	; pointer to line on screen
	txa
	pha
	tay	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+15,x
	sta (DSTPTR2),y
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
:l1a_loop	cpy #PIPE_RCLIP
	bcs :l2_skip
	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+15,x
	sta (DSTPTR2),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #15
	bcc :l1a_loop
	rts



* OLD DRAWPIPE BLIP CODE

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
