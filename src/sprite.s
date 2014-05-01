SPRITE_X	db 0
SPRITE_Y	db 0	; BYTE,not pixel. gotta be, sorry
SPRITE_W	db 0
SPRITE_W_D2	db 0
SPRITE_H	db 0	; <- in bytes

SPRITE_MAIN	da 0
SPRITE_AUX	da 0
SPRITE_MASK   da 0
SPRITE_IMASK  da 0
SPRITE_COLLISION db 0
SPRITE_Y_IDX	dw 0
SPRITE_X_IDX  dw 0

SPRITE_SCREEN_P equz $00
SPRITE_MAIN_P equz $02
SPRITE_AUX_P	equz $04
SPRITE_MASK_P equz $FA
SPRITE_IMASK_P equz $FC

SPRITE_SCREEN_IDX db #$0
AUX_BG_COLOR	db #$BB
MAIN_BG_COLOR	db #$77

DELLINE2	db 0
*** MAKE IT WORK

BirdTest
	lda BIRD_X	;#30 (0-79)
	sta SPRITE_X
	lda BIRD_Y	;#10 (0-23)
	sta SPRITE_Y
	lda #5	;/2 value (we do two passes of 1/2... Aux/Main)
	sta SPRITE_W
	lda #3	;/2 value (must be byte aligned vertically
	sta SPRITE_H
	CopyPtr BIRD_WDN_MAIN;SPRITE_MAIN_P
	CopyPtr BIRD_WDN_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WDN_MASK;SPRITE_MASK_P
	CopyPtr BIRD_WDN_IMASK;SPRITE_IMASK_P
	jsr DrawSpriteBetter
	rts

* still does collision
DrawSpriteBetter
	lda #0 
	sta SPRITE_X_IDX
:drawLine	lda SPRITE_Y	;
	asl	; *2
	tay
	lda LoLineTable,y	; SET SCREEN LINE
	sta SPRITE_SCREEN_P
	lda LoLineTable+1,y
	sta SPRITE_SCREEN_P+1

	lda SPRITE_X		; ADD IN X OFFSET TO SCREEN POSITION
	clc                         ; I think the highest position is $f8
	adc SPRITE_SCREEN_P         ; eg- Line 18, col 40= $4f8
	sta SPRITE_SCREEN_P	; SHOULD NEVER CARRY?
			
			
	jsr DrawSpriteLineC
	inc SPRITE_Y
	dec SPRITE_H
	lda SPRITE_H
	bne :drawLine
	rts


DrawSpriteLineC
	lda DELLINE2
	beq :noTrip
	;brk $f0
:noTrip
	; EVEN COLS
DD_EVEN	lda #0
	sta SPRITE_SCREEN_IDX
	sta TXTPAGE2
	ldy SPRITE_X_IDX	; 
:lineLoop	lda (SPRITE_IMASK_P),y
	beq :noPixel

:collisionCheckDrawer
	ldy SPRITE_SCREEN_IDX	; GET SCREEN PIXELS
	lda (SPRITE_SCREEN_P),y
	pha		; SAVE -> STACK
	ldy SPRITE_X_IDX	; PREP Y INDEX
	cmp #$BB		; AUX BGCOLOR @TODO
	beq :noCollision
	and (SPRITE_IMASK_P),y	
	cmp #$B0
	beq :noCollision
	cmp #$0B
	beq :noCollision
	lda #1
	sta SPRITE_COLLISION
	;bne :doPixels		; BRA

:noCollision	
:doPixels	pla		; Y=SPRITE X   A=BG DATA
	and (SPRITE_MASK_P),y	; CUT OUT SPRITE IN BG DATA
	ora (SPRITE_AUX_P),y	; OVERLAY OUR SPRITE DATA
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y

:noPixel	inc SPRITE_X_IDX
	inc SPRITE_X_IDX
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W
	bcc :lineLoop

DD_ODD
	; ODD COLS
	inc SPRITE_X_IDX	; + 1 column offset
	lda SPRITE_X_IDX
	sec
	sbc SPRITE_W	; RESET DATA PTR
	sbc SPRITE_W	; *2 due to pixel skip
	sta SPRITE_X_IDX
	lda #0
	sta SPRITE_SCREEN_IDX
	sta TXTPAGE1
	ldy SPRITE_X_IDX	; 
:lineLoop	lda (SPRITE_IMASK_P),y
	beq :noPixel

:collisionCheckDrawer
	ldy SPRITE_SCREEN_IDX	; GET SCREEN PIXELS
	lda (SPRITE_SCREEN_P),y
	pha		; SAVE -> STACK
	ldy SPRITE_X_IDX	; PREP Y INDEX
	cmp #$77		; MAIN BGCOLOR @TODO
	beq :noCollision
	and (SPRITE_IMASK_P),y	
	cmp #$70
	beq :noCollision
	cmp #$07
	beq :noCollision
	lda #1
	sta SPRITE_COLLISION
	;bne :doPixels		; BRA

:noCollision	
:doPixels	pla		; Y=SPRITE X   A=BG DATA
	and (SPRITE_MASK_P),y	; CUT OUT SPRITE IN BG DATA
	ora (SPRITE_MAIN_P),y	; OVERLAY OUR SPRITE DATA
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y

:noPixel	inc SPRITE_X_IDX
	inc SPRITE_X_IDX
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W
	bcc :lineLoop
	dec SPRITE_X_IDX	; -1 column offset (for next row)
	lda #1
	sta DELLINE1
	rts




** Doesn't handle odd horizontal displacement, but vertical works.
DrawSpriteC  
	lda SPRITE_W
	lsr
	sta SPRITE_W_D2 ; /2 max loop index?  width/2
:yLoop	lda SPRITE_Y  ; 
	asl
	tay
	lda LoLineTable,y
	sta SPRITE_SCREEN_P
	lda LoLineTable+1,y
	sta SPRITE_SCREEN_P+1
	lda SPRITE_X
	lsr	; /2
	clc 
	adc SPRITE_SCREEN_P
	sta SPRITE_SCREEN_P
	bcc :noCarry
	inc SPRITE_SCREEN_P+1

:noCarry	
AUXDRAW	sta TXTPAGE2	; start with even pixels on aux
:passLoop	lda #0
	sta SPRITE_SCREEN_IDX
	tax	;\_ x/y = 0 
	tay	;/
:lineLoop	
	lda (SPRITE_IMASK_P),y
	beq :noPixel
	cmp #$FF
	beq :simpleCollision
:fancyCollision
	lda (SPRITE_SCREEN_P),y
	cmp #$BB	; AUX BCG
	beq :noSimpleCollision

	lda (SPRITE_SCREEN_P),y
	pha
	txa
	tay
	pla
	pha	; store one more time
	and (SPRITE_IMASK_P),y	
	cmp #$B0
	beq :noFancyCollision
	cmp #$0B
	beq :noFancyCollision
	lda #1
	sta SPRITE_COLLISION
:noFancyCollision
	pla
	and (SPRITE_MASK_P),y	;woops.. cut out sprite shape
	ora (SPRITE_AUX_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	sec
	bcs :nextPixel
:simpleCollision
	lda (SPRITE_SCREEN_P),y
	cmp #$BB	; AUX BCG
	beq :noSimpleCollision
	lda #1
	sta SPRITE_COLLISION
:noSimpleCollision
	txa
	tay
	lda (SPRITE_AUX_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
:noPixel
:nextPixel
	inx
	inx
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W_D2
	bcc :lineLoop

MAINDRAW	sta TXTPAGE1	; start with even pixels on aux
:passLoop	lda #1
	sta SPRITE_SCREEN_IDX
	tax	;\_ x/y = 0 
	ldy #1	; WE'RE OFFSET BY 1 NOW
	dec SPRITE_SCREEN_P ; adjust pointer for mistake
	;tay	;/
:lineLoop	
	lda (SPRITE_IMASK_P),y
	beq :noPixel
	cmp #$FF
	beq :simpleCollision
:fancyCollision
	lda (SPRITE_SCREEN_P),y
	cmp #$77	; MAIN BCG
	beq :noSimpleCollision
	pha
	txa
	tay
	pla
	pha	; store one more time
	and (SPRITE_IMASK_P),y	
	cmp #$70
	beq :noFancyCollision
	cmp #$07
	beq :noFancyCollision
	lda #1
	sta SPRITE_COLLISION
:noFancyCollision
	pla
	and (SPRITE_MASK_P),y	;woops.. cut out sprite shape
	ora (SPRITE_MAIN_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	sec
	bcs :nextPixel
:simpleCollision
	lda (SPRITE_SCREEN_P),y
	cmp #$77	; AUX BCG
	beq :noSimpleCollision
	lda #1
	sta SPRITE_COLLISION
:noSimpleCollision
	txa
	tay
	lda (SPRITE_MAIN_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
:noPixel
:nextPixel
	inx
	inx
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W_D2
	bcc :lineLoop

	lda SPRITE_COLLISION
	sta $c034
	rts

