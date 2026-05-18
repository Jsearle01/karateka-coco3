@echo off
REM Assemble GFXMODE3.ASM (now includes merged SCROLL_TEXT routines)
REM Usage: Double-click or run from command line

echo ======================================
echo Assembling GFXMODE3.ASM (with scrolling)...
echo ======================================
DEL "C:\Projects\cocobasic\src\A.BIN" 2>NUL
del "LISTING.TXT" 2>NUL
wsl lwasm --decb -lLISTING.TXT -o src/A.BIN src/GFXMODE3.ASM

if exist src\A.BIN (
    echo SUCCESS: src\A.BIN created.
    echo.
) else (
    echo ERROR: Assembly failed!
    pause
    exit /b 1
)

echo ======================================
echo Creating disk image...
echo ======================================

REM Set variables
set DISK=disks\KARATEKA.DSK
set IMGTOOL=c:\mame\imgtool.exe

REM Delete old disk image
del "%DISK%" 2>NUL

REM Create a blank disk image
%IMGTOOL% create coco_jvc_rsdos %DISK%
IF NOT EXIST %DISK% (
    echo ERROR: Disk image creation failed!
    pause
    exit /b 1
)

REM Place the linked binary on the disk
%IMGTOOL% put coco_jvc_rsdos %DISK% src\A.BIN A.BIN --ftype=binary
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to place BIN file on disk!
    pause
    exit /b 1
)

echo.
echo ======================================
echo Disk contents:
echo ======================================
%IMGTOOL% dir coco_jvc_rsdos %DISK%

echo.
echo ======================================
echo Build complete!
echo ======================================
echo Files created:
echo   - src\A.BIN (GFXMODE3 with merged scrolling routines)
echo   - disks\KARATEKA.DSK (Disk image)
echo.
echo To run in MAME:
echo   mame coco3 -flop1 disks\KARATEKA.DSK
echo   Then type: LOADM"A":EXEC
echo.
echo Note: SCROLL_TEXT.ASM routines are now merged into GFXMODE3.ASM
echo.
pause