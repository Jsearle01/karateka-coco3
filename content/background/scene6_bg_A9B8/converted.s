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
        fcb     $AA,$AA,$0F,$FF,$AA,$AA,$AA,$AA,$AB,$FF,$FA,$BF,$FF,$FF,$FC,$2A,$AA,$AA  ; row 0
        fcb     $AA,$A0,$FE,$BC,$00,$00,$00,$00,$03,$FF,$F0,$03,$FB,$FF,$FF,$02,$AA,$AA  ; row 1
        fcb     $AA,$0F,$FB,$FA,$AA,$AA,$AA,$AA,$AB,$FF,$BF,$AA,$AB,$FF,$FF,$F0,$2A,$AA  ; row 2
        fcb     $A0,$3F,$0F,$00,$00,$00,$00,$00,$00,$3F,$0F,$00,$00,$0F,$FF,$FF,$02,$AA  ; row 3
