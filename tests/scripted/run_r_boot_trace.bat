@echo off
REM run_r_boot_trace.bat — R-boot execution trace run (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-boot execution trace ===
cd /d "%REPO_ROOT%"
for %%I in ("%REPO_ROOT%\build\karateka.bin") do echo binary: build\karateka.bin (%%~zI bytes)
echo.

if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\build\karateka.bin"                       "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\r_boot_trace.lua"          "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"           "%CAPTURE_DIR%\tools\lib\" >nul
if exist "%CAPTURE_DIR%\tools\rboot_trace.log" del /f /q "%CAPTURE_DIR%\tools\rboot_trace.log"
echo Staged.

if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 30 ^
    -autoboot_script tools\r_boot_trace.lua >"%REPO_ROOT%\build\trace_mame.log" 2>&1
popd

echo.
echo --- Trace output ---
if exist "%CAPTURE_DIR%\tools\rboot_trace.log" (
    copy /Y "%CAPTURE_DIR%\tools\rboot_trace.log" "%REPO_ROOT%\build\" >nul
    type "%REPO_ROOT%\build\rboot_trace.log"
) else (
    echo No trace log produced - check build\trace_mame.log:
    powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\trace_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
)
echo.
echo === Trace done ===
