*********
* Well... optimized number drawing because, why not
****

BB             equ   #$00
BW             equ   #$F0
WB             equ   #$0F
WW             equ   #$FF

DrawNum_Table  da    DrawNum_0
               da    DrawNum_1
               da    DrawNum_2
               da    DrawNum_3
               da    DrawNum_4
               da    DrawNum_5
               da    DrawNum_6
               da    DrawNum_7
               da    DrawNum_8
               da    DrawNum_9

* y = x, a=val (0-9)
DrawNum
               asl
               tax
               lda   DrawNum_Table,x
               sta   :jsrPtr+1
               lda   DrawNum_Table+1,x
               sta   :jsrPtr+2
               tya
               tax
:jsrPtr        jsr   DrawNum_0
               rts

* x = x offset (even cols)  0-40
DrawNum_0      sta   TXTPAGE2
               lda   #BB
               sta   Lo01,x
               sta   Lo02,x
               sta   Lo01+1,x
               sta   Lo02+1,X
               sta   TXTPAGE1
               lda   #BW
               sta   Lo01,x
               lda   #WB
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_1      sta   TXTPAGE2
               lda   #BW
               sta   Lo01,x
               lda   #WB
               sta   Lo02,x
               sta   Lo02+1,x
               lda   #WW
               sta   Lo01+1,x
               sta   TXTPAGE1
               sta   Lo01+1,x
               sta   Lo02+1,x
               lda   #BB
               sta   Lo01,x
               sta   Lo02,x
               rts

DrawNum_2      sta   TXTPAGE2
               lda   #BW
               sta   Lo01,x
               lda   #WB
               sta   Lo02+1,x
               lda   #BB
               sta   Lo02,x
               sta   Lo01+1,x
               sta   TXTPAGE1
               sta   Lo01,x
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_3      sta   TXTPAGE2
               lda   #BW
               sta   Lo01,x
               lda   #WB
               sta   Lo02,x
               lda   #BB
               sta   Lo01+1,x
               sta   Lo02+1,x
               sta   TXTPAGE1
               sta   Lo01,x
               lda   #WB
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_4      sta   TXTPAGE2
               lda   #BB
               sta   Lo01,x
               sta   Lo01+1,x
               sta   Lo02+1,x
               lda   #BW
               sta   Lo02,x
               sta   TXTPAGE1
               sta   Lo02,x
               lda   #WW
               sta   Lo01,x
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_5      sta   TXTPAGE2
               lda   #BW
               sta   Lo01+1,x
               lda   #WB
               sta   Lo02,x
               lda   #BB
               sta   Lo01,x
               sta   Lo02+1,x
               sta   TXTPAGE1
               sta   Lo01,x
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_6      sta   TXTPAGE2
               lda   #BB
               sta   Lo01,x
               sta   Lo02,x
               sta   Lo02+1,x
               lda   #WB
               sta   Lo01+1,x
               sta   TXTPAGE1
               sta   Lo01,x
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_7      sta   TXTPAGE2
               lda   #BW
               sta   Lo01,x
               lda   #WW
               sta   Lo02,x
               sta   Lo02+1,x
               lda   #BB
               sta   Lo01+1,x
               sta   TXTPAGE1
               sta   Lo02,x
               lda   #BW
               sta   Lo01,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_8      sta   TXTPAGE2
               lda   #WB
               sta   Lo01,x
               lda   #BB
               sta   Lo02,X
               sta   Lo01+1,x
               sta   Lo02+1,x
               sta   TXTPAGE1
               sta   Lo02,x
               lda   #BW
               sta   Lo01,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

DrawNum_9      sta   TXTPAGE2
               lda   #BB
               sta   Lo01,x
               sta   Lo01+1,x
               sta   Lo02+1,x
               lda   #BW
               sta   Lo02,x
               sta   TXTPAGE1
               sta   Lo01,x
               sta   Lo02,x
               lda   #WW
               sta   Lo01+1,x
               sta   Lo02+1,x
               rts

