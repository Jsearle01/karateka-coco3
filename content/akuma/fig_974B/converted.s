* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05 by addr
*         Apple II label: addr_974B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

fig_974B_coco3:
        fcb     43,11  ; height=43 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $F2,$AA,$AA,$AB,$C5,$55,$5F,$FF,$FF,$FF,$F0  ; row 0
        fcb     $F0,$2A,$AA,$AB,$C5,$55,$5F,$FF,$FF,$FF,$F0  ; row 1
        fcb     $55,$F2,$AA,$A0,$40,$54,$05,$55,$55,$55,$F0  ; row 2
        fcb     $FF,$F2,$AA,$A0,$00,$00,$00,$55,$55,$5F,$F0  ; row 3
        fcb     $FF,$FC,$2A,$A0,$00,$00,$00,$55,$5F,$FF,$F0  ; row 4
        fcb     $FF,$F0,$2A,$A0,$00,$00,$00,$00,$00,$00,$00  ; row 5
        fcb     $FF,$C0,$02,$A0,$00,$00,$00,$00,$00,$00,$00  ; row 6
        fcb     $FF,$FF,$02,$A0,$00,$00,$00,$00,$00,$00,$00  ; row 7
        fcb     $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 8
        fcb     $FF,$FF,$C4,$00,$00,$00,$00,$00,$FF,$FC,$00  ; row 9
        fcb     $FF,$FF,$FC,$00,$00,$00,$00,$05,$FF,$FF,$00  ; row 10
        fcb     $FF,$FF,$FC,$40,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 11
        fcb     $FF,$FF,$FF,$C0,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 12
        fcb     $FF,$FF,$FF,$C4,$00,$00,$00,$5F,$FF,$FF,$F0  ; row 13
        fcb     $FF,$FF,$FF,$FC,$00,$00,$00,$FF,$FF,$FF,$F0  ; row 14
        fcb     $FF,$FF,$FF,$FC,$40,$00,$05,$FF,$FF,$FF,$F0  ; row 15
        fcb     $FF,$FF,$FF,$FF,$00,$00,$0F,$FF,$FF,$FF,$F0  ; row 16
        fcb     $FF,$FF,$FF,$FF,$00,$00,$0F,$FF,$FF,$FF,$F0  ; row 17
        fcb     $FF,$FF,$F2,$A0,$40,$00,$05,$FF,$FF,$FF,$F0  ; row 18
        fcb     $FF,$FF,$F2,$00,$00,$00,$00,$FF,$FF,$FF,$F0  ; row 19
        fcb     $FF,$FF,$2A,$00,$00,$00,$00,$5F,$FF,$FF,$F0  ; row 20
        fcb     $FF,$FC,$2A,$00,$00,$00,$00,$5F,$FF,$FF,$F0  ; row 21
        fcb     $FF,$FF,$FF,$C0,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 22
        fcb     $FF,$FF,$FF,$C0,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 23
        fcb     $FF,$FF,$FF,$C0,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 24
        fcb     $FF,$FF,$FF,$C0,$00,$00,$00,$0F,$FF,$FF,$F0  ; row 25
        fcb     $FF,$FF,$FC,$40,$00,$00,$00,$05,$FF,$FF,$F0  ; row 26
        fcb     $FF,$FF,$FC,$40,$00,$00,$00,$05,$FF,$FF,$F0  ; row 27
        fcb     $FF,$FF,$FC,$00,$00,$00,$00,$00,$FF,$FF,$F0  ; row 28
        fcb     $FF,$FF,$FC,$00,$00,$00,$00,$00,$FF,$FF,$F0  ; row 29
        fcb     $FF,$FF,$FC,$00,$00,$00,$00,$00,$FF,$FF,$F0  ; row 30
        fcb     $FF,$FF,$FC,$00,$00,$00,$00,$00,$FF,$FF,$F0  ; row 31
        fcb     $FF,$FF,$C4,$00,$00,$00,$00,$00,$5F,$FF,$F0  ; row 32
        fcb     $FF,$FF,$C4,$00,$00,$00,$00,$00,$5F,$FF,$F0  ; row 33
        fcb     $FF,$FF,$C0,$00,$00,$00,$00,$00,$0F,$FF,$F0  ; row 34
        fcb     $FF,$FF,$C0,$00,$00,$00,$00,$00,$0F,$FF,$F0  ; row 35
        fcb     $FF,$FF,$C0,$00,$00,$00,$00,$00,$0F,$FF,$F0  ; row 36
        fcb     $FF,$FF,$C0,$00,$00,$00,$00,$00,$0F,$FF,$F0  ; row 37
        fcb     $FF,$FC,$40,$00,$00,$00,$00,$00,$05,$FF,$F0  ; row 38
        fcb     $FF,$FC,$40,$00,$00,$00,$00,$00,$05,$FF,$F0  ; row 39
        fcb     $FF,$FC,$00,$00,$00,$00,$00,$00,$00,$FF,$F0  ; row 40
        fcb     $FF,$FC,$00,$00,$00,$00,$00,$00,$00,$FF,$F0  ; row 41
        fcb     $FF,$FC,$00,$00,$00,$00,$00,$00,$00,$FF,$F0  ; row 42
