* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_169A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_169A_coco3:
        fcb     16,6  ; height=16 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $00,$00,$0F,$FC,$00,$00  ; row 0
        fcb     $00,$00,$FF,$FF,$00,$00  ; row 1
        fcb     $00,$00,$FF,$FF,$C0,$00  ; row 2
        fcb     $00,$00,$03,$FF,$C0,$00  ; row 3
        fcb     $00,$00,$15,$7F,$C0,$00  ; row 4
        fcb     $00,$00,$15,$7F,$C0,$00  ; row 5
        fcb     $00,$00,$15,$7F,$F0,$00  ; row 6
        fcb     $00,$00,$01,$7F,$F0,$00  ; row 7
        fcb     $00,$00,$01,$7F,$F0,$00  ; row 8
        fcb     $00,$00,$0F,$17,$F0,$00  ; row 9
        fcb     $00,$00,$FF,$17,$F0,$00  ; row 10
        fcb     $00,$03,$FF,$17,$F0,$00  ; row 11
        fcb     $00,$03,$FF,$17,$F0,$00  ; row 12
        fcb     $00,$00,$FF,$17,$C0,$00  ; row 13
        fcb     $00,$00,$3F,$17,$C0,$00  ; row 14
        fcb     $00,$00,$3F,$10,$80,$00  ; row 15
