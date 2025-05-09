#!/usr/bin/env pwsh

# PowerShell Core version of the MapDB checker script

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
$DATABASE = $envVars['MAPDB_DB_NAME']

Write-Host "Checking MapDB tables..."

Write-Host "`nLabels:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, CreatedBy, CreatedAtUtc, IsActive FROM Labels"

Write-Host "`nPoints:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, X, Y, Z, Icon, CreatedBy, CreatedAtUtc, IsActive FROM Points"

Write-Host "`nPointAssociations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, PointId, Association FROM PointAssociations"

Write-Host "`nLabelPoints:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, LabelId, PointId, CreatedBy, CreatedAtUtc, IsActive FROM LabelPoints"

Write-Host "`nPhotos:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, PointId, OrdinalNumber, CreatedBy, CreatedAtUtc, IsActive FROM Photos"

Write-Host "`nPointTypes:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, Name, Icon, CreatedBy, CreatedAtUtc, IsActive FROM PointTypes"

Write-Host "`nPointTypeAssociations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, PointTypeId, Association, CreatedBy, CreatedAtUtc, IsActive FROM PointTypeAssociations"

Write-Host "`nPointTypePoints:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, PointTypeId, PointId FROM PointTypePoints"

Write-Host "`nPointTypeRectangularParallelepipeds:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, PointTypeId, XMin, YMin, ZMin, XMax, YMax, ZMax, CreatedBy, CreatedAtUtc, IsActive FROM PointTypeRectangularParallelepipeds"

Write-Host "`nRelations:"
docker exec $CONTAINER /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P $USER_DB_PASSWORD -d $DATABASE -Q "SELECT Id, FirstPointId, SecondPointId, CreatedBy, CreatedAtUtc FROM Relations"

Write-Host "`nDone ✅"
Read-Host "Press Enter to continue"