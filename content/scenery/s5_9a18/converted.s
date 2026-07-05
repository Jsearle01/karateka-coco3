* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9a18
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

s5_9a18_coco3:
        fcb     8,4  ; height=8 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $FF,$0F,$FF,$00  ; row 0
        fcb     $FF,$0F,$FF,$00  ; row 1
        fcb     $FF,$FF,$FF,$F0  ; row 2
        fcb     $FF,$FF,$FF,$F0  ; row 3
        fcb     $FF,$F1,$57,$F0  ; row 4
        fcb     $FF,$F1,$57,$F0  ; row 5
        fcb     $FF,$F1,$57,$F0  ; row 6
        fcb     $FF,$F1,$57,$F0  ; row 7
