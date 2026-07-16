* scene6_wall_post — HAND-AUTHORED opaque block (cols 0-5 of Jay's 9x7 post).
* w=3(white) b=0(black); NO 't' in this block -> fully OPAQUE (no mask plane needed).
* col 6 (rail) is NOT here — it is drawn as direct row-fills. Placement: byte 46/67 sub 2,
* row 100, via HAL_gfx_blit_sprite_opaque (sub-byte shift 2).
* 6px wide x 9 tall; 2 byte/row.

scene6_wall_post:
        fcb     9,2                  ; height, width(bytes)
        fcb     $F0,$00          ; w w b b b b
        fcb     $F0,$00          ; w w b b b b
        fcb     $F0,$00          ; w w b b b b
        fcb     $00,$00          ; b b b b b b
        fcb     $00,$00          ; b b b b b b
        fcb     $00,$00          ; b b b b b b
        fcb     $F0,$00          ; w w b b b b
        fcb     $F0,$00          ; w w b b b b
        fcb     $F0,$00          ; w w b b b b

