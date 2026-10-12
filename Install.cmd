@echo off
setlocal
set "EDUFLEX_SCRIPT=%TEMP%\EduFlex-Install-%RANDOM%-%RANDOM%.ps1"
curl.exe --fail --location --proto =https --output "%EDUFLEX_SCRIPT%" "https://raw.githubusercontent.com/MJunJunJun/EduFlex-Draw-Download/main/Install.ps1"
if errorlevel 1 exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%EDUFLEX_SCRIPT%"
set "EDUFLEX_RESULT=%ERRORLEVEL%"
del "%EDUFLEX_SCRIPT%" >nul 2>nul
exit /b %EDUFLEX_RESULT%
