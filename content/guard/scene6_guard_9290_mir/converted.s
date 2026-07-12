* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9290
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9290_mir:
        fcb     11,13  ; height=11 rows, coco3_width=13 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$C0,$FF,$C0,$00,$3F,$FF,$C0  ; row 0
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$C3,$FF,$C0,$00,$3F,$FF,$C0  ; row 1
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$C0,$00,$3F,$FF,$C0  ; row 2
        fcb     $FF,$FF,$FF,$FF,$FF,$FF,$0F,$FF,$C0,$00,$00,$0F,$C0  ; row 3
        fcb     $FD,$FF,$FB,$FF,$FF,$F0,$0F,$FF,$C0,$00,$00,$03,$C0  ; row 4
        fcb     $FC,$2A,$AB,$FF,$FF,$C2,$0F,$FF,$C0,$00,$00,$03,$C0  ; row 5
        fcb     $FC,$2A,$AB,$FF,$FF,$FC,$03,$FF,$C0,$00,$00,$00,$40  ; row 6
        fcb     $FC,$00,$00,$03,$FF,$C0,$42,$BF,$C0,$00,$00,$00,$40  ; row 7
        fcb     $FC,$2A,$AA,$BF,$FF,$FF,$FA,$BF,$C0,$00,$00,$00,$40  ; row 8
        fcb     $FC,$2A,$AB,$FF,$FF,$FF,$C2,$A0,$00,$00,$00,$00,$40  ; row 9
        fcb     $FC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40  ; row 10
