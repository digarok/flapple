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

PipeSpr_Aux
	hex aa,7a,7a,6a,7a,6a,6a,6a,6a,2a,6a,2a,2a,aa,bb
	hex aa,a7,a7,a6,a7,a6,a6,a6,a6,a2,a6,a2,a2,aa,bb
	hex bb,aa,77,77,66,77,66,66,22,66,22,22,aa,bb,bb

SRCPTR	equz  $00
DSTPTR	equz  $02
DSTPTR2	equz  $04
PIPE_RCLIP	equ #40
PIPE_WIDTH	equ #15
PIPE_UNDERVAL	db 0

PIPE_X_FULL	db 0	; the 0-96? X value (screen = 16-95)
PIPE_X_IDX	db 0	; MEMORY DLR X index, 0-39 
PIPE_Y	db 0	; MEMORY DLR Y index, 0-24
PIPE_Y_IDX	db 0	; Y*2 for lookups in Lo-Res line table 
PIPE_T_B	db 0	; TOP = 0, BOTTOM = 1 (non-zero)
PIPE_TOP	equ 0	; enum for top pipe type
PIPE_BOT	equ 1	; enum for bottom pipe type

* Used by all of the routines that draw the pipe caps
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
	bcs :NOCLIP
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


DrawPipeOdd	jsr SetPipeCapPtrs
	sta TXTPAGE1	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
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
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
:doTop	jsr DrawPipeOddT
	rts
:doBottom	jsr DrawPipeOddB
	rts

DrawPipeOddB  
	inc PIPE_Y_IDX	; set to advance to 3rd line (2) of sprite pos
	inc PIPE_Y_IDX	; 

:loop	inc PIPE_Y_IDX	; remember this is the *2 table lookup	
	inc PIPE_Y_IDX
	ldy PIPE_Y_IDX
	cpy #44	; make sure we haven't hit bottom... pun intended
	beq :done
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	
	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	beq :l1_clip_break	
	lda 2*PIPE_WIDTH+PipeSpr_Main,x ; line 2
	sta (DSTPTR),y
	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l1_loop
:l1_clip_break

	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	; THE MOST IMPORTANT INY EVAR!!! :P
	ldx #1
:l2_loop	cpy #PIPE_RCLIP
	beq :l2_clip_break	
	lda 2*PIPE_WIDTH+PipeSpr_Aux,x ; line 2
	sta (DSTPTR),y
	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_clip_break sec
	bcs :loop

:done	rts

DrawPipeOddT  rts

DrawPipeEven	jsr SetPipeCapPtrs
	sta TXTPAGE2
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l1_loop

	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l2_loop	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
:doTop	jsr DrawPipeEvenT
	rts
:doBottom	jsr DrawPipeEvenB
	rts

DrawPipeEvenT  
	rts

DrawPipeEvenB  
	inc PIPE_Y_IDX	; set to advance to 3rd line (2) of sprite pos
	inc PIPE_Y_IDX	; 

:loop	inc PIPE_Y_IDX	; remember this is the *2 table lookup	
	inc PIPE_Y_IDX
	ldy PIPE_Y_IDX
	cpy #44	; make sure we haven't hit bottom... pun intended
	beq :done
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	
	sta TXTPAGE2
	ldy PIPE_X_IDX
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	beq :l1_clip_break	
	lda 2*PIPE_WIDTH+PipeSpr_Aux,x ; line 2
	sta (DSTPTR),y
	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l1_loop
:l1_clip_break

	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l2_loop	cpy #PIPE_RCLIP
	beq :l2_clip_break	
	lda 2*PIPE_WIDTH+PipeSpr_Main,x ; line 2
	sta (DSTPTR),y
	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_clip_break sec
	bcs :loop

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
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
	
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
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y

	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_break	

*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
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
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y
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
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_break	

* Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
:doTop	jsr DrawPipeEvenT
	rts
:doBottom	jsr DrawPipeEvenB
	rts

DrawPipeOddL	
	jsr SetPipeCapPtrs
	sta TXTPAGE1
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Main,x
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
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
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop

*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
:doTop	jsr DrawPipeOddT
	rts
:doBottom	jsr DrawPipeOddBL
	rts

DrawPipeOddBL
	inc PIPE_Y_IDX	; set to advance to 3rd line (2) of sprite pos
	inc PIPE_Y_IDX	; 

:loop	inc PIPE_Y_IDX	; remember this is the *2 table lookup	
	inc PIPE_Y_IDX
	ldy PIPE_Y_IDX
	cpy #44	; make sure we haven't hit bottom... pun intended
	beq :done
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	
	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_clip_skip
	lda 2*PIPE_WIDTH+PipeSpr_Main,x ; line 2
	sta (DSTPTR),y
:l1_clip_skip	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l1_loop
:l1_clip_break

	sta TXTPAGE2
	ldy PIPE_X_IDX
	iny	; THE MOST IMPORTANT INY EVAR!!! :P
	ldx #1
:l2_loop	cpy #PIPE_RCLIP
	bcs :l2_clip_skip
	lda 2*PIPE_WIDTH+PipeSpr_Aux,x ; line 2
	sta (DSTPTR),y
:l2_clip_skip	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_clip_break sec
	bcs :loop

:done	rts

DrawPipeEvenL	
	jsr SetPipeCapPtrs
	sta TXTPAGE2	
	ldy PIPE_X_IDX	; y= the x offset... yay dp indexing on 6502
	ldx #0
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_skip
	lda PipeSpr_Aux,x
	sta (DSTPTR),y
	lda PipeSpr_Aux+PIPE_WIDTH,x
	sta (DSTPTR2),y
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
	sta (DSTPTR),y
	lda PipeSpr_Main+PIPE_WIDTH,x
	sta (DSTPTR2),y
:l2_skip	iny	; can check this for clipping?
	inx
	inx	;\_ skip a col
	cpx #PIPE_WIDTH
	bcc :l2_loop


*** Handle body 
	lda PIPE_T_B	; TOP or BOTTOM ?
	bne :doBottom
	rts	; @TODO!!! starting with bottom
:doTop	jsr DrawPipeEvenT
	rts
:doBottom	jsr DrawPipeEvenBL
	rts


DrawPipeEvenBL
	inc PIPE_Y_IDX	; set to advance to 3rd line (2) of sprite pos
	inc PIPE_Y_IDX	; 

:loop	inc PIPE_Y_IDX	; remember this is the *2 table lookup	
	inc PIPE_Y_IDX
	ldy PIPE_Y_IDX
	cpy #44	; make sure we haven't hit bottom... pun intended
	beq :done
	lda LoLineTable,y
	sta DSTPTR
	lda LoLineTable+1,y
	sta DSTPTR+1	; pointer to line on screen
	
	sta TXTPAGE1
	ldy PIPE_X_IDX
	ldx #1
:l1_loop	cpy #PIPE_RCLIP
	bcs :l1_clip_skip
	lda 2*PIPE_WIDTH+PipeSpr_Main,x ; line 2
	sta (DSTPTR),y
:l1_clip_skip	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l1_loop
:l1_clip_break

	sta TXTPAGE2
	ldy PIPE_X_IDX
	ldx #0
:l2_loop	cpy #PIPE_RCLIP
	bcs :l2_clip_skip
	lda 2*PIPE_WIDTH+PipeSpr_Aux,x ; line 2
	sta (DSTPTR),y
:l2_clip_skip	iny
	inx
	inx
	cpx #PIPE_WIDTH
	bcc :l2_loop
:l2_clip_break sec
	bcs :loop

:done	rts


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
