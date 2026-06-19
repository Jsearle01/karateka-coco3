* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr
*         Apple II label: addr_8F2B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_8F2B_coco3:
        fcb     10,6  ; height=10 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$10,$10,$00,$00,$00  ; row 0
        fcb     $00,$80,$80,$00,$00,$00  ; row 1
        fcb     $00,$80,$80,$00,$00,$00  ; row 2
        fcb     $00,$F1,$55,$00,$00,$00  ; row 3
        fcb     $00,$FF,$15,$50,$00,$00  ; row 4
        fcb     $00,$3F,$10,$00,$00,$00  ; row 5
        fcb     $00,$15,$55,$50,$00,$00  ; row 6
        fcb     $00,$15,$55,$50,$00,$00  ; row 7
        fcb     $00,$01,$55,$55,$00,$00  ; row 8
        fcb     $00,$00,$A8,$00,$00,$00  ; row 9
