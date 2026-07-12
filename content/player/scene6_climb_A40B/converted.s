* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A40B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A40B:
        fcb     8,4  ; height=8 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$0F,$FF  ; row 0
        fcb     $20,$00,$3F,$FC  ; row 1
        fcb     $00,$00,$3F,$D4  ; row 2
        fcb     $20,$00,$3D,$40  ; row 3
        fcb     $00,$00,$3D,$54  ; row 4
        fcb     $20,$0F,$FD,$54  ; row 5
        fcb     $03,$FF,$FF,$D4  ; row 6
        fcb     $BF,$FF,$FF,$C0  ; row 7
