* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9E4A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_torso_9E4A:
        fcb     20,3  ; height=20 rows, coco3_width=3 bytes/row (4px/byte)
        fcb     $00,$3D,$40  ; row 0
        fcb     $00,$FF,$C0  ; row 1
        fcb     $03,$FF,$C0  ; row 2
        fcb     $0F,$FF,$F0  ; row 3
        fcb     $0F,$FF,$F0  ; row 4
        fcb     $0F,$FF,$F0  ; row 5
        fcb     $BF,$FF,$F0  ; row 6
        fcb     $BF,$FF,$F0  ; row 7
        fcb     $BF,$FF,$C0  ; row 8
        fcb     $BF,$FF,$C0  ; row 9
        fcb     $BF,$FF,$C0  ; row 10
        fcb     $BF,$F0,$00  ; row 11
        fcb     $BF,$F0,$00  ; row 12
        fcb     $FF,$FF,$C0  ; row 13
        fcb     $FF,$FF,$C0  ; row 14
        fcb     $FF,$FF,$00  ; row 15
        fcb     $FF,$FF,$00  ; row 16
        fcb     $BD,$5F,$00  ; row 17
        fcb     $BD,$54,$00  ; row 18
        fcb     $BD,$54,$00  ; row 19
