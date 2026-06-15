* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 floor, tbl_sprite_*_a)
*         Apple II label: addr_9743
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

floor_9743_coco3:
        fcb     6,3  ; height=6 rows, coco3_width=3 bytes/row (4px/byte)
        ; +1 black byte-column on the RIGHT (Jay 2026-06-15). Drawn BEFORE 964A in
        ; stage_tbl so the post (964A) repaints on top and isn't eaten by this
        ; opaque black where they overlap.
        fcb     $80,$00,$00  ; row 0
        fcb     $00,$00,$00  ; row 1
        fcb     $AA,$80,$00  ; row 2
        fcb     $00,$00,$00  ; row 3
        fcb     $AA,$A8,$00  ; row 4
        fcb     $00,$00,$00  ; row 5
