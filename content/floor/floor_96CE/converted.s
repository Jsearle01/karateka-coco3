* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 floor, tbl_sprite_*_a)
*         Apple II label: floor_96CE
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

floor_96CE_coco3:
        fcb     77,2  ; height=77 rows, coco3_width=2 bytes/row (4px/byte)
        fcb     $FE,$80  ; row 0
        fcb     $FE,$80  ; row 1
        fcb     $FE,$80  ; row 2
        fcb     $FE,$80  ; row 3
        fcb     $FE,$80  ; row 4
        fcb     $FE,$80  ; row 5
        fcb     $FE,$80  ; row 6
        fcb     $FE,$80  ; row 7
        fcb     $FE,$80  ; row 8
        fcb     $FE,$80  ; row 9
        fcb     $FE,$80  ; row 10
        fcb     $FE,$80  ; row 11
        fcb     $FE,$80  ; row 12
        fcb     $FE,$80  ; row 13
        fcb     $FE,$80  ; row 14
        fcb     $FE,$80  ; row 15
        fcb     $FE,$80  ; row 16
        fcb     $FE,$80  ; row 17
        fcb     $FE,$80  ; row 18
        fcb     $FE,$80  ; row 19
        fcb     $FE,$80  ; row 20
        fcb     $FE,$80  ; row 21
        fcb     $FE,$80  ; row 22
        fcb     $FE,$80  ; row 23
        fcb     $FE,$80  ; row 24
        fcb     $FE,$80  ; row 25
        fcb     $FE,$80  ; row 26
        fcb     $FE,$80  ; row 27
        fcb     $FE,$80  ; row 28
        fcb     $FE,$80  ; row 29
        fcb     $FE,$80  ; row 30
        fcb     $FE,$80  ; row 31
        fcb     $FE,$80  ; row 32
        fcb     $FE,$80  ; row 33
        fcb     $FE,$80  ; row 34
        fcb     $FE,$80  ; row 35
        fcb     $FE,$80  ; row 36
        fcb     $FE,$80  ; row 37
        fcb     $FE,$80  ; row 38
        fcb     $FE,$80  ; row 39
        fcb     $FE,$80  ; row 40
        fcb     $FE,$80  ; row 41
        fcb     $FE,$80  ; row 42
        fcb     $FE,$80  ; row 43
        fcb     $FE,$80  ; row 44
        fcb     $FE,$80  ; row 45
        fcb     $FE,$80  ; row 46
        fcb     $FE,$80  ; row 47
        fcb     $FE,$80  ; row 48
        fcb     $FE,$80  ; row 49
        fcb     $FE,$80  ; row 50
        fcb     $FE,$80  ; row 51
        fcb     $FE,$80  ; row 52
        fcb     $FE,$80  ; row 53
        fcb     $FE,$80  ; row 54
        fcb     $FE,$80  ; row 55
        fcb     $FE,$80  ; row 56
        fcb     $FE,$80  ; row 57
        fcb     $FE,$80  ; row 58
        fcb     $FE,$80  ; row 59
        fcb     $FE,$80  ; row 60
        fcb     $FE,$80  ; row 61
        fcb     $FE,$80  ; row 62
        fcb     $FE,$80  ; row 63
        fcb     $FE,$80  ; row 64
        fcb     $FE,$80  ; row 65
        fcb     $FE,$80  ; row 66
        fcb     $FE,$80  ; row 67
        fcb     $FE,$80  ; row 68
        fcb     $FE,$80  ; row 69
        fcb     $FE,$80  ; row 70
        fcb     $FE,$80  ; row 71
        fcb     $FE,$80  ; row 72
        fcb     $7E,$80  ; row 73
        fcb     $A8,$00  ; row 74
        fcb     $00,$00  ; row 75
        fcb     $AA,$A8  ; row 76
