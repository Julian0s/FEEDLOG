@echo off
REM FEEDLOG - Deploy Firebase Cloud Functions
REM This script deploys the backend to Firebase, making it work from anywhere

echo ========================================
echo FEEDLOG - Deploy Cloud Functions
echo ========================================
echo.

echo Checking if you configured OpenAI credentials in functions/.env...
findstr /C:"YOUR_OPENAI_KEY_HERE" functions\.env >nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [ERROR] OpenAI credentials not configured!
    echo Please edit functions/.env and add your OpenAI credentials.
    echo.
    pause
    exit /b 1
)

echo [OK] Credentials configured!
echo.

echo Step 1: Deploying Cloud Functions...
echo This will upload your backend to Firebase.
echo After this, you can test from ANYWHERE (home, work, 4G, WiFi, etc.)
echo.

firebase deploy --only functions

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Deploy failed!
    echo Check the error message above and try again.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Cloud Functions deployed! ✅
echo ========================================
echo.
echo What this means:
echo - Your app can now work from ANY network
echo - No more whitelist IP restrictions
echo - Ready to test on real devices via 4G/5G
echo - Safe to publish to App Store / Play Store
echo.
echo Next steps:
echo 1. Test from anywhere: flutter run
echo 2. Build for production: flutter build apk --release
echo 3. Publish to stores!
echo.
echo To view logs:
echo firebase functions:log
echo.
pause
