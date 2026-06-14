* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_17D3
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_17D3_coco3:
        fcb     14,11  ; height=14 rows, coco3_width=11 bytes/row (4px/byte)
        fcb     $00,$3F,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; row 0
        fcb     $00,$0F,$C0,$00,$00,$00,$00,$00,$00,$00,$00  ; row 1
        fcb     $00,$0F,$C0,$00,$00,$00,$00,$00,$00,$00,$00  ; row 2
        fcb     $0F,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00  ; row 3
        fcb     $7F,$FF,$FF,$FC,$00,$00,$00,$00,$00,$00,$00  ; row 4
        fcb     $7F,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00  ; row 5
        fcb     $7F,$FF,$FF,$7F,$FF,$F0,$00,$00,$00,$00,$00  ; row 6
        fcb     $7F,$F0,$FF,$17,$FF,$FF,$00,$00,$00,$00,$00  ; row 7
        fcb     $A8,$17,$FF,$17,$FF,$FF,$CA,$AA,$AA,$AA,$80  ; row 8
        fcb     $01,$50,$0F,$17,$FF,$FF,$F0,$F0,$00,$00,$00  ; row 9
        fcb     $01,$00,$01,$57,$FF,$FF,$FF,$FC,$AA,$AA,$80  ; row 10
        fcb     $15,$00,$01,$57,$FF,$FF,$FF,$FF,$00,$00,$00  ; row 11
        fcb     $00,$01,$55,$00,$FF,$FF,$FF,$FF,$F1,$00,$00  ; row 12
        fcb     $00,$01,$00,$00,$3F,$F0,$00,$FF,$FC,$00,$00  ; row 13
