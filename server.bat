@echo off
:: open.mp Build Tool - Single Entry Point
:: Usage: server <command> [args...]

setlocal

:: Require PowerShell 7+ (pwsh)
where pwsh >nul 2>&1
if %errorlevel% neq 0 (
    echo error: PowerShell 7+ ^(pwsh^) is required
    echo        https://github.com/PowerShell/PowerShell/releases
    exit /b 1
)
set "PS=pwsh"

set "TOOLS=%~dp0tools"

if "%~1"=="" goto :help
if /i "%~1"=="install"       %PS% -NoProfile -EP Bypass -File "%TOOLS%\install.ps1" %2 %3 %4 %5 %6 %7 %8 %9 & goto :eof
if /i "%~1"=="build"         %PS% -NoProfile -EP Bypass -File "%TOOLS%\build.ps1" %2 %3 %4 %5 %6 %7 %8 %9 & goto :eof
if /i "%~1"=="run"           %PS% -NoProfile -EP Bypass -File "%TOOLS%\run.ps1" %2 %3 %4 %5 %6 %7 %8 %9 & goto :eof
if /i "%~1"=="build-and-run" %PS% -NoProfile -EP Bypass -File "%TOOLS%\build-and-run.ps1" %2 %3 %4 %5 %6 %7 %8 %9 & goto :eof
if /i "%~1"=="help"          goto :help
if /i "%~1"=="--help"        goto :help
if /i "%~1"=="-h"            goto :help

echo error: unknown command "%~1"
echo.
goto :help

:help
echo Usage: server ^<command^> [args...]
echo.
echo Commands:
echo   install [version]
echo   build   [-Gamemode x] [-Filter y] [-File z.pwn] [-Release]
echo   run     [-Window]
echo   build-and-run [-Release]
echo.
echo Examples:
echo   server install
echo   server install 1.5.8.3079
echo   server build
echo   server build -Release
echo   server build -Gamemode "main.pwn"
echo   server build -Filter "vip.pwn"
echo   server build -File "gamemodes\main.pwn"
echo   server run
