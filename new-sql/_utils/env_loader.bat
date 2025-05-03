@echo off

:load_env
  if not exist ".env" (
    call :fail ".env file not found in project root"
  )

  for /f "tokens=1* delims==" %%A in (.env) do (
    set "%%A=%%B"
  )

  call :validate_env DB_CONTAINER
  call :validate_env DB_PASSWORD
goto :eof