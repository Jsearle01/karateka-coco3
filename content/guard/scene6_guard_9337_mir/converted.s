* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_9337
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_guard_9337_mir:
        fcb     4,7  ; height=4 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $FF,$FC,$20,$FF,$FF,$C2,$0F  ; row 0
        fcb     $FF,$FA,$A0,$00,$00,$02,$AA  ; row 1
        fcb     $FF,$C2,$A0,$00,$00,$02,$AA  ; row 2
        fcb     $FF,$F0,$00,$00,$00,$00,$02  ; row 3
