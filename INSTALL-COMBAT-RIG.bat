@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install_visual_packs.ps1" -CombatRigOnly
if errorlevel 1 (
  echo.
  echo Combat rig installation failed. See the error above.
  pause
)
endlocal
