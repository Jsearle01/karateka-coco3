@echo off
REM Create a CoCo disk image and place the BASIC file on it using MAME's imgtool
REM Usage: Double-click or run from command line

REM Set variables
set DISK=disks\HELLO.DSK
set BASIC=basic\HELLO.BAS
set IMGTOOL=c:\mame\imgtool.exe

REM Create a blank disk image
%IMGTOOL% create coco_jvc_rsdos %DISK%
IF NOT EXIST %DISK% (
    echo Disk image creation failed!
    pause
    exit /b 1
)

REM Place the BASIC file on the disk image as BASIC type
%IMGTOOL% put coco_jvc_rsdos %DISK% basic\HELLO.BAS HELLO.BAS --ftype=basic
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to place BASIC file on disk!
    pause
    exit /b 1
)
REM List disk contents to verify
%IMGTOOL% dir coco_jvc_rsdos %DISK%
pause
