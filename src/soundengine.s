
PlayFlappySong
	ldy #0
:loop	lda FlappySong,y
	cmp #NoteEnd
	beq :done
	cmp #NoteRest
	bne :notRest
	ldx FlappySong+1,y
	jsr VBlankX
	clc 
	bcc :nextNote
:notRest	ldx FlappySong+1,y
	jsr SENoteAX
	ldx #2
	jsr VBlankX
:nextNote	iny
	iny
	clc 
	bcc :loop
:done	rts


FlappySong	hex 72,22,72,22,56,22,01,0E
	hex 72,22,72,22,56,22,01,0E
	hex 72,22,72,22,56,22,01,0E
	hex 72,22,72,22,80,22,01,0E
	hex 72,22,72,22,56,22,01,0E
	hex 72,22,72,22,56,22,01,0E
	hex 72,22,72,22,4C,22,56,22
	hex 5B,22,72,22,5B,22,56,40
	hex 02	; end byte




**************************************************
* wrapper for SEplayNote 
* a = freq  ...  x = dur
**************************************************
SENoteAX	jsr _storeReg
	sta _SECURRNOTE
	stx _SECURRNOTE+1
	jsr SEplayNote
	jsr _loadReg
	rts


**************************************************
* 
**************************************************
	ds \

SEplayNote
	ldy _SECURRNOTE+1
:loop	lda SPEAKER
:whyWut	dey
	bne :thar
	dec _SECURRNOTE+1
	beq :doneThat
:thar	dex
	bne :whyWut
	ldx _SECURRNOTE
	jmp :loop
:doneThat	rts

SEplayNote_OLD
:loop	lda SPEAKER
:whyWut	dey
	bne :thar
	dec _SECURRNOTE+1
	beq :doneThat
:thar	dex
	bne :whyWut
	ldx _SECURRNOTE
	jmp :loop
:doneThat	rts


_SECURRNOTE	db 0,0	; current note being played (frequency/duration)



**************************************************
* This is essentially the scale
**************************************************
_SE_tones	db NoteG0,NoteGsharp0,NoteA0,NoteBflat0,NoteB0
	db NoteC1,NoteCsharp1,NoteD1,NoteDsharp1,NoteE1
	db NoteF1,NoteFsharp1,NoteG1,NoteGsharp1,NoteA1
	db NoteBflat1,NoteB1,NoteC2,NoteCsharp2,NoteD2
	db NoteDsharp2,NoteE2,NoteF2

NoteRest	equ $01	;\_ these are inaudible anyway
NoteEnd	equ $02	;/
NoteG0        equ $00       ; because it loops (underflow)
NoteGsharp0   equ $f0
NoteA0        equ $e6
NoteBflat0    equ $d5
NoteB0        equ $cb       ; speculating here on up
NoteC1        equ $c0
NoteCsharp1   equ $b5
NoteD1        equ $ac
NoteDsharp1   equ $a3
NoteE1        equ $99
NoteF1        equ $90
NoteFsharp1   equ $89
NoteG1        equ $80
NoteGsharp1   equ $79
NoteA1        equ $72
NoteBflat1    equ $6c
NoteB1        equ $66
NoteC2        equ $60
NoteCsharp2   equ $5b
NoteD2        equ $56
NoteDsharp2   equ $51
NoteE2        equ $4c
NoteF2        equ $48
                            ; starts to suck here anyway


SErandStatic
	ldy #$ff
:loop	lda SPEAKER
	jsr GetRand
	tax
	beq :next
:wait	dex
	bne :wait
:next	dey
	bne :loop
	rts

* y = length
SErandStaticBit
:loop	lda SPEAKER
	jsr GetRand
	lsr
	tax
	beq :next
:wait	dex
	bne :wait
:next	dey
	bne :loop
	rts

* y = length	 - no shift so wider range
SErandStaticBit2
:loop	lda SPEAKER
	jsr GetRand
	tax
	beq :next
:wait	dex
	bne :wait
:next	dey
	bne :loop
	rts

