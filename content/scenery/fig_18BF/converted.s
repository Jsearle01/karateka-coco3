* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 CELL set-dressing)
*         Apple II label: fig_18BF
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=28
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

fig_18BF_coco3:
        fcb     5,6  ; height=5 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$00,$AF,$C0,$00  ; row 0
        fcb     $00,$00,$00,$AF,$C0,$00  ; row 1
        fcb     $00,$00,$00,$AF,$C0,$00  ; row 2
        fcb     $00,$00,$00,$AF,$C0,$00  ; row 3
        fcb     $00,$00,$00,$AF,$C0,$00  ; row 4
