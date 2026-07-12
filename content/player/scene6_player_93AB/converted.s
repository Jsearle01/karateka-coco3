* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_93AB
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_player_93AB:
        fcb     25,9  ; height=25 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $FF,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FC  ; row 0
        fcb     $FF,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FC  ; row 1
        fcb     $FF,$DF,$FF,$FF,$C0,$FF,$FF,$FF,$FC  ; row 2
        fcb     $FF,$C0,$FF,$FF,$D5,$FF,$FF,$FF,$FC  ; row 3
        fcb     $FF,$D4,$0F,$FF,$D4,$03,$FF,$FF,$FC  ; row 4
        fcb     $FF,$C0,$40,$FC,$05,$43,$FF,$FF,$FC  ; row 5
        fcb     $FF,$FD,$54,$05,$55,$43,$FF,$FF,$FC  ; row 6
        fcb     $FF,$FC,$05,$40,$55,$43,$C0,$00,$04  ; row 7
        fcb     $FF,$FF,$D5,$55,$FD,$40,$05,$54,$3C  ; row 8
        fcb     $FF,$FF,$C0,$55,$FD,$55,$55,$40,$FC  ; row 9
        fcb     $40,$00,$05,$55,$FD,$5F,$D4,$0F,$FC  ; row 10
        fcb     $F0,$55,$55,$5F,$FF,$FD,$40,$FF,$FC  ; row 11
        fcb     $FF,$00,$5F,$FF,$FF,$D4,$03,$FF,$FC  ; row 12
        fcb     $FF,$FC,$05,$5F,$FF,$D5,$43,$FF,$FC  ; row 13
        fcb     $FF,$FF,$C0,$55,$FF,$FD,$40,$FF,$FC  ; row 14
        fcb     $FF,$FF,$D5,$5F,$FF,$FF,$D4,$3F,$FC  ; row 15
        fcb     $FF,$FC,$05,$FD,$FD,$55,$54,$0F,$FC  ; row 16
        fcb     $FF,$F0,$55,$55,$FD,$55,$55,$43,$FC  ; row 17
        fcb     $FF,$05,$40,$05,$55,$40,$00,$00,$FC  ; row 18
        fcb     $FC,$00,$0F,$F0,$54,$0F,$FF,$FF,$FC  ; row 19
        fcb     $FF,$FF,$FF,$F0,$54,$3F,$FF,$FF,$FC  ; row 20
        fcb     $FF,$FF,$FF,$FF,$04,$3F,$FF,$FF,$FC  ; row 21
        fcb     $FF,$FF,$FF,$FF,$04,$3F,$FF,$FF,$FC  ; row 22
        fcb     $FF,$FF,$FF,$FF,$F0,$3F,$FF,$FF,$FC  ; row 23
        fcb     $FF,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FC  ; row 24
