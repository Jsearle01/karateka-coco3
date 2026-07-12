* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_809A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_809A:
        fcb     21,2  ; height=21 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $BC,$3C  ; row 0
        fcb     $FC,$3C  ; row 1
        fcb     $FF,$FC  ; row 2
        fcb     $FF,$FC  ; row 3
        fcb     $FF,$FC  ; row 4
        fcb     $FF,$FC  ; row 5
        fcb     $FF,$F0  ; row 6
        fcb     $FF,$F0  ; row 7
        fcb     $FF,$F0  ; row 8
        fcb     $FF,$F0  ; row 9
        fcb     $BF,$F0  ; row 10
        fcb     $BF,$FC  ; row 11
        fcb     $BF,$FC  ; row 12
        fcb     $BF,$FC  ; row 13
        fcb     $0F,$FC  ; row 14
        fcb     $0F,$FC  ; row 15
        fcb     $0F,$FC  ; row 16
        fcb     $0F,$C0  ; row 17
        fcb     $05,$40  ; row 18
        fcb     $05,$40  ; row 19
        fcb     $55,$40  ; row 20
