@echo off
REM run_presents_test.bat — P2.3a.11 "presents" text test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.3a.11 Presents Text Test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/presents_test_driver.bin ^
    tests/scripted/presents_test_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\presents_test_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\dumps" mkdir "%CAPTURE_DIR%\dumps"
copy /Y "%REPO_ROOT%\tests\scripted\presents_test_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\presents_test.lua"        "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"          "%CAPTURE_DIR%\tools\lib\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3 - real speed for visual observation) ---
echo Jay: watch the MAME window.
echo   'presents' text should appear at approximately row 110.
echo   Eight letters: p-r-e-s-e-n-t-s
echo   Byte columns:  30,33,35,38,40,42,44,47
echo   Colors: white letter strokes with chromatic fringing on black background.
echo MAME will run for ~35 seconds total (5s BASIC boot + 30s observation).
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 35 ^
    -autoboot_script tools\presents_test.lua >"%REPO_ROOT%\build\presents_test_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\presents_test.log" copy /Y "%CAPTURE_DIR%\tools\presents_test.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\dumps\presents_shot*.bin") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\build\" >nul
        echo   collected %%~nxF
    )
)

if exist "%REPO_ROOT%\build\presents_test.log" (
    echo === presents_test.log ===
    type "%REPO_ROOT%\build\presents_test.log"
)

dir /b "%REPO_ROOT%\build\presents_shot*_frameA.bin" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo === Framebuffer decode ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\presents_shot001_frameA.bin"
    echo.
    echo === Region: expected glyph area (rows 110-121, cols 30-51) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\presents_shot001_frameA.bin" --region 110,30,121,51
)

echo.
echo === P2.3a.11 Presents Test COMPLETE ===
echo Framebuffer dump: build\presents_shot001_frameA.bin
echo Expected: 8 glyphs (p-r-e-s-e-n-t-s) at row 110, byte cols 30-47
