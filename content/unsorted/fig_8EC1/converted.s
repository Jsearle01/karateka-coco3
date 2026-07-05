* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr
*         Apple II label: addr_8EC1
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_8EC1_coco3:
        fcb     8,2  ; height=8 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $FF,$FC  ; row 0
        fcb     $00,$08  ; row 1
        fcb     $00,$08  ; row 2
        fcb     $00,$08  ; row 3
        fcb     $00,$08  ; row 4
        fcb     $00,$08  ; row 5
        fcb     $00,$08  ; row 6
        fcb     $00,$3C  ; row 7
