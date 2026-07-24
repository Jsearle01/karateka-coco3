* opacity descriptor (stencil) for scene6_bg_archfill1 — hand-authored (Jay-specified gap fill).
*   matches HAL_gfx_blit_stencil_punch: 2D mask (height,width, h*w bytes; 11=black,00=keep).
*   cel-local (byte-aligned); a sub-byte-placed cel needs build-side mask shifting.
*   $FF = px0-3 opaque; $C0 = px4 opaque, px5-7 keep -> exactly 5 opaque px per row.
scene6_bg_archfill1_opacity_stencil:
        fcb     6,2
        fcb     $FF,$C0  ; row 0
        fcb     $FF,$C0  ; row 1
        fcb     $FF,$C0  ; row 2
        fcb     $FF,$C0  ; row 3
        fcb     $FF,$C0  ; row 4
        fcb     $FF,$C0  ; row 5
