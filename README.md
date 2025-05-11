# Основные команды
- Собрать контейнеры: 
docker compose up -d
- Пересобрать образы и контейнеры: 
docker compose up -d --build
- Остановить контейнеры: 
docker compose down
- Остановить контейнеры и удалить волюмы: 
docker compose down -v
- Заполнить все бд в докере тестовыми данными:
./sql/fill_all_databases_in_docker.ps1
- Очистить все бд в докере:
./sql/clean_all_databases_in_docker.ps1
- Дропнуть все бд в докере:
./sql/drop_all_databases_in_docker.ps1

# Установите все зависимости

Docker Desktop:
- Windows https://docs.docker.com/desktop/setup/install/windows-install/
- Mac https://docs.docker.com/desktop/setup/install/mac-install/

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
На Linux/MacOS: pwsh ./sql/fill_all_databases.ps1
На Windows: ./sql/fill_all_databases.ps1

В MacOS/Linux:
- Сделайте скрипт исполняемым:
chmod +x ./sql/fill_all_databases.ps1

## Вариант 2 (через Makefile)
На Windows: скачать make (например choco install make) и пользоваться командами make up, make down...
Либо так: https://gnuwin32.sourceforge.net/packages/make.htm