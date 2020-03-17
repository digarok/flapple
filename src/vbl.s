
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
                    sei
                    sta   $C07F              ; enable access to VBL register
                    sta   $C05B              ; enable VBL polling
                    sta   $C07E              ; disable access to VBL register
                    lda   #$EA               ; NOP opcode
                    sta   __waitVBLIIcPassthru
:foundIIe           lda   #$10               ; BPL opcode
                    sta   __waitRasterOp
                    lda   #$30               ; BMI opcode
                    sta   __waitVBLOp
:foundIIgs          rts

ShutDownVBL         rts                      ; SMC
                    sta   $C07F              ; enable access to VBL register
                    sta   $C05A              ; disable VBL polling
                    sta   $C07E              ; disable access to VBL register
                    lda   $C070              ; $c019 bit 7 is sticky, reset it
                    cli
                    rts

* This function gets modified based on System: II(+), IIe, IIc, IIgs
WaitVBL
:waitRaster         bit   $c019
                    bmi   :waitRaster        ; make sure we are screen area first, (VBL=0) on IIgs, !SMC IIe/c
__waitRasterOp      =     *-2
:waitVBL            bit   $c019
                    bpl   :waitVBL           ; as soon as blanking starts return, (VBL=1) on IIgs, !SMC IIe/c
__waitVBLOp         =     *-2
__waitVBLIIcPassthru rts
                    lda   $C070              ; $c019 bit 7 is sticky on IIc, reset it
                    rts

