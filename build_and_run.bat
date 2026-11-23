@echo off
title MyFinance - Build ^& Run
cd /d "%~dp0"
cls
echo ======================================================
echo   1. Mengompilasi Flutter Web Release...
echo ======================================================
call "C:\laragon\puro\envs\stable\flutter\bin\flutter.bat" build web --release

echo.
echo ======================================================
echo   2. Menyalin Berkas Pendukung (WASM ^& OCR)...
echo ======================================================
python web\post_build.py

echo.
echo ======================================================
echo   3. Menjalankan Server Port 8085...
echo ======================================================
python web\server_nocache.py
pause
