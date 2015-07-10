****************************************
* Flapple Bird                         *
*                                      *
*  Dagen Brock <dagenbrock@gmail.com>  *
*  2014-04-17                          *
****************************************
                    lst   off
                    org   $2000              ; start at $2000 (all ProDOS8 system files)
                    typ   $ff                ; set P8 type ($ff = "SYS") for output file
                    xc    off                ; @todo force 6502?
                    xc    off
MLI                 equ   $bf00

; Sorry, I gotta have some macros.. this is merlin format after all
; You might as well take advantage of your tools :P
CopyPtr             MAC
                    lda   #<]1               ; load low byte
                    sta   ]2                 ; store low byte
                    lda   #>]1               ; load high byte
                    sta   ]2+1               ; store high byte
                    <<<

; HANDLE GREENSCREEN DOODS... MONO flag set 0 = color mode,  1 = mono mode
MONO                equ  0

                    DO    MONO
                    dsk   fmono.system       ; tell compiler output filename
BGCOLOR             equ   #$00
BGCOLORAUX          equ   #$00
BGCOLOR_0LO         equ   #$00
BGCOLOR_0HI         equ   #$00
BGCOLORAUX_0LO      equ   #$00
BGCOLORAUX_0HI      equ   #$00

; HANDLE COLOR DOODS
                    ELSE
                    dsk   flap.system        ; tell compiler output filename
BGCOLOR             equ   #$77
BGCOLORAUX          equ   #$BB
BGCOLOR_0LO         equ   #$70
BGCOLOR_0HI         equ   #$07
BGCOLORAUX_0LO      equ   #$B0
BGCOLORAUX_0HI      equ   #$0B

                    FIN



Main
                    jsr   DetectMachine      ; also inits vbl
                    jsr   LoadHiScore
                    jsr   IntroWipe

                    jsr   DL_SetDLRMode

Title
                    jsr   VBlank
                    DO    MONO
                    lda   #$FF
                    ELSE
                    lda   #$00
                    FIN
                    jsr   DL_Clear
                    ldx   #3                 ;slight pause
                    jsr   VBlankX
                    lda   #$F6
                    ldx   #$27
                    ldy   #BGCOLOR
                    jsr   DL_WipeIn
                    jsr   DrawFlogo
                    lda   FlogoCount
                    and   #%00000011         ; every 4 times?
                    bne   :noSongForYou
                    jsr   PlayFlappySong     ;@todo throttle
:noSongForYou
                    inc   FlogoCount
                    ldx   #60
                    ldy   #2
                    jsr   WaitKeyXY

PreGameLoop
** INIT ALL GAME STATE ITEMS
                    lda   #BIRD_Y_INIT
                    sta   BIRD_Y
                    sta   BIRD_Y_OLD
                    lda   #0
                    sta   SPRITE_COLLISION
                    sta   PreGameTick
                    sta   PreGameTick+1
                    sta   PreGameText
                    sta   ScoreLo
                    sta   ScoreHi


                    lda   #0
                    ldx   #3
:clearPipes         sta   TopPipes,x
                    sta   BotPipes
                    dex
                    bpl   :clearPipes

** CLEAR SCREEN - SETUP BIRD
                    jsr   VBlank
                    lda   #BGCOLOR
                    jsr   DL_Clear

                    lda   #BIRD_X
                    sta   SPRITE_X
                    lda   #5
                    sta   SPRITE_W           ; all birds are same width

** WAIT FOR PLAYER TO HIT SOMETHING
:noKey              jsr   VBlank
                    jsr   UndrawBird
                    jsr   DrawBird
                    jsr   UpdateGrass
                    jsr   FlapBird

                    inc   PreGameTick
                    bne   :noOverflow
                    inc   PreGameTick+1
:noOverflow         lda   PreGameTick
                    cmp   #60
                    bcc   :skipText
                    lda   PreGameText
                    bne   :skipText
                    inc   PreGameText
                    jsr   DrawTap
:skipText
                    lda   PreGameTick+1
                    cmp   #2
                    bne   :checkKey

                    jmp   HiScreen

                    jsr   ButtonsCheck
                    bcs   :key
:checkKey           lda   KEY
                    bpl   :noKey
:key                sta   STROBE
                    lda   #BGCOLOR
                    jsr   DL_Clear
                    jmp   GameLoop

PreGameTick         dw    0

PreGameText         db    0
GSBORDER            da    _GSBORDER
_GSBORDER           db    0


GameLoop
                    jsr   VBlank

                    jsr   UndrawBird
                    jsr   DrawPipes
                    jsr   DrawScore
                    jsr   DrawBird
                    jmp   UpdatePipes
UpdatePipesDone
DONTUPDATEPIPES
                    jsr   FlapBird
                    jsr   UpdateGrass

                    jmp   HandleInput        ; Also plays flap!
HandleInputDone
                    lda   SPRITE_COLLISION
                    bne   GAME_OVER

                    lda   QuitFlag
                    beq   GameLoop
                    jmp   Quit

GAME_OVER
                    jsr   DrawPipes
                    jsr   DrawScore
                    jsr   DrawSplosion
                    jsr   SND_Static
                    jsr   UpdateHiScore
                    lda   #3
                    sta   SPR_Y
                    jsr   DrawPlaqueShared
                    lda   #10
                    sta   SPR_Y
                    jsr   DrawPlaqueShared

                    ldy   #4
                    jsr   DrawYou
                    ldy   #11
                    jsr   DrawHi

                    ldx   #19
                    ldy   #11
                    jsr   DrawHiScore

                    ldx   #19
                    ldy   #4
                    jsr   DrawYouScore

                    sta   STROBE             ;clear errant flap hits
                    ldx   #60
                    ldy   #5
                    jsr   WaitKeyXY
                    bcc   :noKey
                    lda   QuitFlag
                    beq   :noQuit
                    jmp   Quit
:noQuit             jmp   PreGameLoop
:noKey
                    lda   #$FA
                    ldx   #$50
                    ldy   #$00
                    jsr   DL_WipeIn
                    jmp   Title
HiScreen
                    jsr   GetRand
                    jsr   DL_Clear
                    lda   #9
                    sta   SPR_Y
                    jsr   DrawPlaqueShared
                    ldy   #10
                    jsr   DrawHi
                    ldx   #19
                    ldy   #10
                    jsr   DrawHiScore
                    ldx   #60
                    ldy   #5
                    jsr   WaitKeyXY
                    bcc   :noKey
                    lda   QuitFlag
                    beq   :noQuit
                    jmp   Quit
:noQuit             jmp   PreGameLoop
:noKey              jmp   Title

FlogoCount          db    0                  ; used to throttle how often song is played

SND_Flap            jmp   SND_Flap2
SND_Flap1
                    ldx   #$1c               ;LENGTH OF NOISE BURST
:spkLoop            lda   SPEAKER            ;TOGGLE SPEAKER
                    txa
                    asl
                    asl
                    tay

:waitLoop           dey                      ;DELAY LOOP FOR PULSE WIDTH
                    bne   :waitLoop
                    dex                      ;GET NEXT PULSE OF THIS NOISE BURST
                    bne   :spkLoop
                    rts

SND_Flap2
                    ldx   #$16               ;LENGTH OF NOISE BURST
:spkLoop            sta   SPEAKER            ;TOGGLE SPEAKER
                    txa
                    clc
                    adc   #$30
                    tay

:waitLoop           dey                      ;DELAY LOOP FOR PULSE WIDTH
                    bne   :waitLoop
                    dex                      ;GET NEXT PULSE OF THIS NOISE BURST
                    bne   :spkLoop
                    rts


SND_Static
                    ldx   #$80               ;LENGTH OF NOISE BURST
:spkLoop            lda   SPEAKER            ;TOGGLE SPEAKER
                    jsr   GetRand
                    tay
*	ldy $BA00,X	;GET PULSE WIDTH PSEUDO-RANDOMLY
:waitLoop           dey                      ;DELAY LOOP FOR PULSE WIDTH
                    bne   :waitLoop
                    dex                      ;GET NEXT PULSE OF THIS NOISE BURST
                    bne   :spkLoop

                    ldx   #$60               ;LENGTH OF NOISE BURST
:spkLoop2           lda   SPEAKER            ;TOGGLE SPEAKER
                    jsr   GetRand
                    and   #%1000000
                    tay
*	ldy $BA00,X	;GET PULSE WIDTH PSEUDO-RANDOMLY
:waitLoop2          dey                      ;DELAY LOOP FOR PULSE WIDTH
                    bne   :waitLoop2
                    dex                      ;GET NEXT PULSE OF THIS NOISE BURST
                    bne   :spkLoop2

                    ldx   #$80               ;LENGTH OF NOISE BURST
:spkLoop3           lda   SPEAKER            ;TOGGLE SPEAKER
                    jsr   GetRand
                    lsr
                    tay
:waitLoop3          dey                      ;DELAY LOOP FOR PULSE WIDTH
                    bne   :waitLoop3
                    dex                      ;GET NEXT PULSE OF THIS NOISE BURST
                    bne   :spkLoop3

                    rts

HandleInput
                    lda   BIRD_Y
                    sta   BIRD_Y_OLD
                                             ;Update bird and velocity in here
                    jsr   ButtonsCheck       ;returns 0 when no button hit
                    bcs   :flap              ;don't even check keys if button was hit
:kloop              lda   KEY
                    bpl   :noFlap
:key                sta   STROBE
                    jsr   QuitKeyCheck
                    jsr   PauseKeyCheck      ; returns 0 when there was a pause
                    beq   :noFlap
:flap               lda   #40
                    sta   BIRD_VELOCITY
                    bne   :handleBird
:noFlap             dec   BIRD_VELOCITY
                    lda   BIRD_VELOCITY
                    bpl   :handleBird
                    lda   #3
                    sta   BIRD_VELOCITY
:handleBird
                    lda   BIRD_VELOCITY
                    cmp   #37
                    bcc   :notTop
                    dec   BIRD_Y             ; +2
                    jsr   SND_Flap
                    clc
                    bcc   :boundsCheck
:notTop             cmp   #36
                    bcs   :boundsCheck
                    cmp   #2
                    bcc   :DOWN
                    asl
                    asl
                    bcc   :boundsCheck
:DOWN               inc   BIRD_Y

:boundsCheck
                    lda   BIRD_Y
                    bpl   :notUnder
                    lda   #0
                    sta   BIRD_Y
                    beq   :keyDone
:notUnder           cmp   #38                ; Life, the Universe, and Everything
                    bcc   :keyDone
                    lda   #38
                    sta   BIRD_Y
:keyDone            jmp   HandleInputDone

ButtonsCheck        lda   ButtonHeld
                    lda   $c061              ;b0
                    cmp   #128
                    bcs   :hit
                    lda   $c062              ;b1
                    cmp   #128
                    bcs   :hit
                    lda   $c063              ;b2
                    bcs   :hit
:nohit              lda   #0
                    sta   ButtonHeld
                    clc
                    rts

:hit                lda   ButtonHeld
                    bne   :noflap
                    inc   ButtonHeld         ; set to 1
                    sec
                    rts
:noflap             clc
                    rts
ButtonHeld          db    0

* A= key
QuitKeyCheck        cmp   #"q"
                    beq   :quitHit
                    cmp   #"Q"
                    beq   :quitHit
                    rts
:quitHit            lda   #1
                    sta   QuitFlag
                    rts
PauseKeyCheck       cmp   #"p"
                    beq   :pauseHit
                    cmp   #"P"
                    beq   :pauseHit
                    cmp   #$9b               ; ESC KEY
                    beq   :pauseHit
                    rts
:pauseHit           jsr   WaitKey            ; simply pause until key is hit
                    cmp   #"t"
                    bne   :notTelling        ; totally secret sauce
                    sta   $c051
:notTelling
                    cmp   #"T"
                    bne   :meNeither         ; secret un-sauce
                    jsr   DL_SetDLRMode
:meNeither
                    jsr   QuitKeyCheck       ; they can quit from paused game
                    lda   #0
                    rts

BIRD_VELOCITY       db    0                  ; in two's compliment {-3,3} 
BIRD_VELOCITY_MAX   equ   #20
BIRD_VELOCITY_MIN   equ   #%111111111        ; -1
LoadHiScore         jsr   CreateHiScoreFile
                    bcs   :error
                    jsr   OpenHiScoreFile
                    bcs   :error
                    jsr   ReadHiScoreFile
                    jsr   CloseHiScoreFile
:error              rts

SaveHiScore         jsr   CreateHiScoreFile
                    jsr   OpenHiScoreFile
                    bcc   :noError
                    rts
:noError            jsr   WriteHiScoreFile
                    jsr   CloseHiScoreFile
                    rts

CreateHiScoreFile
                    jsr   MLI
                    dfb   $C0
                    da    CreateHiScoreParam
                    bcs   :error
                    rts
:error              cmp   #$47               ; dup filename - already created?
                    bne   :bail
                    clc                      ; this is ok, clear error state
:bail               rts                      ; oh well... just carry on in session 

OpenHiScoreFile
                    jsr   MLI
                    dfb   $C8                ; OPEN P8 request ($C8)
                    da    OpenHiScoreParam
                    bcc   :noError
                    brk   $10
                    cmp   $46                ; "$46 - File not found"
                    beq   CreateHiScoreFile  ; let's create it if we can and try again
                    rts                      ; return with error state
:noError            rts


ReadHiScoreFile
                    lda   #0
                    sta   IOBuffer
                    sta   IOBuffer+1         ;zero load area, just in case
                    lda   OpenRefNum
                    sta   ReadRefNum
                    jsr   MLI
                    dfb   $CA                ; READ P8 request ($CA)
                    da    ReadHiScoreParam
                    bcs   :readFail

                    lda   ReadResult
                    lda   IOBuffer
                    sta   HiScoreHi
                    lda   IOBuffer+1
                    sta   HiScoreLo
                    rts

:readFail           cmp   #$4C               ;eof - ok on new file
                    beq   :giveUp

                    brk   $99                ; uhm
:giveUp             rts                      ; return with error state


CloseHiScoreFile
                    lda   OpenRefNum
                    sta   CloseRefNum
                    jsr   MLI
                    dfb   $CC                ; CLOSE P8 request ($CC)
                    da    CloseHiScoreParam
                    bcc   :ret
:ret                rts                      ; return with error state - not checked!

WriteHiScoreFile
                    lda   HiScoreHi
                    sta   IOBuffer
                    lda   HiScoreLo
                    sta   IOBuffer+1
                    lda   OpenRefNum
                    sta   WriteRefNum
                    jsr   MLI
                    dfb   $CB                ; READ P8 request ($CB)
                    da    WriteHiScoreParam
                    bcs   :writeFail
                    lda   WriteResult
:writeFail
                    rts


OpenHiScoreParam
                    dfb   #$03               ; number of parameters 
                    dw    HiScoreFile
                    dw    $900
OpenRefNum          db    0                  ; assigned by open call
HiScoreFile         str   'flaphi'


CloseHiScoreParam
                    dfb   #$01               ; number of parameters 
CloseRefNum         db    0


CreateHiScoreParam
                    dfb   7                  ; number of parameters
                    dw    HiScoreFile        ; pointer to filename
                    dfb   $C3                ; normal (full) file access permitted
                    dfb   $06                ; make it a $06 (bin) file
                    dfb   $00,$00            ; AUX_TYPE, not used
                    dfb   $01                ; standard file
                    dfb   $00,$00            ; creation date (unused)
                    dfb   $00,$00            ; creation time (unused)


ReadHiScoreParam
                    dfb   4                  ; number of parameters
ReadRefNum          db    0                  ; set by open subroutine above
                    da    IOBuffer
                    dw    #2                 ; request count (length)
ReadResult          dw    0                  ; result count (amount actually read before EOF)


WriteHiScoreParam
                    dfb   4                  ; number of parameters
WriteRefNum         db    0                  ; set by open subroutine above
                    da    IOBuffer
                    dw    #2                 ; request count (length)
WriteResult         dw    0                  ; result count (amount transferred)


Quit                jsr   QRPause
                    sta   TXTPAGE1           ; Don't forget to give them back the right page!
                    jsr   MLI                ; first actual command, call ProDOS vector
                    dfb   $65                ; QUIT P8 request ($65)
                    da    QuitParm
                    bcs   Error
                    brk   $00                ; shouldn't ever  here!
Error               brk   $00                ; shouldn't be here either

QuitParm            dfb   4                  ; number of parameters
                    dfb   0                  ; standard quit type
                    da    $0000              ; not needed when using standard quit
                    dfb   0                  ; not used
                    da    $0000              ; not used


QuitFlag            db    0                  ; set to 1 to quit

                    ds    \
IOBuffer            ds    512


QRPause             jsr   DL_SetDLRMixMode
                    lda   #$ff
                    jsr   DL_Clear
                    lda   #" "
                    jsr   DL_MixClearText
                    jsr   DrawQRCode
                    ldx   #0
                    ldy   #0
                    sta   TXTPAGE1
:loop               lda   QuitStr+1,x
                    sta   Lo22+12,y
                    iny
                    inx
                    inx
                    cpx   QuitStr
                    bcc   :loop
                    ldx   #1
                    ldy   #0
                    sta   TXTPAGE2
:loop2              lda   QuitStr+1,x
                    sta   Lo22+13,y
                    iny
                    inx
                    inx
                    cpx   QuitStr
                    bcc   :loop2
                    ldx   #5
                    ldy   #60
                    jsr   WaitKeyXY
                    rts
QuitStr             str   "http://dagenbrock.com/flappy"

******************************
* Score Routines
*********************
ScoreLo             db    0                  ; 0-99
ScoreHi             db    0                  ; hundreds, not shown on screen
HiScoreLo           db    0
HiScoreHi           db    0
** Draw the Score - @todo - handle > 99
DrawScore           lda   ScoreLo
                    and   #$0F
                    ldy   #21
                    jsr   DrawNum
                    lda   ScoreLo
                    lsr
                    lsr
                    lsr
                    lsr
                    tax
                    ldy   #19
                    jsr   DrawNum
                    lda   #$FF
                    sta   TXTPAGE1
                    sta   Lo01+18
                    sta   Lo02+18
                    rts

** HANDLE HIGH SCORE	
UpdateHiScore
                    lda   HiScoreHi
                    cmp   ScoreHi
                    bcc   :newHighScore
                    bne   :noHighScore
                    lda   HiScoreLo          ;high byte equal so compare base byte
                    cmp   ScoreLo
                    bcc   :newHighScore
                    bcs   :noHighScore


:newHighScore       lda   ScoreHi
                    sta   HiScoreHi
                    lda   ScoreLo
                    sta   HiScoreLo
                    jsr   SaveHiScore
:noHighScore        rts




**************************************************
* Grass 
**************************************************
UpdateGrass         inc   GrassState
                    lda   GrassState
                    cmp   #4
                    bne   :noReset
                    lda   #0
                    sta   GrassState
:noReset
                    sta   TXTPAGE2
                    ldx   GrassState
                    lda   GrassTop,x         ; top[0]
                    tax
                    lda   MainAuxMap,x
                    sta   Lo23
                    sta   Lo23+2
                    sta   Lo23+4
                    sta   Lo23+6
                    sta   Lo23+8
                    sta   Lo23+10
                    sta   Lo23+12
                    sta   Lo23+14
                    sta   Lo23+16
                    sta   Lo23+18
                    sta   Lo23+20
                    sta   Lo23+22
                    sta   Lo23+24
                    sta   Lo23+26
                    sta   Lo23+28
                    sta   Lo23+30
                    sta   Lo23+32
                    sta   Lo23+34
                    sta   Lo23+36
                    sta   Lo23+38
                    ldx   GrassState
                    lda   GrassBot,x         ; Bot[0]
                    tax
                    lda   MainAuxMap,x
                    sta   Lo24
                    sta   Lo24+2
                    sta   Lo24+4
                    sta   Lo24+6
                    sta   Lo24+8
                    sta   Lo24+10
                    sta   Lo24+12
                    sta   Lo24+14
                    sta   Lo24+16
                    sta   Lo24+18
                    sta   Lo24+20
                    sta   Lo24+22
                    sta   Lo24+24
                    sta   Lo24+26
                    sta   Lo24+28
                    sta   Lo24+30
                    sta   Lo24+32
                    sta   Lo24+34
                    sta   Lo24+36
                    sta   Lo24+38
                    ldx   GrassState
                    lda   GrassTop+2,x       ; top[2]
                    tax
                    lda   MainAuxMap,x
                    sta   Lo23+1
                    sta   Lo23+3
                    sta   Lo23+5
                    sta   Lo23+7
                    sta   Lo23+9
                    sta   Lo23+11
                    sta   Lo23+13
                    sta   Lo23+15
                    sta   Lo23+17
                    sta   Lo23+19
                    sta   Lo23+21
                    sta   Lo23+23
                    sta   Lo23+25
                    sta   Lo23+27
                    sta   Lo23+29
                    sta   Lo23+31
                    sta   Lo23+33
                    sta   Lo23+35
                    sta   Lo23+37
                    sta   Lo23+39
                    ldx   GrassState
                    lda   GrassBot+2,x       ; Bot[2]
                    tax
                    lda   MainAuxMap,x
                    sta   Lo24+1
                    sta   Lo24+3
                    sta   Lo24+5
                    sta   Lo24+7
                    sta   Lo24+9
                    sta   Lo24+11
                    sta   Lo24+13
                    sta   Lo24+15
                    sta   Lo24+17
                    sta   Lo24+19
                    sta   Lo24+21
                    sta   Lo24+23
                    sta   Lo24+25
                    sta   Lo24+27
                    sta   Lo24+29
                    sta   Lo24+31
                    sta   Lo24+33
                    sta   Lo24+35
                    sta   Lo24+37
                    sta   Lo24+39

                    sta   TXTPAGE1
                    ldx   GrassState
                    lda   GrassTop+1,x       ; top[1]
                    sta   Lo23
                    sta   Lo23+2
                    sta   Lo23+4
                    sta   Lo23+6
                    sta   Lo23+8
                    sta   Lo23+10
                    sta   Lo23+12
                    sta   Lo23+14
                    sta   Lo23+16
                    sta   Lo23+18
                    sta   Lo23+20
                    sta   Lo23+22
                    sta   Lo23+24
                    sta   Lo23+26
                    sta   Lo23+28
                    sta   Lo23+30
                    sta   Lo23+32
                    sta   Lo23+34
                    sta   Lo23+36
                    sta   Lo23+38
                    lda   GrassBot+1,x       ; Bot[1]
                    sta   Lo24
                    sta   Lo24+2
                    sta   Lo24+4
                    sta   Lo24+6
                    sta   Lo24+8
                    sta   Lo24+10
                    sta   Lo24+12
                    sta   Lo24+14
                    sta   Lo24+16
                    sta   Lo24+18
                    sta   Lo24+20
                    sta   Lo24+22
                    sta   Lo24+24
                    sta   Lo24+26
                    sta   Lo24+28
                    sta   Lo24+30
                    sta   Lo24+32
                    sta   Lo24+34
                    sta   Lo24+36
                    sta   Lo24+38
                    lda   GrassTop+3,x       ; top[3]
                    sta   Lo23+1
                    sta   Lo23+3
                    sta   Lo23+5
                    sta   Lo23+7
                    sta   Lo23+9
                    sta   Lo23+11
                    sta   Lo23+13
                    sta   Lo23+15
                    sta   Lo23+17
                    sta   Lo23+19
                    sta   Lo23+21
                    sta   Lo23+23
                    sta   Lo23+25
                    sta   Lo23+27
                    sta   Lo23+29
                    sta   Lo23+31
                    sta   Lo23+33
                    sta   Lo23+35
                    sta   Lo23+37
                    sta   Lo23+39
                    lda   GrassBot+3,x       ; bot[3]
                    sta   Lo24+1
                    sta   Lo24+3
                    sta   Lo24+5
                    sta   Lo24+7
                    sta   Lo24+9
                    sta   Lo24+11
                    sta   Lo24+13
                    sta   Lo24+15
                    sta   Lo24+17
                    sta   Lo24+19
                    sta   Lo24+21
                    sta   Lo24+23
                    sta   Lo24+25
                    sta   Lo24+27
                    sta   Lo24+29
                    sta   Lo24+31
                    sta   Lo24+33
                    sta   Lo24+35
                    sta   Lo24+37
                    sta   Lo24+39
                    rts

GrassState          db    00
GrassTop            hex   CE,CE,4E,4E,CE,CE,4E,4E
GrassBot            hex   4C,44,44,4C,4C,44,44,4C

WaitKey
:kloop              lda   KEY
                    bpl   :kloop
                    sta   STROBE
                    rts

WaitKeyXY
                    stx   _waitX
:kloop              jsr   VBlank
                    lda   KEY
                    bmi   :kpress
                    dex
                    bne   :kloop
                    ldx   _waitX
                    dey
                    bne   :kloop
                    clc
                    rts

:kpress             sta   STROBE
                    jsr   QuitKeyCheck
                    sec
                    rts
_waitX              db    0

**************************************************
* See if we're running on a IIgs
* From Apple II Technote: 
*   Miscellaneous #7
*   Apple II Family Identification
**************************************************
DetectMachine
                    sec                      ;Set carry bit (flag)
                    jsr   $FE1F              ;Call to the monitor
                    bcs   :oldmachine        ;If carry is still set, then old machine
*	bcc :newmachine    ;If carry is clear, then new machine
:newmachine         asl   _compType          ;multiply vblank detection val $7E * 2
                    lda   #1
                    bne   :setmachine
:oldmachine         lda   #0
:setmachine         sta   GMachineIIgs

                    jsr   InitVBlank
                    rts

GMachineIIgs        db    0

IntroWipe
                    sta   C80STOREON
                    lda   #"="
                    ldx   #"-"
                    ldy   #" "
                    jsr   DL_WipeInNoNib
                    sta   TXTPAGE1
                    ldx   #1
:loop               lda   IntroText,x
                    beq   :done
                    sta   Lo12+10,x
                    inx
                    cpx   IntroText          ; length byte
                    bne   :loop
:done
                    ldx   #90
                    ldy   #1
                    jsr   WaitKeyXY
                    rts
IntroText           str   "Dagen Brock presents..."



**************************************************
* Wait for vertical blanking interval - IIe/IIgs
**************************************************
VBlankX
:xloop              txa
                    pha
                    jsr   VBlank
                    pla
                    tax
                    dex
                    bne   :xloop
                    rts


InitVBlank
                    lda   $FBC0              ; check for IIc
                    bne   :rts               ; not a IIc--use VBlankIIeIIgs

                    jsr   MLI                ; instantiate our interrupt
                    dfb   $40
                    da    VBLIntParm

                    lda   #%00001000         ; enable vblint only
                    ldx   #SETMOUSE
                    jsr   mouse

                    lda   #VBlankIIc         ; override vblank
                    sta   VBlankRoutine
                    lda   #>VBlankIIc
                    sta   VBlankRoutine+1

                    cli

:rts                rts


VBLIntParm          dfb   2
                    brk                      ;?
                    da    VBLIntHandler

VBLIntHandler       cld                      ; Expected by ProDOS
                    ldx   #SERVEMOUSE
                    jsr   mouse
                    bcs   :notOurs           ; pass if not
                    sec
                    ror   _vblflag           ;set hibit

                    clc
:notOurs            rts

mouse               ldy   $C400,x
                    sty   :jump+1

                    ldx   #$C4
                    ldy   #$40

                    sei
:jump               jmp   $C400




MOUSE               =     $c400              ; mouse = slot 4
*SETMOUSE	=   $c412	; Apple IIc Ref p.168
*SERVEMOUSE	=   $c413	; Apple IIc Ref p.168

SETMOUSE            =     $12
SERVEMOUSE          =     $13
READMOUSE           =     $14
INITMOUSE           =     $19

VBlank              jmp   VBlankIIeIIgs
VBlankRoutine       equ   *-2
VBlankIIc
                    cli                      ;enable interrupts

:loop1              bit   _vblflag
                    bpl   :loop1             ;wait for vblflag = 1
                    lsr   _vblflag           ;...& set vblflag = 0

*:loop2	bit _vblflag
*	bpl :loop2
*	lsr _vblflag

                    sei
                    rts
_vblflag            db    0

VBlankIIeIIgs
                    lda   _compType
:vblActive          cmp   RDVBLBAR           ; make sure we wait for the current one to stop
                    bpl   :vblActive         ; in case it got launched in rapid succession
:screenActive       cmp   RDVBLBAR
                    bmi   :screenActive
                    rts

_compType           db    #$7e               ; $7e - IIe ; $FE - IIgs 





                    put   util
                    put   applerom
                    put   dlrlib
                    put   pipes
                    put   numbers
                    put   soundengine
                    put   bird


