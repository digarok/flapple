
LOGO_Y            db    1
LOGO_X            db    3
LOGO_CURLINE      db    0

SPR_SP            equ   $00
SPR_DP            equ   $02
SPR_PIXEL         db    00
SPR_MASKCOLOR     db    0
SPR_MASKCOLORH    db    0
SPR_MASKCOLORL    db    0
SPR_X             db    0
SPR_Y             db    0

SPR_CURLINE       db    0
SPR_WIDTH         db    0
SPR_HEIGHT        db    0

SPR_Y_STASH       db    0                       ;used by big number routines



DL_SetDLRMode     lda   LORES                   ;set lores
                  lda   SETAN3                  ;enables DLR
                  sta   SET80VID

                  sta   C80STOREON              ; enable aux/page1,2 mapping
                  sta   MIXCLR                  ;make sure graphics-only mode
                  rts
DL_SetDLRMixMode  lda   LORES                   ;set lores
                  lda   SETAN3                  ;enables DLR
                  sta   SET80VID

                  sta   C80STOREON              ; enable aux/page1,2 mapping
                  sta   MIXSET                  ;turn on mixed text/graphics mode
                  rts

DL_MixClearText   sta   TXTPAGE1
                  ldx   #40
:loop             dex
                  sta   Lo24,x
                  sta   Lo23,x
                  sta   Lo22,x
                  sta   Lo21,x
                  bne   :loop
                  sta   TXTPAGE2
                  ldx   #40
:loop2            dex
                  sta   Lo24,x
                  sta   Lo23,x
                  sta   Lo22,x
                  sta   Lo21,x
                  bne   :loop2
                  rts


** A = lo-res color byte
DL_Clear          sta   TXTPAGE1
                  ldx   #40
:loop             dex
                  sta   Lo01,x
                  sta   Lo02,x
                  sta   Lo03,x
                  sta   Lo04,x
                  sta   Lo05,x
                  sta   Lo06,x
                  sta   Lo07,x
                  sta   Lo08,x
                  sta   Lo09,x
                  sta   Lo10,x
                  sta   Lo11,x
                  sta   Lo12,x
                  sta   Lo13,x
                  sta   Lo14,x
                  sta   Lo15,x
                  sta   Lo16,x
                  sta   Lo17,x
                  sta   Lo18,x
                  sta   Lo19,x
                  sta   Lo20,x
                  sta   Lo21,x
                  sta   Lo22,x
                  sta   Lo23,x
                  sta   Lo24,x
                  bne   :loop
                  tax                           ; get aux color value
                  lda   MainAuxMap,x
                  sta   TXTPAGE2                ; turn on p2
                  ldx   #40
:loop2            dex
                  sta   Lo01,x
                  sta   Lo02,x
                  sta   Lo03,x
                  sta   Lo04,x
                  sta   Lo05,x
                  sta   Lo06,x
                  sta   Lo07,x
                  sta   Lo08,x
                  sta   Lo09,x
                  sta   Lo10,x
                  sta   Lo11,x
                  sta   Lo12,x
                  sta   Lo13,x
                  sta   Lo14,x
                  sta   Lo15,x
                  sta   Lo16,x
                  sta   Lo17,x
                  sta   Lo18,x
                  sta   Lo19,x
                  sta   Lo20,x
                  sta   Lo21,x
                  sta   Lo22,x
                  sta   Lo23,x
                  sta   Lo24,x
                  bne   :loop2
                  rts

** A = lo-res color byte  Y = line byte (0-23)
DL_HLine          tax
                  lda   LoLineTableL,y
                  sta   SPR_DP
                  lda   LoLineTableH,y
                  sta   SPR_DP+1
                  txa

                  sta   TXTPAGE1
                  ldy   #39
:loopMain         sta   (SPR_DP),y
                  dey
                  bpl   :loopMain

                  sta   TXTPAGE2
                  tax
                  lda   MainAuxMap,x
                  ldy   #39
:loopAux          sta   (SPR_DP),y
                  dey
                  bpl   :loopAux
                  rts

* A X Y = 0 1 2 ??
DL_WipeLn0        db    0
DL_WipeLn1        db    0
DL_WipeLn2        db    0
DL_WipeLn0_I      db    0                       ; inverted patterns for bottom up
DL_WipeLn1_I      db    0
DL_WipeLn2_I      db    0
DL_WipeCnt        db    0
DL_WipeDelay      db    #4
DL_NibSwap
                  asl                           ; nibble swap
                  rol
                  rol
                  rol
                  sta   $00
                  and   #07
                  adc   $00
                  rts
DL_WipeInNoNib
                  sty   DL_WipeLn2              ; set up color bytes to write
                  sty   DL_WipeLn2_I
                  stx   DL_WipeLn1
                  stx   DL_WipeLn1_I
                  sta   DL_WipeLn0
                  sta   DL_WipeLn0_I
                  jmp   DL_WipeIt

DL_WipeIn
                  sty   DL_WipeLn2              ; set up color bytes to write
                  stx   DL_WipeLn1
                  sta   DL_WipeLn0
                  jsr   DL_NibSwap              ; and their A/B swapped equivalents
                  sta   DL_WipeLn0_I            ; for mirroring the lines below

                  lda   DL_WipeLn1
                  jsr   DL_NibSwap
                  sta   DL_WipeLn1_I

                  lda   DL_WipeLn2
                  jsr   DL_NibSwap
                  sta   DL_WipeLn2_I

DL_WipeIt
                  ldx   DL_WipeDelay
                  jsr   VBlankX                 ; Frame 1 - special case (clipped)
                  lda   DL_WipeLn0
                  ldy   #0
                  jsr   DL_HLine
                  lda   DL_WipeLn0_I
                  ldy   #23
                  jsr   DL_HLine

                  ldx   DL_WipeDelay
                  jsr   VBlankX                 ; Frame 2 - special case (clipped)
                  lda   DL_WipeLn0
                  ldy   #1
                  jsr   DL_HLine
                  lda   DL_WipeLn1
                  ldy   #0
                  jsr   DL_HLine

                  lda   DL_WipeLn0_I
                  ldy   #22
                  jsr   DL_HLine
                  lda   DL_WipeLn1_I
                  ldy   #23
                  jsr   DL_HLine

                  lda   #0
                  sta   DL_WipeCnt

:wiper            ldx   DL_WipeDelay
                  jsr   VBlankX
                  lda   DL_WipeLn2
                  ldy   DL_WipeCnt
                  jsr   DL_HLine
                  lda   DL_WipeLn1
                  ldy   DL_WipeCnt
                  iny
                  jsr   DL_HLine
                  lda   DL_WipeLn0
                  ldy   DL_WipeCnt
                  iny
                  iny
                  jsr   DL_HLine
                  lda   #23
                  sec
                  sbc   DL_WipeCnt
                  pha
                  pha
                  tay
                  lda   DL_WipeLn2_I
                  jsr   DL_HLine
                  pla
                  tay
                  dey
                  lda   DL_WipeLn1_I
                  jsr   DL_HLine
                  pla
                  tay
                  dey
                  dey
                  lda   DL_WipeLn0_I
                  jsr   DL_HLine
                  inc   DL_WipeCnt
                  lda   DL_WipeCnt
                  cmp   #10
                  bne   :wiper


                  ldx   DL_WipeDelay
                  jsr   VBlankX                 ; Frame end-1 - special case (smashed)
                  lda   DL_WipeLn2
                  ldy   #10
                  jsr   DL_HLine
                  lda   DL_WipeLn1
                  ldy   #11
                  jsr   DL_HLine

                  lda   DL_WipeLn1_I
                  ldy   #12
                  jsr   DL_HLine
                  lda   DL_WipeLn2_I
                  ldy   #13
                  jsr   DL_HLine


                  ldx   DL_WipeDelay
                  jsr   VBlankX                 ; Frame end - special case (last fill line)
                  lda   DL_WipeLn2
                  ldy   #11
                  jsr   DL_HLine

                  lda   DL_WipeLn2_I
                  ldy   #12
                  jsr   DL_HLine
                  rts






**************************************************
* Lores/Text lines
**************************************************
Lo01              equ   $400
Lo02              equ   $480
Lo03              equ   $500
Lo04              equ   $580
Lo05              equ   $600
Lo06              equ   $680
Lo07              equ   $700
Lo08              equ   $780
Lo09              equ   $428
Lo10              equ   $4a8
Lo11              equ   $528
Lo12              equ   $5a8
Lo13              equ   $628
Lo14              equ   $6a8
Lo15              equ   $728
Lo16              equ   $7a8
Lo17              equ   $450
Lo18              equ   $4d0
Lo19              equ   $550
Lo20              equ   $5d0
* the "plus four" lines
Lo21              equ   $650
Lo22              equ   $6d0
Lo23              equ   $750
Lo24              equ   $7d0

LoLineTable       da    Lo01,Lo02,Lo03,Lo04,Lo05,Lo06
                  da    Lo07,Lo08,Lo09,Lo10,Lo11,Lo12
                  da    Lo13,Lo14,Lo15,Lo16,Lo17,Lo18
                  da    Lo19,Lo20,Lo21,Lo22,Lo23,Lo24
** Here we split the table for an optimization
** We can directly get our line numbers now
** Without using ASL
LoLineTableH      db    >Lo01,>Lo02,>Lo03,>Lo04,>Lo05,>Lo06
                  db    >Lo07,>Lo08,>Lo09,>Lo10,>Lo11,>Lo12
                  db    >Lo13,>Lo14,>Lo15,>Lo16,>Lo17,>Lo18
                  db    >Lo19,>Lo20,>Lo21,>Lo22,>Lo23,>Lo24
LoLineTableL      db    <Lo01,<Lo02,<Lo03,<Lo04,<Lo05,<Lo06
                  db    <Lo07,<Lo08,<Lo09,<Lo10,<Lo11,<Lo12
                  db    <Lo13,<Lo14,<Lo15,<Lo16,<Lo17,<Lo18
                  db    <Lo19,<Lo20,<Lo21,<Lo22,<Lo23,<Lo24

MainAuxMap
                  hex   00,08,01,09,02,0A,03,0B,04,0C,05,0D,06,0E,07,0F
                  hex   80,88,81,89,82,8A,83,8B,84,8C,85,8D,86,8E,87,8F
                  hex   10,18,11,19,12,1A,13,1B,14,1C,15,1D,16,1E,17,1F
                  hex   90,98,91,99,92,9A,93,9B,94,9C,95,9D,96,9E,97,9F
                  hex   20,28,21,29,22,2A,23,2B,24,2C,25,2D,26,2E,27,2F
                  hex   A0,A8,A1,A9,A2,AA,A3,AB,A4,AC,A5,AD,A6,AE,A7,AF
                  hex   30,38,31,39,32,3A,33,3B,34,3C,35,3D,36,3E,37,3F
                  hex   B0,B8,B1,B9,B2,BA,B3,BB,B4,BC,B5,BD,B6,BE,B7,BF
                  hex   40,48,41,49,42,4A,43,4B,44,4C,45,4D,46,4E,47,4F
                  hex   C0,C8,C1,C9,C2,CA,C3,CB,C4,CC,C5,CD,C6,CE,C7,CF
                  hex   50,58,51,59,52,5A,53,5B,54,5C,55,5D,56,5E,57,5F
                  hex   D0,D8,D1,D9,D2,DA,D3,DB,D4,DC,D5,DD,D6,DE,D7,DF
                  hex   60,68,61,69,62,6A,63,6B,64,6C,65,6D,66,6E,67,6F
                  hex   E0,E8,E1,E9,E2,EA,E3,EB,E4,EC,E5,ED,E6,EE,E7,EF
                  hex   70,78,71,79,72,7A,73,7B,74,7C,75,7D,76,7E,77,7F
                  hex   F0,F8,F1,F9,F2,FA,F3,FB,F4,FC,F5,FD,F6,FE,F7,FF


DrawQRCode        lda   #QRCodeMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<QRCodeData
                  sta   SPR_SP
                  lda   #>QRCodeData
                  sta   SPR_SP+1
                  lda   #QRCodeHeight
                  sta   SPR_HEIGHT
                  lda   #QRCodeWidth
                  sta   SPR_WIDTH
                  lda   #13                     ; @todo rename 'flogo'
                  sta   SPR_X
                  lda   #3
                  sta   SPR_Y
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

DrawFlogo         lda   #flogoMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<flogoData
                  sta   SPR_SP
                  lda   #>flogoData
                  sta   SPR_SP+1
                  lda   #flogoHeight
                  sta   SPR_HEIGHT
                  lda   #flogoWidth
                  sta   SPR_WIDTH
                  lda   LOGO_X                  ; @todo rename 'flogo'
                  sta   SPR_X
                  lda   LOGO_Y
                  sta   SPR_Y
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

DrawTap           lda   #tapMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<tapData
                  sta   SPR_SP
                  lda   #>tapData
                  sta   SPR_SP+1
                  lda   #tapHeight
                  sta   SPR_HEIGHT
                  lda   #tapWidth
                  sta   SPR_WIDTH
                  lda   #8
                  sta   SPR_X
                  lda   #16
                  sta   SPR_Y
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

DrawYou
                  sty   SPR_Y
                  lda   #youMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<youData
                  sta   SPR_SP
                  lda   #>youData
                  sta   SPR_SP+1
                  lda   #youHeight
                  sta   SPR_HEIGHT
                  lda   #youWidth
                  sta   SPR_WIDTH
                  lda   #13
                  sta   SPR_X
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

* y = Y
DrawHi
                  sty   SPR_Y
                  lda   #hiMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<hiData
                  sta   SPR_SP
                  lda   #>hiData
                  sta   SPR_SP+1
                  lda   #hiHeight
                  sta   SPR_HEIGHT
                  lda   #hiWidth
                  sta   SPR_WIDTH
                  lda   #13
                  sta   SPR_X
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

DrawHiScore
                  stx   SPR_X
                  sty   SPR_Y
                  sty   SPR_Y_STASH
                  lda   HiScoreHi
                  sta   DrawNumberHi
                  lda   HiScoreLo
                  sta   DrawNumberLo
                  jsr   DrawBigNumbersFancy
                  rts

DrawYouScore
                  stx   SPR_X
                  sty   SPR_Y
                  sty   SPR_Y_STASH
                  lda   ScoreHi
                  sta   DrawNumberHi
                  lda   ScoreLo
                  sta   DrawNumberLo
                  jsr   DrawBigNumbersFancy
                  rts

* Draws in natural format from 0 to 9999
DrawBigNumbersFancy
                  lda   #NumHeight
                  sta   SPR_HEIGHT
                  lda   #NumWidth
                  sta   SPR_WIDTH
                  lda   #NumMaskColor
                  sta   SPR_MASKCOLOR

                  lda   DrawNumberHi
                  bne   :hiDigits
                  lda   SPR_X
                  clc
                  adc   #NumWidth*2             ; skip two spaces
                  sta   SPR_X
                  bcc   :loDigits
:hiDigits
                  lsr
                  lsr
                  lsr
                  lsr
                  beq   :noThousandDigit
                  jsr   DrawBigNumber           ; draw "thousands" digit
:noThousandDigit  lda   SPR_X
                  clc
                  adc   #NumWidth               ; advance one space
                  sta   SPR_X
                  ldy   SPR_Y_STASH
                  sty   SPR_Y
                  lda   DrawNumberHi
                  and   #$0F
                  jsr   DrawBigNumber           ; draw "hundreds" digit
                  lda   SPR_X
                  clc
                  adc   #NumWidth               ; advance one space
                  sta   SPR_X
                  ldy   SPR_Y_STASH
                  sty   SPR_Y
:loDigits         lda   DrawNumberLo
                  lsr
                  lsr
                  lsr
                  lsr
                  beq   :tensZero
                  ldy   SPR_Y_STASH
                  sty   SPR_Y
                  jsr   DrawBigNumber           ; draw "tens" digit (1-9)
                  clc
                  bcc   :tensDone
:tensZero                                       ; we need to know if we drew anything above
                  lda   DrawNumberHi
                  beq   :noTensDigit
                  ldy   SPR_Y_STASH
                  sty   SPR_Y
                  lda   #0
                  jsr   DrawBigNumber           ; draw "tens" digit (0)
:noTensDigit
:tensDone
                  lda   SPR_X
                  clc
                  adc   #NumWidth
                  sta   SPR_X

                  ldy   SPR_Y_STASH
                  sty   SPR_Y
                  lda   DrawNumberLo
                  and   #$0F
                  jsr   DrawBigNumber
                  rts


DrawNumberHi      db    0
DrawNumberLo      db    0

* All params should be set prior to this.  Just pass digit (0-9) in A
DrawBigNumber
                  asl
                  tay
                  lda   NumList,y
                  sta   SPR_SP
                  lda   NumList+1,y
                  sta   SPR_SP+1
                  lda   #0
                  sta   SPR_CURLINE

                  jsr   DrawSprite
                  rts



DrawPlaqueShared
                  lda   #11
                  sta   SPR_X
                  lda   #plaqueMaskColor
                  sta   SPR_MASKCOLOR
                  lda   #<plaqueData
                  sta   SPR_SP
                  lda   #>plaqueData
                  sta   SPR_SP+1
                  lda   #plaqueHeight
                  sta   SPR_HEIGHT
                  lda   #plaqueWidth
                  sta   SPR_WIDTH
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts


DrawSplosion      lda   #splosionMaskColor
                  sta   SPR_MASKCOLOR

                  lda   #<splosionData
                  sta   SPR_SP
                  lda   #>splosionData
                  sta   SPR_SP+1
                  lda   #splosionHeight
                  sta   SPR_HEIGHT
                  lda   #splosionWidth
                  sta   SPR_WIDTH
                  lda   #BIRD_X
                  clc
                  adc   #2
                  sta   SPR_X
                  lda   BIRD_Y
                  lsr
                  sec
                  sbc   #1
                  sta   SPR_Y
                  lda   #0
                  sta   SPR_CURLINE
                  jsr   DrawSprite
                  rts

DrawSprite        lda   SPR_MASKCOLOR
                  and   #$F0
                  sta   SPR_MASKCOLORH
                  lsr
                  lsr
                  lsr
                  lsr
                  sta   SPR_MASKCOLORL
:lineLoop
                  ldy   SPR_CURLINE
                  cpy   SPR_HEIGHT              ;last line?
                  bcc   :doLine
                  rts                           ; !! ROUTINE ENDS HERE
:doLine           ldy   SPR_Y
                  lda   LoLineTableL,y
                  clc
                  adc   SPR_X                   ;; X OFFSET
                  sta   SPR_DP
                  lda   LoLineTableH,y
                  sta   SPR_DP+1
                  sta   TXTPAGE2
                  ldy   #$0
:auxLoop
                  lda   (SPR_SP),y
                  cmp   SPR_MASKCOLOR
                  beq   :auxNoData
                  and   #$F0
                  cmp   SPR_MASKCOLORH
                  bne   :auxNoMask1
                  lda   (SPR_DP),y
                  and   #$F0
                  sta   SPR_PIXEL
                  lda   (SPR_SP),y
                  and   #$0F
                  ora   SPR_PIXEL
                  bne   :auxData
:auxNoMask1       lda   (SPR_SP),y
                  and   #$0F
                  cmp   SPR_MASKCOLORL
                  bne   :auxNoMask2
                  lda   (SPR_DP),y
                  and   #$0F
                  sta   SPR_PIXEL
                  lda   (SPR_SP),y
                  and   #$F0
                  ora   SPR_PIXEL
                  bne   :auxData
:auxNoMask2       lda   (SPR_SP),y
:auxData          sta   (SPR_DP),y
:auxNoData        iny
                  cpy   SPR_WIDTH
                  bcc   :auxLoop
                  lda   SPR_SP
                  clc
                  adc   SPR_WIDTH
                  sta   SPR_SP
                  bcc   :noCarry
                  inc   SPR_SP+1
:noCarry          sta   TXTPAGE1
                  ldy   #0
:mainLoop
                  lda   (SPR_SP),y
                  cmp   SPR_MASKCOLOR
                  beq   :mainNoData
                  and   #$F0
                  cmp   SPR_MASKCOLORH
                  bne   :mainNoMask1
                  lda   (SPR_DP),y
                  and   #$F0
                  sta   SPR_PIXEL
                  lda   (SPR_SP),y
                  and   #$0F
                  ora   SPR_PIXEL
                  bne   :mainData
:mainNoMask1      lda   (SPR_SP),y
                  and   #$0F
                  cmp   SPR_MASKCOLORL
                  bne   :mainNoMask2
                  lda   (SPR_DP),y
                  and   #$0F
                  sta   SPR_PIXEL
                  lda   (SPR_SP),y
                  and   #$F0
                  ora   SPR_PIXEL
                  bne   :mainData
:mainNoMask2      lda   (SPR_SP),y
:mainData         sta   (SPR_DP),y
:mainNoData       iny
                  cpy   SPR_WIDTH
                  bcc   :mainLoop
                  lda   SPR_SP
                  clc
                  adc   SPR_WIDTH
                  sta   SPR_SP
                  bcc   :noCarry2
                  inc   SPR_SP+1
:noCarry2
                  inc   SPR_CURLINE
                  inc   SPR_Y
                  jmp   :lineLoop


flogoMaskColor    equ   #$11
flogoHeight       equ   #$16
flogoWidth        equ   #$21
** Remember: Data is Aux cols, then main cols, next line, repeat
flogoData
                  hex   FF,0F,0F,0F,0F,0F,0F,0F,0F,0F,0F,0F,0F,FF,11,11,11,11,11,11,11
                  hex   11,FF,0F,0F,0F,0F,0F,0F,0F,0F,0F,FF,0F,0F,0F,0F,0F,0F,0F,0F,0F
                  hex   0F,0F,0F,0F,11,11,11,11,11,11,11,11,11,0F,0F,0F,0F,0F,0F,0F,0F
                  hex   0F,0F,11
                  hex   FF,77,77,77,77,77,77,77,00,77,77,77,77,FF,F1,F1,F1,F1,F1,F1,F1
                  hex   F1,FF,77,77,00,77,77,77,77,77,77,FF,00,EE,EE,EE,EE,00,EE,EE,EE
                  hex   EE,EE,EE,00,F1,F1,F1,F1,F1,F1,F1,F1,F1,00,EE,EE,EE,EE,00,EE,EE
                  hex   EE,00,11
                  hex   FF,77,77,F7,F7,F7,77,77,00,F7,F7,77,77,70,70,70,70,70,70,70,70
                  hex   70,70,77,77,00,77,77,77,77,F7,F7,FF,00,EE,EE,FE,FE,00,EE,EE,FE
                  hex   FE,EE,EE,00,E0,E0,E0,E0,00,E0,E0,E0,E0,00,EE,EE,EE,EE,00,EE,FE
                  hex   FE,00,F1
                  hex   FF,77,77,70,70,70,77,77,70,70,70,77,77,77,77,77,77,77,77,77,77
                  hex   77,77,77,77,00,77,77,77,77,70,70,00,00,EE,EE,E0,E0,00,EE,00,E0
                  hex   E0,EE,EE,00,EE,EE,EE,EE,00,EE,EE,EE,EE,00,EE,EE,EE,EE,00,EE,E0
                  hex   E0,E0,FF
                  hex   FF,77,77,77,77,77,77,77,77,77,77,77,77,77,77,0F,77,77,77,77,0F
                  hex   77,77,77,77,00,77,77,77,77,77,77,00,00,EE,EE,EE,EE,00,EE,00,EE
                  hex   EE,EE,EE,00,EE,EE,EE,EE,00,EE,EE,EE,EE,00,EE,EE,EE,EE,00,EE,EE
                  hex   EE,EE,FF
                  hex   FF,66,66,F6,F6,F6,66,66,66,66,F6,66,66,66,66,00,66,66,66,66,00
                  hex   66,66,66,66,00,66,66,66,66,F6,F6,00,00,CC,CC,FC,FC,00,CC,00,CC
                  hex   CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC
                  hex   FC,FC,FF
                  hex   FF,66,66,00,F0,F0,66,66,66,66,60,66,66,66,66,66,66,66,66,66,66
                  hex   66,66,66,66,00,66,66,66,66,60,60,00,00,CC,CC,F0,F0,00,CC,00,CC
                  hex   CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC
                  hex   C0,C0,FF
                  hex   FF,66,66,00,11,FF,66,66,66,66,66,66,66,66,66,66,66,66,66,66,66
                  hex   66,66,66,66,00,66,66,66,66,66,66,00,00,CC,CC,FF,11,00,CC,00,CC
                  hex   CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC,CC,CC,00,CC,CC
                  hex   CC,CC,FF
                  hex   FF,0F,0F,00,11,FF,0F,0F,0F,0F,0F,0F,0F,66,66,0F,0F,0F,66,66,0F
                  hex   0F,0F,0F,0F,00,0F,0F,0F,0F,0F,0F,00,00,0F,0F,FF,11,00,0F,00,0F
                  hex   0F,0F,0F,00,CC,CC,0F,0F,00,CC,CC,0F,0F,00,0F,0F,0F,0F,00,0F,0F
                  hex   0F,0F,FF
                  hex   1F,1F,1F,1F,11,1F,1F,1F,1F,1F,1F,1F,FF,F6,F6,00,1F,FF,F6,F6,00
                  hex   1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,11,1F,1F,1F,1F
                  hex   1F,1F,1F,00,FC,FC,FF,1F,00,FC,FC,FF,1F,1F,1F,1F,1F,1F,1F,1F,1F
                  hex   1F,1F,1F
                  hex   11,11,11,11,11,11,11,11,11,11,11,11,FF,F0,F0,F0,11,FF,F0,F0,F0
                  hex   11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
                  hex   11,11,11,F0,F0,F0,FF,11,F0,F0,F0,FF,11,11,11,11,11,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
                  hex   11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
                  hex   11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,0F,0F,0F,0F,0F,0F,0F,0F,FF,F1,F1,F1,F1
                  hex   F1,11,0F,0F,0F,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,0F
                  hex   0F,0F,0F,0F,0F,0F,0F,F1,F1,F1,F1,F1,11,FF,0F,0F,0F,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,77,77,77,77,00,77,77,70,70,70,70,70
                  hex   FF,F1,00,77,77,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,EE
                  hex   EE,EE,EE,EE,EE,EE,00,E0,E0,E0,E0,00,F1,FF,EE,EE,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,77,77,77,77,00,F7,F7,77,77,77,77,77
                  hex   70,70,70,77,77,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,EE
                  hex   EE,FE,EE,EE,FE,FE,00,EE,EE,EE,EE,00,E0,E0,EE,EE,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,77,77,77,77,00,70,70,77,77,07,77,77
                  hex   77,77,77,77,77,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,EE
                  hex   EE,E0,EE,EE,E0,E0,00,EE,EE,EE,EE,00,EE,EE,EE,EE,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,77,77,77,77,00,77,77,77,77,00,F7,F7
                  hex   77,77,F7,77,77,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,EE
                  hex   EE,EE,EE,0F,EE,EE,00,EE,EE,FE,FE,00,EE,EE,EE,EE,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,66,66,66,66,00,66,66,66,66,00,F0,F0
                  hex   66,66,00,66,66,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,CC
                  hex   CC,FC,CC,CC,CC,CC,00,CC,CC,F0,F0,00,CC,CC,CC,CC,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,66,66,66,66,00,66,66,66,66,00,11,FF
                  hex   66,66,60,66,66,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,CC
                  hex   CC,C0,CC,CC,CC,CC,00,CC,CC,FF,11,00,CC,CC,CC,CC,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,66,66,66,66,00,66,66,66,66,00,11,FF
                  hex   66,66,66,66,66,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,CC
                  hex   CC,CC,CC,CC,CC,CC,00,CC,CC,FF,11,00,CC,CC,CC,CC,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,00,0F,0F,0F,0F,00,0F,0F,0F,0F,00,11,FF
                  hex   0F,0F,0F,0F,0F,FF,11,11,11,11,11,11,11,11,11,11,11,11,11,FF,0F
                  hex   0F,0F,0F,0F,0F,0F,00,0F,0F,FF,11,00,0F,0F,0F,0F,00,11,11,11,11
                  hex   11,11,11
                  hex   11,11,11,11,11,11,11,11,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,11,1F
                  hex   1F,1F,1F,1F,1F,1F,11,11,11,11,11,11,11,11,11,11,11,11,11,1F,1F
                  hex   1F,1F,1F,1F,1F,1F,1F,1F,1F,1F,11,1F,1F,1F,1F,1F,1F,11,11,11,11
                  hex   11,11,11

tapMaskColor      equ   #$11
tapHeight         equ   #$06
tapWidth          equ   #$18
** Remember: Data is Aux cols, then main cols, next line, repeat
tapData
                  hex   11,F1,F1,11,11,11,11,11,11,11,F1,11,11,11,11,11,AF,FF,FF,11,11,11,11,11
                  hex   11,F1,11,11,11,11,11,11,11,F1,F1,11,11,11,11,FF,0F,5F,11,11,11,11,11,11
                  hex   F1,FF,0F,FF,F1,F1,F1,F1,11,F1,00,AF,F1,F1,11,F1,00,FF,FF,F1,F1,F1,F1,F1
                  hex   F1,00,5F,F1,F1,F1,F1,F1,F1,FF,0F,FF,F1,11,11,FF,0F,00,F1,F1,F1,F1,F1,F1
                  hex   FF,F0,FF,AF,F0,FF,AF,0A,11,FA,00,FF,FA,0F,11,FF,00,FF,FF,AF,F0,FF,AF,00
                  hex   F5,00,FF,F5,00,00,F5,FF,FF,F0,FF,5F,F0,FF,11,F5,FF,00,FF,F5,00,00,F5,FF
                  hex   11,FF,0F,00,0F,FF,0F,F0,11,11,00,FF,0F,F0,11,FF,00,FF,0F,00,0F,FF,0F,F0
                  hex   11,50,FF,0F,00,00,0F,FF,11,FF,0F,F0,0F,FF,11,0F,0F,00,FF,0F,00,00,0F,FF
                  hex   11,1F,1F,1F,1F,FF,0F,1F,11,11,1F,1F,1F,1F,11,1F,1F,1F,1F,1F,1F,FF,0F,1F
                  hex   11,1F,1F,1F,1F,00,FF,11,11,1F,1F,1F,1F,11,11,1F,1F,1F,1F,1F,1F,00,FF,11
                  hex   11,11,11,11,11,1F,1F,11,11,11,11,11,11,11,11,11,11,11,11,11,11,1F,1F,11
                  hex   11,11,11,11,11,1F,1F,11,11,11,11,11,11,11,11,11,11,11,11,11,11,1F,1F,11


splosionMaskColor equ   #$22
splosionHeight    equ   #$06
splosionWidth     equ   #$06
** Remember: Data is Aux cols, then main cols, next line, repeat
splosionData
                  hex   28,82,22,22,22,82,12,22,22,22,12,21
                  hex   22,CC,E8,C2,EC,28,21,D9,92,D1,99,22
                  hex   22,28,EF,FE,8E,22,22,1D,FD,DF,21,22
                  hex   22,C8,EF,8E,EE,22,22,DD,1D,DF,91,22
                  hex   22,8C,28,22,2C,88,11,29,22,21,19,22
                  hex   28,22,22,22,22,22,22,22,22,22,22,21

plaqueMaskColor   equ   #$22
plaqueHeight      equ   #$06
plaqueWidth       equ   #$13
** Remember: Data is Aux cols, then main cols, next line, repeat
plaqueData
                  hex   E2,CE,CE,CE,CE,CE,CE,CE,CE,CE,DE,DE,DE,DE,DE,DE,DE,DE,E2,DD,9D,9D,9D,9D
                  hex   9D,9D,9D,BD,9D,9D,9D,9D,9D,9D,9D,9D,DD,22
                  hex   EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,99,DD,DD,DD,DD
                  hex   DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,FB,62
                  hex   EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,B9,DD,DD,DD,DD
                  hex   DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,FB,66
                  hex   EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,EE,B9,DD,DD,DD,DD
                  hex   DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,DD,BF,66
                  hex   2E,ED,ED,EF,EF,EF,EF,EF,EF,EF,EF,EF,EF,EF,EF,EF,ED,ED,3E,DD,DF,DF,DB,DF
                  hex   DF,DF,DF,DF,DF,DF,DF,DF,DB,DF,DF,DF,DD,26
                  hex   22,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,22,22,26,26,26,26
                  hex   26,26,26,26,26,26,26,26,26,26,26,26,26,22


youMaskColor      equ   #$11
youHeight         equ   #$03
youWidth          equ   #$06
youData
                  hex   01,01,11,11,11,11,11,11,11,11,11,11
                  hex   10,10,01,01,00,00,01,11,10,11,11,11
                  hex   11,11,11,11,11,10,10,11,10,11,10,11


hiMaskColor       equ   #$11
hiHeight          equ   #$03
hiWidth           equ   #$03
hiData
                  hex   01,01,01,11,11,11
                  hex   00,00,01,10,11,11
                  hex   10,10,10,11,11,11



NumMaskColor      equ   #$11
NumHeight         equ   #$03
NumWidth          equ   #$02
NumList           da    N0Data
                  da    N1Data
                  da    N2Data
                  da    N3Data
                  da    N4Data
                  da    N5Data
                  da    N6Data
                  da    N7Data
                  da    N8Data
                  da    N9Data
N0Data
                  hex   01,01,10,11
                  hex   00,00,11,11
                  hex   10,10,01,11

N1Data
                  hex   01,11,00,11
                  hex   11,11,00,11
                  hex   01,01,00,11

N2Data
                  hex   01,01,10,11
                  hex   11,10,01,11
                  hex   00,01,01,11

N3Data
                  hex   10,01,10,11
                  hex   11,01,10,11
                  hex   01,10,01,11

N4Data
                  hex   00,01,11,11
                  hex   00,00,01,11
                  hex   11,00,11,11


N5Data
                  hex   00,10,10,11
                  hex   10,01,10,11
                  hex   10,10,01,11


N6Data
                  hex   01,11,10,11
                  hex   00,01,10,11
                  hex   10,10,01,11

N7Data
                  hex   10,00,10,11
                  hex   11,10,01,11
                  hex   11,11,00,11

N8Data
                  hex   01,01,10,11
                  hex   01,01,10,11
                  hex   10,10,01,11


N9Data
                  hex   01,01,10,11
                  hex   10,00,01,11
                  hex   11,10,01,11

QRCodeMaskColor   equ   #$88
QRCodeHeight      equ   #$0e
QRCodeWidth       equ   #$0e
QRCodeData
                  hex   FF,0F,0F,0F,FF,FF,FF,0F,FF,FF,0F,0F,0F,FF,0F,0F,0F,0F,FF,FF,0F,FF,FF,0F,0F,0F,0F,FF
                  hex   FF,FF,0F,FF,FF,FF,FF,F0,F0,FF,FF,0F,FF,FF,00,0F,0F,00,F0,F0,FF,F0,F0,00,0F,0F,00,FF
                  hex   FF,FF,00,FF,FF,00,0F,F0,FF,FF,FF,00,FF,FF,00,00,00,00,F0,F0,F0,F0,0F,00,00,00,00,FF
                  hex   FF,0F,0F,0F,FF,F0,FF,F0,F0,FF,0F,0F,0F,FF,00,0F,0F,00,00,0F,00,0F,00,00,0F,0F,00,FF
                  hex   FF,0F,0F,FF,0F,00,0F,0F,0F,0F,0F,0F,0F,FF,0F,0F,0F,0F,0F,F0,0F,00,FF,FF,FF,FF,FF,FF
                  hex   FF,00,0F,FF,00,FF,F0,00,0F,0F,00,0F,00,FF,F0,F0,FF,0F,F0,00,0F,0F,00,0F,FF,FF,0F,FF
                  hex   FF,00,F0,00,0F,0F,FF,0F,FF,00,FF,FF,0F,FF,F0,0F,FF,0F,00,0F,F0,00,F0,0F,0F,0F,00,FF
                  hex   FF,F0,00,F0,00,FF,F0,F0,0F,0F,F0,00,00,FF,00,0F,0F,0F,FF,0F,0F,0F,F0,0F,FF,FF,0F,FF
                  hex   FF,FF,00,0F,F0,00,FF,0F,0F,00,00,F0,FF,FF,00,00,00,0F,FF,00,F0,F0,0F,00,0F,0F,F0,FF
                  hex   FF,0F,0F,0F,FF,FF,F0,00,FF,FF,FF,00,0F,FF,0F,0F,0F,0F,00,FF,FF,0F,00,0F,00,00,0F,FF
                  hex   FF,FF,0F,FF,FF,00,FF,0F,0F,0F,0F,00,00,FF,00,0F,0F,00,0F,FF,00,00,00,0F,00,0F,F0,FF
                  hex   FF,FF,00,FF,FF,FF,F0,0F,00,F0,0F,FF,F0,FF,00,00,00,00,00,FF,0F,0F,F0,F0,F0,00,00,FF
                  hex   FF,0F,0F,0F,FF,00,0F,0F,F0,F0,00,00,0F,FF,00,0F,0F,00,00,F0,0F,0F,F0,FF,00,0F,00,FF
                  hex   FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF

