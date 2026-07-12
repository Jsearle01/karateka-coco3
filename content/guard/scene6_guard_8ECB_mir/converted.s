* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8ECB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8ECB_mir:
        fcb     10,4  ; height=10 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $08,$00,$01,$00  ; row 0
        fcb     $10,$00,$00,$80  ; row 1
        fcb     $10,$00,$00,$80  ; row 2
        fcb     $3C,$0A,$83,$C0  ; row 3
        fcb     $3E,$AA,$FF,$C0  ; row 4
        fcb     $08,$00,$FF,$00  ; row 5
        fcb     $00,$AA,$A8,$00  ; row 6
        fcb     $00,$AA,$A8,$00  ; row 7
        fcb     $00,$AA,$80,$00  ; row 8
        fcb     $00,$0A,$80,$00  ; row 9
