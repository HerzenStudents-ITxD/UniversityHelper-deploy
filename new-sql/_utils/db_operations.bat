@echo off
setlocal enabledelayedexpansion

:execute_sql_file
  docker exec -i %1 /opt/mssql-tools/bin/sqlcmd ^
    -S localhost -U SA -P "%DB_PASSWORD%" ^
    -d %2 -i %3
  
  if %ERRORLEVEL% neq 0 (
    call :fail "Failed to execute SQL file: %3"
  )
goto :eof

:start_transaction
  echo BEGIN TRANSACTION;
goto :eof

:commit_transaction
  echo COMMIT;
goto :eof

:rollback_on_error
  echo IF %%TRANCOUNT%% ^> 0 ROLLBACK;
goto :eof

:sql_cleanup
  docker exec %DB_CONTAINER% /bin/bash -c "rm -f /tmp/*.sql"
goto :eof