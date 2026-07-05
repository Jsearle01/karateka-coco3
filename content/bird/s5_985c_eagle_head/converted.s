* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_985c
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

s5_985c_eagle_head_coco3:
        fcb     4,3  ; height=4 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $0F,$F0,$00  ; row 0
        fcb     $3F,$FF,$C0  ; row 1
        fcb     $3F,$F0,$80  ; row 2
        fcb     $3F,$FC,$00  ; row 3
