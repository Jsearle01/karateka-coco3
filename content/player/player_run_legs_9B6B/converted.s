* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9B6B
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

player_run_legs_9B6B:
        fcb     20,10  ; height=20 rows, coco3_width=10 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$FF,$FF,$FC,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00  ; row 1
        fcb     $00,$00,$00,$03,$FF,$FF,$FF,$00,$00,$00  ; row 2
        fcb     $00,$00,$00,$03,$FF,$FF,$FF,$00,$00,$00  ; row 3
        fcb     $00,$00,$00,$0F,$FF,$FF,$FF,$C0,$00,$00  ; row 4
        fcb     $00,$00,$00,$0F,$FF,$FF,$FF,$C0,$00,$00  ; row 5
        fcb     $00,$00,$00,$3F,$FF,$EF,$FF,$F0,$00,$00  ; row 6
        fcb     $00,$00,$00,$3F,$FF,$03,$FF,$FC,$00,$00  ; row 7
        fcb     $00,$00,$03,$FF,$FC,$00,$FF,$FC,$00,$00  ; row 8
        fcb     $00,$03,$FF,$FF,$F0,$00,$3F,$FF,$00,$00  ; row 9
        fcb     $01,$57,$FF,$FF,$C0,$00,$3F,$FF,$00,$00  ; row 10
        fcb     $01,$57,$FF,$FF,$00,$00,$0F,$FF,$C0,$00  ; row 11
        fcb     $01,$00,$00,$00,$00,$00,$03,$FF,$C0,$00  ; row 12
        fcb     $01,$00,$00,$00,$00,$00,$00,$FF,$F0,$00  ; row 13
        fcb     $01,$00,$00,$00,$00,$00,$00,$FF,$F0,$00  ; row 14
        fcb     $00,$00,$00,$00,$00,$00,$00,$3F,$FC,$00  ; row 15
        fcb     $00,$00,$00,$00,$00,$00,$00,$0F,$F0,$00  ; row 16
        fcb     $00,$00,$00,$00,$00,$00,$00,$0F,$55,$50  ; row 17
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$15,$00  ; row 18
        fcb     $00,$00,$00,$00,$00,$00,$00,$00,$10,$00  ; row 19
