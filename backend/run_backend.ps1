Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  KeraLink Tourism Django API Backend" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Localhost URL:   http://127.0.0.1:8000/api/v1" -ForegroundColor Yellow
Write-Host "  Wi-Fi LAN URL:   http://192.168.220.40:8000/api/v1" -ForegroundColor Green
Write-Host "  Health Check:    http://192.168.220.40:8000/api/v1/health/" -ForegroundColor Green
Write-Host ""
Write-Host "  [Physical Phone via USB Tip]:" -ForegroundColor White
Write-Host "  Run: adb reverse tcp:8000 tcp:8000" -ForegroundColor Gray
Write-Host "  Then app connects directly via http://127.0.0.1:8000/api/v1" -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Starting Django server on 0.0.0.0:8000..." -ForegroundColor Green
& "C:\Users\SREERAG\AppData\Local\Programs\Python\Python314\python.exe" manage.py runserver 0.0.0.0:8000
