* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1829
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_1829_coco3:
        fcb     10,11  ; height=10 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00,$0F,$FC,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$03,$FC,$00,$FF,$FF,$00,$00,$00,$00,$00  ; row 1
        fcb     $A8,$3F,$FF,$7F,$FF,$FF,$EF,$CA,$AA,$AA,$80  ; row 2
        fcb     $00,$FF,$FF,$FF,$FF,$FF,$F7,$F0,$00,$00,$00  ; row 3
        fcb     $83,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$AA,$AA,$80  ; row 4
        fcb     $17,$FF,$FF,$17,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 5
        fcb     $15,$7F,$FF,$15,$7F,$FF,$FF,$FF,$F1,$00,$00  ; row 6
        fcb     $01,$55,$00,$01,$50,$00,$FF,$FF,$FC,$00,$00  ; row 7
        fcb     $A8,$15,$01,$55,$50,$AA,$AA,$AA,$AA,$AA,$80  ; row 8
        fcb     $00,$00,$01,$50,$00,$00,$00,$00,$00,$00,$00  ; row 9
