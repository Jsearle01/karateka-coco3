* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (sky floodfill)
*         Apple II label: addr_A976
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A976:
        fcb     8,14  ; height=8 rows, coco3_width=14 bytes/row (4px/byte)
        fcb     $AA,$AA,$AA,$AF,$FF,$EF,$FF,$FF,$FF,$FF,$FA,$AA,$AA,$AA  ; row 0
        fcb     $AA,$AA,$AA,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$AA,$AA,$AA  ; row 1
        fcb     $AA,$AA,$AA,$FF,$FF,$EF,$FF,$FF,$EF,$FF,$FF,$AA,$AA,$AA  ; row 2
        fcb     $AA,$AA,$AF,$FE,$FE,$AF,$FF,$FF,$FF,$FF,$FF,$EA,$AA,$AA  ; row 3
        fcb     $AA,$AA,$FF,$FF,$FE,$AF,$FF,$FF,$FF,$FF,$FF,$FA,$AA,$AA  ; row 4
        fcb     $AA,$AB,$FF,$FF,$EA,$AF,$AF,$FF,$EF,$FF,$FF,$FF,$AA,$AA  ; row 5
        fcb     $AA,$AF,$FF,$EF,$EA,$FE,$AF,$FF,$FA,$FF,$FF,$FF,$EA,$AA  ; row 6
        fcb     $AA,$FF,$FE,$BE,$AA,$AA,$AB,$FF,$FA,$BF,$FF,$FF,$FE,$AA  ; row 7
