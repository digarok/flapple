SPRITE_X          db    0
SPRITE_Y          db    0                       ; BYTE,not pixel. gotta be, sorry
SPRITE_W          db    0
SPRITE_W_D2       db    0
SPRITE_H          db    0                       ; <- in bytes

SPRITE_MAIN       da    0
SPRITE_AUX        da    0
SPRITE_MASK       da    0
SPRITE_IMASK      da    0
SPRITE_COLLISION  db    0
SPRITE_Y_IDX      dw    0
SPRITE_X_IDX      dw    0

SPRITE_SCREEN_P   equz  $00
SPRITE_MAIN_P     equz  $02
SPRITE_SCREEN_P2  equz  $02
SPRITE_AUX_P      equz  $04
SPRITE_SCREEN_P3  equz  $04
SPRITE_MASK_P     equz  $FA
SPRITE_SCREEN_P4  equz  $FA
SPRITE_IMASK_P    equz  $FC

SPRITE_SCREEN_IDX db    #$0
AUX_BG_COLOR      db    #$BB
MAIN_BG_COLOR     db    #$77

* still does collision
DrawSpriteBetter
                  lda   #0
                  sta   SPRITE_X_IDX
:drawLine         lda   SPRITE_Y                ;
                  tay
                  lda   LoLineTableL,y          ; SET SCREEN LINE
                  sta   SPRITE_SCREEN_P
                  lda   LoLineTableH,y
                  sta   SPRITE_SCREEN_P+1

                  lda   SPRITE_X                ; ADD IN X OFFSET TO SCREEN POSITION
                  clc                           ; I think the highest position is $f8
                  adc   SPRITE_SCREEN_P         ; eg- Line 18, col 40= $4f8
                  sta   SPRITE_SCREEN_P         ; SHOULD NEVER CARRY?


                  jmp   DrawSpriteLineC
]DSLCD_done
                  inc   SPRITE_Y
                  dec   SPRITE_H
                  lda   SPRITE_H
                  bne   :drawLine
                  rts


DrawSpriteLineC
                                                ; EVEN COLS
DD_EVEN           lda   #0
                  sta   SPRITE_SCREEN_IDX
                  sta   TXTPAGE2

:lineLoop
                                                ;ldy SPRITE_X_IDX	;
                                                ;lda (SPRITE_IMASK_P),y
                                                ;beq :noPixel

:collisionCheckDrawer
                  ldy   SPRITE_SCREEN_IDX       ; GET SCREEN PIXELS
                  lda   (SPRITE_SCREEN_P),y
                  pha                           ; SAVE -> STACK
                  ldy   SPRITE_X_IDX            ; PREP Y INDEX
                  cmp   #$BB                    ; AUX BGCOLOR @TODO
                  beq   :noCollision
                  and   (SPRITE_IMASK_P),y
                  cmp   #$B0
                  beq   :noCollision
                  cmp   #$0B
                  beq   :noCollision
                  lda   #1
                  sta   SPRITE_COLLISION
                  sta   $c034

:noCollision
:doPixels         pla                           ; Y=SPRITE X   A=BG DATA
                  and   (SPRITE_MASK_P),y       ; CUT OUT SPRITE IN BG DATA
                  ora   (SPRITE_AUX_P),y        ; OVERLAY OUR SPRITE DATA
                  ldy   SPRITE_SCREEN_IDX
                  sta   (SPRITE_SCREEN_P),y

:noPixel          inc   SPRITE_X_IDX
                  inc   SPRITE_X_IDX
                  inc   SPRITE_SCREEN_IDX
                  ldy   SPRITE_SCREEN_IDX
                  cpy   SPRITE_W
                  bcc   :lineLoop

DD_ODD
                                                ; ODD COLS
                  inc   SPRITE_X_IDX            ; + 1 column offset
                  lda   SPRITE_X_IDX
                  sec
                  sbc   SPRITE_W                ; RESET DATA PTR
                  sbc   SPRITE_W                ; *2 due to pixel skip
                  sta   SPRITE_X_IDX
                  lda   #0
                  sta   SPRITE_SCREEN_IDX
                  sta   TXTPAGE1

:lineLoop                                       ;ldy SPRITE_X_IDX	;
                                                ;lda (SPRITE_IMASK_P),y
                                                ;beq :noPixel

:collisionCheckDrawer
                  ldy   SPRITE_SCREEN_IDX       ; GET SCREEN PIXELS
                  lda   (SPRITE_SCREEN_P),y
                  pha                           ; SAVE -> STACK
                  ldy   SPRITE_X_IDX            ; PREP Y INDEX
                  cmp   #$77                    ; MAIN BGCOLOR @TODO
                  beq   :noCollision
                  and   (SPRITE_IMASK_P),y
                  cmp   #$70
                  beq   :noCollision
                  cmp   #$07
                  beq   :noCollision
                  lda   #1
                  sta   SPRITE_COLLISION
                  sta   $c034

:noCollision
:doPixels         pla                           ; Y=SPRITE X   A=BG DATA
                  and   (SPRITE_MASK_P),y       ; CUT OUT SPRITE IN BG DATA
                  ora   (SPRITE_MAIN_P),y       ; OVERLAY OUR SPRITE DATA
                  ldy   SPRITE_SCREEN_IDX
                  sta   (SPRITE_SCREEN_P),y

:noPixel          inc   SPRITE_X_IDX
                  inc   SPRITE_X_IDX
                  inc   SPRITE_SCREEN_IDX
                  ldy   SPRITE_SCREEN_IDX
                  cpy   SPRITE_W
                  bcc   :lineLoop
                  dec   SPRITE_X_IDX            ; -1 column offset (for next row)

                  jmp   ]DSLCD_done


