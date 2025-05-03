#!/bin/bash
echo "Запуск заполнения всех баз данных..."
echo

scripts=(
    "./1_fill_admin_UserDB.sh"
    "./2_fill_admin_RightsDB.sh"
    "./3_fill_admin_CommunityDB.sh"
    "./4_fill_FeedbackDB.sh"
)

for script in "${scripts[@]}"
do
    if [ ! -f "$script" ]; then
        echo "Ошибка: Файл $script не найден!"
        exit 1
    fi
    
    chmod +x "$script"
    echo "Выполнение $script..."
    "$script"
    
    if [ $? -ne 0 ]; then
        echo "Ошибка при выполнении $script"
        exit 1
    fi
done

echo
echo "Все базы данных успешно заполнены!"