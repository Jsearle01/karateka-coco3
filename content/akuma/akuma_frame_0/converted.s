* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_9879
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_frame_0_coco3:
        fcb     8,2  ; height=8 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $00,$FF  ; row 0
        fcb     $3F,$F0  ; row 1
        fcb     $55,$FC  ; row 2
        fcb     $0F,$FF  ; row 3
        fcb     $55,$FF  ; row 4
        fcb     $55,$FF  ; row 5
        fcb     $55,$FC  ; row 6
        fcb     $55,$54  ; row 7
