@echo off
REM run_prod_boot_visual.bat — R-boot visual verification run (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-boot visual verification run ===
powershell -NoProfile -Command "Write-Host ('Timestamp : ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
echo Binary    : build\karateka.bin
echo Throttle  : NORMAL (60 Hz real-time)
echo Duration  : 30 seconds
echo.
echo Jay: watch the MAME window.
echo   ~0-2.7 sec: Broderbund splash (logos + 'presents')
echo   ~2.7-4.0 sec: blank screen
echo   ~4.0 sec+: halted (blank)
echo.

cd /d "%REPO_ROOT%"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\build\karateka.bin"                              "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\prod_boot_loader_minimal.lua"     "%CAPTURE_DIR%\tools\" >nul

for %%I in ("%REPO_ROOT%\build\karateka.bin") do echo Staged karateka.bin (%%~zI bytes)
echo Running MAME...
echo.

if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 30 ^
    -autoboot_script tools\prod_boot_loader_minimal.lua >"%REPO_ROOT%\build\visual_run.log" 2>&1
popd

echo MAME run complete.
echo.
echo Console output:
powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\visual_run.log' -TotalCount 20 -ErrorAction SilentlyContinue"
echo.
echo === Visual run done. Jay: report what you observed. ===
