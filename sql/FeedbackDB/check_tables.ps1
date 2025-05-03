# PowerShell Core version of FeedbackDB checker

# Read .env file located one directory above
$envFile = Join-Path (Split-Path -Parent $PSScriptRoot) ".env"
if (-not (Test-Path $envFile)) {
    Write-Error "Could not find .env file at $envFile"
    exit 1
}

# Parse .env file
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#]\w+)\s*=\s*(.*)\s*$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Set variables from .env
$FEEDBACK_DB_PASSWORD = $envVars['SA_PASSWORD']
$CONTAINER = $envVars['DB_CONTAINER']
$DATABASE = $envVars['FEEDBACKDB_DB_NAME']

Write-Host "Checking Feedback Service tables..."

Write-Host "`nFeedback:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Feedback"

Write-Host "`nImages:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Images"

Write-Host "`nTypes:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM Types"

Write-Host "`nFeedbackTypes:"
docker exec -it $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $FEEDBACK_DB_PASSWORD -d $DATABASE -Q "SELECT * FROM FeedbackTypes"

Write-Host "`nDone ✅"
Read-Host "Press Enter to continue"