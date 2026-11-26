@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title SUPERPOWER INSTALLER
cd /d "%~dp0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM ============================================================
REM  STEP 0 - Make sure we have administrator rights
REM  (Steam is often in Program Files, which needs admin to write)
REM ============================================================
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    color 0E
    cls
    echo.
    echo  ==========================================================
    echo    Administrator rights are needed.
    echo    A Windows prompt will appear - please click YES.
    echo  ==========================================================
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    if not "!errorlevel!"=="0" (
        call :fail "STEP 0 - Administrator rights" "Could not restart as administrator. Right-click this file and choose Run as administrator."
        exit /b 1
    )
    exit /b 0
)

REM Make the console window bigger (ignored by some terminals)
mode con: cols=100 lines=50 >nul 2>&1

REM ============================================================
REM  SCAN SCREEN  (green while we look around)
REM ============================================================
color 2F
cls
type display.dat
echo   ==========================================================
echo           CIVILIZATION V  -  SUPERPOWER INSTALLER
echo   ==========================================================
echo.
echo     Scanning your PC, please wait...
echo.

call :detect

REM ============================================================
REM  EVALUATE PREREQUISITES
REM ============================================================
set "PREREQ_OK=1"
set "PREREQ_MSG="
if not defined CIV5 (
    set "PREREQ_OK=0"
    if not defined STEAM (
        set "PREREQ_MSG=Steam is not installed. "
    ) else (
        set "PREREQ_MSG=Civilization V was not found in any Steam library. "
    )
)
if "!SRC_OK!"=="0" (
    set "PREREQ_OK=0"
    set "PREREQ_MSG=!PREREQ_MSG!Missing next to the installer:!SRC_MISSING!."
)

REM Green if everything is fine, RED if anything is missing
if "!PREREQ_OK!"=="1" (color 2F) else (color 4F)
cls
type display.dat
echo.
echo   ----------------------------------------------------------
echo     PREREQUISITES
echo   ----------------------------------------------------------
echo.

if defined CIV5 (
    echo   [OK]  1. Civ 5 location detected:
    echo            !CIV5!
) else (
    echo   [XX]  1. CIV5 LOCATION DETECTED:  NOT FOUND
)
echo.

if exist "!CACHE!\" (
    echo   [OK]  2. CI:
    echo            !CACHE!
) else (
    echo   [OK]  2. CIV5 CACHE DETECTED:
    echo            !CACHE!
    echo            ^(no cache folder exists yet - nothing to clear^)
)
echo.

if defined EXISTING (
    echo   [OK]  3. EXISTING INSTALLATION DETECTED
    echo            Found:!EXISTING!
    echo            ^(will be replaced with the new version^)
) else (
    echo   [OK]  3. EXISTING INSTALLATION NOT DETECTED
    echo            ^(fresh install^)
)
echo.

if "!SRC_OK!"=="1" (
    echo   [OK]  4. INSTALLATION FILES VALID
) else (
    echo   [XX]  4. INSTALLATION FILES INVALID
    echo            !SRC_MISSING!
)
echo.
echo   ==========================================================

if "!PREREQ_OK!"=="0" (
    echo.
    echo     PREREQUISITES NOT MET - THE INSTALLER CANNOT CONTINUE
    echo.
    echo     Reason: !PREREQ_MSG!
    echo.
    echo     Nothing was changed on your PC.
    echo.
    echo   ==========================================================
    echo     Press any key to EXIT...
    echo   ==========================================================
    pause >nul
    exit /b 1
)

echo.
echo     PREREQUISITES FULFILLED 
echo.
echo     Press ANY KEY to begin the installation...
echo   ==========================================================
pause >nul

REM ============================================================
REM  STEP 1 - Check that the source folders exist next to the BAT
REM ============================================================
color 2F
cls
type display.dat
echo    ####  #####  #####  ####          #             #       #####
echo   #        #    #      #   #        ##            #        #
echo    ###     #    ####   ####          #           #         ####
echo       #    #    #      #             #          #              #
echo   ####     #    #####  #            ###        #           ####
echo.
echo   ##########################################################
echo   #   CHECKING INSTALLATION FILES                          #
echo   ##########################################################
echo.
echo   Looking in: %SCRIPT_DIR%
echo.

if not exist "%SCRIPT_DIR%\MP_MODSPACK\" (
    call :fail "STEP 1 - Checking installation files" "The folder MP_MODSPACK was not found next to this BAT file."
    exit /b 1
)
echo   [OK] Found MP_MODSPACK

if not exist "%SCRIPT_DIR%\UI_MainMenu\" (
    call :fail "STEP 1 - Checking installation files" "The folder UI_MainMenu was not found next to this BAT file."
    exit /b 1
)
echo   [OK] Found UI_MainMenu
echo.
echo   STEP 1 COMPLETE.
timeout /t 2 >nul

REM ============================================================
REM  STEP 2 - Confirm Civilization V location
REM ============================================================
color 2F
cls
type display.dat
echo    ####  #####  #####  ####         ###            #       #####
echo   #        #    #      #   #       #   #          #        #
echo    ###     #    ####   ####          ##          #         ####
echo       #    #    #      #            #           #              #
echo   ####     #    #####  #           #####       #           ####
echo.
echo   ##########################################################
echo   #   CONFIRMING CIVILIZATION V LOCATION                   #
echo   ##########################################################
echo.

if not defined CIV5 (
    call :fail "STEP 2 - Locating Civilization V" "Civilization V was not found in any Steam library. Is it installed through Steam?"
    exit /b 1
)
if not exist "!DLC!\" (
    call :fail "STEP 2 - Locating Civilization V" "The DLC folder does not exist: !DLC!"
    exit /b 1
)
echo   [OK] Steam found at:
echo        !STEAM!
echo   [OK] Civilization V found at:
echo        !CIV5!
echo   [OK] DLC folder:
echo        !DLC!
echo.
echo   STEP 2 COMPLETE.
timeout /t 3 >nul

REM ============================================================
REM  STEP 3 - Remove existing MP_MODSPACK and UI_MainMenu
REM ============================================================
color 2F
cls
type display.dat
echo    ####  #####  #####  ####        ####            #       #####
echo   #        #    #      #   #           #          #        #
echo    ###     #    ####   ####         ###          #         ####
echo       #    #    #      #               #        #              #
echo   ####     #    #####  #           ####        #           ####
echo.
echo   ##########################################################
echo   #   REMOVING OLD INSTALLATION FOLDERS                    #
echo   ##########################################################
echo.
echo   Target: !DLC!
echo.

for %%F in (MP_MODSPACK UI_MainMenu) do (
    if exist "!DLC!\%%F\" (
        echo   Found old %%F - deleting...
        rmdir /s /q "!DLC!\%%F" >nul 2>&1
        if exist "!DLC!\%%F\" (
            call :fail "STEP 3 - Removing old installation folders" "Could not delete !DLC!\%%F. Close Civ 5 and any open Explorer windows, then try again."
            exit /b 1
        )
        echo   [OK] Deleted old %%F
    ) else (
        echo   [OK] No existing %%F - nothing to delete
    )
)
echo.
echo   STEP 3 COMPLETE.
timeout /t 2 >nul

REM ============================================================
REM  STEP 4 - Copy the new folders into Assets\DLC
REM ============================================================
color 2F
cls
type display.dat
echo    ####  #####  #####  ####        #  #            #       #####
echo   #        #    #      #   #       #  #           #        #
echo    ###     #    ####   ####        #####         #         ####
echo       #    #    #      #              #         #              #
echo   ####     #    #####  #              #        #           ####
echo.
echo   ##########################################################
echo   #   COPYING NEW FOLDERS INTO CIV 5                       #
echo   ##########################################################
echo.

for %%F in (MP_MODSPACK UI_MainMenu) do (
    echo   Copying %%F ... please wait
    robocopy "%SCRIPT_DIR%\%%F" "!DLC!\%%F" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >nul
    if !errorlevel! GEQ 8 (
        call :fail "STEP 4 - Copying folders" "Copying %%F to !DLC! failed. Make sure Civ 5 is closed and you have permission."
        exit /b 1
    )
    if not exist "!DLC!\%%F\" (
        call :fail "STEP 4 - Copying folders" "%%F was not found in !DLC! after copying."
        exit /b 1
    )
    echo   [OK] %%F copied successfully
)
echo.
echo   STEP 4 COMPLETE.
timeout /t 2 >nul

REM ============================================================
REM  STEP 5 - Clear the Civ 5 cache in My Documents
REM ============================================================
color 2F
cls
type display.dat
echo    ####  #####  #####  ####        #####           #       #####
echo   #        #    #      #   #       #              #        #
echo    ###     #    ####   ####        ####          #         ####
echo       #    #    #      #               #        #              #
echo   ####     #    #####  #           ####        #           ####
echo.
echo   ##########################################################
echo   #   CLEARING CIV 5 CACHE                                 #
echo   ##########################################################
echo.
echo   My Documents: !DOCS!
echo   Cache folder: !CACHE!
echo.

if exist "!CACHE!\" (
    echo   Cache folder found - deleting...
    rmdir /s /q "!CACHE!" >nul 2>&1
    if exist "!CACHE!\" (
        call :fail "STEP 5 - Clearing cache" "Could not delete !CACHE!. Close Civ 5 and try again."
        exit /b 1
    )
    echo   [OK] Cache folder deleted
) else (
    echo   [OK] No cache folder exists - nothing to clear
)
echo.
echo   STEP 5 COMPLETE.
timeout /t 2 >nul

REM ============================================================
REM  SUCCESS
REM ============================================================
color 2F
cls
type display.dat
echo    ####   #   #   ####  ####  #####   ####   ####   #
echo   #       #   #  #      #     #      #      #      #
echo    ####   #   #  #      #     #####   ####   ####  #
echo        #  #   #  #      #     #          #      #
echo    ####    ###    ####  ####  #####   ####   ####   #
echo.
echo   ==========================================================
echo     INSTALLED SUCCESSFULLY!
echo   ==========================================================
echo.
echo     [OK] Step 1 - Installation files found
echo     [OK] Step 2 - Civilization V located
echo     [OK] Step 3 - Old folders removed
echo     [OK] Step 4 - New folders installed
echo     [OK] Step 5 - Cache cleared
echo.
echo     You can now launch Civilization V.
echo.
echo   ==========================================================
echo     Press any key to EXIT...
echo   ==========================================================
pause >nul
exit /b 0

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:logo
echo.
echo      ______  _____  _______  ___  ____    _ _ _______   _____
echo     / __/ / / / _ \/ __/ _ \/ _ \/ __ \  / / / __/ _ \ /  __/
echo    _\ \/ /_/ / ___/ _// , _/ ___/ /_/ / / / / _// , _/ \ \  
echo   /___/\____/_/  /___/_/ _/_/   \____/ __/ __/ /__/_/ /___/  
echo.
exit /b 0

:detect
REM --- Steam location ---
set "STEAM="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| findstr /i "SteamPath"') do set "STEAM=%%B"
if not defined STEAM (
    for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul ^| findstr /i "InstallPath"') do set "STEAM=%%B"
)
if not defined STEAM (
    for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Valve\Steam" /v InstallPath 2^>nul ^| findstr /i "InstallPath"') do set "STEAM=%%B"
)
set "CIV5="
set "DLC="
if defined STEAM (
    set "STEAM=!STEAM:/=\!"
    call :checkLib "!STEAM!"
    if not defined CIV5 if exist "!STEAM!\steamapps\libraryfolders.vdf" call :scanVdf "!STEAM!\steamapps\libraryfolders.vdf"
)
if defined CIV5 set "DLC=!CIV5!\Assets\DLC"

REM --- Cache location (real My Documents, handles OneDrive redirection) ---
set "DOCS="
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"
set "CACHE=!DOCS!\My Games\Sid Meier's Civilization 5\cache"

REM --- Existing installation ---
set "EXISTING="
if defined DLC (
    if exist "!DLC!\MP_MODSPACK\" set "EXISTING=!EXISTING! MP_MODSPACK"
    if exist "!DLC!\UI_MainMenu\" set "EXISTING=!EXISTING! UI_MainMenu"
)

REM --- Installation files next to this installer ---
set "SRC_OK=1"
set "SRC_MISSING="
if not exist "%SCRIPT_DIR%\MP_MODSPACK\" (
    set "SRC_OK=0"
    set "SRC_MISSING=!SRC_MISSING! MP_MODSPACK"
)
if not exist "%SCRIPT_DIR%\UI_MainMenu\" (
    set "SRC_OK=0"
    set "SRC_MISSING=!SRC_MISSING! UI_MainMenu"
)
exit /b 0

:checkLib
if defined CIV5 exit /b 0
set "CAND=%~1\steamapps\common\Sid Meier's Civilization V"
if exist "%CAND%\Assets\DLC\" set "CIV5=%CAND%"
exit /b 0

:scanVdf
for /f tokens^=4^ delims^=^" %%A in ('findstr /c:"path" "%~1"') do (
    set "LIB=%%A"
    set "LIB=!LIB:\\=\!"
    call :checkLib "!LIB!"
)
exit /b 0

:fail
color 4F
cls
type display.dat
echo.
echo   #####   ####   #####  #       #####  ####
echo   #      #    #    #    #       #      #   #
echo   ####   ######    #    #       ####   #   #
echo   #      #    #    #    #       #      #   #
echo   #      #    #  #####  #####   #####  ####
echo.
echo   ==========================================================
echo     THE INSTALLER FAILED
echo   ==========================================================
echo.
echo     Failed at : %~1
echo     Reason    : %~2
echo.
echo     Nothing after this step was carried out.
echo.
echo   ==========================================================
echo     Press any key to EXIT...
echo   ==========================================================
pause >nul
exit /b 1
