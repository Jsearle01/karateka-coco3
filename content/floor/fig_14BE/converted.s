* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 CELL set-dressing, trailing-trim)
*         Apple II label: fig_14BE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=70
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md �6.7]

fig_14BE_coco3:
        fcb     5,36  ; height=5 rows, coco3_width=36 bytes/row (4px/byte) [cell bench-reach edit]
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA  ; row 0
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 1
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA  ; row 2
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 3
        fcb     $0A,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA  ; row 4
