@echo off
REM run_r_boot_debugtrace.bat — R-boot instruction-level trace (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-boot instruction-level trace ===
cd /d "%REPO_ROOT%"
for %%I in ("%REPO_ROOT%\build\karateka.bin") do echo binary: build\karateka.bin (%%~zI bytes)
echo MAME 0.281  -debug -debugscript boot_trace_bpset.dbg
echo.

if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\build\karateka.bin"                              "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\r_boot_debugtrace.lua"            "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\boot_trace_bpset.dbg"             "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\instrtrace.log" del /f /q "%CAPTURE_DIR%\tools\instrtrace.log"
echo Staged.

if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 30 ^
    -debug ^
    -debugscript tools\boot_trace_bpset.dbg ^
    -autoboot_script tools\r_boot_debugtrace.lua >"%REPO_ROOT%\build\debugtrace_mame.log" 2>&1
popd

echo.
echo --- Trace result ---
if exist "%CAPTURE_DIR%\tools\instrtrace.log" (
    copy /Y "%CAPTURE_DIR%\tools\instrtrace.log" "%REPO_ROOT%\build\" >nul
    powershell -NoProfile -Command "$lines = (Get-Content '%REPO_ROOT%\build\instrtrace.log').Count; Write-Host ('instrtrace.log: ' + $lines + ' lines')"
    echo.
    echo --- First 120 lines ---
    powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\instrtrace.log' -TotalCount 120"
    echo.
    echo --- Last 60 lines ---
    powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\instrtrace.log' -Tail 60"
) else (
    echo No trace log produced - check build\debugtrace_mame.log:
    powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\debugtrace_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
)
echo.
echo === Trace done ===
