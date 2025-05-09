# PowerShell Core version of RightsDB checker

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
$DATABASE = $envVars['RIGHTSDB_DB_NAME']

Write-Host "Checking RightsDB tables..."

Write-Host "`nRoles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, CreatedBy, IsActive FROM Roles"

Write-Host "`nRolesLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, Locale, Name FROM RolesLocalizations"

Write-Host "`nRightsLocalizations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RightId, Locale, Name FROM RightsLocalizations"

Write-Host "`nRolesRights:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, RoleId, RightId, CreatedBy FROM RolesRights"

Write-Host "`nUsersRoles:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, UserId, RoleId, IsActive FROM UsersRoles"

Write-Host "`nDone ✅"
Read-Host "Press Enter to continue"