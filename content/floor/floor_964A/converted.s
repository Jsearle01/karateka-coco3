* converted.s
* CoCo3 sprite data � converted from Apple II source.
*
* ORIGIN: dump05 by addr (scene-5 floor, tbl_sprite_*_a)
*         Apple II label: addr_964A
* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified
*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).
*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White
*   start_col=0
* [ref: karateka-coco3 docs/project/karateka-coco3-design-v0.1.md �6.7]

floor_964A_coco3:
        fcb     65,5  ; height=65 rows, coco3_width=5 (was 4; +1 leading pad byte for left-line extend)
        fcb     $00,$03,$FA,$00,$00  ; row 0
        fcb     $00,$03,$FA,$00,$00  ; row 1
        fcb     $00,$03,$FA,$00,$00  ; row 2
        fcb     $00,$03,$FA,$00,$00  ; row 3
        fcb     $00,$03,$FA,$00,$00  ; row 4
        fcb     $00,$03,$FA,$00,$00  ; row 5
        fcb     $00,$03,$FA,$00,$00  ; row 6
        fcb     $00,$03,$FA,$00,$00  ; row 7
        fcb     $00,$03,$FA,$00,$00  ; row 8
        fcb     $00,$03,$FA,$00,$00  ; row 9
        fcb     $00,$03,$FA,$00,$00  ; row 10
        fcb     $00,$03,$FA,$00,$00  ; row 11
        fcb     $00,$03,$FA,$00,$00  ; row 12
        fcb     $00,$03,$FA,$00,$00  ; row 13
        fcb     $00,$03,$FA,$00,$00  ; row 14
        fcb     $00,$03,$FA,$00,$00  ; row 15
        fcb     $00,$03,$FA,$00,$00  ; row 16
        fcb     $00,$03,$FA,$00,$00  ; row 17
        fcb     $00,$03,$FA,$00,$00  ; row 18
        fcb     $00,$03,$FA,$00,$00  ; row 19
        fcb     $00,$03,$FA,$00,$00  ; row 20
        fcb     $00,$03,$FA,$00,$00  ; row 21
        fcb     $00,$03,$FA,$00,$00  ; row 22
        fcb     $00,$03,$FA,$00,$00  ; row 23
        fcb     $00,$03,$FA,$00,$00  ; row 24
        fcb     $00,$03,$FA,$00,$00  ; row 25
        fcb     $00,$03,$FA,$00,$00  ; row 26
        fcb     $00,$03,$FA,$00,$00  ; row 27
        fcb     $00,$03,$FA,$00,$00  ; row 28
        fcb     $00,$03,$FA,$00,$00  ; row 29
        fcb     $00,$03,$FA,$00,$00  ; row 30
        fcb     $00,$03,$FA,$00,$00  ; row 31
        fcb     $00,$03,$FA,$00,$00  ; row 32
        fcb     $00,$03,$FA,$00,$00  ; row 33
        fcb     $00,$03,$FA,$00,$00  ; row 34
        fcb     $00,$03,$FA,$00,$00  ; row 35
        fcb     $00,$03,$FA,$00,$00  ; row 36
        fcb     $00,$03,$FA,$00,$00  ; row 37
        fcb     $00,$03,$FA,$00,$00  ; row 38
        fcb     $00,$03,$FA,$00,$00  ; row 39
        fcb     $00,$03,$FA,$00,$00  ; row 40
        fcb     $00,$03,$FA,$00,$00  ; row 41
        fcb     $00,$03,$FA,$00,$00  ; row 42
        fcb     $00,$03,$FA,$00,$00  ; row 43
        fcb     $00,$03,$FA,$00,$00  ; row 44
        fcb     $00,$03,$FA,$00,$00  ; row 45
        fcb     $00,$03,$FA,$00,$00  ; row 46
        fcb     $00,$03,$FA,$00,$00  ; row 47
        fcb     $00,$03,$FA,$00,$00  ; row 48
        fcb     $00,$03,$FA,$00,$00  ; row 49
        fcb     $00,$03,$FA,$00,$00  ; row 50
        fcb     $00,$03,$FA,$00,$00  ; row 51
        fcb     $00,$03,$FA,$00,$00  ; row 52
        fcb     $00,$03,$FA,$00,$00  ; row 53
        fcb     $00,$03,$FA,$00,$00  ; row 54
        fcb     $00,$03,$FA,$00,$00  ; row 55
        fcb     $00,$03,$FA,$00,$00  ; row 56
        fcb     $00,$03,$FA,$00,$00  ; row 57
        fcb     $00,$03,$FA,$AA,$A0  ; row 58
        fcb     $00,$03,$FA,$00,$00  ; row 59
        fcb     $00,$03,$FA,$AA,$A0  ; row 60
        fcb     $00,$03,$FA,$00,$00  ; row 61
        fcb     $02,$AB,$FA,$AA,$A0  ; row 62
        fcb     $00,$03,$FA,$00,$00  ; row 63
        fcb     $02,$AB,$FA,$AA,$A0  ; row 64
