@echo off
REM build.bat - Build production binary + all test drivers (native Windows).
REM Requires: lwasm.exe (LWTOOLS) on PATH. No WSL, no make.
REM NOTE: lwasm derives the `include` base dir by splitting the source path on
REM '/', so source args MUST use forward slashes (not backslashes) or relative
REM includes like ../../content/... resolve against the CWD and fail.
setlocal

for %%I in ("%~dp0.") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

REM ======================================================================
REM PRE-BUILD: HAL-SYNC BRIDGE (P2.4 Phase B) — the ONLY karateka change in P2.4.
REM
REM karateka still builds ABSOLUTE and is unaffected by POP's conversion: the
REM `ifdef OBJTARGET` guards in the shared HAL source are OFF here, and this
REM binary is byte-identical to what it built before them. What IS shared is the
REM HAL source itself, which now exists as two copies (POP linked, karateka
REM absolute) until the kernel becomes a single source. Two copies drift.
REM
REM So the check runs HERE, on every build, before anything is assembled, and
REM FAILS the build on substantive drift. A sync script that merely exists
REM enforces nothing. If POP is genuinely absent the check WARNS and the build
REM proceeds — a check that blocks legitimate builds gets deleted, and then it
REM enforces nothing either.
REM
REM TEMPORARY BY DESIGN: this block and harness\tools\hal_sync_check.py both
REM delete cleanly when karateka converts to linked and the kernel is one source.
REM ======================================================================
where python >nul 2>&1
if errorlevel 1 (
    echo [hal-sync] WARNING: python not found on PATH — HAL-sync check SKIPPED.
) else (
    python harness\tools\hal_sync_check.py
    if errorlevel 1 (
        echo *** BUILD BLOCKED BY HAL DRIFT — see [hal-sync] above ***
        exit /b 1
    )
)

where lwasm >nul 2>&1
if errorlevel 1 (
    echo ERROR: lwasm.exe not found on PATH.
    echo Install LWTOOLS ^(lwasm^) and add it to your PATH, then re-run.
    exit /b 1
)

if not exist build mkdir build

echo --- Production binary ---
lwasm --decb -o build/karateka.bin ^
    src/engine/boot.s src/engine/globals.s src/engine/kernel_dispatch.s ^
    src/engine/kernel_per_frame.s src/engine/timer_framesync.s ^
    src/engine/broderbund_scene.s src/engine/intro_scenes.s src/engine/scene4_scroll.s ^
    src/hal/coco3-dsk/sys.s src/hal/coco3-dsk/irq_vbl.s src/hal/coco3-dsk/gfx.s ^
    src/hal/coco3-dsk/time.s src/hal/coco3-dsk/input.s src/hal/coco3-dsk/sound.s ^
    src/hal/coco3-dsk/file.s tests/scripted/scene5_e2e_driver.s src/hal/coco3-dsk/mem.s ^
    src/engine/entry.s
if errorlevel 1 goto :error
call :size build/karateka.bin

echo --- Test drivers ---
rem --- §2F: regenerate the single-home scene-6 placement table (plc_ + climb cl_frames) from its
rem     text-source BEFORE any driver that includes it (crawl drivers + scrollA). No drift. ---
python harness\tools\gen_scene6_placement.py
if errorlevel 1 goto :error
rem --- build-render: codegen the authored-shadow opacity descriptors (read opacity.s sidecars on
rem     disk) for the climb draw path, BEFORE the crawl driver includes scene6_climb_opacity_gen.s ---
python harness\tools\gen_climb_opacity.py
if errorlevel 1 goto :error

lwasm --decb -o tests/scripted/sys_init_driver.bin tests/scripted/sys_init_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/sys_init_driver.bin

lwasm --decb -o tests/scripted/gfx_init_driver.bin tests/scripted/gfx_init_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/gfx_init_driver.bin

lwasm --decb -o tests/scripted/visual_smoke_driver.bin tests/scripted/visual_smoke_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/visual_smoke_driver.bin

lwasm --decb -o tests/scripted/scene6_stage1_driver.bin tests/scripted/scene6_stage1_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_stage1_driver.bin

lwasm --decb -o tests/scripted/scene6_climb_crawl_driver.bin tests/scripted/scene6_climb_crawl_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_climb_crawl_driver.bin

lwasm --decb -o tests/scripted/scene6_stage2_driver.bin tests/scripted/scene6_stage2_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_stage2_driver.bin

lwasm --decb -o tests/scripted/scene6_stage3_driver.bin tests/scripted/scene6_stage3_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_stage3_driver.bin

lwasm --decb -o tests/scripted/scene6_walk_scrollA_driver.bin tests/scripted/scene6_walk_scrollA_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_walk_scrollA_driver.bin

echo --- Stage B2' core scroll (scroll + run + guard, actors on phase 14) ---
lwasm --decb -o tests/scripted/scene6_b2prime_driver.bin tests/scripted/scene6_b2prime_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene6_b2prime_driver.bin

lwasm --decb -I src/engine -I src/hal/coco3-dsk -o tests/scripted/timer_framesync_driver.bin tests/scripted/timer_framesync_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/timer_framesync_driver.bin

lwasm --decb -o tests/scripted/kernel_dispatch_driver.bin tests/scripted/kernel_dispatch_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/kernel_dispatch_driver.bin

lwasm --decb -o tests/scripted/broderbund_splash_driver.bin tests/scripted/broderbund_splash_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/broderbund_splash_driver.bin

lwasm --decb -o tests/scripted/presents_test_driver.bin tests/scripted/presents_test_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/presents_test_driver.bin

lwasm --decb -o tests/scripted/sub_byte_shifter_test_driver.bin tests/scripted/sub_byte_shifter_test_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/sub_byte_shifter_test_driver.bin

lwasm --decb -o tests/scripted/broderbund_presents_scene_driver.bin tests/scripted/broderbund_presents_scene_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/broderbund_presents_scene_driver.bin

lwasm --decb -o tests/scripted/vbl_irq_test_driver.bin tests/scripted/vbl_irq_test_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/vbl_irq_test_driver.bin

lwasm --decb -o tests/scripted/scene5_akuma_ctrl.bin tests/scripted/scene5_akuma_ctrl_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene5_akuma_ctrl.bin

lwasm --decb -D SCENE5_STANDALONE -o tests/scripted/scene5_e2e.bin tests/scripted/scene5_e2e_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/scene5_e2e.bin

lwasm --decb -I src/hal/coco3-dsk -o tests/scripted/disk_sandbox.bin tests/scripted/disk_sandbox_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/disk_sandbox.bin

lwasm --decb -D READJUMP -I src/hal/coco3-dsk -o tests/scripted/disk_sandbox_rj.bin tests/scripted/disk_sandbox_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/disk_sandbox_rj.bin

lwasm --decb -D FULLIMAGE -I src/hal/coco3-dsk -o tests/scripted/disk_sandbox_fi.bin tests/scripted/disk_sandbox_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/disk_sandbox_fi.bin

lwasm --decb -D WORSTCASE -I src/hal/coco3-dsk -o tests/scripted/disk_sandbox_wc.bin tests/scripted/disk_sandbox_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/disk_sandbox_wc.bin

REM BUILD #3b-2 boot loader (framebuffer-resident; DR_VARBASE relocates primitive vars clear of the $0100 game load)
lwasm --decb -D DR_VARBASE=$BF00 -I src/hal/coco3-dsk -o tests/scripted/bootloader.bin src/boot/bootloader.s
if errorlevel 1 goto :error
call :size tests/scripted/bootloader.bin

echo === BUILD COMPLETE ===
exit /b 0

:size
for %%I in ("%~1") do echo   %~1 (%%~zI bytes)
exit /b 0

:error
echo *** BUILD FAILED ***
exit /b 1
