BIRD_X	db #17	; (0-79)
BIRD_Y	db #15	; (0-47)
BIRD_FLAP	db #0	; 0=down 1=up
BIRD_FLAP_RATE equ #3
BIRD_FLAP_CNT	db 0

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
:noFlip
	rts

*** "Even" / base sprites
	ds \
BIRD_WDN_MAIN
 hex 00,50,D5,D5,D5,A5,FF,0F,F0,00
 hex 55,DD,DD,5D,DD,8A,9F,90,9F,90
 hex A8,5D,5D,55,58,51,01,01,01,00


BIRD_WDN_AUX
 hex 00,A0,EA,EA,EA,5A,FF,0F,F0,00
 hex AA,EE,EE,AE,EE,45,CF,C0,CF,C0
 hex 54,AE,AE,AA,A4,A8,08,08,08,00


BIRD_WDN_MASK
 hex FF,0F,00,00,00,00,00,00,0F,FF
 hex 00,00,00,00,00,00,00,00,00,0F
 hex 00,00,00,00,00,00,F0,F0,F0,FF


BIRD_WDN_IMASK
 hex 00,F0,FF,FF,FF,FF,FF,FF,F0,00
 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,F0
 hex FF,FF,FF,FF,FF,FF,0F,0F,0F,00


BIRD_WUP_MAIN
 hex 00,50,D5,D5,D5,A5,FF,0F,F0,00
 hex 55,D5,D5,55,DD,8A,9F,90,9F,90
 hex 0A,05,5B,5D,58,51,01,01,01,00

	ds \
BIRD_WUP_AUX
 hex 00,A0,EA,EA,EA,5A,FF,0F,F0,00
 hex AA,EA,EA,AA,EE,45,CF,C0,CF,C0
 hex 05,0A,AD,AE,A4,A8,08,08,08,00


BIRD_WUP_MASK
 hex FF,0F,00,00,00,00,00,00,0F,FF
 hex 00,00,00,00,00,00,00,00,00,0F
 hex F0,F0,00,00,00,00,F0,F0,F0,FF


BIRD_WUP_IMASK
 hex 00,F0,FF,FF,FF,FF,FF,FF,F0,00
 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,F0
 hex 0F,0F,FF,FF,FF,FF,0F,0F,0F,00



*** "Odd" / shifted sprites
BIRD_WDN_O_MAIN
 hex 00,00,50,50,50,50,F0,F0,00,00
 hex 50,D5,DD,DD,DD,AA,FF,00,FF,00
 hex 85,DD,DD,55,8D,18,19,19,19,09
 hex 0A,05,05,05,05,05,00,00,00,00


BIRD_WDN_O_AUX
 hex 00,00,A0,A0,A0,A0,F0,F0,00,00
 hex A0,EA,EE,EE,EE,55,FF,00,FF,00
 hex 4A,EE,EE,AA,4E,84,8C,8C,8C,0C
 hex 05,0A,0A,0A,0A,0A,00,00,00,00


BIRD_WDN_O_MASK
 hex FF,FF,0F,0F,0F,0F,0F,0F,FF,FF
 hex 0F,00,00,00,00,00,00,00,00,FF
 hex 00,00,00,00,00,00,00,00,00,F0
 hex F0,F0,F0,F0,F0,F0,FF,FF,FF,FF


BIRD_WDN_O_IMASK
 hex 00,00,F0,F0,F0,F0,F0,F0,00,00
 hex F0,FF,FF,FF,FF,FF,FF,FF,FF,00
 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,0F
 hex 0F,0F,0F,0F,0F,0F,00,00,00,00

BIRD_WUP_O_MAIN
 hex 00,00,50,50,50,50,F0,F0,00,00
 hex 50,55,5D,5D,DD,AA,FF,00,FF,00
 hex A5,5D,BD,D5,8D,18,19,19,19,09
 hex 00,00,05,05,05,05,00,00,00,00


BIRD_WUP_O_AUX
 hex 00,00,A0,A0,A0,A0,F0,F0,00,00
 hex A0,AA,AE,AE,EE,55,FF,00,FF,00
 hex 5A,AE,DE,EA,4E,84,8C,8C,8C,0C
 hex 00,00,0A,0A,0A,0A,00,00,00,00


BIRD_WUP_O_MASK
 hex FF,FF,0F,0F,0F,0F,0F,0F,FF,FF
 hex 0F,00,00,00,00,00,00,00,00,FF
 hex 00,00,00,00,00,00,00,00,00,F0
 hex FF,FF,F0,F0,F0,F0,FF,FF,FF,FF


BIRD_WUP_O_IMASK
 hex 00,00,F0,F0,F0,F0,F0,F0,00,00
 hex F0,FF,FF,FF,FF,FF,FF,FF,FF,00
 hex FF,FF,FF,FF,FF,FF,FF,FF,FF,0F
 hex 00,00,0F,0F,0F,0F,00,00,00,00


** y=line   a=height  x=col
UndrawBird	lda BIRD_Y
	lsr
	tay
	bne :oddBird
:evenBird	lda #3
	bne :continue
:oddBird	lda #4
:continue	ldx BIRD_X
	cmp #4
	beq :undraw4
:undraw3	tya	; we don't need height anymore, trash it	
	asl
	tay
	lda LoLineTable,y
	sta SPRITE_SCREEN_P
	lda LoLineTable+1,y
	sta SPRITE_SCREEN_P+1
	lda LoLineTable+2,y
	sta SPRITE_SCREEN_P2
	lda LoLineTable+3,y
	sta SPRITE_SCREEN_P2+1
	lda LoLineTable+4,y
	sta SPRITE_SCREEN_P3
	lda LoLineTable+5,y
	sta SPRITE_SCREEN_P3+1

	txa 
	pha	; stash
	tay	; COL offset
	ldx #5	; TERMINATOR index
	sta TXTPAGE2
	lda #$BB
:wipe1	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
	dex
	bne :wipe1
	pla	; unstash
	tay
	ldx #5
	sta TXTPAGE1
	lda #$77
:wipe2	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	iny
	dex
	bne :wipe2
	rts



:undraw4	tya	; we don't need height anymore, trash it	
	asl
	tay
	lda LoLineTable,y
	sta SPRITE_SCREEN_P
	lda LoLineTable+1,y
	sta SPRITE_SCREEN_P+1
	lda LoLineTable+2,y
	sta SPRITE_SCREEN_P2
	lda LoLineTable+3,y
	sta SPRITE_SCREEN_P2+1
	lda LoLineTable+4,y
	sta SPRITE_SCREEN_P3
	lda LoLineTable+5,y
	sta SPRITE_SCREEN_P3+1
	lda LoLineTable+6,y
	sta SPRITE_SCREEN_P4
	lda LoLineTable+7,y
	sta SPRITE_SCREEN_P4+1

	txa 
	pha	; stash
	tay	; COL offset
	ldx #5	; TERMINATOR index
	sta TXTPAGE2
	lda #$BB
:wipe3	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
	dex
	bne :wipe3
	pla	; unstash
	tay
	ldx #5
	sta TXTPAGE1
	lda #$77
:wipe4	sta (SPRITE_SCREEN_P),y
	sta (SPRITE_SCREEN_P2),y
	sta (SPRITE_SCREEN_P3),y
	sta (SPRITE_SCREEN_P4),y
	iny
	dex
	bne :wipe4
	rts

DrawBird
	lda BIRD_X
	sta SPRITE_X
	lda #5
	sta SPRITE_W	; all birds are same width

	lda BIRD_Y
	lsr
	bcs :oddHeight
:evenHeight	
	sta SPRITE_Y
	lda #3
	sta SPRITE_H
	lda BIRD_FLAP
	beq :flapDownEven
:flapUpEven	CopyPtr BIRD_WUP_MAIN;SPRITE_MAIN_P
              CopyPtr BIRD_WUP_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WUP_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WUP_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:flapDownEven	CopyPtr BIRD_WDN_MAIN;SPRITE_MAIN_P
              CopyPtr BIRD_WDN_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WDN_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WDN_IMASK;SPRITE_IMASK_P
	jmp :drawSprite

:oddHeight	
	sta SPRITE_Y
	lda #4
	sta SPRITE_H
	lda BIRD_FLAP
	beq :flapDownOdd
:flapUpOdd	CopyPtr BIRD_WUP_O_MAIN;SPRITE_MAIN_P
              CopyPtr BIRD_WUP_O_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WUP_O_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WUP_O_IMASK;SPRITE_IMASK_P
:TEST1	CopyPtr BIRD_WDN_O_MAIN;SPRITE_MAIN_P
              CopyPtr BIRD_WDN_O_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WDN_O_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WDN_O_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:flapDownOdd	CopyPtr BIRD_WDN_O_MAIN;SPRITE_MAIN_P
              CopyPtr BIRD_WDN_O_AUX;SPRITE_AUX_P
	CopyPtr BIRD_WDN_O_MASK;SPRITE_MASK_P
              CopyPtr BIRD_WDN_O_IMASK;SPRITE_IMASK_P
	jmp :drawSprite
:drawSprite
	jsr DrawSpriteBetter
	rts 

