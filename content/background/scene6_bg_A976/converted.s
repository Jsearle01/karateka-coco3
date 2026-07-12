* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A976
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=112  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A976:
        fcb     8,14  ; height=8 rows, coco3_width=14 bytes/row (4px/byte)
        fcb     $AA,$AA,$AA,$AF,$FF,$EF,$FF,$FF,$FF,$FF,$F0,$AA,$AA,$A8  ; row 0
        fcb     $AA,$AA,$AA,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$AA,$AA,$A8  ; row 1
        fcb     $AA,$AA,$AA,$FF,$FF,$EF,$FF,$FF,$EF,$FF,$FF,$0A,$AA,$A8  ; row 2
        fcb     $AA,$AA,$AF,$FE,$FC,$0F,$FF,$FF,$FF,$FF,$FF,$EA,$AA,$A8  ; row 3
        fcb     $AA,$AA,$FF,$FF,$FE,$AF,$FF,$FF,$FF,$FF,$FF,$F0,$AA,$A8  ; row 4
        fcb     $AA,$83,$FF,$FF,$C0,$0F,$0F,$FF,$EF,$FF,$FF,$FF,$0A,$A8  ; row 5
        fcb     $A8,$0F,$FF,$EF,$EA,$FE,$AF,$FF,$F0,$FF,$FF,$FF,$C0,$A8  ; row 6
        fcb     $AA,$FF,$FC,$3C,$00,$00,$03,$FF,$F0,$3F,$FF,$FF,$FE,$A8  ; row 7
