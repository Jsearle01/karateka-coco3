* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (sky floodfill)
*         Apple II label: addr_A948
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A948:
        fcb     11,7  ; height=11 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $AA,$AA,$A8,$00,$0A,$AA,$AA  ; row 0
        fcb     $AA,$AA,$AF,$F7,$EA,$AA,$AA  ; row 1
        fcb     $AA,$AA,$AF,$FF,$F0,$AA,$AA  ; row 2
        fcb     $AA,$AA,$FF,$FE,$FE,$AA,$AA  ; row 3
        fcb     $AA,$AA,$FF,$FF,$FF,$0A,$AA  ; row 4
        fcb     $AA,$AF,$FF,$FF,$FF,$EA,$AA  ; row 5
        fcb     $A8,$3F,$FF,$FF,$FF,$F0,$AA  ; row 6
        fcb     $AA,$FF,$FF,$FF,$FF,$FE,$AA  ; row 7
        fcb     $AF,$FF,$FF,$FF,$FF,$FF,$0A  ; row 8
        fcb     $AF,$FF,$FF,$FF,$FF,$FF,$EA  ; row 9
        fcb     $FF,$FF,$FF,$FF,$EF,$FF,$F2  ; row 10
