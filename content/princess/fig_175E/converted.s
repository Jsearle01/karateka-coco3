* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_175E
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

fig_175E_coco3:
        fcb     23,9  ; height=23 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $00,$00,$FF,$F0,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$0F,$FF,$FC,$00,$00,$00,$00,$00  ; row 1
        fcb     $00,$0F,$FF,$FF,$00,$00,$00,$00,$00  ; row 2
        fcb     $00,$04,$0F,$FF,$C0,$00,$00,$00,$00  ; row 3
        fcb     $00,$00,$5F,$FF,$F0,$00,$00,$00,$00  ; row 4
        fcb     $00,$00,$55,$FF,$FF,$C0,$00,$00,$00  ; row 5
        fcb     $00,$00,$55,$FD,$F0,$00,$00,$00,$00  ; row 6
        fcb     $00,$03,$FD,$FC,$40,$00,$00,$00,$00  ; row 7
        fcb     $00,$03,$FD,$FC,$40,$00,$00,$00,$00  ; row 8
        fcb     $00,$0F,$FF,$FC,$5F,$C0,$00,$00,$00  ; row 9
        fcb     $00,$04,$0F,$FC,$5F,$F0,$00,$00,$00  ; row 10
        fcb     $00,$54,$00,$3D,$FF,$F0,$00,$00,$00  ; row 11
        fcb     $00,$40,$00,$55,$FF,$F0,$00,$00,$00  ; row 12
        fcb     $05,$40,$03,$C5,$FF,$C0,$00,$00,$00  ; row 13
        fcb     $04,$00,$05,$5F,$FF,$00,$00,$00,$00  ; row 14
        fcb     $00,$00,$3C,$5F,$F0,$00,$00,$00,$00  ; row 15
        fcb     $00,$00,$FF,$FF,$FF,$00,$00,$00,$00  ; row 16
        fcb     $00,$00,$3F,$FF,$FF,$F0,$00,$00,$00  ; row 17
        fcb     $2A,$AA,$AB,$FF,$FF,$FC,$2A,$AA,$A0  ; row 18
        fcb     $00,$00,$00,$FF,$FF,$FF,$C0,$00,$00  ; row 19
        fcb     $2A,$AA,$AA,$BF,$DF,$FF,$FC,$2A,$A0  ; row 20
        fcb     $00,$00,$00,$03,$F0,$FF,$FF,$C0,$00  ; row 21
        fcb     $00,$00,$00,$05,$40,$05,$40,$00,$00  ; row 22
