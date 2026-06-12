@echo off
REM run_gfx_init_precheck.bat — P2.3a pre-binary BASIC-state validation (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.3a pre-binary BASIC-state validation ===
cd /d "%REPO_ROOT%"

echo --- STAGE ---
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
copy /Y "%REPO_ROOT%\tests\scripted\gfx_init_precheck.lua" "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\gfxprecheck_PASS" del /f /q "%CAPTURE_DIR%\tools\gfxprecheck_PASS"
if exist "%CAPTURE_DIR%\tools\gfxprecheck_FAIL" del /f /q "%CAPTURE_DIR%\tools\gfxprecheck_FAIL"
echo STAGE: gfx_init_precheck.lua staged

echo --- RUN (MAME CoCo3, no binary) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 40 ^
    -autoboot_script tools\gfx_init_precheck.lua >"%REPO_ROOT%\build\gfxprecheck_mame.log" 2>&1
popd

echo --- COLLECT ---
if exist "%CAPTURE_DIR%\tools\gfxprecheck.log" copy /Y "%CAPTURE_DIR%\tools\gfxprecheck.log" "%REPO_ROOT%\build\" >nul

if exist "%CAPTURE_DIR%\tools\gfxprecheck_PASS" (
    echo PRE-CHECK: PASS
    if exist "%REPO_ROOT%\build\gfxprecheck.log" (
        findstr /C:"RESULT" /C:"BASIC-ready" /C:"FFA" /C:"FF91" /C:"FF90" "%REPO_ROOT%\build\gfxprecheck.log" 2>nul
    )
    echo.
    echo === P2.3a PRE-CHECK DONE ===
    exit /b 0
)

if exist "%CAPTURE_DIR%\tools\gfxprecheck_FAIL" (
    echo PRE-CHECK: FAIL
    if exist "%REPO_ROOT%\build\gfxprecheck.log" type "%REPO_ROOT%\build\gfxprecheck.log"
    exit /b 1
)

echo PRE-CHECK: NO RESULT
powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\gfxprecheck_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
exit /b 1
