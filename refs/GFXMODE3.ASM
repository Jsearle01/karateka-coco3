* CoCo 3 Assembly: Set 320x192x4 Color Mode, Graphics RAM at $6000
                    ORG   $2000

DRAW_SCREEN EQU                 $6000
WORK_SCREEN EQU                 $A000
WORK_SCREEN_SIZE EQU            $4080          ; 16,512 bytes (192 visible + 8 extra lines for off-screen text)
BITMAPDATAPTR EQU               $0003
BITMAPDATAPTR_LOBYTE EQU        $0004
Y_COOR_OFFSET EQU               $0006
STARTING_X_POS EQU              $0014
SCRPTRLO_BYTE EQU               $0001
SCRPTRHIGH_BYTE EQU             $0000
HIBYTE_OFFSET_FOR_SCREEN EQU    $0007
TOP_OFFSET EQU                  $0016
MASKED_RESULT EQU               $001A
HEIGHT_CNT_IN_LINES EQU         $000E
BITMAP_X_C00R EQU               $0005
CURRENT_ROW_COUNT EQU           $0015
CURRENT_WIDTH_IN_BYTES EQU      $000F
MASK_BYTE        EQU            $0010
CURRENT_BITMAP_BYTE EQU         $001B
SAVED_X_REG EQU                 $0017
SAVED_Y_REG EQU                 $0019
WIDTH_IN_BYTES EQU              $000D

; Variables for multi-sprite system
CMD_LIST_PTR EQU                $0020
SAVED_HEIGHT EQU                $0021
SAVED_INDEX EQU                 $0022
X_COOR_WIDTH EQU                $0023
RENDER_FLAG EQU                 $000A          ; 0=transparency on, 1=no transparency

START
                    ORCC #$50
                    LDA #0
                    STA	$FFD9
                    STA RENDER_FLAG            ; Initialize transparency mode (0=on)

                    ; Clear visible screen BEFORE enabling video mode
                    LDX #DRAW_SCREEN
                    LDD #$0000
                    LDY #$3C00/2
INIT_CLEAR          STD ,X++
                    LEAY -1,Y
                    BNE INIT_CLEAR

                    ; Now enable video mode (screen is already black)
                    LDD #$8015	'320x192x4 GFX
                    STD $FF98
                    LDD #$EC00                 ; Video offset for $6000 (correct value verified)
                    STD	$FF9D
                    STB	$FF9F
                    LDA	#$4C
                    STA	$FF90
                    LDA #0
                    STA $FFDF
                    LDA #$00
                    STA $FFB0
                    LDA #$26
                    STA $FFB1
                    LDA #$1B
                    STA $FFB2
                    LDA #$FF
                    STA $FFB3
                    LDS #$0100
                    LDA #$00
                    TFR A,DP

START_BRODER        JSR BUTTON_VALUE_STORAGE
                    ; Clear only work buffer (not visible to avoid flash)
                    LDX #WORK_SCREEN
                    JSR SCREEN_CLEAR

                    ; Render frame to work buffer
                    JSR DRAW_BRODERBUND        ; Render to work buffer
                    JSR SCENE_SETUP_1          ; Add more to work buffer

                    ; Copy completed frame to visible screen
                    JSR COPY_TO_VISIBLE

                    JSR DELAY_BEFORE_CLEAR    ; Wait so user can see it

                    ; Scene 2 with double buffering
                    LDX #WORK_SCREEN
                    JSR SCREEN_CLEAR
                    JSR SCENE_SETUP_2
                    JSR COPY_TO_VISIBLE
                    JSR DELAY_BEFORE_CLEAR

                    ; Scene 3 with double buffering
                    LDX #WORK_SCREEN
                    JSR SCREEN_CLEAR
                    JSR SCENE_SETUP_3
                    JSR COPY_TO_VISIBLE
                    JSR DELAY_BEFORE_CLEAR

                    ; Scene 4 - Scrolling text demo
                    JSR SCENE_SETUP_4

LOOP                BRA LOOP

RENDER_DISPATCH       JMP BITMAP_HDR_PARSER

BUTTON_VALUE_STORAGE
                    NOP
                    RTS

SCREEN_CLEAR        LDD   #$0000
                    LDY   #WORK_SCREEN_SIZE/2  ; 15,520 bytes (includes 2 extra lines)
SCREEN_LOOP         STD   ,X++
                    LEAY  -1,Y
                    BNE   SCREEN_LOOP
                    RTS

;=====================================================
; Clear Bottom 8 Lines (lines 192-199 of extended work screen)
; These are the extra lines where text renders before scrolling into view
;=====================================================
CLEAR_OFFSCREEN_BUFFER:
                    LDA   #192               ; Line 192 (first extra line)
                    LDB   #$50               ; 80 bytes per line
                    MUL                      ; D = 192 * 80
                    ADDD  #WORK_SCREEN       ; Add base address
                    TFR   D,X                ; X = pointer to line 192
                    LDD   #$0000             ; Clear with black
                    LDY   #640/2             ; 640 bytes = 320 words (8 lines)
OFFSCREEN_CLEAR_LOOP:
                    STD   ,X++
                    LEAY  -1,Y
                    BNE   OFFSCREEN_CLEAR_LOOP
                    RTS

;=====================================================
; Copy Work Buffer to Visible Screen
; Copies 15,360 bytes ($3C00) from $A000 to $6000
;=====================================================
COPY_TO_VISIBLE     LDX   #WORK_SCREEN       ; Source: work buffer
                    LDU   #DRAW_SCREEN       ; Dest: visible screen
                    LDY   #$3C00/2           ; 15,360 bytes = 7,680 words
COPY_LOOP           LDD   ,X++               ; Read word from work buffer
                    STD   ,U++               ; Write word to visible screen
                    LEAY  -1,Y
                    BNE   COPY_LOOP
                    RTS

DRAW_BRODERBUND     LDD #SHIPS      'B898
                    STD BITMAPDATAPTR
                    LDA #$22
                    STA BITMAP_X_C00R
                    LDA #$48
                    STA Y_COOR_OFFSET
                    JSR RENDER_DISPATCH
                    LDD #BRODERBUND
                    STD BITMAPDATAPTR
                    LDA #$18
                    STA BITMAP_X_C00R
                    LDA #$58
                    STA Y_COOR_OFFSET
                    JMP RENDER_DISPATCH

;=====================================================
; Scene Setup Functions
;=====================================================

SCENE_SETUP_1:
                    LDA   #$6E
                    STA   Y_COOR_OFFSET
                    LDB   #$00
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER
                    RTS

SCENE_SETUP_2:
                    ; First two lines
                    LDA   #$55
                    STA   Y_COOR_OFFSET
                    LDB   #$01
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER

                    LDA   #$63
                    STA   Y_COOR_OFFSET
                    LDB   #$02
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER

                    ; Show first two lines
                    JSR   COPY_TO_VISIBLE
                    JSR   DELAY_BEFORE_CLEAR

                    ; Add next two lines to work buffer
                    LDA   #$80
                    STA   Y_COOR_OFFSET
                    LDB   #$16
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER

                    LDA   #$8E
                    STA   Y_COOR_OFFSET
                    LDB   #$17
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER
                    RTS

SCENE_SETUP_3:
                    ; Render "KARATEKA" using table-driven approach
                    LDX   #KARATEKA_SPRITE_TABLE
SCENE3_LOOP:
                    LDD   ,X++                ; Get sprite pointer
                    BEQ   SCENE3_DONE         ; 0 = end marker
                    STD   BITMAPDATAPTR
                    LDA   ,X+                 ; Get X position
                    STA   BITMAP_X_C00R
                    LDA   ,X+                 ; Get Y position
                    STA   Y_COOR_OFFSET
                    PSHS  X
                    JSR   RENDER_DISPATCH
                    PULS  X
                    BRA   SCENE3_LOOP
SCENE3_DONE:
                    RTS

; Sprite table: pointer (2 bytes), X pos (1 byte), Y pos (1 byte)
KARATEKA_SPRITE_TABLE:
                    .WORD SPRITE_BCA7         ; K
                    .BYTE $08,$50
                    .WORD SPRITE_BD5D         ; K overlay
                    .BYTE $07,$45
                    .WORD SPRITE_TBBEC        ; A
                    .BYTE $0E,$50
                    .WORD SPRITE_BF24         ; R
                    .BYTE $16,$50
                    .WORD SPRITE_TBBEC        ; A
                    .BYTE $1F,$50
                    .WORD SPRITE_BD75         ; T
                    .BYTE $27,$4E
                    .WORD SPRITE_BE44         ; E
                    .BYTE $2E,$50
                    .WORD SPRITE_BCA7         ; K
                    .BYTE $38,$50
                    .WORD SPRITE_BD5D         ; K overlay
                    .BYTE $37,$45
                    .WORD SPRITE_TBBEC        ; A
                    .BYTE $3E,$50
                    .WORD $0000               ; End marker

SCENE_SETUP_4:
                    ; Karateka scrolling text intro sequence
                    ; Use TRANSPARENCY rendering for clean text
                    LDA   #$00                 ; Enable transparency
                    STA   RENDER_FLAG

                    ; Clear work buffer
                    LDX   #WORK_SCREEN
                    JSR   SCREEN_CLEAR         ; Clear work buffer

                    ; Clear off-screen buffer (for text rendering)
                    JSR   CLEAR_OFFSCREEN_BUFFER

                    ; Render all 12 text lines using table-driven approach
                    LDX   #SCROLL_TEXT_TABLE   ; Point to command list table
                    STX   SCROLL_TABLE_PTR

RENDER_TEXT_LOOP:
                    LDX   SCROLL_TABLE_PTR
                    LDB   ,X+                  ; Get cmdlist index
                    CMPB  #$FF                 ; End marker?
                    BEQ   SCROLL_FINAL         ; Yes, do final scroll-off
                    STX   SCROLL_TABLE_PTR     ; Save updated pointer

                    JSR   RENDER_AND_SCROLL_LINE
                    BRA   RENDER_TEXT_LOOP

SCROLL_FINAL:
                    ; Scroll 24 blank lines to scroll all text off screen
                    LDB   #24
FINAL_SCROLL_LOOP:
                    PSHS  B
                    LDB   #$0B                 ; CMDLIST_11 (blank)
                    JSR   RENDER_AND_SCROLL_LINE
                    PULS  B
                    DECB
                    BNE   FINAL_SCROLL_LOOP
                    RTS

;=====================================================
; RENDER_AND_SCROLL_LINE - Render one text line and scroll 8 times
; Input: B = command list index
;=====================================================
RENDER_AND_SCROLL_LINE:
                    PSHS  B                    ; Save command list index
                    JSR   CLEAR_OFFSCREEN_BUFFER
                    LDA   #$B4                 ; Y position = line 180
                    STA   Y_COOR_OFFSET
                    PULS  B                    ; Restore command list index
                    JSR   SETUP_CMD_LIST
                    JSR   MULTI_SPRITE_RENDER_NO_DOUBLE
                    JSR   COPY_TO_VISIBLE
                    ; Fall through to SCROLL_8_TIMES

;=====================================================
; SCROLL_8_TIMES - Scroll screen 8 times with delay
;=====================================================
SCROLL_8_TIMES:
                    LDA   #8
SCROLL_8_LOOP:
                    PSHS  A
                    JSR   SCROLL_TEXT_UP
                    JSR   COPY_TO_VISIBLE
                    PULS  A
                    DECA
                    BEQ   SCROLL_8_DONE
                    PSHS  A
                    JSR   DELAY_SCROLL
                    PULS  A
                    BRA   SCROLL_8_LOOP
SCROLL_8_DONE:
                    RTS

; Table of command list indices for text lines
SCROLL_TEXT_TABLE:
                    .BYTE $03                  ; Line 1: "high atop a craggy cliff guarded"
                    .BYTE $05                  ; Line 2: "by an army of fierce warriors,"
                    .BYTE $06                  ; Line 3: "stands the fortress of the evil"
                    .BYTE $07                  ; Line 4: "warlord akuma. deep in the"
                    .BYTE $08                  ; Line 5: "darkest dungeon of the castle,"
                    .BYTE $09                  ; Line 6: "akuma gloats over his lovely"
                    .BYTE $0A                  ; Line 7: "captive, the princess mariko."
                    .BYTE $0B                  ; Line 8: BLANK LINE
                    .BYTE $0C                  ; Line 9: "you are one trained in the way"
                    .BYTE $0D                  ; Line 10: "of karate: a karateka. alone and"
                    .BYTE $0E                  ; Line 11: "unarmed, you must defeat akuma"
                    .BYTE $0F                  ; Line 12: "and rescue the beautiful mariko."
                    .BYTE $FF                  ; End marker

; Variable for table pointer
SCROLL_TABLE_PTR    EQU $0027                  ; 2 bytes

SETUP_CMD_LIST:
                    ASLB
                    LDX   #CMD_LIST_PTR_TABLE
                    LDD   B,X
                    STD   CMD_LIST_PTR
                    RTS

;=====================================================
; Multi-Sprite Command List Processor (Unified)
; MULTI_SPRITE_RENDER: doubles X coord (Apple II 40-col to CoCo3 80-col)
; MULTI_SPRITE_RENDER_NO_DOUBLE: uses X coord as-is
;=====================================================

CHAR_INDEX EQU $0024
DOUBLE_X_FLAG EQU $0029                    ; 0=no double, 1=double X coord

MULTI_SPRITE_RENDER:
                    LDA   #1
                    STA   DOUBLE_X_FLAG
                    BRA   SPRITE_RENDER_COMMON

MULTI_SPRITE_RENDER_NO_DOUBLE:
                    CLR   DOUBLE_X_FLAG

SPRITE_RENDER_COMMON:
                    LDU   CMD_LIST_PTR
                    LDA   ,U+              ; Read X position
                    TST   DOUBLE_X_FLAG    ; Should we double X?
                    BEQ   SPRITE_STORE_X
                    ASLA                   ; Convert to CoCo3 80-column bytes
SPRITE_STORE_X:
                    STA   X_COOR_WIDTH
                    LEAU  1,U              ; Skip Y byte (don't overwrite Y_COOR_OFFSET)

SPRITE_LOOP:
                    LDA   ,U+              ; Get character code
                    SUBA  #$60             ; Convert to index (0-31)
                    LBMI  SPRITE_DONE      ; If < 0, we're done

                    STA   CHAR_INDEX       ; Save character index for width lookup

                    TFR   A,B              ; Copy to B
                    ASLB                   ; B = index * 2 (word table)
                    LDX   #SPRITE_PTR_TABLE
                    LDD   B,X              ; Get character bitmap pointer
                    STD   BITMAPDATAPTR

                    LDA   CHAR_INDEX       ; Get index back
                    TSTA                   ; Test if index 0 (space)
                    BEQ   UPDATE_X_POS     ; Space doesn't render, just advance X

                    STA   SAVED_INDEX      ; Save index for width lookup

DO_RENDER:
                    LDA   X_COOR_WIDTH
                    STA   BITMAP_X_C00R

                    ; Look up Y-offset adjustment from table
                    LDA   CHAR_INDEX
                    LDX   #CHAR_Y_OFFSET_TABLE
                    LDA   A,X              ; Get Y offset adjustment (0, 1, or 2)
                    BEQ   NORMAL_RENDER    ; No adjustment needed

                    ; Apply Y adjustment
                    PSHS  A                ; Save adjustment value
                    LDB   Y_COOR_OFFSET
                    SUBB  ,S               ; Subtract offset
                    STB   Y_COOR_OFFSET
                    JSR   BITMAP_HDR_PARSER
                    LDA   Y_COOR_OFFSET
                    ADDA  ,S+              ; Restore Y offset
                    STA   Y_COOR_OFFSET
                    BRA   UPDATE_X_POS

NORMAL_RENDER:
                    JSR   BITMAP_HDR_PARSER

UPDATE_X_POS:
                    LDA   CHAR_INDEX       ; Get saved character index
                    LDX   #SPRITE_WIDTH_TABLE
                    LDA   A,X              ; Get width for this character
                    ADDA  X_COOR_WIDTH     ; Add to current X position
                    STA   X_COOR_WIDTH     ; Store new X position
                    LBRA  SPRITE_LOOP      ; Next character

SPRITE_DONE:
                    RTS

; Y-offset adjustment table (indexed by character 0-31)
; 0=no adjustment, 1=up 1 line, 2=up 2 lines
CHAR_Y_OFFSET_TABLE:
                    .BYTE 0,0,0,0,1,0,1,0  ; 0-7:  SPACE,A,B,C,D(1),E,F(1),G
                    .BYTE 2,2,0,2,2,0,0,0  ; 8-15: H(2),I(2),J,K(2),L(2),M,N,O
                    .BYTE 0,0,0,0,2,0,0,0  ; 16-23: P,Q,R,S,T(2),U,V,W
                    .BYTE 0,0,0,0,0,0,0,0  ; 24-31: X,Y,Z,PERIOD,COMMA,COLON,HYPHEN,unused

;=====================================================
; Single Sprite Renderer
;=====================================================
                
BITMAP_HDR_PARSER   JSR BITMAP_DATA_SETUP
                    JMP PRE_RENDER

PRE_RENDER          LDA HEIGHT_CNT_IN_LINES
                    STA CURRENT_ROW_COUNT
                    LDA WIDTH_IN_BYTES
                    STA CURRENT_WIDTH_IN_BYTES

;=================================================
; Main Render Loop with Two-Pass Transparency
;=================================================
MAIN_RENDER         LDA Y_COOR_OFFSET
                    LDB #$50
                    MUL                     ; D = Y * 80
                    ADDB BITMAP_X_C00R      ; Add X position to low byte
                    ADCA #$00               ; Add carry to high byte
                    ADDD #WORK_SCREEN       ; Render to work buffer (double buffering)
                    TFR D,X                 ; X now points to correct screen position
                    
                    LDY BITMAPDATAPTR
                    LEAY 2,Y                ; Skip width/height header
                    BRA BYTE_LOOP

ROW_LOOP            LDB WIDTH_IN_BYTES
                    STB CURRENT_WIDTH_IN_BYTES
                    LDB #$50
                    SUBB WIDTH_IN_BYTES
                    ABX

BYTE_LOOP           LDB   ,Y+                  ; Load bitmap byte
                    LDA   RENDER_FLAG          ; Check transparency mode
                    BNE   NO_TRANSPARENCY      ; If disabled, write directly

                    ; === TRANSPARENCY MODE ===
                    ; Build mask: set bits where pixel is 0 (transparent)
                    ; Check each of 4 pixels (2 bits each)
                    CLR   MASK_BYTE
                    STB   CURRENT_BITMAP_BYTE  ; Save original bitmap byte

                    ; Pixel 3 (bits 0-1)
                    TFR   B,A
                    ANDA  #$03
                    BNE   PIXEL3_OK
                    LDA   #%00000011
                    ORA   MASK_BYTE
                    STA   MASK_BYTE
PIXEL3_OK:
                    ; Pixel 2 (bits 2-3)
                    TFR   B,A
                    ANDA  #$0C
                    BNE   PIXEL2_OK
                    LDA   #%00001100
                    ORA   MASK_BYTE
                    STA   MASK_BYTE
PIXEL2_OK:
                    ; Pixel 1 (bits 4-5)
                    TFR   B,A
                    ANDA  #$30
                    BNE   PIXEL1_OK
                    LDA   #%00110000
                    ORA   MASK_BYTE
                    STA   MASK_BYTE
PIXEL1_OK:
                    ; Pixel 0 (bits 6-7)
                    TFR   B,A
                    ANDA  #$C0
                    BNE   PIXEL0_OK
                    LDA   #%11000000
                    ORA   MASK_BYTE
                    STA   MASK_BYTE
PIXEL0_OK:
                    ; Apply transparency mask
                    ; MASK_BYTE has 1s where pixels are transparent (color 0)
                    LDA   MASK_BYTE            ; A = transparency mask
                    ANDA  ,X                   ; Keep screen pixels where transparent
                    ORA   CURRENT_BITMAP_BYTE  ; OR in bitmap (0s in transparent spots)
                    STA   ,X+
                    BRA   NEXT_BYTE

                    ; === NO TRANSPARENCY MODE ===
NO_TRANSPARENCY:
                    STB   ,X+

NEXT_BYTE
    
                    LDB CURRENT_WIDTH_IN_BYTES
                    DECB
                    STB CURRENT_WIDTH_IN_BYTES
                    BNE BYTE_LOOP
                    LDB CURRENT_ROW_COUNT
                    DECB
                    STB CURRENT_ROW_COUNT
                    BNE   ROW_LOOP
                    RTS

BITMAP_DATA_SETUP   LDY #$0000
                    LDD [BITMAPDATAPTR,Y]
                    STB WIDTH_IN_BYTES
                    STA HEIGHT_CNT_IN_LINES
                    RTS 



;=====================================================
; Delay routine - adjust counter for speed
;=====================================================
DELAY_BEFORE_CLEAR
                    LDA   #$10                ; Outer loop counter (16 iterations - medium delay)
DELAY_OUTER
                    LDX   #$FFFF              ; Inner loop - maximum
DELAY_INNER         LEAX  -1,X
                    BNE   DELAY_INNER
                    DECA
                    BNE   DELAY_OUTER
                    RTS

; Faster delay for scrolling
DELAY_SCROLL
                    LDA   #$01                ; Very short delay for fast scrolling
DELAY_SCROLL_OUTER
                    LDX   #$4000              ; Short inner loop
DELAY_SCROLL_INNER  LEAX  -1,X
                    BNE   DELAY_SCROLL_INNER
                    DECA
                    BNE   DELAY_SCROLL_OUTER
                    RTS

;=====================================================
; SCROLLING TEXT ROUTINES
; Merged from SCROLL_TEXT.ASM
; Based on Apple II Karateka scrolling code at $0786
;=====================================================

; Zero-page variables for scrolling
SCROLL_DSTPTR       EQU $001C       ; 2 bytes - destination pointer
SCROLL_SRCPTR       EQU $001E       ; 2 bytes - source pointer
LINE_INDEX          EQU $0025       ; 1 byte  - line counter
SCROLL_DELAY_CNT    EQU $0026       ; 1 byte  - delay counter

; Screen constants (from original SCROLL_TEXT.ASM)
BYTES_PER_LINE      EQU $50         ; 80 bytes per line (320 pixels / 4 pixels per byte)
NUM_LINES           EQU 192         ; Total pixel lines on screen
TEXT_START_LINE     EQU $48         ; Line 72 - where text starts
TEXT_AREA_LINES     EQU 191         ; Scroll through line 191

; Screen buffer addresses
; DRAW_SCREEN         EQU $6000       ; Visible screen (already defined in GFXMODE3.ASM)
; WORK_SCREEN         EQU $A000       ; Work buffer (already defined in GFXMODE3.ASM)

;=====================================================
; SCROLL_TEXT_UP - Main scrolling routine
; Scrolls the text area up by one pixel line
;=====================================================
SCROLL_TEXT_UP:
                    ; Scroll the entire screen up by 2 scan lines
                    ; Based on original SCROLL_TEXT.ASM
                    LDA   #$00                 ; Start at line 0 (entire screen)
                    STA   LINE_INDEX

SCROLL_LOOP:
                    JSR   SETUP_LINE_POINTERS  ; Setup src/dst pointers
                    JSR   COPY_ONE_LINE        ; Copy 80 bytes

                    ; Move to next line
                    LDA   LINE_INDEX
                    INCA                       ; Next line
                    STA   LINE_INDEX
                    CMPA  #191                 ; Done? (scroll through line 191)
                    BLO   SCROLL_LOOP

                    RTS

;=====================================================
; SETUP_LINE_POINTERS - Setup pointers for current line
; Based on original SCROLL_TEXT.ASM
;=====================================================
SETUP_LINE_POINTERS:
                    ; Calculate destination address = WORK_SCREEN + (LINE_INDEX * 80)
                    LDA   LINE_INDEX
                    LDB   #BYTES_PER_LINE
                    MUL                        ; D = line * 80
                    ADDD  #WORK_SCREEN         ; Add work buffer base address
                    STD   SCROLL_DSTPTR        ; Store 16-bit pointer

                    ; Calculate source address = WORK_SCREEN + ((LINE_INDEX+2) * 80)
                    LDA   LINE_INDEX
                    ADDA  #$02                 ; Source is 2 lines down
                    LDB   #BYTES_PER_LINE
                    MUL                        ; D = (line+2) * 80
                    ADDD  #WORK_SCREEN         ; Add work buffer base address
                    STD   SCROLL_SRCPTR        ; Store 16-bit pointer

                    RTS

;=====================================================
; COPY_ONE_LINE - Copy one line from source to destination
;=====================================================
COPY_ONE_LINE:
                    LDX   SCROLL_SRCPTR
                    LDU   SCROLL_DSTPTR
                    LDB   #BYTES_PER_LINE
COPY_BYTE_LOOP:
                    LDA   ,X+
                    STA   ,U+
                    DECB
                    BNE   COPY_BYTE_LOOP
                    RTS

;=====================================================
; End of scrolling text routines
; (Unused routines removed to save space)
;=====================================================

                    ;ORG $3000
SHIPS       .BYTE $0E,$07,$00,$04,$00,$00,$00,$40,$00,$00,$3F,$00,$00,$03,$F0,$00,$3F,$04,$3F,$03,$F0,$43,$F0,$F0,$FF,$C3,$CF,$0F,$FC,$3C,$3C,$00,$0F,$03,$C0,$00,$F0,$04,$00,$04,$00,$40,$00,$40,$0F,$00,$3C,$20,$F0,$03,$C0,$03,$FF,$20,$FC,$23,$FF,$00,$00,$02,$3C,$20,$F2,$00,$00,$00,$03,$C3,$FF,$0F,$00,$00,$00,$00,$F0,$00,$3C,$00,$00,$00,$00,$20,$00,$20,$00,$00,$00,$00,$3C,$00,$F0,$00,$00,$00,$00,$0F,$FF,$C0,$00,$00

BRODERBUND  .BYTE $09,$1A,$3F,$C0,$00,$00,$00,$F0,$00,$00,$0F,$00,$00,$00,$00,$03,$C0,$3F,$00,$00,$3C,$00,$00,$00,$00,$00,$00,$00,$F0,$F0,$00,$00,$00,$F0,$00,$00,$0F,$00,$00,$00,$00,$03,$C0,$F0,$00,$00,$F0,$F0,$00,$00,$00,$00,$00,$00,$F0,$F0,$FC,$F0,$0F,$F0,$FC,$0F,$CF,$F0,$F3,$C3,$F0,$3F,$C0,$F0,$03,$F3,$FF,$FC,$F3,$CF,$0F,$C0,$FC,$FC,$FF,$C3,$C3,$C2,$3C,$F3,$CF,$3C,$0F,$3C,$F3,$CF,$3C,$F3,$C0,$FC,$0F,$3C,$F0,$F0,$F3,$CF,$3C,$F3,$C3,$CF,$F0,$F3,$C3,$CF,$3C,$F3,$CF,$3C,$0F,$3C,$F3,$CF,$3C,$F3,$C0,$3F,$0F,$3C,$F0,$F0,$F3,$CF,$00,$F3,$C3,$CF,$F0,$F3,$C3,$CF,$3C,$F3,$FC,$3C,$0F,$3C,$F3,$CF,$3C,$F3,$C0,$0F,$CF,$3C,$F0,$F0,$F3,$CF,$0F,$F3,$C3,$FC,$F0,$F3,$C3,$CF,$3C,$F3,$C0,$3C,$0F,$3C,$F3,$CF,$3C,$F3,$C0,$03,$CF,$3C,$F0,$F0,$F3,$CF,$3C,$F3,$C3,$C0,$F0,$F3,$C2,$0F,$3C,$F3,$CF,$3C,$0F,$3C,$F3,$CF,$3C,$F3,$C0,$03,$CF,$3C,$F0,$F0,$F3,$CF,$3C,$F3,$C3,$CF,$FF,$C3,$C0,$3C,$0F,$C0,$FC,$3C,$03,$F0,$3F,$0F,$3C,$3F,$00,$3F,$03,$F0,$F0,$3C,$3C,$3C,$0F,$F3,$C0,$FC
            
;=====================================================
; DATA TABLES - Command List Pointers (22 entries)
;=====================================================

CMD_LIST_PTR_TABLE:
                .WORD CMDLIST_00,CMDLIST_01,CMDLIST_02,CMDLIST_03
                .WORD CMDLIST_04,CMDLIST_05,CMDLIST_06,CMDLIST_07
                .WORD CMDLIST_08,CMDLIST_09,CMDLIST_10,CMDLIST_11
                .WORD CMDLIST_12,CMDLIST_13,CMDLIST_14,CMDLIST_15
                .WORD CMDLIST_16,CMDLIST_17,CMDLIST_18,CMDLIST_19
                .WORD CMDLIST_20,CMDLIST_21,CMDLIST_22,CMDLIST_23
                .WORD CMDLIST_24

;=====================================================
; DATA TABLES - Character/Sprite Pointers (32 entries)
; Points to Apple II font data (convert with your tool)
;=====================================================

SPRITE_PTR_TABLE    .WORD CHAR_SPACE  ; Index 0:  $60 = space
                    .WORD CHAR_00     ; Index 1:  $61 = 'a' → A ✓
                    .WORD CHAR_01     ; Index 2:  $62 = 'b' → B
                    .WORD CHAR_02     ; Index 3:  $63 = 'c' → C
                    .WORD CHAR_03     ; Index 4:  $64 = 'd' → D
                    .WORD CHAR_04     ; Index 5:  $65 = 'e' → E ✓
                    .WORD CHAR_05     ; Index 6:  $66 = 'f' → F
                    .WORD CHAR_06     ; Index 7:  $67 = 'g' → G ✓
                    .WORD CHAR_07     ; Index 8:  $68 = 'h' → H ✓
                    .WORD CHAR_26     ; Index 9:  $69 = 'i' → I (swapped)
                    .WORD CHAR_25     ; Index 10: $6A = 'j' → J (swapped)
                    .WORD CHAR_09     ; Index 11: $6B = 'k' → K (CHAR_09 was Z in sequence)
                    .WORD CHAR_10     ; Index 12: $6C = 'l' → L ✓
                    .WORD CHAR_11     ; Index 13: $6D = 'm' → M ✓
                    .WORD CHAR_12     ; Index 14: $6E = 'n' → N ✓
                    .WORD CHAR_13     ; Index 15: $6F = 'o' → O
                    .WORD CHAR_14     ; Index 16: $70 = 'p' → P ✓
                    .WORD CHAR_15     ; Index 17: $71 = 'q' → Q ✓
                    .WORD CHAR_16     ; Index 18: $72 = 'r' → R ✓
                    .WORD CHAR_17     ; Index 19: $73 = 's' → S ✓
                    .WORD CHAR_18     ; Index 20: $74 = 't' → T ✓
                    .WORD CHAR_19     ; Index 21: $75 = 'u' → U ✓
                    .WORD CHAR_20     ; Index 22: $76 = 'v' → V
                    .WORD CHAR_21     ; Index 23: $77 = 'w' → W
                    .WORD CHAR_22     ; Index 24: $78 = 'x' → X
                    .WORD CHAR_23     ; Index 25: $79 = 'y' → Y
                    .WORD CHAR_24     ; Index 26: $7A = 'z' → Z
                    .WORD CHAR_27     ; Index 27: $7B → PERIOD
                    .WORD CHAR_28     ; Index 28: $7C → COMMA
                    .WORD CHAR_29     ; Index 29: $7D → COLON
                    .WORD CHAR_30     ; Index 30: $7E → HYPHEN
                    .WORD CHAR_31     ; Index 31: $7F

SPRITE_WIDTH_TABLE  .BYTE $01,$02,$03,$03,$03,$03,$03,$03  ; 0-7 (SPACE=$01, A=$02, F=$03)
                    .BYTE $03,$02,$02,$03,$02,$03,$03,$03  ; 8-15 (I=$02, J=$02, L=$02)
                    .BYTE $03,$03,$03,$02,$03,$03,$03,$03  ; 16-23 (S=$02)
                    .BYTE $03,$03,$03,$01,$01,$01,$01,$01  ; 24-31 (PERIOD=$01, COMMA=$01, COLON=$01, HYPHEN=$01)

;=====================================================
; KARATEKA INTRO TEXT COMMAND LISTS
;=====================================================

                    ;ORG   $2500

CMDLIST_00          .BYTE $0D,$03,$70,$72,$65,$73,$65,$6E,$74,$73,$5F
CMDLIST_01          .BYTE $0E,$00,$61,$60,$67,$61,$6D,$65,$60,$62,$79,$5F
CMDLIST_02          .BYTE $0A,$03,$6A,$6F,$72,$64,$61,$6E,$60,$6D,$65,$63
                    .BYTE $68,$6E,$65,$72,$5F
CMDLIST_PUNCT       .BYTE $00,$00,$7B,$60,$7C,$60,$7D,$60,$7E,$5F  ; Punctuation test: . , : -
CMDLIST_03          .BYTE $00,$00,$68,$69,$67,$68,$60,$61,$74,$6F,$70,$60
                    .BYTE $61,$60,$63,$72,$61,$67,$67,$79,$60,$63,$6C,$69
                    .BYTE $66,$66,$60,$67,$75,$61,$72,$64,$65,$64,$5F
CMDLIST_04          .BYTE $00,$00,$68,$69,$67,$68,$60,$61,$74,$6F,$70,$60
                    .BYTE $61,$60,$63,$72,$61,$67,$67,$79,$60,$63,$6C,$69
                    .BYTE $66,$66,$7C,$60,$67,$75,$61,$72,$64,$65,$64,$5F
CMDLIST_05          .BYTE $00,$00,$62,$79,$60,$61,$6E,$60,$61,$72,$6D,$79
                    .BYTE $60,$6F,$66,$60,$66,$69,$65,$72,$63,$65,$60,$77
                    .BYTE $61,$72,$72,$69,$6F,$72,$73,$7C,$5F
CMDLIST_06          .BYTE $00,$00,$73,$74,$61,$6E,$64,$73,$60,$74,$68,$65
                    .BYTE $60,$66,$6F,$72,$74,$72,$65,$73,$73,$60,$6F,$66
                    .BYTE $60,$74,$68,$65,$60,$65,$76,$69,$6C,$5F
CMDLIST_07          .BYTE $00,$00,$77,$61,$72,$6C,$6F,$72,$64,$60,$61,$6B
                    .BYTE $75,$6D,$61,$7B,$60,$60,$64,$65,$65,$70,$60,$69
                    .BYTE $6E,$60,$74,$68,$65,$5F
CMDLIST_08          .BYTE $00,$00,$64,$61,$72,$6B,$65,$73,$74,$60,$64,$75
                    .BYTE $6E,$67,$65,$6F,$6E,$60,$6F,$66,$60,$74,$68,$65
                    .BYTE $60,$63,$61,$73,$74,$6C,$65,$7C,$5F
CMDLIST_09          .BYTE $00,$00,$61,$6B,$75,$6D,$61,$60,$67,$6C,$6F,$61
                    .BYTE $74,$73,$60,$6F,$76,$65,$72,$60,$68,$69,$73,$60
                    .BYTE $6C,$6F,$76,$65,$6C,$79,$5F
CMDLIST_10          .BYTE $00,$00,$63,$61,$70,$74,$69,$76,$65,$7C,$60,$74
                    .BYTE $68,$65,$60,$70,$72,$69,$6E,$63,$65,$73,$73,$60
                    .BYTE $6D,$61,$72,$69,$6B,$6F,$7B,$5F
CMDLIST_11          .BYTE $00,$00,$5F
CMDLIST_12          .BYTE $00,$00,$79,$6F,$75,$60,$61,$72,$65,$60,$6F,$6E
                    .BYTE $65,$60,$74,$72,$61,$69,$6E,$65,$64,$60,$69,$6E
                    .BYTE $60,$74,$68,$65,$60,$77,$61,$79,$5F
CMDLIST_13          .BYTE $00,$00,$6F,$66,$60,$6B,$61,$72,$61,$74,$65,$7D
                    .BYTE $60,$61,$60,$6B,$61,$72,$61,$74,$65,$6B,$61,$7B
                    .BYTE $60,$60,$61,$6C,$6F,$6E,$65,$60,$61,$6E,$64,$5F
CMDLIST_14          .BYTE $00,$00,$75,$6E,$61,$72,$6D,$65,$64,$7C,$60,$79
                    .BYTE $6F,$75,$60,$6D,$75,$73,$74,$60,$64,$65,$66,$65
                    .BYTE $61,$74,$60,$61,$6B,$75,$6D,$61,$5F
CMDLIST_15          .BYTE $00,$00,$61,$6E,$64,$60,$72,$65,$73,$63,$75,$65
                    .BYTE $60,$74,$68,$65,$60,$62,$65,$61,$75,$74,$69,$66
                    .BYTE $75,$6C,$60,$6D,$61,$72,$69,$6B,$6F,$7B,$5F
CMDLIST_16          .BYTE $00,$00,$5F
CMDLIST_17          .BYTE $00,$00,$70,$75,$74,$60,$66,$65,$61,$72,$60,$61
                    .BYTE $6E,$64,$60,$73,$65,$6C,$66,$7E,$63,$6F,$6E,$63
                    .BYTE $65,$72,$6E,$60,$62,$65,$68,$69,$6E,$64,$5F
CMDLIST_18          .BYTE $00,$00,$79,$6F,$75,$7B,$60,$60,$66,$6F,$63,$75
                    .BYTE $73,$60,$79,$6F,$75,$72,$60,$77,$69,$6C,$6C,$60
                    .BYTE $6F,$6E,$60,$79,$6F,$75,$72,$5F
CMDLIST_19          .BYTE $00,$00,$6F,$62,$6A,$65,$63,$74,$69,$76,$65,$7C
                    .BYTE $60,$61,$63,$63,$65,$70,$74,$69,$6E,$67,$60,$64
                    .BYTE $65,$61,$74,$68,$60,$61,$73,$60,$61,$5F
CMDLIST_20          .BYTE $00,$00,$70,$6F,$73,$73,$69,$62,$69,$6C,$69,$74
                    .BYTE $79,$7B,$60,$60,$74,$68,$69,$73,$60,$69,$73,$60
                    .BYTE $74,$68,$65,$60,$77,$61,$79,$60,$6F,$66,$5F
CMDLIST_21          .BYTE $00,$00,$74,$68,$65,$60,$6B,$61,$72,$61,$74,$65
                    .BYTE $6B,$61,$7B,$5F
CMDLIST_22          .BYTE $0B,$03,$63,$6F,$63,$6F,$60,$70,$6F,$72,$74,$60
                    .BYTE $62,$79,$5F
CMDLIST_23          .BYTE $0E,$03,$6A,$61,$79,$60,$73,$65,$61,$72,$6C,$65
                    .BYTE $5F
CMDLIST_24          .BYTE $11,$03,$73,$69,$6E,$67,$6C,$65,$60,$6C,$69,$6E
                    .BYTE $65,$5F

;=====================================================
; APPLE II CHARACTER FONT DATA
; Convert this data with your Apple II to CoCo3 tool
;=====================================================

                    ;ORG   $0400
CHAR_SPACE          .BYTE $08,$02   ; 8 lines tall, 2 bytes wide (blank)
                    .BYTE $00,$00,$00,$00,$00,$00,$00,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$00,$00

CHAR_00             .BYTE $08,$02,$0F,$00,$03,$C0,$00,$F0,$03,$F0,$3C,$20,$F0,$3C,$F0,$FC
                    .BYTE $3F,$0F

CHAR_01             .BYTE $08,$03,$F3,$FC,$00,$3F,$0F,$00,$3C,$0F,$00,$3F,$FC,$00,$3C,$0F
                    .BYTE $00,$3C,$03,$C0,$3C,$0F,$C0,$3F,$FF,$00

CHAR_02             .BYTE $08,$02,$0F,$F0,$20,$3F,$F0,$04,$F0,$00,$F0,$00,$F0,$0F,$3C,$0F
                    .BYTE $0F,$F0

CHAR_03             .BYTE $09,$02,$02,$00,$0F,$C0,$03,$F0,$04,$FC,$20,$3F,$F0,$0F,$F0,$0F
                    .BYTE $3C,$0F,$0F,$F0

CHAR_04             .BYTE $08,$02,$0F,$FC,$20,$0F,$F0,$00,$FF,$F0,$F0,$00,$F0,$00,$3C,$0F
                    .BYTE $0F,$FC

CHAR_05             .BYTE $0B,$02,$03,$F0,$04,$3C,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00
                    .BYTE $FF,$F0,$3C,$00,$3C,$00,$3C,$00

CHAR_06             .BYTE $0A,$02,$0F,$F0,$20,$3F,$F0,$04,$F0,$00,$F0,$3F,$F0,$0F,$3C,$0F
                    .BYTE $0F,$FF,$00,$0F,$00,$3C

CHAR_07             .BYTE $0A,$03,$FC,$00,$00,$3C,$00,$00,$3C,$00,$00,$3C,$FF,$00,$3F,$03
                    .BYTE $C0,$3C,$03,$C0,$3C,$03,$C0,$3C,$03,$C0,$3C,$0F,$00,$3C,$0F,$C0

CHAR_08             .BYTE $08,$03,$3F,$FF,$F0,$20,$0F,$C0,$00,$3F,$00,$00,$FC,$00,$03,$F0
                    .BYTE $00,$0F,$C0,$00,$3F,$00,$20,$FF,$FF,$F0

CHAR_09             ;.BYTE $B6,$9C,
                    .BYTE $0A,$03,$FC,$00,$00,$3C,$00,$00,$3C,$02,$00,$3C,$04,$00,$3C,$20
                    .BYTE $00,$3C,$40,$00,$3F,$F0,$00,$3C,$3C,$00,$3C,$0F,$00,$3C,$03,$C0

CHAR_10             .BYTE $0A,$02,$FC,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00
                    .BYTE $3C,$00,$3C,$00,$3F,$F0

CHAR_11             .BYTE $08,$04,$FC,$FC,$FC,$00,$3F,$3F,$CF,$00,$3C,$0F,$03,$C0,$3C,$0F
                    .BYTE $03,$C0,$3C,$0F,$03,$C0,$3C,$0F,$03,$C0,$3C,$0F,$0F,$00,$3C,$0F
                    .BYTE $0F,$C0

CHAR_12             .BYTE $08,$03,$FC,$3F,$00,$3F,$C3,$C0,$3C,$03,$C0,$3C,$03,$C0,$3C,$03
                    .BYTE $C0,$3C,$03,$C0,$3C,$0F,$00,$3C,$0F,$C0

CHAR_13             .BYTE $08,$03,$0F,$F0,$00,$20,$3F,$00,$F0,$0F,$C0,$F0,$03,$C0,$F0,$03
                    .BYTE $C0,$FC,$03,$C0,$3F,$02,$00,$03,$FC,$00

CHAR_14             .BYTE $0A,$03,$FC,$FF,$00,$3F,$03,$C0,$3C,$00,$F0,$3C,$00,$F0,$3C,$00
                    .BYTE $F0,$3C,$00,$F0,$3F,$00,$40,$3C,$FF,$00,$3C,$00,$00,$3C,$00,$00

CHAR_15             .BYTE $0A,$03,$0F,$FF,$C0,$20,$0F,$C0,$F0,$03,$C0,$F0,$03,$C0,$F0,$03
                    .BYTE $C0,$F0,$03,$C0,$FC,$0F,$C0,$0F,$F3,$C0,$00,$03,$C0,$00,$03,$C0

CHAR_16             .BYTE $08,$03,$FC,$FF,$00,$3F,$03,$F0,$3C,$00,$F0,$3C,$00,$F0,$3C,$03
                    .BYTE $C0,$3F,$FC,$00,$3C,$3F,$00,$3C,$03,$F0

CHAR_17             .BYTE $08,$02,$0F,$C0,$F0,$F0,$F0,$00,$3F,$00,$0F,$C0,$00,$F0,$F0,$F0
                    .BYTE $3F,$C0

CHAR_18             .BYTE $0A,$03,$00,$80,$00,$03,$C0,$80,$FF,$FF,$C0,$83,$C0,$00,$03,$C0
                    .BYTE $00,$03,$C0,$00,$03,$C0,$00,$03,$C0,$00,$03,$C3,$C0,$00,$FF,$00

CHAR_19             .BYTE $08,$03,$F0,$0F,$00,$F0,$0F,$00,$F0,$0F,$00,$F0,$0F,$00,$F0,$0F
                    .BYTE $00,$F0,$0F,$00,$20,$3F,$C0,$0F,$C2,$00

CHAR_20             .BYTE $08,$03,$FC,$00,$F0,$3C,$00,$40,$0F,$02,$00,$0F,$02,$00,$03,$C4
                    .BYTE $00,$03,$FC,$00,$00,$F0,$00,$00,$F0,$00

CHAR_21             .BYTE $08,$04,$FC,$0F,$C0,$0F,$3C,$03,$C0,$04,$0F,$00,$F0,$20,$0F,$03
                    .BYTE $F0,$20,$03,$C4,$3C,$40,$03,$FC,$3F,$C0,$00,$F0,$0F,$00,$00,$F0
                    .BYTE $0F,$00

CHAR_22             .BYTE $08,$03,$F0,$02,$00,$3C,$04,$00,$0F,$20,$00,$03,$C0,$00,$03,$F0
                    .BYTE $00,$04,$3C,$00,$20,$0F,$00,$40,$03,$C0

CHAR_23             .BYTE $0A,$03,$FC,$00,$F0,$3C,$00,$40,$0F,$02,$00,$0F,$02,$00,$03,$C4
                    .BYTE $00,$03,$FC,$00,$00,$20,$00,$00,$40,$00,$3C,$40,$00,$0F,$00,$00

CHAR_24             .BYTE $08,$01,$FC,$3C,$3C,$3C,$3C,$3C,$3C,$3C

CHAR_25             .BYTE $0A,$02,$3F,$C0,$03,$C0,$03,$C0,$03,$C0,$03,$C0,$03,$C0,$03,$C0
                    .BYTE $03,$C0,$F3,$C0,$3F,$00

CHAR_26             .BYTE $0A,$01,$00,$00,$FC,$3C,$3C,$3C,$3C,$3C,$3C,$3C  ; I: vertical stem (moved down 2 lines)

CHAR_27             .BYTE $08,$01,$00,$00,$00,$00,$00,$00,$F0,$F0  ; Period: 8 lines (6 blank + 2 dot at bottom)

CHAR_28             .BYTE $0A,$01,$00,$00,$00,$00,$00,$00,$F0,$F0,$20,$40  ; Comma: 10 lines (6 blank + 4 dot+tail)

CHAR_29             .BYTE $05,$01,$F0,$F0,$00,$F0,$F0  ; Colon: 5 lines tall (two dots separated)

CHAR_30             .BYTE $01,$01,$FF  ; Hyphen: 1 line tall, 1 byte wide (horizontal line)

CHAR_31             ;.BYTE $E6,$F2,$08,$1E,$34,$4E,$68,$7E,$94
                    ;.BYTE $AA,$C0,$D6,$00

;=====================================================
; SPRITE DATA - All Configuration Sprites
;=====================================================

                    ;ORG   $2800

; SPRITE_TBBEC - 37 bytes x 5 lines (already have this)
SPRITE_TBBEC        .BYTE $25,$09,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$04,$44,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$44,$44,$40,$00,$00,$00,$00,$00,$04,$44
                    .BYTE $44,$40,$00,$00,$00,$00,$00,$00,$04,$44,$40,$00,$00,$00,$00,$00
                    .BYTE $00,$04,$44,$44,$00,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$44,$44,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$44,$44,$40,$00,$00,$00,$00,$00,$00,$04
                    .BYTE $44,$40,$00,$00,$00,$00,$00,$00,$04,$44,$40,$00,$00,$00,$00,$00
                    .BYTE $00,$04,$44,$40,$00,$00,$00,$00,$00,$00,$04,$44,$44,$00,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$44,$44,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$44
                    .BYTE $44,$40,$00,$00,$00,$00,$00,$04,$44,$44,$40,$00,$00,$00,$00,$00
                    .BYTE $44,$04,$44,$40,$00,$00,$00,$00,$04,$40,$04,$44,$40,$00,$00,$00
                    .BYTE $00,$44,$00,$04,$44,$44,$00,$00,$00,$04,$40,$00,$00,$44,$44,$00
                    .BYTE $00,$00,$04,$40,$00,$00,$44,$44,$00,$00,$00,$44,$00,$00,$00,$44
                    .BYTE $44,$40,$00,$00,$44,$00,$00,$00,$04,$44,$40,$00,$04,$44,$00,$00
                    .BYTE $00,$04,$44,$40,$00,$04,$44,$00,$00,$00,$04,$44,$44,$00,$04,$44
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$04,$44,$00,$00,$00,$04,$44,$44,$00
                    .BYTE $04,$44,$40,$00,$00,$04,$44,$44,$40,$04,$44,$40,$00,$00,$44,$04
                    .BYTE $44,$40,$00,$44,$40,$00,$00,$40,$04,$44,$40,$40,$44,$44,$00,$04
                    .BYTE $40,$04,$44,$44,$00,$44,$44,$44,$44,$00,$00,$44,$40,$00,$04,$44
                    .BYTE $44,$40,$00,$00,$44,$00,$00,$00,$44,$44,$00,$00,$00,$40,$00

; SPRITE_BCA7 - 36 bytes x 5 lines
SPRITE_BCA7         .BYTE $24,$08,$44,$44,$00,$00,$00,$00,$44,$40,$44,$44,$00,$00,$00,$00
                    .BYTE $44,$00,$44,$44,$00,$00,$00,$00,$44,$00,$44,$44,$00,$00,$00,$04
                    .BYTE $40,$00,$44,$44,$00,$00,$00,$04,$40,$00,$44,$44,$00,$00,$00,$04
                    .BYTE $00,$00,$44,$44,$00,$00,$00,$44,$00,$00,$44,$44,$00,$00,$00,$40
                    .BYTE $00,$00,$44,$44,$00,$00,$04,$40,$00,$00,$44,$44,$00,$00,$04,$00
                    .BYTE $00,$00,$44,$44,$00,$00,$44,$00,$00,$00,$44,$44,$00,$00,$40,$00
                    .BYTE $00,$00,$44,$44,$00,$04,$40,$00,$00,$00,$44,$44,$00,$04,$00,$00
                    .BYTE $00,$00,$44,$44,$00,$44,$00,$00,$00,$00,$44,$44,$00,$40,$00,$00
                    .BYTE $00,$00,$44,$44,$04,$40,$00,$00,$00,$00,$44,$44,$04,$40,$00,$00
                    .BYTE $00,$00,$44,$44,$44,$44,$00,$00,$00,$00,$44,$44,$44,$44,$00,$00
                    .BYTE $00,$00,$44,$44,$44,$44,$40,$00,$00,$00,$44,$44,$04,$44,$40,$00
                    .BYTE $00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$44,$44,$00,$44,$44,$00
                    .BYTE $00,$00,$44,$44,$00,$04,$44,$40,$00,$00,$44,$44,$00,$04,$44,$40
                    .BYTE $00,$00,$44,$44,$00,$00,$44,$44,$00,$00,$44,$44,$00,$00,$44,$44
                    .BYTE $00,$00,$44,$44,$00,$00,$04,$44,$40,$00,$44,$44,$00,$00,$04,$44
                    .BYTE $40,$00,$44,$44,$00,$00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$44
                    .BYTE $44,$40,$44,$44,$00,$00,$00,$04,$44,$40,$44,$40,$00,$00,$00,$04
                    .BYTE $44,$40,$44,$00,$00,$00,$00,$00,$44,$00,$40,$00,$00,$00,$00,$00
                    .BYTE $40,$00

; SPRITE_BD5D - 11 bytes x 2 lines
SPRITE_BD5D         .BYTE $0B,$03,$00,$04,$00,$00,$44,$40,$04,$44,$44,$44,$44,$44,$04,$44
                    .BYTE $44,$00,$44,$44,$00,$44,$44,$00,$44,$44,$00,$44,$44,$00,$44,$44
                    .BYTE $00,$44,$44

; SPRITE_BD75 - 41 bytes x 5 lines
SPRITE_BD75         .BYTE $29,$08,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$04,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $04,$40,$44,$44,$44,$44,$44,$44,$44,$00,$44,$44,$44,$44,$44,$44
                    .BYTE $40,$00,$44,$00,$44,$44,$00,$00,$00,$00,$40,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$04,$00,$00,$00,$44,$44,$00,$00
                    .BYTE $04,$40,$00,$00,$44,$44,$00,$00,$04,$44,$00,$00,$44,$44,$00,$00
                    .BYTE $04,$40,$00,$00,$44,$44,$00,$00,$44,$40,$00,$00,$44,$44,$00,$00
                    .BYTE $44,$40,$00,$00,$44,$44,$00,$00,$44,$00,$00,$00,$04,$44,$40,$04
                    .BYTE $44,$00,$00,$00,$00,$44,$40,$04,$40,$00,$00,$00,$00,$04,$44,$44
                    .BYTE $00,$00,$00,$00,$00,$00,$44,$40,$00,$00

; SPRITE_BE44 - 37 bytes x 6 lines
SPRITE_BE44         .BYTE $25,$0A,$00,$00,$00,$00,$44,$44,$44,$40,$00,$00,$00,$00,$00,$44
                    .BYTE $44,$44,$44,$44,$00,$00,$00,$00,$04,$44,$00,$00,$44,$44,$40,$00
                    .BYTE $00,$00,$44,$40,$00,$00,$04,$44,$44,$00,$00,$04,$44,$00,$00,$00
                    .BYTE $00,$44,$44,$40,$00,$04,$44,$00,$00,$00,$00,$44,$44,$00,$00,$44
                    .BYTE $40,$00,$00,$00,$00,$04,$40,$00,$00,$44,$40,$00,$00,$00,$00,$04
                    .BYTE $00,$00,$00,$44,$40,$00,$00,$00,$00,$00,$00,$00,$04,$44,$00,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$04,$44,$00,$00,$00,$00,$00,$00,$00,$00
                    .BYTE $04,$44,$00,$00,$00,$00,$00,$00,$00,$00,$04,$44,$00,$00,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$00,$44,$44
                    .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$04,$40
                    .BYTE $00,$00,$44,$44,$44,$44,$44,$44,$44,$00,$00,$00,$44,$44,$44,$44
                    .BYTE $44,$44,$40,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$00
                    .BYTE $44,$44,$00,$00,$00,$00,$00,$00,$00,$00,$44,$44,$00,$00,$00,$00
                    .BYTE $00,$00,$00,$00,$44,$44,$00,$00,$00,$00,$00,$00,$00,$00,$04,$44
                    .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$04,$44,$40,$00,$00,$00,$00,$00
                    .BYTE $00,$00,$04,$44,$40,$00,$00,$00,$00,$00,$00,$00,$04,$44,$40,$00
                    .BYTE $00,$00,$00,$00,$00,$00,$00,$44,$40,$00,$00,$00,$00,$00,$40,$00
                    .BYTE $00,$44,$44,$00,$00,$00,$00,$00,$44,$00,$00,$44,$44,$00,$00,$00
                    .BYTE $00,$00,$44,$40,$00,$04,$44,$00,$00,$00,$00,$00,$44,$00,$00,$04
                    .BYTE $44,$40,$00,$00,$00,$04,$44,$00,$00,$00,$44,$40,$00,$00,$00,$04
                    .BYTE $44,$00,$00,$00,$44,$44,$00,$00,$00,$04,$40,$00,$00,$00,$04,$44
                    .BYTE $40,$00,$00,$44,$40,$00,$00,$00,$00,$44,$44,$00,$00,$44,$00,$00
                    .BYTE $00,$00,$00,$04,$44,$44,$44,$40,$00,$00,$00,$00,$00,$00,$04,$44
                    .BYTE $44,$00,$00,$00

; SPRITE_BF24 - 38 bytes x 5 lines
SPRITE_BF24         .BYTE $26,$09,$00,$04,$00,$00,$04,$44,$40,$00,$00,$00,$44,$40,$00,$44
                    .BYTE $44,$44,$00,$00,$04,$44,$44,$04,$44,$44,$44,$40,$00,$44,$44,$44
                    .BYTE $44,$00,$44,$44,$44,$00,$04,$44,$44,$40,$00,$00,$44,$44,$00,$00
                    .BYTE $44,$44,$00,$00,$00,$44,$44,$40,$00,$44,$44,$00,$00,$00,$04,$44
                    .BYTE $40,$00,$44,$44,$00,$00,$00,$04,$44,$40,$00,$44,$44,$00,$00,$00
                    .BYTE $04,$44,$44,$00,$44,$44,$00,$00,$00,$00,$44,$44,$00,$44,$44,$00
                    .BYTE $00,$00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$00,$44,$44,$00,$44
                    .BYTE $44,$00,$00,$00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$00,$44,$44
                    .BYTE $00,$44,$44,$00,$00,$00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$00
                    .BYTE $44,$44,$00,$44,$44,$00,$00,$00,$00,$44,$44,$00,$44,$44,$00,$00
                    .BYTE $00,$00,$44,$44,$00,$44,$44,$00,$00,$00,$00,$44,$44,$00,$44,$44
                    .BYTE $00,$00,$00,$00,$44,$40,$00,$44,$44,$00,$00,$00,$00,$44,$40,$00
                    .BYTE $44,$44,$00,$00,$00,$00,$44,$40,$00,$44,$44,$00,$00,$00,$04,$44
                    .BYTE $40,$00,$44,$44,$00,$00,$00,$04,$44,$00,$00,$44,$44,$00,$00,$00
                    .BYTE $04,$40,$00,$00,$44,$44,$00,$00,$00,$44,$00,$00,$00,$44,$44,$00
                    .BYTE $00,$44,$40,$00,$00,$00,$44,$44,$44,$44,$40,$00,$00,$00,$00,$44
                    .BYTE $44,$44,$44,$44,$00,$00,$00,$00,$44,$44,$04,$44,$44,$40,$00,$00
                    .BYTE $00,$44,$44,$00,$44,$44,$44,$00,$00,$00,$44,$44,$00,$04,$44,$44
                    .BYTE $40,$00,$00,$44,$44,$00,$00,$44,$44,$44,$00,$00,$44,$44,$00,$00
                    .BYTE $04,$44,$44,$40,$00,$44,$44,$00,$00,$00,$44,$44,$44,$00,$44,$44
                    .BYTE $00,$00,$00,$04,$44,$44,$00,$44,$40,$00,$00,$00,$00,$44,$44,$00
                    .BYTE $44,$00,$00,$00,$00,$00,$04,$44

; SPRITE_BFE4 - 2 bytes (truncated in dump)
SPRITE_BFE4         .BYTE $02,$01,$44,$40

                    END START