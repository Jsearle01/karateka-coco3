* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A763
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=202  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A763:
        fcb     18,11  ; height=18 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $AA,$AF,$FF,$FF,$00,$00,$00,$AA,$FF,$FF,$E0  ; row 0
        fcb     $AA,$AF,$FF,$F0,$00,$00,$0A,$AF,$FF,$FF,$E0  ; row 1
        fcb     $AA,$FF,$FF,$00,$00,$00,$AA,$FF,$FF,$FF,$00  ; row 2
        fcb     $AF,$FF,$FC,$00,$00,$0A,$AF,$FF,$FF,$F0,$00  ; row 3
        fcb     $AF,$FF,$C0,$00,$00,$AA,$FF,$FF,$FF,$00,$00  ; row 4
        fcb     $FF,$FF,$0F,$55,$50,$AF,$FF,$FF,$F0,$00,$00  ; row 5
        fcb     $FF,$F0,$FF,$00,$00,$FF,$FF,$FF,$00,$00,$00  ; row 6
        fcb     $FF,$C0,$FF,$55,$0F,$FF,$FF,$F0,$00,$00,$A0  ; row 7
        fcb     $FC,$00,$FF,$00,$FF,$FF,$FF,$00,$00,$0A,$A0  ; row 8
        fcb     $80,$00,$FF,$0F,$FF,$FF,$C0,$00,$00,$AA,$A0  ; row 9
        fcb     $00,$00,$FF,$7F,$FF,$FC,$00,$00,$0A,$AA,$A0  ; row 10
        fcb     $AA,$AA,$FF,$7F,$FF,$C0,$00,$00,$AA,$AA,$A0  ; row 11
        fcb     $AA,$AA,$FF,$7F,$FC,$00,$00,$AA,$AA,$AA,$A0  ; row 12
        fcb     $AA,$AF,$FF,$7F,$C0,$00,$0A,$AA,$AA,$AA,$A0  ; row 13
        fcb     $AA,$FF,$FF,$7C,$00,$00,$AA,$AA,$AA,$AA,$A0  ; row 14
        fcb     $AA,$FF,$FF,$00,$00,$0A,$AA,$AA,$AA,$AA,$A0  ; row 15
        fcb     $AA,$FF,$FF,$55,$50,$AA,$AA,$AA,$AA,$AA,$A0  ; row 16
        fcb     $AA,$FF,$FF,$00,$00,$AA,$AA,$AA,$AA,$AA,$A0  ; row 17
