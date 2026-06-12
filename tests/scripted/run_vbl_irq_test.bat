@echo off
REM run_vbl_irq_test.bat — R-vbl VBL IRQ test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === R-vbl VBL IRQ test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/vbl_irq_test_driver.bin ^
    tests/scripted/vbl_irq_test_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\vbl_irq_test_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
copy /Y "%REPO_ROOT%\tests\scripted\vbl_irq_test_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\vbl_irq_test.lua"        "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"         "%CAPTURE_DIR%\tools\lib\" >nul
if exist "%CAPTURE_DIR%\tools\vbltest_PASS" del /f /q "%CAPTURE_DIR%\tools\vbltest_PASS"
if exist "%CAPTURE_DIR%\tools\vbltest_FAIL" del /f /q "%CAPTURE_DIR%\tools\vbltest_FAIL"
echo STAGE: binary + Lua script staged

echo --- Step 3: RUN (MAME CoCo3) ---
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window -nothrottle ^
    -seconds_to_run 15 ^
    -autoboot_script tools\vbl_irq_test.lua >"%REPO_ROOT%\build\vbltest_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\vbltest.log" copy /Y "%CAPTURE_DIR%\tools\vbltest.log" "%REPO_ROOT%\build\" >nul

if exist "%CAPTURE_DIR%\tools\vbltest_PASS" (
    echo MAME TEST: PASS
    if exist "%REPO_ROOT%\build\vbltest.log" (
        findstr /C:"PASS" /C:"FAIL" /C:"delta" /C:"counter" /C:"FF90" /C:"010C" /C:"sys_init" "%REPO_ROOT%\build\vbltest.log" 2>nul
    )
    echo.
    echo === R-vbl MAME TEST: PASS ===
    exit /b 0
)

if exist "%CAPTURE_DIR%\tools\vbltest_FAIL" (
    echo MAME TEST: FAIL
    if exist "%REPO_ROOT%\build\vbltest.log" type "%REPO_ROOT%\build\vbltest.log"
    exit /b 1
)

echo MAME TEST: NO RESULT (check build\vbltest_mame.log)
powershell -NoProfile -Command "Get-Content '%REPO_ROOT%\build\vbltest_mame.log' -Tail 20 -ErrorAction SilentlyContinue"
exit /b 1
