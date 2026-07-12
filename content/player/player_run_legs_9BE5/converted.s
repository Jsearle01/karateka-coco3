* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9BE5
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9BE5:
        fcb     13,6  ; height=13 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $15,$7F,$FF,$FF,$FF,$FF  ; row 0
        fcb     $15,$7F,$FF,$FF,$EF,$FF  ; row 1
        fcb     $10,$3F,$FF,$FF,$EF,$FF  ; row 2
        fcb     $10,$3F,$FF,$FF,$0F,$FF  ; row 3
        fcb     $10,$00,$00,$00,$0F,$FF  ; row 4
        fcb     $00,$00,$00,$00,$0F,$FF  ; row 5
        fcb     $00,$00,$00,$00,$0F,$FF  ; row 6
        fcb     $00,$00,$00,$00,$3F,$FF  ; row 7
        fcb     $00,$00,$00,$00,$3F,$FF  ; row 8
        fcb     $00,$00,$00,$00,$3F,$FF  ; row 9
        fcb     $00,$00,$00,$00,$10,$00  ; row 10
        fcb     $00,$00,$00,$00,$15,$00  ; row 11
        fcb     $00,$00,$00,$00,$15,$50  ; row 12
