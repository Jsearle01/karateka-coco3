@echo off
REM run_visual_smoke_test.bat — P2.3a.5 visual smoke test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.3a.5 Visual Smoke Test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/visual_smoke_driver.bin ^
    tests/scripted/visual_smoke_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\visual_smoke_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
copy /Y "%REPO_ROOT%\tests\scripted\visual_smoke_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\visual_smoke_test.lua"   "%CAPTURE_DIR%\tools\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3 - REAL SPEED for visual observation) ---
echo Jay: watch the MAME window for alternating white squares.
echo MAME will run for ~25 seconds total (5s BASIC boot + 20s observation).
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 10 ^
    -autoboot_script tools\visual_smoke_test.lua >"%REPO_ROOT%\build\smoketest_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\smoketest.log" copy /Y "%CAPTURE_DIR%\tools\smoketest.log" "%REPO_ROOT%\build\" >nul

if exist "%REPO_ROOT%\build\smoketest.log" (
    echo === smoketest.log ===
    type "%REPO_ROOT%\build\smoketest.log"
)

echo.
echo === P2.3a.5 Visual Smoke Test COMPLETE ===
echo Review smoketest.log and MAME screenshots in snap\coco3\
