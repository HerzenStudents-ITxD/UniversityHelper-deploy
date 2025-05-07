ИНСТРУКЦИЯ по сборке проекта

# Установите все зависимости

Docker Desktop:

PowerShell Core (v7+): https://learn.microsoft.com/ru-ru/powershell/

Все необходимые сервисы включая этот проект:
- UniversityHelper-deploy: 
- UniversityHelper-AuthService: 
- UniversityHelper-RightsService: 
- UniversityHelper-UserService: 
- UniversityHelper-CommunityService: 
- UniversityHelper-FeedbackService: 
- UniversityHelper-MapService: 
(пока что эти, сообщение будет обновляться)

В ближайшее будущее (в прогрессе поддержки, пока они ничего не умеют):
- TimetableService, 



## Вариант 1 (ручной)

Переходите терминалом в папку UniversityHelper-deploy и пишите команду
docker compose up -d
Эта команда создает образы если их нет и запускает по ним контейнеры
В первый раз будет долго (у меня ушло 500 секунд), следующие разы быстрее
Чтобы удалить контейнеры команда 
docker compose down

После этого можете пользоваться нашими сервисами. 
UserService:
http://127.0.0.1:80/swagger/index.html
RightService:
http://127.0.0.1:81/swagger/index.html
AuthService:
http://127.0.0.1:82/swagger/index.html
CommunityService:
http://127.0.0.1:83/swagger/index.html


127.0.0.1 = localhost, просто так в тг ссылка работает как ссылка

Если хотите чтобы какие-то ручки не требовали авторизаци -- прописываете их в конце файла appsettings.json

❗️ИНСТРУКЦИЯ как завести админа для логина 
На Linux: bash install_admin_linux.sh
На MacOs: bash install_admin_macos.sh
На Windows: install_admin_windows.bat

Если из консоли в VS Code то команда будет выглядеть так: .\install_admin_windows.bat

## Вариант 2 (автоматический)
Чтобы использовать эти скрипты:
В Windows:
Просто дважды щелкните на start.bat 
(не работает судя по всему)

В macOS/Linux:
- Откройте терминал
- Перейдите в директорию с проектом
- Сделайте скрипт исполняемым:
chmod +x setup.sh
- Запустите скрипт:
./setup.sh

Скрипты автоматически:
- Определят вашу операционную систему
- Проверят наличие make
- Установят make, если он отсутствует
- Запустят make после установки
- Все скрипты требуют прав администратора для установки пакетов, поэтому они автоматически запросят повышение прав при необходимости.
