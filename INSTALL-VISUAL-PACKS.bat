@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install_visual_packs.ps1"
if errorlevel 1 (
  echo.
  echo Visual pack installation failed. See the error above.
  pause
)
endlocal
