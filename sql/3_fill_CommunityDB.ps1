
Write-Host "Launching CommunityDB database fill script..."

# Configuration
$USER_DB_PASSWORD = "User_1234"
$CONTAINER = "sqlserver_db"
$DATABASE = "CommunityDB"
$USER_ID = "11111111-1111-1111-1111-111111111111"

# Check existing tables
Write-Host "Checking existing CommunityDB tables..."
$checkTables = docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q @"
USE $DATABASE;
SELECT 'Communities' as TableName, COUNT(*) as Count FROM Communities
UNION ALL SELECT 'Agents', COUNT(*) FROM Agents
UNION ALL SELECT 'HiddenCommunities', COUNT(*) FROM HiddenCommunities
UNION ALL SELECT 'News', COUNT(*) FROM News
UNION ALL SELECT 'NewsPhoto', COUNT(*) FROM NewsPhoto
UNION ALL SELECT 'Participating', COUNT(*) FROM Participating;
"@
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to check existing CommunityDB tables."
    Pause
    exit 1
}

# Cleanup
Write-Host "`nCleaning up existing data..."
$cleanup = docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q @"
USE $DATABASE;
DELETE FROM Participating WHERE UserId = '$USER_ID';
DELETE FROM News WHERE AuthorId = '$USER_ID';
DELETE FROM Agents WHERE AgentId = '$USER_ID';
DELETE FROM HiddenCommunities WHERE UserId = '$USER_ID';
DELETE FROM Communities WHERE CreatedBy = '$USER_ID';
"@
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to clean up existing data."
    Pause
    exit 1
}

# Copy SQL script
Write-Host "`nCopying SQL script to container..."
$sqlPath = ".\sql\CommunityDB\06_setup_community_data.sql"
if (-Not (Test-Path $sqlPath)) {
    Write-Error "ERROR: SQL script $sqlPath not found."
    Pause
    exit 1
}
docker cp $sqlPath "$CONTAINER:/tmp/06_setup_community_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to copy SQL script to container."
    Pause
    exit 1
}

# Execute SQL script
Write-Host "Executing SQL script..."
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/06_setup_community_data.sql
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to execute SQL script."
    Pause
    exit 1
}

# Verify
Write-Host "`nVerifying CommunityDB tables..."
$verifyScript = ".\sql\CommunityDB\check_CommunityDB_tables.bat"
if (Test-Path $verifyScript) {
    & $verifyScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Verification script $verifyScript failed."
        Pause
        exit 1
    }
} else {
    Write-Warning "WARNING: Verification script $verifyScript not found."
    # Uncomment the following block if the script is in check_tables folder
    # $altScript = ".\check_tables\check_CommunityDB_tables.bat"
    # if (Test-Path $altScript) {
    #     & $altScript
    #     if ($LASTEXITCODE -ne 0) {
    #         Write-Error "ERROR: Verification script $altScript failed."
    #         Pause
    #         exit 1
    #     }
    # } else {
    #     Write-Warning "WARNING: Verification script $altScript not found."
    # }
}

Write-Host "Done ✅"
Pause
