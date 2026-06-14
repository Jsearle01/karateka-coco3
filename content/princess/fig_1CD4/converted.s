* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin (by address)
*         Apple II label: addr_1CD4
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

fig_1CD4_coco3:
        fcb     21,4  ; height=21 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$F0  ; row 0
        fcb     $FF,$FF,$FF,$F0  ; row 1
        fcb     $FF,$FF,$FF,$F0  ; row 2
        fcb     $FF,$FF,$FF,$F0  ; row 3
        fcb     $FF,$FC,$AA,$F0  ; row 4
        fcb     $FF,$FC,$AF,$F0  ; row 5
        fcb     $FF,$CA,$AF,$F0  ; row 6
        fcb     $FF,$CA,$FF,$F0  ; row 7
        fcb     $FC,$AA,$FF,$F0  ; row 8
        fcb     $FC,$AF,$FF,$F0  ; row 9
        fcb     $FC,$AF,$FF,$F0  ; row 10
        fcb     $FC,$AF,$FF,$F0  ; row 11
        fcb     $FC,$AF,$FF,$F0  ; row 12
        fcb     $FC,$AF,$FF,$F0  ; row 13
        fcb     $FC,$AF,$FF,$F0  ; row 14
        fcb     $FC,$AF,$FF,$F0  ; row 15
        fcb     $FC,$AA,$FF,$F0  ; row 16
        fcb     $FC,$AA,$FF,$F0  ; row 17
        fcb     $FF,$CA,$AF,$F0  ; row 18
        fcb     $FF,$FC,$AF,$F0  ; row 19
        fcb     $FF,$FC,$AF,$F0  ; row 20
