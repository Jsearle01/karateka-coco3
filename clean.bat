@echo off
REM clean.bat - Remove build artifacts (native Windows). No WSL, no make.
setlocal

for %%I in ("%~dp0.") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

if exist build\karateka.bin del /q build\karateka.bin
if exist build\*.log del /q build\*.log
del /q tests\scripted\*.bin 2>nul
echo Clean complete
exit /b 0
