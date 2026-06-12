@echo off
REM run_kernel_dispatch_test.bat — P2.2 kernel/dispatch behavioral test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.2 kernel/dispatch test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/kernel_dispatch_driver.bin ^
    tests/scripted/kernel_dispatch_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\kernel_dispatch_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\captures" mkdir "%CAPTURE_DIR%\captures"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\tests\scripted\kernel_dispatch_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\kernel_dispatch_test.lua"   "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\kdtest_PASS" del /f /q "%CAPTURE_DIR%\tools\kdtest_PASS"
if exist "%CAPTURE_DIR%\tools\kdtest_FAIL" del /f /q "%CAPTURE_DIR%\tools\kdtest_FAIL"
echo STAGE: binary + Lua script staged

echo --- Step 3: RUN (MAME CoCo3) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 5 ^
    -autoboot_script tools\kernel_dispatch_test.lua >"%REPO_ROOT%\build\kdtest_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\kdtest.log" copy /Y "%CAPTURE_DIR%\tools\kdtest.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\captures\p2_2a_coco3_*.json") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\captures\" >nul
        echo   %%~nxF
    )
)

if exist "%CAPTURE_DIR%\tools\kdtest_PASS" (
    echo MAME TEST: PASS
    if exist "%REPO_ROOT%\build\kdtest.log" (
        findstr /C:"PASS" /C:"DP$" /C:"invariant" /C:"frame" "%REPO_ROOT%\build\kdtest.log" 2>nul
    )
    echo.
    echo === P2.2 MAME TEST: PASS ===
    exit /b 0
)

if exist "%CAPTURE_DIR%\tools\kdtest_FAIL" (
    echo MAME TEST: FAIL
    if exist "%REPO_ROOT%\build\kdtest.log" type "%REPO_ROOT%\build\kdtest.log"
    exit /b 1
)

echo MAME TEST: NO RESULT (check build\kdtest_mame.log)
powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\kdtest_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
exit /b 1
