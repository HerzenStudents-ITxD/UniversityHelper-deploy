@echo off
echo Запуск заполнения всех баз данных...
echo.

set SCRIPT1=1_fill_admin_UserDB.bat
set SCRIPT2=2_fill_admin_RightsDB.bat
set SCRIPT3=3_fill_admin_CommunityDB.bat
set SCRIPT4=4_fill_FeedbackDB.bat

if not exist "%SCRIPT1%" (
    echo Файл %SCRIPT1% не найден!
    pause
    exit /b 1
)
call "%SCRIPT1%"
if %errorlevel% neq 0 (
    echo Ошибка при выполнении %SCRIPT1%
    pause
    exit /b %errorlevel%
)

if not exist "%SCRIPT2%" (
    echo Файл %SCRIPT2% не найден!
    pause
    exit /b 1
)
call "%SCRIPT2%"
if %errorlevel% neq 0 (
    echo Ошибка при выполнении %SCRIPT2%
    pause
    exit /b %errorlevel%
)

if not exist "%SCRIPT3%" (
    echo Файл %SCRIPT3% не найден!
    pause
    exit /b 1
)
call "%SCRIPT3%"
if %errorlevel% neq 0 (
    echo Ошибка при выполнении %SCRIPT3%
    pause
    exit /b %errorlevel%
)

if not exist "%SCRIPT4%" (
    echo Файл %SCRIPT4% не найден!
    pause
    exit /b 1
)
call "%SCRIPT4%"
if %errorlevel% neq 0 (
    echo Ошибка при выполнении %SCRIPT4%
    pause
    exit /b %errorlevel%
)

echo.
echo Все базы данных успешно заполнены!
pause