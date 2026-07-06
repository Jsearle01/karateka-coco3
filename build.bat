@echo off
REM build.bat - Build production binary + all test drivers (native Windows).
REM Requires: lwasm.exe (LWTOOLS) on PATH. No WSL, no make.
REM NOTE: lwasm derives the `include` base dir by splitting the source path on
REM '/', so source args MUST use forward slashes (not backslashes) or relative
REM includes like ../../content/... resolve against the CWD and fail.
setlocal

for %%I in ("%~dp0.") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

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
    src/hal/coco3-dsk/file.s tests/scripted/scene5_e2e_driver.s src/hal/coco3-dsk/mem.s
if errorlevel 1 goto :error
call :size build/karateka.bin

echo --- Test drivers ---
lwasm --decb -o tests/scripted/sys_init_driver.bin tests/scripted/sys_init_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/sys_init_driver.bin

lwasm --decb -o tests/scripted/gfx_init_driver.bin tests/scripted/gfx_init_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/gfx_init_driver.bin

lwasm --decb -o tests/scripted/visual_smoke_driver.bin tests/scripted/visual_smoke_driver.s
if errorlevel 1 goto :error
call :size tests/scripted/visual_smoke_driver.bin

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

echo === BUILD COMPLETE ===
exit /b 0

:size
for %%I in ("%~1") do echo   %~1 (%%~zI bytes)
exit /b 0

:error
echo *** BUILD FAILED ***
exit /b 1
