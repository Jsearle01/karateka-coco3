@echo off
REM run_gfx_init_test.bat — P2.3a HAL graphics init behavioral test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.3a HAL gfx_init test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/gfx_init_driver.bin ^
    tests/scripted/gfx_init_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\gfx_init_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\captures" mkdir "%CAPTURE_DIR%\captures"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\tests\scripted\gfx_init_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\gfx_init_test.lua"   "%CAPTURE_DIR%\tools\" >nul
if exist "%CAPTURE_DIR%\tools\gfxtest_PASS" del /f /q "%CAPTURE_DIR%\tools\gfxtest_PASS"
if exist "%CAPTURE_DIR%\tools\gfxtest_FAIL" del /f /q "%CAPTURE_DIR%\tools\gfxtest_FAIL"
echo STAGE: binary + Lua script staged

echo --- Step 3: RUN (MAME CoCo3) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 40 ^
    -autoboot_script tools\gfx_init_test.lua >"%REPO_ROOT%\build\gfxtest_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\gfxtest.log" copy /Y "%CAPTURE_DIR%\tools\gfxtest.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\captures\p2_3a_coco3_*.json") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\captures\" >nul
        echo   %%~nxF
    )
)

if exist "%CAPTURE_DIR%\tools\gfxtest_PASS" (
    echo MAME TEST: PASS
    if exist "%REPO_ROOT%\build\gfxtest.log" (
        findstr /C:"RESULT" /C:"DP$" /C:"frame_count" /C:"$8000" /C:"$BBFF" /C:"$C000" /C:"$FBFF" "%REPO_ROOT%\build\gfxtest.log" 2>nul
    )
    echo.
    echo === P2.3a MAME TEST: PASS ===
    exit /b 0
)

if exist "%CAPTURE_DIR%\tools\gfxtest_FAIL" (
    echo MAME TEST: FAIL
    if exist "%REPO_ROOT%\build\gfxtest.log" type "%REPO_ROOT%\build\gfxtest.log"
    exit /b 1
)

echo MAME TEST: NO RESULT (check build\gfxtest_mame.log)
powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\gfxtest_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
exit /b 1
