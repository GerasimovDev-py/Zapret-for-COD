@echo off

if /i "%~1"=="del" (
    echo DELETE MONKEY DRIVER
    sc stop monkey >nul 2>&1
    sc delete monkey >nul 2>&1
    goto :end
)

sc qc monkey >nul 2>&1
if errorlevel 1 (
    echo Monkey driver is not installed.
    pause
    exit /b
)

echo.
choice /C YN /M "Do you want to stop and delete monkey"
if errorlevel 2 exit /b

powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList 'del' -Verb RunAs" >nul 2>&1
exit /b

:end
pause
