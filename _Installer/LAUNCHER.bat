@echo off
setlocal enabledelayedexpansion
REM Clears the Civilization V cache, then launches the game through Steam
REM using the DX11 launch option (Steam App ID 8930).
REM If Steam can't be found, falls back to starting the exe directly.

REM Steam launch option: Option1 / Option2 / Option3 ...
REM Change this if the wrong version opens. To see the list, run:
REM   start "" "steam://launch/8930/Dialog"
set "LAUNCH_OPTION=Option2"

set "APPID=8930"
set "EXE=CivilizationV_DX11.exe"
set "GAME_DIR="
set "DOCS="
set "STEAM="

REM ============================================================
REM 1) Find the Documents folder (handles OneDrive/moved Documents)
REM ============================================================
for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Personal 2^>nul ^| find "Personal"') do set "DOCS=%%B"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"
set "CACHE_DIR=%DOCS%\My Games\Sid Meier's Civilization 5\Cache"

REM ============================================================
REM 2) Check that Steam is installed
REM ============================================================
for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find "SteamPath"') do set "STEAM=%%B"
if not defined STEAM (
    for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul ^| find "InstallPath"') do set "STEAM=%%B"
)

REM ============================================================
REM 3) Fallback only: find the game folder (Steam App ID 8930 uninstall entry)
REM ============================================================
if not defined STEAM (
    for %%K in (
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 8930"
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 8930"
    ) do (
        if not defined GAME_DIR (
            for /f "tokens=2*" %%A in ('reg query %%K /v InstallLocation 2^>nul ^| find "InstallLocation"') do (
                if exist "%%B\%EXE%" set "GAME_DIR=%%B"
            )
        )
    )
)

REM ============================================================
REM 4) Delete cache contents (keeps the Cache folder itself)
REM ============================================================
if exist "%CACHE_DIR%" (
    echo Clearing cache...
    del /f /s /q "%CACHE_DIR%\*" >nul 2>&1
    for /d %%D in ("%CACHE_DIR%\*") do rd /s /q "%%D" >nul 2>&1
    echo Cache cleared.
) else (
    echo Cache folder not found: "%CACHE_DIR%"
)

REM ============================================================
REM 5) Launch the game
REM ============================================================
if defined STEAM (
    echo Starting Civilization V via Steam ^(%LAUNCH_OPTION%^)...
    start "" "steam://launch/%APPID%/%LAUNCH_OPTION%"
) else if defined GAME_DIR (
    echo Steam not found, starting exe directly from "!GAME_DIR!"
    cd /d "!GAME_DIR!"
    start "" "%EXE%"
) else (
    echo Could not locate Steam or Civilization V.
    echo Make sure Civilization V is installed through Steam.
    pause
)
endlocal
