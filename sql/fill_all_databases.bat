@echo off
echo Запуск заполнения всех баз данных...
echo.

call 1_fill_admin_UserDB.bat
if %errorlevel% neq 0 (
    echo Ошибка при выполнении 1_fill_admin_UserDB.bat
    exit /b %errorlevel%
)

call 2_fill_admin_RightsDB.bat
if %errorlevel% neq 0 (
    echo Ошибка при выполнении 2_fill_admin_RightsDB.bat
    exit /b %errorlevel%
)

call 3_fill_admin_CommunityDB.bat
if %errorlevel% neq 0 (
    echo Ошибка при выполнении 3_fill_admin_CommunityDB.bat
    exit /b %errorlevel%
)

call 4_fill_FeedbackDB.bat
if %errorlevel% neq 0 (
    echo Ошибка при выполнении 4_fill_FeedbackDB.bat
    exit /b %errorlevel%
)

echo.
echo Все базы данных успешно заполнены!
pause