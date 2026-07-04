* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: sprite_data_9b00.s
*         Apple II label: akuma_throne_room_9EB8
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md �6.7]

akuma_throne_room_9EB8_coco3:
        fcb     42,9  ; height=42 rows, coco3_width=9 bytes/row (4px/byte)
        fcb     $05,$F2,$AA,$A0,$00,$54,$00,$5F,$C4  ; row 0
        fcb     $00,$F2,$AA,$A0,$5F,$FF,$C5,$55,$54  ; row 1
        fcb     $00,$00,$2A,$A0,$05,$55,$40,$55,$40  ; row 2
        fcb     $00,$00,$2A,$A0,$55,$55,$54,$00,$00  ; row 3
        fcb     $00,$00,$02,$A0,$55,$55,$54,$00,$40  ; row 4
        fcb     $00,$FF,$02,$A0,$54,$00,$55,$55,$40  ; row 5
        fcb     $03,$FF,$C0,$20,$40,$FC,$05,$55,$40  ; row 6
        fcb     $0F,$FF,$F0,$20,$43,$FF,$05,$55,$40  ; row 7
        fcb     $BF,$FF,$FC,$20,$43,$FF,$05,$54,$00  ; row 8
        fcb     $BF,$FF,$F0,$00,$40,$FC,$05,$54,$00  ; row 9
        fcb     $FF,$FF,$C0,$40,$54,$00,$55,$40,$00  ; row 10
        fcb     $FF,$FF,$C0,$05,$55,$55,$55,$40,$00  ; row 11
        fcb     $FF,$FF,$00,$05,$55,$55,$54,$00,$00  ; row 12
        fcb     $FF,$FF,$C0,$00,$55,$55,$54,$00,$00  ; row 13
        fcb     $BF,$FF,$F0,$00,$05,$55,$40,$00,$00  ; row 14
        fcb     $BF,$FF,$F0,$00,$00,$00,$00,$00,$00  ; row 15
        fcb     $BF,$FF,$F2,$A0,$40,$00,$04,$00,$00  ; row 16
        fcb     $0F,$FF,$F2,$00,$55,$55,$54,$00,$00  ; row 17
        fcb     $03,$FF,$2A,$05,$55,$55,$55,$40,$00  ; row 18
        fcb     $00,$3C,$2A,$05,$55,$55,$55,$40,$00  ; row 19
        fcb     $00,$00,$00,$05,$55,$55,$55,$40,$00  ; row 20
        fcb     $00,$00,$00,$05,$55,$55,$55,$40,$00  ; row 21
        fcb     $00,$00,$00,$05,$55,$55,$55,$40,$00  ; row 22
        fcb     $00,$00,$00,$05,$55,$55,$55,$54,$00  ; row 23
        fcb     $00,$00,$00,$55,$40,$00,$05,$54,$00  ; row 24
        fcb     $00,$00,$00,$55,$55,$55,$55,$54,$00  ; row 25
        fcb     $00,$00,$00,$55,$55,$55,$55,$54,$00  ; row 26
        fcb     $00,$00,$00,$55,$55,$55,$55,$54,$00  ; row 27
        fcb     $00,$00,$00,$55,$55,$55,$55,$54,$00  ; row 28
        fcb     $00,$00,$00,$55,$55,$55,$55,$54,$00  ; row 29
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 30
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 31
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 32 (blue floor line L removed)
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 33
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 34 (blue floor line L removed)
        fcb     $00,$00,$05,$55,$55,$55,$55,$55,$40  ; row 35
        fcb     $00,$00,$55,$55,$55,$55,$55,$55,$54  ; row 36 (blue floor line L removed)
        fcb     $00,$00,$55,$55,$55,$55,$55,$55,$54  ; row 37
        fcb     $00,$00,$FC,$55,$55,$55,$55,$55,$FC  ; row 38 (blue floor line L removed)
        fcb     $00,$00,$5F,$FC,$55,$55,$55,$FF,$C4  ; row 39
        fcb     $00,$00,$05,$5F,$FF,$FF,$FF,$C5,$40  ; row 40
        fcb     $00,$00,$00,$05,$55,$55,$55,$40,$00  ; row 41
