** Register preservation
_sX               dw    0
_sY               dw    0
_sA               dw    0
_storeReg         sta   _sA
                  stx   _sX
                  sty   _sY
                  rts
_loadReg          lda   _sA
                  ldx   _sX
                  ldy   _sY
                  rts

**************************************************
* Awesome PRNG thx to White Flame (aka David Holz)
**************************************************
GetRand
                  lda   _randomByte
                  beq   :doEor
                  asl
                  bcc   :noEor
:doEor            eor   #$1d
:noEor            sta   _randomByte
                  rts
_randomByte       db    0

GetRandLow
                  lda   _randomByte2
                  beq   :doEor
                  asl
                  bcc   :noEor
:doEor            eor   #$1d
:noEor            sta   _randomByte2
                  cmp   #$80
                  bcs   :hot
                  lda   #$0
                  rts
:hot              lda   #$04
                  rts

_randomByte2      db    0




