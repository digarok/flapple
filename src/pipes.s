**************************************************
* Pipe Drawing Routines
* These are custom built to draw pipes that 
* move right-to-left only.  There is no undraw.
* It simply copies a blue pixel in the area to the
* right of the column to restore the background.
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
                   DO    MONO
PipeBody_Main_E    hex   55,ee,ee,cc,cc,44,00
PipeBody_Main_O    hex   00,ee,cc,cc,44,44,55,00
PipeBody_Aux_E     hex   00,77,66,66,22,22,aa,00
PipeBody_Aux_O     hex   aa,77,77,66,66,22,00
                   ELSE
PipeBody_Main_E    hex   55,ee,ee,cc,cc,44,77
PipeBody_Main_O    hex   77,ee,cc,cc,44,44,55,77
PipeBody_Aux_E     hex   bb,77,66,66,22,22,aa,bb
PipeBody_Aux_O     hex   aa,77,77,66,66,22,bb

                   FIN

PipeInterval       equ   #60                ; game ticks to spawn new pipe
PipeSpawn          db    #45                ; our counter, starting point for spawning
PipeSpawnSema      db    0                  ; points to next spot (even if currently unavailable)
MaxPipes           equ   2
PipeSet            ds    MaxPipes*3         ; array of pipe{x,y1,y2}

TopPipes           ds    MaxPipes*2         ; Space for pipe X,Y
BotPipes           ds    MaxPipes*2         ; "

PIPE_SP            equz  $F0


PIPE_DP            equz  $00
PIPE_DP0           equz  $00
PIPE_DP1           equz  $02
PIPE_DP2           equz  $04
PIPE_DP3           equz  $06
PIPE_DP4           equz  $08

PIPE_RCLIP         equ   #40
PIPE_WIDTH         equ   #15
PIPE_UNDERVAL      db    0

PIPE_X             db    0                  ; the 0-96? X value (screen = 16-95)
PIPE_TOP_Y         db    0                  ; MEMORY DLR Y index, 0-24
PIPE_BOT_Y         db    0                  ; MEMORY DLR Y index, 0-24

PIPE_X_IDX         db    0                  ; MEMORY DLR X index, 0-39 
PIPE_Y_IDX         db    0                  ; Y*2 for lookups in Lo-Res line table 
PIPE_BODY_TOP      db    0                  ; Y val 
PIPE_BODY_BOT      db    0                  ; Y val 


PipeXScore         equ   50                 ; pipe at this value causes score increase

** LEGACY !  DELETE AFTER REWRITE !
PIPE_X_FULL        db    0
PIPE_Y             db    0
PIPE_T_B           db    0
PIPE_TOP           equ   0                  ; enum for top pipe type
PIPE_BOT           equ   1                  ; enum for bottom pipe type

* pipe min  =  15x6 pixels  =  15x3 bytes
* playfield =  80x48 pixels =  80x24 bytes
*   - grass =	 80x44 pixels =  80x22 bytes
* we'll make the pipes sit on a 95x22 space
* we don't care about screen pixel X/Y though we could translate
* the drawing routine will handle it, and we will do collision
* in the bird drawing routine
UpdatePipes        inc   PipeSpawn
                   lda   PipeSpawn
                   cmp   #PipeInterval
                   bne   :noSpawn
                   jsr   SpawnPipe
                   lda   #0
                   sta   PipeSpawn
:noSpawn

MovePipes
                   ldx   #2                 ;MaxPipes*2?
:loop              lda   TopPipes,x
                   beq   :noPipe
                   dec   TopPipes,x
                   cmp   #PipeXScore+1      ; A should still be set
                   bne   :noScore
:ScoreUp           sed
                   lda   ScoreLo
                   clc
                   adc   #1
                   sta   ScoreLo
                   bcc   :noFlip
                   lda   ScoreHi
                   adc   #0
                   sta   ScoreHi
:noFlip            cld

:noScore
:noPipe            dex
                   dex
                   bpl   :loop
                   jmp   UpdatePipesDone


SpawnPipe          lda   PipeSpawnSema
                   asl                      ; convert to word index
                   tax
                   jsr   GetRand            ; Build Y Value
                   and   #$0F               ; @todo - this doesn't check bounds.. just for testing
                   lsr                      ; even smaller
                   sta   TopPipes+1,x
                   clc
                   adc   #13
                   sta   BotPipes+1,x
                   lda   #95                ; Build X Value ;)
                   sta   TopPipes,x
                   inc   PipeSpawnSema
                   lda   PipeSpawnSema
                   cmp   #MaxPipes
                   bne   :done
                   lda   #0                 ; flip our semaphore/counter to 0
                   sta   PipeSpawnSema
:done              rts




* A= x coord   X=top y   Y=bot y
DrawPipes
                   lda   TopPipes           ;Pipe X
                   beq   :noPipes0
                   ldx   TopPipes+1         ;top Y
                   ldy   BotPipes+1         ;bottom y
                   jsr   DrawPipe

:noPipes0
                   lda   TopPipes+2         ;Pipe X
                   beq   :noPipes1
                   ldx   TopPipes+3         ;top Y
                   ldy   BotPipes+3         ;bottom y
                   jsr   DrawPipe
:noPipes1
                   rts
*jmp DrawPipesDone	;Back to main


* Used by all of the routines that draw the pipe caps
SetPipeCapPtrs
                   ldy   PIPE_TOP_Y
                   lda   LoLineTableL,y
                   sta   PIPE_DP0
                   lda   LoLineTableH,y
                   sta   PIPE_DP0+1         ; cap top line
                   lda   LoLineTableL+1,y
                   sta   PIPE_DP1
                   lda   LoLineTableH+1,y
                   sta   PIPE_DP1+1         ; cap bottom line

                   ldy   PIPE_BOT_Y
                   lda   LoLineTableL,y
                   sta   PIPE_DP2
                   lda   LoLineTableH,y
                   sta   PIPE_DP2+1         ; cap top line
                   lda   LoLineTableL+1,y
                   sta   PIPE_DP3
                   lda   LoLineTableH+1,y
                   sta   PIPE_DP3+1         ; cap bottom line
                   rts

* A= x coord   X=top y   Y=bot y
DrawPipe           sta   PIPE_X
                   stx   PIPE_TOP_Y
                   sty   PIPE_BOT_Y
                   cmp   #95-13
                   bcc   :notOver
:over              sec                      ; clipped on right
                   sbc   #16
                   lsr
                   sta   PIPE_X_IDX
                   bcc   :evenR
:oddR              jmp   DrawPipeOddR
:evenR             jmp   DrawPipeEvenR

:notOver           cmp   #16
                   bcs   :NOCLIP
:under
                                            ; clipped on left
                                            ; X = 0-16	
                   sta   PIPE_UNDERVAL      ; we're going to flip it around
                   lda   #16                ; and move backwards from 0.  
                   sec
                   sbc   PIPE_UNDERVAL
                   pha
                   lsr
                   sta   PIPE_UNDERVAL
                   lda   #0
                   sec
                   sbc   PIPE_UNDERVAL
                   tax
                   pla
                   lsr
                   bcc   :evenL
:oddL              dex                      ; downshift * 1
                   txa
                   sta   PIPE_X_IDX
                   jmp   DrawPipeOddL
:evenL             txa
                   sta   PIPE_X_IDX
                   jmp   DrawPipeEvenL

:NOCLIP            lda   PIPE_X
                   sec
                   sbc   #16
                   lsr
                   sta   PIPE_X_IDX
                   bcc   :even
:odd               jmp   DrawPipeOdd
:even              jmp   DrawPipeEven




DrawPipeEven
                   jsr   SetPipeCapPtrs

                   sta   TXTPAGE2
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; optimized by hand, not perfect, but big help
                                            ;col 0
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 2
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 4
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 6
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 8
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 10
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 12
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 14 (final!)
                   lda   #BGCOLORAUX        ; BGCOLOR! Last column, no need to undraw whole pipe
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y

                   sta   TXTPAGE1
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ;col 1
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 3
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 5
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 7
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 9
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 11
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 13
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y

* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEven

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEven

                   rts                      ; !!! FORMERLY WAS 'jmp DrawPipeDone' !!! 
                                            ; !!! We are actually returning for parent DrawPipe






DrawPipeBodyEven
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   bcs   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen

                   sta   TXTPAGE1
*** Version 3 - FULL OPTIMIZATION
                   ldy   PIPE_X_IDX
                   lda   #$55               ; PipeBody_Main_E
                   sta   (PIPE_DP),y
                   iny
                   lda   #$EE
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$CC
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$44
                   sta   (PIPE_DP),y
                   iny
                   lda   #BGCOLOR
                   sta   (PIPE_DP),y



                   sta   TXTPAGE2
*** Version 3 - FULL OPTIMIZATION
                   ldy   PIPE_X_IDX
                                            ;lda #$BB	; PipeBody_Aux_E
                                            ;sta (PIPE_DP),y
                   iny
                   lda   #$77
                   sta   (PIPE_DP),y
                   iny
                   lda   #$66
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$22
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$AA
                   sta   (PIPE_DP),y
                   iny
                   lda   #BGCOLORAUX
                   sta   (PIPE_DP),y

                   inc   PIPE_Y
                   jmp   :loop

:done              rts







DrawPipeOdd
                   jsr   SetPipeCapPtrs
                   sta   TXTPAGE1
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; for this "odd" routine, we add 1 for TXTPAGE2

                                            ; optimized by hand, not perfect, but big help
                                            ;col 0
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 2
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 4
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 6
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 8
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 10
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 12
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 14 (final!)
                   lda   #BGCOLOR
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP

                   sta   TXTPAGE2
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                   iny                      ; TXTPAGE2 is +1 in "odd" mode
                                            ;col 1
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 3
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 5
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 7
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 9
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 11
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 13
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP2
* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOdd

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOdd



DrawPipeBodyOdd
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   bcs   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen

                   sta   TXTPAGE1
*** Version 3 - FULL OPTIMIZATION
                   ldy   PIPE_X_IDX
                                            ;lda #$77	; PipeBody_Main_O
                                            ;sta (PIPE_DP),y
                   iny
                   lda   #$EE
                   sta   (PIPE_DP),y
                   iny
                   lda   #$CC
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$44
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$55
                   sta   (PIPE_DP),y
                   iny
                   lda   #BGCOLOR
                   sta   (PIPE_DP),y


                   sta   TXTPAGE2
*** Version 3 - FULL OPTIMIZATION
                   ldy   PIPE_X_IDX
                   iny
                   lda   #$AA               ; PipeBody_Aux_O
                   sta   (PIPE_DP),y
                   iny
                   lda   #$77
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$66
                   sta   (PIPE_DP),y
                   iny
                   sta   (PIPE_DP),y
                   iny
                   lda   #$22
                   sta   (PIPE_DP),y
                   iny
                   lda   #BGCOLORAUX
                   sta   (PIPE_DP),y

                   inc   PIPE_Y
                   jmp   :loop
                                            ;sec
                                            ;bcs :loop
:done              rts




DrawPipeEvenR
                   jsr   SetPipeCapPtrs

                   sta   TXTPAGE2
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; optimized by hand, not perfect, but big help
                                            ;col 0
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 2
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 4
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 6
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 8
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 10
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 12
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 14 (final!)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #BGCOLORAUX
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP
                   sta   TXTPAGE1
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ;col 1
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 3
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 5
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 7
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 9
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 11
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 13
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP2

* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEvenR

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEvenR

                   rts                      ; !!! FORMERLY WAS 'jmp DrawPipeDone' !!! 
                                            ; !!! We are actually returning for parent DrawPipe



DrawPipeBodyEvenR
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   bcs   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen

                   sta   TXTPAGE1
*** Version 2.1
                   lda   PIPE_X_IDX
                   clc
                   adc   #PIPE_WIDTH/2-1
                   pha                      ;PHA for below loop
                   tay
                   ldx   #PIPE_WIDTH/2-1
:oddLoop           cpy   #PIPE_RCLIP
                   bcs   :oddBreak
                   lda   PipeBody_Main_E,x
                   sta   (PIPE_DP),y
:oddBreak
                   dey
                   dex
                   bpl   :oddLoop


                   sta   TXTPAGE2
*** Version 2.1
                   pla
                   tay                      ;PHA from above
                   iny
                   ldx   #PIPE_WIDTH/2
:evenLoop          cpy   #PIPE_RCLIP
                   bcs   :evenBreak
                   lda   PipeBody_Aux_E,x
                   sta   (PIPE_DP),y
:evenBreak
                   dey
                   dex
                   bpl   :evenLoop
                   inc   PIPE_Y
                   jmp   :loop

:done              rts


DrawPipeOddR
                   jsr   SetPipeCapPtrs
                   sta   TXTPAGE1
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; for this "odd" routine, we add 1 for TXTPAGE2

                                            ; optimized by hand, not perfect, but big help
                                            ;col 0
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 2
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 4
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 6
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 8
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 10
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 12
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 14 (final!)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #BGCOLOR
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP

                   sta   TXTPAGE2
                   ldy   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                   iny                      ; TXTPAGE2 is +1 in "odd" mode
                                            ;col 1
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 3
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 5
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 7
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 9
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   iny                      ;col 11
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   iny                      ;col 13
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP2
* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOddR

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOddR

                   rts                      ; !!! FORMERLY WAS 'jmp DrawPipeDone' !!! 
                                            ; !!! We are actually returning for parent DrawPipe



DrawPipeBodyOddR
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   bcs   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen

                   sta   TXTPAGE1
*** Version 2.1
                   lda   PIPE_X_IDX
                   clc
                   adc   #PIPE_WIDTH/2
                   pha                      ;PHA for below loop
                   tay                      ;\_ skip col 0 (bg color)
                   iny                      ;/
                   ldx   #PIPE_WIDTH/2+1
:oddLoop           cpy   #PIPE_RCLIP
                   bcs   :oddBreak
                   lda   PipeBody_Main_O,x
                   sta   (PIPE_DP),y
:oddBreak
                   dey
                   dex
                   bne   :oddLoop           ; we can skip the first pixel, transparent

                   sta   TXTPAGE2
*** Version 2.1
                   pla
                   tay                      ;PHA from above
                   ldx   #PIPE_WIDTH/2-1
:evenLoop          cpy   #PIPE_RCLIP
                   bcs   :evenBreak
                   lda   PipeBody_Aux_O,x
                   sta   (PIPE_DP),y
:evenBreak
                   dey
                   dex
                   bpl   :evenLoop

                   inc   PIPE_Y
                   jmp   :loop
:done              rts

DrawPipeEvenL
                   jsr   SetPipeCapPtrs
                   sta   TXTPAGE2
                   lda   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; optimized by hand, not perfect, but big help
                   clc
                   adc   #PIPE_WIDTH/2
                   tax                      ;stash for below loop
                   tay
                                            ;col 14 (rightmost)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #BGCOLORAUX
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 12
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 10
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 8
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 6
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 4
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 2
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 0 (final! leftmost)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP
                   sta   TXTPAGE1
                   txa
                   tay
                   dey
                                            ;col 13
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 11
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 9
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 7
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 5
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 3
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 1
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
:RCLIP2
* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEvenL

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyEvenL

                   rts                      ; !!! FORMERLY WAS 'jmp DrawPipeDone' !!! 
                                            ; !!! We are actually returning for parent DrawPipe




DrawPipeBodyEvenL
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   beq   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen

                   sta   TXTPAGE2
                   lda   PIPE_X_IDX
                   clc
                   adc   #PIPE_WIDTH/2
                   bmi   :done
                   pha                      ;PHA for below loop
                   tay
                   ldx   #PIPE_WIDTH/2

:evenLoop          lda   PipeBody_Aux_E,x
                   sta   (PIPE_DP),y
                   dex
                   dey
                   bpl   :evenLoop

                   sta   TXTPAGE1
                   pla                      ;PLA from above
                   tay
                   ldx   #PIPE_WIDTH/2

:oddLoop           lda   PipeBody_Main_E,x
                   sta   (PIPE_DP),y
                   dex
                   dey
                   bpl   :oddLoop


                   inc   PIPE_Y
                   jmp   :loop
:done              rts




DrawPipeOddL
                   jsr   SetPipeCapPtrs
                   sta   TXTPAGE1
                   lda   PIPE_X_IDX         ; y= the x offset... yay dp indexing on 6502
                                            ; optimized by hand, not perfect, but big help
                   clc
                   adc   #PIPE_WIDTH/2
                   tax                      ;stash for below loop
                   tay
                                            ;col 14 (rightmost)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #BGCOLOR
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 12
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$45
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$54
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 10
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 8
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$C5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 6
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5C
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 4
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$5E
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 2
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$E5
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 0 (final! leftmost)
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP
                   lda   #$55
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
:RCLIP
                   sta   TXTPAGE2
                   txa
                   tay
                                            ;col 13
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$AA
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP2),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 11
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 9
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$2A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 7
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 5
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   lda   #$6A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   dey                      ;col 3
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A6
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
                   dey                      ;col 1
                   cpy   #PIPE_RCLIP
                   bcs   :RCLIP2
                   lda   #$7A
                   sta   (PIPE_DP0),y
                   sta   (PIPE_DP2),y
                   lda   #$A7
                   sta   (PIPE_DP1),y
                   sta   (PIPE_DP3),y
:RCLIP2
* Handle body 
                   lda   #0
                   sta   PIPE_Y             ; current line
                   lda   PIPE_TOP_Y
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOddL

                   ldy   PIPE_BOT_Y
                   iny
                   iny
                   sty   PIPE_Y             ; current line
                   lda   #22
                   sta   PIPE_BODY_BOT
                   jsr   DrawPipeBodyOddL

                   rts                      ; !!! FORMERLY WAS 'jmp DrawPipeDone' !!! 
                                            ; !!! We are actually returning for parent DrawPipe

DrawPipeBodyOddL
:loop              ldy   PIPE_Y
                   cpy   PIPE_BODY_BOT
                   beq   :done

                   lda   LoLineTableL,y
                   sta   PIPE_DP
                   lda   LoLineTableH,y
                   sta   PIPE_DP+1          ; pointer to line on screen


                   sta   TXTPAGE1
                   lda   PIPE_X_IDX
                   clc
                   adc   #PIPE_WIDTH/2
                   bmi   :done
                   pha                      ;PHA for below loop
                   tay
                   ldx   #PIPE_WIDTH/2

:evenLoop          lda   PipeBody_Main_O,x
                   sta   (PIPE_DP),y
                   dex
                   dey
                   bpl   :evenLoop

                   sta   TXTPAGE2
                   pla                      ;PLA from above
                   tay
                   ldx   #PIPE_WIDTH/2-1

:oddLoop           lda   PipeBody_Aux_O,x
                   sta   (PIPE_DP),y
                   dex
                   dey
                   bpl   :oddLoop

                   inc   PIPE_Y
                   jmp   :loop

:done              rts






















