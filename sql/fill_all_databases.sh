#!/bin/bash
echo "Запуск заполнения всех баз данных..."
echo

./1_fill_admin_UserDB.sh
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении 1_fill_admin_UserDB.sh"
    exit 1
fi

./2_fill_admin_RightsDB.sh
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении 2_fill_admin_RightsDB.sh"
    exit 1
fi

./3_fill_admin_CommunityDB.sh
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении 3_fill_admin_CommunityDB.sh"
    exit 1
fi

./4_fill_FeedbackDB.sh
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении 4_fill_FeedbackDB.sh"
    exit 1
fi

echo
echo "Все базы данных успешно заполнены!"