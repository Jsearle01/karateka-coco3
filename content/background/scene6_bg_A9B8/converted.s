* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (sky floodfill)
*         Apple II label: addr_A9B8
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_bg_A9B8:
        fcb     4,18  ; height=4 rows, coco3_width=18 bytes/row (4px/byte)
        fcb     $AA,$AA,$AF,$FF,$AA,$AA,$AA,$AA,$AB,$FF,$FA,$BF,$FF,$FF,$FE,$AA,$AA,$AA  ; row 0
        fcb     $AA,$AA,$FC,$3E,$AA,$AA,$AA,$AA,$AB,$FF,$FA,$AB,$FB,$FF,$FF,$AA,$AA,$AA  ; row 1
        fcb     $AA,$AF,$FB,$FA,$AA,$AA,$AA,$AA,$AB,$FF,$BF,$AA,$AB,$FF,$FF,$FA,$AA,$AA  ; row 2
        fcb     $AA,$BF,$AF,$AA,$AA,$AA,$AA,$AA,$AA,$BF,$AF,$AA,$AA,$AF,$FF,$FF,$AA,$AA  ; row 3
