* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_942A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_942A:
        fcb     20,7  ; height=20 rows, coco3_width=7 bytes/row (4px/byte)
        fcb     $00,$00,$00,$04,$00,$00,$00  ; row 0
        fcb     $04,$00,$00,$04,$00,$00,$00  ; row 1
        fcb     $00,$40,$00,$05,$40,$00,$00  ; row 2
        fcb     $00,$54,$00,$55,$40,$00,$00  ; row 3
        fcb     $00,$05,$40,$55,$40,$00,$00  ; row 4
        fcb     $00,$05,$55,$FD,$40,$05,$54  ; row 5
        fcb     $00,$00,$55,$FD,$55,$55,$40  ; row 6
        fcb     $00,$05,$55,$FD,$5F,$D4,$00  ; row 7
        fcb     $55,$55,$5F,$FF,$FD,$40,$00  ; row 8
        fcb     $00,$5F,$FF,$FF,$D4,$00,$00  ; row 9
        fcb     $00,$05,$5F,$FF,$D5,$40,$00  ; row 10
        fcb     $00,$00,$55,$FF,$FD,$40,$00  ; row 11
        fcb     $00,$05,$5F,$FF,$FF,$D4,$00  ; row 12
        fcb     $00,$05,$FD,$FD,$55,$54,$00  ; row 13
        fcb     $00,$55,$55,$FD,$55,$55,$40  ; row 14
        fcb     $05,$40,$05,$55,$40,$00,$00  ; row 15
        fcb     $00,$00,$00,$54,$00,$00,$00  ; row 16
        fcb     $00,$00,$00,$54,$00,$00,$00  ; row 17
        fcb     $00,$00,$00,$04,$00,$00,$00  ; row 18
        fcb     $00,$00,$00,$04,$00,$00,$00  ; row 19
