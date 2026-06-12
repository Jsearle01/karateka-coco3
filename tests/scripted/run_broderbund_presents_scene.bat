@echo off
REM run_broderbund_presents_scene.bat — Combined Broderbund scene test (Windows native)
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set CAPTURE_DIR=C:\karateka-capture

echo === Combined Broderbund Presents Scene Test ===
cd /d "%REPO_ROOT%"

echo --- Step 1: ASSEMBLE ---
lwasm --decb ^
    -o tests/scripted/broderbund_presents_scene_driver.bin ^
    tests/scripted/broderbund_presents_scene_driver.s
if errorlevel 1 ( echo ASSEMBLE FAILED & exit /b 1 )
for %%I in ("%REPO_ROOT%\tests\scripted\broderbund_presents_scene_driver.bin") do echo ASSEMBLE: PASS (%%~zI bytes)

echo --- Step 2: STAGE ---
if not exist "%CAPTURE_DIR%\tests" mkdir "%CAPTURE_DIR%\tests"
if not exist "%CAPTURE_DIR%\tools" mkdir "%CAPTURE_DIR%\tools"
if not exist "%CAPTURE_DIR%\tools\lib" mkdir "%CAPTURE_DIR%\tools\lib"
if not exist "%CAPTURE_DIR%\dumps" mkdir "%CAPTURE_DIR%\dumps"
copy /Y "%REPO_ROOT%\tests\scripted\broderbund_presents_scene_driver.bin" "%CAPTURE_DIR%\tests\" >nul
copy /Y "%REPO_ROOT%\tests\scripted\broderbund_presents_scene_test.lua"   "%CAPTURE_DIR%\tools\" >nul
copy /Y "%REPO_ROOT%\tools\lib\framebuffer_dump.lua"                      "%CAPTURE_DIR%\tools\lib\" >nul
echo STAGE: done

echo --- Step 3: RUN (MAME CoCo3) ---
echo Jay: watch the MAME window.
echo   Expect: Broderbund logos at upper portion of screen
echo           'presents' text at row 110
echo   Logo 2 (wordmark): col=26, row=88
echo   Logo 1 (badge):    col=35, row=72
echo   presents:          byte cols 33-52, row 110
if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
pushd C:\karateka-capture
C:\mame\mame.exe coco3 ^
    -rompath C:\mame\roms ^
    -window ^
    -seconds_to_run 35 ^
    -autoboot_script tools\broderbund_presents_scene_test.lua >"%REPO_ROOT%\build\broderbund_presents_scene_mame.log" 2>&1
popd

echo --- Step 4: COLLECT ---
if exist "%CAPTURE_DIR%\tools\broderbund_presents_scene_test.log" copy /Y "%CAPTURE_DIR%\tools\broderbund_presents_scene_test.log" "%REPO_ROOT%\build\" >nul
for %%F in ("%CAPTURE_DIR%\dumps\broderbund_presents_scene_shot*.bin") do (
    if exist "%%F" (
        copy /Y "%%F" "%REPO_ROOT%\build\" >nul
        echo   collected %%~nxF
    )
)

if exist "%REPO_ROOT%\build\broderbund_presents_scene_test.log" (
    echo === broderbund_presents_scene_test.log ===
    type "%REPO_ROOT%\build\broderbund_presents_scene_test.log"
)

dir /b "%REPO_ROOT%\build\broderbund_presents_scene_shot*_frameA.bin" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo === Framebuffer decode ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\broderbund_presents_scene_shot001_frameA.bin"
    echo.
    echo === Region: Logo 1 (rows 72-85, cols 35-44) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\broderbund_presents_scene_shot001_frameA.bin" --region 72,35,85,44
    echo.
    echo === Region: Logo 2 (rows 88-97, cols 26-42) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\broderbund_presents_scene_shot001_frameA.bin" --region 88,26,97,42
    echo.
    echo === Region: presents (rows 108-122, cols 30-55) ===
    python "%REPO_ROOT%\tools\decode_framebuffer.py" "%REPO_ROOT%\build\broderbund_presents_scene_shot001_frameA.bin" --region 108,30,122,55
)

echo.
echo === Combined Scene Test COMPLETE ===
