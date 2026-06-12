@echo off
REM run_prod_boot_test.bat — R-boot production boot integration test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-boot production boot integration test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: BUILD ---
lwasm --decb -o build/karateka.bin ^
    src/engine/boot.s src/engine/globals.s src/engine/kernel_dispatch.s ^
    src/engine/kernel_per_frame.s src/engine/timer_framesync.s ^
    src/engine/broderbund_scene.s ^
    src/hal/coco3-dsk/sys.s src/hal/coco3-dsk/irq_vbl.s src/hal/coco3-dsk/gfx.s ^
    src/hal/coco3-dsk/time.s src/hal/coco3-dsk/input.s src/hal/coco3-dsk/sound.s ^
    src/hal/coco3-dsk/file.s src/hal/coco3-dsk/mem.s
if errorlevel 1 ( echo BUILD FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\build\karateka.bin") do echo BUILD: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\build\karateka.bin"              "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\prod_boot_test.lua" "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\prod_boot_test.log" del /f /q "%CAPTURE_DIR%\tools\prod_boot_test.log"
echo STAGE: karateka.bin + Lua script staged

echo --- Step 3: RUN (MAME CoCo3) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 18 ^
    -autoboot_script tools\prod_boot_test.lua >"%REPO_ROOT%\build\prod_boot_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\prod_boot_test.log" copy /Y "%CAPTURE_DIR%\tools\prod_boot_test.log" "%REPO_ROOT%\build\" >nul

if exist "%REPO_ROOT%\build\prod_boot_test.log" (
    findstr /C:"PASS" /C:"FAIL" /C:"counter-rate" /C:"SCREENSHOT" /C:"page_register" /C:"elapsed" "%REPO_ROOT%\build\prod_boot_test.log" 2>nul
    echo === R-boot MAME TEST COMPLETE ===
) else (
    echo NO RESULT (check build\prod_boot_mame.log)
    powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\prod_boot_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
    exit /b 1
)
