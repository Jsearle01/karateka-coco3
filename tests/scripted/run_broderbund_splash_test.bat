@echo off
REM run_broderbund_splash_test.bat — P2.3a.6 Broderbund splash test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.3a.6 Broderbund Splash Test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/broderbund_splash_driver.bin ^
    tests/scripted/broderbund_splash_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\broderbund_splash_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\dumps" mkdir "%CAPTURE_DIR%\dumps"
copy /Y "%REPO_ROOT%\tests\scripted\broderbund_splash_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\broderbund_splash_test.lua"   "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"              "%CAPTURE_DIR%\tools\lib\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3 - real speed for visual observation) ---
echo Jay: watch the MAME window.
echo   Broderbund logo (two elements) should appear on black screen.
echo   Logo 2 (wider, 'Broderbund' text): row 88, byte col 26
echo   Logo 1 (narrower, 'B' mark):      row 72, byte col 35
echo   Colors: orange, blue, white pixels on black background.
echo MAME will run for ~35 seconds total (5s BASIC boot + 30s observation).
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 10 ^
    -autoboot_script tools\broderbund_splash_test.lua >"%REPO_ROOT%\build\broderbund_splash_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\broderbund_splash_test.log" copy /Y "%CAPTURE_DIR%\tools\broderbund_splash_test.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\dumps\broderbund_splash_shot*.bin") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\build\" >nul
        echo   collected %%~nxF
    )
)

if exist "%REPO_ROOT%\build\broderbund_splash_test.log" (
    echo === broderbund_splash_test.log ===
    type "%REPO_ROOT%\build\broderbund_splash_test.log"
)

dir /b "%REPO_ROOT%\build\broderbund_splash_shot*_frameA.bin" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo === Framebuffer decode ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\broderbund_splash_shot001_frameA.bin"
)

echo.
echo === P2.3a.6 Broderbund Splash Test COMPLETE ===
echo Review MAME screenshots in snap\coco3\ and verify V1-V4 predictions.
echo Framebuffer dump: build\broderbund_splash_shot001_frameA.bin
