@echo off
REM entrypoint-vcvars.bat
REM Purpose: initialize Visual Studio environment variables then run the requested command.
REM If no command is given, start an interactive `cmd` with VS vars set.

REM Initialise VS variables if vcvarsall exists
if exist "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
  call "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
) else (
  echo WARNING: vcvarsall.bat not found at C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat
)

REM Run provided command or drop to interactive cmd
if "%*"=="" (
  cmd
) else (
  cmd /S /C "%*"
)
