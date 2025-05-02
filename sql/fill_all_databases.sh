#!/bin/bash
echo "Запуск заполнения всех баз данных..."
echo

SCRIPTS=(
    "./1_fill_admin_UserDB.sh"
    "./2_fill_admin_RightsDB.sh"
    "./3_fill_admin_CommunityDB.sh"
    "./4_fill_FeedbackDB.sh"
)

for SCRIPT in "${SCRIPTS[@]}"; do
    echo "[Запуск] $SCRIPT"
    if [ -f "$SCRIPT" ]; then
        chmod +x "$SCRIPT" 2>/dev/null
        "$SCRIPT"
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo "[Ошибка] Не удалось выполнить $SCRIPT (код: $EXIT_CODE)"
            exit $EXIT_CODE
        fi
        echo "[Успех] $SCRIPT выполнен успешно"
    else
        echo "[Ошибка] Файл $SCRIPT не найден"
        exit 1
    fi
    echo
done

echo
echo "Все базы данных успешно заполнены!"