* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8B0F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8B0F_mir:
        fcb     13,6  ; height=13 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$00,$AA,$F0,$00  ; row 0
        fcb     $00,$00,$03,$EF,$FC,$00  ; row 1
        fcb     $00,$00,$0F,$FF,$FF,$40  ; row 2
        fcb     $00,$00,$3F,$FF,$FF,$40  ; row 3
        fcb     $00,$00,$3F,$FF,$FF,$40  ; row 4
        fcb     $00,$00,$FF,$FF,$FF,$40  ; row 5
        fcb     $00,$00,$FF,$FF,$FF,$40  ; row 6
        fcb     $00,$03,$FF,$FF,$FF,$40  ; row 7
        fcb     $00,$0F,$FF,$FF,$FC,$00  ; row 8
        fcb     $0A,$AF,$EA,$AF,$FC,$00  ; row 9
        fcb     $0A,$AF,$EA,$AF,$FC,$00  ; row 10
        fcb     $00,$0F,$EA,$FF,$FC,$00  ; row 11
        fcb     $00,$00,$3F,$FC,$00,$00  ; row 12
