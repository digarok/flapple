**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES          equ   $F832
LORES             equ   $C050
TXTSET            equ   $C051
MIXCLR            equ   $C052
MIXSET            equ   $C053
TXTPAGE1          equ   $C054
TXTPAGE2          equ   $C055
KEY               equ   $C000
C80STOREOFF       equ   $C000
C80STOREON        equ   $C001
STROBE            equ   $C010
SPEAKER           equ   $C030
VBL               equ   $C02E
RDVBLBAR          equ   $C019                   ;not VBL (VBL signal low

RAMWRTAUX         equ   $C005
RAMWRTMAIN        equ   $C004
SETAN3            equ   $C05E                   ;Set annunciator-3 output to 0
SET80VID          equ   $C00D                   ;enable 80-column display mode (WR-only)


