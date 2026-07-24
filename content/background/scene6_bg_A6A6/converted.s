* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A6A6
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=216  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A6A6:
        fcb     6,7  ; height=6 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$AA,$AA,$AA  ; row 0
        fcb     $10,$00,$00,$00,$15,$55,$57  ; row 1
        fcb     $A8,$00,$00,$00,$00,$AA,$AA  ; row 2
        fcb     $15,$50,$00,$00,$00,$01,$57  ; row 3
        fcb     $AA,$A8,$00,$00,$00,$00,$AA  ; row 4
        fcb     $15,$55,$50,$00,$00,$00,$03  ; row 5
