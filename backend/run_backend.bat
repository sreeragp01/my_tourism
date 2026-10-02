@echo off
echo ================================================================
echo   KeraLink Tourism Django API Backend
echo ================================================================
echo   Localhost URL:   http://127.0.0.1:8000/api/v1
echo   Wi-Fi LAN URL:   http://192.168.220.40:8000/api/v1
echo   Health Check:    http://192.168.220.40:8000/api/v1/health/
echo.
echo   [Physical Phone via USB Tip]:
echo   Run: adb reverse tcp:8000 tcp:8000
echo   Then app connects directly via http://127.0.0.1:8000/api/v1
echo ================================================================
echo Starting Django server on 0.0.0.0:8000...
"C:\Users\SREERAG\AppData\Local\Programs\Python\Python314\python.exe" manage.py runserver 0.0.0.0:8000
pause
