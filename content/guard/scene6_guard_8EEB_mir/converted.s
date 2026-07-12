* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_8EEB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_8EEB_mir:
        fcb     11,4  ; height=11 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $00,$00,$00,$00  ; row 0
        fcb     $00,$00,$00,$00  ; row 1
        fcb     $FF,$C0,$3F,$F0  ; row 2
        fcb     $FE,$A8,$08,$08  ; row 3
        fcb     $FE,$A8,$0A,$80  ; row 4
        fcb     $FE,$A8,$0A,$80  ; row 5
        fcb     $FE,$AA,$AA,$80  ; row 6
        fcb     $FF,$EA,$AA,$80  ; row 7
        fcb     $FF,$EA,$FC,$00  ; row 8
        fcb     $FF,$FE,$FF,$08  ; row 9
        fcb     $FF,$C0,$3F,$F0  ; row 10
