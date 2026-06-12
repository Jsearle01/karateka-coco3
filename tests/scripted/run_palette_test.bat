@echo off
REM run_palette_test.bat — Palette diagnostic runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === Palette Diagnostic Test (4-band) ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/palette_test_driver.bin ^
    tests/scripted/palette_test_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\palette_test_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\dumps" mkdir "%CAPTURE_DIR%\dumps"
copy /Y "%REPO_ROOT%\tests\scripted\palette_test_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\palette_test.lua"        "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"         "%CAPTURE_DIR%\tools\lib\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3 - real speed) ---
echo Jay: observe 4 horizontal bands on screen.
echo   Band 0 (top quarter):    index 0 = $FFB0=$00 = expected BLACK
echo   Band 1 (2nd quarter):    index 1 = $FFB1=$26 = expected ORANGE
echo   Band 2 (3rd quarter):    index 2 = $FFB2=$1B = expected BLUE
echo   Band 3 (bottom quarter): index 3 = $FFB3=$3F = expected WHITE
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 35 ^
    -autoboot_script tools\palette_test.lua >"%REPO_ROOT%\build\palette_test_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\palette_test.log" copy /Y "%CAPTURE_DIR%\tools\palette_test.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\dumps\palette_test_shot*.bin") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\build\" >nul
        echo   collected %%~nxF
    )
)

if exist "%REPO_ROOT%\build\palette_test.log" type "%REPO_ROOT%\build\palette_test.log"

dir /b "%REPO_ROOT%\build\palette_test_shot*_frameA.bin" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo === Framebuffer decode ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\palette_test_shot001_frameA.bin"
)

echo === Palette Diagnostic Test COMPLETE ===
echo Framebuffer dump: build\palette_test_shot001_frameA.bin
echo   Expected: Band 0 rows 0-47 all idx-0; Band 1 rows 48-95 all idx-1;
echo             Band 2 rows 96-143 all idx-2; Band 3 rows 144-191 all idx-3
