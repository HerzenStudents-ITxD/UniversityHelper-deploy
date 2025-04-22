#!/bin/bash

USER_DB_PASSWORD="User_1234"
CONTAINER="sqlserver_db"
DATABASE="UserDB"
LOGIN="adminlogin"
PASSWORD="Admin_1234"
SALT="Random_Salt"
USER_ID="11111111-1111-1111-1111-111111111111"
INTERNAL_SALT="UniversityHelper.SALT3"

echo "Generating hash..."
HASH=$(echo -n "${SALT}${LOGIN}${PASSWORD}${INTERNAL_SALT}" | openssl dgst -sha512 -binary | base64)
echo "Generated hash: $HASH"

echo "Substituting hash into final SQL..."
sed -e "s|СЮДА_ТВОЙ_BASE64_ХЕШ|$HASH|g" UniversityHelper-deploy/sql/02_create_admin_credentials_template.sql > UniversityHelper-deploy/sql/02_create_admin_credentials.sql

echo "Copying SQL scripts to container..."
docker cp UniversityHelper-deploy/sql/01_create_admin_user.sql $CONTAINER:/tmp/
docker cp UniversityHelper-deploy/sql/02_create_admin_credentials.sql $CONTAINER:/tmp/
docker cp UniversityHelper-deploy/sql/04_setup_admin_user_data.sql $CONTAINER:/tmp/

echo "Creating admin user..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/01_create_admin_user.sql

echo "Creating admin credentials..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/02_create_admin_credentials.sql

echo "Setting up admin user data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/04_setup_admin_user_data.sql

echo "Verifying UserDB tables..."
./UniversityHelper-deploy/check_tables/check_UserDB_tables.sh

echo "Done ✅" 