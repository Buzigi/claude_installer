@echo off
:: Claude Code Installer - Windows Launcher
:: Provides menu-based interface for install/uninstall/verify operations

setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

:menu
cls
echo.
echo  ============================================================
echo        Claude Code Installer - GLM5 Edition
echo  ============================================================
echo.
echo   1. Install Claude Code (Recommended)
echo   2. Verify Installation
echo   3. Update Skills
echo   4. Uninstall Claude Code
echo   5. View Documentation
echo   6. Exit
echo.
echo  ============================================================
echo.

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto verify
if "%choice%"=="3" goto update
if "%choice%"=="4" goto uninstall
if "%choice%"=="5" goto docs
if "%choice%"=="6" goto end

echo.
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:install
cls
echo.
echo  ============================================================
echo        Installing Claude Code with GLM5 Configuration
echo  ============================================================
echo.
echo Starting installation...
echo.
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install-ClaudeCode.ps1"
echo.
pause
goto menu

:verify
cls
echo.
echo  ============================================================
echo        Verifying Claude Code Installation
echo  ============================================================
echo.
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Verify-Installation.ps1"
echo.
pause
goto menu

:update
cls
echo.
echo  ============================================================
echo        Updating Skills from Repository
echo  ============================================================
echo.
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Update-Skills.ps1"
echo.
pause
goto menu

:uninstall
cls
echo.
echo  ============================================================
echo        Uninstalling Claude Code
echo  ============================================================
echo.
echo WARNING: This will remove Claude Code configuration.
echo.
set /p confirm="Are you sure you want to continue? (y/N): "
if /i "%confirm%"=="y" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Uninstall-ClaudeCode.ps1"
)
echo.
pause
goto menu

:docs
cls
echo.
echo  ============================================================
echo        Documentation
echo  ============================================================
echo.
echo Opening documentation folder...
start "" "%SCRIPT_DIR%docs"
goto menu

:end
echo.
echo Thank you for using Claude Code Installer!
echo.
endlocal
exit /b 0
