@echo off
REM run_smoke.bat — CoCo3 smoke test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture
set LUA_SRC=%REPO_ROOT%\harness\smoke\smoke_test.lua
set PASS_SENTINEL=%CAPTURE_DIR%\tools\coco3_smoke_PASS
set FAIL_SENTINEL=%CAPTURE_DIR%\tools\coco3_smoke_FAIL
set LOG_FILE=%CAPTURE_DIR%\tools\coco3_smoke.log

echo [run_smoke] karateka-coco3 smoke test
echo [run_smoke] staging Lua script...

if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
copy /Y "%LUA_SRC%" "%CAPTURE_DIR%\tools\coco3_smoke_test.lua" >nul

if exist "%PASS_SENTINEL%" del /f /q "%PASS_SENTINEL%"
if exist "%FAIL_SENTINEL%" del /f /q "%FAIL_SENTINEL%"

echo [run_smoke] launching CoCo3 under MAME...
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -nothrottle ^
    -seconds_to_run 10 ^
    -autoboot_script tools\coco3_smoke_test.lua >nul 2>&1
popd

if exist "%LOG_FILE%" copy /Y "%LOG_FILE%" "%REPO_ROOT%\harness\smoke\last-run.log" >nul

if exist "%PASS_SENTINEL%" (
    if exist "%LOG_FILE%" findstr /C:"PASS" /C:"FAIL" /C:"snapshot" /C:"EXIT" "%LOG_FILE%" 2>nul
    echo [run_smoke] PASS
    exit /b 0
)

echo [run_smoke] FAILURE
if exist "%REPO_ROOT%\harness\smoke\last-run.log" type "%REPO_ROOT%\harness\smoke\last-run.log"
exit /b 1
