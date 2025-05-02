@echo off
chcp 1251 > nul
setlocal EnableDelayedExpansion
echo Запуск заполнения всех баз данных...
echo.

:: Список скриптов для выполнения
set "SCRIPTS=1_fill_admin_UserDB.bat 2_fill_admin_RightsDB.bat 3_fill_admin_CommunityDB.bat 4_fill_FeedbackDB.bat"

:: Перебор всех скриптов
for %%S in (%SCRIPTS%) do (
    echo [Запуск] %%S
    if exist "%%S" (
        call "%%S"
        if !errorlevel! neq 0 (
            echo [Ошибка] Не удалось выполнить %%S (код: !errorlevel!)
            exit /b !errorlevel!
        )
        echo [Успех] %%S выполнен успешно
    ) else (
        echo [Ошибка] Файл %%S не найден
        exit /b 1
    )
    echo.
)

echo.
echo Все базы данных успешно заполнены!
pause