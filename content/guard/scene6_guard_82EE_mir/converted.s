* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_82EE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_82EE_mir:
        fcb     12,12  ; height=12 rows, coco3_width=12 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$00,$00,$00,$03,$FF,$C0,$00,$00  ; row 0
        fcb     $00,$00,$00,$00,$0A,$80,$0F,$FF,$FF,$EA,$80,$00  ; row 1
        fcb     $00,$00,$00,$00,$0A,$AF,$FF,$FF,$FF,$EF,$F0,$00  ; row 2
        fcb     $00,$00,$00,$00,$00,$0F,$FF,$FF,$EF,$FF,$FC,$00  ; row 3
        fcb     $00,$00,$00,$00,$00,$0F,$FF,$EF,$EA,$FF,$FC,$00  ; row 4
        fcb     $00,$00,$00,$00,$00,$00,$00,$3F,$EA,$FF,$FF,$40  ; row 5
        fcb     $AA,$AF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FF,$40  ; row 6
        fcb     $AA,$AF,$FF,$FF,$FF,$FF,$FC,$3F,$FF,$FF,$FF,$40  ; row 7
        fcb     $80,$0F,$FF,$FF,$FF,$FF,$0F,$7F,$FF,$FF,$FC,$00  ; row 8
        fcb     $00,$0F,$FF,$FF,$FF,$FF,$00,$0F,$FF,$FF,$FC,$00  ; row 9
        fcb     $00,$00,$00,$00,$FF,$FF,$FF,$00,$FF,$FF,$F0,$00  ; row 10
        fcb     $00,$00,$00,$00,$00,$3F,$FF,$E8,$00,$0F,$C0,$00  ; row 11
