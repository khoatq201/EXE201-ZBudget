@echo off
echo Building Android APK for Google Sign-In...

echo.
echo Step 1: Clean project
call flutter clean

echo.
echo Step 2: Get dependencies  
call flutter pub get

echo.
echo Step 3: Build debug APK
call flutter build apk --debug

echo.
echo Step 4: Install on connected device (optional)
set /p install="Install on device? (y/n): "
if /i "%install%"=="y" (
    call flutter install
)

echo.
echo Build completed!
echo APK location: build\app\outputs\flutter-apk\app-debug.apk
pause