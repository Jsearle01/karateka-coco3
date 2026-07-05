* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: sprite_data.s
*         Apple II label: sprite_98af
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=120
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_frame_3_coco3:
        fcb     8,3  ; height=8 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$3F,$C0  ; row 0
        fcb     $00,$FF,$FC  ; row 1
        fcb     $03,$FF,$FC  ; row 2
        fcb     $03,$FF,$FC  ; row 3
        fcb     $03,$FF,$FC  ; row 4
        fcb     $03,$FF,$FC  ; row 5
        fcb     $00,$FF,$C4  ; row 6
        fcb     $00,$55,$54  ; row 7
