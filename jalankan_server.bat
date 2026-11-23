@echo off
title MyFinance Web Server (Port 8085)
cd /d "%~dp0"
cls
echo ======================================================
echo   Menjalankan MyFinance Local Server
echo ======================================================
python web\server_nocache.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Mencoba dengan Python Laragon...
    "C:\laragon\bin\python\python-3.10\python.exe" web\server_nocache.py
)
pause
