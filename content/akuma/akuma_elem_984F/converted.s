* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 (tbl_combatant idx11)
*         Apple II label: addr_984F
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]

akuma_elem_984F_coco3:
        fcb     3,4  ; height=3 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $FF,$CA,$AA,$80  ; row 0
        fcb     $FF,$CA,$AF,$F0  ; row 1
        fcb     $FF,$CA,$AF,$F0  ; row 2
