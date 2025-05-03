#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"
LOGIN="adminlogin"
PASSWORD="Admin_1234"
SALT="Random_Salt"
USER_ID="11111111-1111-1111-1111-111111111111"
INTERNAL_SALT="UniversityHelper.SALT3"

echo "[DEBUG] Launching UserDB database fill script..."

echo "[DEBUG] 1. Generating SHA512 hash..."
HASH=$(echo -n "${SALT}${LOGIN}${PASSWORD}${INTERNAL_SALT}" | openssl dgst -sha512 -binary | base64)
echo "[DEBUG] Generated hash: $HASH"

echo "[DEBUG] 2. Preparing SQL content..."
cat > temp.sql <<EOF
USE UserDB;
DECLARE @Now DATETIME2 = GETUTCDATE();
INSERT INTO UsersCredentials (Id, UserId, Login, PasswordHash, Salt, IsActive, CreatedAtUtc)
VALUES (
  NEWID(),
  '11111111-1111-1111-1111-111111111111',
  'adminlogin',
  '$HASH',
  'Random_Salt',
  1,
  @Now
);
PRINT 'Created admin credentials for login: adminlogin';
EOF

# Конвертируем в UTF-8 без BOM
echo "[DEBUG] 3. Converting to UTF-8 without BOM..."
iconv -f ASCII -t UTF-8 temp.sql > "UniversityHelper-deploy/sql/UserDB/02_create_admin_credentials.sql"
rm temp.sql

echo "[DEBUG] 4. Verifying generated SQL file..."
cat "UniversityHelper-deploy/sql/UserDB/02_create_admin_credentials.sql"

echo "[DEBUG] 5. Copying SQL scripts to container..."
docker cp "UniversityHelper-deploy/sql/UserDB/01_create_admin_user.sql" $CONTAINER:/tmp/01_create_admin_user.sql
docker cp "UniversityHelper-deploy/sql/UserDB/02_create_admin_credentials.sql" $CONTAINER:/tmp/02_create_admin_credentials.sql
docker cp "UniversityHelper-deploy/sql/UserDB/04_setup_admin_user_data.sql" $CONTAINER:/tmp/04_setup_admin_user_data.sql

echo "[DEBUG] 6. Executing SQL scripts..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/01_create_admin_user.sql
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/02_create_admin_credentials.sql
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "USE $DATABASE; DELETE FROM UsersAdditions WHERE UserId = '$USER_ID'; DELETE FROM UsersCommunications WHERE UserId = '$USER_ID';"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_user_data.sql

echo "[SUCCESS] Script completed successfully ✅"