@echo off
REM 
REM 
setlocal
setlocal EnableDelayedExpansion

REM 
for %%I in ("%~dp0.") do set "PROJECT_DIR=%%~fsI"
cd /d "%PROJECT_DIR%"
if %errorlevel% neq 0 (
    echo ERROR: Could not change to project directory
    pause
    exit /b 1
)

title Word Game - Running on Pixel 8 Pro

echo.
echo ============================================
echo   Word Game - Flutter Emulator Runner
echo ============================================
echo.

REM 
echo Checking Flutter installation...
call flutter --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH
    echo Please add Flutter to your PATH environment variable
    pause
    goto :cleanup_fail
)

REM 
echo.
echo Checking for connected devices...
call flutter devices

echo.

REM 
set "DEVICE_ID=emulator-5554"
call flutter devices > "%TEMP%\flutter_devices_word_game.txt" 2>&1
findstr /I /C:"%DEVICE_ID%" "%TEMP%\flutter_devices_word_game.txt" >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: %DEVICE_ID% bulunamadi.
    echo Bagli cihazlardan birini secin (ornek: windows, chrome, edge, emulator-5554)
    set /p DEVICE_ID=Cihaz ID girin: 
    if "!DEVICE_ID!"=="" (
        echo ERROR: Cihaz ID bos birakilamaz.
        pause
        goto :cleanup_fail
    )
)
del "%TEMP%\flutter_devices_word_game.txt" >nul 2>&1

REM 
set "FULL_RESET=0"
if /I "%~1"=="full" (
    set "FULL_RESET=1"
    goto :start_flutter
)
if /I "%~1"=="normal" (
    set "FULL_RESET=0"
    goto :start_flutter
)

echo.
echo Run mode:
echo   [N] Normal run (hizli, hot reload)
echo   [F] Full reset (uninstall + clean + pub get)
choice /C NF /N /M "Secim yapin (N/F): "
if errorlevel 2 (
    set "FULL_RESET=1"
) else (
    set "FULL_RESET=0"
)

:start_flutter

if "%FULL_RESET%"=="1" (
    echo FULL_RESET enabled: clean + pub get
    call flutter clean
    call flutter pub get
)

echo.
echo DEV tips:
echo - Kod degistirince bu terminalde r = hot reload
echo - Kod degistirince bu terminalde R = hot restart
echo - Bu terminali kapatma, surekli acik kalsin
echo.
echo Secilen cihaz: !DEVICE_ID!
call flutter run -d !DEVICE_ID! --target lib/main.dart

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Flutter run failed!
    echo Please check the error message above.
    echo.
    pause
    goto :cleanup_fail
)

echo.
echo ✓ App started successfully!
pause
goto :cleanup_ok

:cleanup_fail
endlocal
exit /b 1

:cleanup_ok
endlocal
exit /b 0
exit /b 0
