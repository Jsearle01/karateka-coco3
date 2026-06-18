* converted.s
* CoCo3 sprite data — converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 cell doorway post; clean post, foot removed)
*         Apple II label: addr_964A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md §6.7]

floor_964A_cell_coco3:
        fcb     65,4  ; height=65 rows, coco3_width=4 bytes/row (4px/byte)
        fcb     $03,$FA,$00,$00  ; row 0
        fcb     $03,$FA,$00,$00  ; row 1
        fcb     $03,$FA,$00,$00  ; row 2
        fcb     $03,$FA,$00,$00  ; row 3
        fcb     $03,$FA,$00,$00  ; row 4
        fcb     $03,$FA,$00,$00  ; row 5
        fcb     $03,$FA,$00,$00  ; row 6
        fcb     $03,$FA,$00,$00  ; row 7
        fcb     $03,$FA,$00,$00  ; row 8
        fcb     $03,$FA,$00,$00  ; row 9
        fcb     $03,$FA,$00,$00  ; row 10
        fcb     $03,$FA,$00,$00  ; row 11
        fcb     $03,$FA,$00,$00  ; row 12
        fcb     $03,$FA,$00,$00  ; row 13
        fcb     $03,$FA,$00,$00  ; row 14
        fcb     $03,$FA,$00,$00  ; row 15
        fcb     $03,$FA,$00,$00  ; row 16
        fcb     $03,$FA,$00,$00  ; row 17
        fcb     $03,$FA,$00,$00  ; row 18
        fcb     $03,$FA,$00,$00  ; row 19
        fcb     $03,$FA,$00,$00  ; row 20
        fcb     $03,$FA,$00,$00  ; row 21
        fcb     $03,$FA,$00,$00  ; row 22
        fcb     $03,$FA,$00,$00  ; row 23
        fcb     $03,$FA,$00,$00  ; row 24
        fcb     $03,$FA,$00,$00  ; row 25
        fcb     $03,$FA,$00,$00  ; row 26
        fcb     $03,$FA,$00,$00  ; row 27
        fcb     $03,$FA,$00,$00  ; row 28
        fcb     $03,$FA,$00,$00  ; row 29
        fcb     $03,$FA,$00,$00  ; row 30
        fcb     $03,$FA,$00,$00  ; row 31
        fcb     $03,$FA,$00,$00  ; row 32
        fcb     $03,$FA,$00,$00  ; row 33
        fcb     $03,$FA,$00,$00  ; row 34
        fcb     $03,$FA,$00,$00  ; row 35
        fcb     $03,$FA,$00,$00  ; row 36
        fcb     $03,$FA,$00,$00  ; row 37
        fcb     $03,$FA,$00,$00  ; row 38
        fcb     $03,$FA,$00,$00  ; row 39
        fcb     $03,$FA,$00,$00  ; row 40
        fcb     $03,$FA,$00,$00  ; row 41
        fcb     $03,$FA,$00,$00  ; row 42
        fcb     $03,$FA,$00,$00  ; row 43
        fcb     $03,$FA,$00,$00  ; row 44
        fcb     $03,$FA,$00,$00  ; row 45
        fcb     $03,$FA,$00,$00  ; row 46
        fcb     $03,$FA,$00,$00  ; row 47
        fcb     $03,$FA,$00,$00  ; row 48
        fcb     $03,$FA,$00,$00  ; row 49
        fcb     $03,$FA,$00,$00  ; row 50
        fcb     $03,$FA,$00,$00  ; row 51
        fcb     $03,$FA,$00,$00  ; row 52
        fcb     $03,$FA,$00,$00  ; row 53
        fcb     $03,$FA,$00,$00  ; row 54
        fcb     $03,$FA,$00,$00  ; row 55
        fcb     $03,$FA,$00,$00  ; row 56
        fcb     $03,$FA,$00,$00  ; row 57
        fcb     $03,$FA,$00,$00  ; row 58
        fcb     $03,$FA,$00,$00  ; row 59
        fcb     $03,$FA,$00,$00  ; row 60
        fcb     $03,$FA,$00,$00  ; row 61
        fcb     $03,$FA,$00,$00  ; row 62
        fcb     $03,$FA,$00,$00  ; row 63
        fcb     $03,$FA,$00,$00  ; row 64
