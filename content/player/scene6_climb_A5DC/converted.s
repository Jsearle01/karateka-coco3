* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05_imprison.bin
*         Apple II label: addr_A5DC
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0  screen-col parity=EVEN
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

scene6_climb_A5DC:
        fcb     36,6  ; height=36 rows, coco3_width=6 bytes/row (4px/byte)
        fcb     $20,$00,$FF,$FC,$00,$00  ; row 0
        fcb     $00,$03,$FF,$FC,$00,$00  ; row 1
        fcb     $20,$0F,$FF,$FC,$00,$00  ; row 2
        fcb     $00,$3F,$FF,$FC,$00,$00  ; row 3
        fcb     $20,$3F,$FF,$F0,$00,$00  ; row 4
        fcb     $00,$FF,$FF,$F0,$00,$00  ; row 5
        fcb     $20,$FF,$FF,$F0,$00,$00  ; row 6
        fcb     $00,$FF,$FF,$FC,$00,$00  ; row 7
        fcb     $20,$03,$FF,$D4,$00,$00  ; row 8
        fcb     $00,$00,$05,$54,$00,$00  ; row 9
        fcb     $2B,$F0,$00,$54,$00,$00  ; row 10
        fcb     $03,$FF,$C0,$00,$00,$00  ; row 11
        fcb     $2B,$FF,$F0,$00,$00,$00  ; row 12
        fcb     $03,$FF,$F0,$00,$00,$00  ; row 13
        fcb     $2B,$FF,$FC,$00,$00,$00  ; row 14
        fcb     $00,$FF,$FC,$00,$00,$00  ; row 15
        fcb     $20,$FF,$FC,$00,$00,$00  ; row 16
        fcb     $00,$3F,$FC,$00,$00,$00  ; row 17
        fcb     $20,$3F,$FF,$00,$00,$00  ; row 18
        fcb     $00,$0F,$FF,$00,$00,$00  ; row 19
        fcb     $20,$0F,$FF,$00,$00,$00  ; row 20
        fcb     $00,$03,$FF,$C0,$00,$00  ; row 21
        fcb     $20,$03,$FF,$C0,$00,$00  ; row 22
        fcb     $00,$03,$FF,$C0,$00,$00  ; row 23
        fcb     $20,$03,$FF,$C0,$00,$00  ; row 24
        fcb     $40,$03,$FF,$C0,$00,$00  ; row 25
        fcb     $2A,$AB,$FF,$AA,$AA,$00  ; row 26
        fcb     $55,$5F,$FF,$D5,$55,$40  ; row 27
        fcb     $2A,$AB,$FF,$AA,$AA,$00  ; row 28
        fcb     $55,$5F,$FF,$D5,$55,$40  ; row 29
        fcb     $2A,$AB,$FF,$AA,$AA,$00  ; row 30
        fcb     $55,$5F,$FD,$55,$55,$40  ; row 31
        fcb     $2A,$A0,$42,$AA,$AA,$00  ; row 32
        fcb     $05,$40,$54,$00,$05,$40  ; row 33
        fcb     $02,$00,$55,$40,$02,$00  ; row 34
        fcb     $05,$40,$00,$00,$05,$40  ; row 35
