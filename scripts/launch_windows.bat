@echo off
setlocal enabledelayedexpansion

echo.
echo =====================================================
echo ===     ActiveDev-Claimer - Setup Assistant       ===
echo =====================================================
echo.

set RUBY_PATH=C:\Ruby34-x64
set PROJECT_ROOT=%~dp0..\
set BOT_SCRIPT="%PROJECT_ROOT%src\bot.rb"

:: Check for restart flag
if exist "%TEMP%\discord_bot_restart.flag" (
    del "%TEMP%\discord_bot_restart.flag"
    goto after_restart
)

:: Phase 1: Ruby Installation Check
echo.
echo ++++++++++++ Checking Ruby Installation +++++++++++++
echo.
if not exist "%RUBY_PATH%\bin\ruby.exe" (
    echo === Installing Ruby 3.4.1-2 ===
    
    :: Download installer
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.1-2/rubyinstaller-3.4.1-2-x64.exe', 'rubyinstaller.exe')"
    
    if exist rubyinstaller.exe (
        start /wait rubyinstaller.exe /verysilent /tasks="assocfiles,modpath" /dir="%RUBY_PATH%"
        del rubyinstaller.exe
        
        echo === Ruby is now installed and the system needs to restart. Save all opened file before rebooting ===
        echo. > "%TEMP%\discord_bot_restart.flag"
        choice /c yn /m "Restart computer now?"
        if errorlevel 2 exit /b
        shutdown /r /t 0
        exit /b
    ) else (
        echo !!! ERROR: Failed to download installer !!!
        pause
        exit /b 1
    )
)

:after_restart
:: Phase 2: Dependency Management
echo.
echo +++++++++++++++ Managing Dependencies +++++++++++++++
echo.
cd /d "%PROJECT_ROOT%"

:: Verify Bundler (avec CALL)
ruby -S gem list bundler -i >nul 2>&1
if %errorlevel% neq 0 (
    echo === Installing Bundler ===
    call gem install bundler --no-document
)

:: Install gems (avec CALL)
if not exist "Gemfile.lock" (
    echo.
    echo ===== Installing Project Dependencies =====
    echo.
    call bundle install
)

:: Phase 3: Bot Execution
echo.
echo ===============================================
echo ===         Launching Discord Bot           ===
echo ===============================================
echo.

:: Verify bot script exists
if not exist %BOT_SCRIPT% (
    echo !!! ERROR: Missing bot script at %BOT_SCRIPT% !!!
    pause
    exit /b 1
)

call bundle exec ruby %BOT_SCRIPT%

if %errorlevel% neq 0 (
    echo !!! Bot stopped with error code %errorlevel% !!!
    pause
)
exit /b 0