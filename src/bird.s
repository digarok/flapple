
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
SPRITE_DATA_P equz $02
SPRITE_SCREEN_P2 equz $02
SPRITE_AUX_P	equz $04
SPRITE_SCREEN_P3 equz $04
SPRITE_MASK_P equz $FA
SPRITE_SCREEN_P4 equz $FA
SPRITE_IMASK_P equz $FC

SPRITE_SCREEN_IDX db #$0


BIRD_X	equ #17
BIRD_Y_INIT	equ #17
BIRD_Y	db #BIRD_Y_INIT	; (0-47)
BIRD_Y_OLD	db #BIRD_Y_INIT	; used for undraw - to decouple input routine from sequence
BIRD_FLAP	db #0	; 0=down 1=up
BIRD_FLAP_RATE equ #5
BIRD_FLAP_CNT	db 0

**

FlapBird	
	inc BIRD_FLAP_CNT
	lda BIRD_FLAP_CNT
	cmp #BIRD_FLAP_RATE
	bcs :flapIt
	rts
:flapIt	
	lda #0
	sta BIRD_FLAP_CNT
	inc BIRD_FLAP
	lda BIRD_FLAP
	cmp #2
	bne :noFlip
	lda #0
	sta BIRD_FLAP
:noFlip	rts


***** EVEN then ODD, i.e. AUX then MAIN
BIRD_WUP_E_PIXEL
	DO MONO
	hex 00,EA,EA,FF,F0,50,D5,A5,0F,00
	hex AA,EA,EE,CF,CF,D5,55,8A,90,90
	hex 05,AD,A4,08,08,05,5D,51,01,00
	ELSE
	hex BB,EA,EA,FF,FB,57,D5,A5,0F,77
	hex AA,EA,EE,CF,CF,D5,55,8A,90,97
	hex B5,AD,A4,B8,B8,75,5D,51,71,77
	FIN

BIRD_WUP_E_MASK
	hex FF,00,00,00,0F,0F,00,00,00,FF
	hex 00,00,00,00,00,00,00,00,00,0F
	hex F0,00,00,F0,F0,F0,00,00,F0,FF


BIRD_WUP_E_IMASK
	hex 00,FF,FF,FF,F0,F0,FF,FF,FF,00
	hex FF,FF,FF,FF,FF,FF,FF,FF,FF,F0
	hex 0F,FF,FF,0F,0F,0F,FF,FF,0F,00

***** EVEN then ODD, i.e. AUX then MAIN
BIRD_WDN_E_PIXEL
	DO MONO
	 hex 00,EA,EA,FF,F0,50,D5,A5,0F,00
	 hex AA,EE,EE,CF,CF,DD,5D,8A,90,90
	 hex 54,AE,A4,08,08,5D,55,51,01,00
	ELSE
	 hex BB,EA,EA,FF,FB,57,D5,A5,0F,77
	 hex AA,EE,EE,CF,CF,DD,5D,8A,90,97
	 hex 54,AE,A4,B8,B8,5D,55,51,71,77
	FIN

BIRD_WDN_E_MASK
	 hex FF,00,00,00,0F,0F,00,00,00,FF
	 hex 00,00,00,00,00,00,00,00,00,0F
	 hex 00,00,00,F0,F0,00,00,00,F0,FF


BIRD_WDN_E_IMASK
	 hex 00,FF,FF,FF,F0,F0,FF,FF,FF,00
	 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,F0
	 hex FF,FF,FF,0F,0F,FF,FF,FF,0F,00

	
***** EVEN then ODD, i.e. AUX then MAIN
BIRD_WUP_O_PIXEL
	DO MONO
	 hex 00,A0,A0,F0,00,00,50,50,F0,00
	 hex A0,AE,EE,FF,FF,55,5D,AA,00,00
	 hex 5A,DE,4E,8C,8C,5D,D5,18,19,09
	 hex 00,0A,0A,00,00,00,05,05,00,00
	ELSE
	 hex BB,AB,AB,FB,BB,77,57,57,F7,77
	 hex AB,AE,EE,FF,FF,55,5D,AA,00,77
	 hex 5A,DE,4E,8C,8C,5D,D5,18,19,79
	 hex BB,BA,BA,BB,BB,77,75,75,77,77

	FIN

BIRD_WUP_O_MASK
	 hex FF,0F,0F,0F,FF,FF,0F,0F,0F,FF
	 hex 0F,00,00,00,00,00,00,00,00,FF
	 hex 00,00,00,00,00,00,00,00,00,F0
	 hex FF,F0,F0,FF,FF,FF,F0,F0,FF,FF


BIRD_WUP_O_IMASK
	 hex 00,F0,F0,F0,00,00,F0,F0,F0,00
	 hex F0,FF,FF,FF,FF,FF,FF,FF,FF,00
	 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,0F
	 hex 00,0F,0F,00,00,00,0F,0F,00,00


***** EVEN then ODD, i.e. AUX then MAIN
BIRD_WDN_O_PIXEL
	DO MONO
	 hex 00,A0,A0,F0,00,00,50,50,F0,00
	 hex A0,EE,EE,FF,FF,D5,DD,AA,00,00
	 hex 4A,EE,4E,8C,8C,DD,55,18,19,09
	 hex 05,0A,0A,00,00,05,05,05,00,00
	ELSE
	 hex BB,AB,AB,FB,BB,77,57,57,F7,77
	 hex AB,EE,EE,FF,FF,D5,DD,AA,00,77
	 hex 4A,EE,4E,8C,8C,DD,55,18,19,79
	 hex B5,BA,BA,BB,BB,75,75,75,77,77
	FIN

BIRD_WDN_O_MASK
	 hex FF,0F,0F,0F,FF,FF,0F,0F,0F,FF
	 hex 0F,00,00,00,00,00,00,00,00,FF
	 hex 00,00,00,00,00,00,00,00,00,F0
	 hex F0,F0,F0,FF,FF,F0,F0,F0,FF,FF


BIRD_WDN_O_IMASK
	 hex 00,F0,F0,F0,00,00,F0,F0,F0,00
	 hex F0,FF,FF,FF,FF,FF,FF,FF,FF,00
	 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,0F
	 hex 0F,0F,0F,00,00,0F,0F,0F,00,00

** y=line   a=height  x=col
UndrawBird	lda BIRD_Y_OLD
	lsr
	tay
	bne :oddBird
:evenBird	lda #3
	bne :continue
:oddBird	lda #4
:continue	ldx #BIRD_X
	cmp #4
	beq :undraw4
:undraw3	lda LoLineTableL,y
	sta SPRITE_SCREEN_P
	lda LoLineTableH,y
	sta SPRITE_SCREEN_P+1
	lda LoLineTableL+1,y
	sta SPRITE_SCREEN_P2
	lda LoLineTableH+1,y
	sta SPRITE_SCREEN_P2+1
	lda LoLineTableL+2,y
	sta SPRITE_SCREEN_P3
	lda LoLineTableH+2,y
	sta SPRITE_SCREEN_P3+1

	txa 
	pha	; stash
	tay	; COL offset
	sta TXTPAGE2
	lda #BGCOLORAUX
:wipe1	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe1b	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe1c	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe1d	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe1e	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y

	pla	; unstash
	tay
	sta TXTPAGE1
	lda #BGCOLOR
:wipe2	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny

:wipe2b	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe2c	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe2d	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
:wipe2e	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	rts




:undraw4	lda LoLineTableL,y
	sta SPRITE_SCREEN_P
	lda LoLineTableH,y
	sta SPRITE_SCREEN_P+1
	lda LoLineTableL+1,y
	sta SPRITE_SCREEN_P2
	lda LoLineTableH+1,y
	sta SPRITE_SCREEN_P2+1
	lda LoLineTableL+2,y
	sta SPRITE_SCREEN_P3
	lda LoLineTableH+2,y
	sta SPRITE_SCREEN_P3+1
	lda LoLineTableL+3,y
	sta SPRITE_SCREEN_P4
	lda LoLineTableH+3,y
	sta SPRITE_SCREEN_P4+1

	txa 
	pha	; stash
	tay	; COL offset
	sta TXTPAGE2
	lda #BGCOLORAUX
:wipe3	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe3b	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe3c	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe3d	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe3e	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y

	pla	; unstash
	tay
	sta TXTPAGE1
	lda #BGCOLOR
:wipe4	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe4b	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe4c	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe4d	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
:wipe4e	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	rts

DrawBird
	lda BIRD_Y
	lsr
	bcs :oddHeight
:evenHeight	
	sta SPRITE_Y
	lda #3
	sta SPRITE_H
	lda BIRD_FLAP
	beq :flapDownEven
:flapUpEven	CopyPtr BIRD_WUP_E_PIXEL;SPRITE_DATA_P
	CopyPtr BIRD_WUP_E_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WUP_E_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:flapDownEven	CopyPtr BIRD_WDN_E_PIXEL;SPRITE_DATA_P
	CopyPtr BIRD_WDN_E_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WDN_E_IMASK;SPRITE_IMASK_P
	jmp :drawSprite

:oddHeight	
	sta SPRITE_Y
	lda #4
	sta SPRITE_H
	lda BIRD_FLAP
	beq :flapDownOdd
:flapUpOdd	CopyPtr BIRD_WUP_O_PIXEL;SPRITE_DATA_P
	CopyPtr BIRD_WUP_O_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WUP_O_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:flapDownOdd	CopyPtr BIRD_WDN_O_PIXEL;SPRITE_DATA_P
	CopyPtr BIRD_WDN_O_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WDN_O_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:drawSprite
	jsr DrawSpriteBetter
	rts

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
;	CopyPtr BIRD_WDN_MAIN;SPRITE_MAIN_P
;	CopyPtr BIRD_WDN_AUX;SPRITE_AUX_P
;	CopyPtr BIRD_WDN_MASK;SPRITE_MASK_P
;	CopyPtr BIRD_WDN_IMASK;SPRITE_IMASK_P
	jsr DrawSpriteBetter
	rts

* still does collision
DrawSpriteBetter
	lda #0 
	sta SPRITE_X_IDX
:drawLine	lda SPRITE_Y	;
	tay
	lda LoLineTableL,y	; SET SCREEN LINE
	sta SPRITE_SCREEN_P
	lda LoLineTableH,y
	sta SPRITE_SCREEN_P+1

	lda #BIRD_X ;SPRITE_X		; ADD IN X OFFSET TO SCREEN POSITION
	clc                         ; I think the highest position is $f8
	adc SPRITE_SCREEN_P         ; eg- Line 18, col 40= $4f8
	sta SPRITE_SCREEN_P	; SHOULD NEVER CARRY?
			
			
	jmp DrawSpriteLineC
]DSLCD_done
	inc SPRITE_Y
	dec SPRITE_H
	lda SPRITE_H
	bne :drawLine
	rts


DrawSpriteLineC
	; EVEN COLS
DD_EVEN	lda #0
	sta SPRITE_SCREEN_IDX
	sta TXTPAGE2
	
:lineLoop	

:collisionCheckDrawer
	ldy SPRITE_SCREEN_IDX	; GET SCREEN PIXELS
	lda (SPRITE_SCREEN_P),y

	ldy SPRITE_X_IDX	; PREP Y INDEX
	cmp #BGCOLORAUX	; AUX BGCOLOR @TODO
	beq :noCollisionSIMPLE
	pha		; SAVE -> STACK
	and (SPRITE_IMASK_P),y	
	cmp #BGCOLORAUX_0LO
	beq :noCollision
	cmp #BGCOLORAUX_0HI
	beq :noCollision
	lda #1
	sta SPRITE_COLLISION
:noCollision
:doPixels	pla		; Y=SPRITE X   A=BG DATA
	and (SPRITE_MASK_P),y	; CUT OUT SPRITE IN BG DATA
	ora (SPRITE_DATA_P),y	; OVERLAY OUR SPRITE DATA
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	sec
	bcs :donePixel

:noCollisionSIMPLE
	lda (SPRITE_DATA_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	

:donePixel	inc SPRITE_X_IDX
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W
	bcc :lineLoop

DD_ODD
	; ODD COLS
	lda #0
	sta SPRITE_SCREEN_IDX
	sta TXTPAGE1
	
:lineLoop	;ldy SPRITE_X_IDX	; 
	;lda (SPRITE_IMASK_P),y
	;beq :noPixel

:collisionCheckDrawer
	ldy SPRITE_SCREEN_IDX	; GET SCREEN PIXELS
	lda (SPRITE_SCREEN_P),y
	ldy SPRITE_X_IDX	; PREP Y INDEX
	cmp #BGCOLOR		; MAIN BGCOLOR @TODO
	beq :noCollisionSIMPLE
	pha		; SAVE -> STACK
	and (SPRITE_IMASK_P),y	
	cmp #BGCOLOR_0LO
	beq :noCollision
	cmp #BGCOLOR_0HI
	beq :noCollision
	lda #1
	sta SPRITE_COLLISION

:noCollision	
:doPixels	pla		; Y=SPRITE X   A=BG DATA
	and (SPRITE_MASK_P),y	; CUT OUT SPRITE IN BG DATA
	ora (SPRITE_DATA_P),y	; OVERLAY OUR SPRITE DATA
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	sec
	bcs :donePixel

:noCollisionSIMPLE
	lda (SPRITE_DATA_P),y
	ldy SPRITE_SCREEN_IDX
	sta (SPRITE_SCREEN_P),y
	

:donePixel	inc SPRITE_X_IDX
	inc SPRITE_SCREEN_IDX
	ldy SPRITE_SCREEN_IDX
	cpy SPRITE_W
	bcc :lineLoop


	jmp ]DSLCD_done

