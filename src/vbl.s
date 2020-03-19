
OP_BPL              =     #$10
OP_BMI              =     #$30

SetupVBL
                    lda   $FBB3              ; machine id byte (A2Misc TN #7)
                    cmp   #$06               ; IIe, IIc, IIgs
                    bne   :foundII           ; II, II+

                    lda   $FBC0              ; machine id byte (A2Misc TN #7)
                    beq   :foundIIc          ; IIc = FBB3:06 FBC0:00

                    sec
                    jsr   $FE1F              ; Check for IIgs compatibility routine
                    bcs   :foundIIe
                    bcc   :foundIIgs

:foundII            lda   #$60               ; RTS opcode
                    sta   WaitVBL
                    rts

:foundIIc           lda   #$EA               ; NOP opcode
                    sta   ShutDownVBL
                    lda   #OP_BPL            ; BPL opcode
                    sta   __waitRasterOp
                    lda   #$70
                    sta   __patchVBLIIc+1
                    lda   #$60
                    sta   __patchVBLIIc+3

                    sei
                    sta   $C07F              ; enable access to VBL register
                    sta   $C05B              ; enable VBL polling
                    sta   $C07E              ; disable access to VBL register
                    rts

:foundIIe           lda   #OP_BPL            ; BPL opcode
                    sta   __waitRasterOp
                    lda   #OP_BMI            ; BMI opcode
                    sta   __waitVBLOp
:foundIIgs          rts

ShutDownVBL         rts                      ; SMC
:lastVBL            bit   $C019
                    bpl   :lastVBL
                    lda   $C070              ; $c019 bit 7 is sticky, reset it
                    sta   $C07F              ; enable access to VBL register
                    sta   $C05A              ; disable VBL polling
                    sta   $C07E              ; disable access to VBL register
                    cli
                    rts

* This function gets modified based on System: II(+), IIe, IIc, IIgs
WaitVBL
:waitRaster         lda   $c019
                    bmi   :waitRaster        ; make sure we are screen area first, (VBL=0) on IIgs, !SMC IIe/c
__waitRasterOp      =     *-2
__patchVBLIIc       =     *
:waitVBL            lda   $c019
                    bpl   :waitVBL           ; as soon as blanking starts return, (VBL=1) on IIgs, !SMC IIe/c
__waitVBLOp         =     *-2
                    rts

