DL_SetDLRMode lda LORES     ;set lores
	lda SETAN3	;enables DLR
	sta SET80VID
	
	sta C80STOREON ; enable aux/page1,2 mapping
	rts


DL_Clear	sta TXTPAGE1
	ldx #40
:loop	dex
	sta Lo01,x
	sta Lo02,x
	sta Lo03,x
	sta Lo04,x
	sta Lo05,x
	sta Lo06,x
	sta Lo07,x
	sta Lo08,x
	sta Lo09,x
	sta Lo10,x
	sta Lo11,x
	sta Lo12,x
	sta Lo13,x
	sta Lo14,x
	sta Lo15,x
	sta Lo16,x
	sta Lo17,x
	sta Lo18,x
	sta Lo19,x
	sta Lo20,x
	sta Lo21,x
	sta Lo22,x
	sta Lo23,x
	sta Lo24,x
	bne :loop
	tax	; get aux color value
	lda MainAuxMap,x
	sta TXTPAGE2	; turn on p2
	ldx #40
:loop2	dex
	sta Lo01,x
	sta Lo02,x
	sta Lo03,x
	sta Lo04,x
	sta Lo05,x
	sta Lo06,x
	sta Lo07,x
	sta Lo08,x
	sta Lo09,x
	sta Lo10,x
	sta Lo11,x
	sta Lo12,x
	sta Lo13,x
	sta Lo14,x
	sta Lo15,x
	sta Lo16,x
	sta Lo17,x
	sta Lo18,x
	sta Lo19,x
	sta Lo20,x
	sta Lo21,x
	sta Lo22,x
	sta Lo23,x
	sta Lo24,x
	bne :loop2
	rts 

**************************************************
* Lores/Text lines
**************************************************
Lo01	equ $400
Lo02	equ $480
Lo03	equ $500
Lo04	equ $580
Lo05	equ $600
Lo06	equ $680
Lo07	equ $700
Lo08	equ $780
Lo09	equ $428
Lo10	equ $4a8
Lo11	equ $528
Lo12	equ $5a8
Lo13	equ $628
Lo14	equ $6a8
Lo15	equ $728
Lo16	equ $7a8
Lo17	equ $450
Lo18	equ $4d0
Lo19	equ $550
Lo20	equ $5d0
* the "plus four" lines
Lo21	equ $650
Lo22	equ $6d0
Lo23	equ $750
Lo24	equ $7d0

LoLineTable	da Lo01,Lo02,Lo03,Lo04,Lo05,Lo06
	da Lo07,Lo08,Lo09,Lo10,Lo11,Lo12
	da Lo13,Lo14,Lo15,Lo16,Lo17,Lo18
	da Lo19,Lo20,Lo21,Lo22,Lo23,Lo24
MainAuxMap
	hex 00,08,01,09,02,0A,03,0B,04,0C,05,0D,06,0E,07,0F
	hex 80,88,81,89,82,8A,83,8B,84,8C,85,8D,86,8E,87,8F
	hex 10,18,11,19,12,1A,13,1B,14,1C,15,1D,16,1E,17,1F
	hex 90,98,91,99,92,9A,93,9B,94,9C,95,9D,96,9E,97,9F
	hex 20,28,21,29,22,2A,23,2B,24,2C,25,2D,26,2E,27,2F
	hex A0,A8,A1,A9,A2,AA,A3,AB,A4,AC,A5,AD,A6,AE,A7,AF
	hex 30,38,31,39,32,3A,33,3B,34,3C,35,3D,36,3E,37,3F
	hex B0,B8,B1,B9,B2,BA,B3,BB,B4,BC,B5,BD,B6,BE,B7,BF
	hex 40,48,41,49,42,4A,43,4B,44,4C,45,4D,46,4E,47,4F
	hex C0,C8,C1,C9,C2,CA,C3,CB,C4,CC,C5,CD,C6,CE,C7,CF
	hex 50,58,51,59,52,5A,53,5B,54,5C,55,5D,56,5E,57,5F
	hex D0,D8,D1,D9,D2,DA,D3,DB,D4,DC,D5,DD,D6,DE,D7,DF
	hex 60,68,61,69,62,6A,63,6B,64,6C,65,6D,66,6E,67,6F
	hex E0,E8,E1,E9,E2,EA,E3,EB,E4,EC,E5,ED,E6,EE,E7,EF
	hex 70,78,71,79,72,7A,73,7B,74,7C,75,7D,76,7E,77,7F
	hex F0,F8,F1,F9,F2,FA,F3,FB,F4,FC,F5,FD,F6,FE,F7,FF
