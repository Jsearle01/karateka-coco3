* src/engine/entry.s
*
* Program entry declaration for the karateka-coco3 production binary.
*
* WHY THIS FILE EXISTS (HAL-sync flag 2):
* `end boot` previously sat at the bottom of src/hal/coco3-dsk/mem.s — a build
* directive naming the ENGINE's entry symbol, inside a HAL module. Two concrete
* costs: the HAL could not be assembled in any project that lacks a `boot` symbol
* (demonstrated when POP adopted the HAL — `Undefined symbol boot`), and mem.s was
* pinned to the end of the build list purely because of it.
*
* This file carries the directive instead. It must be listed LAST in the lwasm
* invocation, which is a property of the ENTRY declaration, not of the HAL.
*
* `boot` is defined in src/engine/boot.s; DECB exec address = $0200.
* ---------------------------------------------------------------

        end     boot                    ; DECB exec address = $0200 (boot in boot.s)
