* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 cell door; 1b animation element, $84=5 @ f5235)
*         Apple II label: addr_9980
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

door_9980_coco3:
        fcb     75,4  ; height=75 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $FE,$AA,$AA,$80  ; row 0
        fcb     $AA,$AA,$AA,$80  ; row 1
        fcb     $AA,$AA,$AA,$80  ; row 2
        fcb     $AA,$A8,$00,$80  ; row 3
        fcb     $80,$00,$AA,$80  ; row 4
        fcb     $80,$AA,$AA,$80  ; row 5
        fcb     $80,$AA,$AA,$80  ; row 6
        fcb     $80,$AA,$AA,$80  ; row 7
        fcb     $80,$AA,$AA,$80  ; row 8
        fcb     $80,$AA,$AA,$80  ; row 9
        fcb     $80,$AA,$AA,$80  ; row 10
        fcb     $80,$AA,$AA,$80  ; row 11
        fcb     $80,$AA,$AA,$80  ; row 12
        fcb     $80,$AA,$AA,$80  ; row 13
        fcb     $80,$AA,$AA,$80  ; row 14
        fcb     $80,$AA,$AA,$80  ; row 15
        fcb     $80,$AA,$AA,$80  ; row 16
        fcb     $80,$AA,$AA,$80  ; row 17
        fcb     $80,$AA,$AA,$80  ; row 18
        fcb     $80,$AA,$AA,$80  ; row 19
        fcb     $80,$AA,$AA,$80  ; row 20
        fcb     $80,$AA,$AA,$80  ; row 21
        fcb     $80,$AA,$AA,$80  ; row 22
        fcb     $80,$AA,$AA,$80  ; row 23
        fcb     $80,$AA,$AA,$80  ; row 24
        fcb     $80,$AA,$AA,$80  ; row 25
        fcb     $80,$AA,$AA,$80  ; row 26
        fcb     $80,$AA,$AA,$80  ; row 27
        fcb     $80,$AA,$AA,$80  ; row 28
        fcb     $80,$AA,$AA,$80  ; row 29
        fcb     $80,$AA,$AA,$80  ; row 30
        fcb     $80,$AA,$AA,$80  ; row 31
        fcb     $80,$AA,$AA,$80  ; row 32
        fcb     $80,$AA,$AA,$80  ; row 33
        fcb     $80,$AA,$AA,$80  ; row 34
        fcb     $80,$AA,$AA,$80  ; row 35
        fcb     $80,$AA,$AA,$80  ; row 36
        fcb     $80,$AA,$AA,$80  ; row 37
        fcb     $80,$AA,$AA,$80  ; row 38
        fcb     $80,$AA,$AA,$80  ; row 39
        fcb     $80,$AA,$AA,$80  ; row 40
        fcb     $80,$AA,$AA,$80  ; row 41
        fcb     $80,$AA,$AA,$80  ; row 42
        fcb     $80,$AA,$AA,$80  ; row 43
        fcb     $80,$AA,$AA,$80  ; row 44
        fcb     $80,$AA,$AA,$80  ; row 45
        fcb     $80,$AA,$AA,$80  ; row 46
        fcb     $80,$AA,$AA,$80  ; row 47
        fcb     $80,$AA,$AA,$80  ; row 48
        fcb     $80,$AA,$AA,$80  ; row 49
        fcb     $80,$AA,$AA,$80  ; row 50
        fcb     $80,$AA,$AA,$80  ; row 51
        fcb     $80,$AA,$AA,$80  ; row 52
        fcb     $80,$AA,$AA,$80  ; row 53
        fcb     $80,$AA,$AA,$80  ; row 54
        fcb     $80,$AA,$AA,$80  ; row 55
        fcb     $80,$AA,$AA,$80  ; row 56
        fcb     $80,$AA,$AA,$80  ; row 57
        fcb     $80,$AA,$AA,$80  ; row 58
        fcb     $80,$AA,$AA,$80  ; row 59
        fcb     $80,$AA,$AA,$80  ; row 60
        fcb     $80,$AA,$AA,$80  ; row 61
        fcb     $80,$AA,$AA,$80  ; row 62
        fcb     $80,$AA,$AA,$80  ; row 63
        fcb     $AF,$EA,$AA,$80  ; row 64
        fcb     $AA,$FE,$AA,$80  ; row 65
        fcb     $AA,$AF,$EA,$80  ; row 66
        fcb     $AA,$AA,$FE,$80  ; row 67
        fcb     $0A,$AA,$AA,$80  ; row 68
        fcb     $00,$AA,$AA,$80  ; row 69
        fcb     $00,$0A,$AA,$80  ; row 70
        fcb     $00,$00,$AA,$80  ; row 71
        fcb     $AA,$A8,$0A,$80  ; row 72
        fcb     $00,$00,$00,$80  ; row 73
        fcb     $AA,$AA,$A8,$00  ; row 74
