Write-Host "Launching FeedbackDB database fill script..."

$USER_DB_PASSWORD = "User_1234"
$CONTAINER = "sqlserver_db"
$DATABASE = "FeedbackDB"

Write-Host "Copying Feedback SQL scripts to container..."
$sqlScriptPath = ".\sql\FeedbackDB\07_setup_feedback_data.sql"
if (-Not (Test-Path $sqlScriptPath)) {
    Write-Host "ERROR: SQL script $sqlScriptPath not found." -ForegroundColor Red
    Pause
    exit 1
}
docker cp $sqlScriptPath "$CONTAINER:/tmp/07_setup_feedback_data.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy SQL script to container." -ForegroundColor Red
    Pause
    exit 1
}

Write-Host "Setting up Feedback tables and data..."
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -i /tmp/07_setup_feedback_data.sql
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to execute SQL script." -ForegroundColor Red
    Pause
    exit 1
}

Write-Host "Verifying Feedback tables..."
$verificationScript = ".\sql\FeedbackDB\check_FeedbackDB_tables.bat"
if (Test-Path $verificationScript) {
    Write-Host "Running verification script..."
    & $verificationScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Verification script check_FeedbackDB_tables.bat failed." -ForegroundColor Red
        Pause
        exit 1
    }
} else {
    Write-Host "WARNING: Verification script $verificationScript not found." -ForegroundColor Yellow
}

Write-Host "Done ✅"
Pause