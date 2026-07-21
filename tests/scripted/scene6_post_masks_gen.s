* tests/scripted/scene6_post_masks_gen.s — GENERATED (B2' post generator).
*   post_masks: the post itself — 2 px white at x,x+1 then black at x+2..x+5.
*   gap_masks : the RAIL NOTCH — black at x+2..x+5 only, so the rail's white line is broken
*               at each post exactly as the baked tableau does (row 104 shows OR $C0/$3F at
*               the post bytes, not $FF). Without this the rail runs straight through the post.
*   Both pre-baked for all 4 sub-byte phases (pitch 85 px is not a multiple of 4).
*   Layout per phase: 3 AND bytes then 3 OR bytes, applied at byte (x>>2)+0..2.
post_masks:
        fcb     $00,$0F,$FF,$F0,$00,$00   ; phase 0
        fcb     $C0,$03,$FF,$3C,$00,$00   ; phase 1
        fcb     $F0,$00,$FF,$0F,$00,$00   ; phase 2
        fcb     $FC,$00,$3F,$03,$C0,$00   ; phase 3
gap_masks:
        fcb     $F0,$0F,$FF,$00,$00,$00   ; phase 0
        fcb     $FC,$03,$FF,$00,$00,$00   ; phase 1
        fcb     $FF,$00,$FF,$00,$00,$00   ; phase 2
        fcb     $FF,$C0,$3F,$00,$00,$00   ; phase 3
