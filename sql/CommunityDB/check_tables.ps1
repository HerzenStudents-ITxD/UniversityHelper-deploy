# PowerShell Core version of the database checker script

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
$USER_DB_PASSWORD = $envVars['SA_PASSWORD']
$CONTAINER = $envVars['DB_CONTAINER']
$DATABASE = $envVars['COMMUNITYDB_DB_NAME']

Write-Host "Checking CommunityDB tables..."

Write-Host "`nCommunities:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, Avatar, CreatedBy, CreatedAtUtc FROM Communities"

Write-Host "`nAgents:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, AgentId, CommunityId FROM Agents"

Write-Host "`nHiddenCommunities:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, CommunityId FROM HiddenCommunities"

Write-Host "`nNews:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Title, Text, AuthorId, CommunityId FROM News"

Write-Host "`nNewsPhoto:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Photo, NewsId FROM NewsPhoto"

Write-Host "`nParticipating:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, NewsId FROM Participating"

Write-Host "`nDone ✅"
Read-Host "Press Enter to continue"