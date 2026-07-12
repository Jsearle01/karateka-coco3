* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8557
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8557_mir:
        fcb     19,6  ; height=19 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $03,$C0,$00,$0F,$00,$00  ; row 0
        fcb     $03,$FC,$10,$FF,$00,$00  ; row 1
        fcb     $0F,$F0,$FC,$3F,$C0,$00  ; row 2
        fcb     $0F,$F0,$FC,$3F,$F0,$00  ; row 3
        fcb     $3F,$FF,$FF,$FF,$F0,$00  ; row 4
        fcb     $3F,$FF,$03,$FF,$FC,$00  ; row 5
        fcb     $FF,$FC,$00,$FF,$FC,$00  ; row 6
        fcb     $FF,$FC,$00,$3F,$FC,$00  ; row 7
        fcb     $FF,$F0,$00,$3F,$FF,$40  ; row 8
        fcb     $FF,$F0,$00,$0F,$FF,$40  ; row 9
        fcb     $FF,$C0,$00,$0F,$FF,$40  ; row 10
        fcb     $FF,$C0,$00,$0F,$FF,$40  ; row 11
        fcb     $FF,$C0,$00,$0F,$FC,$00  ; row 12
        fcb     $3F,$C0,$00,$0F,$FC,$00  ; row 13
        fcb     $3F,$C0,$00,$0F,$FC,$00  ; row 14
        fcb     $3F,$C0,$00,$0F,$FC,$00  ; row 15
        fcb     $08,$00,$00,$00,$80,$00  ; row 16
        fcb     $A8,$00,$00,$00,$A8,$00  ; row 17
        fcb     $A8,$00,$00,$00,$A8,$00  ; row 18
