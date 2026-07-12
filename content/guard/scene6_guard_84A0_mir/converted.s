* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_84A0
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_84A0_mir:
        fcb     20,4  ; height=20 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$01,$00  ; row 0
        fcb     $80,$00,$0F,$00  ; row 1
        fcb     $FC,$10,$FF,$C0  ; row 2
        fcb     $F0,$FC,$3F,$C0  ; row 3
        fcb     $F0,$FC,$3F,$F0  ; row 4
        fcb     $FF,$FF,$FF,$F0  ; row 5
        fcb     $FF,$F0,$FF,$FC  ; row 6
        fcb     $FF,$F0,$3F,$FC  ; row 7
        fcb     $FF,$F0,$3F,$FC  ; row 8
        fcb     $FF,$F0,$0F,$FF  ; row 9
        fcb     $FF,$F0,$0F,$FF  ; row 10
        fcb     $FF,$F0,$3F,$FF  ; row 11
        fcb     $FF,$F0,$3F,$FC  ; row 12
        fcb     $3F,$F0,$FF,$FC  ; row 13
        fcb     $3F,$F0,$FF,$F0  ; row 14
        fcb     $3F,$F0,$AF,$C0  ; row 15
        fcb     $3F,$C0,$A8,$00  ; row 16
        fcb     $08,$00,$A8,$00  ; row 17
        fcb     $AA,$80,$08,$00  ; row 18
        fcb     $A8,$00,$00,$00  ; row 19
