* tests/scripted/scene6_cliff_face.s — SHARED cliff-face + ground fills (single source, HS-6).
* Extracted verbatim from scene6_climb_crawl_driver.s (Jay-gated 2026-07-12) so the crawl driver
* and the walk-scroll driver both draw the identical cliff-face striations + ground segments.
* Hand-fills direct to buffer-A logical base $8000 (part of the static substrate).
* include-only; no org.
* ---------------------------------------------------------------

draw_climb_striations:
        * extend the cliff-face pattern UP by 2 black lines: black base rows 113..116, bytes 5..24
        * (blue striations below then paint rows 113 & 115, leaving black lines at 114 & 116).
        ldb     #113
dcbk_cf:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8005
        tfr     d,x
        ldd     #$0000                  ; black base
        ldy     #10                     ; bytes 5..24
dcbk_ff:
        std     ,x++
        leay    -1,y
        bne     dcbk_ff
        puls    b
        incb
        cmpb    #117
        blo     dcbk_cf
        ldb     #113                    ; BLUE odd rows 113..179, bytes 5..24 (cliff face)
dcst_cf:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8005
        tfr     d,x
        ldd     #$AAAA                  ; blue (index 2)
        ldy     #10                     ; bytes 5..24 (cliff-face width)
dcst_cff:
        std     ,x++
        leay    -1,y
        bne     dcst_cff
        lda     #$A8                    ; byte24: px96-98 blue, px99 BLACK — align the black-wall
        sta     -1,x                    ;   left edge to px99 for the back area below the wall
        puls    b
        addb    #2
        cmpb    #180
        blo     dcst_cf
        rts

draw_climb_ground_right:
        ldb     #153                    ; BLUE odd ground rows 153..179, bytes 25..74
dcgr_b:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8019                  ; byte 25
        tfr     d,x
        ldd     #$AAAA                  ; blue (index 2)
        ldy     #25                     ; bytes 25..74
dcgr_bf:
        std     ,x++
        leay    -1,y
        bne     dcgr_bf
        puls    b
        addb    #2
        cmpb    #180
        blo     dcgr_b
        ldb     #154                    ; ORANGE even ground rows 154..180 (was 152; Jay: the TOP floor
                                        ;   line must be BLUE, so drop the topmost orange row — the floor
                                        ;   now starts at row 153 BLUE, row 152 rejoins the black above)
dcgr_o:
        pshs    b
        tfr     b,a
        ldb     #80
        mul
        addd    #$8019                  ; byte 25
        tfr     d,x
        ldd     #$5555                  ; orange (index 1)
        ldy     #25                     ; bytes 25..74
dcgr_of:
        std     ,x++
        leay    -1,y
        bne     dcgr_of
        puls    b
        addb    #2
        cmpb    #182
        blo     dcgr_o
        rts
