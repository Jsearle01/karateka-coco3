@echo off
REM run_sub_byte_shifter_test.bat — P2.4.1 sub-byte shifter unit test runner (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === P2.4.1 Sub-Byte Shifter Test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/sub_byte_shifter_test_driver.bin ^
    tests/scripted/sub_byte_shifter_test_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\sub_byte_shifter_test_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\dumps" mkdir "%CAPTURE_DIR%\dumps"
copy /Y "%REPO_ROOT%\tests\scripted\sub_byte_shifter_test_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\sub_byte_shifter_test.lua"        "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"                  "%CAPTURE_DIR%\tools\lib\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3 - real speed) ---
echo Jay: watch the MAME window.
echo   Expect 4 horizontal white bands at rows 20, 35, 50, 65.
echo   Each band should be shifted 1 pixel further right than the previous:
echo     Row 20 (subbyte=0): left edge at pixel 40 (byte boundary)
echo     Row 35 (subbyte=1): left edge at pixel 41
echo     Row 50 (subbyte=2): left edge at pixel 42
echo     Row 65 (subbyte=3): left edge at pixel 43
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 10 ^
    -autoboot_script tools\sub_byte_shifter_test.lua >"%REPO_ROOT%\build\sub_byte_shifter_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\sub_byte_shifter_test.log" copy /Y "%CAPTURE_DIR%\tools\sub_byte_shifter_test.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\dumps\sb_shifter_shot*.bin") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\build\" >nul
        echo   collected %%~nxF
    )
)

if exist "%REPO_ROOT%\build\sub_byte_shifter_test.log" (
    echo === sub_byte_shifter_test.log ===
    type "%REPO_ROOT%\build\sub_byte_shifter_test.log"
)

dir /b "%REPO_ROOT%\build\sb_shifter_shot*_frameA.bin" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo === Framebuffer decode - overall ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\sb_shifter_shot001_frameA.bin"
    echo.
    echo === Region: subbyte=0 (rows 20-27, cols 9-14) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\sb_shifter_shot001_frameA.bin" --region 20,9,27,14
    echo.
    echo === Region: subbyte=1 (rows 35-42, cols 9-14) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\sb_shifter_shot001_frameA.bin" --region 35,9,42,14
    echo.
    echo === Region: subbyte=2 (rows 50-57, cols 9-14) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\sb_shifter_shot001_frameA.bin" --region 50,9,57,14
    echo.
    echo === Region: subbyte=3 (rows 65-72, cols 9-14) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\sb_shifter_shot001_frameA.bin" --region 65,9,72,14
)

echo.
echo === P2.4.1 Sub-Byte Shifter Test COMPLETE ===
echo Expected framebuffer byte values at byte col 10-12:
echo   subbyte=0: $FF $FF $00  (no shift, no overflow)
echo   subbyte=1: $3F $FF $C0  (2-bit shift)
echo   subbyte=2: $0F $FF $F0  (4-bit shift)
echo   subbyte=3: $03 $FF $FC  (6-bit shift)
