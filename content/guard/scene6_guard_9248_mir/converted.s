* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9248
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9248_mir:
        fcb     10,13  ; height=10 rows, coco3_width=13 bytes/row (4px/byte)
        fcb     $FF,$C2,$AB,$FF,$FF,$FF,$F0,$FF,$FF,$00,$FF,$FF,$C0  ; row 0
        fcb     $FF,$C2,$AB,$FF,$FF,$FF,$F0,$FA,$BF,$00,$00,$3F,$C0  ; row 1
        fcb     $FF,$FF,$DF,$FF,$FF,$FF,$C0,$FA,$BF,$00,$00,$0F,$C0  ; row 2
        fcb     $FF,$FF,$AA,$AB,$FF,$FF,$00,$FA,$AA,$00,$00,$0F,$C0  ; row 3
        fcb     $FF,$FC,$2A,$AB,$FF,$FF,$00,$3F,$AA,$00,$00,$0F,$C0  ; row 4
        fcb     $FF,$FC,$2A,$AB,$FF,$FF,$04,$3F,$FF,$00,$00,$0F,$C0  ; row 5
        fcb     $FF,$FF,$FF,$C3,$FF,$FF,$04,$3F,$FF,$00,$00,$0F,$C0  ; row 6
        fcb     $FF,$FF,$FF,$03,$FF,$FF,$FC,$3F,$FF,$00,$0F,$FF,$C0  ; row 7
        fcb     $FF,$FC,$00,$00,$00,$0F,$FF,$0F,$FF,$00,$00,$00,$40  ; row 8
        fcb     $FF,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40  ; row 9
