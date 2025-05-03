Write-Host "[DEBUG] Launching UserDB database fill script..."

# Конфигурационные параметры
$USER_DB_PASSWORD = "User_1234"
$CONTAINER = "sqlserver_db"
$DATABASE = "UserDB"
$LOGIN = "adminlogin"
$PASSWORD = "Admin_1234"
$SALT = "Random_Salt"
$USER_ID = "11111111-1111-1111-1111-111111111111"
$INTERNAL_SALT = "UniversityHelper.SALT3"

Write-Host "[DEBUG] 1. Generating SHA512 hash..."

# Генерация SHA512 хэша
$plain = "$SALT$LOGIN$PASSWORD$INTERNAL_SALT"
$hashBytes = [System.Security.Cryptography.SHA512]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($plain))
$HASH = [Convert]::ToBase64String($hashBytes)

Write-Host "[DEBUG] Generated hash: $HASH"

Write-Host "[DEBUG] 2. Preparing SQL content..."

# Генерация SQL-запроса
$sqlLines = @(
    "USE $DATABASE;",
    "DECLARE @Now DATETIME2 = GETUTCDATE();",
    "INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)",
    "VALUES (",
    "  NEWID(),",
    "  '$USER_ID',",
    "  '$LOGIN',",
    "  '$HASH',",
    "  '$SALT',",
    "  1,",
    "  @Now",
    ");",
    "PRINT 'Created admin credentials for login: $LOGIN';"
)

$tempPath = "temp.sql"
$outPath = ".\sql\UserDB\02_create_admin_credentials.sql"

# Запись в файл (UTF-8 без BOM)
$sqlLines | Set-Content -Encoding UTF8 -NoNewline $tempPath
Get-Content $tempPath | Set-Content -Encoding UTF8 $outPath
Remove-Item $tempPath

Write-Host "[DEBUG] 3. Verifying generated SQL file..."
Get-Content $outPath | ForEach-Object { Write-Host $_ }

Write-Host "[DEBUG] 4. Checking file encoding..."
$bytes = [System.IO.File]::ReadAllBytes($outPath)
Write-Host "First 3 bytes (BOM): $($bytes[0]) $($bytes[1]) $($bytes[2])"

Write-Host "[DEBUG] 5. Copying SQL scripts to container..."
docker cp ".\sql\UserDB\01_create_admin_user.sql" "$CONTAINER:/tmp/01_create_admin_user.sql"
docker cp "$outPath" "$CONTAINER:/tmp/02_create_admin_credentials.sql"
docker cp ".\sql\UserDB\04_setup_admin_user_data.sql" "$CONTAINER:/tmp/04_setup_admin_user_data.sql"

Write-Host "[DEBUG] 6. Executing SQL scripts..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/01_create_admin_user.sql
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/02_create_admin_credentials.sql
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; DELETE FROM UsersAdditions WHERE UserId = '$USER_ID'; DELETE FROM UsersCommunications WHERE UserId = '$USER_ID';"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_user_data.sql

Write-Host "[SUCCESS] Script completed successfully ✅"
Read-Host "Press Enter to continue..."
