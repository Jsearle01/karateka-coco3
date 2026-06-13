@echo off
REM run_sprite_engine_sandbox.bat — R-engine sandbox runner (Windows native).
REM Builds the sandbox by LINKING THE REAL ENGINE + REAL HAL (single source).
REM boot.s is NOT in this build (AC-5: sandbox is boot-excluded).
REM
REM Automated pass: -nothrottle; P2 static snapshot + P3 memory trace
REM   (eng_idx/page_register cadence + flip; reliable from memory).
REM Live P4 gate: re-run the STAGED bin WITH throttle (real-time) —
REM   see the command printed at the end; Jay observes + single-steps.
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-engine sprite/animation sandbox ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE (real engine + real HAL, single-file include build) ---
lwasm --decb -o tests/scripted/sprite_engine_trace.bin tests/scripted/sprite_engine_trace_driver.s
if errorlevel 1 ( echo TRACE ASSEMBLE FAILED & exit /b 1 )
lwasm --decb -o tests/scripted/sprite_engine_sandbox.bin tests/scripted/sprite_engine_sandbox_driver.s
if errorlevel 1 ( echo SANDBOX ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\sprite_engine_sandbox.bin") do echo ASSEMBLE: PASS (sandbox %%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
copy /Y "%REPO_ROOT%\tests\scripted\sprite_engine_trace.bin"        "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\sprite_engine_sandbox.bin"      "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\sprite_engine_sandbox.lua"      "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\sprite_engine_sandbox_live.lua" "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\sprite_engine_sandbox.log" del /f /q "%CAPTURE_DIR%\tools\sprite_engine_sandbox.log"
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3, -nothrottle: automated P2/P3 trace) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 14 ^
    -autoboot_script tools\sprite_engine_sandbox.lua >"%REPO_ROOT%\build\sprite_engine_sandbox_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\sprite_engine_sandbox.log" copy /Y "%CAPTURE_DIR%\tools\sprite_engine_sandbox.log" "%REPO_ROOT%\build\" >nul
if exist "%REPO_ROOT%\build\sprite_engine_sandbox.log" (
    echo === sprite_engine_sandbox.log ===
    type "%REPO_ROOT%\build\sprite_engine_sandbox.log"
)

echo.
echo === LIVE P4 GATE ^(Jay, real-time^) ===
echo Run interactively to watch the animation + single-step ^(tap any key^):
echo   cd /d C:\karateka-capture
echo   C:\mame\mame.exe coco3 -rompath C:\mame\roms -window -autoboot_script tools\sprite_engine_sandbox_live.lua
echo   ^(No -nothrottle = real 60fps. Close the MAME window when done.^)
echo === R-engine sandbox COMPLETE ===
