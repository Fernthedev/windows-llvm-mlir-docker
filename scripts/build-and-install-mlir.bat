@echo off
setlocal

REM build-and-install-mlir.bat
REM Assumes VS environment is already initialised by the caller (VsDevCmd.bat).

set "SRC_DIR=C:\llvm-project"
set "BUILD_DIR=%SRC_DIR%\build"
set "INSTALL_PREFIX=C:\mlir-install"

set "LOG_DIR=C:\TEMP\mlir-build-logs"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo Logging build output to %LOG_DIR%

if not exist "%SRC_DIR%" (
    echo ERROR: Source not found at %SRC_DIR%
    exit /b 1
)

if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

if not defined CMAKE_GENERATOR set "CMAKE_GENERATOR=Visual Studio 17 2022"
echo Using CMAKE_GENERATOR=%CMAKE_GENERATOR%

echo Creating install prefix if missing...
if not exist "%INSTALL_PREFIX%" mkdir "%INSTALL_PREFIX%"

echo Configuring with explicit -S/-B (logs in %LOG_DIR%)...
cmake -S "%SRC_DIR%\llvm" -B "%BUILD_DIR%" ^
    -G "%CMAKE_GENERATOR%" ^
    -A x64 ^
    -Thost=x64 ^
    -DLLVM_ENABLE_PROJECTS=mlir ^
    -DLLVM_BUILD_EXAMPLES=ON ^
    -DLLVM_TARGETS_TO_BUILD=Native ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%INSTALL_PREFIX%" ^
    -DLLVM_ENABLE_ASSERTIONS=ON

echo Building and installing using `cmake --install` (logs in %LOG_DIR%)...
cmake --build "%BUILD_DIR%" --config Release
cmake --install "%BUILD_DIR%" --config Release --prefix "%INSTALL_PREFIX%" --verbose

REM verify install
if exist "%INSTALL_PREFIX%\bin" (
    echo Installed to %INSTALL_PREFIX%
) else (
    echo ERROR: expected install prefix missing (%INSTALL_PREFIX%). Dumping logs...
    type "%LOG_DIR%\cmake-config.log"
    type "%LOG_DIR%\cmake-build.log"
    type "%LOG_DIR%\cmake-install.log"
    echo Directory listing of build dir:
    dir "%BUILD_DIR%"
    popd
    @REM exit /b 1
)

echo Installed to %INSTALL_PREFIX%
popd
endlocal
exit /b 0